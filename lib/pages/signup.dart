import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:giveandtake/model/user_chat.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';




final _formKey = GlobalKey<FormState>();
TextEditingController textEditingController1 = TextEditingController();

class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;
  bool isLoading = false;
  bool isLoggedIn = false;
  User currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && prefs?.getString('id') != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(currentUserId: prefs.getString('id') ?? "")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }


  Future<UserCredential> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      isLoading = true;
      isLoggedIn = true;
    });

    var googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      var googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      var firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result =
        await FirebaseFirestore.instance.collection('UserName').where('id', isEqualTo: firebaseUser.uid).get();
        final List<DocumentSnapshot> documents = result.docs;
        if (documents.isEmpty) {
          // Update data to server if new user
          await FirebaseFirestore.instance.collection('UserName').doc(firebaseUser.uid).set({
            'uid': firebaseUser.uid,
            'email': firebaseUser.email,
            'photoUrl': firebaseUser.photoURL,
            'username': textEditingController1.text,
            'created': FieldValue.serverTimestamp(),
            'isLogged' : isLoggedIn,
          });
          currentUser = firebaseUser;
          await prefs?.setString('uid', currentUser.uid);
          await prefs?.setString('username', currentUser.displayName ?? "");
          await prefs?.setString('photoUrl', currentUser.photoURL ?? "");
        } else {
          var documentSnapshot = documents[0];
          var userChat = UserChat.fromDocument(documentSnapshot);
          // Write data to local
          await prefs?.setString('uid', userChat.id);
          await prefs?.setString('username', userChat.nickname);
          await prefs?.setString('photoUrl', userChat.photoUrl);
          await prefs?.setString('aboutMe', userChat.aboutMe);
        }
        await Fluttertoast.showToast(msg: "Sign in success");
        setState(() {
          isLoading = false;
        });

       // Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(currentUserId: firebaseUser.uid)));
      } else {
        await Fluttertoast.showToast(msg: "Sign in fail");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      await Fluttertoast.showToast(msg: "Can not init google sign in");
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    //final uid = FirebaseAuth.instance.currentUser.uid;
    //final email =  FirebaseAuth.instance.currentUser.email;
    //bool isLogged = false;
   // CollectionReference signup = FirebaseFirestore.instance.collection("UserName");


    return Material(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  controller: textEditingController1,
                  decoration: InputDecoration(
                    hintText: ("UserName"),
                    fillColor: Colors.white30,
                    filled: true,
                  ),
                ),
              ),


              ElevatedButton.icon(
                label: Text('Sign in with Google'),
                icon: Icon(Icons.android),
                onPressed: ()   async {
                  // Sign in with Google account,
                  // Traditional style (then, catchError) used here



                  await handleSignIn().then((value) {
                    print('User: ' + value.user.displayName);
                   /*
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Authenticated\n',

                        )));

                    */
                    // Display User Info with SnackBar
                    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    //   content: Text('Welcome, ' + value.user.displayName + '!'),
                    //   behavior: SnackBarBehavior.fixed,
                    //   duration: Duration(seconds: 1),
                    // ));


                  });
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.cyan,
                  onPrimary: Colors.white,
                  shadowColor: Colors.black,
                  elevation: 3,
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
                      onPressed: () async {
                        print("click actionbutton");
                       // isLogged = true;

                        if(isLoggedIn){
                          textEditingController1.clear();
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage(currentUserId: prefs.getString('id') ?? "")));



                        }
                        else{
                          await Fluttertoast.showToast(msg: "You should Login with Google");
                        }


                      },
                      style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                      child: Text(
                        '시작하기',
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

/*
    Future <void> createUser (String uid, String email, String username){


      FirebaseFirestore.instance.collection("UserName")
          .add(
          {
            uid: uid,
            email: email,
            username: username,
          }
      );

    }

 */


