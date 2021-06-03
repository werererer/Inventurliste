import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventur_liste/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'excelParser.dart';
import 'package:inventur_liste/parseUtils.dart';
import 'import.dart';
import 'product.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final List<String> fieldHeaders = ["item", "count", "unit"];

void main() {
  runApp(BlocProvider<ProductListBloc>(
      create: (context) {
        return ProductListBloc([]);
      },
      child: MyApp()));
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
    context.read<ProductListBloc>().add(InitAllEvent());
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
        '/import': (context) => ImportState(),
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

  final TextEditingController exportController =
      TextEditingController(text: "inventur_liste");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InventurListe'),
        actions: [
        IconButton(
            icon: Icon(Icons.undo),
            onPressed: () { context.read<ProductListBloc>().undo(); },
        ),
        IconButton(
            icon: Icon(Icons.redo),
            onPressed: () { context.read<ProductListBloc>().redo(); },
        ),
        ],
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

                List<String> header =
                    ExcelParser.getHeaders(platformFile.path!);
                List<int> fieldPositions =
                    await Navigator.pushNamed(context, '/import',
                        arguments: ImportArguments(fieldHeaders, [
                          NameTag(header[0], 0),
                          NameTag(header[1], 1),
                          NameTag(header[2], 2),
                        ])) as List<int>;

                List<List<String>> rows =
                    ExcelParser.getContent(platformFile.path!);

                List<Product> newProducts = [
                  for (var cells in rows)
                    () {
                      Product newProduct = Product(
                          cells[fieldPositions[0]],
                          parseInteger(cells[fieldPositions[1]]),
                          cells[fieldPositions[2]]);
                      return newProduct;
                    }()
                ];

                context.read<ProductListBloc>().add(SetAllEvent(newProducts));
              }).catchError((error) {
                print('error ${error.toString()}');
              });
            },
          ),
          BlocBuilder<ProductListBloc, ProductLists>(builder: (context, lists) {
            List<Product> list = lists.state;
            return ListTile(
              title: Text('Export'),
              onTap: () async {
                await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                          title: Text('Name'),
                          content: Container(
                              child: Column(children: <Widget>[
                            TextField(
                              autofocus: true,
                              controller: exportController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "inventur_liste",
                              ),
                            ),
                            TextButton(
                              child: Text('button'),
                              onPressed: () async {
                                String fileName = '${exportController.text}';
                                if (fileName.isEmpty) {
                                  fileName = 'inventur_liste';
                                }
                                String file = '$fileName.xlsx';
                                var directory =
                                    await getApplicationSupportDirectory();
                                String path = '${directory.path}/$file';
                                storeExcel(path, list);
                                Navigator.of(context).pop();
                                Share.shareFiles([path]);
                              },
                            )
                          ])));
                    });
              },
            );
          }),
        ],
      )),
      body: BlocBuilder<ProductListBloc, ProductLists>(
          builder: (context, productLists) {
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
    return BlocBuilder<ProductListBloc, ProductLists>(
        builder: (context, lists) {
      List<Product> list = lists.state;
      return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            Product product = list[i];
            return Dismissible(
                key: UniqueKey(),
                onDismissed: (direction) {
                  context.read<ProductListBloc>().add(RemoveAtIndexEvent(i));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Container(
                          child: Row(
                    children: [
                      Text('hi'),
                      TextButton(
                          onPressed: () {
                            context.read<ProductListBloc>().undo();
                            ScaffoldMessenger.of(context).clearSnackBars();
                          },
                          child: Text('undo'))
                    ],
                  ))));
                },
                child: ListTile(
                    title: Center(
                        child: Text("${product.name} " +
                            "${product.count.toString()} ${product.unit}")),
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
                                      int.tryParse(product.count.toString());
                                  if (i == null) i = 0;
                                  return CounterBloc(i);
                                }),
                              ], child: MyNumberPicker(product, context)),
                            );
                          });
                    },
                    onLongPress: () {
                      showDialog(
                          context: context,
                          builder: (context2) {
                            return AlertDialog(
                              title: Text('option'),
                              content: Container(child:
                                  BlocBuilder<ProductListBloc, ProductLists>(
                                      builder: (context, lists) {
                                TextEditingController nameController =
                                    TextEditingController(text: product.name);
                                TextEditingController countController =
                                    TextEditingController(
                                        text: product.count.toString());
                                TextEditingController unitController =
                                    TextEditingController(text: product.unit);
                                return Column(children: [
                                  TextField(
                                    autofocus: true,
                                    controller: nameController,
                                  ),
                                  TextField(
                                    controller: countController,
                                  ),
                                  TextField(
                                    controller: unitController,
                                  ),
                                  TextButton(
                                      child: Text('done'),
                                      onPressed: () {
                                        String name = nameController.text;
                                        int count =
                                            parseInteger(countController.text);
                                        String unit = unitController.text;
                                        context.read<ProductListBloc>().add(
                                            SetProductEvent(product,
                                                Product(name, count, unit)));
                                        Navigator.of(context).pop();
                                      })
                                ]);
                              })),
                            );
                          });
                    }));
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
                  parseInteger(textControllers['unit']!.text),
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
              previousContext
                  .read<ProductListBloc>()
                  .add(ChangeProductEvent(product, count));
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.done))
      ]);
    });
  }
}
