import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../model/product.dart';
import 'dart:io';
import 'dart:ui';


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
  String productId;

  @override
  void initState(){
    super.initState();

    productId = widget.productId;
  }
  ///**************** Multi Image 선택 및 저장과 관련된 변수/ 함수들 ***************///

  /// Firebase Storage 참조 간략화
  FirebaseStorage storage = FirebaseStorage.instance;

  /// 게시글에 저장되어 있던 사진들 + 저장될 사진들
  List<File> uploadImages = [];

  /// multiImage Picker로 선택한 사진들이 담길 리스트 (File타입 - 사진 저장할 때 사용됨)
  List<File> willBeSavedFileList = [];

  /// 게시글에 업로드 되어 있었던 사진들이 들어가는 리스트
  List<File> alreadySavedList = [];

  /// 게시글에 업로드 되어 있었던 이미지들의 개수
  int numberOfImages = 0;

  /// 한번 storage에서 업로드 되어 있었던 이미지를 읽어들이면 true로 변함(여러번 다운로드 방지)
  bool alreadyLoading = false;

  /// 10개의 이미지 개수 제한에 다다랐을 때 true 로 변함(글자색 바꿀 때 사용)
  bool numberOfImagesTextColor = false;

  /// ImagePicker 간략화시켜 참조
  final ImagePicker _picker = ImagePicker();

  /// index 만큼의 이미지를 갤러리에서 선택한 후 image 리스트에 저장시키는 함수
  Future<void> getMultiImage(int index) async {
    //이미지 받아올 때 사이즈 압축
    var pickedFileList = await _picker.pickMultiImage(
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    /// pick된 사진이 10개 아래이면 바로 image list에 넣고(글씨 검정)
    /// 10개이상이면 10개까지만 잘라서 image에 넣기(글씨 빨강)
    setState(() {
      if(pickedFileList.length < 10 - numberOfImages - alreadySavedList.length){
        numberOfImages += pickedFileList.length;
        for(var i = 0 ; i<pickedFileList.length; i++){
          willBeSavedFileList.add(File(pickedFileList[i].path));
        }
        numberOfImagesTextColor = false;
      } else {
        pickedFileList = pickedFileList.sublist(0, 10 - numberOfImages - alreadySavedList.length);
        for(var i = 0 ; i< 10 - numberOfImages - alreadySavedList.length; i++){
          willBeSavedFileList.add(File(pickedFileList[i].path));
        }
        numberOfImages += pickedFileList.length;
        numberOfImagesTextColor = true;
      }
    });
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

  /// 게시글 내용 입력과 관련된 key, controller 들
  final _formKey = GlobalKey<FormState>(debugLabel: '_EditPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  var _selectedFilter = '물건';

  int photoNum;
  int imageLoadCount =0;

  Future<File> fileFromImageUrl(String url, int num) async {
    var response = await http.get(Uri.parse(url));

    var documentDirectory = await getApplicationDocumentsDirectory();

    var file = File('${documentDirectory.path}/${widget.productId}$num.png');

    file.writeAsBytesSync(response.bodyBytes);

    return file;
  }

  /// storage 에서 다운로드한 이미지 url 들이 저장될 정적 저장소 (한 번 받고 나서 안변함)
  var imageUrlList = [];

  /// storage 에서 다운로드한 이미지 url 들이 저장된 리스트 (삭제버튼 누르면 내용물이 변함)
  var alreadyUrlList = [];

  /// 다운로드한 url 들 중 null 이 아닌 것들만을 imageUrlList 에 저장시킨는 함수
  Future<void> makeUrlList() async {
    /// 이미 한번 로딩 했는지 안했는지 확인(이미 했으면 다시 로딩 안함)
    if(!alreadyLoading){
      imageUrlList = await Future.wait([
        downloadURL(widget.productId,0),
        downloadURL(widget.productId,1),
        downloadURL(widget.productId,2),
        downloadURL(widget.productId,3),
        downloadURL(widget.productId,4),
        downloadURL(widget.productId,5),
        downloadURL(widget.productId,6),
        downloadURL(widget.productId,7),
        downloadURL(widget.productId,8),
        downloadURL(widget.productId,9),]);

      imageUrlList = imageUrlList.where((e) => e != null).toList();
      //alreadySavedList = imageUrlList;

      /*if(alreadyUrlList.length == 10) {
        numberOfImagesTextColor = true;
      }*/
      /// image file으로 만들어서 따로 저장해줘야함
      for(var i=0; i<imageUrlList.length; i++) {
        alreadySavedList.add(await fileFromImageUrl(imageUrlList[i],i));
      }
      print('alreadySavedList의 길이는 -> ${alreadySavedList.length}');

      if(alreadySavedList.length == 10) {
        numberOfImagesTextColor = true;
      }

      /// 이미 한번 로딩하여 가져온 경우 다시 안가져오도록 true로 바꿈
      alreadyLoading = true;
      print('alreadyLoading -> $alreadyLoading');
    }

    print('makeUrlList에서 alreadySavedList 길이는 -> ${alreadySavedList.length}');
  }

  /// edit한 게시글을 저장할 때 원래 저장되어 있던 이미지들의 url String 을 File 타입으로 바꿔주는 함수
  /// (처음에 url 다운로드 할 때부터 File 타입으로 바꾸는 것으로 시도해보았으나 변환 시간이 오래 걸려서 이 방법으로 대체)
  /*Future<void> makeAlreadySavedList() async {
    for(var i=0; i<alreadyUrlList.length; i++) {
      alreadySavedList.add(await fileFromImageUrl(alreadyUrlList[i],i));
    }

    print('alreadySavedList 길이는 -> ${alreadySavedList.length}');
  }*/


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
        body: CircularProgressIndicator(color: Color(0xfffc7174),),
      );
    }

    ///********************* 사진 리스트 관련 함수들 *********************///

    photoNum = product.photo;

    ///********************* 변경한 내용대로 게시물을 업데이트 *********************///

    Future<void> deleteOneImage(int num) async {
      try {
        print('사진 삭제 시작!');
        return await storage
            .refFromURL(imageUrlList[num])
            .delete()
            .whenComplete(() => print('$num번째 사진 삭제 완료!'));
      } on Exception {
        return null;
      }
    }

    Future<void> deleteImages() async {
      return await Future.wait([
        deleteOneImage(0),
        deleteOneImage(1),
        deleteOneImage(2),
        deleteOneImage(3),
        deleteOneImage(4),
        deleteOneImage(5),
        deleteOneImage(6),
        deleteOneImage(7),
        deleteOneImage(8),
        deleteOneImage(9),]);
    }

    /// giveProducts 또는 takeProducts 중 어디 컬랙션에 속한 게시물인지에 따라 참조할 path 결정
    CollectionReference target =
        FirebaseFirestore.instance.collection(editGiveOrTake);

    /// 변경한 내용대로 게시물 업데이트 시키는 함수
    /// 이미지 storage 에 저장할 때 productID 뒤에 숫자붙여서 저장시키는 함수
    Future<void> uploadFile(String id) async {
      try {
        for (var num = 0; num < uploadImages.length; num++) {
          print('uploadImages 저장 시작 -> ${num + 1}');
          await storage
              .ref('images/' + id + num.toString() + '.png')
              .putFile(uploadImages[num]);
        }
      } on Exception {
        return null;
      }
    }

    Future<void> editProduct(String category, String title, String content) {
      return target.doc(productId).update({
        'title': title,
        'content': content,
        'category': category,
        'modified': FieldValue.serverTimestamp(),
        'photo': alreadySavedList.length + willBeSavedFileList.length,
      }).then((value) async {
        /// storage에 올려진 사진 삭제 후 다시 업로드
        await deleteImages().whenComplete(() async {
          //await makeAlreadySavedList().then((value) async {
            uploadImages = alreadySavedList + willBeSavedFileList;
            if (uploadImages.isNotEmpty) await uploadFile(productId);
         // });
        });
      }).catchError((error) => print('Error: $error'));
    }


    /// 상단 사진업로드하는 위젯
    Widget imageUpLoadWidget() {
      return FutureBuilder(
          future: makeUrlList(),
          builder: (context, snapshot) {
            /// 시진 로딩중일 때
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                  height: MediaQuery.of(context).size.height * (0.11) * 0.77,
                  width: MediaQuery.of(context).size.height * (0.35),
                  child: Center(
                    child: CircularProgressIndicator(),
                  )
              );
            }
            /// 사진 로딩 후
            else {
              return Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * (0.11),
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
                                print('선택가능한 사진 수 -> ${10 - (numberOfImages + alreadySavedList.length)}');
                                if(!numberOfImagesTextColor){
                                  getMultiImage(alreadySavedList.length);
                                }
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
                                    '${willBeSavedFileList.length + alreadySavedList.length}/10',
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
                          alreadySavedList.isEmpty && willBeSavedFileList.isEmpty
                              ? Container(
                            height: MediaQuery.of(context).size.height * (0.11) * 0.77,
                            width: MediaQuery.of(context).size.height * (0.35),
                          )
                              : Container(
                            height: MediaQuery.of(context).size.height * (0.11) * 0.77,
                            width: MediaQuery.of(context).size.height * (0.35),
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: willBeSavedFileList.length + alreadySavedList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  print('보여주기 전 alreadySavedList.length -> ${alreadySavedList.length}');
                                  print('보여주기 전 willBeSavedFileList.length -> ${willBeSavedFileList.length}');
                                  print('보여주기 전 uploadImages.length -> ${uploadImages.length}');
                                  var alreadyFile;
                                  //var alreadyURL;
                                  var willFile;
                                  if(index < alreadySavedList.length){
                                    //alreadyURL = alreadySavedList[index];
                                    alreadyFile = alreadySavedList[index];
                                  } else {
                                    willFile = willBeSavedFileList[index-alreadySavedList.length];
                                  }

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Stack(children: [
                                                Container(
                                                    height: MediaQuery.of(context).size.height * (0.11) * 0.77,
                                                    width: MediaQuery.of(context).size.height * (0.11) * 0.7,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: [
                                                        SizedBox(
                                                          height: MediaQuery.of(context).size.height * (0.11) * 0.045,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Container(
                                                                height: 67,
                                                                width: 67,
                                                                child: ClipRRect(
                                                                    borderRadius: BorderRadius.circular(5.0),
                                                                    child: index < alreadySavedList.length ?
                                                                    Image.file(
                                                                      alreadyFile,
                                                                      fit: BoxFit.cover,
                                                                      width: 200,
                                                                    ): Image.file(
                                                                      willFile,
                                                                      fit: BoxFit.cover,
                                                                      width: 200,
                                                                    )
                                                                )
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    )
                                                ),
                                                Container(
                                                  height: MediaQuery.of(context).size.height * (0.11) * 0.76,
                                                  width: MediaQuery.of(context).size.height * (0.11) * 0.73,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        height: MediaQuery.of(context).size.height * (0.11) * 0.65,
                                                        width: MediaQuery.of(context).size.height * (0.11) * 0.73,
                                                        child: Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.start,
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                            children: [
                                                              Container(
                                                                width: 53,
                                                              ),
                                                              Expanded(
                                                                child: Container(
                                                                    width: 20,
                                                                    height: 20,
                                                                    child: InkWell(
                                                                      onTap: () {
                                                                        setState(() {
                                                                          if(index < alreadySavedList.length){
                                                                            alreadySavedList.remove(alreadyFile);
                                                                            //alreadySavedList.remove(alreadyFile);
                                                                          } else {
                                                                            willBeSavedFileList.remove(willFile);
                                                                          }
                                                                          numberOfImages = willBeSavedFileList.length;
                                                                          print('willsaved 길이 : ${willBeSavedFileList.length}\n'
                                                                              'alreadsaved 길이 : ${alreadySavedList.length}');

                                                                          /// 삭제해서 선택한 사진이 10개 아래이면 다시 색깔 검정으로
                                                                          if (numberOfImages + alreadySavedList.length >= 10) {
                                                                            numberOfImagesTextColor = true;
                                                                          } else {
                                                                            numberOfImagesTextColor = false;
                                                                          }
                                                                        });
                                                                      },
                                                                      child: Icon(
                                                                        Icons.cancel,
                                                                        size: 18,
                                                                        color: Color(0x00000000).withOpacity(0.5),
                                                                      ),
                                                                    )
                                                                ),)
                                                            ]),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ]),
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
                                      )
                                    ],
                                  );
                                }),
                          )
                        ]),
                      ]),
                    ],
                  ));
            }
          }
      );
    }

    /// Edit 페이지 화면 구성
    return Consumer<ApplicationState>(builder: (context, appState, _) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xfffc7174),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              semanticLabel: 'back',
            ),
            onPressed: () {
              alreadyLoading = false;
              numberOfImages = 0;
              alreadyUrlList.clear();
              alreadySavedList.clear();
              willBeSavedFileList.clear();
              uploadImages.clear();
              photoNum =0;
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
                  ).whenComplete(() => Navigator.pop(context));
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
              /// 업로드 된 사진들 가로 스크롤 가능
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
                                height:
                                    MediaQuery.of(context).size.height * (0.06),
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
                                          hintText: product.title,
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
                                          if (value == null || value.isEmpty) {
                                            _titleController.text =
                                                product.title;
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
                                  if (widget.editGiveOrTake == 'giveProducts')
                                    _buildGiveCategoryToggleButtons()
                                  else
                                    _buildTakeCategoryToggleButtons()
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

  /// 나눔페이지의 add페이지 내에서 ToggleButtons 내의 물건, 재능 버튼의 상태를 표시하기 위해 필요한 리스트 변수
  final _selectionsOfGive = List<bool>.generate(2, (_) => false);

  /// 나눔페이지의 add페이지 내에서의 ToggleButtons 위젯(물건, 재능)
  ToggleButtons _buildGiveCategoryToggleButtons() {
    return ToggleButtons(
      color: Colors.black.withOpacity(0.60),
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width * 0.461,
        minHeight: 50,
      ),
      selectedBorderColor: Color(0xffeb6859),
      selectedColor: Color(0xffeb6859),
      fillColor: Color(0xffeb6859).withOpacity(0.10),
      borderRadius: BorderRadius.circular(4.0),
      isSelected: _selectionsOfGive,
      onPressed: (int index) {
        setState(() {
          if (index == 0) {
            print('물건 선택!');
            _selectedFilter = '물건';
            _selectionsOfGive[0] = true;
            _selectionsOfGive[1] = false;
          } else {
            print('재능 선택!');
            _selectedFilter = '재능';
            _selectionsOfGive[0] = false;
            _selectionsOfGive[1] = true;
          }
        });
      },
      children: [
        Text(
          '물건',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NanumSquareRoundR',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          '재능',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NanumSquareRoundR',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        )
      ],
    );
  }

  ///단체 후원 카테고리 추가할 가능성이 있어서 give / take 다른 위젯으로 만들어놓음 (현재 ui는 같은 상태)
  ///
  /// 나눔요청 페이지의 add페이지 내에서 ToggleButtons 내의 물건, 재능 버튼의 상태를 표시하기 위해 필요한 리스트 변수
  final _selectionsOfTake = List<bool>.generate(2, (_) => false);

  /// 나눔요청 페이지의 add페이지 내에서의 ToggleButtons 위젯(물건, 재능)
  ToggleButtons _buildTakeCategoryToggleButtons() {
    return ToggleButtons(
      color: Colors.black.withOpacity(0.60),
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width * 0.461,
        minHeight: 50,
      ),
      selectedBorderColor: Color(0xffeb6859),
      selectedColor: Color(0xffeb6859),
      fillColor: Color(0xffeb6859).withOpacity(0.10),
      borderRadius: BorderRadius.circular(4.0),
      isSelected: _selectionsOfTake,
      onPressed: (int index) {
        setState(() {
          if (index == 0) {
            print('물건 선택!');
            _selectedFilter = '물건';
            _selectionsOfTake[0] = true;
            _selectionsOfTake[1] = false;
          } else {
            print('재능 선택!');
            _selectedFilter = '재능';
            _selectionsOfTake[0] = false;
            _selectionsOfTake[1] = true;
          }
        });
      },
      children: [
        Text(
          '물건',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NanumSquareRoundR',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          '재능',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NanumSquareRoundR',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        )
      ],
    );
  }

}
