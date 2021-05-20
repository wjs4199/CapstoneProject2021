import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'main.dart';
import 'product.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Post -> Product, posts -> products로 바꿨어요!
  List<ListView> _buildListView(BuildContext context, List<Product> products) {
    if (products == null || products.isEmpty) {
      return const <ListView>[];
    }

    final ThemeData theme = Theme.of(context);
    final NumberFormat formatter = NumberFormat.simpleCurrency(
        locale: Localizations.localeOf(context).toString());

    // Set name for Firebase Storage
    firebase_storage.FirebaseStorage storage =
        firebase_storage.FirebaseStorage.instance;

    // Download image url of each product based on id
    Future<String> downloadURL(String id) async {
      await Future.delayed(Duration(seconds: 2));
      try {
        return await storage
            .ref()
            .child('images')
            .child('$id.png')
            .getDownloadURL();
      } on Exception {
        return null;
      }
    }

    return products.map((product) {
      return ListView(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 18 / 11,
                child: FutureBuilder(
                  // Product 요소에 맞게 바꿨어요
                  future: downloadURL(product.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      if (snapshot.hasData) {
                        return Image.network(snapshot.data.toString());
                      } else if (snapshot.hasData == false) {
                        return Image.asset('assets/logo.png');
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    }
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        // Product 요소에 맞게 바꿨어요
                        product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        // Product 요소에 맞게 바꿨어요
                        product.description,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }).toList();
  }

  int _selectedIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      bottomNavigationBar: buildNavBar(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => SafeArea(
          child: Column(
            /**child: Column(
              mainAxisAlignment: MainAxisAlignment.center,


              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: EdgeInsets.all(16.0),
                    childAspectRatio: 8.0 / 9.0,
                    children: _buildGridCards(context, appState.giveProducts),
                  ),
                ),

                FloatingActionButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add');
                    },
                    child: Icon(Icons.add)),*/
            children: [
              Expanded(
                  child: ListView(
                      //children: _buildListView(context, appState.posts),
                      )),
            ],
          ),
        ),
      ),
    );
    //);
  }

  // Builder Widget for AppBar
  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Give'),
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
          onPressed: () {
            //
          },
        ),
      ],
    );
  }

  // Builder Widget for Bottom Navigation Bar
  BottomNavigationBar buildNavBar(BuildContext context) {
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    int _currentIndex = 0;

    return BottomNavigationBar(
      selectedItemColor: Colors.cyan,
      type: BottomNavigationBarType.fixed,
      // Tap actions for each tab
      // setState로 _currentIndex값 변경
      onTap: _onItemTapped,
      currentIndex: _selectedIndex,
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
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            title: Text('Search'),
            leading: Icon(
              Icons.search,
            ),
            onTap: () {},
          ),
          ListTile(
            title: Text('My Page'),
            leading: Icon(
              Icons.person,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/mypage');
            },
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
