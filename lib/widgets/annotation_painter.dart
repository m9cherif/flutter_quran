import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/annotation.dart';

class AnnotationPainter extends CustomPainter {
  final ui.Image? image;
  final List<HLine> hLines;
  final List<VLine> vLines;
  final List<Word> words;
  final int borderWidth;
  final bool showWords;
  final bool showHLines;
  final bool showVLines;
  final Annotation? selectedElement;
  final Rect? previewRect;
  final double displayScale;
  final Color highlightColor;
  final double highlightOpacity;
  final bool showHiddenWords;

  AnnotationPainter({
    this.image,
    required this.hLines,
    required this.vLines,
    required this.words,
    this.borderWidth = 2,
    this.showWords = true,
    this.showHLines = false,
    this.showVLines = false,
    this.selectedElement,
    this.previewRect,
    this.displayScale = 1.0,
    this.highlightColor = Colors.yellow,
    this.highlightOpacity = 0.2,
    this.showHiddenWords = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    if (image != null) {
      paintImage(canvas, size);
    }

    final s = displayScale;

    if (showHLines) {
      for (var h in hLines) {
        final isSelected = selectedElement == h;
        canvas.drawLine(
          Offset(0, h.y * s),
          Offset(size.width, h.y * s),
          Paint()
            ..color = isSelected ? Colors.yellow : Colors.red
            ..strokeWidth = isSelected ? 3.0 : 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }

    if (showVLines) {
      for (var v in vLines) {
        final isSelected = selectedElement == v;
        canvas.drawLine(
          Offset(v.x * s, v.top * s),
          Offset(v.x * s, v.bottom * s),
          Paint()
            ..color = isSelected ? Colors.yellow : Colors.green
            ..strokeWidth = isSelected ? 3.0 : 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }

    for (var w in words) {
      final isSelected = selectedElement == w;
      if (!showWords && !isSelected) continue;
      final rect = Rect.fromLTRB(w.x1 * s, w.y1 * s, w.x2 * s, w.y2 * s);

      if (w.hidden && !showHiddenWords) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }

      if (borderWidth > 0) {
        if (isSelected) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = highlightColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0,
          );
        } else {
          canvas.drawRect(
            rect,
            Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderWidth.toDouble(),
          );
        }
      }

      if (isSelected && !w.hidden) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = highlightColor.withAlpha((highlightOpacity * 255).round())
            ..style = PaintingStyle.fill,
        );
      }
    }

    if (previewRect != null) {
      final r = Rect.fromLTRB(
        previewRect!.left * s,
        previewRect!.top * s,
        previewRect!.right * s,
        previewRect!.bottom * s,
      );
      final paint = Paint()
        ..color = const Color(0x780096FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final fillPaint = Paint()
        ..color = const Color(0x280096FF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(r, fillPaint);
      canvas.drawRect(r, paint);
    }
  }

  void paintImage(Canvas canvas, Size size) {
    if (image == null) return;
    final srcSize = Size(image!.width.toDouble(), image!.height.toDouble());
    final scaleX = size.width / srcSize.width;
    final scaleY = size.height / srcSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final destW = srcSize.width * scale;
    final destH = srcSize.height * scale;
    final offsetX = (size.width - destW) / 2;
    final offsetY = (size.height - destH) / 2;
    final destRect = Rect.fromLTWH(offsetX, offsetY, destW, destH);
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, srcSize.width, srcSize.height),
      destRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return image != oldDelegate.image ||
        hLines != oldDelegate.hLines ||
        vLines != oldDelegate.vLines ||
        words != oldDelegate.words ||
        borderWidth != oldDelegate.borderWidth ||
        showWords != oldDelegate.showWords ||
        showHLines != oldDelegate.showHLines ||
        showVLines != oldDelegate.showVLines ||
        selectedElement != oldDelegate.selectedElement ||
        previewRect != oldDelegate.previewRect ||
        highlightColor != oldDelegate.highlightColor ||
        highlightOpacity != oldDelegate.highlightOpacity ||
        showHiddenWords != oldDelegate.showHiddenWords;
  }

  Size get imageSize {
    if (image == null) return Size.zero;
    return Size(image!.width.toDouble(), image!.height.toDouble());
  }
}
