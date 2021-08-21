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
}

class Comment {
  Comment({
    @required this.userName,
    @required this.comment,
    @required this.created,
    // @required this.isDeleted,


  });

  final String userName;
  final String comment;
  final Timestamp created;
// final bool isDeleted;

}

class Like {
  Like({
    @required this.uid,
  });

  final String uid;
}

class UserName {

  UserName({
    @required this.uid,
    @required this.email,
    @required this.username,
    @required this.created,
    @required this.isLogged,

  });

  final String uid;
  final String email;
  final String username;
  final Timestamp created;
  final bool isLogged;


}
