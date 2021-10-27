import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:giveandtake/pages/login.dart';
import 'package:giveandtake/pages/views/2_request_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../main.dart';
import '../model/product.dart';
import '../components/postTile.dart';
import 'views/1_nanum_view.dart';
import 'views/3_msg_view.dart';

// Home
class HomePage extends StatefulWidget {
  ///* ------------------------------ 수정 -------------------------------- *////
  final SharedPreferences currentUserId;
  var nickname; // main 에 정의되어도 됨
  final bool messageState;
  HomePage({Key key, @required this.currentUserId, @required this.messageState})
      : super(key: key); // 필요X

  ///* ------------------------------------------------------------------ *////
  @override
  State createState() =>
      _HomePageState(currentUserId: currentUserId, messageState: messageState);
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  ///* ------------------------------ 수정 -------------------------------- *////
  /// _HomePageState 클래스 밑에 바로 build 가 보이도록,
  /// home.dart 에 정의 필요 없는것들 전부 main.dart 로
  _HomePageState({@required this.currentUserId, @required this.messageState});

  final SharedPreferences currentUserId;
  final bool messageState;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  /// bool isLoading = false; handleSign을 위한 변수
  /// 시스템 함수에 PageView 기능 반영 처리(1) +@
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _scrollController = ScrollController();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
    _focusNode = FocusNode();
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// 시스템 함수에 PageView 기능 반영 처리(2)
  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      endDrawer: buildDrawer(context),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => SafeArea(
          child: NestedScrollView(
            floatHeaderSlivers: true,
            controller: _scrollController,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              if (_selectedIndex == 0) {
                return <Widget>[
                  // SliverOverlapAbsorber(
                  //   handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  //       context),
                  //   sliver:
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    pinned: true,
                    snap: true,
                    floating: true,
                    expandedHeight: 108.0, // 118.0
                    iconTheme: IconThemeData(color: Colors.black),
                    title: Text(
                      'Pelag',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontFamily: 'NanumSquareRoundR',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // flexibleSpace: FlexibleSpaceBar(
                    //   background: Column(
                    //     children: <Widget>[
                    //       SizedBox(height: 60.0), // 60.0
                    //       Padding(
                    //         padding: const EdgeInsets.fromLTRB(
                    //             16.0, 6.0, 16.0, 16.0),
                    //         child: Container(
                    //           height: 36.0,
                    //           width: double.infinity,
                    //           child: CupertinoTextField(
                    //             focusNode: _focusNode,
                    //             keyboardType: TextInputType.text,
                    //             style: TextStyle(
                    //               fontSize: 16.0,
                    //               fontFamily: 'NanumSquareRoundR',
                    //             ),
                    //             placeholder: '검색',
                    //             placeholderStyle: TextStyle(
                    //               color: Color(0xffC4C6CC),
                    //               fontSize: 16.0,
                    //               fontFamily: 'NanumSquareRoundR',
                    //             ),
                    //             prefix: Padding(
                    //               padding: const EdgeInsets.fromLTRB(
                    //                   9.0, 6.0, 9.0, 6.0),
                    //               child: Icon(
                    //                 Icons.search,
                    //                 color: Color(0xffC4C6CC),
                    //               ),
                    //             ),
                    //             decoration: BoxDecoration(
                    //               borderRadius: BorderRadius.circular(8.0),
                    //               color: Color(0xffF0F1F5),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: [
                        Tab(
                          child: Text(
                            '나눔',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'NanumSquareRoundR',
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            '요청',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'NanumSquareRoundR',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ),
                ];
              } else {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    pinned: true,
                    snap: true,
                    floating: true,
                    iconTheme: IconThemeData(color: Colors.black),
                    title: Text(
                      'Pelag',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontFamily: 'NanumSquareRoundR',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ];
              }
            },
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },

              /// _selectedIndex 값에 따른 페이지(상응 위젯) 출력
              children: _buildWidgetOptions(context, appState, _selectedIndex),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
              ),
            ],
          ),
          child: buildNavAppBar(context)),
      // bottomNavigationBar: buildNavAppBar(context),
      floatingActionButton: buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
    //);
  }

  /// Builder Widget for Drawer
  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xfffc7174),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '-Drawer-\n프로필, 레밸 등 배치',
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
            title: Text('My Page'),
            // - The Menu Icons should be placed in the leading position
            leading: Icon(Icons.account_circle),
            onTap: () {},
          ),
          ListTile(
            title: Text('Change Nickname'),
            // - The Menu Icons should be placed in the leading position
            leading: Icon(Icons.change_circle),
            onTap: () {
              Navigator.pushNamed(context, '/signup');
            },
          ),
          ListTile(
            title: Text('Manual'),
            // - The Menu Icons should be placed in the leading position
            leading: Icon(Icons.book),
            onTap: () {
              Navigator.pushNamed(context, '/manual');
            },
          ),
          ListTile(
            title: Text('Sign Out'),
            // - The Menu Icons should be placed in the leading position
            leading: Icon(
              Icons.logout,
            ),
            onTap: () {
              handleSignOut();
            },
          ),
        ],
      ),
    );
  }

  /// Index 별 위젯 반환: (순서: 0-홈, 1-나눔, 2-나눔요청, 3-메신저, 4-My)
  List<Widget> _buildWidgetOptions(
      BuildContext context, ApplicationState appState, int selectedIndex) {
    var _widgetOptions = <Widget>[
      /// 0(나눔):
      TabBarView(
        controller: _tabController,
        children: [
          NanumView(context, appState),
          RequestView(context, appState),
        ],
      ),

      /// 1(나눔요청):
      // RequestView(context, appState),

      /// 2(홈):
      // HomeView(context, appState),

      /// 3(메신저):
      MessagePage(),

      /// 4(MyPage):
      // MyView(context, appState)
    ];
    return _widgetOptions;
  }

  /// FloatingActionButton 생성기
  Widget buildFAB() {
    if (_selectedIndex == 0) {
      return SpeedDial(
        icon: Icons.edit,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        spacing: 10,
        spaceBetweenChildren: 5,
        elevation: 10,
        animationSpeed: 200,
        children: [
          SpeedDialChild(
            child: Icon(Icons.accessibility),
            foregroundColor: Colors.white,
            backgroundColor: Color(0xfffc8862),
            label: '나눔',
            labelStyle: TextStyle(
                fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
            onTap: () {
              Navigator.pushNamed(context, '/giveadd');
            },
            // closeSpeedDialOnPressed: false,
          ),
          SpeedDialChild(
            child: Icon(Icons.accessibility_new),
            foregroundColor: Colors.white,
            backgroundColor: Color(0xfffda26b),
            label: '나눔요청',
            labelStyle: TextStyle(
                fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
            onTap: () {
              Navigator.pushNamed(context, '/takeadd');
            },
          ),
        ],
      );
    } else if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          /// 메시지 작성 기능(페이지) 호출
        },
        elevation: 10,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.send),
      );
    }
    // else if (_selectedIndex == 1) {
    //   return FloatingActionButton(
    //     onPressed: () {
    //       Navigator.pushNamed(context, '/takeadd');
    //     },
    //     backgroundColor: Color(0xfffc7174),
    //     child: Icon(Icons.mode_edit),
    //   );
    // }
    return null;
  }

  /// Builder Widget for Bottom Navigation Bar
  BottomAppBar buildNavAppBar(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      color: Theme.of(context).bottomAppBarColor.withAlpha(255),
      elevation: 0,
      child: buildNavBar(context),
    );
  }

  BottomNavigationBar buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      // showSelectedLabels: true,
      // showUnselectedLabels: false,
      currentIndex: _selectedIndex,
      elevation: 0,
      backgroundColor: Theme.of(context).bottomAppBarColor.withAlpha(220),
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.accessibility,
            size: 30,
          ),
          label: '나눔',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.forum,
            size: 30,
          ),
          label: '메신저',
        ),
      ],
    );
  }

  /// Drawer 관련 Scaffold Key
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Sign Out (call on null 오류)
  Future<Null> handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut().then((value) => Navigator.of(context)
        .pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false));
  }

  ///* ---------------- BottomNavigationBar, PageView 관련 ----------------- *///
  /// PaveView 용 controller
  PageController _pageController;
  TabController _tabController;
  ScrollController _scrollController;
  FocusNode _focusNode;

  /// 현재 선택된 인덱스값 (첫번째 인덱스로 초기화)
  int _selectedIndex = 0;

  /// BottomNavigationBar 인덱스 시경 시 _selectedIndex 변경 및 애니메이션 처리
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      //using this page controller you can make beautiful animation effects
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.easeOut);
    });
  }

  ///* -------------------------------------------------------------------- *///
}

/// PostTileMaker - 각 게시글 별 postTile Listview.builder(separated) 사용해 자동 생성
class PostTileMaker extends StatelessWidget {
  PostTileMaker(this._product, this._giveOrTake);

  final Product _product;
  final bool _giveOrTake;

  /// Set name for Firebase Storage
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  /// Download image url of each product based on id
  Future<String> downloadURL(String id) async {
    // await Future.delayed(Duration(seconds: 1));
    try {
      return await _storage
          .ref() //스토리지 참조
          .child('images')
          .child('$id\0.png') //차일드로 가져오고
          .getDownloadURL(); //url 다운로드
    } on Exception {
      return null;
    }
  }

  // @override
  // void initState() {
  //   var asd;
  // }

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

    /// 사용자가 게시글 눌러 들어갈 때마다 조회수 올리는 함수
    Future<void> editProductHits(String GiveOrTake) {
      return FirebaseFirestore.instance
          .collection(GiveOrTake)
          .doc(_product.id)
          .update({
        'hits': _product.hits + 1,
      });
    }

    /// findNickname add.dart 에 정의되어 있는데 왜 여기 또있는지?
    // String findNickname(AsyncSnapshot<QuerySnapshot> snapshot, String name) {
    //   var nickName = 'null';
    //   snapshot.data.docs.forEach((document) {
    //     if (document['username'] == name) {
    //       nickName = document['nickname'];
    //     }
    //   });
    //   print('찾은 닉네임은 $nickName!!');
    //   return nickName;
    // }

    ///*** user collection 내에서 userName이 일치하는 doc의 nickname을 가져오는 부분 ****///

    return InkWell(
        onTap: () {
          if (_giveOrTake) {
            editProductHits('giveProducts');
            Provider.of<ApplicationState>(context, listen: false)
                .detailPageUid(_product.id, 'giveProducts', _product.photo)
                .then((value) => Navigator.pushNamed(
                    context, '/detail/' + _product.id + '/giveProducts'));
          } else {
            editProductHits('takeProducts');
            Provider.of<ApplicationState>(context, listen: false)
                .detailPageUid(_product.id, 'takeProducts', _product.photo)
                .then((value) => Navigator.pushNamed(
                    context, '/detail/' + _product.id + '/takeProducts'));
          }
        },

        /// Custom Tile 구조로 생성 (postTile.dart 구조 참조)
        child: FutureBuilder(
          future: returnDate(),
          builder: (context, snapshot) {
            var id = _product.id;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ));
            } else {
              return CustomListItem(
                title: _product.title,
                subtitle: _product.content,
                author: _product.nickname,
                publishDate: snapshot.data,
                // category: _product.category,
                likes: _product.likes,
                // thumbnail: FutureBuilder(
                //   future: downloadURL(_product.id),
                //   builder: (context, snapshot) {
                //     // if (snapshot.connectionState == ConnectionState.waiting) {
                //     //   return Center(
                //     //       child: CircularProgressIndicator(
                //     //           color: Theme.of(context).primaryColor));
                //     // } else {
                //     if (snapshot.hasData) {
                //       return ClipRRect(
                //         borderRadius: BorderRadius.circular(8.0),
                //         // child: Image.network(snapshot.data.toString(),
                //         //     fit: BoxFit.fitWidth),
                //         child: CachedNetworkImage(
                //           imageUrl: snapshot.data,
                //           fit: BoxFit.fitWidth,
                //           errorWidget: (context, url, error) =>
                //               Icon(Icons.error),
                //         ),
                //       );
                //     } else if (snapshot.hasData == false) {
                //       return Container();
                //     } else {
                //       return Center(
                //           child: CircularProgressIndicator(
                //               color: Theme.of(context).primaryColor));
                //     }
                //     // }
                //   },
                // ),
                // thumbnail: Image.network(
                //     'gs://give-take-535cf.appspot.com/images/$id\0.png'),
                thumbnail: _product.thumbnail == null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14.0),
                        child: Image.asset('assets/no-thumbnail.jpg'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14.0),
                        child: CachedNetworkImage(
                          // placeholder: CircularProgressIndicator(),
                          imageUrl: _product.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ),
              );
            }
          },
        ));
  }
}
