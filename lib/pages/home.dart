import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:giveandtake/pages/login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// Home
class HomePage extends StatefulWidget {
  ///* ------------------------------ 수정 -------------------------------- *////
  final String currentUserId; // main 에 정의되어도 됨
  HomePage({Key key, @required this.currentUserId}) : super(key: key); // 필요X

  ///* ------------------------------------------------------------------ *////
  @override
  State createState() => _HomePageState(currentUserId: currentUserId);
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  ///* ------------------------------ 수정 -------------------------------- *////
  /// _HomePageState 클래스 밑에 바로 build 가 보이도록,
  /// home.dart 에 정의 필요 없는것들 전부 main.dart 로
  _HomePageState({Key key, @required this.currentUserId});

  final String currentUserId;
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
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);

  }

  /// 시스템 함수에 PageView 기능 반영 처리(2)
  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
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
                  /// 작업중
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
            title: Text('Sign Out'),
            // - The Menu Icons should be placed in the leading position
            leading: Icon(
              Icons.logout,
            ),
            onTap: () {
              // - Each menu should be navigated by Named Routes
              /// 오류수정
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
      /// 0(홈):
      HomeView(context, appState),

      /// 1(나눔):
      NanumView(context, appState, _tabController),

      /// 2(나눔요청):
      RequestView(context, appState, _tabController),

      /// 3(메신저):
      MsgView(context, appState),

      /// 4(MyPage):
      MyView(context, appState)
    ];
    return _widgetOptions;
  }

  /// FloatingActionButton 생성기 (버튼 2개로 수정)
  Widget buildFAB() {
    if (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2) {
      return Container(
        height: 60,
        width: 60,
        color: Colors.transparent,
        child: SpeedDial(
          icon: Icons.add,
          animatedIconTheme: IconThemeData(size: 30),
          activeIcon: Icons.close,
          backgroundColor: Colors.cyan,
          childPadding: EdgeInsets.all(5),
          spacing: 10,
          visible: true,
          elevation: 10.0,
          curve: Curves.bounceIn,
          animationSpeed: 120,
          overlayOpacity: 0.7,
          children: [
            // FAB 1
            SpeedDialChild(
              child: Icon(Icons.accessibility, size: 27, color: Colors.white,),
              backgroundColor: Colors.cyan,
              onTap: () {
                Navigator.pushNamed(context, '/giveadd');
              },
              label: '나눔',
              labelStyle: TextStyle(
                  fontFamily: 'NanumSquareRoundrR',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16.0),
              labelBackgroundColor: Colors.cyan,),
            // FAB 2
            SpeedDialChild(
              child: Icon(Icons.accessibility_new, size: 27, color: Colors.white,),
              backgroundColor: Colors.cyan,
              onTap: () {
                Navigator.pushNamed(context, '/takeadd');
              },
              label: '나눔 요청',
              labelStyle: TextStyle(
                  fontFamily: 'NanumSquareRoundR',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16.0),
              labelBackgroundColor: Colors.cyan,)
          ],
        ),
      );


        /*FloatingActionButton(
        onPressed: () {
          setState(() {
            _getFAB();
          });

          //Navigator.pushNamed(context, '/add');
        },
        backgroundColor: Colors.cyan,
        child: Icon(Icons.add),
      );*/
    }
    ;
    return null;
  }

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

  /// Sign Out (call on null 오류)
  Future<Null> handleSignOut() async {
    /*
    setState(() {
      isLoading = true;
    });

     */

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
/*
    setState(() {
      isLoading = false;
    });


 */
    await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false);
  }

  ///* ---------------- BottomNavigationBar, PageView 관련 ----------------- *///
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

///* -------------------------------------------------------------------- *///
}

/// PostTileMaker - 각 게시글 별 postTile Listview.builder(separated) 사용해 자동 생성
class PostTileMaker extends StatelessWidget {
  PostTileMaker(this._product, this._giveOrTake);

  final Product _product;
  final bool _giveOrTake;

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

    /// 사용자가 게시글 눌러 들어갈 때마다 조회수 올리는 함수
    Future<void> editProductHits(String GiveOrTake) {
      return FirebaseFirestore.instance.collection(GiveOrTake).doc(_product.id).update({
        'hits': _product.hits + 1,
      });
    }

    return InkWell(
      onTap: () {
        if (_giveOrTake) {
          Provider.of<ApplicationState>(context, listen: false)
              .detailPageUid(_product.id, 'giveProducts', _product.photo);
          Navigator.pushNamed(
              context, '/detail/' + _product.id + '/giveProducts');
          editProductHits('giveProducts');
        } else {
          Provider.of<ApplicationState>(context, listen: false)
              .detailPageUid(_product.id, 'takeProducts',_product.photo);
          Navigator.pushNamed(
              context, '/detail/' + _product.id + '/takeProducts');
          editProductHits('takeProducts');
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
