import 'package:flutter/material.dart';
import 'product.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
              title: Text('Import Stuff'),
              onTap: () {
                Future<FilePickerResult?> results = FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['xlsx'],
                );
                results.then((FilePickerResult? result) {
                  if (result == null)
                    return;

                  PlatformFile file = result.files.first;
                  print(file.name);
                  print(file.bytes);
                  print(file.size);
                  print(file.extension);
                  print(file.path);

                  print('done');
                }).catchError((error) {
                  print('error');
                });
              },
            ),
            ListTile(
              title: Text('Export Stuff'),
              onTap: () {},
            ),
          ],
        )),
        body: MyStatefulWidget(),
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
}

/// This is the stateless widget that the main application instantiates
class MyClassState extends State<MyStatefulWidget> {
  final Map<String, TextEditingController> textControllers = {
    'name': TextEditingController(),
    'unit': TextEditingController(),
    'count': TextEditingController()
  };

  List<Product> products = [
    Product('3', '4', '5'),
    Product('f', 'd', 'f'),
    Product('fd', 'd', 'g')
  ];

  void addProduct(Product item) {
    setState(() {
      products.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Table(
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
            for (Product product in products)
              TableRow(children: [
                TableCell(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: product.getWidget()))
              ])
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) => _buildPopupDialog(context));
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ));
  }

  Widget _buildPopupDialog(BuildContext context) {
    return new AlertDialog(
      title: Text('Popup'),
      content: Container(
        child: Column(
          children: <Widget>[
            new TextField(
                autofocus: true,
                controller: textControllers['name'],
                onSubmitted: (value) {
                  addProduct(Product(value, 'f', 'f'));
                  Navigator.of(context).pop();
                }),
            new TextField(
                controller: textControllers['unit'],
                onSubmitted: (value) {
                  addProduct(Product(value, 'f', 'f'));
                  Navigator.of(context).pop();
                }),
            new TextField(
                controller: textControllers['count'],
                onSubmitted: (value) {
                  addProduct(Product(value, 'f', 'f'));
                  Navigator.of(context).pop();
                }),
          ],
        ),
      ),
      // content: new TextField(
      //     autofocus: true,
      //     controller: myController,
      //     onSubmitted: (value) {
      //       addProduct(Product(value, 'f', 'f'));
      //       Navigator.of(context).pop();
      //     }),
      actions: <Widget>[
        TextButton(
            child: Text('Hinzufügen'),
            onPressed: () {
              addProduct(Product(
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

class MyStatefulWidget extends StatefulWidget {
  @override
  MyClassState createState() => MyClassState();
}
