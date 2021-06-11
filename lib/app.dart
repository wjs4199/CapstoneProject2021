import 'package:flutter/material.dart';

import 'home.dart';
import 'login.dart';
import 'map.dart';

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
        '/map': (context) => MapPage(),
      },
    );
  }
}
