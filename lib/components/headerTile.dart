import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Header 타일 - 공지사항용 타일
class HeaderTile extends StatelessWidget {
  /// url_launcher api 함수
  void _launchURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        child: GestureDetector(
          onTap: () => _launchURL('https://flutter.dev'),
          child: Image.network(
              "https://t1.daumcdn.net/thumb/R720x0/?fname=https://t1.daumcdn.net/brunch/service/user/1YN0/image/ak-gRe29XA2HXzvSBowU7Tl7LFE.png"),
        ),
      ),
    );
  }
}
