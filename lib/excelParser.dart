import 'dart:io';

import 'package:excel/excel.dart';

class ExcelParser {
  static List<String> getHeaders(String path) {
    File file = File(path);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    var tableKey = excel.tables.keys.first;
    var row = excel.tables[tableKey]!.rows[0];
    List<String> cells = [];
    for (int i = 0; i < row.length; i++) {
      var cell = row[i];
      if (cell == null) {
        cells.add('');
        continue;
      }
      cells.add(cell.value);
    }
    return cells;
  }

  static List<List<String>> getContent(String path) {
    File file = File(path);
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<List<String>> content = [];
    for (var tableKey in excel.tables.keys) {
      Sheet sheet = excel.tables[tableKey]!;
      // starts at 1 to ignore the first row (header row)
      for (int i = 1; i < sheet.rows.length; ++i) {
        var row = sheet.rows[i];
        List<String> rowContent = [];
        for (int j = 0; j < row.length; j++) {
          var cell = row[j];
          if (cell == null) {
            rowContent.add('');
            continue;
          }
          rowContent.add(cell.value.toString());
        }
        content.add(rowContent);
      }
    }
    return content;
  }
}
