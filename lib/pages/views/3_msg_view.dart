import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

Widget MsgView(
    BuildContext context, ApplicationState appState, int selectedIndex) {
  return CustomScrollView(
    slivers: <Widget>[
      SliverAppBar(
        title: Text(
          '메신저',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'NanumSquareRoundR',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.cyan,
        pinned: true,
        snap: false,
        floating: true,
        // expandedHeight: 140.0,
        // flexibleSpace: const FlexibleSpaceBar(
        //   background: FlutterLogo(),
        // ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.location_on,
              semanticLabel: 'location',
            ),
            onPressed: () {},
          ),
        ],
      ),
      SliverList(
        delegate: SliverChildListDelegate(
          [],
        ),
      )
    ],
  );
}