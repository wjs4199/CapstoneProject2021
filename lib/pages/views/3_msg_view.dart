import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:giveandtake/components/loading.dart';
import 'package:giveandtake/model/const.dart';
import 'package:giveandtake/model/user_chat.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../main.dart';
import '../chat.dart';

final String currentUserId = FirebaseAuth.instance.currentUser.uid;
final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GoogleSignIn googleSignIn = GoogleSignIn();
final ScrollController listScrollController = ScrollController();

bool isLoading = false;
int _limit = 20;

Widget MsgView(BuildContext context, ApplicationState appState) {
  return CustomScrollView(
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
        backgroundColor: Color(0xfffc7174),
        pinned: true,
        snap: false,
        floating: true,
        // expandedHeight: 140.0,
        // flexibleSpace: const FlexibleSpaceBar(
        //   background: FlutterLogo(),
        // ),
        // actions: <Widget>[
        //   IconButton(
        //     icon: Icon(
        //       Icons.location_on,
        //       semanticLabel: 'location',
        //     ),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      SliverList(
        delegate: SliverChildListDelegate(
          [
            ///added
            Stack(
                children: <Widget>[
                  // List
                  ///chatting list 를 보여주는 container
                  Container(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .limit(_limit)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          return ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.all(10.0),

                            /// data 를 가져오는 곳 buildItem 위젯
                            itemBuilder: (context, index) =>
                                buildItem(context, snapshot.data.docs[index]),
                            itemCount: snapshot.data.docs.length,
                            controller: listScrollController,
                          );
                        } else {
                          /// data 가 없을 시
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
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
          ],
        ),
      )
    ],
  );
}

///
Widget buildItem(BuildContext context, DocumentSnapshot document) {
  if (document != null) {
    var userChat = UserChat.fromDocument(document);
    if (userChat.id == currentUserId) {
      return SizedBox.shrink();
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),

        /// 메신저 탭에서 각각 사용자들 list 를 클릭할 수 있게 만들어 놓은 text button
        child: TextButton(
          /// 각 사용자들의 list 를 누르면 채팅창으로 넘어간다
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

          ///위 text button 에 대한 style
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(greyColor2),
            shape: MaterialStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),

          /// 각 사용자에 대한 list 를 만드는 row
          child: Row(
            children: <Widget>[
              Material(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
                child: userChat.photoUrl.isNotEmpty

                    /// empty 가 아니면 photoURL 을 가져온다
                    ? Image.network(
                        userChat.photoUrl,
                        fit: BoxFit.cover,
                        width: 50.0,
                        height: 50.0,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes
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
                ///nickname 을 가져오는 container
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
                      /*
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        child: Text(
                          'About me: ${userChat.aboutMe}',
                          maxLines: 1,
                          style: TextStyle(color: primaryColor),
                        ),
                      )

                     */
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

/*

@override
void initState() {
  //super.initState();
  registerNotification();
  configLocalNotification();
  listScrollController.addListener(scrollListener);

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

void showNotification(RemoteNotification remoteNotification) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Platform.isAndroid ? 'com.dfa.flutterchatdemo' : 'com.duytq.flutterchatdemo',
    'Flutter chat demo',
    'your channel description',
    playSound: true,
    enableVibration: true,
    importance: Importance.max,
    priority: Priority.high,
  );
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics =
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

void configLocalNotification() {
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings =
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
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: Icon(
                      Icons.exit_to_app,
                      size: 30.0,
                      color: Colors.white,
                    ),
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
                    margin: EdgeInsets.only(right: 10.0),
                    child: Icon(
                      Icons.cancel,
                      color: primaryColor,
                    ),
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
                    margin: EdgeInsets.only(right: 10.0),
                    child: Icon(
                      Icons.check_circle,
                      color: primaryColor,
                    ),
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

 */
