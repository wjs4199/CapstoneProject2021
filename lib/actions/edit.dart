import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../model/product.dart';
import 'dart:io';

class EditPage extends StatefulWidget {
  EditPage({this.productId, this.editGiveOrTake});

  /// route 생성 시에 사용되는 product ID
  final String productId;

  /// giveProducts / takeProducts collection 중 어디서 가져와야하는 지 표시
  final String editGiveOrTake;

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  ///********************* 사진 변경 기능을 위한 부분 *********************///

  /// 유저가 사진을 변경할 시 변경된 사진파일이 담길 변수
  File _image;

  /// 유저가 사진을 변경할 시 필요한 ImagePicker() 참조 변수
  final picker = ImagePicker();

  /// 유저가 사진변경 버튼을 눌렀을 때 실행되는 사진 변경하여 가져오는 함수
  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  /// Firebase Storage 참조 간략화
  var storage = FirebaseStorage.instance;

  /// 변경된 사진을 저장할 때 Firebase 에 업로드 시키는 함수
  Future<void> uploadFile(File photo, String id) async {
    try {
      await storage.ref('images/' + id + '.png').putFile(photo);
    } on Exception {
      return null;
    }
  }

  ///********************* 카테고리 변경 기능을 위한 부분 *********************///

  /// 'Product', 'Time', 'Talent' 카테고리를 선택하는 DropdownButton 의 선택지 리스트
  final _filter = ['Product', 'Time', 'Talent'];

  /// DropdownButton 에서 선택한 카테고리를 담는 변수 (기본으로 보여지는 항목을 'Product'로 초기화)
  var _selectedFilter = 'Product';

  /// DropdownButton 의 상태를 사용자의 선택에 따라 변경하는 함수
  void dropdownUpdate(value) {
    if (value != _selectedFilter) _selectedFilter = value;
    setState(() {
      _selectedFilter = value;
    });
  }

  ///********************* 게시'글' 내용 변경 기능을 위한 부분 *********************///

  /// title과 content의 Text상자 상태를 검증하는 GlobalKey
  final _formKey = GlobalKey<FormState>(debugLabel: '_EditPageState');

  /// title 을 수정하는 text 상자의 Controller
  final _titleController = TextEditingController();

  /// content 를 수정하는 text 상자의 Controller
  final _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ///*********** ProductID와 맞는 게시물 내용을 Firebase 에서 찾아내는 부분 ***********///

    /// EditPage 호출시 받는 매개변수 참조
    var productId = widget.productId;
    var editGiveOrTake = widget.editGiveOrTake;

    /// editGiveOrTake 가 담고 있는 collection 이름에 따라 그 collection 담긴 내용 가져오기
    var products = editGiveOrTake == 'giveProducts'
        ? context.watch<ApplicationState>().giveProducts
        : context.watch<ApplicationState>().takeProducts;

    /// 컬랙션 내에서 productId가 같은 제품을 찾아냈을 때 그 내용을 담을 변수
    Product product;

    /// 컬랙션 내에서 productId가 같은 제품을 찾아냈을 때 true
    var productFound = false;

    /// products 에 담긴 것들 중 현재 productId와 같은 것 찾기
    for (var i = 0; i < products.length; i++) {
      if (products[i].id == productId) {
        product = products[i];
        productFound = true;

        print(product.userName);
        print(product.uid);
      }
    }

    /// productId와 일치하는 게시물이 없을 경우 로딩 표시
    if (products == null || products.isEmpty || productFound == false) {
      return Scaffold(
        body: CircularProgressIndicator(),
      );
    }

    /// ProductID에 따라 해당하는 image url 다운로드
    Future<String> downloadURL(String id) async {
      try {
        return await storage
            .ref()
            .child('images')
            .child('$id.png')
            .getDownloadURL();
      } on Exception {
        return null;
      }
    }

    ///********************* 변경한 내용대로 게시물을 업데이트 *********************///

    /// giveProducts 또는 takeProducts 중 어디 컬랙션에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference target =
        FirebaseFirestore.instance.collection(editGiveOrTake);

    /// 변경한 내용대로 게시물 업데이트 시키는 함수
    Future<void> editProduct(String category, String title, String content) {
      return target.doc(productId).update({
        'title': title,
        'content': content,
        'category': category,
        'modified': FieldValue.serverTimestamp(),
      }).then((value) {
        if (_image != null) uploadFile(_image, productId);
      }).catchError((error) => print('Error: $error'));
    }

    /// Edit 페이지 화면 구성
    return Consumer<ApplicationState>(builder: (context, appState, _) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              semanticLabel: 'back',
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Edit'),
          centerTitle: true,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  editProduct(
                    _selectedFilter,
                    _titleController.text,
                    _contentController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                child: _image == null
                    ? FutureBuilder(
                        future: downloadURL(productId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.network(snapshot.data.toString(),
                                fit: BoxFit.fitWidth);
                          } else if (snapshot.hasData == false) {
                            return Image.asset('assets/logo.png');
                          } else {
                            return Container(
                              child: Text('Snapshot Error!'),
                            );
                          }
                        },
                      )
                    : Image.file(
                        _image,
                        fit: BoxFit.fitWidth,
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 48.0),
                        Row(
                          children: [
                            Expanded(
                              flex: 9,
                              child: Container(),
                            ),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: Icon(
                                  Icons.photo_camera,
                                  semanticLabel: 'pick_photo',
                                ),
                                onPressed: getImage,
                              ),
                            ),
                          ],
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButton<String>(
                                      value: _selectedFilter,
                                      items: _filter.map(
                                        (value) {
                                          return DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          );
                                        },
                                      ).toList(),
                                      onChanged: (value) {
                                        dropdownUpdate(value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _titleController,
                                      decoration: InputDecoration(
                                        hintText: product.title,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          _titleController.text = product.title;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _contentController,
                                      decoration: InputDecoration(
                                        hintText: product.content,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          _contentController.text =
                                              product.content;
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
                        SizedBox(height: 48.0),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
