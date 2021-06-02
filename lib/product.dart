import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Product {
  var _properties = Map<String, String>();

  Product([String name = "", String count = "", String unit = ""]) {
    _properties['name'] = name;
    _properties['count'] = count;
    _properties['unit'] = unit;
  }

  List<Widget> getWidget() {
    return <Widget>[
      Text(_properties['name']!),
      Text(_properties['unit']!),
      Text(_properties['count']!),
    ];
  }

  String getProperty(String property) {
    return _properties[property]!;
  }

  void setCount(int count) {
    this._properties['count'] = count.toString();
  }
}

class ProductLists {
  List<Product> state;
  List<Product> products;

  ProductLists(List<Product> state, List<Product> products)
      : state = List.from(state),
        products = List.from(products);
}

abstract class BlocEvent {
  ProductLists changeState(ProductLists productLists);
}

class AddProductEvent extends BlocEvent {
  Product product;

  AddProductEvent(Product product) : product = product;

  @override
  ProductLists changeState(ProductLists productLists) {
    productLists.state.add(product);
    return productLists;
  }
}

class SetAllEvent extends BlocEvent {
  List<Product> products;

  SetAllEvent(List<Product> products) : products = products;

  @override
  ProductLists changeState(ProductLists productLists) {
    productLists.state = products;
    productLists.products = products;
    return productLists;
  }
}

class RemoveAllEvent extends BlocEvent {
  @override
  ProductLists changeState(ProductLists productLists) {
    productLists.products.clear();
    productLists.state.clear();
    return productLists;
  }
}

class FilterSearchResultsEvent extends BlocEvent {
  String query;

  FilterSearchResultsEvent(String query) : query = query;

  @override
  ProductLists changeState(ProductLists productLists) {
    if (query.isEmpty) {
      productLists.state = productLists.products;
      return productLists;
    }

    productLists.state = productLists.products.where((product) {
      String _query = query.toLowerCase();
      String productName = product.getProperty('name').toLowerCase();
      return productName.contains(_query);
    }).toList();
    print('length: ${productLists.state.length}');

    return productLists;
  }
}

class ChangeProductEvent extends BlocEvent {
  Product product;
  int value;

  ChangeProductEvent(Product product, int value)
      : product = product,
        value = value;

  @override
  ProductLists changeState(ProductLists productLists) {
    product.setCount(value);
    return productLists;
  }
}

class ProductListBloc extends Bloc<BlocEvent, List<Product>> {
  List<Product> products;

  ProductListBloc(List<Product> products)
      : products = products,
        super(products);

  @override
  Stream<List<Product>> mapEventToState(BlocEvent event) async* {
    ProductLists productLists = new ProductLists(state, products);
    productLists = event.changeState(productLists);
    products = productLists.products;
    yield productLists.state;
  }
}
