import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giveandtake/pages/login.dart';
import 'package:giveandtake/pages/signup.dart';

import '../../main.dart';
import '3_msg_view.dart';

/// 프로필 사진 url retrieve 용
String photoUrl = FirebaseAuth.instance.currentUser.photoURL;
// String highResUrl = photoUrl.replaceAll('s96-c', 's400-c'); // 고해상도

bool isLoading = false;

///handleSignout 변수

Widget MyView(BuildContext context, ApplicationState appState) {
  ///logout
  Future<Null> handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false);
  }

  return CustomScrollView(
    slivers: <Widget>[
      // SliverAppBar(
      //   title: Text(
      //     'My',
      //     style: TextStyle(
      //       fontSize: 18,
      //       fontFamily: 'NanumSquareRoundR',
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      //   backgroundColor: Color(0xfffc7174),
      //   pinned: true,
      //   snap: false,
      //   floating: true,
      //   // expandedHeight: 140.0,
      //   // flexibleSpace: const FlexibleSpaceBar(
      //   //   background: FlutterLogo(),
      //   // ),
      //   actions: <Widget>[
      //     IconButton(
      //       icon: Icon(
      //         Icons.logout,
      //         //semanticLabel: 'location',
      //       ),
      //       onPressed: () {
      //         handleSignOut();
      //       },
      //     ),
      //   ],
      // ),
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
                      NetworkImage(FirebaseAuth.instance.currentUser.photoURL),
                ),
                SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FirebaseAuth.instance.currentUser.displayName,
                        style: TextStyle(
                          fontFamily: 'NanumBarunGothic',
                          fontSize: 25.0,
                          color: Colors.black87,
                          // fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUp()));
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 20,
                        ),
                      )
                    ],
                  ),
                ),
                Text(
                  'HANDONG GLOBAL UNIVERSITY',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xfffc7174),
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
                    color: Color(0xfffc7174),
                  ),
                ),
                Card(
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
                  child: ListTile(
                    leading: Icon(
                      Icons.phone,
                      color: Color(0xfffc7174),
                    ),
                    title: Text(
                      '+82 10 9865 7165',
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.black,
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
                      color: Color(0xfffc7174),
                    ),
                    title: Text(
                      'Pohang, Replublic of Korea',
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.black,
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
