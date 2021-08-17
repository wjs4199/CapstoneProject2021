import 'package:cloud_firestore/cloud_firestore.dart';
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
                      onPressed: () {
                        print("click actionbutton");


                        /// DB 추가 부분
                        if (_formKey.currentState.validate()) {

                         // CollectionReference username = FirebaseFirestore.instance.collection("UserName");

                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Processed Data')));
                     /*
                          username.add(
                       {
                       //  uid:  FirebaseAuth.instance.currentUser.uid,
                       //      email:  FirebaseAuth.instance.currentUser.email,
                      // username: textEditingController1.text.toString()
                       }
                     );

                      */


                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()));
                        }
                      },
                      child: Text(
                        '시작하기',
                      ),
                      style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
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
Future<void> addUser(String comment) {
  return comments
      .add({
    'userName': FirebaseAuth.instance.currentUser.displayName,
    'comment': comment,
    'created': FieldValue.serverTimestamp(), ///editted
  })
      .then((value) => print('add user!'))
      .catchError((error) => print('Failed to add an user: $error'));
}
*/