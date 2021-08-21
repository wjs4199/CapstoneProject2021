import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../model/product.dart';
import '../main.dart';


class CommentBook extends StatefulWidget {
  CommentBook({this.detailGiveOrTake, this.productId,}); //, required this.dates

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

  /// comment 적는 텍스트 칸이 빈칸인지 아닌지 분별할 때 사용됨
  final _commentFormKey = GlobalKey<FormState>(debugLabel: '_CommentState');

  /// comment 를 적는 텍스트 상자의 상태를 control 할 때 사용
  final _commentController = TextEditingController();

  /// 해당 댓글이 달린 Timestamp 형식의 시간을 UI에 표기 가능한 형식으로 바꾸는 함수
  Future<String> convertDateTime(Timestamp time) async {
    try {
      return DateFormat('MM.dd HH:mm').format(time.toDate());
    } on Exception {
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {

    ///******** comment 의 추가/삭제에 따라 Firebase 와 연동시키기 위해 필요한 변수/함수 ********///

    /// comment 가 어느 게시물 밑에 달린 것인지 알기 위해 필요한 Product ID
    var productId = widget.productId;

    /// 'comments' Collection 참조
    CollectionReference comments = FirebaseFirestore.instance
        .collection('comments/' + productId + '/commentList');

    /// 해당 productId에 부합하는 게시물에 담긴 comment 들을 가져와 담을 변수
    var commentsList =
        Provider.of<ApplicationState>(context, listen: false).commentContext;

    /// comment 추가 기능
    Future<void> addComments(String comment) {
      return comments
          .add({
        'userName': FirebaseAuth.instance.currentUser.displayName,
        'comment': comment,
        'time': FieldValue.serverTimestamp(),
      })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
    }
/*
    /// comment 삭제기능 (구현이 안됨 -> 다시 짜기)
    Future<void> deleteComments(Comment comment) async {
      try {
        for (var eachComment in commentsList){
          if(eachComment.id == comment.id){
            return await FirebaseFirestore.instance
                .collection('comments/$productId/commentList')
                .doc(comment.id)
                .delete();
          }
        }
      } on Exception {
        return null;
      }
    }

 */
    /// ToggleButtons 내의 대댓글, 좋아요, 삭제 버튼의 상태를 표시하기 위해 필요한 리스트 변수
    var _selections = List<bool>.generate(3, (_) => false);

    /// 보기 쉽게 빼려고 하였으나 deleteComments() 함수 아래에 있어야해서...여기로 옴...
    /// 왜 ToggleButtons 매개변수로 deleteComments()가 전달시키면 가능!(나는 실패..)
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
              if (FirebaseAuth.instance.currentUser.displayName ==
                  userName) {
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
                           // deleteComments(comment)
                           //     .then((value) => appState.init())
                             //   .catchError((error) => null);

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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      /*Form(
        key: _commentFormKey,
        child: Row(
          children: [
            Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 1, 10, 5),
                  child: TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Leave a comment',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your message to continue';
                      }
                      return null;
                    },
                  ),
                )),
            SizedBox(width: 3),
            IconButton(
              icon: const Icon(Icons.comment),
              iconSize: 38,
              color: Colors.cyan,
              onPressed: () async {
                var currentFocus = FocusScope.of(context);
                currentFocus.unfocus();
                setState(() {
                  if (_commentFormKey.currentState.validate()) {
                    addComments(_commentController.text)
                        .then((value) => print('add comment ok!'));
                    _commentController.clear();
                    Provider.of<ApplicationState>(context, listen: false)
                        .detailPageUid(
                        widget.productId, widget.detailGiveOrTake);
                    print('clear!');
                  }
                });
              },
            ),
          ],
        ),
      ),*/

      for (var eachComment in commentsList)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 5, 0.0, 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /// 사용자의 구글 이메일 프로필 사진으로 바꾸는 작업 필요
                  CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    radius: 15,
                    child: Image.asset('assets/userDefault.png'),
                  ),
                  SizedBox(width: 7.0),
                  FutureBuilder(
                    /// 지금은 댓글 단 시간이 안들어가 있지만 원래 시간도 댓글마다 표기하려 했으므로 futrue에 사용됨
                    future: convertDateTime(eachComment.created),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            SizedBox(
                                width: 5,
                                height: 5,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey),
                                  strokeWidth: 1.0,
                                )),
                          ],
                        );
                      } else {
                        if (snapshot.hasData) {
                          return Text(eachComment.userName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ));
                        } else if (snapshot.hasData == false) {
                          return Text('알수없음',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ));
                        } else {
                          return Container(
                            child: Text('Snapshot Error!'),
                          );
                        }
                      }
                    },
                  ),
                  Expanded(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            /// 댓글마다 대댓글, 좋아요, 삭제 기능을 담당하는 토글버튼 생성
                            _buildCommentToggleButtons(
                                context,
                                Provider.of<ApplicationState>(context, listen: false),
                                eachComment
                            ),
                            SizedBox(width: 10),
                          ]))
                ],
              )),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            SizedBox(width: 10.0),
            RichText(
                text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      TextSpan(text: eachComment.comment + '\n'),
                    ])),
          ]),
          Divider(thickness: 1.0),
        ])
    ]);
  }
}
