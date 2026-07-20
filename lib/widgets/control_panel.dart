import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/annotation.dart';
import '../providers/annotation_provider.dart';
import '../services/audio_manager.dart';

class ControlPanel extends StatefulWidget {
  final AnnotationProvider provider;
  final AudioManager audioManager;
  final VoidCallback onLoadImage;
  final VoidCallback onImportExcel;
  final VoidCallback onExportExcel;
  final VoidCallback onExportMaskedImage;
  final VoidCallback onClose;
  final TextEditingController pageInputCtrl;
  final FocusNode pageInputFocus;

  const ControlPanel({
    super.key,
    required this.provider,
    required this.audioManager,
    required this.onLoadImage,
    required this.onImportExcel,
    required this.onExportExcel,
    required this.onExportMaskedImage,
    required this.onClose,
    required this.pageInputCtrl,
    required this.pageInputFocus,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  @override
  void initState() {
    super.initState();
    widget.audioManager.positionNotifier.addListener(_onAudioChange);
    widget.audioManager.durationNotifier.addListener(_onAudioChange);
  }

  @override
  void dispose() {
    widget.audioManager.positionNotifier.removeListener(_onAudioChange);
    widget.audioManager.durationNotifier.removeListener(_onAudioChange);
    super.dispose();
  }

  void _onAudioChange() {
    if (mounted) setState(() {});
  }

  AnnotationProvider get p => widget.provider;
  AudioManager get a => widget.audioManager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageLoader(theme),
                const SizedBox(height: 12),
                _buildAnnotationsList(theme),
                const SizedBox(height: 12),
                _buildActionButtons(theme),
                const SizedBox(height: 12),
                _buildWordControls(theme),
                const SizedBox(height: 12),
                _buildBorderSlider(theme),
                const SizedBox(height: 12),
                _buildVisibilityButtons(theme),
                const SizedBox(height: 12),
                _buildImportExportButtons(theme),
                const SizedBox(height: 8),
                _buildExportMaskedButton(theme),
                const SizedBox(height: 12),
                _buildAudioSection(theme),
                const SizedBox(height: 12),
                _buildTimelineSection(theme),
                const SizedBox(height: 12),
                _buildCounters(theme),
                const SizedBox(height: 8),
                _buildStatus(theme),
                const SizedBox(height: 12),
                _buildCloseButton(theme),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withAlpha(30),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            'تحديد الكلمات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageLoader(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('رقم الصفحة', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: widget.pageInputCtrl,
              focusNode: widget.pageInputFocus,
              decoration: InputDecoration(
                hintText: 'أدخل رقم الصفحة',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: theme.colorScheme.primary),
                  onPressed: widget.onLoadImage,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => widget.onLoadImage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التعليقات', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          height: 160,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withAlpha(80)),
            ),
            child: ListView.builder(
              key: ValueKey('list_${p.words.length}'),
              itemCount: _getAllAnnotations().length,
              itemBuilder: (context, index) {
                final item = _getAllAnnotations()[index];
                return _buildAnnotationItem(item, theme);
              },
            ),
          ),
        ),
      ],
    );
  }

  List<dynamic> _getAllAnnotations() {
    final items = <dynamic>[];
    for (var h in p.hLines) {
      items.add(h);
    }
    for (var v in p.vLines) {
      items.add(v);
    }
    for (var w in p.getSortedWords()) {
      items.add(w);
    }
    return items;
  }

  Widget _buildAnnotationItem(dynamic item, ThemeData theme) {
    final isSelected = p.selectedElement == item;
    String text;
    if (item is HLine) {
      text = 'H : y=${item.y.toStringAsFixed(1)}';
    } else if (item is VLine) {
      text = 'V : x=${item.x.toStringAsFixed(1)}';
    } else if (item is Word) {
      final prefix = item.hidden ? '[مخفي] ' : '';
      text = '$prefixكلمة #${item.id} : (${item.x1.toStringAsFixed(1)}, ${item.y1.toStringAsFixed(1)})';
    } else {
      text = '';
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.amber.withAlpha(40)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => p.selectAnnotation(item),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.amber : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: [
        _styledButton(
          icon: Icons.delete_outline, label: 'حذف', shortcut: 'Del',
          color: Colors.red.shade300,
          onPressed: p.selectedElement != null ? p.deleteSelected : null, theme: theme,
        ),
        _styledButton(
          icon: Icons.open_with, label: 'نقل', shortcut: 'M',
          color: p.moveMode ? Colors.amber : null,
          onPressed: p.selectedElement != null ? () => p.toggleMoveMode() : null, theme: theme,
        ),
        _styledButton(
          icon: Icons.cancel_outlined, label: 'إلغاء', shortcut: 'Esc',
          onPressed: p.cancelMove, theme: theme,
        ),
      ],
    );
  }

  Widget _buildWordControls(ThemeData theme) {
    final checked = p.showWords;
    return Tooltip(
      message: 'إظهار/إخفاء الكلمات (Ctrl+Maj+W)',
      child: Material(
        color: checked ? theme.colorScheme.primary.withAlpha(40) : theme.disabledColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: p.toggleWordsVisibility,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(checked ? Icons.visibility : Icons.visibility_off, size: 18,
                  color: checked ? theme.colorScheme.primary : theme.disabledColor),
                const SizedBox(width: 6),
                Text('كلمات', style: TextStyle(fontSize: 13,
                  fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                  color: checked ? theme.colorScheme.primary : theme.disabledColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBorderSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('سمك الإطار: ${p.borderWidth}', style: theme.textTheme.labelSmall),
        Slider(
          value: p.borderWidth.toDouble(), min: 0, max: 3, divisions: 3,
          activeColor: theme.colorScheme.primary,
          onChanged: (v) => p.setBorderWidth(v.toInt()),
        ),
      ],
    );
  }

  Widget _buildVisibilityButtons(ThemeData theme) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: [
        _styledButton(icon: Icons.check_circle_outline, label: 'إظهار الكل', shortcut: 'A',
          onPressed: p.showAllWords, theme: theme),
        _styledButton(icon: Icons.cancel_outlined, label: 'إخفاء الكل', shortcut: 'C',
          onPressed: p.hideAllWords, theme: theme),
        _styledButton(icon: Icons.swap_horiz, label: 'تبديل', shortcut: 'T',
          onPressed: p.selectedElement is Word ? p.toggleSelectedWordVisibility : null, theme: theme),
      ],
    );
  }

  Widget _buildImportExportButtons(ThemeData theme) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: [
        _styledButton(icon: Icons.file_upload_outlined, label: 'استيراد', shortcut: 'Ctrl+I',
          onPressed: widget.onImportExcel, theme: theme),
        _styledButton(icon: Icons.file_download_outlined, label: 'تصدير', shortcut: 'Ctrl+E',
          onPressed: widget.onExportExcel, theme: theme),
      ],
    );
  }

  Widget _buildCounters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('H: ${p.hLines.length} | V: ${p.vLines.length} | كلمات: ${p.words.length}',
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatus(ThemeData theme) {
    String status = '';
    if (p.moveMode) {
      status = 'وضع النقل: انقر على الصورة';
    } else if (p.selectedElement != null) {
      status = 'تم التحديد';
    } else {
      status = 'انقر لإضافة كلمة';
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(status,
        key: ValueKey(status),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExportMaskedButton(ThemeData theme) {
    return _styledButton(
      icon: Icons.image_outlined, label: 'تصدير الصورة المعالجة', shortcut: 'Ctrl+Maj+E',
      onPressed: widget.onExportMaskedImage, theme: theme, fullWidth: true,
    );
  }

  Widget _buildAudioSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.music_note, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('الصوت', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(a.timeDisplay, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: a.durationNotifier.value > 0
                    ? (a.positionNotifier.value / a.durationNotifier.value).clamp(0.0, 1.0)
                    : 0,
                min: 0, max: 1,
                activeColor: theme.colorScheme.primary,
                onChanged: (v) {
                  final pos = (v * a.durationNotifier.value).toInt();
                  a.onSliderReleased(pos);
                },
                onChangeStart: (_) => a.onSliderPressed(),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4, runSpacing: 4,
              children: [
                _styledButton(icon: Icons.folder_open, label: 'تحميل', shortcut: '',
                  onPressed: () => a.loadAudioFile(), theme: theme),
                _styledButton(
                  icon: a.isPlayingNotifier.value ? Icons.pause : Icons.play_arrow,
                  label: a.isPlayingNotifier.value ? 'إيقاف مؤقت' : 'تشغيل',
                  shortcut: 'Space',
                  onPressed: () => a.toggleAudioPlay(), theme: theme),
                _styledButton(icon: Icons.stop, label: 'إيقاف', shortcut: '',
                  onPressed: () => a.stopAudio(), theme: theme),
              ],
            ),
            const SizedBox(height: 4),
            Text(a.statusNotifier.value,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.tertiaryContainer.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text('الخط الزمني', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (a.timelineEventCount.value > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${a.timelineEventCount.value}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4, runSpacing: 4,
              children: [
                _styledButton(
                  icon: a.isRecordingNotifier.value ? Icons.stop_circle : Icons.fiber_manual_record,
                  label: a.isRecordingNotifier.value ? 'إيقاف التسجيل' : 'تسجيل',
                  color: a.isRecordingNotifier.value ? Colors.red : null,
                  shortcut: 'R',
                    onPressed: () {
                      if (a.recording) {
                        a.stopRecording();
                      } else {
                        a.startRecording();
                      }
                    }, theme: theme),
                _styledButton(
                  icon: Icons.play_circle_outline, label: 'تشغيل',
                  shortcut: 'P',
                  onPressed: () => a.togglePlayPause(), theme: theme),
                _styledButton(icon: Icons.stop, label: 'إيقاف', shortcut: '',
                  onPressed: () => a.stopPlayback(), theme: theme),
                _styledButton(icon: Icons.save, label: 'حفظ', shortcut: '',
                  onPressed: a.timeline.isNotEmpty ? () => a.saveTimeline() : null, theme: theme),
                _styledButton(icon: Icons.file_open, label: 'تحميل', shortcut: '',
                  onPressed: () => a.loadTimeline(), theme: theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(ThemeData theme) {
    return _styledButton(
      icon: Icons.close, label: 'إغلاق', shortcut: 'Ctrl+Q',
      color: Colors.red.shade300,
      onPressed: widget.onClose, theme: theme, fullWidth: true,
    );
  }

  Widget _styledButton({
    required IconData icon,
    required String label,
    String? shortcut,
    Color? color,
    VoidCallback? onPressed,
    required ThemeData theme,
    bool fullWidth = false,
  }) {
    return Tooltip(
      message: shortcut != null && shortcut.isNotEmpty ? '$label ($shortcut)' : label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: onPressed == null
              ? theme.disabledColor.withAlpha(30)
              : (color ?? theme.colorScheme.primaryContainer).withAlpha(80),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: onPressed == null ? theme.disabledColor : (color ?? theme.colorScheme.primary)),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(
                    fontSize: 12,
                    color: onPressed == null ? theme.disabledColor : (color ?? theme.colorScheme.onSurface),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
