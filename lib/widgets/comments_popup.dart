import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPopup extends StatefulWidget {
  final String postId;
  final FirebaseFirestore firestore;
  final String currentUsername;
  final String currentUserImageUrl;
  final List<Map<String, dynamic>> initialComments; // Danh sách bình luận ban đầu
  final Function(Map<String, dynamic>) onCommentAdded; // Callback khi thêm bình luận

  const CommentsPopup({
    Key? key,
    required this.postId,
    required this.firestore,
    required this.currentUsername,
    required this.currentUserImageUrl,
    this.initialComments = const [],
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentsPopup> createState() => _CommentsPopupState();
}

class _CommentsPopupState extends State<CommentsPopup> {
  late Stream<QuerySnapshot> _commentsStream;
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _localComments = [];
  int _localCommentIdCounter = 0;
  final Map<String, String> _localToServerIdMap = {};

  @override
  void initState() {
    super.initState();
    _commentsStream = widget.firestore
        .collection('comments')
        .where('postId', isEqualTo: widget.postId)
        .orderBy('createdAt', descending: true)
        .snapshots();
    _localComments.addAll(widget.initialComments); // Khởi tạo với danh sách ban đầu
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to comment.')),
      );
      return;
    }

    final localId = 'local_${_localCommentIdCounter++}';
    final newComment = {
      'id': localId,
      'postId': widget.postId,
      'text': text,
      'username': widget.currentUsername,
      'userImageUrl': widget.currentUserImageUrl,
      'createdAt': DateTime.now(),
    };

    setState(() {
      _localComments.insert(0, newComment);
    });
    widget.onCommentAdded(newComment); // Gửi bình luận mới lên PostDetailScreen

    try {
      print('Adding comment to Firestore...');
      final docRef = await widget.firestore.collection('comments').add({
        'postId': widget.postId,
        'text': text,
        'username': widget.currentUsername,
        'userImageUrl': widget.currentUserImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      _localToServerIdMap[localId] = docRef.id;
      _commentController.clear();
      print('Comment added successfully, popup should stay open.');
    } catch (e) {
      setState(() {
        _localComments.removeWhere((c) => c['id'] == localId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
      print('Error adding comment: $e');
    }
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final DateTime? commentDate = comment['createdAt'] is DateTime
        ? comment['createdAt'] as DateTime
        : null;
    final String dateString = commentDate != null
        ? '${commentDate.day}/${commentDate.month}/${commentDate.year}'
        : '';

    return ListTile(
      leading: comment['userImageUrl'] != null && comment['userImageUrl'].isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(comment['userImageUrl']))
          : CircleAvatar(child: Icon(Icons.person)),
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
      subtitle: Text(comment['text'] ?? ''),
    );
  }

  Widget _buildCommentTileFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final DateTime? commentDate = timestamp?.toDate();

    final String dateString = commentDate != null
        ? '${commentDate.day}/${commentDate.month}/${commentDate.year}'
        : '';

    return ListTile(
      leading: data['userImageUrl'] != null && data['userImageUrl'].isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(data['userImageUrl']))
          : CircleAvatar(child: Icon(Icons.person)),
      title: Row(
        children: [
          Text(
            data['username'] ?? 'Unknown',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            dateString,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      subtitle: Text(data['text'] ?? ''),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    if (_localComments.isEmpty) {
                      return Center(child: Text('No comments yet'));
                    } else {
                      return ListView(
                        reverse: true,
                        children: _localComments.map(_buildCommentTile).toList(),
                      );
                    }
                  }
                  final serverComments = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data;
                  }).toList();

                  final filteredLocalComments = _localComments.where((localComment) {
                    final serverHasComment = snapshot.data!.docs.any((doc) {
                      final serverId = doc.id;
                      final localId = localComment['id'] as String?;
                      if (localId != null && _localToServerIdMap[localId] == serverId) {
                        return true;
                      }
                      return false;
                    });
                    return !serverHasComment;
                  }).toList();

                  return ListView(
                    reverse: true,
                    children: [
                      ...filteredLocalComments.map(_buildCommentTile).toList(),
                      ...snapshot.data!.docs.map(_buildCommentTileFromDoc).toList(),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _addComment),
              ],
            ),
          ],
        ),
      ),
    );
  }
}