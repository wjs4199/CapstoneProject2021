import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giveandtake/pages/login.dart';
import 'package:google_sign_in/google_sign_in.dart';

// For Google Sign in
Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final googleUser = await GoogleSignIn().signIn();
  // Obtain the auth details from the request
  final googleAuth = await googleUser.authentication;
  // Create a new credential
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

final _formKey = GlobalKey<FormState>();

void main() => runApp(SignUp1());

class SignUp1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignUp(),
    );
  }
}

class SignUp extends StatefulWidget {
  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  TextEditingController textEditingController1 = TextEditingController();
  TextEditingController textEditingController2 = TextEditingController();
  TextEditingController textEditingController3 = TextEditingController();
  TextEditingController textEditingController4 = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                    hintText: ("Username"),
                    fillColor: Colors.white30,
                    filled: true,
                  ),
                ),
              ),
              Divider(
                color: Colors.white,
                height: 20,
              ),
              ElevatedButton.icon(
                label: Text('Authenticate with Google'),
                icon: Icon(Icons.android),
                onPressed: () {
                // Sign in with Google account,
                // Traditional style (then, catchError) used here
                  signInWithGoogle().then((value) {
                    print('User: ' + value.user.displayName);
                // Display User Info with SnackBar
                // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    //   content: Text('Welcome, ' + value.user.displayName + '!'),
                //   behavior: SnackBarBehavior.fixed,
                //   duration: Duration(seconds: 1),
                // ));
                    Navigator.pop(context);
                  }).catchError((error) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: Text("Login Failed"),
                              content: Text(
                                  "You must complete your\nGoogle sign in procedures."),
                              actions: <Widget>[
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Dismiss"),
                                ),
                              ],
                            ));
                    print('error: $error');
                  });
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.cyan,
                  onPrimary: Colors.white,
                  shadowColor: Colors.black,
                  elevation: 3,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, right: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        print("click actionbutton");


                        /// DB 추가 부분
                        if (_formKey.currentState.validate()) {

                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Processed Data')));

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage()));
                        }
                      },
                      child: Text(
                        'Sign Up',
                      ),
                      style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
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

