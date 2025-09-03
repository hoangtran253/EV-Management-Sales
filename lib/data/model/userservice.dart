import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_instagram_clone/data/model/usermodel.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> createUser(Usermodel user) async {
    await usersCollection.doc(user.email).set(user.toMap());
  }

  Future<Usermodel?> getUserByEmail(String email) async {
    final doc = await usersCollection.doc(email).get();
    if (doc.exists) {
      return Usermodel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<Usermodel?> getUserById(String id) async {
    final doc = await usersCollection.doc(id).get();
    if (doc.exists) {
      return Usermodel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUser(String email, Map<String, dynamic> data) async {
    await usersCollection.doc(email).update(data);
  }

  Future<List<Usermodel>> getAllUsers() async {
    final snapshot = await usersCollection.get();
    return snapshot.docs
        .map((doc) => Usermodel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
