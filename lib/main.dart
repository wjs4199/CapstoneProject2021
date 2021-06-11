import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'login.dart';
import 'detail.dart';
import 'chart.dart';
import 'map.dart';
import 'product.dart';
import 'add.dart';
import 'edit.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => Application(),
    ),
  );
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Give_N_Take',
            home: HomePage(),
            initialRoute: '/login',

            // Named Routes
            routes: {
              '/login': (context) => LoginPage(),
              '/home': (context) => HomePage(),
              '/giveadd': (context) => giveAddPage(),
              '/takeadd': (context) => takeAddPage(),
              '/map': (context) => MapPage(),
            },

            // 동적 경로할당
            onGenerateRoute: (RouteSettings settings) {
              final List<String> pathElements = settings.name.split('/');
              //detail 페이지로 이동시키는 동적 경로할당
              if (pathElements[1] == 'detail' &&
                  pathElements[3] == 'giveProducts') {
                return MaterialPageRoute(
                    builder: (_) => DetailPage(
                        productId: pathElements[2],
                        detailGiveOrTake: 'giveProducts'));
              } else if (pathElements[1] == 'detail' &&
                  pathElements[3] == 'takeProducts') {
                return MaterialPageRoute(
                    builder: (_) => DetailPage(
                        productId: pathElements[2],
                        detailGiveOrTake: 'takeProducts'));
              }
              //edit 페이지로 이동시키는 동적 경로할당
              if (pathElements[1] == 'edit' &&
                  pathElements[3] == 'giveProducts') {
                return MaterialPageRoute(
                    builder: (_) => EditPage(
                        productId: pathElements[2],
                        editGiveOrTake: 'giveProducts'));
              } else if (pathElements[1] == 'edit' &&
                  pathElements[3] == 'takeProducts') {
                return MaterialPageRoute(
                    builder: (_) => EditPage(
                        productId: pathElements[2],
                        editGiveOrTake: 'takeProducts'));
              }
              return null;
            },
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class ApplicationState extends ChangeNotifier {
  String orderBy;
  String uid;
  String detailGiveOrTake;

  void detailPageUid(String uid, String detailGiveOrTake) {
    this.uid = uid;
    this.detailGiveOrTake = detailGiveOrTake;
    print("detail page uid -> " + uid);
    init();
  }

  void orderByFilter(String orderBy) {
    this.orderBy = orderBy;
    print("filtering ->  " + orderBy);
    init();
  }

  ApplicationState() {
    orderBy = 'All';
    uid = "null";
    init();
  }

  List<Product> _giveProducts = [];
  List<Product> _takeProducts = [];
  List<Comment> _commentContext = [];
  List<Like> _likeList = [];
  int likeCount = 0;

  Stream<QuerySnapshot> currentStream;

  //collection 'giveProducts' 파이어베이스에서 불러오기
  Future<void> init() async {
    // FirebaseFirestore.instance
    if (orderBy != 'All') {
      FirebaseFirestore.instance
          .collection('giveProducts')
          .where('category', isEqualTo: orderBy)
          .orderBy('modified', descending: true)
          .snapshots()
          .listen((snapshot) {
        _giveProducts = [];
        snapshot.docs.forEach((document) {
          _giveProducts.add(Product(
            id: document.id,
            title: document.data()['title'],
            content: document.data()['content'],
            category: document.data()['category'],
            created: document.data()['created'],
            modified: document.data()['modified'],
            userName: document.data()['userName'],
            uid: document.data()['uid'],
            likes: document.data()['like'],
            mark: document.data()['mark'],
            comments: document.data()['comments'],
          ));
        });
        notifyListeners();
      });

      //collection 'takeProducts' 파이어베이스에서 불러오기
      FirebaseFirestore.instance
          .collection('takeProducts')
          .where('category', isEqualTo: orderBy)
          .orderBy('modified', descending: true)
          .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
          .listen((snapshot) {
        _takeProducts = [];
        snapshot.docs.forEach((document) {
          _takeProducts.add(Product(
            id: document.id,
            title: document.data()['title'],
            content: document.data()['content'],
            category: document.data()['category'],
            created: document.data()['created'],
            modified: document.data()['modified'],
            userName: document.data()['userName'],
            uid: document.data()['uid'],
            likes: document.data()['like'],
            mark: document.data()['mark'],
            comments: document.data()['comments'],
          ));
        });
        notifyListeners();
      });
    } else {
      FirebaseFirestore.instance
          .collection('giveProducts')
          .orderBy('modified', descending: true)
          .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
          .listen((snapshot) {
        _giveProducts = [];
        snapshot.docs.forEach((document) {
          //A non null string must be provided to a text widget
          //밑에는 위의 오류 때문에 넣은 부분
          String content = document.data()['content'];
          if (content == null) {
            content = "글 읽기 실패";
          }
          _giveProducts.add(Product(
            id: document.id,
            title: document.data()['title'],
            content: content,
            category: document.data()['category'],
            created: document.data()['created'],
            modified: document.data()['modified'],
            userName: document.data()['userName'],
            uid: document.data()['uid'],
          ));
        });
        notifyListeners();
      });

      //collection 'takeProducts' 파이어베이스에서 불러오기
      FirebaseFirestore.instance
          .collection('takeProducts')
          .orderBy('modified', descending: true)
          .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
          .listen((snapshot) {
        _takeProducts = [];
        snapshot.docs.forEach((document) {
          _takeProducts.add(Product(
            id: document.id,
            title: document.data()['title'],
            content: document.data()['content'],
            category: document.data()['category'],
            created: document.data()['created'],
            modified: document.data()['modified'],
            userName: document.data()['userName'],
            uid: document.data()['uid'],
          ));
        });
        notifyListeners();
      });
    }

    if (uid != "null") {
      FirebaseFirestore.instance
          .collection('comments/' + uid + '/commentList')
          .orderBy('time', descending: true)
          .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
          .listen((snapshot) {
        _commentContext = [];
        snapshot.docs.forEach((document) {
          _commentContext.add(Comment(
            userName: document.data()['userName'],
            comment: document.data()['comment'],
            time: document.data()['time'],
          ));
        });
        notifyListeners();
      });

      FirebaseFirestore.instance
          .collection(detailGiveOrTake + '/' + uid + '/like')
          .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
          .listen((snapshot) {
        _likeList = [];
        snapshot.docs.forEach((document) {
          _likeList.add(Like(
            uid: document.data()['uid'],
          ));
        });
        likeCount = _likeList.length;
        notifyListeners();
      });
    }
  }

  List<Product> get giveProducts => _giveProducts;
  List<Product> get takeProducts => _takeProducts;
  List<Comment> get commentContext => _commentContext;
  List<Like> get likeList => _likeList;
}
