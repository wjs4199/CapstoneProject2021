import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home.dart';


TextEditingController textEditingController1 = TextEditingController();


class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {

  final _formKey = GlobalKey<FormState>();

  CollectionReference users =
  FirebaseFirestore.instance.collection('users');


  @override
  Widget build(BuildContext context) {
    var isDuplicated = false;
    var checkLoop = false;
    var name = '';

    var currentUserId = FirebaseAuth.instance.currentUser.uid;

    final snackBar1 = SnackBar(content: Text('중복이 존재합니다'));
    final snackBar2 = SnackBar(content: Text('사용해도 좋습니다'));
    final snackBar3 = SnackBar(content: Text('중복체크를 해주세요'));

    _currentNickname() async {
      await FirebaseFirestore.instance.collection('users').doc(currentUserId)
          .get()
          .then((DocumentSnapshot ds) {
        name = ds['nickname'];
        return name;
      });
    }

    _currentNickname();

    return Scaffold(
      body: Form(
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
                      return 'Please enter Nickname';
                    }
                    return null;
                  },
                  controller: textEditingController1,
                  decoration: InputDecoration(
                    hintText: ('Nickname'),
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
                      onPressed: ()   async {
                        checkLoop = true;
                        isDuplicated = false;
                        await for (var snapshot in FirebaseFirestore.instance.collection('users').snapshots())
                        {
                          for(var users in snapshot.docs){

                            if(textEditingController1.text == users.get('nickname')) {
                              print('중복이 존재합니다');
                              ScaffoldMessenger.of(context).showSnackBar(snackBar1);
                              isDuplicated = true;
                              break;
                            }
                          }
                          break;
                        };
                        if(isDuplicated == false) {
                          ScaffoldMessenger.of(context).showSnackBar(snackBar2);
                        }
                      },

                      style: ElevatedButton.styleFrom(
                          primary: Color(0xfffc7174),
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                      child: Text(
                        '중복확인',
                      ),
                    ),
                    Container(
                      width: 20,
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        /// 중복체크를 하지 않거나, 중복이 있음에도 불구하고 시작하기 누르면 그냥 로그인 되는 현상 해결

                        if(name == textEditingController1.text) {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()));
                        }
                        else if(isDuplicated || checkLoop == false)
                        {
                          ScaffoldMessenger.of(context).showSnackBar(snackBar3);

                        }
                        else {
                          if(_formKey.currentState.validate()) {

                            await FirebaseFirestore.instance.collection('users')
                                .doc(FirebaseAuth.instance.currentUser.uid) /// document ID 를 uid 로 설정하는 부분
                                .set({
                              'username': FirebaseAuth.instance.currentUser
                                  .displayName,
                              'photoUrl': FirebaseAuth.instance.currentUser
                                  .photoURL,
                              'id': FirebaseAuth.instance.currentUser.uid,
                              'createdAt': FieldValue.serverTimestamp(),
                              'nickname': textEditingController1.text,
                            }).then((value) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomePage()));
                            }).catchError((error) => print('Error: $error'));
                          }
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