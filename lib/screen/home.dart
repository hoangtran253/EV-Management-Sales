import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/widgets/post_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_instagram_clone/widgets/comments_popup.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUsername;
  String? _currentUserImageUrl;
  final Map<String, List<Map<String, dynamic>>> _commentsMap = {}; // Lưu bình luận theo postId

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUsername = userData['username'] ?? 'Unknown';
          _currentUserImageUrl = userData['avatarUrl'] ?? '';
        });
      }
    }
  }

  void _showCommentsPopup(String postId) {
    if (_currentUsername == null || _currentUserImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading user data... Please try again.')),
      );
      return;
    }

    if (!_commentsMap.containsKey(postId)) {
      _commentsMap[postId] = []; // Khởi tạo danh sách cho postId nếu chưa có
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CommentsPopup(
          postId: postId,
          firestore: _firestore,
          currentUsername: _currentUsername!,
          currentUserImageUrl: _currentUserImageUrl!,
          initialComments: _commentsMap[postId] ?? [],
          onCommentAdded: (newComment) {
            setState(() {
              _commentsMap[postId]?.insert(0, newComment);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(55.h),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: Image.asset('images/camera.png', width: 25.w),
            onPressed: () {},
          ),
          title: Image.asset('images/instagram.png', height: 30.h),
          actions: [
            IconButton(
              icon: Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: Image.asset('images/send.png', width: 24.w),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('posts').orderBy('postTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              final DateTime? postDate = post['postTime'] != null
                  ? (post['postTime'] as Timestamp).toDate()
                  : null;
              final String dateString = postDate != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(postDate)
                  : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

              return PostWidget(
                username: post['username'] ?? 'Unknown',
                caption: post['caption'] ?? '',
                imageUrl: post['imageUrl'] ?? '',
                postTime: dateString,
                avatarUrl: post['avatarUrl'] ?? '',
                onCommentTap: () => _showCommentsPopup(postId),
              );
            },
          );
        },
      ),
    );
  }
}