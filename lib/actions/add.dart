import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../main.dart';

class AddPage extends StatefulWidget {
  AddPage({this.giveOrTake});

  final String giveOrTake;

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  ///**************** Multi Image 선택 및 저장과 관련된 변수/ 함수들 ***************///
  /// Firebase Storage 참조 간략화
  FirebaseStorage storage = FirebaseStorage.instance;

  /// multiImage Picker로 선택한 사진들이 담길 리스트 (Asset타입 - 사진 띄울 때 사용됨)
  List<Asset> images = [];

  /// multiImage Picker로 선택한 사진들이 담길 리스트 (File타입 - 사진 저장할 때 사용됨)
  List<File> file = [];

  /// 업로드 된 이미지의 개수
  int numberOfImages = 0;

  /// 10개의 이미지 개수 제한에 다다랐을 때 true 로 변함(글자색 바꿀 때 사용)
  bool numberOfImagesTextColor = false;

  /// index 만큼의 이미지를 갤러리에서 선택한 후 image 리스트에 저장시키는 함수
  Future<void> getMultiImage(int index) async {
    List<Asset> resultList;
    resultList = await MultiImagePicker.pickImages(
        maxImages: index, enableCamera: true, selectedAssets: images);

    setState(() {
      images = resultList;
      numberOfImages = images.length;
      if (numberOfImages >= 10) {
        numberOfImagesTextColor = true;
      } else {
        numberOfImagesTextColor = false;
      }
    });

    /// 받아온 이미지를 File 타입으로 변환
    await getImageFileFromAssets();
  }

  /// image 리스트에 들어있는 Asset 타입 이미지들을 File 타입으로 변환시키는 함수(storage 저장 위해)
  Future<void> getImageFileFromAssets() async {
    images.forEach((imageAsset) async {
      final filePath =
          await FlutterAbsolutePath.getAbsolutePath(imageAsset.identifier);
      var tempFile = File(filePath);

      file.add(tempFile);
    });
  }

  /// 이미지 storage 에 저장할 때 productID 뒤에 숫자붙여서 저장시키는 함수
  Future<void> uploadFile(String id) async {
    try {
      for (var num = 0; num < file.length; num++) {
        print('file 저장 시작 -> ${num + 1}');
        await storage
            .ref('images/' + id + num.toString() + '.png')
            .putFile(file[num]);
      }
    } on Exception {
      return null;
    }
  }

  ///**************** 게시글 저장과 관련된 변수/ 함수들 ***************///
  /// 현재 유저의 이름 참조 간략화
  var user = FirebaseAuth.instance.currentUser;
  var name;

  /// Firestore collection 참조 간략화
  CollectionReference giveProduct =
      FirebaseFirestore.instance.collection('giveProducts');
  CollectionReference takeProduct =
      FirebaseFirestore.instance.collection('takeProducts');

  /// 'giveProducts' collection 에 게시글 추가시키는 함수
  Future<void> addGiveProduct(String title, String content, String category) {
    if (user != null) {
      name = user.displayName;
    }
    return giveProduct.add({
      'title': title,
      'content': content,
      'category': category,
      'uid': FirebaseAuth.instance.currentUser.uid,
      'created': FieldValue.serverTimestamp(),
      'modified': FieldValue.serverTimestamp(),
      'userName': name,
      'hits': 1,
      'photo': numberOfImages,
      'user_photoURL': user.photoURL,
    }).then((value) async {
      if (images.isNotEmpty) {
        await uploadFile(value.id);
      }
    }).catchError((error) => print('Error: $error'));
  }

  /// 'takeProducts' collection 에 게시글 추가시키는 함수
  Future<void> addTakeProduct(String title, String content, String category) {
    if (user != null) {
      name = user.displayName;
    }
    return takeProduct.add({
      'title': title,
      'content': content,
      'category': category,
      'uid': FirebaseAuth.instance.currentUser.uid,
      'created': FieldValue.serverTimestamp(),
      'modified': FieldValue.serverTimestamp(),
      'userName': name,
      'hits': 1,
      'photo': numberOfImages,
      'user_photoURL': user.photoURL,
    }).then((value) {
      if (images.isNotEmpty) uploadFile(value.id);
    }).catchError((error) => print('Error: $error'));
  }

  ///**************** UI 구성에 필요한 변수들(하단의 위젯함수 내부에서 사용되는 것들도 포함) ***************///
  /// Add 페이지 내에서 give/take 중 무엇을 선택했는지를 담고 있는 변수
  String giveOrTakeCategory;

  /// Give or Take 선택용 ToggleButtons - 각 버튼용 bool 리스트
  final List<bool> _selectionsOfGiveOrTake = List.generate(2, (_) => false);

  /// 게시글 내용 입력과 관련된 key, controller 들
  final _formKey = GlobalKey<FormState>(debugLabel: '_giveAddPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  /// 카테고리 설정하는 토글버튼과 관련된 함수
  final _filter = [
    '카테고리',
    '여성 의류',
    '남성의류',
    '음식',
    '쿠폰',
    '전자제품',
    '책',
    '학용품',
    '재능기부',
    '기타'
  ];
  var _selectedFilter = '카테고리';

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
        builder: (context, appState, _) => Scaffold(
            appBar: AppBar(
              backgroundColor: Color(0xfffc7174),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  semanticLabel: '뒤로가기',
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: widget.giveOrTake == 'give'
                  ? Text(
                      '나눔 글쓰기',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRoundR',
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      '나눔요청 글쓰기',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRoundR',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              centerTitle: true,
              actions: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.save,
                      semanticLabel: '저장',
                    ),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        if (widget.giveOrTake == 'give') {
                          addGiveProduct(
                            _titleController.text,
                            _contentController.text,
                            _selectedFilter,
                          );
                        } else {
                          addTakeProduct(
                            _titleController.text,
                            _contentController.text,
                            _selectedFilter,
                          );
                        }
                        Navigator.pop(context);
                        appState.orderByFilter('All');
                      }
                    }),
              ],
            ),
            body: SafeArea(
              child: ListView(children: [
                imageUpLoadWidget(),
                Row(
                  children: [
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          Divider(thickness: 1),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                /// 제목 입력하는 부분
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      (0.06),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _titleController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            hintText: '제목',
                                            hintStyle: TextStyle(
                                                height: 1.5,
                                                fontSize: 18.0,
                                                color: Color(0xffced3d0)),
                                            contentPadding: EdgeInsets.fromLTRB(
                                                0, 10.0, 0, 10.0),
                                          ),
                                          style: TextStyle(
                                            fontSize: 18,
                                            height: 1.5,
                                          ),
                                          enableSuggestions: false,
                                          autocorrect: false,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Enter your message to continue';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      )
                                    ],
                                  ),
                                ),
                                Divider(thickness: 1),

                                /// 카테고리 드롭다운 버튼과 원해요/나눠요 토글 버튼 있는 Row
                                Row(
                                  children: [
                                    Expanded(
                                        flex: 7,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: _selectedFilter,
                                            items: _filter.map(
                                              (value) {
                                                return DropdownMenuItem(
                                                  value: value,
                                                  child: Center(
                                                    child: Text(
                                                      value,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                            onChanged: (value) {
                                              if (value != _selectedFilter) {
                                                _selectedFilter = value;
                                              }
                                              setState(() {
                                                _selectedFilter = value;
                                              });
                                            },
                                          ),
                                        )),
                                  ],
                                ),
                                Divider(thickness: 1),

                                /// 게시글 내용 입력하는 부분
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        controller: _contentController,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          hintMaxLines: 3,
                                          hintText:
                                              '당신이 나눔할 내용을 입력해주세요. 재사용이 불가능하거나 판매금지품목인 경우 게시가 제한될 수 있어요.',
                                          hintStyle: TextStyle(
                                              height: 1.5,
                                              fontSize: 18.0,
                                              color: Color(0xffced3d0)),
                                        ),
                                        style: TextStyle(
                                          fontSize: 18,
                                          height: 1.5,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter your message to continue';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14),
                  ],
                ),
              ]),
            )));
  }

  /// 상단 사진업로드하는 위젯
  Widget imageUpLoadWidget() {
    return Container(
        color: Colors.transparent,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * (0.1),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.016,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(
                width: MediaQuery.of(context).size.height * (0.11) * 0.12,
              ),
              Container(
                width: MediaQuery.of(context).size.height * (0.11) * 0.7,
                height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      primary: Colors.black,
                      backgroundColor: Colors.transparent,
                      textStyle: TextStyle(
                        color:
                            numberOfImagesTextColor ? Colors.red : Colors.black,
                        fontSize: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        getMultiImage(10);
                        if (numberOfImages < 10) {
                          numberOfImagesTextColor = false;
                        } else {
                          numberOfImagesTextColor = true;
                        }
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          semanticLabel: 'Image upload',
                          color: Colors.grey,
                        ),
                        Text(
                          '$numberOfImages/10',
                          style: TextStyle(
                            color: numberOfImagesTextColor
                                ? Colors.red
                                : Colors.black,
                          ),
                        )
                      ],
                    )),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.height * (0.11) * 0.12,
              ),

              /// 업로드 된 사진들 가로 스크롤 가능
              Row(children: [
                images.isEmpty
                    ? Container()
                    : Container(
                        height:
                            MediaQuery.of(context).size.height * (0.11) * 0.7,
                        width: MediaQuery.of(context).size.height * (0.35),
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            itemBuilder: (BuildContext context, int index) {
                              var asset = images[index];
                              return Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      AssetThumb(
                                        asset: asset,
                                        height: 200,
                                        width: 200,
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                (0.11) *
                                                0.7,
                                        width:
                                            MediaQuery.of(context).size.height *
                                                (0.11) *
                                                0.12,
                                      ),
                                    ],
                                  ),

                                  /// 여기서 삭제버튼 구현하다 관둠...
                                ],
                              );
                            }),
                      )
              ])
            ]),
          ],
        ));
  }

  /// give or take 선택하는 토글 버튼
  ToggleButtons _buildToggleButtons(BuildContext context) {
    return ToggleButtons(
      color: Colors.black.withOpacity(0.60),
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width * 0.2,
        minHeight: 30,
      ),
      selectedBorderColor: Color(0xfffc7174),
      selectedColor: Color(0xfffc7174),
      borderRadius: BorderRadius.circular(4.0),
      isSelected: _selectionsOfGiveOrTake,
      onPressed: (int index) {
        setState(() {
          if (index == 0) {
            _selectionsOfGiveOrTake[0] = true;
            _selectionsOfGiveOrTake[1] = false;
            giveOrTakeCategory = 'give';
          } else {
            _selectionsOfGiveOrTake[0] = false;
            _selectionsOfGiveOrTake[1] = true;
            giveOrTakeCategory = 'take';
          }
        });
      },
      children: [
        Text('나눠요'),
        Text('원해요'),
      ],
    );
  }
}
