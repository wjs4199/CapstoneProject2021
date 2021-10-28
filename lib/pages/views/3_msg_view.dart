import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:giveandtake/components/loading.dart';
import 'package:giveandtake/model/const.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../chat.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final ScrollController listScrollController = ScrollController();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool isLoading = false;
int _limit = 20;
var _flutterLocalNotificationsPlugin;
var _messageState = false;


Future<void> _cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}


Future _showNotification() async {
  var android = AndroidNotificationDetails(
      'your channel id', 'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high);

  var ios = IOSNotificationDetails();
  var detail = NotificationDetails(android: android, iOS: ios);

  await _flutterLocalNotificationsPlugin.show(
    0,
    '새로운 메시지가 도착했습니다',
    '메신저 텝을 눌러주세요',
    detail,
    payload: 'Hello Flutter',
  );
}

class MessagePage extends StatefulWidget {
  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    //ios 알림 설정 : 소리, 뱃지 등
    var initializationSettingsIOS = IOSInitializationSettings();

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //onSelectNotification의 경우 알림을 눌렀을때 어플에서 실행되는 행동을 설정
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    print('payload : $payload');
/*
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Well done'),
          content: Text('Payload: $payload'),
        ));
        //.then((value) => _cancelAllNotifications());


 */

  // await Navigator.pushNamed(context, '/message');
    /*
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(),
      ),
    );

     */


  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          ///chatting list 를 보여주는 container
          Container(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRoom')
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
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {

    if (document != null && document.id.contains(FirebaseAuth.instance.currentUser.uid)) {
        if (document.get('idFrom') == FirebaseAuth.instance.currentUser.uid)
          ///내가 보내는 입장이면
        {

          return _buildSenderScreen(context, document);
        } else {

          if(_messageState == false) {
            _showNotification();
          }
          // print(_messageState);
          _messageState = true;
          // print(_messageState);

          return _buildReceiverScreen(context, document);
        }
    } else {
      return SizedBox.shrink();
    }
  }




  Container _buildSenderScreen(BuildContext context, DocumentSnapshot document) {

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
                peerId: document.get('idTo'),
                peerAvatar: document.get('peerAvatar'),
                peerName: document.get('peerNickname'),
                myName: document.get('myNickname'),
                myAvatar: document.get('myAvatar'),
                // peerName: userChat.nickname,
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
              child: document.get('peerAvatar').isNotEmpty

              /// empty 가 아니면 photoURL 을 가져온다
                  ? Image.network(
                document.get('peerAvatar'),
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
                        value: loadingProgress.expectedTotalBytes != null &&
                            loadingProgress.expectedTotalBytes != null
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
                        '${document.get('peerNickname')}',
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

  Container _buildReceiverScreen(
      BuildContext context, DocumentSnapshot document) {
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
                peerId: document.get('idFrom'),
                peerAvatar: document.get('myAvatar'),
                peerName: document.get('myNickname'),
                myName: document.get('peerNickname'),
                myAvatar: document.get('peerAvatar'),
                // peerName: userChat.nickname,
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
              child: document.get('myAvatar').isNotEmpty

              /// empty 가 아니면 photoURL 을 가져온다
                  ? Image.network(
                document.get('myAvatar'),
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
                        value: loadingProgress.expectedTotalBytes != null &&
                            loadingProgress.expectedTotalBytes != null
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
                        '${document.get('myNickname')}',
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
            Icon(
              Icons.add_alert,
              color: Colors.deepOrangeAccent,
            ),
          ],
        ),
      ),
    );
  }





}
/*
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
                        .collection('chatRoom')
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


 */


///* —————————————————————————————————— *///
