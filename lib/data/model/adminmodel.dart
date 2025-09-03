import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'uid': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('posts').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'postId': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      final QuerySnapshot userPosts =
          await _firestore
              .collection('posts')
              .where('userId', isEqualTo: uid)
              .get();

      for (var doc in userPosts.docs) {
        await _firestore.collection('posts').doc(doc.id).delete();
      }

    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();

      final QuerySnapshot comments =
          await _firestore
              .collection('comments')
              .where('postId', isEqualTo: postId)
              .get();

      for (var doc in comments.docs) {
        await _firestore.collection('comments').doc(doc.id).delete();
      }
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post');
    }
  }

  Future<void> updateUserInfo({
    required String uid,
    String? username,
    String? bio,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
      }

      if (bio != null) {
        updateData['bio'] = bio;
      }

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      if (isActive != null) {
        updateData['isActive'] = isActive;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updateData);
      }
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final userCount = await _firestore.collection('users').count().get();
      final postCount = await _firestore.collection('posts').count().get();

      final DateTime sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
      final recentPosts =
          await _firestore
              .collection('posts')
              .where('createdAt', isGreaterThan: sevenDaysAgo)
              .count()
              .get();

      return {
        'totalUsers': userCount.count,
        'totalPosts': postCount.count,
        'recentPosts': recentPosts.count,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {'totalUsers': 0, 'totalPosts': 0, 'recentPosts': 0};
    }
  }
}
