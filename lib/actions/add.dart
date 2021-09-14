import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:image_picker/image_picker.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../main.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  /// multiImage Picker로 선택한 사진들이 담길 리스트
  List<Asset> imageList = [];

  /// index만큼의 이미지를 갤러리에서 선택한 후 imageList에 저장하는 함수
  void getMultiImage(int index) async {
    List<Asset> resultList;
    resultList = await MultiImagePicker.pickImages(
        maxImages: index, enableCamera: true, selectedAssets: imageList);
    setState(() {
      imageList = resultList;
      numberOfImages = imageList.length;
      if (numberOfImages >= 10) {
        numberOfImagesTextColor = true;
      } else {
        numberOfImagesTextColor = false;
      }
    });
  }

  /// Give or Take 선택용 ToggleButtons - 각 버튼용 bool 리스트
  final List<bool> _selectionsOfGiveOrTake = List.generate(2, (_) => false);

  // Input form related
  final _formKey = GlobalKey<FormState>(debugLabel: '_giveAddPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  /// Firebase Storage 참조 간략화
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  /// 현재 유저의 이름 참조 간략화
  var user = FirebaseAuth.instance.currentUser;
  var name;

  /// Add 페이지 내에서 give/take 중 무엇을 선택했는지를 담고 있는 변수
  String giveOrTakeCategory;

  /// 이미지 storage 에 저장할 때 productID 뒤에 숫자붙여서 저장하기
  Future<void> uploadFile(String id) async {
    await getImageFileFromAssets();

    try {
      for (var num = 0; num < imageList.length; num++) {
        await storage
            .ref('images/' + id + num.toString() + '.png')
            .putFile(file[num]);
      }
    } on Exception {
      print('storage에 안올라감!');
      return null;
    }
  }

  /// Firestore collection names
  CollectionReference giveProduct =
      FirebaseFirestore.instance.collection('giveProducts');
  CollectionReference takeProduct =
      FirebaseFirestore.instance.collection('takeProducts');

  /// Add product in 'giveProducts' collection
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
    }).then((value) {
      if (imageList != null) uploadFile(value.id);
    }).catchError((error) => print('Error: $error'));
  }

  /// Add product in 'takeProducts' collection
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
    }).then((value) {
      if (imageList != null) uploadFile(value.id);
    }).catchError((error) => print('Error: $error'));
  }

  List<File> file;

  /// asset으로 저장된 이미지들을 file로 바꾸는 작업하는 함수
  Future<void> getImageFileFromAssets() async {
    List<String> path;
    for (var i = 0; i < imageList.length; i++) {
      path[i] =
          await FlutterAbsolutePath.getAbsolutePath(imageList[i].identifier);
      final byteData = await rootBundle.load('assets/$path');

      file[i] = File('${(await getTemporaryDirectory()).path}/$path');
      await file[i].writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
  }

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

  /// 업로드 된 이미지의 개수
  int numberOfImages = 0;

  /// 10개의 이미지 개수 제한에 다다랐을 때 true 로 변함(글자색 바꿀 때 사용)
  bool numberOfImagesTextColor = false;

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
                imageList.isEmpty
                    ? Container()
                    : Container(
                        height:
                            MediaQuery.of(context).size.height * (0.11) * 0.7,
                        width: MediaQuery.of(context).size.height * (0.35),
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageList.length,
                            itemBuilder: (BuildContext context, int index) {
                              var asset = imageList[index];
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
        builder: (context, appState, _) => Scaffold(
            appBar: AppBar(
              backgroundColor: Color(0xfffc7174),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  semanticLabel: 'back',
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text('나눔 글쓰기'),
              centerTitle: true,
              actions: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.save,
                      semanticLabel: 'save',
                    ),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        if (giveOrTakeCategory == 'give') {
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
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      flex: 6,

                                      /// 게시물 올릴 카테고리 (give 또는 take) 정하는 토글버튼
                                      child: _buildToggleButtons(context),
                                    )
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
