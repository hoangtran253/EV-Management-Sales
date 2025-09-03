import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_instagram_clone/util/exception.dart';

class AdminAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<bool> isUserAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get();

      if (doc.exists && doc.data()?['isAdmin'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<bool> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return await isUserAdmin();
    } on FirebaseAuthException catch (e) {
      throw exceptions(e.message ?? 'Login failed');
    }
  }

  Future<void> setAdmin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isAdmin': true});
    } catch (e) {
      throw exceptions('Failed to grant admin role: $e');
    }
  }

  Future<void> removeAdmin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isAdmin': false});
    } catch (e) {
      throw exceptions('Failed to remove admin role: $e');
    }
  }
}
