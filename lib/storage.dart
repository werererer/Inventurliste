import 'dart:io';

import 'package:excel/excel.dart';
import 'package:inventur_liste/parseUtils.dart';
import 'package:inventur_liste/product.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'excelParser.dart';
import 'main.dart';

Future<String> _getPath() async {
  var directory = await getApplicationDocumentsDirectory();
  String path = '${directory.path}/inventur_liste.xlsx';
  return path;
}

void storeProductList(List<Product> list) async {
  String path = await _getPath();
  storeExcel(path, list);
}

Future<List<Product>> loadProductList() async {
  String path = await _getPath();

  List<List<String>> rows =
      ExcelParser.getContent(path);

  List<Product> newProducts = [
  for (var cells in rows)
    () {
      Product newProduct = Product(
          cells[0],
          parseNum(cells[1]),
          cells[2]);
      return newProduct;
    }()
  ];

  return Future.sync(() => newProducts);
}

void storeExcel(String path, List<Product> products) async {
  var status = await Permission.storage.status;
  if (status.isDenied) {
    await Permission.storage.request();
  }

  Excel excel = Excel.createExcel();

  var sheet = excel['Sheet1'];
  sheet.appendRow(fieldHeaders);
  for (Product product in products) {
    sheet.appendRow([product.name, product.count, product.unit]);
  }

  // Call function save() to download the file
  var fileBytes = excel.save();

  File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);
}
