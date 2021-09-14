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
    @required this.hits,
    @required this.photo,
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
  final int hits;
  final int photo;
}

class Comment {
  Comment({
    @required this.userName,
    @required this.comment,
    @required this.created,
    @required this.nickname,
    // @required this.isDeleted,


  });

  final String userName;
  final String comment;
  final Timestamp created;
  final String nickname;
// final bool isDeleted;

}

class Like {
  Like({
    @required this.uid,
  });

  final String uid;
}

class Users {

  Users({
    @required this.chattingWith,
    @required this.createdAt,
    @required this.id,
    @required this.nickname,
    @required this.photoUrl,
    @required this.username,

  });

  final String chattingWith;
  final Timestamp createdAt;
  final String id;
  final String nickname;
  final String photoUrl;
  final String username;


}
