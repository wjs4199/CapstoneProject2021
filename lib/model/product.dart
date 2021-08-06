import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Product {
  Product({
    @required this.category,
    @required this.title,
    @required this.content,
    @required this.created,
    @required this.modified,
    @required this.userName,
    @required this.uid,
    @required this.id,
    @required this.likes,
    @required this.mark,
    @required this.comments,
  });

  final String category;
  final String title;
  final String content;
  final Timestamp created;
  final Timestamp modified;
  final String userName;
  final String uid;
  final String id;
  final int likes;
  final bool mark;
  final int comments;
}

class Comment {
  Comment({
    @required this.userName,
    @required this.comment,
    @required this.time,
    @required this.id,
  });

  final String userName;
  final String comment;
  final Timestamp time;
  final String id;
}

class Like {
  Like({
    @required this.uid,
  });

  final String uid;
}
