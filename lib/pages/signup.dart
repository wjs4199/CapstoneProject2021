import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home.dart';


TextEditingController textEditingController1 = TextEditingController();
var nickname = '';


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
    var isCurrentName = false;
    var isInvalid = false;
    var name = '';
    var currentUserId = FirebaseAuth.instance.currentUser.uid;

    final snackBar1 = SnackBar(content: Text('중복이 존재합니다'));
    final snackBar2 = SnackBar(content: Text('사용해도 좋습니다'));
    final snackBar3 = SnackBar(content: Text('중복체크를 해주세요'));
    final snackBar4 = SnackBar(content: Text('닉네임을 한글자 이상 입력해주세요'));


    Future<String> _currentNickname() async {
      await FirebaseFirestore.instance.collection('users').doc(currentUserId)
          .get()
          .then((DocumentSnapshot ds) {
        name = ds['nickname'];
        nickname = name;
      });
      return name;
    }

    _currentNickname();
    //print("nickname = " + nickname);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: Column(
            children: [
              Text(
                "현재 닉네임: " + nickname,
                style: TextStyle(color: Colors.black54, letterSpacing: 1.0),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Nickname';
                    }
                    return null;
                  },
                  controller: textEditingController1,
                  decoration: InputDecoration(
                    hintText: ("변경할 닉네임"),
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

                        //닉네임을 빈칸으로 입력하고 중복체크를 눌렀을 경우
                        if(textEditingController1.text == "") {
                          isInvalid = true;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(snackBar4);
                        }
                        else {
                          isInvalid = false;
                          await for (var snapshot in FirebaseFirestore.instance.collection('users').snapshots())
                          {
                            for(var users in snapshot.docs){

                              if(textEditingController1.text == users.get('nickname')) {
                                if(name == textEditingController1.text) {
                                  isCurrentName = true;
                                  break;
                                } else {
                                  print('중복이 존재합니다');
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar1);
                                  isDuplicated = true;
                                  break;
                                }
                              }
                            }
                            break;
                          };
                        }
                        if(isDuplicated == false && isCurrentName == false && isInvalid == false) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                        //닉네임을 처음 설정하는데 빈칸을 입력했을 경우
                        if((name == null || name == "") && textEditingController1.text == "") {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(snackBar4);
                        }
                        //닉네임을 처음 설정하는게 아니거나 빈칸을 입력하지 않았을 경우
                        else {
                          //닉네임이 현재 닉네임과 같거나 빈칸인 채로 시작하기를 눌렀을 경우
                          if(name == textEditingController1.text || textEditingController1.text == "") {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          }
                          //중복체크를 하지 않았을 경우
                          else if(isDuplicated || checkLoop == false)
                          {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(snackBar3);
                          }
                          //정상적으로 바꿀 닉네임을 입력하고 중복체크도 완료했을 경우
                          else {
                            _currentNickname();

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
                                'email' : FirebaseAuth.instance.currentUser.email,
                              }).then((value) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => HomePage()));
                              }).catchError((error) => print('Error: $error'));
                            }
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