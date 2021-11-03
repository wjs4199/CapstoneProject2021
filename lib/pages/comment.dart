import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  var userNickName = 'null';

  /// 유저의 학번을 찾아서 보여주는 함수
  String findStudentNumber(AsyncSnapshot<QuerySnapshot> snapshot, String uid) {
    var email = '00';
    snapshot.data.docs.forEach((document) {
      if (document['id'] == uid) {
        email = document['email'];
      }
    });
    return email;
  }

  /// 유저의 닉네임을 찾아서 보여주는 함수
  String findNickname(AsyncSnapshot<QuerySnapshot> snapshot, String userId) {
    var nickName = 'null';
    snapshot.data.docs.forEach((document) {
      if (document['id'] == userId) {
        nickName = document['nickname'];
      }
    });
    return nickName;
  }

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<String> commentSetStream =
      StreamController<String>.broadcast();


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
    var commentsList = context.watch<ApplicationState>().commentContext;

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

    /// 사용자의 댓글에 달리는 삭제 버튼
    InkWell _CommentDeleteButtonsForUser(
        BuildContext context, ApplicationState appState, Comment comment) {
      return InkWell(
        child: Icon(
          Icons.clear_rounded,
          size: 16,
          color: Colors.black.withOpacity(0.2),
        ),
        onTap: () {
          setState(() {
            print('push delete button!');
            print(FirebaseAuth.instance.currentUser.displayName);
            print(userName);

            /// 사용자가 올린 댓글만 삭제 가능하도록 사용자 이름과 댓글 기록자의 이름을 비교(닉네임 비교로 수정 필요)
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
                            .catchError((error) => null);
                      },
                      child: Text('Yes'),
                    ),
                  ],
                ));
          });
        },
      );
    }

    /// 사용자의 댓글을 제외한 댓글들에 달리는 채팅하기 버튼
    InkWell _CommentChatButtonsForOthers(
        BuildContext context, ApplicationState appState, Comment comment) {
      return InkWell(
        child: Container(
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('채팅하기 ',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'NanumSquareRoundR',
                  height: 1.2,
                ),
              ),
              Image.asset(
                'assets/chat_grey.jpg',
                //'assets/chat.jpg',
                width: 13,
                height: 13,
              )
            ],
          ),
        ),
        onTap: () {
         //
        },
      );
    }


    /// ToggleButtons 위젯(대댓글, 좋아요, 삭제)

    /*
     var _selectionsForOthers = List<bool>.generate(1, (_) => false);
    ToggleButtons _buildCommentToggleButtonsForOthers(
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
        isSelected: _selectionsForOthers,
        onPressed: (int index) {
          setState(() {
            /*if (index == 0) {
              print('push delete button!');
              print(FirebaseAuth.instance.currentUser.displayName);
              print(userName);

              /// 사용자가 올린 댓글만 삭제 가능하도록 사용자 이름과 댓글 기록자의 이름을 비교(닉네임 비교로 수정 필요)

              if (comment.userName == userName) {
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
                                .catchError((error) => null);
                          },
                          child: Text('Yes'),
                        ),
                      ],
                    ));
              } else {
                null;
              }
            }*/
          });
        },
        children: [
          Icon(
            Icons.chat,
            size: 15,
          ),
      /*Icon(
            Icons.more_horiz,
            size: 15,
          ),
          Icon(
            Icons.delete,
            size: 15,
          ),*/
        ],
      );
    }*/


    /// ********************************** 시간 계산하는 함수들 ********************************///

    Future<String> returnDate(Timestamp time) async {
      //await Future.delayed(Duration(seconds: 1));
      try {
        return DateFormat('MM/dd HH:mm').format(time.toDate());
      } on Exception {
        return null;
      }
    }

    /// comment 를 적는 텍스트 상자의 상태를 control 할 때 사용
    final _commentController = TextEditingController();

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
          var commentEdit = false;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var eachComment in commentsList)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///사진, 이름, 토글버튼
                        Padding(
                            padding: const EdgeInsets.fromLTRB(10.0, 3, 10.0, 10),
                            child: StreamBuilder<QuerySnapshot>(
                                stream: users.snapshots(),
                                builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot2) {
                                if (snapshot2.hasError) {
                                return Text('x');
                                }
                                if (snapshot2.connectionState ==
                                ConnectionState.waiting) {
                                return Text('');
                                }
                                userNickName = findNickname(snapshot2, userId);
                                return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment : CrossAxisAlignment.start,
                              children: [
                                /// 사용자의 구글 이메일 프로필 사진으로 바꾸는 작업 필요
                                SizedBox(
                                  width: 35,
                                  height: 35,
                                  child: Image.asset(
                                      'assets/userDefaultImage.png'),
                                  ),
                                  SizedBox(width: 8.5),
                                  /// 닉네임
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 1),
                                      Text(findNickname(snapshot2, eachComment.uid),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NanumSquareRoundR',
                                          )),
                                      SizedBox(height: 4),
                                      FutureBuilder(
                                        future: returnDate(eachComment.created),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Text('    ');
                                          }
                                          else {
                                            //print('${findStudentNumber(snapshot2, eachComment.nickName)}학번');
                                            return Text( findStudentNumber(snapshot2, eachComment.uid).substring(1,3) + '학번',
                                                  style: TextStyle(
                                                    color: Colors.black.withOpacity(0.3),
                                                    fontSize: 11,
                                                    fontFamily: 'NanumSquareRoundR',
                                                  ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  ///토글버튼
                                  Expanded(
                                      child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            /// 댓글마다 대댓글, 좋아요, 삭제 기능을 담당하는 버튼 생성
                                            if(userNickName == findNickname(snapshot2, eachComment.uid))
                                              _CommentDeleteButtonsForUser(context,
                                                  Provider.of<ApplicationState>(context, listen: false), eachComment)
                                            else
                                             _CommentChatButtonsForOthers(
                                                  context,
                                                  Provider.of<ApplicationState>(context, listen: false), eachComment
                                             ),
                                        //SizedBox(width: 10),
                                      ]
                                      )
                                  )
                              ],
                            );})
                        ),
                        /// comment 내용
                        Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 10.0),
                                  if(commentEdit)
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          //padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.5),
                                          width: MediaQuery.of(context).size.width - 36,
                                          child: TextFormField(
                                            autofocus: true,
                                            keyboardType: TextInputType.multiline,
                                            maxLines: 30,
                                            initialValue: eachComment.comment,
                                            controller: _commentController,
                                            decoration: const InputDecoration(

                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                            ),
                                          ),
                                        ),

                                      ],
                                    ),

                                  Container(
                                    //padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.3, 0),
                                    width: MediaQuery.of(context).size.width - 35,
                                    child: RichText(
                                        maxLines: 20,
                                        text: TextSpan(
                                            style: TextStyle(
                                                fontSize: 16.5,
                                                color: Colors.black,
                                                height: 1.05,
                                                fontFamily: 'NanumSquareRoundR',
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(text: eachComment.comment + '\n'),
                                            ])
                                    ),
                                  ),
                                  SizedBox(width: 5.0),
                                ]
                        ),
                        /// 날짜
                        FutureBuilder(
                          future: returnDate(eachComment.created),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Column(
                                children: [
                                  Container(
                                    child: Text('    '),
                                  )
                                ],
                              );
                            }
                            else {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: users.snapshots(),
                                    builder: (BuildContext context,
                                      AsyncSnapshot<QuerySnapshot> snapshot2) {
                                      if (snapshot2.hasError) {
                                        return Text('x');
                                      }
                                      if (snapshot2.connectionState == ConnectionState.waiting) {
                                      return Text('');
                                      }
                                      return Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text( snapshot.data == null ? 'null': snapshot.data + ' ',
                                              style: TextStyle(
                                                color: Colors.black.withOpacity(0.4),
                                                fontSize: 11,
                                                fontFamily: 'NanumSquareRoundR',
                                              ),),
                                            /*if( findNickname(snapshot2,userName) != eachComment.nickName)
                                              _CommentChatButtonsForOthers(
                                                  context,
                                                  Provider.of<ApplicationState>(context, listen: false), eachComment
                                              ),*/
                                          ],
                                        ),
                                      );
                                    }),
                                  SizedBox(
                                    width: 10,
                                  )
                                ],
                              );
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(11, 2, 11, 0),
                          child: Divider(thickness: 1.0),
                        ),
                      ])
              ]);
        });
  }
}
