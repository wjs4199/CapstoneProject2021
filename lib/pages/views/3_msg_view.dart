import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

Widget MsgView(
    BuildContext context, ApplicationState appState, int selectedIndex) {
  return Text('');
  // return CustomScrollView(
  //     slivers: <Widget>[
  //       SliverAppBar(
  //         title: Text(
  //           '메신저',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontFamily: 'NanumSquareRoundR',
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         backgroundColor: Colors.cyan,
  //         pinned: true,
  //         snap: false,
  //         floating: true,
  //         // expandedHeight: 140.0,
  //         // flexibleSpace: const FlexibleSpaceBar(
  //         //   background: FlutterLogo(),
  //         // ),
  //         actions: <Widget>[
  //           IconButton(
  //             icon: Icon(
  //               Icons.location_on,
  //               semanticLabel: 'location',
  //             ),
  //             onPressed: () {},
  //           ),
  //           ///added
  //           IconButton(
  //             icon: Icon(
  //               Icons.logout,
  //               //semanticLabel: 'location',
  //             ),
  //             onPressed: () {
  //               //  handleSignOut();
  //             },
  //           ),
  //         ],
  //       ),
  //       SliverList(
  //         delegate: SliverChildListDelegate(
  //           [
  //             ///added
  //             IconButton(
  //               icon: Icon(
  //                 Icons.logout,
  //                 //semanticLabel: 'location',
  //               ),
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => Chat(
  //
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //
  //             WillPopScope(
  //               onWillPop: onBackPress,
  //               child: Stack(
  //                 children: <Widget>[
  //                   // List
  //                   Container(
  //                     child: StreamBuilder<QuerySnapshot>(
  //                       stream: FirebaseFirestore.instance.collection('UserName').limit(_limit).snapshots(),
  //                       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
  //                         if (snapshot.hasData) {
  //                           return ListView.builder(
  //                             padding: EdgeInsets.all(10.0),
  //                             itemBuilder: (context, index) => buildItem(context, snapshot.data.docs[index]),
  //                             itemCount: snapshot.data.docs.length,
  //                             controller: listScrollController,
  //                           );
  //                         } else {
  //                           return Center(
  //                             child: CircularProgressIndicator(
  //                               valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
  //                             ),
  //                           );
  //                         }
  //                       },
  //                     ),
  //                   ),
  //
  //                   // Loading
  //                   Positioned(
  //                     child: isLoading ? const Loading() : Container(),
  //                   )
  //                 ],
  //               ),
  //             ),
  //
  //           ],
  //         ),
  //       )
  //     ],
  //   );

// Widget buildItem(BuildContext context, DocumentSnapshot document) {
//   if (document != null) {
//     UserChat userChat = UserChat.fromDocument(document);
//     if (userChat.id == currentUserId) {
//       return SizedBox.shrink();
//     } else {
//       return Container(
//         margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
//         child: TextButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => Chat(
//                   peerId: userChat.id,
//                   peerAvatar: userChat.photoUrl,
//                 ),
//               ),
//             );
//           },
//           style: ButtonStyle(
//             backgroundColor: MaterialStateProperty.all<Color>(greyColor2),
//             shape: MaterialStateProperty.all<OutlinedBorder>(
//               RoundedRectangleBorder(
//                 borderRadius: BorderRadius.all(Radius.circular(10)),
//               ),
//             ),
//           ),
//           child: Row(
//             children: <Widget>[
//               Material(
//                 borderRadius: BorderRadius.all(Radius.circular(25.0)),
//                 clipBehavior: Clip.hardEdge,
//                 child: userChat.photoUrl.isNotEmpty
//                     ? Image.network(
//                   userChat.photoUrl,
//                   fit: BoxFit.cover,
//                   width: 50.0,
//                   height: 50.0,
//                   loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
//                     if (loadingProgress == null) return child;
//                     return Container(
//                       width: 50,
//                       height: 50,
//                       child: Center(
//                         child: CircularProgressIndicator(
//                           color: primaryColor,
//                           value: loadingProgress.expectedTotalBytes != null &&
//                               loadingProgress.expectedTotalBytes != null
//                               ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
//                               : null,
//                         ),
//                       ),
//                     );
//                   },
//                   errorBuilder: (context, object, stackTrace) {
//                     return Icon(
//                       Icons.account_circle,
//                       size: 50.0,
//                       color: greyColor,
//                     );
//                   },
//                 )
//                     : Icon(
//                   Icons.account_circle,
//                   size: 50.0,
//                   color: greyColor,
//                 ),
//               ),
//               Flexible(
//                 child: Container(
//                   margin: EdgeInsets.only(left: 20.0),
//                   child: Column(
//                     children: <Widget>[
//                       Container(
//                         alignment: Alignment.centerLeft,
//                         margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
//                         child: Text(
//                           'Nickname: ${userChat.nickname}',
//                           maxLines: 1,
//                           style: TextStyle(color: primaryColor),
//                         ),
//                       ),
//                       Container(
//                         alignment: Alignment.centerLeft,
//                         margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
//                         child: Text(
//                           'About me: ${userChat.aboutMe}',
//                           maxLines: 1,
//                           style: TextStyle(color: primaryColor),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//   } else {
//     return SizedBox.shrink();
//   }
// }
}
