import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_room_screen.dart';
import 'profile.dart';

class ChatListScreen extends StatefulWidget {
  final String? selectedUserId;
  const ChatListScreen({super.key, this.selectedUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Text(
            'Please log in to chat.',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.red[900]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: Text(
          'Chats',
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users or chats...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  print('User snapshot error: ${userSnapshot.error}');
                  return Center(
                    child: Text(
                      'Error loading users: ${userSnapshot.error}',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[900]),
                    ),
                  );
                }
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = userSnapshot.data!.docs.where((user) {
                  final data = user.data() as Map<String, dynamic>?;
                  if (data == null) {
                    print('Null user data for user ${user.id}');
                    return false;
                  }
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final email = data['email']?.toString().toLowerCase() ?? '';
                  return user.id != currentUser.uid &&
                      (_searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery));
                }).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: currentUser.uid)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    if (chatSnapshot.hasError) {
                      print('Chat snapshot error: ${chatSnapshot.error}');
                      return Center(
                        child: Text(
                          'Error loading chats: ${chatSnapshot.error}',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[900]),
                        ),
                      );
                    }
                    if (!chatSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = chatSnapshot.data!.docs;
                    final chatUserIds = chats
                        .map((chat) {
                          final data = chat.data() as Map<String, dynamic>?;
                          if (data == null || data['participants'] == null) {
                            print('Invalid chat data for chat ${chat.id}: $data');
                            return '';
                          }
                          final participants = data['participants'] as List<dynamic>;
                          return participants
                              .whereType<String>()
                              .firstWhere(
                                (id) => id != currentUser.uid,
                                orElse: () => '',
                              );
                        })
                        .where((id) => id.isNotEmpty)
                        .toList();

                    final displayUsers = users.where((user) {
                      if (_searchQuery.isEmpty) {
                        return chatUserIds.contains(user.id);
                      }
                      return true;
                    }).toList();

                    if (displayUsers.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No chats yet. Start one!' : 'No users found.',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayUsers.length,
                      itemBuilder: (context, index) {
                        final user = displayUsers[index];
                        final userId = user.id;
                        final userData = user.data() as Map<String, dynamic>?;
                        if (userData == null) {
                          print('Null user data for user $userId');
                          return const SizedBox.shrink();
                        }
                        final userName = userData['name']?.toString() ?? userId;
                        final profilePic = userData['profilePic']?.toString() ?? 'https://picsum.photos/100';

                        // Find chat document
                        QueryDocumentSnapshot<Map<String, dynamic>>? chat;
                        for (var c in chats) {
                          final data = c.data() as Map<String, dynamic>?;
                          if (data == null || data['participants'] == null) {
                            print('Invalid chat data for chat ${c.id}: $data');
                            continue;
                          }
                          final participants = data['participants'] as List<dynamic>;
                          if (participants.contains(userId)) {
                            chat = c as QueryDocumentSnapshot<Map<String, dynamic>>;
                            break;
                          }
                        }

                        final lastMessage = chat?.data()['lastMessage']?.toString() ?? '';
                        final unreadCount = chat?.data()['unreadCount'] is Map
                            ? chat!.data()['unreadCount'][currentUser.uid] ?? 0
                            : 0;

                        final isSelected = widget.selectedUserId == userId;

                        return Card(
                          elevation: isSelected ? 8 : 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isSelected ? Colors.red[100] : Colors.white,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profilePic,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.red,
                                      child: Text(
                                        unreadCount.toString(),
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected || unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                color: Colors.red[900],
                              ),
                            ),
                            subtitle: Text(
                              lastMessage.isNotEmpty ? lastMessage : 'Start a chat',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: isSelected || unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      currentUserId: currentUser.uid,
                                      otherUserId: userId,
                                      otherUserName: userName,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}