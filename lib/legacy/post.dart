import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Post {
  Post({
    @required this.title,
    @required this.content,
    @required this.category,
    @required this.time,
    @required this.id,
    @required this.uid,
  });

  final String title;
  final String category;
  final String content;
  final Timestamp time;
  final String uid;
  final String id;
}
