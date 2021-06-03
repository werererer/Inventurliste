import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc.dart';

enum ProductProperty {
  Name, Unit, Count
}

class Product {
  String name;
  int count;
  String unit;

  Product(String name, int count, String unit) : name = name, count = count, unit
      = unit;

  static from(Product product) {
    return Product(product.name, product.count, product.unit);
  }

  List<Widget> getWidget() {
    return <Widget>[
      Text(name),
      Text(count.toString()),
      Text(unit),
    ];
  }

  String getProperty(ProductProperty property) {
    switch(property) {
      case ProductProperty.Name:
        return name;
      case ProductProperty.Count:
        return count.toString();
      case ProductProperty.Unit:
        return unit;
    }
  }
}

class ProductLists {
  List<Product> state;
  List<Product> products;

  ProductLists(List<Product> state, List<Product> products)
      : state = List.from(state),
        products = List.from(products);
}

abstract class ProductListBlocEvent extends BlocEvent<ProductLists> {}

class AddProductEvent extends ProductListBlocEvent {
  Product product;

  AddProductEvent(Product product) : product = product;

  @override
  ProductLists changeState(ProductLists productLists) {
    productLists.state.add(product);
    return productLists;
  }
}

class SetAllEvent extends ProductListBlocEvent {
  List<Product> products;

  SetAllEvent(List<Product> products) : products = products;

  @override
  ProductLists changeState(ProductLists productLists) {
    productLists.state = products;
    productLists.products = products;
    return productLists;
  }
}

class RemoveAllEvent extends ProductListBlocEvent {
  @override
  ProductLists changeState(ProductLists productLists) {
    productLists.products.clear();
    productLists.state.clear();
    return productLists;
  }
}

class FilterSearchResultsEvent extends ProductListBlocEvent {
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
  ProductLists changeState(ProductLists productLists) {
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
  ProductLists changeState(ProductLists productLists) {
    product.name = newProduct.name;
    product.count = newProduct.count;
    product.unit = newProduct.unit;
    return productLists;
  }
}

class ProductListBloc extends Bloc<ProductListBlocEvent, List<Product>> {
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
