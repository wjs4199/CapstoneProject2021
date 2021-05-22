import 'package:flutter/material.dart';
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

String photoUrl = FirebaseAuth.instance.currentUser.photoURL;
String highResUrl = photoUrl.replaceAll('s96-c', 's400-c');

class _HomePageState extends State<HomePage> {
  List<Card> _buildListElement(BuildContext context, List<Product> products) {
    if (products == null || products.isEmpty) {
      return const <Card>[];
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
      return Card(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.pushNamed(
                context, '/detail/' + product.id + '/giveProducts');
          },
          child: ListTile(
            title: Text(
              // Product 요소에 맞게 바꿨어요
              product.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            subtitle: Text(
              // Product 요소에 맞게 바꿨어요
              product.content,
              maxLines: 3,
            ),
            trailing: Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              alignment: Alignment.center,
              child: FutureBuilder(
                future: downloadURL(product.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.hasData) {
                      return Image.network(snapshot.data.toString());
                    } else if (snapshot.hasData == false) {
                      return Container();
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  }
                },
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _filterOfProduct = false;
  bool _filterOfTime = false;
  bool _filterOfTalent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      bottomNavigationBar: buildNavBar(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => SafeArea(
          child: getBody(context, appState),
        ),
      ),
      floatingActionButton: buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
    //);
  }

  Widget getBody(BuildContext context, ApplicationState appState) {
    // If 'Give' NavButton is pressed
    if (_selectedIndex == 0)
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: _buildFilterRow(context, appState),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: _buildListElement(context, appState.giveProducts),
            ),
          ),
        ],
      );
    // If 'Take' NavButton is pressed
    else if (_selectedIndex == 1)
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: _buildFilterRow(context, appState),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: _buildListElement(context, appState.takeProducts),
            ),
          ),
        ],
      );
    // If 'Chat' NavButton is pressed
    else if (_selectedIndex == 2)
      return Text('Chat');
    // If 'MyPage' NavButton is pressed
    else if (_selectedIndex == 3)
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                ),
                Container(
                  width: 100,
                  height: 100,
                  child: FirebaseAuth.instance.currentUser.isAnonymous
                      ? Image.asset('assets/logo.png', fit: BoxFit.fitWidth)
                      : Image.network(highResUrl, fit: BoxFit.fitWidth),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(FirebaseAuth.instance.currentUser.displayName),
                Divider(
                  color: Colors.black26,
                  height: 30,
                  thickness: 1,
                ),
                Text(FirebaseAuth.instance.currentUser.isAnonymous
                    ? 'Anonymous'
                    : FirebaseAuth.instance.currentUser.email),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      );
    return Text('Navigation out of reach');
  }

  FloatingActionButton buildFAB() {
    if (_selectedIndex == 0)
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/giveadd');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    else if (_selectedIndex == 1)
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/takeadd');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    return null;
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

  // void _changeScreen() {
  //   //하단네비바 탭하여 페이지 이동하는 부분
  //   if (_selectedIndex != 0) {
  //     if (_selectedIndex == 1) {
  //       Future.delayed(const Duration(milliseconds: 200), () {
  //         Navigator.of(context).pushReplacementNamed('/take');
  //       });
  //     } else if (_selectedIndex == 2) {
  //       Future.delayed(const Duration(milliseconds: 200), () {
  //         Navigator.of(context).pushReplacementNamed('/chat');
  //       });
  //     } else if (_selectedIndex == 3) {
  //       Future.delayed(const Duration(milliseconds: 200), () {
  //         Navigator.of(context).pushReplacementNamed('/mypage');
  //       });
  //     }
  //   }
  // }

  Row _buildFilterRow(BuildContext context, ApplicationState appState) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
          padding: EdgeInsets.all(0),
          alignment: Alignment.centerRight,
          icon: (_filterOfProduct
              ? Icon(Icons.wallet_giftcard, size: 30, color: Colors.blue)
              : Icon(Icons.wallet_giftcard, size: 30, color: Colors.grey)),
          onPressed: () {
            _chooseFilter("Product");
            if (_filterOfProduct) {
              appState.orderByFilter('Product');
              print("product filtering!");
            } else if (!_filterOfProduct && !_filterOfTime && !_filterOfTalent)
              appState.orderByFilter('All');
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
            } else if (!_filterOfProduct && !_filterOfTime && !_filterOfTalent)
              appState.orderByFilter('All');
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
            } else if (!_filterOfProduct && !_filterOfTime && !_filterOfTalent)
              appState.orderByFilter('All');
          }),
    ]);
  }

  // Builder Widget for AppBar
  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Center(
        child: Text('Give & Take'),
      ),
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
            Navigator.pushNamed(context, '/take');
          },
        ),
      ],
    );
  }

  // Builder Widget for Bottom Navigation Bar
  BottomNavigationBar buildNavBar(BuildContext context) {
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
