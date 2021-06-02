import 'package:flutter/material.dart';
import 'excelParser.dart';
import 'import.dart';
import 'product.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final List<String> fieldHeaders = ["item", "unit", "count"];

List<Product> defaultProducts = [
  Product('Apfel', '5', 'Stück'),
  Product('Birne', '2', 'Kg'),
  Product('Blatt', '4', 'Blatt')
];

void main() {
  runApp(BlocProvider<ProductListBloc>(
      create: (context) => ProductListBloc(defaultProducts), child: MyApp()));
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrease() => emit(state - 1);
}

class CounterEvent {
  final int value;

  const CounterEvent({required this.value});
}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc(int value) : super(value);

  @override
  Stream<int> mapEventToState(CounterEvent event) async* {
    yield event.value;
  }
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
      home: MyHome(),
      routes: <String, WidgetBuilder>{
        '/import': (context) => MyImportState(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHome extends StatelessWidget {
  final searchController = TextEditingController();

  final Map<String, TextEditingController> textControllers = {
    'name': TextEditingController(),
    'unit': TextEditingController(),
    'count': TextEditingController()
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Future<FilePickerResult?> results = FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['xlsx'],
              );
              results.then((FilePickerResult? result) async {
                if (result == null) return;

                PlatformFile platformFile = result.files.first;

                Product header = ExcelParser.getHeaders(platformFile.path!);
                List<TableColumn> res =
                    await Navigator.pushNamed(context, '/import',
                        arguments: ImportArguments(fieldHeaders, [
                          TableColumn(header.getProperty('name'), 'name'),
                          TableColumn(header.getProperty('unit'), 'unit'),
                          TableColumn(header.getProperty('count'), 'count'),
                        ])) as List<TableColumn>;

                List<Product> products =
                    ExcelParser.getContent(platformFile.path!);

                List<Product> newProducts = [
                  for (var product in products)
                    () {
                      Product newProduct = Product(
                          product.getProperty(res[0].property),
                          product.getProperty(res[1].property),
                          product.getProperty(res[2].property));
                      return newProduct;
                    }()
                ];

                context.read<ProductListBloc>().add(SetAllEvent(newProducts));
              }).catchError((error) {
                print('error');
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
      body: BlocBuilder<ProductListBloc, List<Product>>(
          builder: (context, products) {
        return Scaffold(
            body: (Column(children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                      hintText: "Suche",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      )),
                  onChanged: (value) {
                    context
                        .read<ProductListBloc>()
                        .add(FilterSearchResultsEvent(value));
                  },
                ),
              ),
              Expanded(
                child: _buildContentTable(context),
              )
            ])),
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
    );
  }

  Widget _buildContentTable(BuildContext context) {
    return BlocBuilder<ProductListBloc, List<Product>>(
        builder: (context, list) {
      return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            Product product = list[i];
            return ListTile(
                title: Center(
                    child: Text("${product.getProperty('name')} " +
                        "${product.getProperty('count')} ${product.getProperty('unit')}")),
                onTap: () {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context2) {
                        return AlertDialog(
                          title: Center(child: Text('Anzahl')),
                          content: MultiBlocProvider(providers: [
                            BlocProvider<CounterBloc>(create: (_) {
                              int? i =
                                  int.tryParse(product.getProperty('count'));
                              if (i == null) i = 0;
                              return CounterBloc(i);
                            }),
                          ], child: MyNumberPicker(product, context)),
                        );
                      });
                },
                onLongPress: () {});
          });
    });
  }

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
              context.read<ProductListBloc>().add(AddProductEvent(Product(
                  textControllers['name']!.text,
                  textControllers['unit']!.text,
                  textControllers['count']!.text)));
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

class MyNumberPicker extends StatelessWidget {
  final TextEditingController editingController = TextEditingController();
  final Product product;
  final BuildContext previousContext;

  MyNumberPicker(Product product, BuildContext previousContext)
      : product = product,
        previousContext = previousContext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, int>(builder: (_, count) {
      return Column(children: [
        NumberPicker(
          value: count,
          minValue: 0,
          maxValue: 10,
          onChanged: (int value) {
            editingController.text = value.toString();
            context.read<CounterBloc>().add(CounterEvent(value: value));
          },
        ),
        TextField(
          controller: editingController,
          keyboardType: TextInputType.number,
          onChanged: (value) {},
        ),
        ElevatedButton(
            onPressed: () {
              previousContext.read<ProductListBloc>().add(ChangeProductEvent(product, count));
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.done))
      ]);
    });
  }
}
