import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:giveandtake/model/product.dart';
import 'package:giveandtake/pages/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../main.dart';

import 'home.dart';

class LoginPage extends StatefulWidget {


  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  @override
  Widget build(BuildContext context)  {


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
                onPressed: ()   async {
                  // Sign in with Google account,
                  // Traditional style (then, catchError) used here
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SignUp()));


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

