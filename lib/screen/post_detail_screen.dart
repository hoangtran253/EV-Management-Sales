import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_instagram_clone/widgets/post_widget.dart';
import 'package:flutter_instagram_clone/widgets/comments_popup.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUsername;
  String? _currentUserImageUrl;
  final Map<String, List<Map<String, dynamic>>> _commentsMap = {}; // Lưu bình luận theo postId

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _commentsMap[widget.post['postId'] ?? ''] = []; // Khởi tạo danh sách cho postId hiện tại
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

  void _showCommentsPopup() {
    if (_currentUsername == null || _currentUserImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading user data... Please try again.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CommentsPopup(
          postId: widget.post['postId'] ?? '',
          firestore: _firestore,
          currentUsername: _currentUsername!,
          currentUserImageUrl: _currentUserImageUrl!,
          initialComments: _commentsMap[widget.post['postId'] ?? ''] ?? [],
          onCommentAdded: (newComment) {
            setState(() {
              _commentsMap[widget.post['postId'] ?? '']?.insert(0, newComment);
            });
          },
        );
      },
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final DateTime? commentDate =
        comment['createdAt'] != null
            ? (comment['createdAt'] as Timestamp).toDate()
            : null;

    final String dateString =
        commentDate != null
            ? '${commentDate.day}/${commentDate.month}/${commentDate.year}'
            : '';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundImage:
              comment['userImageUrl'] != null && comment['userImageUrl'].isNotEmpty
                  ? NetworkImage(comment['userImageUrl'])
                  : null,
          child: comment['userImageUrl'] == null || comment['userImageUrl'].isEmpty
              ? Icon(Icons.person)
              : null,
        ),
        title: Row(
          children: [
            Text(
              comment['username'] ?? 'Unknown',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              dateString,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SizedBox(height: 4), Text(comment['text'] ?? '')],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? postDate =
        widget.post['createdAt'] != null
            ? (widget.post['createdAt'] as Timestamp).toDate()
            : null;

    final String dateString =
        postDate != null
            ? '${postDate.day.toString().padLeft(2, '0')}/${postDate.month.toString().padLeft(2, '0')}/${postDate.year} ${postDate.hour.toString().padLeft(2, '0')}:${postDate.minute.toString().padLeft(2, '0')}'
            : '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: Text('Post Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostWidget(
              username: widget.post['username'] ?? 'Unknown',
              caption: widget.post['caption'] ?? '',
              imageUrl: widget.post['imageUrl'] ?? '',
              postTime: dateString,
              avatarUrl: widget.post['avatarUrl'] ?? '',
              onCommentTap: _showCommentsPopup,
            ),
          ],
        ),
      ),
    );
  }
}