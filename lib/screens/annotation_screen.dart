import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/annotation_provider.dart';
import '../services/excel_service.dart';
import '../widgets/annotation_painter.dart';
import '../widgets/control_panel.dart';

class AnnotationScreen extends StatefulWidget {
  const AnnotationScreen({super.key});

  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  final AnnotationProvider provider = AnnotationProvider();
  final TransformationController transformCtrl = TransformationController();
  final FocusNode focusNode = FocusNode();
  final TextEditingController pageInputCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  int _panelAnimKey = 0;

  @override
  void initState() {
    super.initState();
    provider.addListener(_onProviderChange);
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    provider.removeListener(_onProviderChange);
    transformCtrl.dispose();
    focusNode.dispose();
    pageInputCtrl.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (mounted) setState(() {});
  }

  Offset _screenToScene(Offset screenPoint) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return screenPoint;
    final localPos = box.globalToLocal(screenPoint);
    final matrix = transformCtrl.value;
    final inverted = Matrix4.inverted(matrix);
    final transformed = MatrixUtils.transformPoint(inverted, localPos);
    return transformed;
  }

  Future<void> _loadImage() async {
    final text = pageInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await provider.loadPageImage(text);
      setState(() {
        _panelAnimKey++;
      });
      _autoImport(text);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _autoImport(String pageNumber) async {
    try {
      await ExcelService.autoImportIfExists(
        pageNumber: pageNumber,
        onWord: (x1, y1, x2, y2) {
          provider.addWordAtPoint(Offset((x1 + x2) / 2, (y1 + y2) / 2));
        },
        onHLine: (y) {
          provider.addHLine(y);
        },
        onVLine: (x, top, bottom) {
          provider.addVLine(x, top, bottom);
        },
      );
    } catch (_) {}
  }

  Future<void> _importExcel() async {
    final data = await ExcelService.importExcel();
    if (data == null || !mounted) return;

    for (var m in (data['Mots'] ?? [])) {
      final x1 = (m['x1'] as num?)?.toDouble() ?? 0;
      final y1 = (m['y1'] as num?)?.toDouble() ?? 0;
      final x2 = (m['x2'] as num?)?.toDouble() ?? 0;
      final y2 = (m['y2'] as num?)?.toDouble() ?? 0;
      if (x2 > x1 && y2 > y1) {
        provider.addWordAtPoint(Offset((x1 + x2) / 2, (y1 + y2) / 2));
      }
    }
    for (var h in (data['Horizontales'] ?? [])) {
      final y = (h['y'] as num?)?.toDouble() ?? 0;
      provider.addHLine(y);
    }
    for (var v in (data['Verticales'] ?? [])) {
      final x = (v['x'] as num?)?.toDouble() ?? 0;
      final top = (v['top'] as num?)?.toDouble() ?? 0;
      final bottom = (v['bottom'] as num?)?.toDouble() ?? 0;
      provider.addVLine(x, top, bottom);
    }
  }

  Future<void> _exportExcel() async {
    if (provider.currentPageNumber.isEmpty) {
      _showSnackBar('لم يتم تحميل أي صفحة');
      return;
    }
    final ok = await ExcelService.exportExcel(
      words: provider.words,
      hLines: provider.hLines,
      vLines: provider.vLines,
      pageNumber: provider.currentPageNumber,
    );
    if (mounted) {
      _showSnackBar(ok ? 'تم التصدير بنجاح' : 'خطأ في التصدير');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onTapUp(Offset scenePos) {
    if (provider.image == null) return;

    if (provider.moveMode && provider.selectedElement != null) {
      provider.performMove(scenePos);
      return;
    }

    final hit = provider.hitTest(scenePos);
    if (hit != null) {
      provider.trySelectElement(scenePos);
      return;
    }

    provider.addWordAtPoint(scenePos);
  }

  void _updatePreview(Offset screenPos) {
    if (provider.image == null) {
      provider.clearPreviewRect();
      return;
    }
    final scenePos = _screenToScene(screenPos);
    final hBounds = provider.findBoundingHLines(scenePos.dy);
    if (hBounds == null) {
      provider.clearPreviewRect();
      return;
    }
    final top = hBounds['top']!;
    final bottom = hBounds['bottom']!;
    final tol = 2.0;
    final validXs = <double>[];
    for (var v in provider.vLines) {
      if (v.top <= top + tol && v.bottom >= bottom - tol) {
        validXs.add(v.x);
      }
    }
    validXs.sort();
    if (validXs.length < 2) {
      provider.clearPreviewRect();
      return;
    }
    final leftCandidates = validXs.where((x) => x < scenePos.dx).toList();
    final rightCandidates = validXs.where((x) => x > scenePos.dx).toList();
    if (leftCandidates.isEmpty || rightCandidates.isEmpty) {
      provider.clearPreviewRect();
      return;
    }
    final left = leftCandidates.last;
    final right = rightCandidates.first;
    if (right <= left || bottom <= top) {
      provider.clearPreviewRect();
      return;
    }
    provider.setPreviewRect(Rect.fromLTRB(left, top, right, bottom));
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isCtrl = HardwareKeyboard.instance.logicalKeysPressed
        .any((k) => k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight);
    final isShift = HardwareKeyboard.instance.logicalKeysPressed
        .any((k) => k == LogicalKeyboardKey.shiftLeft || k == LogicalKeyboardKey.shiftRight);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyA:
        if (!isCtrl) provider.showAllWords();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyC:
        if (!isCtrl) provider.hideAllWords();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyT:
        provider.toggleSelectedWordVisibility();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        provider.toggleMoveMode();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        provider.deleteSelected();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        provider.cancelMove();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        provider.navigateToPrevWord();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        provider.navigateToNextWord();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyZ:
        if (isCtrl) provider.undo();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyI:
        if (isCtrl) _importExcel();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyE:
        if (isCtrl && !isShift) _exportExcel();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Row(
            children: [
              Expanded(child: _buildImageViewer()),
              _buildPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return Listener(
      onPointerMove: (event) => _updatePreview(event.position),
      child: GestureDetector(
        onTapUp: (details) {
          final scenePos = _screenToScene(details.globalPosition);
          _onTapUp(scenePos);
        },
        child: Container(
          color: const Color(0xFF0D1117),
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: transformCtrl,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 10.0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([provider, transformCtrl]),
                    builder: (context, _) {
                      if (provider.image == null && !_isLoading) {
                        return _buildEmptyState();
                      }
                      if (provider.image == null && _isLoading) {
                        return _buildLoadingState();
                      }
                      final imgSize = Size(
                        provider.image!.width.toDouble(),
                        provider.image!.height.toDouble(),
                      );
                      return SizedBox(
                        width: imgSize.width,
                        height: imgSize.height,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: imgSize.width,
                            height: imgSize.height,
                            child: CustomPaint(
                              painter: AnnotationPainter(
                                image: provider.image,
                                hLines: provider.hLines,
                                vLines: provider.vLines,
                                words: provider.words,
                                borderWidth: provider.borderWidth,
                                showWords: provider.showWords,
                                showHLines: provider.showHLines,
                                showVLines: provider.showVLines,
                                selectedElement: provider.selectedElement,
                                previewRect: provider.previewRect,
                              ),
                              size: imgSize,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories, size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            'أدخل رقم الصفحة لبدء التحديد',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('جاري التحميل...'),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ControlPanel(
        key: ValueKey('panel_$_panelAnimKey'),
        provider: provider,
        onLoadImage: _loadImage,
        onImportExcel: _importExcel,
        onExportExcel: _exportExcel,
      ),
    );
  }
}
