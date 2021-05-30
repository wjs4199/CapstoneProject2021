import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'product.dart';
import 'add.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

// Header 타일 - 공지사항용 타일
class HeaderTile extends StatelessWidget {
  // url_launcher api 함수
  void _launchURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        child: GestureDetector(
          onTap: () => _launchURL('https://flutter.dev'),
          child: Image.network(
              "https://t1.daumcdn.net/thumb/R720x0/?fname=https://t1.daumcdn.net/brunch/service/user/1YN0/image/ak-gRe29XA2HXzvSBowU7Tl7LFE.png"),
        ),
      ),
    );
  }
}

// PostTile - 각 게시글 표시해주는 타일, Listview.builder(separated) 사용해 자동 생성
class PostTile extends StatelessWidget {
  PostTile(this._product, this._giveOrTake);

  final Product _product;
  final int _giveOrTake;

  // Set name for Firebase Storage
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  // Download image url of each product based on id
  Future<String> downloadURL(String id) async {
    await Future.delayed(Duration(seconds: 1));
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // leading: Icon(Icons.person),
      title: Text(_product.title),
      subtitle: Text(
        _product.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (_giveOrTake == 0)
          Navigator.pushNamed(
              context, '/detail/' + _product.id + '/giveProducts');
        else
          Navigator.pushNamed(
              context, '/detail/' + _product.id + '/takeProducts');
      },
      trailing: Container(
        width: 90,
        height: 90,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        alignment: Alignment.center,
        child: FutureBuilder(
          future: downloadURL(_product.id),
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
    );
  }
}

class _HomePageState extends State<HomePage> {
  // ToggleButtons - 각 버튼용 bool list
  List<bool> _selections = List.generate(3, (_) => false);

  // Drawer 관련 Key
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /* ----------------- BottomNavigationBar, PageView 관련 ----------------- */
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      //using this page controller you can make beautiful animation effects
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /* -------------------------------------------------------------------- */

  // For profile photo resizing
  String photoUrl = FirebaseAuth.instance.currentUser.photoURL;
  // String highResUrl = photoUrl.replaceAll('s96-c', 's400-c');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => SafeArea(
          child: SizedBox.expand(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              // NavBar Index 별 상응 위젯 출력
              children: _buildWidgetOptions(context, appState),
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildNavBar(context),
      floatingActionButton: buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
    //);
  }

  // Index 별 위젯 반환: (순서: 0-Give, 1-Take, 2-Chart, 3-MyPage)
  List<Widget> _buildWidgetOptions(
      BuildContext context, ApplicationState appState) {
    List<Widget> _widgetOptions = <Widget>[
      // 0(Give):
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            /* 기존 method
            child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: _buildListElement(context, appState.giveProducts),
            ), */

            // New method (listview builder 사용)
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              // HeaderTile 포함 length + 1
              itemCount: appState.giveProducts.length + 2,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) return HeaderTile();
                if (index == 1)
                  return Container(
                    child: _buildToggleButtonBar(context, appState),
                  );
                // HeaderTile 고려 index - 1
                return PostTile(
                    appState.giveProducts[index - 2], _selectedIndex);
              },
              separatorBuilder: (context, index) {
                if (index == 0 || index == 1) return SizedBox.shrink();
                return const Divider(
                  height: 20,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                );
              },
            ),
          ),
        ],
      ),
      // 1(Take):
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: _buildToggleButtonBar(context, appState),
          ),
          Expanded(
            /* 기존 method
            child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: _buildListElement(context, appState.takeProducts),
            ), */
            // New method (listview builder 사용)

            // New method
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: appState.takeProducts.length,
              itemBuilder: (BuildContext context, int index) {
                return PostTile(appState.takeProducts[index], _selectedIndex);
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 20,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                );
              },
            ),
          ),
        ],
      ),
      // 2(Chart):
      Center(
        child: Text('Chart(To be implemented)'),
      ),
      // 3(MyPage):
      Row(
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
                      : Image.network(photoUrl.replaceAll('s96-c', 's400-c'),
                          fit: BoxFit.fitWidth),
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
      )
    ];
    return _widgetOptions;
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

  // 필터링 기능을 토글버튼화하여 버튼바로 생성
  ButtonBar _buildToggleButtonBar(
      BuildContext context, ApplicationState appState) {
    return ButtonBar(
      alignment: MainAxisAlignment.end,
      children: <Widget>[
        ToggleButtons(
          color: Colors.black.withOpacity(0.60),
          constraints: BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),
          selectedBorderColor: Colors.cyan,
          selectedColor: Colors.cyan,
          borderRadius: BorderRadius.circular(4.0),
          isSelected: _selections,
          onPressed: (int index) {
            setState(() {
              for (int buttonIndex = 0;
                  buttonIndex < _selections.length;
                  buttonIndex++) {
                if (buttonIndex == index) {
                  _selections[buttonIndex] = !_selections[buttonIndex];
                } else {
                  _selections[buttonIndex] = false;
                }
              }
              if (_selections[index] == true) {
                if (index == 0)
                  appState.orderByFilter('Product');
                else if (index == 1)
                  appState.orderByFilter('Time');
                else
                  appState.orderByFilter('Talent');
              } else {
                appState.orderByFilter('All');
              }
            });
          },
          children: [
            Icon(
              Icons.shopping_bag,
              size: 20,
            ),
            Icon(
              Icons.access_time,
              size: 20,
            ),
            Icon(
              Icons.school,
              size: 20,
            ),
          ],
        ),
      ],
    );

    // 기존 (복잡)
    // Row(
    //   mainAxisAlignment: MainAxisAlignment.end,
    //   children: [
    //     IconButton(
    //         padding: EdgeInsets.all(0),
    //         alignment: Alignment.centerRight,
    //         icon: (_filterOfProduct
    //             ? Icon(Icons.wallet_giftcard, size: 30, color: Colors.cyan)
    //             : Icon(Icons.wallet_giftcard, size: 30, color: Colors.grey)),
    //         onPressed: () {
    //           _chooseFilter("Product");
    //           if (_filterOfProduct) {
    //             appState.orderByFilter('Product');
    //             print("product filtering!");
    //           } else if (!_filterOfProduct &&
    //               !_filterOfTime &&
    //               !_filterOfTalent) appState.orderByFilter('All');
    //         }),
    //     IconButton(
    //         padding: EdgeInsets.all(0),
    //         alignment: Alignment.centerRight,
    //         icon: (_filterOfTime
    //             ? Icon(Icons.timer, size: 30, color: Colors.cyan)
    //             : Icon(Icons.timer, size: 30, color: Colors.grey)),
    //         onPressed: () {
    //           _chooseFilter("Time");
    //           if (_filterOfTime) {
    //             print("time filtering!");
    //             appState.orderByFilter('Time');
    //           } else if (!_filterOfProduct &&
    //               !_filterOfTime &&
    //               !_filterOfTalent) appState.orderByFilter('All');
    //         }),
    //     IconButton(
    //         padding: EdgeInsets.all(0),
    //         alignment: Alignment.centerRight,
    //         icon: (_filterOfTalent
    //             ? Icon(
    //                 Icons.lightbulb,
    //                 size: 30,
    //                 color: Colors.cyan,
    //               )
    //             : Icon(
    //                 Icons.lightbulb,
    //                 size: 30,
    //                 color: Colors.grey,
    //               )),
    //         onPressed: () {
    //           _chooseFilter("Talent");
    //           if (_filterOfTalent) {
    //             print("talent filtering!");
    //             appState.orderByFilter('Talent');
    //           } else if (!_filterOfProduct &&
    //               !_filterOfTime &&
    //               !_filterOfTalent) appState.orderByFilter('All');
    //         }),
    //   ],
    // );
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
          onPressed: () {},
        ),
      ],
    );
  }

  // Builder Widget for Bottom Navigation Bar
  BottomNavigationBar buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.cyan,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.redo),
          label: 'Give',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.undo),
          label: 'Take',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Chart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
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
              Icons.account_circle,
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
