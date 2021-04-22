import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  String? _img;

  Future signOut() async{
    await _auth.signOut();
  }
  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    //_auth.signOut();
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Status get status => _status;
  User? get user => _user;
  String? get img=>_img;
  FirebaseAuth? get auth =>_auth;

  void Authenticated() {
    _status = Status.Authenticated;
    notifyListeners();
  }

  void Authenticating() {
    _status = Status.Authenticating;
    notifyListeners();
  }

  void Unauthenticated() {
    _status = Status.Unauthenticated;
    notifyListeners();
  }

  void Update() {
    notifyListeners();
  }

  Future _imgFromGallery() async {
    PickedFile? result = await ImagePicker()
        .getImage(source: ImageSource.gallery);
    if (result != null) {
      var user = FirebaseAuth.instance.currentUser;
      await user!.updateProfile(photoURL: result.path);
      notifyListeners();
    }
  }
  void PullProfileImageFromFirestore(userID)  async {
    DocumentSnapshot snapshot;
    Map field;
    CollectionReference database = FirebaseFirestore.instance.collection('PP');
    //---- Retrieval ----
    try {
      snapshot = await database.doc(userID).get();
      field = snapshot.data()!;
      String avatar =  field['Avatar'];
      _img = avatar;
    } catch (e) {
      print(e);
    }

    //avatar =  "https://i.pinimg.com/originals/97/5b/3b/975b3b4ba33ccd5bbcfb37542832d8f7.jpg";
  }

  Future<void> PushProfileImageToFirestore(userID) async {
    if (userID == "") {
      return;
    }
    PickedFile? result = await ImagePicker()
        .getImage(source: ImageSource.gallery);
    CollectionReference database =
    await FirebaseFirestore.instance.collection('PP');
    await database.doc(userID).set({'Avatar': result!.path});
    _img = result.path;
    notifyListeners();
  }


}


Future<void> PullFavoritesFromFirestore(userID,_saved) async {
  List<dynamic> SavedNames = [];
  DocumentSnapshot snapshot;
  Map field;
  CollectionReference database = FirebaseFirestore.instance.collection('Users');
  //---- Retrieval ----
  try {
    snapshot = await database.doc(userID).get();
    field = snapshot.data()!;
    SavedNames = field['SavedNames'];
    for (String s in SavedNames) {
      _saved.add(WordPair(s.substring(0, s.indexOf(',')), s.substring(s.indexOf(',')+1)));
    }
  } catch (e) {}

}

Future<void> PushFavoritesToFirestore(userID,_saved) async {
  try {
    if (userID == "") {
      return;
    }
    List<String> SavedNames = [];
    CollectionReference database =
    await FirebaseFirestore.instance.collection('Users');

    for (WordPair p in _saved) {
      SavedNames.add(
          p.first + "," + p.second); // comma for marker between words
    }
    await database.doc(userID).set({'SavedNames': SavedNames});
  }catch(e){
    print(e);
  }
}








