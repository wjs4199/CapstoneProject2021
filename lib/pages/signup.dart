import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home.dart';




final _formKey = GlobalKey<FormState>();
TextEditingController textEditingController1 = TextEditingController();

class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {

  CollectionReference users =
  FirebaseFirestore.instance.collection('users');




  @override
  Widget build(BuildContext context) {


    return Material(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  controller: textEditingController1,
                  decoration: InputDecoration(
                    hintText: ("UserName"),
                    fillColor: Colors.white30,
                    filled: true,
                  ),
                ),
              ),


              Divider(
                color: Colors.white,
                height: 20,
              ),

              Padding(
                padding: const EdgeInsets.only(top: 24.0, right: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        print("click actionbutton");

                        await FirebaseFirestore.instance.collection('users')
                            .doc(FirebaseAuth.instance.currentUser.uid)
                            .set({

                          'username': FirebaseAuth.instance.currentUser.displayName,
                          'photoUrl': FirebaseAuth.instance.currentUser.photoURL,
                          'id': FirebaseAuth.instance.currentUser.uid,
                          'createdAt': DateTime
                              .now()
                              .millisecondsSinceEpoch
                              .toString(),
                          'nickname': textEditingController1.text,

                        }).then((value) async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()));
                        }).catchError((error) => print('Error: $error'));



                      },
                      style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                      child: Text(
                        '시작하기',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



