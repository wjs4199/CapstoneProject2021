import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';

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
  Scaffold _buildScaffold(BuildContext context, ApplicationState appState) {
    String productId = this.widget.productId;
    String detailGiveOrTake = this.widget.detailGiveOrTake;

    List<Product> Products = detailGiveOrTake == 'giveProducts'
        ? appState.giveProducts
        : appState.takeProducts;
    Product product;
    String userId = FirebaseAuth.instance.currentUser.uid;
    bool productFound = false;

    for (int i = 0; i < Products.length; i++) {
      if (Products[i].id == productId) {
        product = Products[i];
        productFound = true;
      }
    }

    if (Products == null ||
        Products.isEmpty ||
        productFound == false ||
        product.modified == null) {
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

    // Add a like
    Future<void> addLike() {
      return likes
          .add({'uid': userId})
          .then((value) => print('LIKED!'))
          .catchError((error) => print('Failed to add a like: $error'));
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
                              ],
                            ))
                    : null)
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              child: FutureBuilder(
                future: downloadURL(productId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        SizedBox(height: 96),
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
                      SizedBox(height: 48.0),
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
                                int count = snapshot.data.size;
                                return Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        (count != 0)
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_alt_outlined,
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
                      SizedBox(height: 8.0),
                      Text(
                        product.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xff296d98),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Divider(thickness: 1.0),
                      SizedBox(height: 16.0),
                      Text(
                        product.content ?? product.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff3792cb),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) => _buildScaffold(context, appState),
    );
  }
}
