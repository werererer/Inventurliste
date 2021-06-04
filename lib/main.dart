import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:inventur_liste/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'excelParser.dart';
import 'package:inventur_liste/parseUtils.dart';
import 'import.dart';
import 'product.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final List<String> fieldHeaders = ["Artikel", "Anzahl", "Einheit"];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getTemporaryDirectory());
  runApp(MultiBlocProvider(providers: [
    BlocProvider<ProductListBloc>(create: (_) => ProductListBloc([])),
  ], child: MyApp()));
}

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrease() => emit(state - 1);
}

class CounterEvent {
  final num value;

  const CounterEvent({required this.value});
}

class CounterBloc extends Bloc<CounterEvent, num> {
  CounterBloc(num value) : super(value);

  @override
  Stream<num> mapEventToState(CounterEvent event) async* {
    yield event.value;
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventurliste',
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

enum AppbarOptions { ClearList }

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
        title: const Text('Inventurliste'),
        actions: [
              IconButton(
                icon: Icon(Icons.sort),
                color: Colors.white,
                onPressed: () {
                  context.read<ProductListBloc>().add(SortEvent());
                },
              ),
          BlocBuilder<ProductListBloc, ProductLists>(
            builder: (context, lists) {
              return IconButton(
                icon: Icon(Icons.undo),
                color: _getActiveStatusColor(
                    context.read<ProductListBloc>().canUndo),
                onPressed: () {
                  context.read<ProductListBloc>().undo();
                },
              );
            },
          ),
          BlocBuilder<ProductListBloc, ProductLists>(builder: (context, lists) {
            return IconButton(
              icon: Icon(Icons.redo),
              color: _getActiveStatusColor(
                  context.read<ProductListBloc>().canRedo),
              onPressed: () {
                context.read<ProductListBloc>().redo();
              },
            );
          }),
          PopupMenuButton<AppbarOptions>(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                    value: AppbarOptions.ClearList, child: Text('lösche Liste'))
              ];
            },
            onSelected: (item) {
              switch (item) {
                case AppbarOptions.ClearList:
                  context.read<ProductListBloc>().add(ClearListEvent());
                  break;
              }
            },
          )
        ],
      ),
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
              child: Text(''),
              decoration: BoxDecoration(
                color: Colors.blue,
              )),
          ListTile(
            title: Text('Importieren'),
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
                          for (int i = 0; i < header.length; i++)
                            NameTag(header[i], i),
                        ])) as List<int>;

                List<List<String>> rows =
                    ExcelParser.getContent(platformFile.path!);

                List<Product> newProducts = [
                  for (var cells in rows)
                    () {
                      Product newProduct = Product(
                          cells[fieldPositions[0]],
                          parseNum(cells[fieldPositions[1]]),
                          cells[fieldPositions[2]]);
                      return newProduct;
                    }()
                ];

                context.read<ProductListBloc>().add(SetAllEvent(newProducts));
                Navigator.of(context).pop();
              }).catchError((error) {
                print('error ${error.toString()}');
              });
            },
          ),
          BlocBuilder<ProductListBloc, ProductLists>(builder: (context, lists) {
            List<Product> list = lists.state;
            return ListTile(
              title: Text('Exportieren'),
              onTap: () async {
                await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                          title: Text('Name'),
                          content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                TextField(
                                  autofocus: true,
                                  controller: exportController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'inventur_liste',
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.done),
                                  onPressed: () async {
                                    String fileName =
                                        '${exportController.text}';
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
                              ]));
                    });
                Navigator.of(context).pop();
              },
            );
          }),
        ],
      )),
      body: GestureDetector(onTap: () {
        FocusScope.of(context).unfocus();
      }, child: BlocBuilder<ProductListBloc, ProductLists>(
          builder: (context, productLists) {
        return Scaffold(
            body: (Column(children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Suche',
                    prefixIcon: Icon(Icons.search),
                  ),
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
                    builder: (BuildContext context) =>
                        _buildPopupDialog(context));
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            ));
      })),
    );
  }

  Color _getActiveStatusColor(bool active) {
    return active ? Colors.white : Colors.white60;
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
                },
                child: ListTile(
                    title: Center(
                        child: Text('${product.name} ' +
                            '${product.count.toString()} ${product.unit}')),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (childContext) {
                            return AlertDialog(
                              title: Center(child: Text('Anzahl')),
                              content: MultiBlocProvider(providers: [
                                BlocProvider<CounterBloc>(create: (_) {
                                  return CounterBloc(product.count);
                                }),
                              ], child: MyNumberPicker(product, context)),
                            );
                          });
                    },
                    onLongPress: () {
                      showDialog(
                          context: context,
                          builder: (childContext) {
                            return AlertDialog(
                              title: Text(
                                  '${product.name} ${product.count} ${product.unit}'),
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
                                return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        autofocus: true,
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          hintText: 'Artikel',
                                        ),
                                      ),
                                      TextField(
                                        controller: countController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Anzahl',
                                        ),
                                      ),
                                      TextField(
                                        controller: unitController,
                                        decoration: InputDecoration(
                                          hintText: 'Einheit',
                                        ),
                                      ),
                                      IconButton(
                                          icon: Icon(Icons.done),
                                          onPressed: () {
                                            String name = nameController.text;
                                            num count =
                                                parseNum(countController.text);
                                            String unit = unitController.text;
                                            context.read<ProductListBloc>().add(
                                                SetProductEvent(
                                                    product,
                                                    Product(
                                                        name, count, unit)));
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
      title: Text('Neues Produkt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            autofocus: true,
            controller: textControllers['name'],
            decoration: InputDecoration(
              hintText: 'Artikel',
            ),
          ),
          TextField(
            controller: textControllers['unit'],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Anzahl',
            ),
          ),
          TextField(
            controller: textControllers['count'],
            decoration: InputDecoration(
              hintText: 'Einheit',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              Navigator.of(context).pop();
              textControllers.forEach((key, controller) => controller.clear());
            }),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              context.read<ProductListBloc>().add(AddProductEvent(Product(
                  textControllers['name']!.text,
                  parseNum(textControllers['unit']!.text),
                  textControllers['count']!.text)));
              Navigator.of(context).pop();
              textControllers.forEach((key, controller) => controller.clear());
            }),
      ],
    );
  }
}

class MyNumberPicker extends StatelessWidget {
  final Product product;
  final BuildContext previousContext;

  MyNumberPicker(Product product, BuildContext previousContext)
      : product = product,
        previousContext = previousContext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, num>(builder: (_, count) {
      final TextEditingController editingController =
          TextEditingController(text: count.toString());
      final double fontSize = 22;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Flexible(
              child: Column(children: [
            TextButton(
              child: Center(
                  child: Text('-',
                      style:
                          TextStyle(fontSize: fontSize, color: Colors.black))),
              onPressed: () {
                num count = parseNum(editingController.text);
                count -= 1;
                editingController.text = count.toString();
              },
              onLongPress: () {
                num count = parseNum(editingController.text);
                count = count.floor();
                editingController.text = count.toString();
              },
            ),
            TextButton(
              child: Center(
                  child: Text('-5',
                      style:
                          TextStyle(fontSize: fontSize, color: Colors.black))),
              onPressed: () {
                num count = parseNum(editingController.text);
                count -= 5;
                editingController.text = count.toString();
              },
              onLongPress: () {
                num count = parseNum(editingController.text);
                count = count.floor();
                editingController.text = count.toString();
              },
            ),
          ])),
          Flexible(
              child: TextField(
            textAlign: TextAlign.center,
            controller: editingController,
            keyboardType: TextInputType.number,
            onChanged: (value) {},
          )),
          Flexible(
              child: Column(children: [
            TextButton(
              child: Center(
                  child: Text('+',
                      style:
                          TextStyle(fontSize: fontSize, color: Colors.black))),
              onPressed: () {
                num count = parseNum(editingController.text);
                count += 1;
                editingController.text = count.toString();
              },
              onLongPress: () {
                num count = parseNum(editingController.text);
                count = count.ceil();
                editingController.text = count.toString();
              },
            ),
            TextButton(
              child: Center(
                  child: Text('+5',
                      style:
                          TextStyle(fontSize: fontSize, color: Colors.black))),
              onPressed: () {
                num count = parseNum(editingController.text);
                count += 5;
                editingController.text = count.toString();
              },
              onLongPress: () {
                num count = parseNum(editingController.text);
                count = count.ceil();
                editingController.text = count.toString();
              },
            )
          ])),
        ]),
        IconButton(
            icon: Icon(Icons.done),
            onPressed: () {
              num newCount = parseNum(editingController.text);
              previousContext
                  .read<ProductListBloc>()
                  .add(ChangeProductEvent(product, newCount));
              Navigator.of(context).pop();
            }),
      ]);
    });
  }
}
