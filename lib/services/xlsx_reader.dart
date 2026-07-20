import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class XlsxReader {
  static Map<String, List<Map<String, dynamic>>> readXlsx(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    String? workbookXml;
    String? sharedStringsXml;
    final sheetXmls = <String, String>{};

    for (var file in archive) {
      if (file.isFile) {
        final name = file.name;
        final content = utf8.decode(file.content);
        if (name == 'xl/workbook.xml') {
          workbookXml = content;
        } else if (name == 'xl/sharedStrings.xml') {
          sharedStringsXml = content;
        } else if (name.startsWith('xl/worksheets/sheet') && name.endsWith('.xml')) {
          sheetXmls[name] = content;
        }
      }
    }

    if (workbookXml == null) return {};

    final workbookDoc = XmlDocument.parse(workbookXml);
    final sheets = workbookDoc.findAllElements('sheet');

    final sheetNameToIndex = <String, int>{};
    var sheetIndex = 0;
    for (var sheet in sheets) {
      sheetNameToIndex[sheet.getAttribute('name') ?? ''] = sheetIndex;
      sheetIndex++;
    }

    final sharedStrings = <String>[];
    if (sharedStringsXml != null) {
      try {
        final siDoc = XmlDocument.parse(sharedStringsXml);
        for (var si in siDoc.findAllElements('si')) {
          final text = si.findElements('t').firstOrNull;
          sharedStrings.add(text?.innerText ?? '');
        }
      } catch (_) {}
    }

    final result = <String, List<Map<String, dynamic>>>{};

    for (var entry in sheetNameToIndex.entries) {
      final name = entry.key;
      final idx = entry.value;
      final path = 'xl/worksheets/sheet${idx + 1}.xml';
      final sheetXml = sheetXmls[path];
      if (sheetXml == null) continue;

      final sheetDoc = XmlDocument.parse(sheetXml);
      final sheetData = sheetDoc.findAllElements('sheetData').firstOrNull;
      if (sheetData == null) continue;

      final rows = sheetData.findAllElements('row');
      if (rows.isEmpty) continue;

      final allRowData = <List<dynamic>>[];
      var maxCols = 0;

      for (var row in rows) {
        final cells = row.findElements('c');
        final rowValues = <dynamic>[];
        for (var cell in cells) {
          final cellRef = cell.getAttribute('r') ?? '';
          final colLetter = cellRef.replaceAll(RegExp(r'\d'), '');
          final colIndex = _colLetterToIndex(colLetter);
          final cellType = cell.getAttribute('t') ?? '';
          final valueEl = cell.findElements('v').firstOrNull;
          String? rawValue = valueEl?.innerText;

          dynamic cellValue;
          if (cellType == 'inlineStr') {
            final isEl = cell.findElements('is').firstOrNull;
            final tEl = isEl?.findElements('t').firstOrNull;
            cellValue = tEl?.innerText ?? '';
          } else if (cellType == 's' && rawValue != null) {
            final siIndex = int.tryParse(rawValue);
            if (siIndex != null && siIndex < sharedStrings.length) {
              cellValue = sharedStrings[siIndex];
            } else {
              cellValue = rawValue;
            }
          } else if (cellType == 'b') {
            cellValue = rawValue == '1';
          } else if (rawValue != null) {
            final asNum = num.tryParse(rawValue);
            cellValue = asNum ?? rawValue;
          }

          while (rowValues.length <= colIndex) {
            rowValues.add(null);
          }
          rowValues[colIndex] = cellValue;
        }
        allRowData.add(rowValues);
        if (rowValues.length > maxCols) maxCols = rowValues.length;
      }

      if (allRowData.isNotEmpty) {
        final headers = allRowData.first.map((e) => e?.toString() ?? '').toList();
        final dataRows = <Map<String, dynamic>>[];
        for (var i = 1; i < allRowData.length; i++) {
          final row = allRowData[i];
          final map = <String, dynamic>{};
          for (var j = 0; j < headers.length && j < row.length; j++) {
            if (headers[j].isNotEmpty) {
              map[headers[j]] = row[j];
            }
          }
          dataRows.add(map);
        }
        result[name] = dataRows;
      }
    }

    return result;
  }

  static int _colLetterToIndex(String letters) {
    var result = 0;
    for (var i = 0; i < letters.length; i++) {
      result = result * 26 + (letters.codeUnitAt(i) - 64);
    }
    return result - 1;
  }
}
