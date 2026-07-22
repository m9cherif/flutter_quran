import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/annotation_provider.dart';
import '../services/xlsx_reader.dart';
import '../services/audio_manager.dart';
import 'package:flutter_quran/l10n/app_localizations.dart';
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
  double brightness = 1.0;
  String lastPage = '';
  int minScale = 50;
  int maxScale = 300;
  bool showPageNumOnImage = false;
  bool autoLoadAudio = false;
  bool hideSystemUI = true;
  int pageNumSize = 16;
  bool pageNumBg = true;
  String pageNumColor = 'white';
  bool invertColors = false;
  int autoScrollInterval = 0;
  bool showZoomButtons = false;
  bool smoothTransition = true;
  bool doubleTapZoom = false;
  bool memoryMode = false;
  bool showWordCount = false;
  int imageCornerRadius = 0;
  bool showPageBorder = false;
  bool lockOrientation = false;
  bool boldPageNum = false;
  int pageNumOffset = 0;
  String language = 'ar';
  bool tapZones = false;
  bool showProgressBar = false;
  bool swipeNavigation = true;
  bool alwaysShowPageInput = false;

  Color get pageNumPaintColor {
    switch (pageNumColor) {
      case 'red': return Colors.red;
      case 'yellow': return Colors.yellow;
      case 'black': return Colors.black;
      case 'gold': return Color(0xFFD4A843);
      default: return Colors.white;
    }
  }

  bool get effectiveLockOrientation => lockOrientation;

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
    'brightness': brightness,
    'lastPage': lastPage,
    'minScale': minScale,
    'maxScale': maxScale,
    'showPageNumOnImage': showPageNumOnImage,
    'autoLoadAudio': autoLoadAudio,
    'hideSystemUI': hideSystemUI,
    'pageNumSize': pageNumSize,
    'pageNumBg': pageNumBg,
    'pageNumColor': pageNumColor,
    'invertColors': invertColors,
    'autoScrollInterval': autoScrollInterval,
    'showZoomButtons': showZoomButtons,
    'smoothTransition': smoothTransition,
    'doubleTapZoom': doubleTapZoom,
    'memoryMode': memoryMode,
    'showWordCount': showWordCount,
    'imageCornerRadius': imageCornerRadius,
    'showPageBorder': showPageBorder,
    'lockOrientation': lockOrientation,
    'boldPageNum': boldPageNum,
    'pageNumOffset': pageNumOffset,
    'language': language,
    'tapZones': tapZones,
    'showProgressBar': showProgressBar,
    'swipeNavigation': swipeNavigation,
    'alwaysShowPageInput': alwaysShowPageInput,
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
    brightness = (json['brightness'] as num?)?.toDouble() ?? 1.0;
    autoLoadAudio = json['autoLoadAudio'] as bool? ?? false;
    hideSystemUI = json['hideSystemUI'] as bool? ?? true;
    pageNumSize = json['pageNumSize'] as int? ?? 16;
    pageNumBg = json['pageNumBg'] as bool? ?? true;
    pageNumColor = json['pageNumColor'] as String? ?? 'white';
    invertColors = json['invertColors'] as bool? ?? false;
    autoScrollInterval = json['autoScrollInterval'] as int? ?? 0;
    showZoomButtons = json['showZoomButtons'] as bool? ?? false;
    smoothTransition = json['smoothTransition'] as bool? ?? true;
    doubleTapZoom = json['doubleTapZoom'] as bool? ?? false;
    memoryMode = json['memoryMode'] as bool? ?? false;
    showWordCount = json['showWordCount'] as bool? ?? false;
    imageCornerRadius = json['imageCornerRadius'] as int? ?? 0;
    showPageBorder = json['showPageBorder'] as bool? ?? false;
    lockOrientation = json['lockOrientation'] as bool? ?? false;
    boldPageNum = json['boldPageNum'] as bool? ?? false;
    pageNumOffset = json['pageNumOffset'] as int? ?? 0;
    language = json['language'] as String? ?? 'ar';
    tapZones = json['tapZones'] as bool? ?? false;
    showProgressBar = json['showProgressBar'] as bool? ?? false;
    swipeNavigation = json['swipeNavigation'] as bool? ?? true;
    alwaysShowPageInput = json['alwaysShowPageInput'] as bool? ?? false;
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
  Timer? _autoScrollTimer;
  bool _isLandscape = false;
  double _zoomMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings();
    _loadSettings().then((_) => _applySettings());
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
    _autoScrollTimer?.cancel();
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
    if (_settings.hideSystemUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ));
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _updateAutoScroll();
    if (_settings.lockOrientation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() {});
    _saveSettings();
  }

  void _updateAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (_settings.autoScrollInterval > 0 && provider.image != null) {
      _autoScrollTimer = Timer.periodic(Duration(seconds: _settings.autoScrollInterval), (_) {
        if (mounted) _navigatePage(1);
      });
    }
  }

  Future<void> loadPage(String pageNumber) async {
    if (pageNumber.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _zoomMultiplier = 1.0;
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

      _updateAutoScroll();

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
    return (scaleX < scaleY ? scaleX : scaleY) * _zoomMultiplier;
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
              decoration: BoxDecoration(
                color: _settings.darkBg ? Colors.black : Colors.white,
                borderRadius: _settings.imageCornerRadius > 0
                    ? BorderRadius.circular(_settings.imageCornerRadius.toDouble())
                    : null,
                border: _settings.showPageBorder
                    ? Border.all(color: const Color(0xFFD4A843), width: 2)
                    : null,
              ),
              clipBehavior: _settings.imageCornerRadius > 0 && _zoomMultiplier <= 1.0 ? Clip.antiAlias : Clip.none,
              child: _buildImageViewer(),
            ),
          ),
          if (_settings.showPageNumOnImage && provider.currentPageNumber.isNotEmpty)
            Positioned(
              bottom: 8 + _settings.pageNumOffset.toDouble(), left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: _settings.pageNumBg
                      ? BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Text(
                    '${provider.currentPageNumber}',
                    style: TextStyle(
                      color: _settings.pageNumPaintColor,
                      fontSize: _settings.pageNumSize.toDouble(),
                      fontWeight: _settings.boldPageNum ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          if (_settings.showWordCount && provider.words.isNotEmpty)
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${provider.words.length} ${tr(_settings.language, 'words')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          if (_settings.brightness < 1.0)
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withAlpha(((1.0 - _settings.brightness) * 255).round())),
            ),
          if (_settings.showProgressBar && provider.currentPageNumber.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 2,
                color: const Color(0xFFD4A843).withAlpha(100),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ((int.tryParse(provider.currentPageNumber) ?? 1) / 604).clamp(0.0, 1.0),
                    child: Container(color: const Color(0xFFD4A843)),
                  ),
                ),
              ),
            ),
          if (_showOverlay) _buildOverlay(),
          if (provider.image == null || _showOverlay || _settings.alwaysShowPageInput) _buildPageInput(),
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
                  decoration: InputDecoration(
                    hintText: tr(_settings.language, 'pageNumber'),
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
            Text(tr(_settings.language, 'quran'),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (currentPage.isNotEmpty)
              Text('${tr(_settings.language, 'page')} $currentPage',
                  style: const TextStyle(color: Color(0xFFD4A843), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            if (_settings.showZoomButtons) ...[
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white54, size: 20),
                onPressed: () => setState(() => _zoomMultiplier = (_zoomMultiplier - 0.25).clamp(0.5, 3.0)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Text('${(_zoomMultiplier * 100).round()}%',
                  style: const TextStyle(color: Color(0xFFD4A843), fontSize: 11)),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white54, size: 20),
                onPressed: () => setState(() => _zoomMultiplier = (_zoomMultiplier + 0.25).clamp(0.5, 3.0)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              if (_zoomMultiplier != 1.0)
                IconButton(
                  icon: const Icon(Icons.zoom_out_map, color: Color(0xFFD4A843), size: 18),
                  onPressed: () => setState(() => _zoomMultiplier = 1.0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
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
                Text(tr(_settings.language, 'settings'), style: const TextStyle(color: Color(0xFFD4A843), fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white12),
                _sectionHeader(tr(_settings.language, 'display')),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showWordBoxes'), Icons.text_fields, _settings.showWordBoxes, (v) { _settings.showWordBoxes = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showHLines'), Icons.horizontal_rule, _settings.showHLines, (v) { _settings.showHLines = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showVLines'), Icons.vertical_align_center, _settings.showVLines, (v) { _settings.showVLines = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'boldBorders'), Icons.line_weight, _settings.boldBorders, (v) { _settings.boldBorders = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showHiddenWords'), Icons.visibility_off, _settings.showHiddenWords, (v) { _settings.showHiddenWords = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'memoryMode'), Icons.school, _settings.memoryMode, (v) { _settings.memoryMode = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'invertColors'), Icons.invert_colors, _settings.invertColors, (v) { _settings.invertColors = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showPageBorder'), Icons.border_all, _settings.showPageBorder, (v) { _settings.showPageBorder = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'landscapeFit'), Icons.aspect_ratio, _settings.landscapeFit, (v) { _settings.landscapeFit = v; _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'borderWidth'), '${_settings.borderWidth}', _settings.borderWidth.toDouble(), 0, 6, (v) { _settings.borderWidth = v.round(); _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'imageCornerRadius'), '${_settings.imageCornerRadius}', _settings.imageCornerRadius.toDouble(), 0, 30, (v) { _settings.imageCornerRadius = v.round(); _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'highlightOpacity'), '${(_settings.highlightOpacity * 100).round()}%', _settings.highlightOpacity * 100, 5, 50, (v) { _settings.highlightOpacity = v / 100; _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'brightness'), '${(_settings.brightness * 100).round()}%', _settings.brightness * 100, 30, 100, (v) { _settings.brightness = v / 100; _applySettings(); }),
                const Divider(color: Colors.white12),
                _sectionHeader(tr(_settings.language, 'pageSettings')),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showPageNumOnImage'), Icons.numbers, _settings.showPageNumOnImage, (v) { _settings.showPageNumOnImage = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'pageNumBg'), Icons.sticky_note_2, _settings.pageNumBg, (v) { _settings.pageNumBg = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'boldPageNum'), Icons.format_bold, _settings.boldPageNum, (v) { _settings.boldPageNum = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showWordCount'), Icons.format_list_numbered, _settings.showWordCount, (v) { _settings.showWordCount = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showZoomButtons'), Icons.zoom_in, _settings.showZoomButtons, (v) { _settings.showZoomButtons = v; _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'pageNumSize'), '${_settings.pageNumSize}', _settings.pageNumSize.toDouble(), 10, 48, (v) { _settings.pageNumSize = v.round(); _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'pageNumOffset'), '${_settings.pageNumOffset}', _settings.pageNumOffset.toDouble(), 0, 50, (v) { _settings.pageNumOffset = v.round(); _applySettings(); }),
                _colorPickerTile(ctx, setSheetState, tr(_settings.language, 'pageNumColor'), _settings.pageNumColor, (v) { _settings.pageNumColor = v; _applySettings(); }),
                const Divider(color: Colors.white12),
                _sectionHeader(tr(_settings.language, 'navigation')),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'swipeNavigation'), Icons.swipe, _settings.swipeNavigation, (v) { _settings.swipeNavigation = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'tapZones'), Icons.touch_app, _settings.tapZones, (v) { _settings.tapZones = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'doubleTapZoom'), Icons.zoom_in_map, _settings.doubleTapZoom, (v) { _settings.doubleTapZoom = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'smoothTransition'), Icons.animation, _settings.smoothTransition, (v) { _settings.smoothTransition = v; _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'swipeThreshold'), '${_settings.swipeThreshold.toInt()}px', _settings.swipeThreshold, 20, 150, (v) { _settings.swipeThreshold = v; _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'overlayTimeoutSec'), '${_settings.overlayTimeoutSec}${tr(_settings.language, 'sec')}', _settings.overlayTimeoutSec.toDouble(), 1, 10, (v) { _settings.overlayTimeoutSec = v.round(); _applySettings(); }),
                _sliderTile(ctx, setSheetState, tr(_settings.language, 'autoScrollInterval'), _settings.autoScrollInterval > 0 ? '${tr(_settings.language, 'every')} ${_settings.autoScrollInterval}${tr(_settings.language, 'sec')}' : tr(_settings.language, 'disabled'), _settings.autoScrollInterval.toDouble(), 0, 30, (v) { _settings.autoScrollInterval = v.round(); _applySettings(); }),
                const Divider(color: Colors.white12),
                _sectionHeader(tr(_settings.language, 'audio')),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'autoLoadAudio'), Icons.music_note, _settings.autoLoadAudio, (v) { _settings.autoLoadAudio = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'vibrateOnWord'), Icons.vibration, _settings.vibrateOnWord, (v) { _settings.vibrateOnWord = v; _applySettings(); }),
                const Divider(color: Colors.white12),
                _sectionHeader(tr(_settings.language, 'other')),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'darkBg'), Icons.dark_mode, _settings.darkBg, (v) { _settings.darkBg = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'hideSystemUI'), Icons.notifications_off, _settings.hideSystemUI, (v) { _settings.hideSystemUI = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'lockOrientation'), Icons.screen_lock_portrait, _settings.lockOrientation, (v) { _settings.lockOrientation = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'keepAwake'), Icons.lightbulb, _settings.keepAwake, (v) { _settings.keepAwake = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'snapToGrid'), Icons.grid_view, _settings.snapToGrid, (v) { _settings.snapToGrid = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'showProgressBar'), Icons.show_chart, _settings.showProgressBar, (v) { _settings.showProgressBar = v; _applySettings(); }),
                _switchTile(ctx, setSheetState, tr(_settings.language, 'alwaysShowPageInput'), Icons.keyboard, _settings.alwaysShowPageInput, (v) { _settings.alwaysShowPageInput = v; _applySettings(); }),
                _colorPickerTile(ctx, setSheetState, tr(_settings.language, 'highlightColor'), _settings.highlightColor, (v) { _settings.highlightColor = v; _applySettings(); }),
                const Divider(color: Colors.white12),
                _languageTile(ctx, setSheetState),
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
                          SnackBar(content: Text(tr(_settings.language, 'cacheCleared'))),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                    label: Text(tr(_settings.language, 'clearCache'), style: const TextStyle(color: Colors.redAccent)),
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(title, style: const TextStyle(color: Color(0xFFD4A843), fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _languageTile(BuildContext ctx, void Function(void Function()) setSheetState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: const Icon(Icons.language, color: Color(0xFFD4A843), size: 20),
        title: Text(tr(_settings.language, 'language'), style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'ar', label: Text(tr(_settings.language, 'arabic'), style: const TextStyle(fontSize: 12))),
            ButtonSegment(value: 'en', label: Text(tr(_settings.language, 'english'), style: const TextStyle(fontSize: 12))),
          ],
          selected: {_settings.language},
          onSelectionChanged: (v) {
            _settings.language = v.first;
            _applySettings();
            setSheetState(() {});
          },
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
        if (_settings.swipeNavigation && !_isLandscape &&
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
          onDoubleTap: _settings.doubleTapZoom ? () {
            setState(() {
              _zoomMultiplier = _zoomMultiplier == 1.0 ? 2.0 : 1.0;
            });
          } : null,
          onTapUp: (details) {
          provider.selectAnnotation(null);
          if (_settings.tapZones && provider.image != null && _lastW > 0) {
            final x = details.localPosition.dx;
            if (x < _lastW / 3) {
              _navigatePage(-1);
              return;
            } else if (x > _lastW * 2 / 3) {
              _navigatePage(1);
              return;
            }
          }
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
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_stories, size: 60, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(tr(_settings.language, 'enterPageNumber'),
                        style: const TextStyle(color: Colors.white38, fontSize: 16)),
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

            Widget imageContent = SizedBox(
              width: displayW,
              height: displayH,
              child: CustomPaint(
                painter: AnnotationPainter(
                  image: provider.image,
                  hLines: provider.hLines,
                  vLines: provider.vLines,
                  words: provider.words,
                  borderWidth: _settings.boldBorders ? _settings.borderWidth + 2 : _settings.borderWidth,
                  showWords: _settings.memoryMode ? false : _settings.showWordBoxes,
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

            if (_settings.invertColors) {
              imageContent = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  -1, 0, 0, 0, 255,
                  0, -1, 0, 0, 255,
                  0, 0, -1, 0, 255,
                  0, 0, 0, 1, 0,
                ]),
                child: imageContent,
              );
            }

            final content = KeyedSubtree(
              key: ValueKey(provider.currentPageNumber),
              child: imageContent,
            );

            Widget imageWidget;
            if (_isLandscape && !_settings.landscapeFit) {
              imageWidget = SingleChildScrollView(
                controller: _scrollCtrl,
                scrollDirection: Axis.vertical,
                child: content,
              );
            } else {
              imageWidget = Center(child: content);
            }

            Widget result = imageWidget;

            if (_settings.smoothTransition) {
              result = AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: result,
              );
            }
            return result;
          },
        ),
      ),
    );
  }
}
