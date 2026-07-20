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

      final hLinesList = <Map<String, dynamic>>[];
      final vLinesList = <Map<String, dynamic>>[];
      final wordsList = <Map<String, dynamic>>[];

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
          if (table == 'Horizontales') {
            hLinesList.add(map);
          } else if (table == 'Verticales') {
            vLinesList.add(map);
          } else if (table == 'Mots') {
            wordsList.add(map);
          }
        }
      }

      for (var h in hLinesList) {
        final y = (h['y'] as num?)?.toDouble() ?? 0;
        onHLine(y);
      }

      for (var v in vLinesList) {
        final x = (v['x'] as num?)?.toDouble() ?? 0;
        final top = (v['top'] as num?)?.toDouble() ?? 0;
        final bottom = (v['bottom'] as num?)?.toDouble() ?? 0;
        onVLine(x, top, bottom);
      }

      for (var m in wordsList) {
        final x1 = (m['x1'] as num?)?.toDouble() ?? 0;
        final y1 = (m['y1'] as num?)?.toDouble() ?? 0;
        final x2 = (m['x2'] as num?)?.toDouble() ?? 0;
        final y2 = (m['y2'] as num?)?.toDouble() ?? 0;
        if (x2 > x1 && y2 > y1) {
          onWord(x1, y1, x2, y2);
        }
      }
    } catch (_) {}
  }
}
