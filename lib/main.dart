import 'package:flutter/material.dart';

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

class MyStatefulWidget extends StatefulWidget {
  @override
  MyClassState createState() => MyClassState();
}

/// This is the stateless widget that the main application instantiates
class MyClassState extends State<MyStatefulWidget> {
  List<String> articles = ['one', 'two', 'three'];

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
            for (String item in articles)
              TableRow(children: [
                TableCell(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[Text(item)],
                ))
              ])
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => _buildPopupDialog(context));
            // addItem('o');
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ));
  }

  Widget _buildPopupDialog(BuildContext context) {
    return new AlertDialog(
        title: Text('Popup'),
        content: new TextField(
            onSubmitted: (value) {
              addItem(value);
              Navigator.of(context).pop();
            }
        ),
    );
  }

  void addItem(String item) {
    setState(() {
      articles.add(item);
    });
  }
}
