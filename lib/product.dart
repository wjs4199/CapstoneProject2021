import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Product {
  Product({
    @required this.category,
    @required this.title,
    @required this.content,
    @required this.created,
    @required this.modified,
    @required this.uid,
    @required this.id,
    @required this.like,
    @required this.mark,
    @required this.comments,
  });

  final String category;
  final String title;
  final String content;
  final Timestamp created;
  final Timestamp modified;
  final String uid;
  final String id;
  final int like;
  final bool mark;
  final int comments;
}