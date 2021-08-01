import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import 'main.dart';
import 'product.dart';
import 'tile.dart';
import 'chart.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

/// Header 타일 - 공지사항용 타일
class HeaderTile extends StatelessWidget {
  /// url_launcher api 함수
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

/// PostTile - 각 게시글 표시해주는 타일, Listview.builder(separated) 사용해 자동 생성
class PostTile extends StatelessWidget {
  PostTile(this._product, this._giveOrTake);

  final Product _product;
  final int _giveOrTake;

  /// Set name for Firebase Storage
  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  /// Download image url of each product based on id
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
    /// Firebase TimeStamp => DateFormat 변환
    // String formattedDate =
    //     DateFormat('MMM d, HH:mm').format(_product.created.toDate());
    Future<String> returnDate() async {
      //await Future.delayed(Duration(seconds: 1));
      try {
        return DateFormat('MMM d, HH:mm').format(_product.created.toDate());
      } on Exception {
        return null;
      }
    }

    return InkWell(
      onTap: () {
        if (_giveOrTake == 0) {
          Provider.of<ApplicationState>(context, listen: false)
              .detailPageUid(_product.id, 'giveProducts');
          Navigator.pushNamed(
              context, '/detail/' + _product.id + '/giveProducts');
        } else {
          Provider.of<ApplicationState>(context, listen: false)
              .detailPageUid(_product.id, 'takeProducts');
          Navigator.pushNamed(
              context, '/detail/' + _product.id + '/takeProducts');
        }
      },

      /// Custom Tile 구조로 생성 (tile.dart 구조 참조)
      child: FutureBuilder(
        future: returnDate(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return CustomListItem(
              title: _product.title,
              subtitle: _product.content,
              author: _product.userName,
              publishDate: snapshot.data,
              category: _product.category,
              likes: _product.likes,
              thumbnail: FutureBuilder(
                future: downloadURL(_product.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.hasData) {
                      return ClipRRect(
                        borderRadius: new BorderRadius.circular(8.0),
                        child: Image.network(snapshot.data.toString(),
                            fit: BoxFit.fitWidth),
                      );
                    } else if (snapshot.hasData == false) {
                      return Container();
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  /// ToggleButtons - 각 버튼용 bool list
  List<bool> _selections = List.generate(3, (_) => false);

  /// Drawer 관련 Key
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ///* ----------------- BottomNavigationBar, PageView 관련 ----------------- *///
  int _selectedIndex = 0;

  // 이게 정확히 어디에서 나타나는 효과인지 모르겠어요!
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      //using this page controller you can make beautiful animation effects
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  PageController _pageController;

  //이 밑에 두개 override된 부분이 뭔지 모르겠어요!
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

  ///* -------------------------------------------------------------------- *///

  /// For profile photo resizing
  String photoUrl = FirebaseAuth.instance.currentUser.photoURL;
  // String highResUrl = photoUrl.replaceAll('s96-c', 's400-c');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => Container(
          color: Colors.cyan,
          child: SafeArea(
            child: Container(
              color: Colors.white,
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
        ),
      ),
      bottomNavigationBar: buildNavBar(context),
      floatingActionButton: buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Index 별 위젯 반환: (순서: 0-Give, 1-Take, 2-Chart, 3-MyPage)
  List<Widget> _buildWidgetOptions(
      BuildContext context, ApplicationState appState) {
    var _widgetOptions = <Widget>[
      /// 0(Give):
      CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.cyan,
            // stretch: true,
            pinned: false,
            snap: false,
            floating: false,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Home | Give',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'NanumSquareRoundR',
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  FlutterLogo(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.0, 0.5),
                        end: Alignment.center,
                        colors: <Color>[
                          Color(0x60000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  semanticLabel: 'location',
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/map');
                },
              ),
            ],
          ),
          SliverStickyHeader(
            header: Container(
              alignment: Alignment.centerLeft,
              height: 40,
              color: Colors.cyan.shade50,
              padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text(
                'Notice | 공지사항',
                style: TextStyle(
                  fontFamily: 'NanumSquareRoundR',
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [HeaderTile()],
              ),
            ),
          ),
          SliverStickyHeader(
            header: Container(
              height: 40,
              color: Colors.cyan.shade50,
              padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Give | 나눔 게시판',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRoundR',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildToggleButtons(context, appState),
                ],
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Column(
                    children: [
                      SizedBox(height: 5),
                      PostTile(appState.giveProducts[index], _selectedIndex),
                      SizedBox(height: 5),
                      Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                    ],
                  );
                },
                childCount: appState.giveProducts.length,
              ),
            ),
          ),
        ],
      ),

      /// 1(Take):
      CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.cyan,
            // stretch: true,
            pinned: false,
            snap: false,
            floating: false,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Take',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'NanumSquareRoundR',
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  FlutterLogo(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.0, 0.5),
                        end: Alignment.center,
                        colors: <Color>[
                          Color(0x60000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  semanticLabel: 'location',
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/map');
                },
              ),
            ],
          ),
          SliverStickyHeader(
            header: Container(
              height: 40,
              color: Colors.cyan.shade50,
              padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Take | 나눔, 도움 요청 게시판',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRoundR',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildToggleButtons(context, appState),
                ],
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Column(
                    children: [
                      SizedBox(height: 5),
                      PostTile(appState.takeProducts[index], _selectedIndex),
                      SizedBox(height: 5),
                      Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                    ],
                  );
                },
                childCount: appState.takeProducts.length,
              ),
            ),
          ),
        ],
      ),

      /// 2(Chart) 작업중, Sliver 사용 실험중:
      CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text(
              'Chart Analysis',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'NanumSquareRoundR',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.cyan,
            pinned: true,
            snap: false,
            floating: true,
            // expandedHeight: 140.0,
            // flexibleSpace: const FlexibleSpaceBar(
            //   background: FlutterLogo(),
            // ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  semanticLabel: 'location',
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 9),
                  child: Text(
                    'Analysis on Give Board:',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'NanumSquareRoundR',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CustomPieChart(appState.giveProducts),
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 9),
                  child: Text(
                    'Analysis on Take Board:',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'NanumSquareRoundR',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CustomPieChart(appState.takeProducts),
              ],
            ),
          )
        ],
      ),

      /// 3(MyPage):

      CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text(
              'My Page',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'NanumSquareRoundR',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.cyan,
            pinned: true,
            snap: false,
            floating: true,
            // expandedHeight: 140.0,
            // flexibleSpace: const FlexibleSpaceBar(
            //   background: FlutterLogo(),
            // ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  semanticLabel: 'location',
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.0),
                    CircleAvatar(
                      radius: 50.0,
                      backgroundImage:
                          NetworkImage(photoUrl.replaceAll('s96-c', 's400-c')),
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      FirebaseAuth.instance.currentUser.displayName,
                      style: TextStyle(
                        fontFamily: 'NanumBarunGothic',
                        fontSize: 20.0,
                        color: Colors.black87,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'HANDONG GLOBAL UNIVERSITY',
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser.email,
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 12.0,
                        color: Colors.black54,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser.uid,
                      style: TextStyle(
                        fontFamily: 'Source Sans Pro',
                        fontSize: 12.0,
                        color: Colors.black54,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                      width: 200.0,
                      child: Divider(
                        color: Colors.cyan.shade200,
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 25.0),
                      child: ListTile(
                        leading: Icon(
                          Icons.phone,
                          color: Colors.cyan,
                        ),
                        title: Text(
                          '+82 10 9865 7165',
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.cyan.shade900,
                              fontFamily: 'Source Sans Pro'),
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 25.0),
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: Colors.cyan,
                        ),
                        title: Text(
                          'Pohang, Replublic of Korea',
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.cyan.shade900,
                              fontFamily: 'Source Sans Pro'),
                        ),
                      ),
                    ),
                    CustomPieChart2(
                        appState.giveProducts + appState.takeProducts),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ];
    return _widgetOptions;
  }

  FloatingActionButton buildFAB() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/giveadd');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    } else if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/takeadd');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    }
    return null;
  }

  /// 필터링 기능을 토글버튼화하여 버튼바로 생성
  ToggleButtons _buildToggleButtons(
      BuildContext context, ApplicationState appState) {
    return ToggleButtons(
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
    );
  }

  /// Builder Widget for Bottom Navigation Bar
  BottomNavigationBar buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.cyan,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
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

  /// Builder Widget for Drawer
  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.cyan,
            ),
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
            title: Text('Map'),
            leading: Icon(
              Icons.map,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/map');
            },
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
