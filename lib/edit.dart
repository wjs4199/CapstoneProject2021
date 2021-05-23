import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'product.dart';
import 'dart:io';

class EditPage extends StatefulWidget {
  final String productId;
  final String editGiveOrTake;

  EditPage({this.productId, this.editGiveOrTake});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
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
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // Storage
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  // Download image url of each product based on id
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

  // Upload photo to storage
  Future<void> uploadFile(File photo, String id) async {
    try {
      await storage.ref('images/' + id + '.png').putFile(photo);
    } on Exception {
      return null;
    }
  }

  // List of DropdownButton for filtering //
  final _filter = ['Product', 'Time', 'Talent'];
  var _selectedFilter = 'Product';

  Scaffold _buildScaffold(BuildContext context, ApplicationState appState) {
    String productId = this.widget.productId;
    String editGiveOrTake = this.widget.editGiveOrTake;

    CollectionReference target =
        FirebaseFirestore.instance.collection(editGiveOrTake);

    List<Product> products = editGiveOrTake == 'giveProducts'
        ? appState.giveProducts
        : appState.takeProducts;
    Product product;
    String userId = FirebaseAuth.instance.currentUser.uid;
    bool productFound = false;

    for (int i = 0; i < products.length; i++) {
      if (products[i].id == productId) {
        product = products[i];
        productFound = true;
      }
    }

    if (products == null || products.isEmpty || productFound == false) {
      return Scaffold(
        body: CircularProgressIndicator(),
      );
    }

    // Add product in Firestore
    Future<void> editProduct(String category, String title, String content) {
      return target.doc(productId).update({
        'title': title,
        'content': content,
        'category': category,
        'modified': FieldValue.serverTimestamp(),
      }).then((value) {
        if (_image != null) uploadFile(_image, productId);
      }).catchError((error) => print("Error: $error"));
    }

    //원래 바로 밑에 return Scaffold 안에 dorpdownUpdate(value)함수 있는 자리에
    // setState를 바로 넣어서 돌리니까 edit 페이지에서 드롭다운 버튼이 value값에 따라 변하질 않았는데
    // setState를 밖에다가 함수로 만들어서 넣으니까 잘 돌아간다...(왜인지 정확히 모르겠음,,)
    void dorpdownUpdate(value) {
      if (value != _selectedFilter) _selectedFilter = value;
      setState(() {
        _selectedFilter = value;
      });
    }

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
                                      dorpdownUpdate(value);
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplicationState>(
      builder: (context, appState, _) => _buildScaffold(context, appState),
    );
  }
}
