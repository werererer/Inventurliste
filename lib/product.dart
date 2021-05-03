import 'package:flutter/material.dart';

class Product {
  String name;
  String unit;
  String count;

  Product(String name, String unit, String count)
      : name = name,
        unit = unit,
        count = count;

  List<Widget> getWidget() {
    return <Widget>[
      Text(name),
      Text(unit),
      Text(count),
    ];
  }
}
