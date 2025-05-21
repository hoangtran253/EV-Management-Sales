import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_instagram_clone/widgets/post_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
  }

  void _showCommentsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CommentsPopup(
          postId: widget.post['postId'],
          firestore: _firestore,
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
              comment['userImageUrl'] != null &&
                      comment['userImageUrl'].isNotEmpty
                  ? NetworkImage(comment['userImageUrl'])
                  : null,
          child:
              comment['userImageUrl'] == null || comment['userImageUrl'].isEmpty
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
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsPopup extends StatefulWidget {
  final String postId;
  final FirebaseFirestore firestore;

  const CommentsPopup({Key? key, required this.postId, required this.firestore})
    : super(key: key);

  @override
  State<CommentsPopup> createState() => _CommentsPopupState();
}

class _CommentsPopupState extends State<CommentsPopup> {
  late Stream<QuerySnapshot> _commentsStream;
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _localComments = [];

  @override
  void initState() {
    super.initState();
    _commentsStream =
        widget.firestore
            .collection('comments')
            .where('postId', isEqualTo: widget.postId)
            .orderBy('createdAt', descending: true)
            .snapshots();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = {
      'postId': widget.postId,
      'text': text,
      'username': 'CurrentUser', // Replace with actual user info
      'userImageUrl': '', // Replace with actual user avatar URL
      'createdAt': DateTime.now(),
    };

    setState(() {
      _localComments.insert(0, newComment);
    });

    try {
      await widget.firestore.collection('comments').add({
        'postId': widget.postId,
        'text': text,
        'username': 'CurrentUser', // Replace with actual user info
        'userImageUrl': '', // Replace with actual user avatar URL
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      setState(() {
        _localComments.remove(newComment);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment')));
    }
  }

  Widget _buildCommentTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final DateTime? commentDate = timestamp?.toDate();

    final String dateString =
        commentDate != null
            ? '${commentDate.day}/${commentDate.month}/${commentDate.year}'
            : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            data['userImageUrl'] != null && data['userImageUrl'].isNotEmpty
                ? NetworkImage(data['userImageUrl'])
                : null,
        child:
            data['userImageUrl'] == null || data['userImageUrl'].isEmpty
                ? Icon(Icons.person)
                : null,
      ),
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
                    return Center(child: Text('No comments yet'));
                  }
                  return ListView(
                    reverse: true,
                    children:
                        snapshot.data!.docs.map(_buildCommentTile).toList(),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
