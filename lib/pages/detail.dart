import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giveandtake/pages/chat.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../model/product.dart';
import '../main.dart';
import '../pages/comment.dart';
import 'dart:async';

import 'home.dart';

class DetailPage extends StatefulWidget {

  DetailPage({this.productId, this.detailGiveOrTake, this.photoNum});

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

  /// detail 페이지 실행시 인자로 전달되는 변수들
  String productId ; // product ID
  String detailGiveOrTake; // giveProducts / takeProducts 중 어디 해당되는지
  int photoNum; // 저장된 photo 의 개수

  @override
  void initState() {
    super.initState();

    productId = widget.productId; // product ID
    detailGiveOrTake = widget.detailGiveOrTake; // giveProducts / takeProducts 중 어디 해당되는지
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
  StreamController<Icon> changeFavoriteButton = StreamController<Icon>.broadcast();

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
      downloadURL(widget.productId,0),
      downloadURL(widget.productId,1),
      downloadURL(widget.productId,2),
      downloadURL(widget.productId,3),
      downloadURL(widget.productId,4),
      downloadURL(widget.productId,5),
      downloadURL(widget.productId,6),
      downloadURL(widget.productId,7),
      downloadURL(widget.productId,8),
      downloadURL(widget.productId,9),]);

    imageUrlList = imageUrlList.where((e) => e != null).toList();

    //future안에서 for문이 안돌아서 정적 리스트에 들어가는 것을 확인하기 위해 이렇게 해둠
    print('imageURL 리스트의 길이는  => ${imageUrlList.length}');
    print('0 번째 imageUrlList 주소는 => ${imageUrlList[0]}');
    print('1 번째 imageUrlList 주소는 => ${imageUrlList[1]}');
    print('2 번째 imageUrlList 주소는 => ${imageUrlList[2]}');
    print('3 번째 imageUrlList 주소는 => ${imageUrlList[3]}');
    print('4 번째 imageUrlList 주소는 => ${imageUrlList[4]}');
    print('5 번째 imageUrlList 주소는 => ${imageUrlList[5]}');
    print('6 번째 imageUrlList 주소는 => ${imageUrlList[6]}');
    print('7 번째 imageUrlList 주소는 => ${imageUrlList[7]}');
    print('8 번째 imageUrlList 주소는 => ${imageUrlList[8]}');
    print('9 번째 imageUrlList 주소는 => ${imageUrlList[9]}');
  }

  @override
  Widget build(BuildContext context) {

    ///************ ProductID와 맞는 게시물 내용을 Firebase 에서 찾아내는 부분 ************///
    /// DetailPage() 호출시 받는 매개변수 참조
    var productId = widget.productId;
    var detailGiveOrTake = widget.detailGiveOrTake;

    /// detailGiveOrTake 가 담고 있는 collection 이름에 따라 그 collection 담긴 내용 가져오기
    // 시작하자마자 이부분에서 build가 2번 되길래 watch에서 read로 바꿈
    var products = detailGiveOrTake == 'giveProducts'
        ? context.read<ApplicationState>().giveProducts
        : context.read<ApplicationState>().takeProducts;

    CollectionReference users = FirebaseFirestore.instance
        .collection('users');

    /// 현재 유저의 아이디와 이름 간략화
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userName = FirebaseAuth.instance.currentUser.displayName;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈을 때 그 내용을 담을 변수
    Product product;

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

    /// 유저의 닉네임을 찾아서 보여주는 함수
    String findNickname( AsyncSnapshot<QuerySnapshot> snapshot, String name){
      var nickName = 'null';
      snapshot.data.docs.forEach((document) {
        if (document['username'] == name){
          nickName = document['nickname'];
        }
      });

      print('찾은 닉네임은 $nickName!!');

      return nickName;
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

    /// 현재 시간
    var nowTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateTime.now().hour,
        DateTime.now().minute,
        DateTime.now().second
    );

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
      if(time < 1) {
        time = nowTime.difference(productTime).inHours;
        /// 한시간도 안지났을 때
        if(time< 1){
          time = nowTime.difference(productTime).inMinutes;
          /// 1분도 안지났을 때
          if(time<1){
            return '방금';
          } else {
            return '$time분 전';
          }
        } else {
          return '$time시간 전';
        }
      } /// 7일이 안지났을 때
      else if(time < 7) {
        return '$time일 전';
      }
      /// 일주일 이상 지났고 한달 미만의 시간이 지났을 떄
      else if(time >= 7 && time < 30) {
        time = nowTime.difference(productTime).inDays;
        if(time < 14){
          return '1주 전';
        } else if(time < 21){
          return '2주 전';
        } else if(time< 28){
          return '3주 전';
        } else if(time< 30){
          return '한달 전';
        }
      } /// 한달이상 지났을 때
      else if (time >= 30) {
        time = nowTime.difference(productTime).inDays;
        if(time <= 60) {
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


    ///************************ like 기능 구현부분 (수정필요) ************************///

    /// giveProducts 또는 takeProducts 중 어디에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference likes = FirebaseFirestore.instance
          .collection('${widget.detailGiveOrTake}/' + productId + '/like');

    /// 현재는 하트버튼 누르면 사용자가 이미 눌렀든 말든 간에 계속 숫자 올라감 ㅋㅎ (수정필요)
    /// 현재 사용자가 이미 좋아요를 누른 경우를 분별하는 함수
    bool isLiked( AsyncSnapshot<QuerySnapshot> snapshot){
      var isLikeCheck = false;
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId){
          isLikeCheck = true;
        }
      });

      if(isLikeCheck){
        print('isLiked에서 좋아요는 지금 true 상태!!');
      } else{
        print('isLiked에서 좋아요는 지금 false 상태ㅠㅠ');
      }

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
        for (var eachLike in context.read<ApplicationState>().likeList){
          if(eachLike.uid == userId){
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
    CollectionReference comments = FirebaseFirestore.instance
        .collection('giveProducts/' + productId + '/comment');

    /// comment 추가 기능
    Future<void> addComments(String comment) {
      return comments
          .add({
        'userName': FirebaseAuth.instance.currentUser.displayName,
        'comment': comment,
        'created': FieldValue.serverTimestamp(),
      })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
    }

    /// Add 페이지 화면 구성
    return Scaffold(
      body: SafeArea(
          child: Stack(
            children: [
              ListView(
                  children: [
                    Stack(
                      children: [
                        /// MultiImage를 보여주는 Carousel 위젯 부분
                        FutureBuilder(
                          future: makeUrlList(),
                          builder: (context, snapshot) {
                            /// 시진 로딩중일 때
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Column(
                                children: [
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    width: MediaQuery.of(context).size.width,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                ],
                              );
                            }
                            /// 사진 로딩 후
                            else {
                              return Stack(
                                children: [
                                  /// imageUrlList 데이터가 있으면 CarouselSlider보여줌
                                  if(imageUrlList.isNotEmpty)
                                    Stack(
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context).size.height * 0.5,
                                          width: MediaQuery.of(context).size.width,
                                          color: Color(0xffced3d0),
                                        ),
                                        CarouselSlider(
                                          carouselController: carouselController,
                                          options: CarouselOptions(
                                              autoPlay: false,
                                              enlargeCenterPage: false,
                                              viewportFraction: 1.0,
                                              aspectRatio: 1.0,
                                              height: MediaQuery.of(context).size.height* 0.5,
                                              initialPage: 0,
                                              onPageChanged: (index, reason) {
                                                carouselIndexChange.add(index);
                                              }
                                          ),
                                          items: imageUrlList.map<Widget>((item) {
                                            return Container(
                                              child: Image.network(item,
                                                  fit: BoxFit.cover,
                                                  width: 1000),
                                            );
                                          }).toList(),
                                        ),
                                        /// 사진 밑의 dot Row
                                        StreamBuilder<int>(
                                            stream: carouselIndexChange.stream,
                                            initialData: 0,
                                            builder: (context, snapshot) {
                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: MediaQuery.of(context).size.height* 0.46,),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: imageUrlList.asMap().entries.map<Widget>((entry){
                                                      return GestureDetector(
                                                        onTap: () {
                                                          carouselController.animateToPage(entry.key);
                                                          print('entry key -> ${entry.key}');
                                                        },
                                                        child: Container(
                                                          width: 12.0,
                                                          height: 12.0,
                                                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: (Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.white
                                                                  : Colors.black)
                                                                  .withOpacity(snapshot.data  == entry.key ? 1.0 : 0.4)),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  )
                                                ],
                                              );
                                            }),
                                      ],
                                    )
                                  /// imageUrlList 데이터가 없으면 사진란 아예 없앰
                                  else
                                    Container(
                                      height: 50,
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                ],
                              );
                            }
                          },
                        ),
                        AppBar(
                          foregroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          backgroundColor: Colors.transparent,
                          leading: IconButton(
                            color: appbarIconColor? Color(0xffeeeeee) : Colors.black,
                            iconSize: 35,
                            icon: Icon(
                              Icons.arrow_back,
                              semanticLabel: 'back',
                            ),
                            onPressed: () {
                              // add FAB누르고 detail로 넘어갔을 때 뒤로가기 하면 FAB가 누른 그대로 있어서 pop에서 이렇게 바꿈
                              Navigator.pushAndRemoveUntil<dynamic>(
                                context,
                                MaterialPageRoute<dynamic>(builder: (context) => HomePage(),),
                                    (Route<dynamic> route) => false,
                              );
                              //Navigator.pop(context);
                            },
                          ),
                          actions: <Widget>[
                            if (FirebaseAuth.instance.currentUser.uid == product.uid)
                              IconButton(
                                  iconSize: 30,
                                  icon: Icon(
                                    Icons.create,
                                    semanticLabel: 'edit',
                                    color: Color(0xffeeeeee),
                                  ),
                                  onPressed:
                                  (FirebaseAuth.instance.currentUser.uid == product.uid)
                                      ? () => Navigator.pushNamed(
                                    context,
                                    '/edit/' + productId + '/' + detailGiveOrTake,
                                  )
                                      : null),
                            if (FirebaseAuth.instance.currentUser.uid == product.uid)
                              IconButton(
                                  color: Color(0xffeeeeee),
                                  iconSize: 30,
                                  icon: Icon(
                                    Icons.delete,
                                    semanticLabel: 'delete',
                                  ),
                                  onPressed: (FirebaseAuth.instance.currentUser.uid ==
                                      product.uid)
                                      ? () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) => CupertinoAlertDialog(
                                        title: Text('게시글 삭제'),
                                        content: Text(
                                            '정말 이 게시글을 삭제하시겠습니까?'),
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
                                                        .then((value) => appState.init())
                                                        .catchError((error) => null)
                                                        .whenComplete(
                                                            () => Navigator.pop(context));
                                                  },
                                                  child: Text('네'),
                                                ),
                                          )
                                        ],
                                      ))
                                      : null)
                          ],
                        ),
                      ],
                    ),
                    /// 사진 밑의 게시글 내용들
                    Row(
                      children: [
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20.0),
                                /// 게시자 사진, 이름 , 시간
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// 게시자 사진
                                    SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Image.asset('assets/userDefaultImage.png'),
                                    ),
                                    SizedBox(width: 10.0),
                                    SizedBox(
                                      height: 42,
                                      child:
                                      /// 이름과 시간
                                          StreamBuilder<QuerySnapshot>(
                                              stream: users.snapshots(),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                                if (snapshot.hasError) {
                                                  return Text('x');
                                                }
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Text('');
                                                }
                                                return Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 2,),
                                                    /// 이름
                                                    SizedBox(
                                                      //width: 10,
                                                      height: 18,
                                                      child: Text(
                                                        ' ${findNickname(snapshot, product.userName)}\n',
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto_Bold',
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      //width: 10,
                                                      height: 22,
                                                      child: TextButton(
                                                        style: TextButton.styleFrom(
                                                          padding: EdgeInsets.zero,
                                                          alignment: Alignment.centerLeft,
                                                          primary: Colors.grey,
                                                          backgroundColor: Colors.transparent,
                                                          textStyle: TextStyle(
                                                            fontFamily: 'Roboto_Bold',
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12.5,
                                                            height: 1.2,
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => Chat(
                                                                peerId: product.uid,
                                                                peerAvatar: FirebaseAuth.instance.currentUser.photoURL,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          children: [
                                                            Text(' 채팅하기',
                                                              textAlign: TextAlign.left,
                                                            ),
                                                            Icon(Icons.chat, size: 13.5,),
                                                          ],
                                                        )
                                                      ),
                                                    )
                                                  ]
                                                );
                                              }
                                          ),

                                    ),
                                    /// 채팅으로 넘어가는 버튼
                                    /*IconButton(
                                        onPressed: (){
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Chat(
                                                peerId: product.uid,
                                                peerAvatar: FirebaseAuth.instance.currentUser.photoURL,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.chat)
                                    ),*/
                                  ],
                                ),
                                SizedBox(height: 9.0),
                                Divider(thickness: 1.0),
                                SizedBox(height: 9.0),
                                Row(
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                          style: TextStyle(
                                            fontFamily: 'Roboto_Black',
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: '${product.title}\n',
                                              style: TextStyle(
                                                fontFamily: 'Roboto_Bold',
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                height: 1,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '${product.category} · ${calculateTime()}\n\n',
                                              style: TextStyle(
                                                fontFamily: 'Roboto_Bold',
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                height: 1.6,
                                              ),
                                            ),
                                          ]
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                  ],
                                ),
                                /// 게시글 내용
                                Text(
                                  product.content ?? product.content,
                                  style: TextStyle(
                                    fontFamily: 'Roboto_Bold',
                                    color: Colors.black,
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
                                        return Text('x',style: TextStyle(fontSize: 13, height: 1,));
                                      }
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Text('',style: TextStyle(fontSize: 13, height: 1,));
                                      }
                                      var count = snapshot.data.size;
                                        return StreamBuilder<int>(
                                            stream: changeLikeCount.stream.asBroadcastStream(),
                                            initialData: count,
                                            builder: (context, snapshot2) {
                                              return Text(
                                                '\n\n조회 ${product.hits}회 · 좋아요 ${snapshot2.data}회',
                                                style: TextStyle(
                                                  fontFamily: 'Roboto_Bold',
                                                  color: Colors.grey,
                                                  //fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  height: 1,
                                                ),
                                              );
                                            }
                                        );
                                    },
                                ),
                                SizedBox(height: 9.0),
                                Divider(thickness: 1.0),
                              ]),
                        ),
                        SizedBox(width: 20),
                      ],///
                    ),
                    /// 게시물 내용 아래 댓글들
                    Container(
                        padding: const EdgeInsets.all(8.0),
                        child: CommentBook(
                          detailGiveOrTake: detailGiveOrTake,
                          productId: productId,
                        )
                    ),
                    // 고정된 댓글 창과 겹치지 않게하는 sizedbox
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.038,
                    )
                  ]
              ),
              /// 고정된 댓글 창 위젯
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.057,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xffe5e5e5),
                        boxShadow: [
                          BoxShadow(color: Color(0xffe5e5e5), spreadRadius: 2),
                        ],
                      ),
                      margin: EdgeInsets.fromLTRB(7.0, 7.0, 7.0, 0.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            child: StreamBuilder<QuerySnapshot>(
                                stream: likes.snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('x');
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text('');
                                  }
                                  return StreamBuilder <Icon> (
                                      stream: changeFavoriteButton.stream,
                                      initialData: isLiked(snapshot)
                                          ? Icon(Icons.favorite,
                                        color: Colors.red,
                                        semanticLabel: 'like',
                                      )
                                          : Icon(Icons.favorite_border_outlined,
                                        color: Colors.red,
                                        semanticLabel: 'like',
                                      ),
                                      builder: (context, snapshot2) {
                                        /// changeFavoriteButton 스트림 컨트롤러에 새 데이터가 들어올때마다 부분적으로 빌드됨
                                        return IconButton(
                                          /// 아이콘의 snapshot2 => changeFavoriteButton 스트림으로 건네준 아이콘
                                            icon: snapshot2.data,
                                            onPressed: () async {
                                              /// 이미 좋아요가 눌러져 있었을 떄
                                              if(isLiked(snapshot)) {
                                                await deleteLike(userId)
                                                    .catchError((error) => null)
                                                    .whenComplete(() {
                                                  products = detailGiveOrTake == 'giveProducts'
                                                      ? context.read<ApplicationState>().giveProducts
                                                      : context.read<ApplicationState>().takeProducts;
                                                  changeFavoriteButton.add(Icon(Icons.favorite_border_outlined,
                                                    color: Colors.red, semanticLabel: 'like',));
                                                  changeLikeCount.add(context.read<ApplicationState>().likeCount);
                                                });
                                              }
                                              /// 좋아요가 눌러져 있지 않을 때
                                              else {
                                                await addLike()
                                                    .catchError((error) => null)
                                                    .whenComplete(() {
                                                  products = detailGiveOrTake == 'giveProducts'
                                                      ? context.read<ApplicationState>().giveProducts
                                                      : context.read<ApplicationState>().takeProducts;
                                                  changeFavoriteButton.add(Icon(Icons.favorite,
                                                    color: Colors.red, semanticLabel: 'like',));
                                                  changeLikeCount.add(context.read<ApplicationState>().likeCount);
                                                });
                                              }
                                            }
                                        );
                                      }
                                  );
                                }),
                          ),
                          Form(
                            key: _commentFormKey,
                            child: Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 1, 10, 5),
                                  child: TextFormField(
                                    controller: _commentController,
                                    decoration: const InputDecoration(
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      hintText: '댓글을 입력하세요',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '댓글을 입력하세요';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                            ),
                          ),
                          SizedBox(width: 3),
                          IconButton(
                            icon: const Icon(Icons.send_outlined),
                            iconSize: 27,
                            color: Color(0xffc32323),
                            onPressed: () async {
                              var currentFocus = FocusScope.of(context);
                              currentFocus.unfocus();
                                if (_commentFormKey.currentState.validate()) {
                                  await addComments(_commentController.text)
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
                ),
              ),
            ],
          )
      ),
    );
  }
}

