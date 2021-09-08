import 'dart:io' as prefix;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
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
      final filePath = await FlutterAbsolutePath.getAbsolutePath(imageAsset.identifier);
      var tempFile = File(filePath);

      file.add(tempFile);
    });
  }

  /// ProductID에 따라 해당하는 image url 다운로드
  Future<String> downloadURL(String id, int num) async {
    try {
      return await storage
          .ref()
          .child('images')
      //.child('$id.png')
          .child('$id$num.png')
          .getDownloadURL();
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

  ///**************** UI 구성에 필요한 변수들(하단의 위젯함수 내부에서 사용되는 것들도 포함) ***************///

  /// Add 페이지 내에서 give/take 중 무엇을 선택했는지를 담고 있는 변수
  String giveOrTakeCategory;

  /// Give or Take 선택용 ToggleButtons - 각 버튼용 bool 리스트
  final List<bool> _selectionsOfGiveOrTake = List.generate(2, (_) => false);

  /// 게시글 내용 입력과 관련된 key, controller 들
  final _formKey = GlobalKey<FormState>(debugLabel: '_EditPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  /// 카테고리 설정하는 토글버튼과 관련된 함수
  final _filter = ['카테고리', '여성 의류', '남성의류', '음식', '쿠폰', '전자제품', '책','학용품', '재능기부', '기타'];
  var _selectedFilter = '카테고리';

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
    Future<String> downloadURL(String id, int num) async {
      try {
        return await storage
            .ref()
            .child('images')
            .child('$id$num.png')
            .getDownloadURL();
      } on Exception {
        return null;
      }
    }

    /// 이미지 storage 에 저장할 때 productID 뒤에 숫자붙여서 저장시키는 함수
    Future<void> uploadFile(String id) async {
      try {
        for (var num = 0; num < file.length; num++) {
          print('file 저장 시작 -> ${num+1}');
          await storage.ref('images/' + id + (product.photo + num).toString() + '.png')
              .putFile(file[num]);
        }
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
        'photo' : product.photo + numberOfImages,
      }).then((value) {
        if (images.isNotEmpty) uploadFile(productId);
      }).catchError((error) => print('Error: $error'));
        /*if (_image != null) uploadFile(_image, productId);
      }).catchError((error) => print('Error: $error'));*/
    }

    Widget savedImages(List<String> data) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for(var i=0; i<product.photo; i++)
            if(data[i] != null)
              Container(
                height: 200,
                width: 200,
                child: Image.network(data[i]),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                width: MediaQuery.of(context).size.height * (0.11) * 0.12,
              ),
        ],
      );
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
          title: Text('글 수정'),
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
                '저장',
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
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * (0.1),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.016,
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
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
                                  color: numberOfImagesTextColor ? Colors.red : Colors.black,
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
                                      color:
                                      numberOfImagesTextColor ? Colors.red : Colors.black,
                                    ),
                                  )
                                ],
                              )),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.height * (0.11) * 0.12,
                        ),

                        /// 업로드 된 사진들 가로 스크롤 가능
                        FutureBuilder(
                          future:Future.wait([
                            downloadURL(productId,0),
                            downloadURL(productId,1),
                            downloadURL(productId,2),
                            downloadURL(productId,3),
                            downloadURL(productId,4),
                            downloadURL(productId,5),
                            downloadURL(productId,6),
                            downloadURL(productId,7),
                            downloadURL(productId,8),
                            downloadURL(productId,9),
                          ]),
                          builder: (context, snapshot){
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Column(
                                children: [
                                  Center(child: CircularProgressIndicator()),
                                ],
                              );
                            }  else {
                              if(snapshot.hasData) {
                                return /*ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    savedImages(snapshot.data),
                                    images.isEmpty ? Container() : Container(
                                      height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                                      width: MediaQuery.of(context).size.height * (0.35),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          for(var i=0; i<numberOfImages; i++)
                                            AssetThumb(
                                              asset: images[i],
                                              height: 200,
                                              width: 200,
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                                              width: MediaQuery.of(context).size.height * (0.11) * 0.12,
                                            ),
                                        ],
                                      ),
                                    )
                                  ],
                                );*/


                                  Row(
                                    children: [
                                      //savedImages(snapshot.data),
                                      images.isEmpty ? Container() : Container(
                                    height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                                    width: MediaQuery.of(context).size.height * (0.35),
                                    child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: images.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          var asset = images[index];
                                          return Row(
                                            children: [
                                              Stack(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      //savedImages(snapshot.data),
                                                      AssetThumb(
                                                        asset: asset,
                                                        height: 200,
                                                        width: 200,
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                                                        width: MediaQuery.of(context).size.height * (0.11) * 0.12,
                                                      ),
                                                    ],
                                                  ),

                                                  /// 여기서 삭제버튼 구현하다 관둠...
                                                ],
                                              )
                                            ],
                                          );
                                        }),
                                  )
                                ]);
                              } else if (snapshot.hasData == false) {
                                return Container(height: 35,);
                              } else {
                                return Container(
                                  child: Text('Snapshot Error!'),
                                );
                              }
                            }
                          },
                        ),

                      ]),
                  ],
                )
              ),
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
                                height: MediaQuery.of(context).size.height * (0.06) ,
                                child:  Column(
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
                                          hintText: product.title,
                                          hintStyle: TextStyle(
                                              height: 1.5,
                                              fontSize: 18.0,
                                              color: Color(0xffced3d0)
                                          ),
                                          contentPadding: EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
                                        ),
                                        style: TextStyle(fontSize: 18, height: 1.5, ),
                                        enableSuggestions: false,
                                        autocorrect: false,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            _titleController.text = product.title;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 5,)
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
                                                  child: Text(value,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ).toList(),
                                          onChanged: (value) {
                                            if (value != _selectedFilter)
                                            { _selectedFilter= value;}
                                            setState(() {
                                              _selectedFilter = value;
                                            });
                                          },
                                        ),
                                      )
                                  ),
                                  SizedBox(width: 10,),
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
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        hintMaxLines: 3,
                                        hintText: product.content,
                                        hintStyle: TextStyle(height: 1.5, fontSize: 18.0, color: Color(0xffced3d0)),
                                      ),
                                      style: TextStyle(fontSize: 18, height: 1.5,),
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
                      ],
                    ),
                  ),
                  SizedBox(width: 14),
                ],
              ),
            ],
          ),
        ),
      );
    });
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
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
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
                            color: numberOfImagesTextColor ? Colors.red : Colors.black,
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
                                color:
                                numberOfImagesTextColor ? Colors.red : Colors.black,
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
                    images.isEmpty ? Container() : Container(
                      height: MediaQuery.of(context).size.height * (0.11) * 0.7,
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
                                      height: MediaQuery.of(context).size.height * (0.11) * 0.7,
                                      width: MediaQuery.of(context).size.height * (0.11) * 0.12,
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
        )
    );
  }

  /// give or take 선택하는 토글 버튼
  ToggleButtons _buildToggleButtons(BuildContext context) {
    return ToggleButtons(
      color: Colors.black.withOpacity(0.60),
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width * 0.2,
        minHeight: 30,
      ),
      selectedBorderColor: Colors.cyan,
      selectedColor: Colors.cyan,
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
