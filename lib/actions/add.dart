import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../main.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  // Image picker
  File _image;
  final picker = ImagePicker();

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

  /// Give or Take 선택용 ToggleButtons - 각 버튼용 bool list
  final List<bool> _selectionsOfGiveOrTake = List.generate(2, (_) => false);

  // Input form related
  final _formKey = GlobalKey<FormState>(debugLabel: '_giveAddPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // Storage
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  var user = FirebaseAuth.instance.currentUser;
  var name;

  /// Add 페이지 내에서 give/take 중 무엇을 선택했는지를 담고 있는 변수
  String giveOrTakeCategory;

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
      if (_image != null) uploadFile(_image, value.id);
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
      if (_image != null) uploadFile(_image, value.id);
    }).catchError((error) => print('Error: $error'));
  }

  // Upload photo to storage
  Future<void> uploadFile(File photo, String id) async {
    try {
      await storage.ref('images/' + id + '.png').putFile(photo);
    } on Exception {
      return null;
    }
  }

  final _filter = ['Product', 'Time', 'Talent'];
  var _selectedFilter = 'Product';

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) => Scaffold(
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
          title: Text('Add'),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.save,
                  semanticLabel: 'save',
                ),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    if(giveOrTakeCategory == 'give') {
                      addGiveProduct(
                        _titleController.text,
                        _contentController.text,
                        _selectedFilter,
                      );
                    } else{
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
          child: ListView(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                // height: MediaQuery.of(context).size.height / 2,
                child: _image == null
                    ? Image.asset(
                        'assets/logo.png',
                      )
                    : Image.file(
                        _image,
                        fit: BoxFit.fitWidth,
                      ),
              ),
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
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 8,
                    child: Column(
                      children: [
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
                                        if (value != _selectedFilter)
                                          { _selectedFilter= value;}
                                        setState(() {
                                          _selectedFilter = value;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                  ),
                                  /// 게시물 올릴 카테고리 (give 또는 take) 정하는 토글버튼
                                  _buildToggleButtons(context),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _titleController,
                                      decoration: const InputDecoration(
                                        hintText: 'Title',
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
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _contentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Content',
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
                  Expanded(
                    flex: 1,
                    child: Container(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ToggleButtons _buildToggleButtons(
      BuildContext context) {
    return ToggleButtons(
      color: Colors.black.withOpacity(0.60),
      constraints: BoxConstraints(
        minWidth: 60,
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
        Text('give'),
        Text('take'),
      ],
    );
  }
}