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
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      paintImage(canvas, size);
    }

    if (showHLines) {
      for (var h in hLines) {
        final isSelected = selectedElement == h;
        canvas.drawLine(
          Offset(0, h.y),
          Offset(size.width, h.y),
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
          Offset(v.x, v.top),
          Offset(v.x, v.bottom),
          Paint()
            ..color = isSelected ? Colors.yellow : Colors.green
            ..strokeWidth = isSelected ? 3.0 : 2.0
            ..style = PaintingStyle.stroke,
        );
      }
    }

    if (showWords) {
      for (var w in words) {
        final isSelected = selectedElement == w;
        final rect = Rect.fromLTRB(w.x1, w.y1, w.x2, w.y2);

        if (w.hidden) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill,
          );
        }

        if (borderWidth == 0) {
          if (isSelected) {
            canvas.drawRect(
              rect,
              Paint()
                ..color = Colors.yellow
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.0,
            );
          }
        } else {
          final paint = Paint()
            ..color = isSelected ? Colors.yellow : Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 3.0 : borderWidth.toDouble();
          canvas.drawRect(rect, paint);
        }

        if (isSelected && !w.hidden) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = Colors.yellow.withAlpha(50)
              ..style = PaintingStyle.fill,
          );
        }
      }
    }

    if (previewRect != null) {
      final paint = Paint()
        ..color = const Color(0x780096FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final fillPaint = Paint()
        ..color = const Color(0x280096FF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(previewRect!, fillPaint);
      canvas.drawRect(previewRect!, paint);
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
        previewRect != oldDelegate.previewRect;
  }

  Size get imageSize {
    if (image == null) return Size.zero;
    return Size(image!.width.toDouble(), image!.height.toDouble());
  }
}
