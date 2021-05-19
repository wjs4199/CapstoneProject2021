import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'login.dart';

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

    // FirebaseFirestore.instance
    //     ... // collection data 수집해서 프로젝트에 정의된 자료형에 저장, 리스너들에게 실시간 반영
    //   notifyListeners();
  }
}
