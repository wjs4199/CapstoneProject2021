/// 0(홈):
// CustomScrollView(
//   physics: const BouncingScrollPhysics(
//       parent: AlwaysScrollableScrollPhysics()),
//   slivers: <Widget>[
//     SliverAppBar(
//       backgroundColor: Colors.cyan,
//       // stretch: true,
//       pinned: false,
//       snap: false,
//       floating: false,
//       expandedHeight: 120.0,
//       flexibleSpace: FlexibleSpaceBar(
//         title: Text(
//           '홈',
//           style: TextStyle(
//             fontSize: 18,
//             fontFamily: 'NanumSquareRoundR',
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         background: Stack(
//           fit: StackFit.expand,
//           children: <Widget>[
//             FlutterLogo(),
//             const DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment(0.0, 0.5),
//                   end: Alignment.center,
//                   colors: <Color>[
//                     Color(0x60000000),
//                     Color(0x00000000),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: <Widget>[
//         IconButton(
//           icon: Icon(
//             Icons.location_on,
//             semanticLabel: 'location',
//           ),
//           onPressed: () {
//             // Navigator.pushNamed(context, '/map');
//           },
//         ),
//       ],
//     ),
//     SliverStickyHeader(
//       header: Container(
//         alignment: Alignment.centerLeft,
//         height: 40,
//         color: Colors.cyan.shade50,
//         padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
//         child: Text(
//           'Notice | 공지사항',
//           style: TextStyle(
//             fontFamily: 'NanumSquareRoundR',
//             fontSize: 16.0,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//       ),
//       sliver: SliverList(
//         delegate: SliverChildListDelegate(
//           [HeaderTile()],
//         ),
//       ),
//     ),
//     SliverStickyHeader(
//       header: Container(
//         height: 40,
//         color: Colors.cyan.shade50,
//         padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 'Give | 나눔 게시판',
//                 style: TextStyle(
//                   fontFamily: 'NanumSquareRoundR',
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//             _buildToggleButtons(context, appState),
//           ],
//         ),
//       ),
//       sliver: SliverList(
//         delegate: SliverChildBuilderDelegate(
//           (BuildContext context, int index) {
//             return Column(
//               children: [
//                 SizedBox(height: 5),
//                 PostTileMaker(
//                     appState.giveProducts[index], _selectedIndex),
//                 SizedBox(height: 5),
//                 Divider(
//                   height: 1,
//                   indent: 12,
//                   endIndent: 12,
//                 ),
//               ],
//             );
//           },
//           childCount: appState.giveProducts.length,
//         ),
//       ),
//     ),
//   ],
// ),

/// 1(나눔):
// CustomScrollView(
//   slivers: <Widget>[
//     SliverAppBar(
//       backgroundColor: Colors.cyan,
//       // stretch: true,
//       pinned: false,
//       snap: false,
//       floating: false,
//       expandedHeight: 120.0,
//       flexibleSpace: FlexibleSpaceBar(
//         title: Text(
//           '나눔',
//           style: TextStyle(
//             fontSize: 18,
//             fontFamily: 'NanumSquareRoundR',
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         background: Stack(
//           fit: StackFit.expand,
//           children: <Widget>[
//             FlutterLogo(),
//             const DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment(0.0, 0.5),
//                   end: Alignment.center,
//                   colors: <Color>[
//                     Color(0x60000000),
//                     Color(0x00000000),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: <Widget>[
//         IconButton(
//           icon: Icon(
//             Icons.location_on,
//             semanticLabel: 'location',
//           ),
//           onPressed: () {
//             // Navigator.pushNamed(context, '/map');
//           },
//         ),
//       ],
//     ),
//     SliverStickyHeader(
//       header: Container(
//         height: 40,
//         color: Colors.cyan.shade50,
//         padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
//         child: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 'Take | 나눔, 도움 요청 게시판',
//                 style: TextStyle(
//                   fontFamily: 'NanumSquareRoundR',
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//             _buildToggleButtons(context, appState),
//           ],
//         ),
//       ),
//       sliver: SliverList(
//         delegate: SliverChildBuilderDelegate(
//           (BuildContext context, int index) {
//             return Column(
//               children: [
//                 SizedBox(height: 5),
//                 PostTileMaker(
//                     appState.takeProducts[index], selectedIndex),
//                 SizedBox(height: 5),
//                 Divider(
//                   height: 1,
//                   indent: 12,
//                   endIndent: 12,
//                 ),
//               ],
//             );
//           },
//           childCount: appState.takeProducts.length,
//         ),
//       ),
//     ),
//   ],
// ),

/// 2(메신저):
// CustomScrollView(
//   slivers: <Widget>[
//     SliverAppBar(
//       title: Text(
//         '메신저',
//         style: TextStyle(
//           fontSize: 18,
//           fontFamily: 'NanumSquareRoundR',
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.cyan,
//       pinned: true,
//       snap: false,
//       floating: true,
//       // expandedHeight: 140.0,
//       // flexibleSpace: const FlexibleSpaceBar(
//       //   background: FlutterLogo(),
//       // ),
//       actions: <Widget>[
//         IconButton(
//           icon: Icon(
//             Icons.location_on,
//             semanticLabel: 'location',
//           ),
//           onPressed: () {},
//         ),
//       ],
//     ),
//     SliverList(
//       delegate: SliverChildListDelegate(
//         [],
//       ),
//     )
//   ],
// ),

/// 3(MyPage):
// CustomScrollView(
//   slivers: <Widget>[
//     SliverAppBar(
//       title: Text(
//         'My',
//         style: TextStyle(
//           fontSize: 18,
//           fontFamily: 'NanumSquareRoundR',
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: Colors.cyan,
//       pinned: true,
//       snap: false,
//       floating: true,
//       // expandedHeight: 140.0,
//       // flexibleSpace: const FlexibleSpaceBar(
//       //   background: FlutterLogo(),
//       // ),
//       actions: <Widget>[
//         IconButton(
//           icon: Icon(
//             Icons.location_on,
//             semanticLabel: 'location',
//           ),
//           onPressed: () {},
//         ),
//       ],
//     ),
//     SliverList(
//       delegate: SliverChildListDelegate(
//         [
//           Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               SizedBox(height: 20.0),
//               CircleAvatar(
//                 radius: 50.0,
//                 backgroundImage:
//                     NetworkImage(photoUrl.replaceAll('s96-c', 's400-c')),
//               ),
//               SizedBox(height: 10.0),
//               Text(
//                 FirebaseAuth.instance.currentUser.displayName,
//                 style: TextStyle(
//                   fontFamily: 'NanumBarunGothic',
//                   fontSize: 20.0,
//                   color: Colors.black87,
//                   // fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'HANDONG GLOBAL UNIVERSITY',
//                 style: TextStyle(
//                   fontFamily: 'Source Sans Pro',
//                   fontSize: 12.0,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.cyan,
//                   letterSpacing: 2.5,
//                 ),
//               ),
//               Text(
//                 FirebaseAuth.instance.currentUser.email,
//                 style: TextStyle(
//                   fontFamily: 'Source Sans Pro',
//                   fontSize: 12.0,
//                   color: Colors.black54,
//                   letterSpacing: 1.5,
//                 ),
//               ),
//               Text(
//                 FirebaseAuth.instance.currentUser.uid,
//                 style: TextStyle(
//                   fontFamily: 'Source Sans Pro',
//                   fontSize: 12.0,
//                   color: Colors.black54,
//                   letterSpacing: 1.5,
//                 ),
//               ),
//               SizedBox(
//                 height: 20.0,
//                 width: 200.0,
//                 child: Divider(
//                   color: Colors.cyan.shade200,
//                 ),
//               ),
//               Card(
//                 margin: EdgeInsets.symmetric(
//                     vertical: 10.0, horizontal: 25.0),
//                 child: ListTile(
//                   leading: Icon(
//                     Icons.phone,
//                     color: Colors.cyan,
//                   ),
//                   title: Text(
//                     '+82 10 9865 7165',
//                     style: TextStyle(
//                         fontSize: 20.0,
//                         color: Colors.cyan.shade900,
//                         fontFamily: 'Source Sans Pro'),
//                   ),
//                 ),
//               ),
//               Card(
//                 margin: EdgeInsets.symmetric(
//                     vertical: 10.0, horizontal: 25.0),
//                 child: ListTile(
//                   leading: Icon(
//                     Icons.location_on,
//                     color: Colors.cyan,
//                   ),
//                   title: Text(
//                     'Pohang, Replublic of Korea',
//                     style: TextStyle(
//                         fontSize: 20.0,
//                         color: Colors.cyan.shade900,
//                         fontFamily: 'Source Sans Pro'),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     )
//   ],
// ),
