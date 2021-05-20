<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'login.dart';
<<<<<<< HEAD
import 'take.dart';
import 'chat.dart';
import 'mypage.dart';
=======
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef

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
<<<<<<< HEAD
              '/take': (context) => TakePage(),
              '/chat': (context) => ChatPage(),
              '/mypage': (context) => ProfilePage(),

=======
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
            },

            // 동적 경로할당 위해 추후 사용
            // onGenerateRoute: (RouteSettings settings) {
            //   final List<String> pathElements = settings.name.split('/');
            //   if (pathElements[1] == 'detail') {
            //     return MaterialPageRoute(
            //       builder: (_) => DetailPage(itemId: pathElements[2]),
            //     );
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
  ApplicationState() {
    init();
  }

  Future<void> init() async {
    await Firebase.initializeApp();

<<<<<<< HEAD
    if (Firebase.initializeApp() == null)
      CircularProgressIndicator();

=======
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
    // FirebaseFirestore.instance
    //     ... // collection data 수집해서 프로젝트에 정의된 자료형에 저장, 리스너들에게 실시간 반영
    //   notifyListeners();
  }
}
