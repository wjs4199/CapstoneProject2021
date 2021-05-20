import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
<<<<<<< HEAD
  int _selectedIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

=======
  final _scaffoldKey = GlobalKey<ScaffoldState>();
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      bottomNavigationBar: buildNavBar(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // 로그인한 유저 정보 불러오기 (FirebaseAuth 사용)
              children: [
                Text('Name: ' + FirebaseAuth.instance.currentUser.displayName),
                Text('Email: ' + FirebaseAuth.instance.currentUser.email),
                Text('UID: ' + FirebaseAuth.instance.currentUser.uid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builder Widget for AppBar
  AppBar buildAppBar(BuildContext context) {
<<<<<<< HEAD

    return AppBar(
      title: Center(
        child: Text('Give'),
      ),
=======
    return AppBar(
      title: Text('Give'),
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
      backgroundColor: Colors.cyan,
      leading: IconButton(
        icon: Icon(
          Icons.menu_rounded,
          semanticLabel: 'menu',
        ),
        onPressed: () =>
            _scaffoldKey.currentState.openDrawer(), // Open drawer on pressed
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.search,
            semanticLabel: 'search',
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  // Builder Widget for Bottom Navigation Bar
  BottomNavigationBar buildNavBar(BuildContext context) {
<<<<<<< HEAD

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }
=======
    int _currentIndex = 0;
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef

    return BottomNavigationBar(
      selectedItemColor: Colors.cyan,
      type: BottomNavigationBarType.fixed,
      // Tap actions for each tab
      // setState로 _currentIndex값 변경
<<<<<<< HEAD
      onTap: _onItemTapped,
      currentIndex: _selectedIndex,
=======
      onTap: (index) => {},
      currentIndex: _currentIndex,
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Give',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Take',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.messenger),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'MyPage',
        )
      ],
    );
  }

  // Builder Widget for Drawer
  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '-Drawer-',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.cyan,
            ),
          ),
          ListTile(
            title: Text('Home'),
            // - The Menu Icons should be placed in the leading position
            leading: Icon(
              Icons.home,
            ),
            onTap: () {
              // - Each menu should be navigated by Named Routes
<<<<<<< HEAD
              Navigator.pushNamed(context,'/home');
=======
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
            },
          ),
          ListTile(
            title: Text('Search'),
            leading: Icon(
              Icons.search,
            ),
<<<<<<< HEAD
            onTap: () {
            },
=======
            onTap: () {},
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
          ),
          ListTile(
            title: Text('My Page'),
            leading: Icon(
              Icons.person,
            ),
<<<<<<< HEAD
            onTap: () {
              Navigator.pushNamed(context,'/mypage');
            },
=======
            onTap: () {},
>>>>>>> 64486a4df0fb9ad6428d8f6d2488fcf60ac660ef
          ),
          ListTile(
            title: Text('Settings'),
            leading: Icon(
              Icons.settings,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
