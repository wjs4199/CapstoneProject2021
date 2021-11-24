import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giveandtake/pages/chat.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../model/product.dart';
import '../main.dart';
import '../pages/comment.dart';
import 'dart:async';

/// uid 를 이용하여 닉네임을 찾아 호출하고, 이메일을 호출하기 위해 필요한 클래스
class FindInUsers {
  /// User 컬랙션 참조
  static CollectionReference users = FirebaseFirestore.instance.collection('users');

  static String findNickname(AsyncSnapshot<QuerySnapshot> snapshot, String userId) {
    var nickName = ' ';
    snapshot.data.docs.forEach((document) {
      if (document['id'] == userId) {
        nickName = document['nickname'];
      }
    });
    return nickName;
  }

  /// 유저의 학번을 찾아서 보여주는 함수
  static String findStudentNumber(AsyncSnapshot<QuerySnapshot> snapshot, String userId) {
    var email = '2??00000@handong.edu';
    snapshot.data.docs.forEach((document) {
      if (document['id'] == userId) {
        email = document['email'];
      }
    });
    return email;
  }
}

class DetailPage extends StatefulWidget {
  const DetailPage({Key key, this.productId, this.detailGiveOrTake, this.photoNum}) : super(key: key);

  //DetailPage({this.productId, this.detailGiveOrTake, this.photoNum});

  /// route 생성 시에 사용되는 product ID
  final String productId;

  /// giveProducts / takeProducts collection 중 어디서 가져와야하는 지 표시
  final String detailGiveOrTake;

  /// 저장된 photo의 개수
  final int photoNum;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  _DetailPageState({this.chatRoomDocId});

  /// detail 페이지 실행시 인자로 전달되는 변수들
  String productId; // product ID
  String detailGiveOrTake; // giveProducts / takeProducts 중 어디 해당되는지
  int photoNum; // 저장된 photo 의 개수
  String chatRoomDocId;
  var currentUserId = FirebaseAuth.instance.currentUser.uid;
  var name = ''; // myNickname 저장소
  var nickname = ''; //myNickname 임시저장소

  /// futurebuilder 의 future: ___에 사용될 변수
  Future<void> future;

  @override
  void initState() {
    /// 댓글쓰는 창 클릭시 rebuild되는 것을 막기 위해서 한번만 build
    future = makeUrlList();

    super.initState();

    productId = widget.productId; // product ID
    detailGiveOrTake =
        widget.detailGiveOrTake; // giveProducts / takeProducts 중 어디 해당되는지
    photoNum = widget.photoNum; // 저장된 photo 의 개수
  }

  /// comment 적는 텍스트 칸이 빈칸인지 아닌지 분별할 때 사용됨
  final _commentFormKey = GlobalKey<FormState>(debugLabel: '_CommentState');

  /// comment 를 적는 텍스트 상자의 상태를 control 할 때 사용
  final _commentController = TextEditingController();

  /// appbar 아이콘의 컬러를 사진 여부에 따라 다르게 표시하기 위해 필요한 변수
  bool appbarIconColor = false;

  ///************************* 사진 띄우는 부분 관련 변수/ 함수들*************************///
  /// Firebase Storage 참조 간략화
  var storage = firebase_storage.FirebaseStorage.instance;

  /// Carousel_slider 페이지 이동을 인식하기 위한 컨트롤러
  final carouselController = CarouselController();

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<int> carouselIndexChange = StreamController<int>.broadcast();

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<bool> pushLikeButton = StreamController<bool>.broadcast();

  /// Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<int> changeLikeCount = StreamController<int>.broadcast();

  // Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<Icon> changeFavoriteButton =
      StreamController<Icon>.broadcast();

  // Carousel 하단의 Dot list 를 Carousel 페이지에 따라 업데이트 시키기 위해 필요한 stream
  StreamController<String> changeTextField =
      StreamController<String>.broadcast();

  /// storage 에서 다운로드한 이미지 url 들이 저장될 정적 저장소
  var imageUrlList = [];

  /// ProductID에 따라 해당하는 image url 다운로드
  Future<String> downloadURL(String id, int num) async {
    try {
      return await storage
          .ref()
          .child('images')
          .child('$id$num.png')
          .getDownloadURL();
    } on Exception {
      return null;
    }
  }

  /// 다운로드한 url 들 중 null 이 아닌 것들만을 imageUrlList 에 저장시킨는 함수
  Future<void> makeUrlList() async {
    imageUrlList = await Future.wait([
      downloadURL(widget.productId, 0),
      downloadURL(widget.productId, 1),
      downloadURL(widget.productId, 2),
      downloadURL(widget.productId, 3),
      downloadURL(widget.productId, 4),
      downloadURL(widget.productId, 5),
      downloadURL(widget.productId, 6),
      downloadURL(widget.productId, 7),
      downloadURL(widget.productId, 8),
      downloadURL(widget.productId, 9),
    ]);

    imageUrlList = imageUrlList.where((e) => e != null).toList();
  }

  /// 드롭다운 버튼 위해 필요
  var initialFilterCheck = false;
  var _selectedFilter = '진행 중';
  var _filter =['진행 중', '예약 중', '나눔 완료'];

  Color stateCheck(String complete, Color originColor) {
    if(complete == '나눔 완료' || complete == '나눔받기 완료'){
      return Colors.black.withOpacity(0.2);
    }
    return originColor;
  }

  @override
  Widget build(BuildContext context) {


    ///************ ProductID와 맞는 게시물 내용을 Firebase 에서 찾아내는 부분 ************///
    /// DetailPage() 호출시 받는 매개변수 참조
    var productId = widget.productId;
    var detailGiveOrTake = widget.detailGiveOrTake;

    /// detailGiveOrTake 가 담고 있는 collection 이름에 따라 그 collection 담긴 내용 가져오기
    var products = detailGiveOrTake == 'giveProducts'
        ? context.watch<ApplicationState>().giveProducts
        : context.read<ApplicationState>().takeProducts;

    /// 현재 유저의 아이디와 이름 간략화
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userName = FirebaseAuth.instance.currentUser.displayName;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈을 때 그 내용을 담을 변수
    Product product;
    int productNum;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈는지 여부 표시 (찾아냈을 때 true)
    var productFound = false;

    /// products 에 담긴 것들 중 현재 productId와 같은 것 찾기
    for (var i = 0; i < products.length; i++) {
      if (products[i].id == productId) {
        product = products[i];
        productFound = true;
        print(products.length);
        print(product.userName);
        print(product.uid);
      }
    }

    /// productId와 일치하는 게시글이 없을 경우 로딩 표시
    if (products == null ||
        products.isEmpty ||
        productFound == false ||
        product.modified == null) {
      return Scaffold(
        body: CircularProgressIndicator(),
      );
    }

    ///************************ 게시글 삭제 및  지난 시간 계산 함수들 ************************///
    /// 게시물 자체 삭제 기능 (왼쪽 상단 휴지통 버튼)
    Future<void> deleteProduct() async {
      try {
        return await FirebaseFirestore.instance
            .collection(detailGiveOrTake)
            .doc(productId)
            .delete();
      } on Exception {
        return null;
      }
    }

    Future<void> deleteOneImage(int num) async {
      try {
        print('사진 삭제 시작!');
        return await storage
            .refFromURL(imageUrlList[num])
            .delete()
            .whenComplete(() => print('$num번째 사진 삭제 완료!'));
      } on Exception {
        return null;
      }
    }

    Future<void> deleteImages() async {
      return await Future.wait([
        deleteOneImage(0),
        deleteOneImage(1),
        deleteOneImage(2),
        deleteOneImage(3),
        deleteOneImage(4),
        deleteOneImage(5),
        deleteOneImage(6),
        deleteOneImage(7),
        deleteOneImage(8),
        deleteOneImage(9),
      ]);
    }

    /// 현재 시간
    var nowTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateTime.now().hour,
        DateTime.now().minute,
        DateTime.now().second);

    /// 상품에 저장된 최근에 수정된 시간
    var productTime = DateTime(
        product.modified.toDate().year,
        product.modified.toDate().month,
        product.modified.toDate().day,
        product.modified.toDate().hour,
        product.modified.toDate().minute,
        product.modified.toDate().second);

    /// 현재시간 - 게시글 마지막 수정 시간 계산하여 내보내는 위젯
    String calculateTime() {
      var time = nowTime.difference(productTime).inDays;

      /// 하루가 안지났을 때
      if (time < 1) {
        time = nowTime.difference(productTime).inHours;

        /// 한시간도 안지났을 때
        if (time < 1) {
          time = nowTime.difference(productTime).inMinutes;

          /// 1분도 안지났을 때
          if (time < 1) {
            return '방금';
          } else {
            return '$time분 전';
          }
        } else {
          return '$time시간 전';
        }
      }

      /// 7일이 안지났을 때
      else if (time < 7) {
        return '$time일 전';
      }

      /// 일주일 이상 지났고 한달 미만의 시간이 지났을 떄
      else if (time >= 7 && time < 30) {
        time = nowTime.difference(productTime).inDays;
        if (time < 14) {
          return '1주 전';
        } else if (time < 21) {
          return '2주 전';
        } else if (time < 28) {
          return '3주 전';
        } else if (time < 30) {
          return '한달 전';
        }
      }

      /// 한달이상 지났을 때
      else if (time >= 30) {
        time = nowTime.difference(productTime).inDays;
        if (time <= 60) {
          return '한달 전';
        } else if (time <= 90) {
          return '두달 전';
        } else if (time <= 120) {
          return '세달 전';
        } else if (time <= 150) {
          return '네달 전';
        } else if (time <= 150) {
          return '다섯달 전';
        } else if (time <= 180) {
          return '반년 전';
        } else {
          return '오래 된 글';
        }
      } else {
        return '오래 된 글';
      }
      return '오래 된 글';
    }

    ///************************ like 기능 구현부분 ************************///

    /// giveProducts 또는 takeProducts 중 어디에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference likes = FirebaseFirestore.instance
        .collection('${widget.detailGiveOrTake}/' + productId + '/like');

    /// 현재는 하트버튼 누르면 사용자가 이미 눌렀든 말든 간에 계속 숫자 올라감 ㅋㅎ (수정필요)
    /// 현재 사용자가 이미 좋아요를 누른 경우를 분별하는 함수
    bool isLiked(AsyncSnapshot<QuerySnapshot> snapshot) {
      var isLikeCheck = false;
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId) {
          isLikeCheck = true;
        }
      });

      return isLikeCheck;
    }

    /// 사용자가 하트 누른 경우 좋아요 추가하는 기능
    Future<void> addLike() async {
      return await likes
          .add({'uid': userId})
          .then((value) => print('LIKE 추가됨!'))
          .catchError((error) => print('Failed to add a like: $error'));
    }

    /// 좋아요 취소기능
    Future<void> deleteLike(userId) async {
      try {
        for (var eachLike in context.read<ApplicationState>().likeList) {
          if (eachLike.uid == userId) {
            await likes
                .doc(eachLike.id)
                .delete()
                .then((value) => print('LIKE 취소됨! 취소된 uid 는 ${eachLike.id}'))
                .catchError((error) => print('Failed to add a like: $error'));
          }
        }
      } on Exception {
        return null;
      }
    }

    /// 'comments' Collection 참조
    CollectionReference comments = detailGiveOrTake == 'giveProducts' ? FirebaseFirestore.instance
        .collection('giveProducts/' + productId + '/comment')
    : FirebaseFirestore.instance
        .collection('takeProducts/' + productId + '/comment');

    /// comment 추가 기능
    Future<void> addComments(String comment, String uid) {
      return comments
          .add({
            'userName': FirebaseAuth.instance.currentUser.displayName,
            'comment': comment,
            'created': FieldValue.serverTimestamp(),
            // 빼야할지도!
            'uid': uid,
          })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
    }

    _currentNickname() async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get()
          .then((DocumentSnapshot ds) {
        name = ds['nickname'];
        nickname = name;
        return name;
      });
    }

    _currentNickname();

    ///****************************** 상태변경 기능 부분 ******************************///
    /// giveProducts 또는 takeProducts 중 어디 컬랙션에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference target =
    FirebaseFirestore.instance.collection(detailGiveOrTake);

    /// complete 필드 값을 드롭다운 버튼 변경한대로 바꾸는 함수
    Future<void> editComplete(String complete) {
      return target.doc(productId).update({
        'complete': complete,
      }).whenComplete(() async {
        Navigator.pop(context);
      }).catchError((error) => print('Error: $error'));
    }

    /// 게시자 이름 옆의 완료/예약/진행중 표시하는 드롭다운 버튼 (자기가 올린 게시물일 경우에 보여짐)
    Container _buildDropdownButtonForComplete(
        String complete, String detailGiveOrTake){
      if(!initialFilterCheck){
        _selectedFilter = complete;
      }
      if(detailGiveOrTake == 'giveProducts') {
        _filter = ['진행 중', '예약 중', '나눔 완료'];
      } else {
        _filter = ['진행 중', '예약 중', '나눔받기 완료'];
      }
      return Container(
          decoration: ShapeDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius:BorderRadius.all(Radius.circular(15.0)),)),
          child: DropdownButtonHideUnderline(
              child: Container(
                margin: EdgeInsets.only( left: 15.0, right: 15.0),
                child: DropdownButton<String>(
                  //dropdownColor: Colors.grey.,
                  value: _selectedFilter,
                  items: _filter.map(
                        (value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'NanumSquareRoundR',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    initialFilterCheck = true;
                    if (value != _selectedFilter) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              CupertinoAlertDialog(
                                title: Text('상태 변경',
                                    style: TextStyle(
                                      fontFamily: 'NanumSquareRoundR',
                                      height: 1.5,
                                    )
                                ),
                                content: value.substring(0,2) == '나눔'
                                    ? Text('$value 로 상태를 변경하시겠습니까?',
                                    style: TextStyle(
                                      fontFamily: 'NanumSquareRoundR',
                                      height: 1.5,
                                      fontSize: 14,
                                    )
                                )
                                    : Text('$value으로 상태를 변경하시겠습니까?',
                                    style: TextStyle(
                                      fontFamily: 'NanumSquareRoundR',
                                      height: 1.5,
                                      fontSize: 14,
                                    )
                                ),
                                actions: <Widget>[
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('아니오'),
                                  ),
                                  Consumer<ApplicationState>(
                                    builder: (context, appState, _) =>
                                        CupertinoDialogAction(
                                          onPressed: () async {
                                            // 색바꾸기
                                            // editComplete 함수 내에서 pop 함
                                            await editComplete(value).whenComplete(() {
                                              setState(() {
                                                _selectedFilter = value;
                                              });
                                            });
                                          },
                                          child: Text('네'),
                                        ),
                                  )
                                ],
                              ));
                    }
                  },
                ),
              )
          ));
    }


    /// _CommentChatButtonsForOthers(채팅하기 버튼)에서 사용자의 닉네임을 담을 변수 선언
    String nickName;

    /// 게시자 이름 옆의 채팅하기 버튼 (자기가 올린 게시물이 아닐 경우에 보여짐)
    InkWell _CommentChatButtonsForOthers(
        BuildContext context, ApplicationState appState) {
      return InkWell(
        child: StreamBuilder<QuerySnapshot>(
          stream: FindInUsers.users.snapshots(),
          builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
          return Text('x');
          }
          if (snapshot.connectionState ==
          ConnectionState.waiting) {
          return Text('');
          }
          nickName = FindInUsers.findNickname(snapshot, product.uid);
          return Container(
              padding: EdgeInsets.fromLTRB( 11.0, 8, 11.0, 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 10,),
                  Text('채팅하기  ',
                    style: TextStyle(
                      color: stateCheck(product.complete, Colors.black),
                      fontSize: 15,
                      fontFamily: 'NanumSquareRoundR',
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Stack(
                    children: [
                      Image.asset(
                        'assets/chat_grey.jpg',
                        //'assets/chat.jpg',
                        width: 17,
                        height: 17,
                      ),
                    ],
                  )

                ],
              ),
            );
          }),
        onTap: () {
          /// 나눔 완료가 아닐 시에만 채팅하기 버튼 가능
          if(product.complete.substring(0,2) != '나눔') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    Chat(
                      peerId: product.uid,
                      peerAvatar: product
                          .user_photoURL,
                      peerName: nickName,
                      myName: name, ///editted
                      myAvatar:
                      FirebaseAuth
                          .instance
                          .currentUser
                          .photoURL,
                    ),
              ),
            );
          }

        },
      );
    }


    /// Add 페이지 화면 구성
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Stack(
        children: [
          NestedScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.5,
                  backgroundColor: Colors.white,
                  iconTheme: IconThemeData(
                    // color: Colors.black,
                    opacity: 0.9,
                  ),
                  pinned: true, // true 처리 시 스크롤을 내려도 appbar 가 작게 보임
                  floating: false, // true 처리 시 스크롤을 내릴때 appbar 가 보임
                  snap: false, // true 처리 시 스크롤 살짝 내리면 appbar 가 전부 보임
                  stretch: false,
                  // onStretchTrigger: () {
                  //   // Function callback for stretch
                  //   return Future<void>.value();
                  // },
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    // stretchModes: const <StretchMode>[
                    //   StretchMode.zoomBackground,
                    //   StretchMode.blurBackground,
                    //   StretchMode.fadeTitle,
                    // ],
                    background: FutureBuilder(
                      future: future,
                      builder: (context, snapshot) {
                        /// 시진 로딩중일 때
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Column(
                            children: [
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                width: MediaQuery.of(context).size.width,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            ],
                          );
                        }

                        /// 사진 로딩 후
                        else {
                          if (imageUrlList.isNotEmpty) {
                            return Stack(
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  width: MediaQuery.of(context).size.width,
                                  // color: Color(0xffced3d0),
                                ),
                                CarouselSlider(
                                  carouselController: carouselController,
                                  options: CarouselOptions(
                                      autoPlay: false,
                                      enlargeCenterPage: false,
                                      viewportFraction: 1.0,
                                      aspectRatio: 1.0,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.5,
                                      initialPage: 0,
                                      onPageChanged: (index, reason) {
                                        carouselIndexChange.add(index);
                                      }),
                                  items: imageUrlList.map<Widget>((item) {
                                    return Image.network(
                                      item,
                                      fit: BoxFit.cover,
                                    );
                                  }).toList(),
                                ),

                                /// 사진 밑의 dot Row
                                StreamBuilder<int>(
                                    stream: carouselIndexChange.stream,
                                    initialData: 0,
                                    builder: (context, snapshot) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.46,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: imageUrlList
                                                .asMap()
                                                .entries
                                                .map<Widget>((entry) {
                                              return GestureDetector(
                                                onTap: () {
                                                  carouselController
                                                      .animateToPage(entry.key);
                                                  print(
                                                      'entry key -> ${entry.key}');
                                                },
                                                child: Container(
                                                  width: 8.0,
                                                  height: 8.0,
                                                  margin: EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                      horizontal: 4.0),
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: (Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                              : Colors.black)
                                                          .withOpacity(
                                                              snapshot.data ==
                                                                      entry.key
                                                                  ? 1.0
                                                                  : 0.4)),
                                                ),
                                              );
                                            }).toList(),
                                          )
                                        ],
                                      );
                                    }),
                              ],
                            );
                          }

                          /// imageUrlList 데이터가 없으면 사진란 아예 없앰 => 기본썸네일
                          else {
                            return Image.asset(
                              'assets/no-thumbnail.jpg',
                              fit: BoxFit.cover,
                              height: MediaQuery.of(context).size.height * 0.5,
                              width: MediaQuery.of(context).size.width,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  actions: <Widget>[
                    if (FirebaseAuth.instance.currentUser.uid == product.uid)
                      IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            semanticLabel: 'edit',
                          ),
                          onPressed: (FirebaseAuth.instance.currentUser.uid ==
                                  product.uid)
                              ? () => Navigator.pushNamed(
                                    context,
                                    '/edit/' +
                                        productId +
                                        '/' +
                                        detailGiveOrTake,
                                  )
                              : null),
                    if (FirebaseAuth.instance.currentUser.uid == product.uid)
                      IconButton(
                          icon: Icon(
                            Icons.delete_forever_outlined,
                            semanticLabel: 'delete',
                          ),
                          onPressed: (FirebaseAuth.instance.currentUser.uid ==
                                  product.uid)
                              ? () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CupertinoAlertDialog(
                                        title: Text('게시글 삭제'),
                                        content: Text('정말 이 게시글을 삭제하시겠습니까?'),
                                        actions: <Widget>[
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('아니오'),
                                          ),
                                          Consumer<ApplicationState>(
                                            builder: (context, appState, _) =>
                                                CupertinoDialogAction(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                deleteProduct()
                                                    .then((value) =>
                                                        appState.init())
                                                    .catchError((error) => null)
                                                    .whenComplete(() {
                                                  Navigator.pop(context);
                                                  if(product.photo!=0){
                                                    deleteImages();
                                                  }

                                                });
                                              },
                                              child: Text('네'),
                                            ),
                                          )
                                        ],
                                      ))
                              : null)
                  ],
                ),
              ];
            },
            body: SingleChildScrollView(
              child: Container(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20.0),

                                        /// 게시자 사진, 이름, 학번
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            /// 게시자 사진
                                            SizedBox(
                                              width: 42,
                                              height: 42,
                                              child: Image.asset(
                                                  'assets/userDefaultImage.png'),
                                            ),
                                            SizedBox(width: 10.0),
                                            StreamBuilder<QuerySnapshot>(
                                                    stream: FindInUsers.users.snapshots(),
                                                    builder: (BuildContext context,
                                                    AsyncSnapshot<QuerySnapshot> snapshot2) {
                                                    if (snapshot2.hasError) {
                                                    return Text('x');
                                                    }
                                                    if (snapshot2.connectionState ==
                                                    ConnectionState.waiting) {
                                                    return Text('');
                                                    }
                                                    /// 이름과 학번
                                                    return Column(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        height: 2,
                                                      ),
                                                      /// 이름
                                                      Text(
                                                          '${FindInUsers.findNickname(snapshot2, product.uid)}',
                                                          style: TextStyle(
                                                            fontFamily: 'NanumSquareRoundR',
                                                            color: stateCheck(product.complete, Colors.black),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      SizedBox(height: 3),
                                                      /// 학번
                                                      Text( FindInUsers.findStudentNumber(snapshot2, product.uid).substring(1,3) + '학번',
                                                          style: TextStyle(
                                                            color: stateCheck(product.complete, Colors.black.withOpacity(0.4)),
                                                            fontSize: 13,
                                                            fontFamily: 'NanumSquareRoundR',
                                                          ),
                                                        )
                                                    ]
                                                    );
                                                    }),
                                            if(userName != product.userName)
                                              Expanded(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      _CommentChatButtonsForOthers(
                                                        context, Provider.of<ApplicationState>(context, listen: false),
                                                    ),
                                                    ]
                                                  )

                                              )
                                            else
                                              Expanded(
                                                  child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        _buildDropdownButtonForComplete(product.complete, widget.detailGiveOrTake),
                                                      ]
                                                  )
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 9.0),
                                        Divider(thickness: 1.0),
                                        SizedBox(height: 9.0),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: RichText(
                                                overflow: TextOverflow.ellipsis,
                                                maxLines:4,
                                                text: TextSpan(
                                                    style: TextStyle(
                                                      fontFamily: 'NanumSquareRoundR',
                                                      color: stateCheck(product.complete, Colors.black),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: '${product.title}\n',
                                                        style: TextStyle(
                                                          fontFamily: 'NanumSquareRoundR',
                                                          color: stateCheck(product.complete, Colors.black),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 22,
                                                          height: 1.5,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                        '${product.category} · ${calculateTime()}\n\n',
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto_Bold',
                                                          color: stateCheck(product.complete, Colors.grey),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          height: 1.6,
                                                        ),
                                                      ),
                                                    ]),
                                                textAlign: TextAlign.start,
                                              ),
                                            )
                                          ],
                                        ),

                                        /// 게시글 내용
                                        Text(
                                          product.content ?? product.content,
                                          style: TextStyle(
                                            fontFamily: 'NanumSquareRoundR',
                                            color: stateCheck(product.complete, Colors.black),
                                            //fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            height: 1.5,
                                          ),
                                        ),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: likes.snapshots().asBroadcastStream(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<QuerySnapshot> snapshot) {
                                            if (snapshot.hasError) {
                                              return Text('x',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    height: 1,
                                                  ));
                                            }
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Text('',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    height: 1,
                                                  ));
                                            }
                                            var count = snapshot.data.size;
                                            return StreamBuilder<int>(
                                                stream: changeLikeCount.stream
                                                    .asBroadcastStream(),
                                                initialData: count,
                                                builder: (context, snapshot2) {
                                                  return Text(
                                                    '\n\n조회 ${product.hits}회 · 좋아요 ${snapshot2.data}회',
                                                    style: TextStyle(
                                                      fontFamily: 'NanumSquareRoundR',
                                                      color: stateCheck(product.complete, Colors.grey),
                                                      //fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      height: 1,
                                                    ),
                                                  );
                                                });
                                          },
                                        ),
                                        SizedBox(height: 9.0),
                                        if(product.complete.substring(0,2) != '진행')
                                          Container(
                                            padding: EdgeInsets.fromLTRB(11, 8, 11, 8),
                                            margin: EdgeInsets.fromLTRB(0,8,8,8),
                                            decoration: ShapeDecoration(
                                                color: product.complete != '예약 중' ? Colors.black.withOpacity(0.4): Colors.red.withOpacity(0.4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:BorderRadius.all(Radius.circular(10.0)),)),
                                            child: Text(
                                              /// 예약중이거나 완료되었을 때 표시됨
                                              product.complete != '예약 중' ? '${product.complete}됨': '${product.complete}',
                                              style: TextStyle(
                                                fontFamily: 'NanumSquareRoundR',
                                                color: product.complete != '예약 중' ? Colors.black.withOpacity(0.7): Colors.red,//Color(0xfffc7174).withOpacity(0.7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        Divider(thickness: 1.0),
                                      ]),
                                ),
                                SizedBox(width: 20),
                              ],
                            ),

                    /// 게시물 내용 아래 댓글들
                    Container(
                        padding: const EdgeInsets.fromLTRB(8.0, 4, 8, 8),
                        child: CommentBook(
                          detailGiveOrTake: detailGiveOrTake,
                          productId: productId,
                        )),

                            /// 고정된 댓글 창과 겹치지 않게하는 sizedbox
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.044,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      //height: MediaQuery.of(context).size.height * 0.157,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xffe5e5e5),
                        boxShadow: [
                          BoxShadow(color: Color(0xffe5e5e5), spreadRadius: 2),
                        ],
                      ),
                      margin: EdgeInsets.fromLTRB(7.0, 7.0, 7.0, 1.0),
                      child: Row(
                        children: [
                          // 하트 아이콘
                          Container(
                            width: 50,
                            child: StreamBuilder<QuerySnapshot>(
                                stream: likes.snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('x');
                                  }
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text('');
                                  }
                                  return StreamBuilder<Icon>(
                                      stream: changeFavoriteButton.stream,
                                      initialData: isLiked(snapshot)
                                          ? Icon(
                                        Icons.favorite,
                                        color: stateCheck(product.complete, Color(0xfffc7174),),
                                        semanticLabel: 'like',
                                      )
                                          : Icon(
                                        Icons.favorite_border_outlined,
                                        color:stateCheck(product.complete, Color(0xfffc7174)),
                                        semanticLabel: 'like',
                                      ),
                                      builder: (context, snapshot2) {
                                        /// changeFavoriteButton 스트림 컨트롤러에 새 데이터가 들어올때마다 부분적으로 빌드됨
                                        return IconButton(

                                          /// 아이콘의 snapshot2 => changeFavoriteButton 스트림으로 건네준 아이콘
                                            icon: snapshot2.data,
                                            onPressed: () async {
                                              /// 이미 좋아요가 눌러져 있었을 떄
                                              if (isLiked(snapshot)) {
                                                await deleteLike(userId)
                                                    .catchError((error) => null)
                                                    .whenComplete(() {
                                                  products =
                                                  detailGiveOrTake == 'giveProducts'
                                                      ? context
                                                      .read<ApplicationState>()
                                                      .giveProducts
                                                      : context
                                                      .read<ApplicationState>()
                                                      .takeProducts;
                                                  changeFavoriteButton.add(Icon(
                                                    Icons.favorite_border_outlined,
                                                    color: stateCheck(product.complete,Color(0xfffc7174),),
                                                    semanticLabel: 'like',
                                                  ));
                                                  changeLikeCount.add(context
                                                      .read<ApplicationState>()
                                                      .likeCount);
                                                });
                                              }

                                              /// 좋아요가 눌러져 있지 않을 때
                                              else {
                                                await addLike()
                                                    .catchError((error) => null)
                                                    .whenComplete(() {
                                                  products =
                                                  detailGiveOrTake == 'giveProducts'
                                                      ? context
                                                      .read<ApplicationState>()
                                                      .giveProducts
                                                      : context
                                                      .read<ApplicationState>()
                                                      .takeProducts;
                                                  changeFavoriteButton.add(Icon(
                                                    Icons.favorite,
                                                    color: stateCheck(product.complete, Color(0xfffc7174),),
                                                    semanticLabel: 'like',
                                                  ));
                                                  changeLikeCount.add(context
                                                      .read<ApplicationState>()
                                                      .likeCount);
                                                });
                                              }
                                            });
                                      });
                                }),
                          ),
                          // 입력부분
                          Form(
                            key: _commentFormKey,
                            child: Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 1, 10, 5),
                                  child: TextFormField(
                                    style: TextStyle(
                                      fontFamily: 'NanumSquareRoundR',
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(400), //글자 수 제한 400자
                                    ],
                                    enabled: product.complete.substring(0,2) != '나눔' ? true : false,
                                    enableInteractiveSelection: true,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      hintText: product.complete.substring(0,2) != '나눔' ? '댓글을 입력하세요' : '완료 처리된 게시글입니다',
                                      hintStyle: TextStyle(
                                        fontFamily: 'NanumSquareRoundR',
                                      )
                                    ),
                                  ),
                                )),
                          ),
                          SizedBox(width: 3),
                          // 댓글 저장 아이콘
                          IconButton(
                            icon: const Icon(Icons.send_outlined),
                            iconSize: 27,
                            color: stateCheck(product.complete, Color(0xfffc7174),),
                            onPressed: () async {
                              var currentFocus = FocusScope.of(context);
                              currentFocus.unfocus();
                              if (_commentFormKey.currentState.validate()) {
                                await addComments(_commentController.text, userId)
                                    .then((value) => print('add comment ok!'));
                                _commentController.clear();
                                products = detailGiveOrTake == 'giveProducts'
                                    ? context.read<ApplicationState>().giveProducts
                                    : context.read<ApplicationState>().takeProducts;
                                print('clear!');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
            ),
          ],
        )
      ),
    );
  }
}
