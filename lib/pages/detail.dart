import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giveandtake/pages/chat.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:intl/intl.dart';

import '../model/product.dart';
import '../main.dart';
import '../pages/comment.dart';

class DetailPage extends StatefulWidget {
  DetailPage({this.productId, this.detailGiveOrTake});

  /// route 생성 시에 사용되는 product ID
  final String productId;

  /// giveProducts / takeProducts collection 중 어디서 가져와야하는 지 표시
  final String detailGiveOrTake;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  /// 프로필 사진 url retrieve 용
  String photoUrl = FirebaseAuth.instance.currentUser.photoURL;

  var appbarIconColor = true;

  void appbarColor(bool ImageExist) {
    setState(() {
      if (ImageExist) {
        appbarIconColor = true;
      } else {
        appbarIconColor = false;
      }
    });
  }

  /// comment 적는 텍스트 칸이 빈칸인지 아닌지 분별할 때 사용됨
  final _commentFormKey = GlobalKey<FormState>(debugLabel: '_CommentState');

  /// comment 를 적는 텍스트 상자의 상태를 control 할 때 사용
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ///******* ProductID와 맞는 게시물 내용을 Firebase 에서 찾아내는 부분 *******///
    /// DetailPage() 호출시 받는 매개변수 참조
    var productId = widget.productId;
    var detailGiveOrTake = widget.detailGiveOrTake;

    /// detailGiveOrTake 가 담고 있는 collection 이름에 따라 그 collection 담긴 내용 가져오기
    var products = detailGiveOrTake == 'giveProducts'
        ? context.watch<ApplicationState>().giveProducts
        : context.watch<ApplicationState>().takeProducts;

    /// 현재 유저의 아이디와 이름 간략화
    var userId = FirebaseAuth.instance.currentUser.uid;
    var userName = FirebaseAuth.instance.currentUser.displayName;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈을 때 그 내용을 담을 변수
    Product product;

    /// 컬랙션(products) 내에서 productId가 같은 제품을 찾아냈는지 여부 표시 (찾아냈을 때 true)
    var productFound = false;

    /// products에 담긴 것들 중 현재 productId와 같은 것 찾기
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

    /// Firebase Storage 참조 간략화
    var storage = firebase_storage.FirebaseStorage.instance;

    /// ProductID에 따라 해당하는 image url 다운로드
    Future<String> downloadURL(String id) async {
      try {
        return await storage
            .ref()
            .child('images')
            .child('$id.png')
            .getDownloadURL();
      } on Exception {
        return null;
      }
    }

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

    ///************************ like 기능 구현부분 (수정필요) ************************///
    /// giveProducts 또는 takeProducts 중 어디에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference likes;
    if (detailGiveOrTake == 'giveProducts') {
      likes = FirebaseFirestore.instance
          .collection('giveProducts/' + productId + '/like');
    } else {
      likes = FirebaseFirestore.instance
          .collection('takeProducts/' + productId + '/like');
    }

    /// 현재는 하트버튼 누르면 사용자가 이미 눌렀든 말든 간에 계속 숫자 올라감 ㅋㅎ (수정필요)
    /// 현재 사용자가 이미 좋아요를 누른 경우를 분별하는 함수
    bool isLiked(AsyncSnapshot<QuerySnapshot> snapshot) {
      snapshot.data.docs.forEach((document) {
        if (document['uid'] == userId) {
          return true;
        }
      });
      return false;
    }

    /// 사용자가 하트 누른 경우 좋아요 추가하는 기능
    Future<void> addLike() {
      return likes
          .add({'uid': userId})
          .then((value) => print('LIKED!'))
          .catchError((error) => print('Failed to add a like: $error'));
    }

    /// 좋아요 취소기능 (구현이 안됨 -> 다시 짜기)
    /* Future<void> deleteLike() async {
       try {
         return likes.doc(userId).delete();
       } on Exception {
         return null;
       }
     }*/

    /// 현재시간 - 게시글 마지막 수정 시간 계산하여 내보내는 위젯
    String calculateTime() {
      var time = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .difference(DateTime(product.modified.toDate().year,
          product.modified.toDate().month, product.modified.toDate().day))
          .inDays;

      /// 하루가 안지났을 때
      if (time < 1) {
        time = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .difference(DateTime(product.modified.toDate().year,
            product.modified.toDate().month, product.modified.toDate().day))
            .inHours;

        /// 한시간도 안지났을 때
        if (time < 1) {
          time = DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day)
              .difference(DateTime(
              product.modified.toDate().year,
              product.modified.toDate().month,
              product.modified.toDate().day))
              .inMinutes;

          /// 1분도 안지났을 때
          if (time < 1) {
            time = DateTime(DateTime.now().year, DateTime.now().month,
                DateTime.now().day)
                .difference(DateTime(
                product.modified.toDate().year,
                product.modified.toDate().month,
                product.modified.toDate().day))
                .inSeconds;
            return '$time초 전';
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
        time = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .difference(DateTime(product.modified.toDate().year,
            product.modified.toDate().month, product.modified.toDate().day))
            .inDays;
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
        time = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .difference(DateTime(product.modified.toDate().year,
            product.modified.toDate().month, product.modified.toDate().day))
            .inDays;
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
    }

    /// 'comments' Collection 참조
    /// editted
    CollectionReference comments = FirebaseFirestore.instance
        .collection('giveProducts/' + productId + '/comment');

    /// comment 추가 기능
    Future<void> addComments(String comment) {
      return comments
          .add({
        'userName': FirebaseAuth.instance.currentUser.displayName,
        'comment': comment,
        'created': FieldValue.serverTimestamp(),

        ///editted
      })
          .then((value) => print('add comment!'))
          .catchError((error) => print('Failed to add a comment: $error'));
    }

    /// Add 페이지 화면 구성
    return Scaffold(
      body: SafeArea(
          child: Stack(
            children: [
              ListView(children: [
                Stack(
                  children: [
                    Consumer<ApplicationState>(
                      builder: (context, appState, _) => FutureBuilder(
                        future: downloadURL(productId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              children: [
                                SizedBox(height: 50),
                                Center(child: CircularProgressIndicator()),
                                SizedBox(height: 48),
                              ],
                            );
                          } else {
                            if (snapshot.hasData) {
                              appbarIconColor = true;
                              return Stack(
                                children: [
                                  Container(
                                    height:
                                    MediaQuery.of(context).size.height * 0.5,
                                    width: MediaQuery.of(context).size.width,
                                    color: Color(0xffced3d0),
                                  ),
                                  Container(
                                      height:
                                      MediaQuery.of(context).size.height * 0.5,
                                      width: MediaQuery.of(context).size.width,
                                      child: Image.network(snapshot.data.toString(),
                                          fit: BoxFit.fitWidth))
                                ],
                              );
                            } else if (snapshot.hasData == false) {
                              return Container(
                                height: 35,
                              );
                            } else {
                              return Container(
                                child: Text('Snapshot Error!'),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    AppBar(
                      foregroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        color: appbarIconColor ? Color(0xffeeeeee) : Colors.black,
                        iconSize: 35,
                        icon: Icon(
                          Icons.arrow_back,
                          semanticLabel: 'back',
                        ),
                        onPressed: () {
                          Navigator.pop(context);
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
                                                        .whenComplete(() =>
                                                        Navigator.pop(context));
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
                                CircleAvatar(
                                  radius: 21.0,
                                  backgroundImage: NetworkImage(photoUrl),
                                ),

                                SizedBox(width: 10.0),
                                SizedBox(
                                  height: 40,
                                  child:

                                  /// 이름과 시간
                                  RichText(
                                    text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Roboto_Black',
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: '${product.userName}\n',
                                            style: TextStyle(
                                              fontFamily: 'Roboto_Bold',
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              height: 1,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${calculateTime()}',
                                            style: TextStyle(
                                              fontFamily: 'Roboto_Bold',
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              height: 1.55,
                                            ),
                                          )
                                        ]),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      print('IconButton clicked');

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Chat(
                                            peerId: product.userName,
                                            //peerAvatar: product.photoUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.chat)),
                              ],

                              ///
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
                                          text:
                                          '${product.category} · ${calculateTime()}\n\n',
                                          style: TextStyle(
                                            fontFamily: 'Roboto_Bold',
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            height: 1.6,
                                          ),
                                        ),
                                      ]),
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
                              stream: likes.snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error!');
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading');
                                }
                                var count = snapshot.data.size;
                                return Text(
                                  '\n\n조회 5회 · 좋아요 $count회',
                                  style: TextStyle(
                                    fontFamily: 'Roboto_Bold',
                                    color: Colors.grey,
                                    //fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    height: 1,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 9.0),
                            Divider(thickness: 1.0),
                          ]),
                    ),
                    SizedBox(width: 20),
                  ],

                  ///
                ),

                /// 게시물 내용 아래 댓글들
                Container(
                    padding: const EdgeInsets.all(8.0),
                    child: CommentBook(
                      detailGiveOrTake: detailGiveOrTake,
                      productId: productId,
                    ))
              ]),

              /// 고정된 댓글 창
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
                      child: Form(
                        key: _commentFormKey,
                        child: Row(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: likes.snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error!');
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading');
                                }
                                return IconButton(
                                  icon: Icon(
                                    (isLiked(snapshot))
                                        ? Icons.favorite
                                        : Icons.favorite_outlined,
                                    color: Color(0xfffc7174),
                                    semanticLabel: 'like',
                                  ),
                                  onPressed: () => (isLiked(snapshot))
                                      ? print('You can only like once!')
                                      : addLike(),
                                );
                              },
                            ),
                            Expanded(
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
                                )),
                            SizedBox(width: 3),
                            IconButton(
                              icon: const Icon(Icons.send_outlined),
                              iconSize: 27,
                              color: Color(0xfffc7174),
                              onPressed: () async {
                                var currentFocus = FocusScope.of(context);
                                currentFocus.unfocus();
                                setState(() {
                                  if (_commentFormKey.currentState.validate()) {
                                    addComments(_commentController.text)
                                        .then((value) => print('add comment ok!'));
                                    _commentController.clear();
                                    Provider.of<ApplicationState>(context,
                                        listen: false)
                                        .detailPageUid(widget.productId,
                                        widget.detailGiveOrTake);
                                    print('clear!');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}