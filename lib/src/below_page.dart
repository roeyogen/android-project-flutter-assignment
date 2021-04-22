import 'dart:io';
import 'dart:ui';

import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/src/UserRepository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:math';

class DefaultGrabbing extends StatelessWidget {
  final Color color;
  final bool reverse;
  final AuthRepository? auth;
  final SnappingSheetController? snappingSheetController;


  const DefaultGrabbing(
      {Key? key, this.color = Colors.grey, this.reverse = false,
        required this.auth, this.snappingSheetController})
      : super(key: key);

  /*BorderRadius _getBorderRadius() {
    var radius = Radius.circular(25.0);
    return BorderRadius.only(
      topLeft: reverse ? Radius.zero : radius,
      topRight: reverse ? Radius.zero : radius,
      bottomLeft: reverse ? radius : Radius.zero,
      bottomRight: reverse ? radius : Radius.zero,
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            spreadRadius: 10,
            color: Colors.black.withOpacity(0.15),
          )
        ],
        //borderRadius: _getBorderRadius(),   //round edges
        color: Colors.grey,

      ),
      child: Transform.rotate(
        angle: reverse ? pi : 0,
        child: Stack(
          children: [
            Align(
              alignment: Alignment(0, 0.5),
              child: ListTile(
                title: Text("Welcome back, "+ auth!.user!.email.toString(),
                    style:TextStyle(fontSize: 18, color: Colors.black)),
                //leading: Icon(Icons.label),
                trailing: IconButton(icon:Icon(Icons.keyboard_arrow_up_sharp,color: Colors.black),
                  onPressed: () {
                    snappingSheetController!.currentPosition>30?
                    snappingSheetController!.setSnappingSheetPosition(26):
                    snappingSheetController!.setSnappingSheetPosition(100);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DummyContent extends StatelessWidget {

  final bool reverse;
  final AuthRepository? auth;
  const DummyContent({Key? key, this.reverse = false, required this.auth} )
      : super(key: key);


  //add here user information
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(builder: (context,auth,_){
      auth.PullProfileImageFromFirestore(auth.user!.uid);
    String? avatar = auth.img;
    return Container(
        color: Colors.white,
        child: ListView(
          children: [
            ListTile(
              title: Column(
                children: [
                  Text(auth.user!.email.toString(),
                      style:TextStyle(fontSize: 18)),
                  _ChangeAvatarButton(auth,context)
                ],
              ),
              leading: Container(
                  width: 90, height: 90,
                  child: avatar != null ? CircleAvatar(backgroundImage: FileImage(File(avatar)), radius: 200.0,) : Text("Avatar image non-existent")
                  ),


            ) //trailing: Icon(Icons.label),
          ],
        ));
  });
}

Widget _ChangeAvatarButton(AuthRepository auth, context){
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      primary: Colors.teal, // background
      onPrimary: Colors.white, // foreground
    ),
    child: Text('Change avatar'),
    onPressed: () async {
      String before = auth.img!;
      auth.PushProfileImageToFirestore(auth.auth!.currentUser!.uid);
      if(auth.img! == before){
        Scaffold.of(context).showSnackBar( SnackBar(
            content: Text('No image selected')
        ));
      }
    },
  );

}}









