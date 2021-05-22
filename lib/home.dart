import 'package:flutter/material.dart';
import 'package:giveandtake/take.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'main.dart';
import 'product.dart';
import 'add.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ListView> _buildListView(BuildContext context, List<Product> products) {
    if (products == null || products.isEmpty) {
      return const <ListView>[];
    }

    // Set name for Firebase Storage
    firebase_storage.FirebaseStorage storage =
        firebase_storage.FirebaseStorage.instance;

    // Download image url of each product based on id
    Future<String> downloadURL(String id) async {
      await Future.delayed(Duration(seconds: 2));
      try {
        return await storage
            .ref() //스토리지 참조
            .child('images')
            .child('$id.png') //차일드로 가져오고
            .getDownloadURL(); //url 다운로드
      } on Exception {
        return null;
      }
    }

    return products.map((product) {
      return ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: [
          InkWell(
            onTap: () {
              print("디테일 페이지로 넘어감!");
              Navigator.pushNamed(
                  context, '/detail/' + product.id + '/giveProducts');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          // Product 요소에 맞게 바꿨어요
                          product.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                        SizedBox(height: 5.0),
                        Text(
                          // Product 요소에 맞게 바꿨어요
                          product.content,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 100,
                      height: 100,
                      // asynchronously load images
                      child: FutureBuilder(
                        future: downloadURL(product.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _filterOfProduct = false;
  bool _filterOfTime = false;
  bool _filterOfTalent = false;

  //bool _debugLocked = false;

  @override
  Widget build(BuildContext context) {
    //하단네비바 탭하여 페이지 이동하는 부분
    if (_selectedIndex != 0) {
      if (_selectedIndex == 1) {
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.of(context).pushReplacementNamed('/take');
        });
      } else if (_selectedIndex == 2) {
      } else if (_selectedIndex == 3) {}
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      bottomNavigationBar: buildNavBar(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(
                      padding: EdgeInsets.all(0),
                      alignment: Alignment.centerRight,
                      icon: (_filterOfProduct
                          ? Icon(Icons.wallet_giftcard,
                              size: 30, color: Colors.blue)
                          : Icon(Icons.wallet_giftcard,
                              size: 30, color: Colors.grey)),
                      onPressed: () {
                        _chooseFilter("Product");
                        if (_filterOfProduct) {
                          appState.orderByFilter('Product');
                          print("product filtering!");
                        } else if (!_filterOfProduct &&
                            !_filterOfTime &&
                            !_filterOfTalent) appState.orderByFilter('All');
                      }),
                  IconButton(
                      padding: EdgeInsets.all(0),
                      alignment: Alignment.centerRight,
                      icon: (_filterOfTime
                          ? Icon(Icons.timer, size: 30, color: Colors.blue)
                          : Icon(Icons.timer, size: 30, color: Colors.grey)),
                      onPressed: () {
                        _chooseFilter("Time");
                        if (_filterOfTime) {
                          print("time filtering!");
                          appState.orderByFilter('Time');
                        } else if (!_filterOfProduct &&
                            !_filterOfTime &&
                            !_filterOfTalent) appState.orderByFilter('All');
                      }),
                  IconButton(
                      padding: EdgeInsets.all(0),
                      alignment: Alignment.centerRight,
                      icon: (_filterOfTalent
                          ? Icon(
                              Icons.lightbulb,
                              size: 30,
                              color: Colors.blue,
                            )
                          : Icon(
                              Icons.lightbulb,
                              size: 30,
                              color: Colors.grey,
                            )),
                      onPressed: () {
                        _chooseFilter("Talent");
                        if (_filterOfTalent) {
                          print("talent filtering!");
                          appState.orderByFilter('Talent');
                        } else if (!_filterOfProduct &&
                            !_filterOfTime &&
                            !_filterOfTalent) appState.orderByFilter('All');
                      }),
                ]),
              ),
              Expanded(
                child: ListView(
                  children: _buildListView(context, appState.giveProducts),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/giveadd');
          },
          child: Icon(Icons.add)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
    //);
  }

  void _chooseFilter(String fitering) {
    setState(() {
      if (fitering == 'Product') {
        _filterOfProduct = _filterOfProduct ? false : true;
        if (_filterOfProduct) _filterOfTime = _filterOfTalent = false;
      } else if (fitering == 'Time') {
        _filterOfTime = _filterOfTime ? false : true;
        if (_filterOfTime) _filterOfProduct = _filterOfTalent = false;
      } else {
        _filterOfTalent = _filterOfTalent ? false : true;
        if (_filterOfTalent) _filterOfProduct = _filterOfTime = false;
      }
    });
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
            //Navigator.pushNamed(context, '/take');
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
