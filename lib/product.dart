import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:replay_bloc/replay_bloc.dart';

import 'bloc.dart';

class Product {
  String name;
  num count;
  String unit;

  Product(String name, num count, String unit)
      : name = name,
        count = count,
        unit = unit;

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

  ProductLists.copy(ProductLists productLists)
      : state = List.of(productLists.state),
        products = List.of(productLists.products);
}

abstract class ProductListBlocEvent extends BlocEvent<ProductLists> {}

class AddProductEvent extends ProductListBlocEvent {
  Product product;

  AddProductEvent(Product product) : product = product;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    productLists.products.add(product);
    productLists.products.sort((product1, product2) {
      return product1.name.compareTo(product2.name);
    });
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

class ClearListEvent extends ProductListBlocEvent {
  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    productLists.products.clear();
    productLists.state.clear();
    return productLists;
  }
}

class RemoveAtIndexEvent extends ProductListBlocEvent {
  int i;

  RemoveAtIndexEvent(int i) : i = i;

  @override
  Future<ProductLists> changeState(ProductLists productLists) async {
    if (i >= productLists.products.length || i < 0) return productLists;

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
      return Fuzzy([product.name]).search(query).isNotEmpty;
    }).toList();
    productLists.state.sort((product1, product2) {
      double score1 = Fuzzy([product1.name]).search(query).first.score;
      double score2 = Fuzzy([product2.name]).search(query).first.score;
      return (score1 < score2) ? -1 : 1;
    });

    return productLists;
  }
}

class ChangeProductEvent extends ProductListBlocEvent {
  Product product;
  num value;

  ChangeProductEvent(Product product, num value)
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

class ProductListBloc extends HydratedBloc<ProductListBlocEvent, ProductLists>
    with ReplayBlocMixin {
  ProductListBloc(List<Product> products)
      : super(ProductLists(products, products));

  @override
  Stream<ProductLists> mapEventToState(ProductListBlocEvent event) async* {
    ProductLists productLists = ProductLists.copy(state);
    productLists = await event.changeState(productLists);
    yield productLists;
  }

  @override
  ProductLists fromJson(Map<String, dynamic> json) {
    var productsJson = json['products'];
    var visibleProductsJson = json['visibleProducts'];

    List<Product> products = [
      for (var product in productsJson)
        Product(product[0], product[1], product[2])
    ];

    List<Product> visibleProducts = [
      for (var product in visibleProductsJson) 
        Product(product[0], product[1], product[2])
    ];

    return ProductLists(visibleProducts, products);
  }

  @override
  Map<String, dynamic> toJson(ProductLists state) {
    List<Product> visibleProducts = state.state;
    List<Product> products = state.products;
    return {
        'products': [for (var product in products) [product.name, product.count, product.unit]],
        'visibleProducts': [for (var product in visibleProducts) [product.name, product.count, product.unit]],
    };
  }
}
