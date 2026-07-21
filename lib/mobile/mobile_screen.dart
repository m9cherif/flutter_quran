import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/annotation_provider.dart';
import '../services/xlsx_reader.dart';
import '../services/audio_manager.dart';
import '../widgets/annotation_painter.dart';
import 'mobile_data_service.dart';

class AppSettings {
  bool showWordBoxes = true;
  bool showHLines = false;
  bool showVLines = false;
  int borderWidth = 2;
  double swipeThreshold = 50;
  int overlayTimeoutSec = 3;
  bool keepAwake = false;
  bool vibrateOnWord = true;
  bool boldBorders = false;
  bool darkBg = true;
  bool landscapeFit = false;
  bool snapToGrid = false;
  bool showHiddenWords = false;
  double highlightOpacity = 0.2;
  String highlightColor = 'yellow';
  String lastPage = '';
  int minScale = 50;
  int maxScale = 300;
  bool showPageNumOnImage = false;
  bool autoLoadAudio = false;

  Map<String, dynamic> toJson() => {
    'showWordBoxes': showWordBoxes,
    'showHLines': showHLines,
    'showVLines': showVLines,
    'borderWidth': borderWidth,
    'swipeThreshold': swipeThreshold,
    'overlayTimeoutSec': overlayTimeoutSec,
    'keepAwake': keepAwake,
    'vibrateOnWord': vibrateOnWord,
    'boldBorders': boldBorders,
    'darkBg': darkBg,
    'landscapeFit': landscapeFit,
    'snapToGrid': snapToGrid,
    'showHiddenWords': showHiddenWords,
    'highlightOpacity': highlightOpacity,
    'highlightColor': highlightColor,
    'lastPage': lastPage,
    'minScale': minScale,
    'maxScale': maxScale,
    'showPageNumOnImage': showPageNumOnImage,
    'autoLoadAudio': autoLoadAudio,
  };

  AppSettings.fromJson(Map<String, dynamic> json) {
    showWordBoxes = json['showWordBoxes'] as bool? ?? false;
    showHLines = json['showHLines'] as bool? ?? false;
    showVLines = json['showVLines'] as bool? ?? false;
    borderWidth = json['borderWidth'] as int? ?? 2;
    swipeThreshold = (json['swipeThreshold'] as num?)?.toDouble() ?? 50;
    overlayTimeoutSec = json['overlayTimeoutSec'] as int? ?? 3;
    keepAwake = json['keepAwake'] as bool? ?? false;
    vibrateOnWord = json['vibrateOnWord'] as bool? ?? true;
    boldBorders = json['boldBorders'] as bool? ?? false;
    darkBg = json['darkBg'] as bool? ?? true;
    landscapeFit = json['landscapeFit'] as bool? ?? false;
    snapToGrid = json['snapToGrid'] as bool? ?? false;
    showHiddenWords = json['showHiddenWords'] as bool? ?? false;
    highlightOpacity = (json['highlightOpacity'] as num?)?.toDouble() ?? 0.2;
    highlightColor = json['highlightColor'] as String? ?? 'yellow';
    lastPage = json['lastPage'] as String? ?? '';
    minScale = json['minScale'] as int? ?? 50;
    maxScale = json['maxScale'] as int? ?? 300;
    showPageNumOnImage = json['showPageNumOnImage'] as bool? ?? false;
    autoLoadAudio = json['autoLoadAudio'] as bool? ?? false;
  }

  AppSettings();

  Color get highlightPaintColor {
    switch (highlightColor) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'pink': return Colors.pink;
      default: return Colors.yellow;
    }
  }
}

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final AnnotationProvider provider = AnnotationProvider();
  final TextEditingController pageInputCtrl = TextEditingController();
  final FocusNode pageInputFocus = FocusNode();
  final MobileDataService dataService = MobileDataService();
  final ScrollController _scrollCtrl = ScrollController();

  late final AudioManager audioManager;
  late AppSettings _settings;

  bool _isLoading = false;
  String? _errorMessage;
  double? _dragStartX;
  int? _dragStartTime;
  int _pointerCount = 0;

  double _lastW = 0;
  double _lastH = 0;
  double _scrollOffset = 0;

  bool _showOverlay = false;
  Timer? _overlayTimer;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _settings = AppSettings();
    _loadSettings();
    audioManager = AudioManager(provider);
    provider.addListener(_onProviderChange);
    _checkConnection();
    _scrollCtrl.addListener(() {
      _scrollOffset = _scrollCtrl.offset;
    });
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    provider.removeListener(_onProviderChange);
    audioManager.cleanup();
    audioManager.dispose();
    pageInputCtrl.dispose();
    pageInputFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (mounted) setState(() {});
  }

  Future<void> _checkConnection() async {
    await dataService.checkConnection();
  }

  Future<void> _loadSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/quran_settings.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
        if (_settings.lastPage.isNotEmpty) {
          pageInputCtrl.text = _settings.lastPage;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/quran_settings.json');
      _settings.lastPage = provider.currentPageNumber;
      await file.writeAsString(jsonEncode(_settings.toJson()));
    } catch (_) {}
  }

  void _applySettings() {
    if (_settings.keepAwake) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ));
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {});
    _saveSettings();
  }

  Future<void> loadPage(String pageNumber) async {
    if (pageNumber.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = <Future>[
        dataService.getImageBytes(pageNumber),
        dataService.getAnnotationBytes(pageNumber),
      ];
      final results = await Future.wait(futures);
      final imgBytes = results[0] as Uint8List;
      final annotBytes = results[1] as Uint8List;

      await provider.loadImageFromBytes(imgBytes, pageNumber);

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0);
      }
      _scrollOffset = 0;
      _saveSettings();

      final data = XlsxReader.readXlsxFromBytes(annotBytes);

      final mots = data['Mots'] ?? [];
      final hLines = data['Horizontales'] ?? [];
      final vLines = data['Verticales'] ?? [];

      for (final h in hLines) {
        final y = (h['y'] as num?)?.toDouble() ?? 0;
        provider.addHLine(y);
      }

      for (final v in vLines) {
        final x = (v['x'] as num?)?.toDouble() ?? 0;
        final top = (v['top'] as num?)?.toDouble() ?? 0;
        final bottom = (v['bottom'] as num?)?.toDouble() ?? 0;
        provider.addVLine(x, top, bottom);
      }

      for (final m in mots) {
        final x1 = (m['x1'] as num?)?.toDouble() ?? 0;
        final y1 = (m['y1'] as num?)?.toDouble() ?? 0;
        final x2 = (m['x2'] as num?)?.toDouble() ?? 0;
        final y2 = (m['y2'] as num?)?.toDouble() ?? 0;
        if (x2 > x1 && y2 > y1) {
          provider.addWordAtRect(x1, y1, x2, y2);
        }
      }

    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _computeScale(double viewW, double viewH) {
    if (provider.image == null) return 1.0;
    final imgW = provider.image!.width.toDouble();
    final imgH = provider.image!.height.toDouble();
    final scaleX = viewW / imgW;
    final scaleY = viewH / imgH;
    if (_isLandscape && !_settings.landscapeFit) return scaleX;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  Offset _screenToImagePos(Offset screenPos) {
    if (provider.image == null) return screenPos;
    final viewW = _lastW;
    final viewH = _lastH;
    if (viewW <= 0 || viewH <= 0) return screenPos;
    final scale = _computeScale(viewW, viewH);
    final imgW = provider.image!.width.toDouble();
    final imgH = provider.image!.height.toDouble();
    final contentW = imgW * scale;
    final contentH = imgH * scale;

    if (_isLandscape && !_settings.landscapeFit) {
      return Offset(
        screenPos.dx / scale,
        (screenPos.dy + _scrollOffset) / scale,
      );
    }

    final offsetX = (viewW - contentW) / 2;
    final offsetY = (viewH - contentH) / 2;
    return Offset(
      (screenPos.dx - offsetX) / scale,
      (screenPos.dy - offsetY) / scale,
    );
  }

  void _onLongPress(Offset localPos) {
    if (provider.image == null) return;
    final imgPos = _screenToImagePos(localPos);
    final hit = provider.hitTest(imgPos);
    if (hit != null) {
      provider.trySelectElement(imgPos);
      if (_settings.vibrateOnWord) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _navigatePage(int delta) {
    if (_isLandscape && !_settings.landscapeFit) return;
    final current = provider.currentPageNumber;
    final p = int.tryParse(current);
    if (p == null) return;
    final next = p + delta;
    if (next < 1) return;
    pageInputCtrl.text = '$next';
    loadPage('$next');
  }

  void _submitPage(String v) {
    if (v.trim().isNotEmpty) {
      pageInputCtrl.text = v.trim();
      loadPage(v.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _settings.darkBg ? Colors.black : Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: _buildImageViewer(),
            ),
          ),
          if (_settings.showPageNumOnImage && provider.currentPageNumber.isNotEmpty)
            Positioned(
              top: 8, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${provider.currentPageNumber}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          if (_showOverlay) _buildOverlay(),
          if (provider.image == null || _showOverlay) _buildPageInput(),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFD4A843))),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              top: 16, left: 16, right: 16,
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
    );
  }

  Widget _buildPageInput() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 8,
      left: 40, right: 40,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xBB1A1A2E),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.auto_stories, color: Color(0xFFD4A843), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: pageInputCtrl,
                  focusNode: pageInputFocus,
                  decoration: const InputDecoration(
                    hintText: 'رقم الصفحة',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: _submitPage,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFFD4A843), size: 20),
                onPressed: () => _submitPage(pageInputCtrl.text),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    final currentPage = provider.currentPageNumber;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: const Color(0x99000000),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4, bottom: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFFD4A843), size: 28),
              onPressed: _isLandscape && !_settings.landscapeFit ? null : () => _navigatePage(-1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const Icon(Icons.auto_stories, color: Color(0xFFD4A843), size: 18),
            const SizedBox(width: 6),
            const Text('القرآن الكريم',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (currentPage.isNotEmpty)
              Text('صفحة $currentPage',
                  style: const TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white54, size: 20),
              onPressed: _showSettings,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFFD4A843), size: 28),
              onPressed: _isLandscape && !_settings.landscapeFit ? null : () => _navigatePage(1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('الإعدادات', style: TextStyle(color: Color(0xFFD4A843), fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white12),
                _switchTile(ctx, setSheetState, 'إظهار مربعات الكلمات', Icons.text_fields, _settings.showWordBoxes, (v) { _settings.showWordBoxes = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'إظهار الخطوط الأفقية', Icons.horizontal_rule, _settings.showHLines, (v) { _settings.showHLines = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'إظهار الخطوط العمودية', Icons.vertical_align_center, _settings.showVLines, (v) { _settings.showVLines = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'خطوط عريضة', Icons.line_weight, _settings.boldBorders, (v) { _settings.boldBorders = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'إظهار الكلمات المخفية', Icons.visibility_off, _settings.showHiddenWords, (v) { _settings.showHiddenWords = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'اهتزاز عند الضغط', Icons.vibration, _settings.vibrateOnWord, (v) { _settings.vibrateOnWord = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'خلفية داكنة', Icons.dark_mode, _settings.darkBg, (v) { _settings.darkBg = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'مناسب للعرض في الأفقي', Icons.aspect_ratio, _settings.landscapeFit, (v) { _settings.landscapeFit = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'التقاط إلى الشبكة', Icons.grid_view, _settings.snapToGrid, (v) { _settings.snapToGrid = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'رقم الصفحة فوق الصورة', Icons.numbers, _settings.showPageNumOnImage, (v) { _settings.showPageNumOnImage = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'تشغيل الصوت تلقائياً', Icons.music_note, _settings.autoLoadAudio, (v) { _settings.autoLoadAudio = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, 'إبقاء الشاشة مضاءة', Icons.lightbulb, _settings.keepAwake, (v) { _settings.keepAwake = v; _applySettings(); }),
                const Divider(color: Colors.white12),
                _sliderTile(ctx, setSheetState, 'سمك الحدود', '${_settings.borderWidth}', _settings.borderWidth.toDouble(), 0, 6, (v) { _settings.borderWidth = v.round(); _applySettings(); }),
                _sliderTile(ctx, setSheetState, 'حساسية السحب', '${_settings.swipeThreshold.toInt()}px', _settings.swipeThreshold, 20, 150, (v) { _settings.swipeThreshold = v; _applySettings(); }),
                _sliderTile(ctx, setSheetState, 'مدة الإخفاء', '${_settings.overlayTimeoutSec}ث', _settings.overlayTimeoutSec.toDouble(), 1, 10, (v) { _settings.overlayTimeoutSec = v.round(); _applySettings(); }),
                _sliderTile(ctx, setSheetState, 'شفافية التحديد', '${(_settings.highlightOpacity * 100).round()}%', _settings.highlightOpacity * 100, 5, 50, (v) { _settings.highlightOpacity = v / 100; _applySettings(); }),
                const Divider(color: Colors.white12),
                _colorPickerTile(ctx, setSheetState, 'لون التحديد', _settings.highlightColor, (v) { _settings.highlightColor = v; _applySettings(); }),
                const Divider(color: Colors.white12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextButton.icon(
                    onPressed: () async {
                      final dir = await getApplicationDocumentsDirectory();
                      final cache = Directory('${dir.path}/quran_cache');
                      if (await cache.exists()) {
                        await cache.delete(recursive: true);
                      }
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('تم مسح الذاكرة المؤقتة')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                    label: const Text('مسح الذاكرة المؤقتة', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile(BuildContext ctx, void Function(void Function()) setSheetState, String label, IconData icon, bool value, void Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4A843), size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: Switch(
          value: value,
          activeColor: const Color(0xFFD4A843),
          onChanged: (v) { onChange(v); setSheetState(() {}); },
        ),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _sliderTile(BuildContext ctx, void Function(void Function()) setSheetState, String label, String display, double value, double min, double max, void Function(double) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFFD4A843), size: 16),
              const SizedBox(width: 8),
              Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(display, style: const TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFFD4A843),
            inactiveColor: Colors.white12,
            onChanged: (v) { onChange(v); setSheetState(() {}); },
          ),
        ],
      ),
    );
  }

  Widget _colorPickerTile(BuildContext ctx, void Function(void Function()) setSheetState, String label, String current, void Function(String) onChange) {
    final colors = ['yellow', 'red', 'green', 'blue', 'orange', 'pink'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette, color: Color(0xFFD4A843), size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: colors.map((c) {
              final color = _colorFromName(c);
              return GestureDetector(
                onTap: () { onChange(c); setSheetState(() {}); },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: current == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'pink': return Colors.pink;
      default: return Colors.yellow;
    }
  }

  Widget _buildImageViewer() {
    return Listener(
      onPointerDown: (event) {
        _pointerCount++;
        if (_pointerCount == 1 && provider.image != null) {
          _dragStartX = event.position.dx;
          _dragStartTime = DateTime.now().millisecondsSinceEpoch;
        }
      },
      onPointerUp: (event) {
        _pointerCount--;
        if (!_isLandscape &&
            _dragStartX != null && _dragStartTime != null && provider.image != null) {
          final dx = event.position.dx - _dragStartX!;
          final dt = DateTime.now().millisecondsSinceEpoch - _dragStartTime!;
          if (dx.abs() > _settings.swipeThreshold && dt < 400) {
            _navigatePage(dx < 0 ? 1 : -1);
          }
        }
        _dragStartX = null;
        _dragStartTime = null;
      },
      onPointerCancel: (event) {
        _pointerCount = 0;
        _dragStartX = null;
        _dragStartTime = null;
      },
      child: GestureDetector(
        onTapUp: (_) {
          setState(() {
            _showOverlay = !_showOverlay;
            if (_showOverlay && _settings.overlayTimeoutSec > 0) {
              _overlayTimer?.cancel();
              _overlayTimer = Timer(Duration(seconds: _settings.overlayTimeoutSec), () {
                if (mounted) setState(() => _showOverlay = false);
              });
            } else {
              _overlayTimer?.cancel();
            }
          });
        },
        onLongPressStart: (details) => _onLongPress(details.localPosition),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _lastW = constraints.maxWidth;
            _lastH = constraints.maxHeight;
            _isLandscape = _lastW > _lastH;

            if (provider.image == null) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A843)));
              }
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories, size: 60, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('اكتب رقم الصفحة بالأسفل',
                        style: TextStyle(color: Colors.white38, fontSize: 16)),
                  ],
                ),
              );
            }

            final scale = _computeScale(_lastW, _lastH);
            final imgW = provider.image!.width.toDouble();
            final imgH = provider.image!.height.toDouble();
            final displayW = imgW * scale;
            final displayH = imgH * scale;

            debugPrint('QURAN_DEBUG: showHLines=${_settings.showHLines} showVLines=${_settings.showVLines} borderWidth=${_settings.borderWidth} showWords=${_settings.showWordBoxes} scale=$scale imgW=$imgW imgH=$imgH');

            final content = SizedBox(
              width: displayW,
              height: displayH,
              child: CustomPaint(
                painter: AnnotationPainter(
                  image: provider.image,
                  hLines: provider.hLines,
                  vLines: provider.vLines,
                  words: provider.words,
                  borderWidth: _settings.boldBorders ? _settings.borderWidth + 2 : _settings.borderWidth,
                  showWords: _settings.showWordBoxes,
                  showHLines: _settings.showHLines,
                  showVLines: _settings.showVLines,
                  showHiddenWords: _settings.showHiddenWords,
                  selectedElement: provider.selectedElement,
                  displayScale: scale,
                  highlightColor: _settings.highlightPaintColor,
                  highlightOpacity: _settings.highlightOpacity,
                ),
              ),
            );

            if (_isLandscape && !_settings.landscapeFit) {
              return SingleChildScrollView(
                controller: _scrollCtrl,
                scrollDirection: Axis.vertical,
                child: content,
              );
            }

            return Center(child: content);
          },
        ),
      ),
    );
  }
}
