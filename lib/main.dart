import 'dart:io';

import 'package:flutter/material.dart';
import 'product.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
      ChangeNotifierProvider(create: (context) => ItemModel(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  final searchController = TextEditingController();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventur Liste',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Inventurliste'),
        ),
        drawer: Drawer(
            child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                child: Text('Header'),
                decoration: BoxDecoration(
                  color: Colors.blue,
                )),
            ListTile(
              title: Text('Import'),
              onTap: () {
                Future<FilePickerResult?> results =
                    FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );
                results.then((FilePickerResult? result) {
                  if (result == null) return;

                  PlatformFile platformFile = result.files.first;
                  File file = File(platformFile.path!);
                  var bytes = file.readAsBytesSync();
                  var excel = Excel.decodeBytes(bytes);

                  List<Product> products = [];
                  for (var tableKey in excel.tables.keys) {
                    for (var row in excel.tables[tableKey]!.rows) {
                      List<String> cells = List.filled(3, "");
                      for (int i = 0; i < cells.length; i++) {
                        var cell = row[i];
                        if (cell == null) continue;
                        cells[i] = cell.value;
                      }
                      products.add(Product(cells[0], cells[1], cells[2]));
                    }
                  }
                  Provider.of<ItemModel>(context, listen: false)
                      .setAll(products);
                  print('set all done');

                  // print('works2');
                  // print(file.name);
                  // print(file.bytes);
                  // print(file.size);
                  // print(file.extension);
                  // print(file.path);

                  print('done');
                }).catchError((error) {
                  print(error.toString());
                });
              },
            ),
            ListTile(
              title: Text('Export Stuff'),
              onTap: () {},
            ),
          ],
        )),
        body: Consumer<ItemModel>(builder: (context, products, child) {
          return Scaffold(
              body: Container(
                child: Column(children: <Widget>[
                TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                        hintText: "Suche",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        )
                    ),
                ),
                _buildContentTable(context)]),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) =>
                          _buildPopupDialog(context));
                },
                child: const Icon(Icons.add),
                backgroundColor: Colors.blue,
              ));
        }),
      ),
      routes: <String, WidgetBuilder>{
        '/about': (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('About Route'),
            ),
          );
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Table _buildContentTable(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(20),
        3: FixedColumnWidth(20),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(children: [
          TableCell(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text("HEAD"),
              Text("Two"),
              Text("Three"),
            ],
          ))
        ]),
        for (Product product
            in Provider.of<ItemModel>(context, listen: false).getAll())
          TableRow(children: [
            TableCell(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: product.getWidget()))
          ])
      ],
    );
  }

  final Map<String, TextEditingController> textControllers = {
    'name': TextEditingController(),
    'unit': TextEditingController(),
    'count': TextEditingController()
  };

  Widget _buildPopupDialog(BuildContext context) {
    return new AlertDialog(
      title: Text('Popup'),
      content: Container(
        child: Column(
          children: <Widget>[
            TextField(
              autofocus: true,
              controller: textControllers['name'],
            ),
            TextField(
              controller: textControllers['unit'],
            ),
            TextField(
              controller: textControllers['count'],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            child: Text('Hinzufügen'),
            onPressed: () {
              Provider.of<ItemModel>(context, listen: false).add(Product(
                  textControllers['name']!.text,
                  textControllers['unit']!.text,
                  textControllers['count']!.text));
              Navigator.of(context).pop();
              textControllers.forEach((key, controller) => controller.clear());
            }),
        TextButton(
            child: Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop();
              textControllers.forEach((key, controller) => controller.clear());
            }),
      ],
    );
  }
}

class ItemModel extends ChangeNotifier {
  List<Product> products = [
    Product('3', '5', '5'),
    Product('f', 'd', 'f'),
    Product('fd', 'd', 'g')
  ];

  List<Product> getAll() {
    return products;
  }

  void add(Product product) {
    print('add');
    products.add(product);
    print('notify');
    notifyListeners();
  }

  void setAll(List<Product> products) {
    this.products = products;
    notifyListeners();
  }

  void removeAll() {
    products.clear();
    notifyListeners();
  }
}

class Search extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    // TODO: implement buildActions
    throw UnimplementedError();
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    throw UnimplementedError();
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    throw UnimplementedError();
  }
}
