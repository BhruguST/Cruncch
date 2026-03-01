import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class ChatRoomScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ChatRoomScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatId = [widget.currentUserId, widget.otherUserId]..sort();
    final chatDocId = '${chatId[0]}_${chatId[1]}';
    final messageData = {
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    try {
      final batch = FirebaseFirestore.instance.batch();
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatDocId);
      final messageRef = chatRef.collection('messages').doc();

      batch.set(messageRef, messageData);
      batch.set(
        chatRef,
        {
          'participants': chatId,
          'lastMessage': _messageController.text.trim(),
          'unreadCount': {
            widget.currentUserId: 0,
            widget.otherUserId: FieldValue.increment(1),
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e', style: GoogleFonts.poppins())),
        );
      }
    }
  }

  void _markMessagesAsRead() async {
    final chatId = [widget.currentUserId, widget.otherUserId]..sort();
    final chatDocId = '${chatId[0]}_${chatId[1]}';

    try {
      final batch = FirebaseFirestore.instance.batch();
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .where('receiverId', isEqualTo: widget.currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.update(FirebaseFirestore.instance.collection('chats').doc(chatDocId), {
        'unreadCount.${widget.currentUserId}': 0,
      });

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update messages: $e', style: GoogleFonts.poppins())),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = [widget.currentUserId, widget.otherUserId]..sort();
    final chatDocId = '${chatId[0]}_${chatId[1]}';

    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        elevation: 2,
        
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.red[100]!],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatDocId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Message snapshot error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[900]),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients && messages.isNotEmpty) {
                      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                    }
                  });

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String, dynamic>?;
                      if (message == null) return const SizedBox.shrink();
                      final isSentByCurrentUser = message['senderId'] == widget.currentUserId;
                      final timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final formattedTime = DateFormat('MMM d, HH:mm').format(timestamp);

                      return Align(
                        alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSentByCurrentUser ? Colors.red[300] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          child: Column(
                            crossAxisAlignment: isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: isSentByCurrentUser ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isSentByCurrentUser ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(fontSize: 16),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.red, size: 28),
                    onPressed: _sendMessage,
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}