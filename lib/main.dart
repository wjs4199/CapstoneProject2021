import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'home.dart';
import 'login.dart';
import 'home.dart';
import 'login.dart';
import 'take.dart';
import 'chat.dart';
import 'mypage.dart';
import 'product.dart';
import 'add.dart';

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
              '/take': (context) => TakePage(),
              '/chat': (context) => ChatPage(),
              '/mypage': (context) => ProfilePage(),
              '/add': (context) => AddPage(),
            },

            // 동적 경로할당 위해 추후 사용
            // onGenerateRoute: (RouteSettings settings) {
            //   final List<String> pathElements = settings.name.split('/');
            //   if (pathElements[1] == 'detail') {
            //     return MaterialPageRoute(
            //       builder: (_) => DetailPage(itemId: pathElements[2]),

            //   }
            //   return null;
            // },
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class ApplicationState extends ChangeNotifier {
  List<Product> _giveProducts = [];

  ApplicationState() {
    init();
  }

  Future<void> init() async {
    //await Firebase.initializeApp();
    //예슬이가 추가한 부분 오류떠서 고친 듯!
    //if (Firebase.initializeApp() == null) CircularProgressIndicator();

    // FirebaseFirestore.instance
    FirebaseFirestore.instance
        .collection('giveProducts')
        //.orderBy('price', descending: isDesc)
        .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
        .listen((snapshot) {
      _giveProducts = [];
      snapshot.docs.forEach((document) {
        _giveProducts.add(Product(
          id: document.id,
          name: document.data()['name'],
          price: document.data()['price'],
          description: document.data()['description'],
          created: document.data()['created'],
          modified: document.data()['modified'],
          uid: document.data()['uid'],
        ));
      });
      notifyListeners();
    });
  }

  List<Product> get giveProducts => _giveProducts;
//products 업데이트 완료
}
