import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MealPlannerPage extends StatefulWidget {
  final String restaurantName;

  const MealPlannerPage({super.key, required this.restaurantName});

  @override
  State<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMealPlanningForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => MealPlanningForm(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Meal Planner',
                  style: GoogleFonts.pacifico(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD32F2F),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('meal_plans').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.pacifico(fontSize: 18, color: const Color(0xFFD32F2F)),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No meal plans yet',
                            style: GoogleFonts.pacifico(fontSize: 18, color: Colors.grey[700]),
                          ),
                        );
                      }

                      final mealPlans = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: mealPlans.length,
                        itemBuilder: (context, index) {
                          final plan = mealPlans[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFF8BBD0), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF8BBD0),
                                child: Icon(Icons.restaurant, color: Color(0xFFD32F2F), size: 24),
                              ),
                              title: Text(
                                plan['restaurant'] ?? 'Unknown',
                                style: GoogleFonts.pacifico(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM dd, yyyy').format(plan['date'].toDate())} at ${plan['time']}',
                                style: GoogleFonts.pacifico(fontSize: 16, color: Colors.grey[700]),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Color(0xFFD32F2F), size: 24),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _openMealPlanningForm,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Create New Plan',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealPlanningForm extends StatefulWidget {
  final ScrollController controller;

  const MealPlanningForm({super.key, required this.controller});

  @override
  _MealPlanningFormState createState() => _MealPlanningFormState();
}

class _MealPlanningFormState extends State<MealPlanningForm> with SingleTickerProviderStateMixin {
  final TextEditingController _searchRestaurantController = TextEditingController();
  final TextEditingController _searchUserController = TextEditingController();
  String _restaurantQuery = '';
  String _userQuery = '';
  List<dynamic> restaurants = [];
  List<dynamic> filteredRestaurants = [];
  Map<String, bool> selectedUsers = {};
  String? selectedRestaurant;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _searchRestaurantController.addListener(() {
      setState(() {
        _restaurantQuery = _searchRestaurantController.text.toLowerCase();
        _filterRestaurants();
      });
    });
    _searchUserController.addListener(() {
      setState(() {
        _userQuery = _searchUserController.text.toLowerCase();
      });
    });
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  Future<void> _loadRestaurants() async {
    try {
      final String response = await rootBundle.loadString('assets/output.json');
      setState(() {
        restaurants = json.decode(response);
        filteredRestaurants = restaurants;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restaurants: $e')),
        );
      }
    }
  }

  void _filterRestaurants() {
    setState(() {
      filteredRestaurants = restaurants.where((restaurant) {
        final name = restaurant['restaurant']?.toString().toLowerCase() ?? '';
        return _restaurantQuery.isEmpty || name.contains(_restaurantQuery);
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD32F2F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD32F2F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _createMealPlan() async {
    if (selectedRestaurant == null || selectedDate == null || selectedTime == null || selectedUsers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields and select users')),
        );
      }
      return;
    }

    final invitedUsers = selectedUsers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final mealPlan = {
      'restaurant': selectedRestaurant,
      'date': Timestamp.fromDate(selectedDate!),
      'time': selectedTime!.format(context),
      'invitedUsers': invitedUsers,
      'createdAt': Timestamp.now(),
      'createdBy': FirebaseFirestore.instance.collection('users').doc().id,
    };

    try {
      await FirebaseFirestore.instance.collection('meal_plans').add(mealPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meal plan created for $selectedRestaurant')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating meal plan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchRestaurantController.dispose();
    _searchUserController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.controller,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Your Meal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchRestaurantController,
              decoration: InputDecoration(
                labelText: 'Search Restaurant',
                labelStyle: const TextStyle(color: Color(0xFFD32F2F)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD32F2F)),
                filled: true,
                fillColor: const Color(0xFFFCE4EC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 15),
            if (_restaurantQuery.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];
                    final isSelected = selectedRestaurant == restaurant['restaurant'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRestaurant = restaurant['restaurant'];
                          });
                          _controller.forward(from: 0);
                        },
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSelected ? 1.05 : 1.0,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFD32F2F) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Container(
                                  width: 140,
                                  padding: const EdgeInsets.all(10),
                                  color: const Color(0xFFFCE4EC),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: restaurant['image'] ?? 'https://via.placeholder.com/100',
                                        height: 80,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFD32F2F)),
                                        errorWidget: (context, url, error) => const Icon(Icons.error, color: Color(0xFFD32F2F)),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        restaurant['restaurant'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? const Color(0xFFD32F2F) : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchUserController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                labelStyle: const TextStyle(color: Color(0xFFD32F2F)),
                prefixIcon: const Icon(Icons.person_search, color: Color(0xFFD32F2F)),
                filled: true,
                fillColor: const Color(0xFFFCE4EC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 15),
            _userQuery.isNotEmpty
                ? SizedBox(
                    height: 150,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(fontSize: 18, color: Color(0xFFD32F2F)),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                            ),
                          );
                        }

                        final users = snapshot.data!.docs.where((user) {
                          final name = user['name']?.toString().toLowerCase() ?? '';
                          return name.contains(_userQuery);
                        }).toList();

                        for (var user in users) {
                          if (!selectedUsers.containsKey(user.id)) {
                            selectedUsers[user.id] = false;
                          }
                        }

                        if (users.isEmpty) {
                          return Center(
                            child: Text(
                              'No matching users',
                              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFFF8BBD0), width: 1),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user['profilePic'] ?? 'https://picsum.photos/100',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFD32F2F)),
                                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Color(0xFFD32F2F)),
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: selectedUsers[user.id] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedUsers[user.id] = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFFD32F2F),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                : SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'Search users to invite',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(selectedDate!),
                      style: const TextStyle(fontSize: 18, color: Color(0xFFD32F2F)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectTime(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      selectedTime == null ? 'Select Time' : selectedTime!.format(context),
                      style: const TextStyle(fontSize: 18, color: Color(0xFFD32F2F)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _createMealPlan,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  'Save Plan',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}