import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/annotation.dart';
import '../providers/annotation_provider.dart';

class ControlPanel extends StatelessWidget {
  final AnnotationProvider provider;
  final VoidCallback onLoadImage;
  final VoidCallback onImportExcel;
  final VoidCallback onExportExcel;

  const ControlPanel({
    super.key,
    required this.provider,
    required this.onLoadImage,
    required this.onImportExcel,
    required this.onExportExcel,
  });

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
                const SizedBox(height: 12),
                _buildCounters(theme),
                const SizedBox(height: 8),
                _buildStatus(theme),
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
              decoration: InputDecoration(
                hintText: 'أدخل رقم الصفحة',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: theme.colorScheme.primary),
                  onPressed: onLoadImage,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => onLoadImage(),
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
              key: ValueKey('list_${provider.words.length}'),
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
    for (var h in provider.hLines) {
      items.add(h);
    }
    for (var v in provider.vLines) {
      items.add(v);
    }
    for (var w in provider.getSortedWords()) {
      items.add(w);
    }
    return items;
  }

  Widget _buildAnnotationItem(dynamic item, ThemeData theme) {
    final isSelected = provider.selectedElement == item;
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
        onTap: () {},
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
      spacing: 6,
      runSpacing: 6,
      children: [
        _styledButton(
          icon: Icons.delete_outline,
          label: 'حذف',
          shortcut: 'Del',
          color: Colors.red.shade300,
          onPressed: provider.selectedElement != null ? provider.deleteSelected : null,
          theme: theme,
        ),
        _styledButton(
          icon: Icons.open_with,
          label: 'نقل',
          shortcut: 'M',
          color: provider.moveMode ? Colors.amber : null,
          onPressed: provider.selectedElement != null ? () => provider.toggleMoveMode() : null,
          theme: theme,
        ),
        _styledButton(
          icon: Icons.cancel_outlined,
          label: 'إلغاء',
          shortcut: 'Esc',
          onPressed: provider.cancelMove,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildWordControls(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _styledButton(
            icon: provider.showWords ? Icons.visibility : Icons.visibility_off,
            label: 'كلمات',
            onPressed: provider.toggleWordsVisibility,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildBorderSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('سمك الإطار: ${provider.borderWidth}', style: theme.textTheme.labelSmall),
        Slider(
          value: provider.borderWidth.toDouble(),
          min: 0,
          max: 3,
          divisions: 3,
          activeColor: theme.colorScheme.primary,
          onChanged: (v) => provider.setBorderWidth(v.toInt()),
        ),
      ],
    );
  }

  Widget _buildVisibilityButtons(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _styledButton(
          icon: Icons.check_circle_outline,
          label: 'إظهار الكل',
          shortcut: 'A',
          onPressed: provider.showAllWords,
          theme: theme,
        ),
        _styledButton(
          icon: Icons.cancel_outlined,
          label: 'إخفاء الكل',
          shortcut: 'C',
          onPressed: provider.hideAllWords,
          theme: theme,
        ),
        _styledButton(
          icon: Icons.swap_horiz,
          label: 'تبديل',
          shortcut: 'T',
          onPressed: provider.selectedElement is Word ? provider.toggleSelectedWordVisibility : null,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildImportExportButtons(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _styledButton(
          icon: Icons.file_upload_outlined,
          label: 'استيراد',
          shortcut: 'Ctrl+I',
          onPressed: onImportExcel,
          theme: theme,
        ),
        _styledButton(
          icon: Icons.file_download_outlined,
          label: 'تصدير',
          shortcut: 'Ctrl+E',
          onPressed: onExportExcel,
          theme: theme,
        ),
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
      child: Text(
        'H: ${provider.hLines.length} | V: ${provider.vLines.length} | كلمات: ${provider.words.length}',
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatus(ThemeData theme) {
    String status = '';
    if (provider.moveMode) {
      status = 'وضع النقل: انقر على الصورة';
    } else if (provider.selectedElement != null) {
      status = 'تم التحديد';
    } else {
      status = 'انقر لإضافة كلمة';
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        status,
        key: ValueKey(status),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _styledButton({
    required IconData icon,
    required String label,
    String? shortcut,
    Color? color,
    VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: shortcut != null ? '$label ($shortcut)' : label,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: onPressed == null ? theme.disabledColor : (color ?? theme.colorScheme.primary)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: onPressed == null ? theme.disabledColor : (color ?? theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
