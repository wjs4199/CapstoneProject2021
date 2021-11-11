import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

TextEditingController textEditingController1 = TextEditingController();
var name = '';
var nickname = '';
var currentUserId = FirebaseAuth.instance.currentUser.uid;


class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();

}

class SignUpState extends State<SignUp> {

  final _formKey = GlobalKey<FormState>();
  CollectionReference users =
  FirebaseFirestore.instance.collection('users');

  String userId = FirebaseAuth.instance.currentUser.uid;

  ///********************************* user 사진 변경 관련 함수 변수들 *********************************///
  /// Firebase Storage 참조 간략화
  FirebaseStorage storage = FirebaseStorage.instance;

  /// ImagePicker 간략화시켜 참조
  final ImagePicker _picker = ImagePicker();

  /// 선택한 사진
  File pickedImage;

  /// 다운로드 받은 사용자 이미지 URL
  String userImageUrl;

  /// index 만큼의 이미지를 갤러리에서 선택한 후 image 리스트에 저장시키는 함수
  Future<void> getImage() async {
    //이미지 받아올 때 사이즈 압축
    var pickedFile = await _picker.pickImage(
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85, source: ImageSource.gallery,
    );

    setState(() {
      pickedImage = File(pickedFile.path);
    });
  }

  /// ProductID에 따라 해당하는 thumbnail image url 다운로드
  Future<String> thumbnailURL(String id) async {
    try {
      return await storage
          .ref()
          .child('userImage')
          .child('$id.png')
          .getDownloadURL();
    } on Exception {
      return null;
    }
  }

  /// 이미지 storage 에 저장할 때 productID 뒤에 숫자붙여서 저장시키는 함수
  Future<void> uploadUserImage(String id) async {
    try {
        await storage
            .ref('userImage/' + id + '.png')
            .putFile(pickedImage);
    } on Exception {
      return null;
    }
  }

  /// ProductID에 따라 해당하는 image url 다운로드
  Future<String> downloadURL(String id) async {
    try {
       userImageUrl = await storage
          .ref()
          .child('userImage/')
          .child('$id.png')
          .getDownloadURL();
       return userImageUrl;
    } on Exception {
      return null;
    }
  }

  /// 다운로드 받은 url에 해당하는 사진 삭제
  Future<void> deleteOneImage() async {
    try {
      print('사진 삭제 시작!');
      return await storage
          .refFromURL(userImageUrl)
          .delete()
          .whenComplete(() => print('사용자 사진 삭제 완료!'));
    } on Exception {
      return null;
    }
  }

  Future<File> fileFromImageUrl(String url) async {
    if(await downloadURL(userId) == null) {
      return null;
    }
    var response = await http.get(Uri.parse(await downloadURL(userId)));

    var documentDirectory = await getApplicationDocumentsDirectory();

    var file = File('${documentDirectory.path}/$userId.png');

    file.writeAsBytesSync(response.bodyBytes);

    return file;
  }


  @override
  Widget build(BuildContext context) {
    var isDuplicated = false;
    var checkLoop = false;
    var isCurrentName = false;
    var isInvalid = false;

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

    thumbnailURL(userId);

    Future<void> editUserImage() {
      return deleteOneImage().then((value) async {
        /// storage에 올려진 사진 삭제 후 다시 업로드
        if(userImageUrl != null) {
          await deleteOneImage().whenComplete(() async {
            if (pickedImage != null) {
              await uploadUserImage(userId)
                  .whenComplete(() => print('유저 사진 업로드 완료'));
            }
          });
        } else {
          if (pickedImage != null) {
            await uploadUserImage(userId)
                .whenComplete(() => print('유저 사진 업로드 완료'));
          }
        }

      }).catchError((error) => print('Error: $error'));
    }

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
            FutureBuilder(
              future:
                fileFromImageUrl(userImageUrl),
              builder: (context, snapshot) {
              /// 시진 로딩중일 때
              if (snapshot.connectionState == ConnectionState.waiting) {
                return  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.width * 0.3,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xfffc7174)),
                  )
                );
              }
              /// 사진 로딩 후
              else {
                //userImageUrl = snapshot.data[i];
                pickedImage ?? snapshot.data;
                return Stack(
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: MediaQuery.of(context).size.width * 0.3,
                        child: pickedImage != null
                            ? Image.file(pickedImage)
                            : Image.asset('assets/userDefaultImage.png')
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: MediaQuery.of(context).size.width * 0.3 - 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            InkWell(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                semanticLabel: 'Image upload',
                                color: Colors.grey,
                              ),
                              onTap: () {
                                getImage();
                                setState(() {
                                  //editUserImage();
                                });
                              },
                            ),
                            SizedBox( width: 5,),
                          ],
                        )
                    ),
                    SizedBox( height: 5,),
                  ],
                );
                }
              }),
              SizedBox( height: 10,),
              Text(
                nickname,
                style: TextStyle(color: Colors.black54,
                    letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NanumSquareRoundR',),
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
                    hintText: ('새로운 닉네임을 입력하세요.'),
                    hintStyle: TextStyle(
                      fontFamily: 'NanumSquareRoundR',
                    ),
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
                            fontFamily: 'NanumSquareRoundR',
                          )),
                      child: Text(
                        '중복확인',
                        style: TextStyle(
                          fontFamily: 'NanumSquareRoundR',
                        ),
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
                              }).then((value) async {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                await editUserImage().whenComplete(() {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomePage()));
                                  }).catchError((error) => print('Error: $error'));
                                });
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
                            fontFamily: 'NanumSquareRoundR',
                          )),
                      child: Text(
                        '시작하기',
                        style: TextStyle(
                          fontFamily: 'NanumSquareRoundR',
                        ),
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