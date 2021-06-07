import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'product.dart';
import 'main.dart';

class DetailPage extends StatefulWidget {
  DetailPage({this.productId, this.detailGiveOrTake});

  final String productId;
  final String detailGiveOrTake;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    var likeList = context.watch<ApplicationState>().likeList;
    var likeCount = context.watch<ApplicationState>().likeCount;

    print('likeList-> $likeList');

    var productId = widget.productId;
    var detailGiveOrTake = widget.detailGiveOrTake;

    var products = detailGiveOrTake == 'giveProducts'
        ? context.watch<ApplicationState>().giveProducts
        : context.watch<ApplicationState>().takeProducts;
    Product product;
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userName = FirebaseAuth.instance.currentUser.displayName;
    var productFound = false;

    for (var i = 0; i < products.length; i++) {
      if (products[i].id == productId) {
        product = products[i];

        print(product.userName);
        print(product.uid);

        productFound = true;
      }
    }

    if (products == null ||
        products.isEmpty ||
        productFound == false ||
        product.modified == null) {
      print("로딩중");
      return Scaffold(
        body: CircularProgressIndicator(),
      );
    }

    // Set name for Firebase Storage
    var storage = firebase_storage.FirebaseStorage.instance;

    // Download image url of each product based on id
    Future<String> downloadURL(String id) async {
      //await Future.delayed(Duration(seconds: 1));
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

    // Get Likes
    CollectionReference likes;
    if (detailGiveOrTake == 'giveProducts') {
      likes = FirebaseFirestore.instance
          .collection('giveProducts/' + productId + '/like');
    } else {
      likes = FirebaseFirestore.instance
          .collection('takeProducts/' + productId + '/like');
    }

    // Collection 참조 ->  comments
    CollectionReference comments;
    comments = FirebaseFirestore.instance
        .collection('comments/' + productId + '/commentList');

    // Add a like
    Future<void> addLike() {
      return likes
          .add({'uid': userId})
          .then((value) => print('LIKED!'))
          .catchError((error) => print('Failed to add a like: $error'));
    }

    // Delete like
    Future<void> deleteLike() async {
      try {
        return likes.doc(userId).delete();
      } on Exception {
        return null;
      }
    }

    // Delete item
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

    // Delete comment
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

    // Check if already liked
    bool isLiked(AsyncSnapshot<QuerySnapshot> snapshot) {
      bool liked = false;
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId) liked = true;
      });
      return liked;
    }

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
                                  child: Text("No"),
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
                                  "                            ",
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
      return await DateFormat('MM.dd HH:mm').format(time.toDate());
    } on Exception {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var comments = context.watch<ApplicationState>().commentContext;

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
              icon: const Icon(Icons.send),
              iconSize: 38,
              color: Colors.blueAccent,
              onPressed: () async {
                var currentFocus = FocusScope.of(context);
                currentFocus.unfocus();
                setState(() {
                  if (_commentFormKey.currentState.validate()) {
                    widget
                        .addComments(_commentController.text)
                        .then((value) => print('addcomment ok!'));
                    _commentController.clear();
                    context.watch<ApplicationState>().detailPageUid(
                        widget.productId, widget.detailGiveOrTake);
                    print("clear!");
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
                    future: convertDateTime(eachComment.time),
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
                  /*Expanded(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                        _buildCommentToggleButtons(
                            context, context.watch<ApplicationState>()),
                        SizedBox(width: 10),
                      ]))*/
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

  List<bool> _selections = List.generate(3, (_) => false);

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
                            child: Text("No"),
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
