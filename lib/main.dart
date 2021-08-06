import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/detail.dart';
import 'legacy/map.dart';
import 'model/product.dart';
import 'actions/add.dart';
import 'actions/edit.dart';

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
              '/add': (context) => AddPage(),
              //'/takeadd': (context) => takeAddPage(),
              '/map': (context) => MapPage(),
            },

            // 동적 경로할당
            onGenerateRoute: (RouteSettings settings) {
              final pathElements = settings.name.split('/');
              //detail 페이지로 이동시키는 동적 경로할당
              // give페이지의 detail페이지에서 필요로한다는 뜻인거 같음
              // give&take 통합할 거니까 detail 페이지에서 부를 경우만 나타내면 될듯
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

  // comment와 like를 collection안에 어떤 구조로 넣을 것인가?
  // 원래 하던대로 상품 uid통해 찾으려면 이미 init한 상품 리스트들을 돌면서
  // datail페이지에 필요한 내용을 찾아내는 형식으로 해야할까?
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

    // comment 컬랙션을 따로 만들었기 때문에 comment 컬랙션 내에서 상품 uid를 또또찾고,
    // 그 후에 해당 상품에 달린 comments들을 찾아오는 게 필요해진 것 같은데,
    // comments들을 하위 콜랙션으로 만들면 더 편해지지 않을 까요?
    // 그리고 comments는 댓글 달릴 때마다 업데이트 시켜줘야하는 부분이니까 지금처럼 init()
    // 함수 내에 있을 게 아니라 다른 함수로 빼줘야하지 않을 까요?
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
            id: document.id,
          ));
        });
        notifyListeners();
      });

      //like는 이부분 만들어놓기만 했지 제대로 collection에서 못가져와서 사용안했던 거 같아요!
      // 없애고 새로 만들어도 될듯...
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
