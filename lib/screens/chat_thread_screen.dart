import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatThreadScreen extends StatefulWidget {
  final String currentUserId;
  final String peerId;
  final String peerName;
  final String category; // 'blood' or 'community'

  const ChatThreadScreen({
    Key? key,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
    this.category = 'blood',
  }) : super(key: key);

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _conversationId {
    final ids = [widget.currentUserId, widget.peerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  void initState() {
    super.initState();
    _ensureConversationDoc();
  }

  Future<void> _ensureConversationDoc() async {
    try {
      final convoRef = FirebaseFirestore.instance.collection('chat_conversations').doc(_conversationId);
      final snap = await convoRef.get();
      final currentName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
      if (!snap.exists) {
        await convoRef.set({
          'participants': [widget.currentUserId, widget.peerId],
          'participantNames': {
            widget.currentUserId: currentName,
            widget.peerId: widget.peerName,
          },
          'participantAvatars': {},
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageSenderId': '',
          'unreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {'category': widget.category},
        }, SetOptions(merge: true));
      } else {
        await convoRef.set({
          'metadata': {'category': widget.category},
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    try {
      final currentName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
      // Write message
      await FirebaseFirestore.instance.collection('direct_messages').add({
        'conversationId': _conversationId,
        'senderId': widget.currentUserId,
        'receiverId': widget.peerId,
        'senderName': currentName,
        'receiverName': widget.peerName,
        'content': text,
        'imageUrl': null,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'readAt': null,
        'messageType': 'text',
        'metadata': null,
      });
      // Update conversation summary
      final convoRef = FirebaseFirestore.instance.collection('chat_conversations').doc(_conversationId);
      await convoRef.set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': widget.currentUserId,
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Scroll down
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('direct_messages')
                  .where('conversationId', isEqualTo: _conversationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList();
                // Sort client-side by timestamp ascending
                docs.sort((a, b) {
                  final aTs = (a.data() as Map<String, dynamic>)['timestamp'];
                  final bTs = (b.data() as Map<String, dynamic>)['timestamp'];
                  final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return aDate.compareTo(bDate);
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;
                    final message = data['content'] ?? '';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 