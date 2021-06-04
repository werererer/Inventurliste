import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc.dart';

class NameTag {
  String visibleName;
  int id;
  NameTag(String visibleName, int id)
      : visibleName = visibleName,
        id = id;
}

class ImportArguments {
  List<String> categories;
  List<NameTag> items;
  ImportArguments(List<String> categories, List<NameTag> items)
      : categories = categories,
        items = items;
}

class ImportState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ImportArguments importArguments =
        ModalRoute.of(context)!.settings.arguments as ImportArguments;
    return BlocProvider<ImportBloc>(
        create: (_) => ImportBloc(importArguments.items),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Import Route'),
          ),
          floatingActionButton:
              BlocBuilder<ImportBloc, List<NameTag>>(builder: (context, i) {
            return FloatingActionButton.extended(
                onPressed: () {
                  List<NameTag> state = context.read<ImportBloc>().state;
                  List<int> positions = [ for (var product in state) product.id ];
                  Navigator.pop(context, positions);
                },
                label: Text('Approve'),
                icon: Icon(Icons.thumb_up),
                backgroundColor: Colors.pink);
          }),
          body: Row(children: [
            Expanded(
                child: ListView.builder(
                    itemCount: importArguments.categories.length,
                    itemBuilder: (context, property) {
                      return ListTile(
                          title: Text(
                              '${importArguments.categories[property]}: '));
                    })),
            Expanded(child: BlocBuilder<ImportBloc, List<NameTag>>(
                builder: (context, list) {
              return ReorderableListView(
                children: list
                    .map((item) => ListTile(
                          key: Key("${item.visibleName}"),
                          title: Text("${item.visibleName}"),
                          trailing: Icon(Icons.menu),
                        ))
                    .toList(),
                onReorder: (start, current) {
                  context
                      .read<ImportBloc>()
                      .add(ChangeOrderEvent(start, current));
                },
              );
            }))
          ]),
        ));
  }
}

abstract class ImportBlocEvent extends BlocEvent<List<NameTag>> {}

class ChangeOrderEvent extends ImportBlocEvent {
  int start;
  int current;

  ChangeOrderEvent(int start, int current)
      : start = start,
        current = current;

  @override
  Future<List<NameTag>> changeState(List<NameTag> args) async {
    List<NameTag> _args = List.of(args);
    if (start < current) {
      int end = current - 1;
      NameTag startItem = _args[start];
      int i = 0;
      int local = start;
      do {
        _args[local] = _args[++local];
        i++;
      } while (i < end - start);
      _args[end] = startItem;
    } else if (start > current) {
      NameTag startItem = _args[start];
      for (int i = start; i > current; i--) {
        _args[i] = _args[i - 1];
      }
      _args[current] = startItem;
    }
    return _args;
  }
}

class ImportBloc extends Bloc<ImportBlocEvent, List<NameTag>> {
  ImportBloc(List<NameTag> initialState) : super(initialState);

  @override
  Stream<List<NameTag>> mapEventToState(ImportBlocEvent event) async* {
    yield await event.changeState(state);
  }
}
