import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<String> following = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _loadFollowing();
    }
  }

  Future<void> _loadFollowing() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('following')
        .get();

    setState(() {
      following = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> followUser(String userIdToFollow) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('following')
        .doc(userIdToFollow)
        .set({'followedAt': Timestamp.now()});

    setState(() {
      following.add(userIdToFollow);
    });
  }

  void showUserDetails(DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user['name'] ?? 'User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user['profilePic'] != null && user['profilePic'] != ''
                  ? NetworkImage(user['profilePic'])
                  : null,
              child: (user['profilePic'] == null || user['profilePic'] == '')
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(user['bio'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Chat'),
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to chat screen
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to connect.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connect with Foodies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                final allUsers = snapshot.data!.docs;
                final filtered = allUsers.where((doc) {
                  final isSelf = doc.id == currentUser!.uid;
                  final nameMatches = (doc['name'] ?? '').toLowerCase().contains(searchQuery);
                  return !isSelf && nameMatches;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final isFollowing = following.contains(user.id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profilePic'] != null && user['profilePic'] != ''
                            ? NetworkImage(user['profilePic'])
                            : null,
                        child: (user['profilePic'] == null || user['profilePic'] == '')
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['name'] ?? ''),
                      subtitle: Text(user['bio'] ?? ''),
                      trailing: isFollowing
                          ? IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => showUserDetails(user),
                            )
                          : ElevatedButton(
                              onPressed: () => followUser(user.id),
                              child: const Text("Follow"),
                            ),
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
