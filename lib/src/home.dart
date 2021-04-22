import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:hello_me/src/UserRepository.dart';
import 'package:hello_me/src/below_page.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:provider/provider.dart';

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  var _saved = Set<WordPair>();
  AuthRepository? _auth;
  bool loggedIn = false;
  String userID = "";
  String userEmail = "";

  final ScrollController _scrollController = ScrollController();
  final SnappingSheetController _snappingSheetController = SnappingSheetController();


  @override
  Widget build(BuildContext context) {
    bool moved = false;
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          Consumer<AuthRepository>(builder: (context,auth,_)=>IconButton(
              icon: loggedIn ? Icon(Icons.exit_to_app) : Icon(Icons.login),
              onPressed:() {loggedIn ? signOut(auth) : _loginScreen();})),
        ],
      ),
      body: loggedIn ? SnappingSheet(
        controller: _snappingSheetController,
        lockOverflowDrag: true,
        snappingPositions: [
          SnappingPosition.factor(
            positionFactor: 0.0,
            grabbingContentOffset: GrabbingContentOffset.top,
          ),
          SnappingPosition.factor(
            snappingCurve: Curves.elasticOut,
            snappingDuration: Duration(milliseconds: 1750),
            positionFactor: 0.5,
          ),
          SnappingPosition.factor(positionFactor: 0.9),
        ],
        grabbingHeight: 55,
        grabbing: Consumer<AuthRepository>(builder: (context,auth,_)=>DefaultGrabbing(auth: auth,snappingSheetController: _snappingSheetController)),
        child:_buildSuggestions(),
        sheetBelow: SnappingSheetContent(
          childScrollController: _scrollController,
          draggable: true,
          child: Consumer<AuthRepository>(builder: (context,auth,_)=>DummyContent(
            auth: auth,
          )),
        ),
      ): _buildSuggestions(),
    );
  }

  void _loginScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Consumer<AuthRepository>(builder: (context,auth,_){
            final isLoggingIn = auth.status;
            final nameController = TextEditingController();
            final passwordController = TextEditingController();
            final passwordValidator = TextEditingController();
            return Scaffold(
              appBar: AppBar(
                title: Text('Login'),
              ),
              body: ListView(children: [
                _StartupMessageContainer(),
                _emailInputContainer(nameController),
                _passwordInputContainer(passwordController),

                isLoggingIn == Status.Authenticating
                    ? Center(child: CircularProgressIndicator())
                    : Container(
                  padding: EdgeInsets.all(10),
                  child: _loginButton(nameController,passwordController),
                ),
                Container(
                    padding: EdgeInsets.all(10),
                    child: _modalButton(nameController,passwordController,passwordValidator)
                )
              ]),
            );
          },
        );
    })
    );
  }

  void _pushSaved()  {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          Provider.of<AuthRepository>(context);
          if (_saved.isEmpty) { // if no names are selected
            return Scaffold(
                appBar: AppBar(
                  title: Text('Saved Suggestions'),
                ),
                body: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'No Favorites saved',
                      style: TextStyle(fontSize: 19),
                    )));
          }
          final tiles = _saved.map(
                (WordPair pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
                trailing: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                onTap: () {
                  _saved.remove(pair);
                  PushFavoritesToFirestore(userID,_saved);

                  setState(() {
                    Provider.of<AuthRepository>(context, listen: false).Update();
                  });
                },
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  void _tryToSignUp(String user_email, String user_password,bool userExists,FirebaseAuth _auth) async{
    try {
      await _auth.createUserWithEmailAndPassword(
          email: user_email, password: user_password);
      userExists = true;
    } catch (e) {}
    if (userExists) {
      loggedIn = true;
      userID = _auth.currentUser!.uid;
      userEmail = _auth.currentUser!.email!;
      await PullFavoritesFromFirestore(userID,_saved);
      await PushFavoritesToFirestore(userID,_saved);
      Provider.of<AuthRepository>(context, listen: false)
          .Authenticated();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      setState(() {
      });
    } else {
      userID = "";
      userEmail = "";
      final snackBar = SnackBar(
          content:
          Text("There was an error logging into the app"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Provider.of<AuthRepository>(context, listen: false)
          .Unauthenticated();
    }
  }

  void _tryToLogin(String user_email, String user_password,bool userExists,FirebaseAuth _auth) async{

    try {
      await _auth.signInWithEmailAndPassword(
          email: user_email, password: user_password);
      userExists = true;
    } catch (e) {
      print(e);
    }

    if (userExists) {
      loggedIn = true;
      userID = _auth.currentUser!.uid;
      userEmail = _auth.currentUser!.email!;
      await PullFavoritesFromFirestore(userID,_saved);
      await PushFavoritesToFirestore(userID,_saved);


      Provider.of<AuthRepository>(context, listen: false)
          .Authenticated();
      Navigator.of(context).pop();
      setState(() {
      });
    } else {
      userID = "";
      userEmail = "";
      final snackBar = SnackBar(
          content:
          Text("There was an error logging into the app"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Provider.of<AuthRepository>(context, listen: false)
          .Unauthenticated();
    }
  }



  Future<Widget> signOut(AuthRepository auth) async {
    await PushFavoritesToFirestore(userID,_saved);
    _saved = {};
    final res = await auth.signOut();
    loggedIn = false;
    userID = "";
    userEmail = "";
    setState(() {
      _loginScreen();
    });
    return res;
  }

  Widget _StartupMessageContainer() {
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(10),
        child: Text(
          'Welcome to Startup Names Generator, please log in below',
          style: TextStyle(fontSize: 20),
        ));
  }

  Widget _emailInputContainer(TextEditingController nameController){
    return Container(
      padding: EdgeInsets.all(10),
      child: TextField(
        controller: nameController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Email',
        ),
      ),
    );
  }

  Widget _passwordInputContainer(TextEditingController passwordController){
    return Container(
      padding: EdgeInsets.all(10),
      child: TextField(
        obscureText: true,
        controller: passwordController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Password',
        ),
      ),
    );
  }

  Widget _passwordValidatorContainer(TextEditingController passwordValidator,TextEditingController passwordController){
    return Container(
      padding: EdgeInsets.all(10),
      child: TextField(
        obscureText: true,
        controller: passwordValidator,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Password',
          errorText: passwordValidator.text==passwordController.text || passwordValidator.text=="" ? null : 'Passwords mush match',
        ),
      ),
    );
  }

  Widget _loginButton(TextEditingController nameController,TextEditingController passwordController){
    return Consumer<AuthRepository>(builder: (context,auth,_) {
      return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Colors.red, // background
        onPrimary: Colors.white, // foreground
        shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(30.0),
        ),
      ),
      child: Text('Log in'),
      onPressed: () {
        //_tryToLogin(nameController,passwordController,_auth);
        Provider.of<AuthRepository>(context, listen: false)
            .Authenticating();
        String user_email = nameController.text;
        String user_password = passwordController.text;
        bool userExists = false;
        FocusScope.of(context).unfocus();

        _tryToLogin(user_email,user_password,userExists,auth.auth!);
      }
    );});
  }

  Widget _signupButton(TextEditingController nameController,TextEditingController passwordController,TextEditingController passwordValidator){
    return Consumer<AuthRepository>(builder: (context,auth,_) {return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Colors.teal, // background
        onPrimary: Colors.white, // foreground
      ),
      child: Text('Confirm'),
      onPressed: () {
        String user_email = nameController.text;
        String user_password = passwordController.text;
        String password_renter = passwordValidator.text;
        bool userExists = false;
        FocusScope.of(context).unfocus();

        if(user_password==password_renter){
          _tryToSignUp(user_email, user_password, userExists, auth.auth!);
        }else{
          setState(() {
          });
        }
      },
    );});;
  }

  Widget _modalButton(TextEditingController nameController,TextEditingController passwordController,TextEditingController passwordValidator){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Colors.teal, // background
        onPrimary: Colors.white, // foreground
        shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(30.0),
        ),
      ),
      child: Text('New user? Click to sign up'),
      onPressed:(){
        showModalBottomSheet<dynamic>(
          isScrollControlled: true,
          context: context,
          builder: (context){
            return Wrap(
                alignment: WrapAlignment.center,
                children: [
                    Text("Please confirm your password below",
                        style:TextStyle(fontSize: 18)),
                    _passwordValidatorContainer(passwordValidator,passwordController),
                    _signupButton(nameController,passwordController,passwordValidator)
                  ],
            );

          },
        );
      },
    );
  }


  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            PushFavoritesToFirestore(userID,_saved);
          } else {
            _saved.add(pair);
            PushFavoritesToFirestore(userID,_saved);
          }
        });
      },
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

}

/*

class BlurFilter extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final SnappingSheetController snappingSheetController;

  BlurFilter({required this.child,required this.snappingSheetController,this.sigmaX = 5.0, this.sigmaY = 5.0});

  @override
  Widget build(BuildContext context) {
    if(snappingSheetController.isAttached && snappingSheetController.currentPosition >30){
      return Stack(
        children: <Widget>[
          child,
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: sigmaX,
                sigmaY: sigmaY,
              ),
              child: Opacity(
                opacity: 0.01,
                child: child,
              ),
            ),
          ),
        ],
      );
    }
    return child;
  }
}
*/
