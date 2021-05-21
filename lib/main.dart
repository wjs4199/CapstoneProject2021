import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'login.dart';
import 'home.dart';
import 'login.dart';
import 'take.dart';
import 'model/post.dart';

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
            title: 'giveandtake',
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
  List<Post> _posts = [];

  ApplicationState() {
    init();
  }

  Future<void> init() async {

    FirebaseFirestore.instance
        .collection('post')
        .snapshots() //파이어베이스에 저장되어있는 애들 데려오는 거 같음
        .listen((snapshot) {
      _posts = [];
      snapshot.docs.forEach((document) {
        _posts.add(Post(
          id: document.id,
          title: document.data()['title'],
          content: document.data()['content'],
          time: document.data()['time'],
          category: document.data()['category'],
          uid: document.data()['uid'],
        ));
      });
      notifyListeners();
    });
  }
  List<Post> get posts => _posts;
//products 업데이트 완료
}