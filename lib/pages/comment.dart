import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';

import '../model/product.dart';
import '../main.dart';

class CommentBook extends StatefulWidget {
  CommentBook({
    this.detailGiveOrTake,
    this.productId,
  }); //, required this.dates

  /// comment 가 어느 게시물 밑에 달린 것인지 알기 위해 필요한 Product ID
  final String productId;

  /// giveProducts / takeProducts collection 중 어디서 가져와야하는 지 표시
  final String detailGiveOrTake;

  @override
  _CommentBookState createState() => _CommentBookState();
}

class _CommentBookState extends State<CommentBook> {
  ///**************** comments 를 UI 상으로 보여주기 위해 필요한 변수 / 함수들 ****************///

  /// 현재 유저의 이름 간략화
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var userId = FirebaseAuth.instance.currentUser.uid;

  /// 유저의 닉네임을 찾아서 보여주는 함수
  String findNickname(AsyncSnapshot<QuerySnapshot> snapshot, String name) {
    var nickName = 'null';
    snapshot.data.docs.forEach((document) {
      if (document['username'] == name) {
        nickName = document['nickname'];
      }
    });

    print('찾은 닉네임은 $nickName!!');

    return nickName;
  }

  @override
  Widget build(BuildContext context) {
    ///******** comment 의 추가/삭제에 따라 Firebase 와 연동시키기 위해 필요한 변수/함수 ********///

    /// comment 가 어느 게시물 밑에 달린 것인지 알기 위해 필요한 Product ID
    var productId = widget.productId;

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    /// 'comments' Collection 참조
    CollectionReference comments = FirebaseFirestore.instance
        .collection('${widget.detailGiveOrTake}/$productId/comment');

    /// 해당 productId에 부합하는 게시물에 담긴 comment 들을 가져와 담을 변수
    var commentsList = context.read<ApplicationState>().commentContext;

    /// comment 삭제기능
    Future<void> deleteComments(Comment comment) async {
      try {
        for (var eachComment in commentsList) {
          if (eachComment.id == comment.id) {
            return await FirebaseFirestore.instance
                .collection('${widget.detailGiveOrTake}/$productId/comment')
                .doc(comment.id)
                .delete();
          }
        }
      } on Exception {
        return null;
      }
    }

    /// ToggleButtons 내의 대댓글, 좋아요, 삭제 버튼의 상태를 표시하기 위해 필요한 리스트 변수
    var _selections = List<bool>.generate(3, (_) => false);

    /// ToggleButtons 위젯(대댓글, 좋아요, 삭제)
    ToggleButtons _buildCommentToggleButtons(
        BuildContext context, ApplicationState appState, Comment comment) {
      return ToggleButtons(
        color: Colors.black.withOpacity(0.60),
        constraints: BoxConstraints(
          minWidth: 25,
          minHeight: 25,
        ),
        selectedBorderColor: Colors.cyan,
        selectedColor: Colors.cyan,
        borderRadius: BorderRadius.circular(4.0),
        isSelected: _selections,
        onPressed: (int index) {
          setState(() {
            if (index == 2) {
              print('push delete button!');
              print(FirebaseAuth.instance.currentUser.displayName);
              print(userName);

              /// 사용자가 올린 댓글만 삭제 가능하도록 사용자 이름과 댓글 기록자의 이름을 비교(수정 필요)
              if (FirebaseAuth.instance.currentUser.displayName == userName) {
                print('same userName');

                /// 정말 삭제할 것인지 사용자에게 질문하는 알림창을 띄우는 위젯
                showDialog(
                    context: context,
                    builder: (BuildContext context) => CupertinoAlertDialog(
                          title: Text('Deleting Comment'),
                          content: Text(
                              'Are you sure that you want to delete this comment?'),
                          actions: <Widget>[
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('No'),
                            ),
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.pop(context);
                                deleteComments(comment)
                                    .then((value) => appState.init())
                                    .catchError((error) => null)
                                    .whenComplete(() {
                                  setState(() {
                                    //
                                  });
                                });
                              },
                              child: Text('Yes'),
                            ),
                          ],
                        ));
              } else {
                null;
              }
            }
          });
        },
        children: [
          Icon(
            Icons.chat,
            size: 15,
          ),
          Icon(
            Icons.thumb_up,
            size: 15,
          ),
          Icon(
            Icons.delete,
            size: 15,
          ),
        ],
      );
    }

    /// comments 나열된 화면 구성
    return StreamBuilder<QuerySnapshot>(
        stream: comments.snapshots().asBroadcastStream(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('x',
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('',
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                ));
          }
          var count = snapshot.data.size;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var eachComment in commentsList)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.fromLTRB(10.0, 5, 0.0, 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                /// 사용자의 구글 이메일 프로필 사진으로 바꾸는 작업 필요
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: Image.asset(
                                      'assets/userDefaultImage.png'),
                                ),
                                SizedBox(width: 8.5),
                                StreamBuilder<QuerySnapshot>(
                                    stream: users.snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<QuerySnapshot> snapshot) {
                                      if (snapshot.hasError) {
                                        return Text('x');
                                      }
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Text('');
                                      }
                                      return SizedBox(
                                        height: 30,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 5),
                                            Text(
                                                findNickname(snapshot,
                                                    eachComment.userName),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                )),
                                          ],
                                        ),
                                      );
                                    }),
                                Expanded(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                      /// 댓글마다 대댓글, 좋아요, 삭제 기능을 담당하는 토글버튼 생성
                                      _buildCommentToggleButtons(
                                          context,
                                          Provider.of<ApplicationState>(context,
                                              listen: false),
                                          eachComment),
                                      SizedBox(width: 10),
                                    ]))
                              ],
                            )),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 10.0),
                              RichText(
                                  text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: <TextSpan>[
                                    TextSpan(text: eachComment.comment + '\n'),
                                  ])),
                            ]),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
                          child: Divider(thickness: 1.0),
                        ),
                      ])
              ]);
        });
  }
}
