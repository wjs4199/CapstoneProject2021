import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home.dart';




final _formKey = GlobalKey<FormState>();

void main() => runApp(SignUp1());

class SignUp1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignUp(),
    );
  }
}

class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  TextEditingController textEditingController1 = TextEditingController();



  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser.uid;
    final email =  FirebaseAuth.instance.currentUser.email;
    CollectionReference signup = FirebaseFirestore.instance.collection("UserName");


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
                    hintText: ("Username"),
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

                        ///editted
                        /// DB 추가 부분
                          if (_formKey.currentState.validate()) {
                            // If the form is valid, display a snackbar. In the real world,
                            // you'd often call a server or save the information in a database.

                            await signup.add(
                                {
                                  'uid': uid,
                                  'email': email,
                                  'username': textEditingController1.text.toString(),
                                  'created': FieldValue.serverTimestamp(),
                                }
                            ).then((value) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Welcome' + ' ' + textEditingController1.text.toString(),

                                    ))),
                            ).catchError((error) => print('Failed to signup: $error') );



                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          }


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

/*
    Future <void> createUser (String uid, String email, String username){


      FirebaseFirestore.instance.collection("UserName")
          .add(
          {
            uid: uid,
            email: email,
            username: username,
          }
      );

    }

 */


