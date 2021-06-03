import 'package:flutter/material.dart';
import 'package:inventur_liste/storage.dart';
import 'package:replay_bloc/replay_bloc.dart';

import 'bloc.dart';

class Product {
  String name;
  int count;
  String unit;

  Product(String name, int count, String unit) : name = name, count = count, unit
      = unit;

  static of(Product product) {
    return Product(product.name, product.count, product.unit);
  }

  List<Widget> getWidget() {
    return <Widget>[
      Text(name),
      Text(count.toString()),
      Text(unit),
    ];
  }
}

class ProductLists {
  List<Product> state;
  List<Product> products;

  ProductLists(List<Product> state, List<Product> products)
      : state = List.of(state),
        products = List.of(products);

  ProductLists.copy(ProductLists productLists): state = List.of(productLists.state),
  products = List.of(productLists.products);
}

abstract class ProductListBlocEvent extends BlocEvent<ProductLists> {}

class AddProductEvent extends ProductListBlocEvent {
  Product product;

  AddProductEvent(Product product) : product = product;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    productLists.products.add(product);
    productLists.state.add(product);
    return productLists;
  }
}

class SetAllEvent extends ProductListBlocEvent {
  List<Product> products;

  SetAllEvent(List<Product> products) : products = products;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    productLists.state = products;
    productLists.products = products;
    return productLists;
  }
}

class InitAllEvent extends ProductListBlocEvent {
  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    print('init all');
    List<Product> products = await loadProductList();
    print('products.length: ${products.length}');
    productLists.state = products;
    productLists.products = products;
    print('init all end');
    return productLists;
  }
}

class RemoveAllEvent extends ProductListBlocEvent {
  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    productLists.products.clear();
    productLists.state.clear();
    return productLists;
  }
}

class RemoveAtIndexEvent extends ProductListBlocEvent {
  int i;

  RemoveAtIndexEvent(int i): i = i;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    if (i >= productLists.products.length || i < 0)
      return productLists;

    productLists.products.removeAt(i);
    productLists.state.removeAt(i);
    return productLists;
  }
}

class FilterSearchResultsEvent extends ProductListBlocEvent {
  String query;

  FilterSearchResultsEvent(String query) : query = query;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    if (query.isEmpty) {
      productLists.state = productLists.products;
      return productLists;
    }

    productLists.state = productLists.products.where((product) {
      String _query = query.toLowerCase();
      String productName = product.name.toLowerCase();
      return productName.contains(_query);
    }).toList();
    print('length: ${productLists.state.length}');

    return productLists;
  }
}

class ChangeProductEvent extends ProductListBlocEvent {
  Product product;
  int value;

  ChangeProductEvent(Product product, int value)
      : product = product,
        value = value;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    product.count = value;
    return productLists;
  }
}

class SetProductEvent extends ProductListBlocEvent {
  Product product;
  Product newProduct;

  SetProductEvent(Product product, Product newProduct)
      : product = product,
        newProduct = newProduct;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    product.name = newProduct.name;
    product.count = newProduct.count;
    product.unit = newProduct.unit;
    return productLists;
  }
}

class ProductListBloc extends ReplayBloc<ProductListBlocEvent, ProductLists> {
  ProductListBloc(List<Product> products) : super(ProductLists(products, products));

  @override
  Stream<ProductLists> mapEventToState(ProductListBlocEvent event) async* {
    ProductLists productLists = ProductLists.copy(state);
    productLists = await event.changeState(productLists);
    yield productLists;

    print('original products.length: ${productLists.products.length}');
    storeProductList(productLists.products);
  }
}
