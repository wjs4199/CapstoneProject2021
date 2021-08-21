import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giveandtake/pages/login.dart';

import '../../main.dart';
import '3_msg_view.dart';

/// 프로필 사진 url retrieve 용
String photoUrl = FirebaseAuth.instance.currentUser.photoURL;
// String highResUrl = photoUrl.replaceAll('s96-c', 's400-c'); // 고해상도

bool isLoading = false; ///handleSignout 변수

Widget MyView(BuildContext context, ApplicationState appState) {

  Future<Null> handleSignOut() async {
    /*
  setState(() {
    isLoading = true;
  });

  */
    ///
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
/*
  setState(() {
    isLoading = false;
  });

 */

    await Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginPage()), (Route<dynamic> route) => false);
  }

  return CustomScrollView(
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
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
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
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
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
  );
}
