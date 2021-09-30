import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserChat {
  String id;
  String photoUrl;
  String idTo;
  String nickname;
  String peerNickname;
  String peerPhotoUrl;
  String aboutMe;

  UserChat(
      {@required this.id, @required this.photoUrl, @required this.nickname, @required this.idTo, @required this.aboutMe, @required this.peerNickname, @required this.peerPhotoUrl}); /// 이부분도 수정할 것

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    var aboutMe = '';
    var photoUrl = '';
    var idTo = '';
    var nickname = "";
    var peerNickname = "";
    var peerPhotoUrl = "";
    try {
      aboutMe = doc.get('aboutMe');
    } catch (e) {}
    try {
      photoUrl = doc.get('photoUrl');
    } catch (e) {}
    try {
      nickname = doc.get('nickname');
    } catch (e) {}
    try {
      aboutMe = doc.get('peerNickname');
    } catch (e) {}
    try {
      aboutMe = doc.get('peerPhotoUrl');
    } catch (e) {}
    try {
      idTo = doc.get('idTo');
    }catch (e) {}

    return UserChat(
      id: doc.id,
      photoUrl: photoUrl,
      idTo: idTo,
      nickname: nickname,
      peerNickname: peerNickname,
      aboutMe: aboutMe,
      peerPhotoUrl: peerPhotoUrl,
    );
  }
}