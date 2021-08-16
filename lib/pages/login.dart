import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:giveandtake/pages/signup.dart';
//import 'package:google_sign_in/google_sign_in.dart';
/*
// For Google Sign in
Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final googleUser = await GoogleSignIn().signIn();
  // Obtain the auth details from the request
  final googleAuth = await googleUser.authentication;
  // Create a new credential
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

 */

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
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
                label: Text('Sign in with Google'),
                icon: Icon(Icons.android),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUp()
                    )
                  );

                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.cyan,
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





