import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../../main.dart';
import '../home.dart';

Widget NanumView(
    BuildContext context, ApplicationState appState, int selectedIndex) {
  return CustomScrollView(
    slivers: <Widget>[
      SliverAppBar(
        backgroundColor: Colors.cyan,
        // stretch: true,
        pinned: false,
        snap: false,
        floating: false,
        expandedHeight: 120.0,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            '나눔',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'NanumSquareRoundR',
              fontWeight: FontWeight.bold,
            ),
          ),
          background: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FlutterLogo(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.0, 0.5),
                    end: Alignment.center,
                    colors: <Color>[
                      Color(0x60000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.location_on,
              semanticLabel: 'location',
            ),
            onPressed: () {
              // Navigator.pushNamed(context, '/map');
            },
          ),
        ],
      ),
      SliverStickyHeader(
        header: Container(
          height: 40,
          color: Colors.cyan.shade50,
          padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Take | 나눔, 도움 요청 게시판',
                  style: TextStyle(
                    fontFamily: 'NanumSquareRoundR',
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              /// *** 작업중 ***
              // _buildToggleButtons(context, appState),
            ],
          ),
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return Column(
                children: [
                  SizedBox(height: 5),
                  PostTileMaker(appState.takeProducts[index], selectedIndex),
                  SizedBox(height: 5),
                  Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                  ),
                ],
              );
            },
            childCount: appState.takeProducts.length,
          ),
        ),
      ),
    ],
  );
}
