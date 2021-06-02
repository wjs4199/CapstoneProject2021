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
  final String productId;
  final String detailGiveOrTake;

  DetailPage({this.productId, this.detailGiveOrTake});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  //firebase에서 저장된 comments가져오기
  List<Comment> _commentsList = [];
  List<Comment> get commentsList => _commentsList;

  Scaffold _buildScaffold() {
    String productId = this.widget.productId;
    String detailGiveOrTake = this.widget.detailGiveOrTake;

    List<Product> products = detailGiveOrTake == 'giveProducts'
        ? context.watch<ApplicationState>().giveProducts
        : context.watch<ApplicationState>().takeProducts;
    Product product;
    String userId = FirebaseAuth.instance.currentUser.uid;
    String userName;
    bool productFound = false;

    for (int i = 0; i < products.length; i++) {
      if (products[i].id == productId) {
        product = products[i];
        userName = product.userName;

        print(product.userName);
        print(product.uid);

        productFound = true;
      }
    }

    //product uid에 해당하는 commentContext 가져오기
    context.watch<ApplicationState>().detailPageUid(productId);
    // List<Comment> commentContext =context.watch<ApplicationState>().commentContext;

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
    firebase_storage.FirebaseStorage storage =
        firebase_storage.FirebaseStorage.instance;

    // Download image url of each product based on id
    Future<String> downloadURL(String id) async {
      await Future.delayed(Duration(seconds: 2));
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
    /*// Delete like
      Future<void> deleteLike() async {
        try {
          return await FirebaseFirestore.instance
              .collection(detailGiveOrTake)
              .doc(productId)
              .snapshots()
              .['likes']
              .delete();
        } on Exception {
          return null;
        }
      }*/

    Future<void> addComments(String comment) {
      return comments
          .add({
            'userName': userName,
            'comment': comment,
            'time': FieldValue.serverTimestamp(),
          })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
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

    // Check if already liked
    bool isLiked(AsyncSnapshot<QuerySnapshot> snapshot) {
      bool liked = false;
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId) liked = true;
      });
      return liked;
    }

    /*List<Comment> getComments(AsyncSnapshot<QuerySnapshot> snapshot) {
      snapshot.data.docs.forEach((document) {
        _commentsList = [];
        _commentsList.add(Comment(
            userName: document['userName'],
            comment: document['comment'],
            time: document['time']));
      });
      return commentsList;
    }*/

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
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
                              title: Text("Deleting Item"),
                              content: Text(
                                  "Are you sure that you want to delete this item?"),
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
                                    child: Text("Yes"),
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
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
                Expanded(
                  flex: 8,
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
                            Consumer<ApplicationState>(
                              builder: (context, appState, _) => Expanded(
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
                                    int count = snapshot.data.size;
                                    return Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            (count != 0)
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
                            )
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
                      ]),
                ),
              ],
            ),
            Container(
                padding: const EdgeInsets.all(8.0),
                child: CommentBook(
                  addComments: (String comment) => addComments(comment),
                  //comments: commentContext,
                  productId: productId,
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }
}

/*class Comment {
  Comment({this.userName, this.comment, this.time});
  final String userName;
  final String comment;
  Timestamp time;
}
*/
class CommentBook extends StatefulWidget {
  CommentBook(
      {this.addComments,
      //this.comments,
      this.productId}); //, required this.dates
  final Future<void> Function(String message) addComments;
  //final List<Comment> comments;
  final String productId;

  @override
  _CommentBookState createState() => _CommentBookState();
}

class _CommentBookState extends State<CommentBook> {
  final _commentFormKey = GlobalKey<FormState>(debugLabel: '_CommentState');
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    List<Comment> comments = context.watch<ApplicationState>().commentContext;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Form(
        key: _commentFormKey,
        child: Row(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
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
            SizedBox(width: 5),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.blueAccent,
              onPressed: () async {
                setState(() {
                  if (_commentFormKey.currentState.validate()) {
                    widget.addComments(_commentController.text);
                    _commentController.clear();
                    context
                        .watch<ApplicationState>()
                        .detailPageUid(widget.productId);
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
        Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 10, 15.0, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  child: Text(eachComment.userName),
                  radius: 25,
                  //backgroundColor: Colors.
                ),
              ),
              Container(
                  padding: EdgeInsets.all(3.0),
                  width: 240,
                  child: RichText(
                      text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                        TextSpan(text: eachComment.comment + '\n'),
                        TextSpan(
                            text: DateFormat('yyyy.MM.dd HH:mm')
                                .format(eachComment.time.toDate())),
                      ]))),
              if (FirebaseAuth.instance.currentUser.displayName ==
                  eachComment.userName)
                IconButton(
                    onPressed: () {
                      print("this comment deleted!");
                    },
                    icon: Icon(Icons.delete_outline)),
              Divider(thickness: 1.0),
            ]))
    ]);
  }
}
