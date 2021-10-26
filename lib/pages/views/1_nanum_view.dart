import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../home.dart';

Widget NanumView(BuildContext context, ApplicationState appState,
    TabController tabController) {
  return ListView.builder(
    itemCount: appState.giveProducts.length,
    itemBuilder: (BuildContext context, int index) {
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
  );
}

//     CustomScrollView(
//     slivers: <Widget>[
//       SliverAppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         pinned: true,
//         snap: true,
//         floating: true,
//         expandedHeight: 118.0,
//         iconTheme: IconThemeData(color: Colors.black),
//         title: Text(
//           'Pelag',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 28,
//             fontFamily: 'NanumSquareRoundR',
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         flexibleSpace: FlexibleSpaceBar(
//           background: Column(
//             children: <Widget>[
//               SizedBox(height: 60.0),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 16.0),
//                 child: Container(
//                   height: 36.0,
//                   width: double.infinity,
//                   child: CupertinoTextField(
//                     keyboardType: TextInputType.text,
//                     placeholder: '검색',
//                     placeholderStyle: TextStyle(
//                       color: Color(0xffC4C6CC),
//                       fontSize: 16.0,
//                       fontFamily: 'NanumSquareRoundR',
//                     ),
//                     prefix: Padding(
//                       padding: const EdgeInsets.fromLTRB(9.0, 6.0, 9.0, 6.0),
//                       child: Icon(
//                         Icons.search,
//                         color: Color(0xffC4C6CC),
//                       ),
//                     ),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8.0),
//                       color: Color(0xffF0F1F5),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // actions: <Widget>[
//         //   IconButton(
//         //     icon: Icon(
//         //       Icons.forum,
//         //       semanticLabel: 'messenger',
//         //       color: Colors.black,
//         //     ),
//         //     onPressed: () {},
//         //   ),
//         // ],
//       ),
//       SliverStickyHeader(
//         header: Container(
//           height: 35,
//           color: Color(0xffF0F1F5),
//           padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   '나눔',
//                   style: TextStyle(
//                     fontFamily: 'NanumSquareRoundR',
//                     fontSize: 16.0,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//
//               // 토글버튼 제거
//               // _buildToggleButtons(context, appState),
//             ],
//           ),
//         ),
//         sliver: SliverList(
//           delegate: SliverChildBuilderDelegate(
//             (BuildContext context, int index) {
//               return Column(
//                 children: [
//                   SizedBox(height: 5),
//                   PostTileMaker(appState.giveProducts[index], true),
//                   SizedBox(height: 5),
//                   Divider(
//                     height: 1,
//                     indent: 12,
//                     endIndent: 12,
//                   ),
//                 ],
//               );
//             },
//             childCount: appState.giveProducts.length,
//           ),
//         ),
//       ),
//     ],
//   );
// }
