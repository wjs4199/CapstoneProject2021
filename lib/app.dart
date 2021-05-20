import 'package:flutter/material.dart';

import 'home.dart';
import 'login.dart';

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Give_N_Take',
      home: HomePage(),
      // initialRoute: '/login',
      // - Named Routes
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

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
