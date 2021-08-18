import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giveandtake/model/product.dart';
import 'package:giveandtake/pages/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

///수정필요
/*
  CollectionReference signup = FirebaseFirestore.instance.collection("UserName");



  Future<void> getData() async {
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await signup.get();

    // Get data from docs and convert map to List
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();

    print(allData);
  }
  var products = context.watch<ApplicationState>().UserName;
  UserName product;
  bool productFound = false;

 */



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
                  // Sign in with Google account,
                  // Traditional style (then, catchError) used here
                  signInWithGoogle().then((value) {
                    print('User: ' + value.user.displayName);
                    // Display User Info with SnackBar
                    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    //   content: Text('Welcome, ' + value.user.displayName + '!'),
                    //   behavior: SnackBarBehavior.fixed,
                    //   duration: Duration(seconds: 1),
                    // ));

///수정필요
/*
                    Future<void> future = getData();

                    for (var i = 0; i < product.length; i++) {
                      if (product[i].id == productId) {
                        product = products[i];
                        productFound = true;

                        print(product.username);
                        print(product.uid);
                      }
                    }


 */


                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SignUp()));
                  }).catchError((error) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            CupertinoAlertDialog(
                              title: Text("Login Failed"),
                              content: Text(
                                  "You must complete your\nGoogle sign in procedures."),
                              actions: <Widget>[
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Dismiss"),
                                ),
                              ],
                            ));
                    print('error: $error');
                  });
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