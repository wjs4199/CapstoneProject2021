import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:giveandtake/components/headerTile.dart';

import '../../main.dart';
import '../home.dart';

Widget HomeView(
    BuildContext context, ApplicationState appState, int selectedIndex) {
  return CustomScrollView(
    physics:
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
            '홈',
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
        // actions: <Widget>[
        //   IconButton(
        //     icon: Icon(
        //       Icons.location_on,
        //       semanticLabel: 'location',
        //     ),
        //     onPressed: () {
        //       // Navigator.pushNamed(context, '/map');
        //     },
        //   ),
        // ],
      ),
      SliverStickyHeader(
        header: Container(
          alignment: Alignment.centerLeft,
          height: 40,
          color: Colors.cyan.shade50,
          padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            '공지사항',
            style: TextStyle(
              fontFamily: 'NanumSquareRoundR',
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            [HeaderTile()],
          ),
        ),
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
                  '나눔 | 최신글',
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
                  PostTileMaker(appState.giveProducts[index], selectedIndex),
                  SizedBox(height: 5),
                  Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                  ),
                ],
              );
            },
            childCount: 4,
          ),
        ),
      ),
      // SliverList(
      //   delegate: SliverChildListDelegate(
      //     [
      //       Container(
      //         height: 40,
      //         child: Text('나눔글 더보기'),
      //       )
      //     ],
      //   ),
      // ),
      SliverStickyHeader(
        header: Container(
          height: 40,
          color: Colors.cyan.shade50,
          padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '나눔요청 | 최신글',
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
            childCount: 4,
          ),
        ),
      ),
    ],
  );
}
