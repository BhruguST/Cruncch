import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_list_screen.dart';
import 'profile.dart';
import 'meal_planner.dart';

class CruncchSocialPage extends StatefulWidget {
  final String restaurantName;
  final Function(List<String>) onInvitesSent;

  const CruncchSocialPage({
    super.key,
    required this.restaurantName,
    required this.onInvitesSent,
  });

  @override
  State<CruncchSocialPage> createState() => _CruncchSocialPageState();
}

class _CruncchSocialPageState extends State<CruncchSocialPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _snackVidsSection(context),
      _createPostSection(context),
      MealPlannerPage(restaurantName: widget.restaurantName),
    ];

    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cruncch Social',
          style: GoogleFonts.pacifico(
            fontSize: 28,
            color: Colors.redAccent.shade400,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.red),
            tooltip: 'Chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.red),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.red[100]!],
          ),
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Snack Vids',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Meal Planner',
          ),
        ],
      ),
    );
  }

  Widget _snackVidsSection(BuildContext context) {
    return SizedBox(
      height: 600,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            height: index.isEven ? 200 : 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/200'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.red.withOpacity(0.5)],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white.withOpacity(0.8),
                    size: 40,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Text(
                    '#CruncchBite ${index + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _createPostSection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Share a Cruncch Moment',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red[900],
            ),
          ),
          
          
        ],
      ),
    );
  }
}


