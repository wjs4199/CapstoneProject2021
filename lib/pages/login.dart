import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:giveandtake/model/user_chat.dart';
import 'package:giveandtake/pages/home.dart';
import 'package:giveandtake/pages/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;
  bool isLoading = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    isSignedIn();
    ///자동로그인 호출
  }

  void isSignedIn() async {
    setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && prefs?.getString('id') != null) {
       await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                HomePage(currentUserId: prefs)),
      );
    }

    setState(() {
      isLoading = false;
    });
  }



  Future<Null> handleSignIn() async {
    var googleUser = await googleSignIn.signIn();
    var googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    var firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (googleUser != null) {
      var googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (firebaseUser != null) {
        /// Check is already sign up
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: firebaseUser.uid)
            .get();
        final List<DocumentSnapshot> documents = result.docs;
        if (documents.isEmpty) {
          /// Update data to firestore if new user

          // Write data to local
          // currentUser = firebaseUser;
          await prefs.setString('id', firebaseUser.uid);
          await prefs.setString('username', firebaseUser.displayName);
          await prefs.setString('photoUrl', firebaseUser.photoURL);

          await Navigator.push(
              context, MaterialPageRoute(builder: (context) => SignUp()));
        } else {
          var documentSnapshot = documents[0];
          var userChat = UserChat.fromDocument(documentSnapshot);
          // Write data to local
          await prefs.setString('id', userChat.id);
          await prefs.setString('username', userChat.nickname);
          await prefs.setString('photoUrl', userChat.photoUrl);
          await prefs.setString('aboutMe', userChat.aboutMe);
        }
        await Fluttertoast.showToast(msg: 'Sign in success');
        setState(() {
          isLoading = false;
        });

         await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomePage(currentUserId: prefs)));
      } else {
        await Fluttertoast.showToast(msg: 'Sign in fail');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      await Fluttertoast.showToast(msg: 'Can not init google sign in');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
/*
      final snackBar = SnackBar(
        content: const Text('한동 구글 계정으로 로그인 해야 합니다'),
        action: SnackBarAction(
          label: 'dismiss',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );


 */
//ScaffoldMessenger.of(context).showSnackBar(snackBar);

    void _showDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_alert, color: Colors.amberAccent),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text('주의사항'),
                ),
              ],
            ),
            content: SingleChildScrollView(
                child: Text('반드시 한동대학교 구글 계정으로 로그인하셔야 합니다!')),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await handleSignIn();
                },
                child: Text('한동 구글 계정으로 로그인하기'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            SizedBox(height: 250.0),
            Column(
              children: <Widget>[
                Container(
                    height: 50,
                    child: Image.asset('assets/hgu.png', fit: BoxFit.fill)),
                Text('MAD Final Project'),
              ],
            ),
            SizedBox(height: 140.0),
            SizedBox(
              height: 50.0,
              child: ElevatedButton.icon(
                label: Text('앱 시작하기'),
                icon: Icon(Icons.android),
                onPressed: () async {
                  // Sign in with Google account,
                  // Traditional style (then, catchError) used here
                  // ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  _showDialog();

                  //await handleSignIn();
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xfffc7174),
                  onPrimary: Colors.white,
                  shadowColor: Colors.black,
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///banner 사용법 (snackbar 와 달리, banner 는 dismiss 버튼을 눌러야 사라진다.
///필독 사항이 있을 때 사용하면 좋을 것 같다
///flutter 2.5 버전부터 사용 가능
/*
  Center(
          child: ElevatedButton(
            child: const Text('Show MaterialBanner'),
            onPressed: () => ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: const Text('Hello, I am a Material Banner'),
                leading: const Icon(Icons.info),
                backgroundColor: Colors.yellow,
                actions: [
                  TextButton(
                    child: const Text('Dismiss'),
                    onPressed: () => ScaffoldMessenger.of(context)
                        .hideCurrentMaterialBanner(),
                  ),
                ],
              ),
            ),
          ),
        ),
   */