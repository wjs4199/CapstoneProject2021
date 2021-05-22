import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'main.dart';

class giveAddPage extends StatefulWidget {
  @override
  _giveAddPageState createState() => _giveAddPageState();
}

class _giveAddPageState extends State<giveAddPage> {
  // Image picker
  File _image;
  final picker = ImagePicker();

  final _valueList = ['product', 'time', 'talent'];
  var _selectedValue = 'product';

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

  // Input form related
  final _formKey = GlobalKey<FormState>(debugLabel: '_giveAddPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();

  // Firestore
  CollectionReference giveProduct =
      FirebaseFirestore.instance.collection('giveProducts');

  // Storage
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  var user = FirebaseAuth.instance.currentUser;
  var name;

  // Add product in Firestore
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
    }).catchError((error) => print("Error: $error"));
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
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
                  addGiveProduct(
                    _titleController.text,
                    _contentController.text,
                    _selectedFilter,
                  );
                  Navigator.pop(context);
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
                                        _selectedFilter = value;
                                      setState(() {
                                        _selectedFilter = value;
                                      });
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
    );
  }
}

class takeAddPage extends StatefulWidget {
  @override
  _takeAddPageState createState() => _takeAddPageState();
}

class _takeAddPageState extends State<takeAddPage> {
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

  // Input form related
  final _formKey = GlobalKey<FormState>(debugLabel: '_takeAddPageState');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // Firestore
  CollectionReference takeProduct =
      FirebaseFirestore.instance.collection('takeProducts');

  // Storage
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  var user = FirebaseAuth.instance.currentUser;
  var name;

  // Add product in Firestore
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
    }).catchError((error) => print("Error: $error"));
  }

  // Upload photo to storage
  Future<void> uploadFile(File photo, String id) async {
    try {
      await storage.ref('images/' + id + '.png').putFile(photo);
    } on Exception {
      return null;
    }
  }

  //dropdown버튼에 들어가는 항목들
  final _filter = ['Product', 'Time', 'Talent'];
  var _selectedFilter = 'Product';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
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
                  if (_titleController.text != null &&
                      _contentController.text != null) {
                    addTakeProduct(
                      _titleController.text,
                      _contentController.text,
                      _selectedFilter,
                    );
                  }
                  Navigator.pop(context);
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
                            //카테고리 부분 나중에 dropdown selector로 만들면 좋을 듯
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
                                        _selectedFilter = value;
                                      setState(() {
                                        _selectedFilter = value;
                                      });
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
    );
  }
}
