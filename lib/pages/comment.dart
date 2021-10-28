import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  var commentNickName = 'null';

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

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<String> commentSetStream = StreamController<String>.broadcast();

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
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var eachComment in commentsList)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.fromLTRB(10.0, 5, 0.0, 13),
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
                                      userNickName = findNickname(snapshot, FirebaseAuth.instance.currentUser.displayName);
                                      commentNickName = findNickname(snapshot, eachComment.userName);
                                      print('commentNickName : $commentNickName');
                                      print('userNickName : $userNickName');
                                      print('eachComment.userName의 닉네임: ${findNickname(snapshot, eachComment.userName)}');
                                      print('userName : $userName');
                                      return SizedBox(
                                        height: 30,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 5),
                                            Text(findNickname(snapshot, eachComment.userName),
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
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          /// 댓글마다 대댓글, 좋아요, 삭제 기능을 담당하는 토글버튼 생성
                                          if(commentNickName == userNickName)
                                            _buildCommentToggleButtons(
                                              context,
                                              Provider.of<ApplicationState>(context, listen: false), eachComment
                                            ),
                                      SizedBox(width: 10),
                                    ]))
                              ],
                            )
                        ),
                        Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: 11.0),
                                  Container(
                                    //padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.5),
                                    width: MediaQuery.of(context).size.width - 36,
                                    child: RichText(
                                        maxLines: 30,
                                        text: TextSpan(
                                            style: TextStyle(
                                                fontSize: 16.5,
                                                color: Colors.black,
                                                height: 1.05
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(text: eachComment.comment + '\n'),
                                            ])
                                    ),
                                  ),
                                  SizedBox(width: 9.0),
                                ]
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
                          child: Divider(thickness: 1.0),
                        ),
                      ])
              ]);
        });
  }
}

class CommentBoxPage extends StatefulWidget {

  CommentBoxPage({this.productId, this.detailGiveOrTake, this.photoNum});

  /// route 생성 시에 사용되는 product ID
  final String productId;

  /// giveProducts / takeProducts collection 중 어디서 가져와야하는 지 표시
  final String detailGiveOrTake;

  /// 저장된 photo의 개수
  final int photoNum;
  @override
  _CommentBoxState createState() => _CommentBoxState();
}

class _CommentBoxState extends State<CommentBoxPage> {

  /// detail 페이지 실행시 인자로 전달되는 변수들
  String productId ; // product ID
  String detailGiveOrTake; // giveProducts / takeProducts 중 어디 해당되는지
  int photoNum; // 저장된 photo 의 개수

  @override
  void initState() {
    super.initState();

    productId = widget.productId; // product ID
    detailGiveOrTake = widget.detailGiveOrTake; // giveProducts / takeProducts 중 어디 해당되는지
    photoNum = widget.photoNum; // 저장된 photo 의 개수
  }

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<bool> pushLikeButton = StreamController<bool>.broadcast();

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
   StreamController<int> changeLikeCount = StreamController<int>.broadcast();

  // Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<Icon> changeFavoriteButton = StreamController<Icon>.broadcast();

  // Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<String> changeTextField = StreamController<String>.broadcast();

  /// comment 를 적는 텍스트 상자의 상태를 control 할 때 사용
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    ///************ ProductID와 맞는 게시물 내용을 Firebase 에서 찾아내는 부분 ************///
    /// DetailPage() 호출시 받는 매개변수 참조
    var productId = widget.productId;
    var detailGiveOrTake = widget.detailGiveOrTake;

    /// detailGiveOrTake 가 담고 있는 collection 이름에 따라 그 collection 담긴 내용 가져오기
    // 시작하자마자 이부분에서 build가 2번 되길래 watch에서 read로 바꿈
    var products = detailGiveOrTake == 'giveProducts'
        ? context.read<ApplicationState>().giveProducts
        : context.read<ApplicationState>().takeProducts;


    /// 현재 유저의 아이디와 이름 간략화
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userName = FirebaseAuth.instance.currentUser.displayName;


    ///************************ like 기능 구현부분 (수정필요) ************************///

    /// giveProducts 또는 takeProducts 중 어디에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference likes = FirebaseFirestore.instance
        .collection('${widget.detailGiveOrTake}/' + productId + '/like');

    /// 현재는 하트버튼 누르면 사용자가 이미 눌렀든 말든 간에 계속 숫자 올라감 ㅋㅎ (수정필요)
    /// 현재 사용자가 이미 좋아요를 누른 경우를 분별하는 함수
    bool isLiked( AsyncSnapshot<QuerySnapshot> snapshot){
      var isLikeCheck = false;
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId){
          isLikeCheck = true;
        }
      });

      if(isLikeCheck){
        print('isLiked에서 좋아요는 지금 true 상태!!');
      } else{
        print('isLiked에서 좋아요는 지금 false 상태ㅠㅠ');
      }

      return isLikeCheck;
    }

    /// 사용자가 하트 누른 경우 좋아요 추가하는 기능
    Future<void> addLike() async {
      return await likes
          .add({'uid': userId})
          .then((value) => print('LIKE 추가됨!'))
          .catchError((error) => print('Failed to add a like: $error'));
    }

    /// 좋아요 취소기능
    Future<void> deleteLike(userId) async {
      try {
        for (var eachLike in context.read<ApplicationState>().likeList){
          if(eachLike.uid == userId){
            await likes
                .doc(eachLike.id)
                .delete()
                .then((value) => print('LIKE 취소됨! 취소된 uid 는 ${eachLike.id}'))
                .catchError((error) => print('Failed to add a like: $error'));
          }
        }
      } on Exception {
        return null;
      }
    }

    /// 'comments' Collection 참조
    CollectionReference comments = FirebaseFirestore.instance
        .collection('giveProducts/' + productId + '/comment');

    /// comment 추가 기능
    Future<void> addComments(String comment) {
      return comments
          .add({
        'userName': FirebaseAuth.instance.currentUser.displayName,
        'comment': comment,
        'created': FieldValue.serverTimestamp(),
      })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
    }

    var currentFocus = FocusScope.of(context);
    return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.057,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Color(0xffe5e5e5),
              boxShadow: [
                BoxShadow(color: Color(0xffe5e5e5), spreadRadius: 2),
              ],
            ),
            margin: EdgeInsets.fromLTRB(7.0, 7.0, 7.0, 0.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  child: StreamBuilder<QuerySnapshot>(
                      stream: likes.snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text('x');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('');
                        }
                        return StreamBuilder <Icon> (
                            stream: changeFavoriteButton.stream,
                            initialData: isLiked(snapshot)
                                ? Icon(Icons.favorite,
                              color: Colors.red,
                              semanticLabel: 'like',
                            )
                                : Icon(Icons.favorite_border_outlined,
                              color: Colors.red,
                              semanticLabel: 'like',
                            ),
                            builder: (context, snapshot2) {
                              /// changeFavoriteButton 스트림 컨트롤러에 새 데이터가 들어올때마다 부분적으로 빌드됨
                              return IconButton(
                                /// 아이콘의 snapshot2 => changeFavoriteButton 스트림으로 건네준 아이콘
                                  icon: snapshot2.data,
                                  onPressed: () async {
                                    /// 이미 좋아요가 눌러져 있었을 떄
                                    if(isLiked(snapshot)) {
                                      await deleteLike(userId)
                                          .catchError((error) => null)
                                          .whenComplete(() {
                                        products = detailGiveOrTake == 'giveProducts'
                                            ? context.read<ApplicationState>().giveProducts
                                            : context.read<ApplicationState>().takeProducts;
                                        changeFavoriteButton.add(Icon(Icons.favorite_border_outlined,
                                          color: Colors.red, semanticLabel: 'like',));
                                        changeLikeCount.add(context.read<ApplicationState>().likeCount);
                                      });
                                    }
                                    /// 좋아요가 눌러져 있지 않을 때
                                    else {
                                      await addLike()
                                          .catchError((error) => null)
                                          .whenComplete(() {
                                        products = detailGiveOrTake == 'giveProducts'
                                            ? context.read<ApplicationState>().giveProducts
                                            : context.read<ApplicationState>().takeProducts;
                                        changeFavoriteButton.add(Icon(Icons.favorite,
                                          color: Colors.red, semanticLabel: 'like',));
                                        changeLikeCount.add(context.read<ApplicationState>().likeCount);
                                      });
                                    }
                                  }
                              );
                            }
                        );
                      }),
                ),
                Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10.0, 1, 10, 5),
                      child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: '댓글을 입력하세요',
                          ),
                          onSubmitted: (value) {
                            //if (value == null || value.isEmpty) {
                            //return '댓글을 입력하세요';
                            //}
                            //return null;
                          },
                          onChanged: (value) {
                            changeTextField.add(value);
                          }
                      ),
                    )
                ),
                SizedBox(width: 3),
                StreamBuilder(
                    stream: changeTextField.stream,
                    builder: (context, snapshot) {
                      return IconButton(
                        icon: const Icon(Icons.send_outlined),
                        iconSize: 27,
                        color: Color(0xffc32323),
                        onPressed: () async {
                          _commentController.clear();
                          currentFocus.unfocus();
                          await addComments(snapshot.data)
                              .then((value) {
                            print(snapshot.data);
                            print('add comment ok!');
                            context.read<ApplicationState>().init();
                          }). whenComplete(() => context.read<ApplicationState>().commentContext);
                          //_commentController.clear();
                          print('clear!');
                        },
                      );
                    }
                ),
              ],
            ),
          ),

        ],
      );
  }
}

