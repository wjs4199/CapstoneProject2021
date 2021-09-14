import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../../main.dart';
import '../home.dart';

Widget NanumView(BuildContext context, ApplicationState appState,
    TabController tabController) {
  return CustomScrollView(
    slivers: <Widget>[
      SliverAppBar(
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            '나눔',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'NanumSquareRoundR',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Color(0xfffc7174),
        pinned: false,
        snap: true,
        floating: true,
        // expandedHeight: 140.0,
        // flexibleSpace: const FlexibleSpaceBar(
        //   background: FlutterLogo(),
        // ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.search,
              semanticLabel: 'search',
            ),
            onPressed: () {},
          ),
        ],
      ),
      SliverStickyHeader(
        header: Container(
          height: 40,
          color: Color(0x80eb6859),
          padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '나눔',
                  style: TextStyle(
                    fontFamily: 'NanumSquareRoundR',
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // 토글버튼 제거
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
                  PostTileMaker(appState.giveProducts[index], true),
                  SizedBox(height: 5),
                  Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                  ),
                ],
              );
            },
            childCount: appState.giveProducts.length,
          ),
        ),
      ),
    ],
  );
}
