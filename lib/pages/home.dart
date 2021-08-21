import 'package:firebase_storage/firebase_storage.dart';
//import 'dart:html';
import 'dart:async';
import 'dart:io' show Platform, exit;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:giveandtake/components/headerTile.dart';
import 'package:giveandtake/model/const.dart';
import 'package:giveandtake/model/loading.dart';
import 'package:giveandtake/pages/chat.dart';
import 'package:giveandtake/pages/login.dart';
import 'package:giveandtake/model/user_chat.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';

import '../main.dart';
import '../model/product.dart';
import '../components/postTile.dart';
import 'views/0_home_view.dart';
import 'views/1_nanum_view.dart';
import 'views/2_request_view.dart';
import 'views/3_msg_view.dart';
import 'views/4_my_view.dart';

// home
class HomePage extends StatefulWidget {
final String currentUserId;
HomePage({Key key, @required this.currentUserId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(currentUserId: currentUserId);
}



class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  _HomePageState({Key key, @required this.currentUserId});
  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  bool isLoading = false;
  int _limit = 20;
  int _limitIncrement = 20;

  //_HomePageState(this.currentUserId);





  @override
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
    listScrollController.addListener(scrollListener);
    _pageController = PageController();
  }

  void registerNotification() {
    firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: $message');
      if (message.notification != null) {
        showNotification(message.notification);
      }
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance.collection('UserName').doc(currentUserId).update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();
    InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void scrollListener() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void showNotification(RemoteNotification remoteNotification) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      Platform.isAndroid ? 'com.dfa.flutterchatdemo' : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      'your channel description',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    print(remoteNotification);

    await flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      platformChannelSpecifics,
      payload: null,
    );
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }
  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }


  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });
    ///
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    await Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // appBar: buildAppBar(context), /// SliverUI 사용으로 appBar 미사용
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

                  /// _selectedIndex 값에 따른 페이지(상응 위젯) 출력
                  children:
                      _buildWidgetOptions(context, appState, _selectedIndex),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black,
              ),
            ],
          ),
          child: buildNavBar(context)),
      floatingActionButton: buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              color: Colors.cyan,
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  /// 작업 필요
                  '-Drawer-\n프로필, 레밸 등 배치',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          /// 작업 필요
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
        ],
      ),
    );
  }

  /// ***작업중***
  /// Index 별 위젯 반환: (순서: 0-홈, 1-나눔, 2-나눔요청, 3-메신저, 4-My)
  List<Widget> _buildWidgetOptions(
      BuildContext context, ApplicationState appState, int selectedIndex) {
    var _widgetOptions = <Widget>[
      /// 0(홈):

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
                '홈',
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
                  // Navigator.pushNamed(context, '/map');
                },
              ),
              ///added
              IconButton(
                icon: Icon(
                  Icons.logout,
                  //semanticLabel: 'location',
                ),
                onPressed: () {
                  handleSignOut();
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
                  //_buildToggleButtons(context, appState),
                ],
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Column(
                    children: [
                      SizedBox(height: 5),
                      PostTileMaker(
                          appState.giveProducts[index], _selectedIndex),
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

      /// 1(나눔):
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
                '나눔',
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
                  // Navigator.pushNamed(context, '/map');
                },
              ),
              ///added
              IconButton(
                icon: Icon(
                  Icons.logout,
                  //semanticLabel: 'location',
                ),
                onPressed: () {
                 // handleSignOut();
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
                  //_buildToggleButtons(context, appState),
                ],
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Column(
                    children: [
                      SizedBox(height: 5),
                      PostTileMaker(
                          appState.takeProducts[index], _selectedIndex),
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

      /// 2(메신저):
      CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text(
              '메신저',
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
             ///added

              IconButton(
                icon: Icon(
                  Icons.logout,
                  //semanticLabel: 'location',
                ),
                onPressed: () {
                //  handleSignOut();
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                ///added
    IconButton(
    icon: Icon(
    Icons.logout,
    //semanticLabel: 'location',
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chat(

          ),
        ),
      );
    },
    ),

                WillPopScope(
                  onWillPop: onBackPress,
                  child: Stack(
                    children: <Widget>[
                      // List
                      Container(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('UserName').limit(_limit).snapshots(),
                          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.hasData) {
                              return ListView.builder(
                                padding: EdgeInsets.all(10.0),
                                itemBuilder: (context, index) => buildItem(context, snapshot.data.docs[index]),
                                itemCount: snapshot.data.docs.length,
                                controller: listScrollController,
                              );
                            } else {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      // Loading
                      Positioned(
                        child: isLoading ? const Loading() : Container(),
                      )
                    ],
                  ),
                ),

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
              'My',
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
              ///added
              IconButton(
                icon: Icon(
                  Icons.logout,
                  //semanticLabel: 'location',
                ),
                onPressed: () {
               //   handleSignOut();
                },
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
                  ],
                ),
              ],
            ),
          )
        ],
      ),

      HomeView(context, appState, selectedIndex),

      /// 1(나눔):
      NanumView(context, appState, selectedIndex, _tabController),

      /// 2(나눔요청):
      RequestView(context, appState, selectedIndex, _tabController),

      /// 3(메신저):
      MsgView(context, appState, selectedIndex),

      /// 4(MyPage):
      MyView(context, appState, selectedIndex)

    ];
    return _widgetOptions;
  }

  // /// 필터링 기능을 토글버튼화하여 버튼바로 생성
  // ToggleButtons _buildToggleButtons(
  //     BuildContext context, ApplicationState appState) {
  //   return ToggleButtons(
  //     color: Colors.black.withOpacity(0.60),
  //     constraints: BoxConstraints(
  //       minWidth: 30,
  //       minHeight: 30,
  //     ),
  //     selectedBorderColor: Colors.cyan,
  //     selectedColor: Colors.cyan,
  //     borderRadius: BorderRadius.circular(4.0),
  //     isSelected: _selections,
  //     onPressed: (int index) {
  //       setState(() {
  //         for (var buttonIndex = 0;
  //             buttonIndex < _selections.length;
  //             buttonIndex++) {
  //           if (buttonIndex == index) {
  //             _selections[buttonIndex] = !_selections[buttonIndex];
  //           } else {
  //             _selections[buttonIndex] = false;
  //           }
  //         }
  //         if (_selections[index] == true) {
  //           if (index == 0) {
  //             appState.orderByFilter('Product');
  //           } else if (index == 1) {
  //             appState.orderByFilter('Time');
  //           } else {
  //             appState.orderByFilter('Talent');
  //           }
  //         } else {
  //           appState.orderByFilter('All');
  //         }
  //       });
  //     },
  //     children: [
  //       Icon(
  //         Icons.shopping_bag,
  //         size: 20,
  //       ),
  //       Icon(
  //         Icons.access_time,
  //         size: 20,
  //       ),
  //       Icon(
  //         Icons.school,
  //         size: 20,
  //       ),
  //     ],
  //   );
  // }

  /// FloatingActionButton 생성기
  FloatingActionButton buildFAB() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    } else if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    } else if (_selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );
    }
    return null;
  }

  // /// ToggleButtons - 각 버튼용 bool list 생성
  // final List<bool> _selections = List.generate(3, (_) => false);

  /// Builder Widget for Bottom Navigation Bar
  BottomNavigationBar buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      elevation: 0,
      selectedItemColor: Colors.cyan,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRoundR', fontWeight: FontWeight.bold),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.accessibility),
          label: '나눔',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.accessibility_new),
          label: '나눔요청',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.messenger),
          label: '메신저',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'My',
        )
      ],
    );
  }

  /// Drawer 관련 Scaffold Key
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ///* ----------------- BottomNavigationBar, PageView 관련 ----------------- *///
  /// PaveView 용 controller
  PageController _pageController;
  TabController _tabController;

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

  /// 시스템 함수에 PageView 기능 반영 처리(1)
  /// 위에 initState랑 합쳐짐
 /*
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  */

  /// 시스템 함수에 PageView 기능 반영 처리(2)
  @override
  void dispose() {
    _pageController.dispose();
    //_tabController.dispose();
    super.dispose();
  }


  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if (userChat.id == currentUserId) {
        return SizedBox.shrink();
      } else {
        return Container(
          margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Chat(
                    peerId: userChat.id,
                    peerAvatar: userChat.photoUrl,
                  ),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(greyColor2),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Material(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  clipBehavior: Clip.hardEdge,
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                    userChat.photoUrl,
                    fit: BoxFit.cover,
                    width: 50.0,
                    height: 50.0,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            value: loadingProgress.expectedTotalBytes != null &&
                                loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, object, stackTrace) {
                      return Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: greyColor,
                      );
                    },
                  )
                      : Icon(
                    Icons.account_circle,
                    size: 50.0,
                    color: greyColor,
                  ),
                ),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left: 20.0),
                    child: Column(
                      children: <Widget>[
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                          child: Text(
                            'Nickname: ${userChat.nickname}',
                            maxLines: 1,
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                          child: Text(
                            'About me: ${userChat.aboutMe}',
                            maxLines: 1,
                            style: TextStyle(color: primaryColor),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  ///* -------------------------------------------------------------------- *///
}

/// PostTileMaker - 각 게시글 별 postTile Listview.builder(separated) 사용해 자동 생성
class PostTileMaker extends StatelessWidget {
  PostTileMaker(this._product, this._giveOrTake);

  final Product _product;
  final int _giveOrTake;

  /// Set name for Firebase Storage
  final storage =
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

      /// Custom Tile 구조로 생성 (postTile.dart 구조 참조)
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
              // category: _product.category,
              likes: _product.likes,
              thumbnail: FutureBuilder(
                future: downloadURL(_product.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.hasData) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
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
