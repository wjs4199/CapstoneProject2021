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
    @required this.user_photoURL,
    @required this.thumbnail,
    @required this.complete,
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
  final String user_photoURL;
  final dynamic thumbnail;
  final String complete; /// booked, completed, selling
}

class Comment {
  Comment({
    @required this.userName,
    @required this.comment,
    @required this.created,
    @required this.id,
    @required this.uid,
    // @required this.isDeleted,
  });

  final String userName;
  final String comment;
  final Timestamp created;
  final String id;
  final String uid;
// final bool isDeleted;

}

class Like {
  Like({
    @required this.uid,
    @required this.id,
  });

  final String uid;
  final String id;
}

class Users {
  Users({
    @required this.createdAt,
    @required this.id,
    @required this.nickname,
    @required this.photoUrl,
    @required this.username,
    @required this.email,
  });

  final String createdAt;
  final String id;
  final String nickname;
  final String photoUrl;
  final String username;
  final String email;
}
