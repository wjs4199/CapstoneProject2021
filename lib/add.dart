import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'main.dart';

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

  // Input form related
  final _formKey = GlobalKey<FormState>(debugLabel: '_AddPageState');
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  // Firestore
  CollectionReference product =
      FirebaseFirestore.instance.collection('giveProducts');

  // Storage
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  // Add product in Firestore
  Future<void> addProduct(String name, int price, String description) {
    return product.add({
      'name': name,
      'price': price,
      'description': description,
      'uid': FirebaseAuth.instance.currentUser.uid,
      'created': FieldValue.serverTimestamp(),
      'modified': FieldValue.serverTimestamp(),
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
                  addProduct(
                    _nameController.text,
                    int.tryParse(_priceController.text),
                    _descController.text,
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
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Product Name',
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
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    // inputFormatters: [
                                    //   FilteringTextInputFormatter.digitsOnly
                                    // ],
                                    decoration: const InputDecoration(
                                      hintText: 'Price',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter your message to continue';
                                      } else if (!(int.tryParse(value)
                                          is int)) {
                                        return 'Enter integer only';
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
                                    controller: _descController,
                                    decoration: const InputDecoration(
                                      hintText: 'Description',
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
                      // Form(
                      //   key: _priceKey,
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         child: TextFormField(
                      //           controller: _priceController,
                      //           keyboardType: TextInputType.number,
                      //           // inputFormatters: [
                      //           //   FilteringTextInputFormatter.digitsOnly
                      //           // ],
                      //           decoration: const InputDecoration(
                      //             hintText: 'Price',
                      //           ),
                      //           validator: (value) {
                      //             if (value == null || value.isEmpty) {
                      //               return 'Enter your message to continue';
                      //             } else if (!(int.tryParse(value) is int)) {
                      //               return 'Enter integer only';
                      //             }
                      //             return null;
                      //           },
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // Form(
                      //   key: _descKey,
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         child: TextFormField(
                      //           controller: _descController,
                      //           decoration: const InputDecoration(
                      //             hintText: 'Description',
                      //           ),
                      //           validator: (value) {
                      //             if (value == null || value.isEmpty) {
                      //               return 'Enter your message to continue';
                      //             }
                      //             return null;
                      //           },
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
