import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';

import '../main.dart';
import '../model/product.dart';
import '../components/postTile.dart';
import 'views/0_home_view.dart';
import 'views/1_nanum_view.dart';
import 'views/2_msg_view.dart';
import 'views/3_my_view.dart';

// home
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  /// Index 별 위젯 반환: (순서: 0-홈, 1-나눔, 2-메신저, 3-My)
  List<Widget> _buildWidgetOptions(
      BuildContext context, ApplicationState appState, int selectedIndex) {
    var _widgetOptions = <Widget>[
      /// 0(홈):
      HomeView(context, appState, selectedIndex),

      /// 1(나눔):
      NanumView(context, appState, selectedIndex),

      /// 2(메신저):
      MsgView(context, appState, selectedIndex),

      /// 3(MyPage):
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
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  /// 시스템 함수에 PageView 기능 반영 처리(2)
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ///* -------------------------------------------------------------------- *///
}

/// PostTileMaker - 각 게시글 별 postTile Listview.builder(separated) 사용해 자동 생성
class PostTileMaker extends StatelessWidget {
  PostTileMaker(this._product, this._giveOrTake);

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
