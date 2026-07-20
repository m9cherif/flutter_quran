import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show Rect, Offset;
import 'package:flutter/foundation.dart';
import '../models/annotation.dart';

class AnnotationProvider extends ChangeNotifier {
  ui.Image? _image;
  File? _imageFile;
  final List<HLine> _hLines = [];
  final List<VLine> _vLines = [];
  final List<Word> _words = [];
  final List<UndoAction> _undoStack = [];

  int _wordCounter = 0;
  int _borderWidth = 2;
  bool _showWords = true;
  bool _showHLines = false;
  bool _showVLines = false;
  bool _moveMode = false;
  String _currentPageNumber = '';
  Annotation? _selectedElement;

  ui.Image? get image => _image;
  File? get imageFile => _imageFile;
  List<HLine> get hLines => List.unmodifiable(_hLines);
  List<VLine> get vLines => List.unmodifiable(_vLines);
  List<Word> get words => List.unmodifiable(_words);
  int get borderWidth => _borderWidth;
  bool get showWords => _showWords;
  bool get showHLines => _showHLines;
  bool get showVLines => _showVLines;
  bool get moveMode => _moveMode;
  String get currentPageNumber => _currentPageNumber;
  Annotation? get selectedElement => _selectedElement;
  int get wordCounter => _wordCounter;

  Rect? previewRect;

  void reset() {
    _image = null;
    _imageFile = null;
    _hLines.clear();
    _vLines.clear();
    _words.clear();
    _undoStack.clear();
    _wordCounter = 0;
    _selectedElement = null;
    _moveMode = false;
    previewRect = null;
    notifyListeners();
  }

  Future<void> loadPageImage(String pageNumber) async {
    final base = _getBaseDirectory();
    final filePath = '$base\\png\\page$pageNumber.png';
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Fichier introuvable : $filePath');
    }
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _image = frame.image;
    _imageFile = file;
    _currentPageNumber = pageNumber;
    _hLines.clear();
    _vLines.clear();
    _words.clear();
    _undoStack.clear();
    _wordCounter = 0;
    _selectedElement = null;
    _moveMode = false;
    _borderWidth = 2;
    _showWords = true;
    _showHLines = false;
    _showVLines = false;
    previewRect = null;
    notifyListeners();
  }

  String _getBaseDirectory() {
    final base = Directory('${Directory.current.path}\\quran_data');
    if (!base.existsSync()) {
      base.createSync(recursive: true);
    }
    return base.path;
  }

  void ensureDirectories() {
    final base = _getBaseDirectory();
    Directory('$base\\png').createSync(recursive: true);
    Directory('$base\\annotation').createSync(recursive: true);
  }

  List<Word> getSortedWords() {
    final sorted = List<Word>.from(_words)
      ..sort((a, b) {
        if (a.y1 != b.y1) return a.y1.compareTo(b.y1);
        return b.x2.compareTo(a.x2);
      });
    return sorted;
  }

  Map<String, double>? findBoundingHLines(double y, {double tol = 5.0}) {
    if (_hLines.length < 2) return null;
    final sortedYs = _hLines.map((h) => h.y).toList()..sort();
    double? closest;
    double minDist = double.infinity;
    for (var yy in sortedYs) {
      final dist = (yy - y).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = yy;
      }
    }
    if (closest == null) return null;
    final idx = sortedYs.indexOf(closest);
    double? top, bottom;
    if (minDist <= tol) {
      if (idx > 0 && idx < sortedYs.length - 1) {
        top = sortedYs[idx - 1];
        bottom = sortedYs[idx + 1];
      } else if (idx == 0 && sortedYs.length >= 2) {
        top = sortedYs[0];
        bottom = sortedYs[1];
      } else if (idx == sortedYs.length - 1 && sortedYs.length >= 2) {
        top = sortedYs[sortedYs.length - 2];
        bottom = sortedYs[sortedYs.length - 1];
      }
    } else {
      for (var yy in sortedYs) {
        if (yy < y) {
          top = yy;
        } else {
          bottom = yy;
          break;
        }
      }
    }
    if (top == null || bottom == null) return null;
    return {'top': top, 'bottom': bottom};
  }

  bool isDuplicateWord(double x1, double y1, double x2, double y2, {double tol = 2.0}) {
    for (var w in _words) {
      if ((w.x1 - x1).abs() < tol &&
          (w.y1 - y1).abs() < tol &&
          (w.x2 - x2).abs() < tol &&
          (w.y2 - y2).abs() < tol) {
        return true;
      }
    }
    return false;
  }

  Annotation? hitTest(Offset point) {
    for (var h in _hLines.reversed) {
      if ((point.dy - h.y).abs() < 5) return h;
    }
    for (var v in _vLines.reversed) {
      if ((point.dx - v.x).abs() < 5 &&
          point.dy >= v.top &&
          point.dy <= v.bottom) {
        return v;
      }
    }
    for (var w in _words.reversed) {
      if (point.dx >= w.x1 &&
          point.dx <= w.x2 &&
          point.dy >= w.y1 &&
          point.dy <= w.y2) {
        return w;
      }
    }
    return null;
  }

  bool trySelectElement(Offset point) {
    final element = hitTest(point);
    if (element != null && element != _selectedElement) {
      _selectedElement = element;
      notifyListeners();
      return true;
    } else if (element == null && _selectedElement != null) {
      _selectedElement = null;
      notifyListeners();
    }
    return element != null;
  }

  Word? addWordAtPoint(Offset point) {
    final hBounds = findBoundingHLines(point.dy);
    if (hBounds == null) return null;

    final top = hBounds['top']!;
    final bottom = hBounds['bottom']!;
    final tol = 2.0;

    final validXs = <double>[];
    for (var v in _vLines) {
      if (v.top <= top + tol && v.bottom >= bottom - tol) {
        validXs.add(v.x);
      }
    }
    validXs.sort();
    if (validXs.length < 2) return null;

    final leftCandidates = validXs.where((x) => x < point.dx).toList();
    final rightCandidates = validXs.where((x) => x > point.dx).toList();
    if (leftCandidates.isEmpty || rightCandidates.isEmpty) return null;

    final left = leftCandidates.last;
    final right = rightCandidates.first;
    if (right <= left || bottom <= top) return null;

    if (isDuplicateWord(left, top, right, bottom)) return null;

    _wordCounter++;
    final word = Word(
      id: _wordCounter,
      x1: left,
      y1: top,
      x2: right,
      y2: bottom,
    );
    _words.add(word);
    _undoStack.add(UndoAction(type: 'add_word', data: {'id': word.id}));
    notifyListeners();
    return word;
  }

  void addHLine(double y) {
    final exists = _hLines.any((h) => (h.y - y).abs() < 5);
    if (exists) return;
    final id = _hLines.isEmpty ? 1 : _hLines.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
    final line = HLine(id: id, y: y);
    _hLines.add(line);
    _hLines.sort((a, b) => a.y.compareTo(b.y));
    _undoStack.add(UndoAction(type: 'add_h', data: {'id': line.id}));
    notifyListeners();
  }

  void addVLine(double x, double top, double bottom) {
    final exists = _vLines.any((v) => (v.x - x).abs() < 5);
    if (exists) return;
    final id = _vLines.isEmpty ? 1 : _vLines.map((v) => v.id).reduce((a, b) => a > b ? b : a) + 1;
    final line = VLine(id: id, x: x, top: top, bottom: bottom);
    _vLines.add(line);
    _vLines.sort((a, b) => a.x.compareTo(b.x));
    _undoStack.add(UndoAction(type: 'add_v', data: {'id': line.id}));
    notifyListeners();
  }

  void deleteSelected() {
    if (_selectedElement == null) return;
    if (_selectedElement is HLine) {
      final h = _selectedElement as HLine;
      _undoStack.add(UndoAction(type: 'delete', data: {'type': 'h', 'y': h.y, 'id': h.id}));
      _hLines.remove(h);
    } else if (_selectedElement is VLine) {
      final v = _selectedElement as VLine;
      _undoStack.add(UndoAction(type: 'delete', data: {
        'type': 'v',
        'x': v.x,
        'top': v.top,
        'bottom': v.bottom,
        'id': v.id,
      }));
      _vLines.remove(v);
    } else if (_selectedElement is Word) {
      final w = _selectedElement as Word;
      _undoStack.add(UndoAction(type: 'delete', data: {
        'type': 'word',
        'x1': w.x1,
        'y1': w.y1,
        'x2': w.x2,
        'y2': w.y2,
        'id': w.id,
        'hidden': w.hidden,
      }));
      _words.remove(w);
    }
    _selectedElement = null;
    notifyListeners();
  }

  void performMove(Offset point) {
    if (_selectedElement == null || !_moveMode) return;
    if (_selectedElement is HLine) {
      final h = _selectedElement as HLine;
      final oldY = h.y;
      _undoStack.add(UndoAction(type: 'move_h', data: {'id': h.id, 'old_y': oldY}));
      h.y = point.dy;
      _hLines.sort((a, b) => a.y.compareTo(b.y));
    } else if (_selectedElement is VLine) {
      final v = _selectedElement as VLine;
      final oldX = v.x;
      _undoStack.add(UndoAction(type: 'move_v', data: {
        'id': v.id,
        'old_x': oldX,
        'top': v.top,
        'bottom': v.bottom,
      }));
      v.x = point.dx;
      _vLines.sort((a, b) => a.x.compareTo(b.x));
    } else if (_selectedElement is Word) {
      final w = _selectedElement as Word;
      final oldX1 = w.x1, oldY1 = w.y1, oldX2 = w.x2, oldY2 = w.y2;
      _undoStack.add(UndoAction(type: 'move_word', data: {
        'id': w.id,
        'old_x1': oldX1,
        'old_y1': oldY1,
        'old_x2': oldX2,
        'old_y2': oldY2,
      }));
      final dx = point.dx - w.x1;
      final dy = point.dy - w.y1;
      w.x1 = point.dx;
      w.y1 = point.dy;
      w.x2 = w.x2 + dx;
      w.y2 = w.y2 + dy;
    }
    _moveMode = false;
    notifyListeners();
  }

  void setMoveMode(bool value) {
    _moveMode = value;
    notifyListeners();
  }

  void toggleMoveMode() {
    _moveMode = !_moveMode;
    if (_moveMode && _selectedElement == null) {
      _moveMode = false;
    }
    notifyListeners();
  }

  void cancelMove() {
    _moveMode = false;
    _selectedElement = null;
    notifyListeners();
  }

  void setBorderWidth(int value) {
    _borderWidth = value;
    notifyListeners();
  }

  void toggleWordsVisibility() {
    _showWords = !_showWords;
    notifyListeners();
  }

  void showAllWords() {
    final states = <Map<String, dynamic>>[];
    for (var w in _words) {
      states.add({'id': w.id, 'old_hidden': w.hidden});
      w.hidden = false;
    }
    _undoStack.add(UndoAction(type: 'visibility_all', data: {'states': states}));
    notifyListeners();
  }

  void hideAllWords() {
    final states = <Map<String, dynamic>>[];
    for (var w in _words) {
      states.add({'id': w.id, 'old_hidden': w.hidden});
      w.hidden = true;
    }
    _undoStack.add(UndoAction(type: 'visibility_all', data: {'states': states}));
    notifyListeners();
  }

  void toggleSelectedWordVisibility() {
    if (_selectedElement == null || _selectedElement is! Word) return;
    final w = _selectedElement as Word;
    final oldHidden = w.hidden;
    w.hidden = !w.hidden;
    _undoStack.add(UndoAction(
      type: 'visibility_word',
      data: {'id': w.id, 'old_hidden': oldHidden},
    ));
    notifyListeners();
  }

  void navigateToNextWord() {
    if (_words.isEmpty) return;
    final sorted = getSortedWords();
    int idx = 0;
    if (_selectedElement is Word) {
      final currentIdx = sorted.indexOf(_selectedElement as Word);
      if (currentIdx >= 0) {
        idx = (currentIdx + 1) % sorted.length;
      }
    }
    _selectedElement = sorted[idx];
    notifyListeners();
  }

  void navigateToPrevWord() {
    if (_words.isEmpty || _selectedElement is! Word) return;
    final sorted = getSortedWords();
    final currentIdx = sorted.indexOf(_selectedElement as Word);
    if (currentIdx < 0) return;
    final idx = (currentIdx - 1 + sorted.length) % sorted.length;
    _selectedElement = sorted[idx];
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeLast();
    switch (entry.type) {
      case 'add_h':
        final id = entry.data['id'] as int;
        _hLines.removeWhere((h) => h.id == id);
        break;
      case 'add_v':
        final id = entry.data['id'] as int;
        _vLines.removeWhere((v) => v.id == id);
        break;
      case 'add_word':
        final id = entry.data['id'] as int;
        _words.removeWhere((w) => w.id == id);
        break;
      case 'delete':
        final type = entry.data['type'] as String;
        if (type == 'h') {
          final y = entry.data['y'] as double;
          final id = entry.data['id'] as int;
          _hLines.add(HLine(id: id, y: y));
          _hLines.sort((a, b) => a.y.compareTo(b.y));
        } else if (type == 'v') {
          final x = entry.data['x'] as double;
          final top = entry.data['top'] as double;
          final bottom = entry.data['bottom'] as double;
          final id = entry.data['id'] as int;
          _vLines.add(VLine(id: id, x: x, top: top, bottom: bottom));
          _vLines.sort((a, b) => a.x.compareTo(b.x));
        } else if (type == 'word') {
          final x1 = entry.data['x1'] as double;
          final y1 = entry.data['y1'] as double;
          final x2 = entry.data['x2'] as double;
          final y2 = entry.data['y2'] as double;
          final id = entry.data['id'] as int;
          final hidden = entry.data['hidden'] as bool? ?? false;
          final word = Word(id: id, x1: x1, y1: y1, x2: x2, y2: y2);
          word.hidden = hidden;
          _words.add(word);
        }
        break;
      case 'move_h':
        final id = entry.data['id'] as int;
        final oldY = entry.data['old_y'] as double;
        final h = _hLines.where((h) => h.id == id).firstOrNull;
        if (h != null) h.y = oldY;
        _hLines.sort((a, b) => a.y.compareTo(b.y));
        break;
      case 'move_v':
        final id = entry.data['id'] as int;
        final oldX = entry.data['old_x'] as double;
        final v = _vLines.where((v) => v.id == id).firstOrNull;
        if (v != null) v.x = oldX;
        _vLines.sort((a, b) => a.x.compareTo(b.x));
        break;
      case 'move_word':
        final id = entry.data['id'] as int;
        final oldX1 = entry.data['old_x1'] as double;
        final oldY1 = entry.data['old_y1'] as double;
        final oldX2 = entry.data['old_x2'] as double;
        final oldY2 = entry.data['old_y2'] as double;
        final w = _words.where((w) => w.id == id).firstOrNull;
        if (w != null) {
          w.x1 = oldX1;
          w.y1 = oldY1;
          w.x2 = oldX2;
          w.y2 = oldY2;
        }
        break;
      case 'visibility_word':
        final id = entry.data['id'] as int;
        final oldHidden = entry.data['old_hidden'] as bool;
        final w = _words.where((w) => w.id == id).firstOrNull;
        if (w != null) w.hidden = oldHidden;
        break;
      case 'visibility_all':
        final states = entry.data['states'] as List;
        for (var s in states) {
          final id = s['id'] as int;
          final oldHidden = s['old_hidden'] as bool;
          final w = _words.where((w) => w.id == id).firstOrNull;
          if (w != null) w.hidden = oldHidden;
        }
        break;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedElement = null;
    notifyListeners();
  }

  void setPreviewRect(Rect? rect) {
    previewRect = rect;
    notifyListeners();
  }

  void clearPreviewRect() {
    previewRect = null;
    notifyListeners();
  }
}
