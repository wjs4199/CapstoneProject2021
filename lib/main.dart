import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giveandtake/pages/manual.dart';
import 'package:giveandtake/pages/signup.dart';
import 'package:giveandtake/pages/splash.dart';
import 'package:giveandtake/pages/views/3_msg_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/detail.dart';
import 'legacy/map.dart';
import 'model/product.dart';
import 'actions/add.dart';
import 'actions/edit.dart';
import 'pages/splash.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => Application(),
    ),
  );
}
class Application extends StatefulWidget {


  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {


  SharedPreferences prefs;
  bool isLoading = false;
  bool isLoggedIn = false;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  // Future<bool> _decideMainPage() async {
  //   isLoggedIn = await googleSignIn.isSignedIn();
  //   if (isLoggedIn) {
  //     print('Login true');
  //     return true;
  //   }
  //   else{
  //     print('Login false');
  //     return false;
  //   }
  //
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Give_N_Take',
            theme: ThemeData(
              primaryColor: Color(0xfffc7174),
              focusColor: Colors.black12,
              backgroundColor: Colors.white,
              // bottomAppBarColor: Color(0xffF0F1F5),
            ),

            home: SplashPage(),
            //home: _decideMainPage() == true ? HomePage() : LoginPage(),
            //initialRoute: _decideMainPage() == null ? '/home' : '/login',
            debugShowCheckedModeBanner: false,

            // Named Routes
            routes: {
              '/manual': (context) => ManualPage(),
              '/signup': (context) => SignUp(),
              '/login': (context) => LoginPage(),
              '/home': (context) => HomePage(),
              '/giveadd': (context) => AddPage(giveOrTake: 'give'),
              '/takeadd': (context) => AddPage(giveOrTake: 'take'),
              '/message': (context) => MessagePage(),
            },

            // 동적 경로할당
            onGenerateRoute: (RouteSettings settings) {
              final pathElements = settings.name.split('/');
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
  ApplicationState() {
    orderBy = 'All';
    uid = 'null';
    init();
  }

  String orderBy;
  String uid;
  String nickname;
  String detailGiveOrTake;
  int photo;

  Future<void> detailPageUid(
      String uid, String detailGiveOrTake, int photo) async {
    this.uid = uid;
    this.detailGiveOrTake = detailGiveOrTake;
    this.photo = photo;
    print('main 에서 불려짐! detail page uid -> ' + uid);
    await init().whenComplete(
        () => print('detailPageUid 에서 likeCount => ${likeList.length}'));
  }

  void checkNickname(String nickname) {
    this.nickname = nickname;
    init();
  }

  void orderByFilter(String orderBy) {
    this.orderBy = orderBy;
    print('filtering ->  ' + orderBy);
    init();
  }

  List<Product> _giveProducts = [];
  List<Product> _takeProducts = [];
  List<Comment> _commentContext = [];
  List<Like> _likeList = [];
  int likeCount = 0;
  List<Users> _userName = [];
  List<Users> _users = [];

  /// added
  Stream<QuerySnapshot> currentStream;

  Future<void> init() async {
    ///************************* giveProducts / takeProducts 가져오는 부분 *************************///
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
            hits: document.data()['hits'],
            photo: document.data()['photo'],
            user_photoURL: document.data()['user_photoURL'],
            thumbnail: document.data()['thumbnailURL'],
            complete: document.data()['complete'],
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
            hits: document.data()['hits'],
            photo: document.data()['photo'],
            user_photoURL: document.data()['user_photoURL'],
            thumbnail: document.data()['thumbnailURL'],
            complete: document.data()['complete'],
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
          content ??= '글 읽기 실패';
          _giveProducts.add(Product(
            id: document.id,
            title: document.data()['title'],
            content: content,
            category: document.data()['category'],
            created: document.data()['created'],
            modified: document.data()['modified'],
            userName: document.data()['userName'],
            uid: document.data()['uid'],
            likes: null,
            hits: document.data()['hits'],
            photo: document.data()['photo'],
            user_photoURL: document.data()['user_photoURL'],
            thumbnail: document.data()['thumbnailURL'],
            complete: document.data()['complete'],
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
            likes: null,
            hits: document.data()['hits'],
            photo: document.data()['photo'],
            user_photoURL: document.data()['user_photoURL'],
            thumbnail: document.data()['thumbnailURL'],
            complete: document.data()['complete'],
          ));
        });
        notifyListeners();
      });
    }

    ///************************* commentList 가져오는 부분 *************************///
    if (uid != 'null') {
      FirebaseFirestore.instance
          .collection(detailGiveOrTake + '/' + uid + '/comment')
          .orderBy('created', descending: true)
          .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
          .listen((snapshot) {
        _commentContext = [];
        snapshot.docs.forEach((document) {
          _commentContext.add(Comment(
            userName: document.data()['userName'],
            comment: document.data()['comment'],
            created: document.data()['created'],
            id: document.id,
            uid: document.data()['uid'],

            ///edited
            //   isDeleted: document.data()['idDeleted'],
          ));
        });
        notifyListeners();
      });

      ///************************* likeList 가져오는 부분 *************************///
      FirebaseFirestore.instance
          .collection(detailGiveOrTake + '/' + uid + '/like')
          .snapshots()
          .listen((snapshot) {
        _likeList = [];
        snapshot.docs.forEach((document) {
          _likeList.add(Like(
            uid: document.data()['uid'],
            id: document.id,
          ));
        });
        likeCount = _likeList.length;
        notifyListeners();
      });
    }

    ///************************* users 가져오는 부분 *************************///
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _users = [];
      snapshot.docs.forEach((document) {
        _users.add(Users(
          createdAt: document.data()['createdAt'].toString(),
          id: document.data()['id'],
          nickname: document.data()['nickname'],
          photoUrl: document.data()['photoUrl'],
          username: document.data()['username'],
          email : document.data()['email'],
        ));
      });
      notifyListeners();
    });

    print('main에서 likeCount => ${likeList.length}');
  }

  List<Product> get giveProducts => _giveProducts;
  List<Product> get takeProducts => _takeProducts;
  List<Comment> get commentContext => _commentContext;
  List<Like> get likeList => _likeList;
  List<Users> get username => _userName;
  List<Users> get users => _users;

  /// added
}
