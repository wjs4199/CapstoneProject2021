import 'package:flutter/material.dart';
import 'package:giveandtake/pages/home.dart';
import 'package:giveandtake/pages/login.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();

class SplashPage extends StatefulWidget {
  const SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      // just delay for showing this slash page clearer because it too fast
      checkSignedIn();
    });
  }

  void checkSignedIn() async {
    var isLoggedIn = await googleSignIn.isSignedIn();
    //AuthProvider authProvider = context.read<AuthProvider>();
    //bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      return;
    }
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo2.png',
              width: 120,
              height: 120,
            ),
            SizedBox(height: 20),
            Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
