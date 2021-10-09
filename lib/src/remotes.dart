import 'package:cloud_firestore/cloud_firestore.dart';

class Remotes {
  Future<void> createUser(String user) async {
    Map<String, dynamic> data = <String, dynamic>{
      "login": user,
    };
    FirebaseFirestore db = FirebaseFirestore.instance;
    db.collection('users').doc(user).set(data);
  }

  Future<void> addLoginCallerToCallee(String callee, String caller) async {
    Map<String, dynamic> data = <String, dynamic>{
      "login": caller,
    };
    FirebaseFirestore db = FirebaseFirestore.instance;
    db
        .collection('users')
        .doc(callee)
        .collection('calls')
        .doc(caller)
        .set(data);
  }
}
