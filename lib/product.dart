import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Product {
  Product({
    @required this.name,
    @required this.price,
    @required this.description,
    @required this.created,
    @required this.modified,
    @required this.uid,
    @required this.id,
  });

  final String name;
  final int price;
  final String description;
  final Timestamp created;
  final Timestamp modified;
  final String uid;
  final String id;
}
