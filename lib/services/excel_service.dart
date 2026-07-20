import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/annotation.dart';

class ExcelService {
  static String getBaseDirectory() {
    return 'G:\\trav_quran2';
  }

  static Future<Map<String, List<Map<String, dynamic>>>?> importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return null;
    final filePath = result.files.single.path;
    if (filePath == null) return null;

    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final data = <String, List<Map<String, dynamic>>>{
      'Mots': [],
      'Horizontales': [],
      'Verticales': [],
    };

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      final rows = sheet.rows;
      if (rows.isEmpty) continue;
      final headers = rows.first.map((e) => e?.value?.toString() ?? '').toList();
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final map = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j]?.value;
        }
        data[table]!.add(map);
      }
    }

    return data;
  }

  static Future<bool> exportExcel({
    required List<Word> words,
    required List<HLine> hLines,
    required List<VLine> vLines,
    required String pageNumber,
  }) async {
    final base = getBaseDirectory();
    final annotationDir = Directory('$base\\annotation');
    if (!await annotationDir.exists()) {
      await annotationDir.create(recursive: true);
    }
    final filePath = '$base\\annotation\\a$pageNumber.xlsx';

    final excel = Excel.createExcel();

    if (words.isNotEmpty) {
      final sheet = excel['Mots'];
      sheet.appendRow([
        TextCellValue('x1'),
        TextCellValue('y1'),
        TextCellValue('x2'),
        TextCellValue('y2'),
        TextCellValue('hidden'),
        TextCellValue('id'),
      ]);
      for (var w in words) {
        sheet.appendRow([
          DoubleCellValue(w.x1),
          DoubleCellValue(w.y1),
          DoubleCellValue(w.x2),
          DoubleCellValue(w.y2),
          BoolCellValue(w.hidden),
          IntCellValue(w.id),
        ]);
      }
    }

    if (hLines.isNotEmpty) {
      final sheet = excel['Horizontales'];
      sheet.appendRow([TextCellValue('y')]);
      for (var h in hLines) {
        sheet.appendRow([DoubleCellValue(h.y)]);
      }
    }

    if (vLines.isNotEmpty) {
      final sheet = excel['Verticales'];
      sheet.appendRow([
        TextCellValue('x'),
        TextCellValue('top'),
        TextCellValue('bottom'),
      ]);
      for (var v in vLines) {
        sheet.appendRow([
          DoubleCellValue(v.x),
          DoubleCellValue(v.top),
          DoubleCellValue(v.bottom),
        ]);
      }
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return false;

    await File(filePath).writeAsBytes(fileBytes);
    return true;
  }

  static Future<void> autoImportIfExists({
    required String pageNumber,
    required void Function(double x1, double y1, double x2, double y2) onWord,
    required void Function(double y) onHLine,
    required void Function(double x, double top, double bottom) onVLine,
  }) async {
    final base = getBaseDirectory();
    final filePath = '$base\\annotation\\a$pageNumber.xlsx';
    final file = File(filePath);
    if (!await file.exists()) return;

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.containsKey('Mots')) {
        final sheet = excel.tables['Mots']!;
        final rows = sheet.rows;
        if (rows.length > 1) {
          final headers = rows.first.map((e) => e?.value?.toString() ?? '').toList();
          final x1Idx = headers.indexOf('x1');
          final y1Idx = headers.indexOf('y1');
          final x2Idx = headers.indexOf('x2');
          final y2Idx = headers.indexOf('y2');
          if (x1Idx >= 0 && y1Idx >= 0 && x2Idx >= 0 && y2Idx >= 0) {
            for (var i = 1; i < rows.length; i++) {
              final row = rows[i];
              final x1 = (row[x1Idx]?.value as num?)?.toDouble() ?? 0;
              final y1 = (row[y1Idx]?.value as num?)?.toDouble() ?? 0;
              final x2 = (row[x2Idx]?.value as num?)?.toDouble() ?? 0;
              final y2 = (row[y2Idx]?.value as num?)?.toDouble() ?? 0;
              if (x2 > x1 && y2 > y1) {
                onWord(x1, y1, x2, y2);
              }
            }
          }
        }
      }

      if (excel.tables.containsKey('Horizontales')) {
        final sheet = excel.tables['Horizontales']!;
        final rows = sheet.rows;
        if (rows.length > 1) {
          final headers = rows.first.map((e) => e?.value?.toString() ?? '').toList();
          final yIdx = headers.indexOf('y');
          if (yIdx >= 0) {
            for (var i = 1; i < rows.length; i++) {
              final y = (rows[i][yIdx]?.value as num?)?.toDouble() ?? 0;
              onHLine(y);
            }
          }
        }
      }

      if (excel.tables.containsKey('Verticales')) {
        final sheet = excel.tables['Verticales']!;
        final rows = sheet.rows;
        if (rows.length > 1) {
          final headers = rows.first.map((e) => e?.value?.toString() ?? '').toList();
          final xIdx = headers.indexOf('x');
          final topIdx = headers.indexOf('top');
          final bottomIdx = headers.indexOf('bottom');
          if (xIdx >= 0 && topIdx >= 0 && bottomIdx >= 0) {
            for (var i = 1; i < rows.length; i++) {
              final row = rows[i];
              final x = (row[xIdx]?.value as num?)?.toDouble() ?? 0;
              final top = (row[topIdx]?.value as num?)?.toDouble() ?? 0;
              final bottom = (row[bottomIdx]?.value as num?)?.toDouble() ?? 0;
              onVLine(x, top, bottom);
            }
          }
        }
      }
    } catch (_) {}
  }
}
