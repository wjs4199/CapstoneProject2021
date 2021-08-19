import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../model/product.dart';
import '../main.dart';

class DetailPage extends StatefulWidget {

  DetailPage({this.productId, this.detailGiveOrTake});

  /// route 생성 시에 사용되는 product ID
  final String productId;

  /// giveProducts / takeProducts collection 중 어디서 가져와야하는 지 표시
  final String detailGiveOrTake;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  @override
  Widget build(BuildContext context) {

    ///******* ProductID와 맞는 게시물 내용을 Firebase 에서 찾아내는 부분 *******///

    /// DetailPage() 호출시 받는 매개변수 참조
    var productId = widget.productId;
    var detailGiveOrTake = widget.detailGiveOrTake;

    /// detailGiveOrTake 가 담고 있는 collection 이름에 따라 그 collection 담긴 내용 가져오기
    var products = detailGiveOrTake == 'giveProducts'
        ? context.watch<ApplicationState>().giveProducts
        : context.watch<ApplicationState>().takeProducts;

    /// 현재 유저의 아이디와 이름 간략화
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userName = FirebaseAuth.instance.currentUser.displayName;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈을 때 그 내용을 담을 변수
    Product product;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈는지 여부 표시 (찾아냈을 때 true)
    var productFound = false;

    /// products에 담긴 것들 중 현재 productId와 같은 것 찾기
    for (var i = 0; i < products.length; i++) {
      if (products[i].id == productId) {
        product = products[i];
        productFound = true;
        print(products.length);
        print(product.userName);
        print(product.uid);
      }
    }

    /// productId와 일치하는 게시글이 없을 경우 로딩 표시
    if (products == null ||
        products.isEmpty ||
        productFound == false ||
        product.modified == null) {
      return Scaffold(
        body: CircularProgressIndicator(),
      );
    }

    /// Firebase Storage 참조 간략화
    var storage = firebase_storage.FirebaseStorage.instance;

    /// ProductID에 따라 해당하는 image url 다운로드
    Future<String> downloadURL(String id) async {
      try {
        return await storage
            .ref()
            .child('images')
            .child('$id.png')
            .getDownloadURL();
      } on Exception {
        return null;
      }
    }

    /// 게시물 자체 삭제 기능 (왼쪽 상단 휴지통 버튼)
    Future<void> deleteProduct() async {
      try {
        return await FirebaseFirestore.instance
            .collection(detailGiveOrTake)
            .doc(productId)
            .delete();
      } on Exception {
        return null;
      }
    }


    ///************************ like 기능 구현부분 (수정필요) ************************///

    /// giveProducts 또는 takeProducts 중 어디에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference likes;
    if (detailGiveOrTake == 'giveProducts') {
      likes = FirebaseFirestore.instance
          .collection('giveProducts/' + productId + '/like');
    } else {
      likes = FirebaseFirestore.instance
          .collection('takeProducts/' + productId + '/like');
    }

    /// 현재는 하트버튼 누르면 사용자가 이미 눌렀든 말든 간에 계속 숫자 올라감 ㅋㅎ (수정필요)
    /// 현재 사용자가 이미 좋아요를 누른 경우를 분별하는 함수
    bool isLiked(AsyncSnapshot<QuerySnapshot> snapshot) {
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId) {
          return true;
        }
      });
      return false;
    }

    /// 사용자가 하트 누른 경우 좋아요 추가하는 기능
    Future<void> addLike() {
      return likes
          .add({'uid': userId})
          .then((value) => print('LIKED!'))
          .catchError((error) => print('Failed to add a like: $error'));
    }

    /// 좋아요 취소기능 (구현이 안됨 -> 다시 짜기)
    /* Future<void> deleteLike() async {
       try {
         return likes.doc(userId).delete();
       } on Exception {
         return null;
       }
     }*/


    ///************************* comments 기능 구현부분 *************************///

    /// 'comments' Collection 참조
    /// editted
    CollectionReference comments = FirebaseFirestore.instance
        .collection('giveProducts/' + productId + '/comment');

    /// comment 추가 기능
    Future<void> addComments(String comment) {
      return comments
          .add({
            'userName': FirebaseAuth.instance.currentUser.displayName,
            'comment': comment,
            'created': FieldValue.serverTimestamp(), ///editted
          })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
    }

    /// comment 삭제기능 (구현이 안됨 -> 다시 짜기)
    Future<void> deleteComments() async {
      try {
        return await FirebaseFirestore.instance
            .collection('comments/$productId/commentList')
            .doc(productId)
            .delete();
      } on Exception {
        return null;
      }
    }

    /// Add 페이지 화면 구성
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            semanticLabel: 'back',
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Detail'),
        centerTitle: true,
        actions: <Widget>[
          if (FirebaseAuth.instance.currentUser.uid == product.uid)
            IconButton(
                icon: Icon(
                  Icons.create,
                  semanticLabel: 'edit',
                ),
                onPressed:
                    (FirebaseAuth.instance.currentUser.uid == product.uid)
                        ? () => Navigator.pushNamed(
                              context,
                              '/edit/' + productId + '/' + detailGiveOrTake,
                            )
                        : null),
          if (FirebaseAuth.instance.currentUser.uid == product.uid)
            IconButton(
                icon: Icon(
                  Icons.delete,
                  semanticLabel: 'delete',
                ),
                onPressed: (FirebaseAuth.instance.currentUser.uid ==
                        product.uid)
                    ? () => showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: Text('Deleting Item'),
                              content: Text(
                                  'Are you sure that you want to delete this item?'),
                              actions: <Widget>[
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('No'),
                                ),
                                Consumer<ApplicationState>(
                                  builder: (context, appState, _) =>
                                      CupertinoDialogAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      deleteProduct()
                                          .then((value) => appState.init())
                                          .catchError((error) => null)
                                          .whenComplete(
                                              () => Navigator.pop(context));
                                    },
                                    child: Text('Yes'),
                                  ),
                                )
                              ],
                            ))
                    : null)
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Consumer<ApplicationState>(
              builder: (context, appState, _) => Container(
                width: MediaQuery.of(context).size.width,
                child: FutureBuilder(
                  future: downloadURL(productId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        children: [
                          SizedBox(height: 50),
                          Center(child: CircularProgressIndicator()),
                          SizedBox(height: 48),
                        ],
                      );
                    } else {
                      if (snapshot.hasData) {
                        return Image.network(snapshot.data.toString(),
                            fit: BoxFit.fitWidth);
                      } else if (snapshot.hasData == false) {
                        return Image.asset('assets/logo.png');
                      } else {
                        return Container(
                          child: Text('Snapshot Error!'),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
            Row(
              children: [
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.0),
                        Row(
                          children: [
                            Expanded(
                              flex: 8,
                              child: Text(
                                product.category,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff3792cb),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: likes.snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Error!');
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text('Loading');
                                  }
                                  var count = snapshot.data.size;
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          (isLiked(snapshot))
                                              ? Icons.favorite
                                              : Icons.favorite_outlined,
                                          color: Colors.red,
                                          semanticLabel: 'like',
                                        ),
                                        onPressed: () => (isLiked(snapshot))
                                            ? print('You can only like once!')
                                            : addLike(),
                                      ),
                                      Text(count.toString())
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(thickness: 1.0),
                        SizedBox(height: 8.0),
                        Text(
                          product.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xff296d98),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Divider(thickness: 1.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.userName.toString() +
                                  '                            ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff296d98),
                              ),
                            ),
                            Text(
                              DateFormat('yyyy.MM.dd HH:mm')
                                  .format(product.modified.toDate()),
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff296d98),
                              ),
                            ),
                          ],
                        ),
                        Divider(thickness: 1.0),
                        SizedBox(height: 8.0),
                        Text(
                          product.content ?? product.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xff3792cb),
                          ),
                        ),
                        Divider(thickness: 1.0),
                      ]),
                ),
                SizedBox(width: 12),
              ],
            ),
            Container(
                padding: const EdgeInsets.all(8.0),
                child: CommentBook(
                  addComments: (String comment) => addComments(comment),
                  deleteComments: () => deleteComments(),
                  detailGiveOrTake: detailGiveOrTake,
                  productId: productId,
                  userName: userName,
                ))
          ],
        ),
      ),
    );
  }
}

class CommentBook extends StatefulWidget {
  CommentBook(
      {this.addComments,
      this.detailGiveOrTake,
      this.productId,
      this.deleteComments,
      this.userName}); //, required this.dates
  final Future<void> Function(String message) addComments;
  final Future<void> Function() deleteComments;
  final String productId;
  final String detailGiveOrTake;
  final String userName;

  @override
  _CommentBookState createState() => _CommentBookState();
}

class _CommentBookState extends State<CommentBook> {
  final _commentFormKey = GlobalKey<FormState>(debugLabel: '_CommentState');
  final _commentController = TextEditingController();

  Future<String> convertDateTime(Timestamp time) async {
    //await Future.delayed(Duration(seconds: 1));
    try {
      return DateFormat('MM.dd HH:mm').format(time.toDate());
    } on Exception {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var comments =
        Provider.of<ApplicationState>(context, listen: false).commentContext;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Form(
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
                    widget
                        .addComments(_commentController.text)
                        .then((value) => print('addcomment ok!'));
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
      ),
      SizedBox(height: 8),
      for (var eachComment in comments)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 5, 0.0, 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    radius: 15,
                    child: Image.asset('assets/userDefault.png'),
                    //backgroundColor: Colors.
                  ),
                  SizedBox(width: 7.0),
                  FutureBuilder(
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
                        //
                        _buildCommentToggleButtons(
                            context,
                            Provider.of<ApplicationState>(context,
                                listen: false)),
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

  final List<bool> _selections = List.generate(3, (_) => false);

  ToggleButtons _buildCommentToggleButtons(
      BuildContext context, ApplicationState appState) {
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
            print(widget.userName);
            /////
            if (FirebaseAuth.instance.currentUser.displayName ==
                widget.userName) {
              print('same userName');

              showDialog(
                  context: context,
                  builder: (BuildContext context) => CupertinoAlertDialog(
                        title: Text('Deleting Item'),
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
                              widget
                                  .deleteComments()
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

            /////
          }
        });
      },

/*onPressed: (int index) {
        setState(() {
          if (index == 2) {
            print('push delete button!');
          }
        });
      },*/

//_selections[2] = !_selections[1];
//나중에는 애타처럼 시간 옆에 손가락 뜨도록 만들기
/*덧글좋아요 컬랙션에 추가*/
/*----------------------
          else {
            _selections[1] = false;
          }
            else if(index == 0){
              //채팅으로 이동
            }
            else if(index == 2){
              //더보기 -> 삭제, 수정 기능
            }
            -----------------------*/

/*if (_selections[index] == true) {
            if (index == 0)
             //
            else if (index == 1)
              //
            else
              //
          } else {
            //
          }*/

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
}
