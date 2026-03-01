// ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
// 1. fooder.dart — ONLY ADDED IMPORT + ONE LINE IN DETAIL PAGE
// ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tcard/tcard.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart'; // ←← NEW IMPORT
import 'restaurant_3d_view.dart';

class FooderPage extends StatefulWidget {
  const FooderPage({super.key});
  @override
  State<FooderPage> createState() => _FooderPageState();
}

class _FooderPageState extends State<FooderPage> {
  List<Map<String, dynamic>> allRestaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  List<String> allCuisines = [];
  String selectedCuisine = 'Explore';
  late TCardController _tCardController;

  final TextEditingController _searchController = TextEditingController();

  final Map<String, IconData> cuisineIcons = {
    'Explore': Icons.explore,
    'Unknown': Icons.restaurant,
  };

  @override
  void initState() {
    super.initState();
    _tCardController = TCardController();
    loadRestaurantData();

    _searchController.addListener(() {
      filterByCuisine(selectedCuisine);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadRestaurantData() async {
    try {
      final String data = await rootBundle.loadString('assets/output.json');
      final List<dynamic> jsonResult = json.decode(data);
      final Set<String> cuisineSet = {};

      for (var item in jsonResult) {
        if (item['cuisines'] != null && item['cuisines'] is List) {
          List<String> cuisines = List<String>.from(item['cuisines']);
          cuisineSet.addAll(cuisines);
        }
      }

      setState(() {
        allRestaurants = jsonResult.cast<Map<String, dynamic>>();
        filteredRestaurants = List.from(allRestaurants);
        allCuisines = ['Explore', ...cuisineSet.toList()..sort()];
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void filterByCuisine(String cuisine) {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      selectedCuisine = cuisine;

      List<Map<String, dynamic>> temp = allRestaurants;

      if (query.isNotEmpty) {
        temp = temp.where((r) {
          final name = (r['restaurant'] ?? '').toString().toLowerCase();
          final location = (r['location'] ?? '').toString().toLowerCase();
          final cuisinesList = r['cuisines'] is List
              ? (r['cuisines'] as List)
                    .map((c) => c.toString().toLowerCase())
                    .join(' ')
              : '';
          return name.contains(query) ||
              location.contains(query) ||
              cuisinesList.contains(query);
        }).toList();
      }

      if (cuisine != 'Explore') {
        temp = temp.where((r) {
          final cuisines = r['cuisines'];
          return cuisines != null &&
              cuisines is List &&
              cuisines.contains(cuisine);
        }).toList();
      }

      filteredRestaurants = temp;

      _tCardController.reset(
        cards: filteredRestaurants.map((r) => _buildCard(r)).toList(),
      );
    });
  }

  Widget _buildCard(Map<String, dynamic> restaurant) {
    final imageUrl =
        (restaurant['image'] != null &&
            restaurant['image'].toString().isNotEmpty)
        ? restaurant['image']
        : 'https://via.placeholder.com/400x300?text=No+Image';

    final cuisineText =
        (restaurant['cuisines'] != null && restaurant['cuisines'] is List)
        ? (restaurant['cuisines'] as List<dynamic>).join(', ')
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 80),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.54),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['restaurant'] ?? 'Unnamed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cuisineText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSwipe(int index, SwipInfo info) {
    if (info.direction == SwipDirection.Right) {
      final swipedIndex = index - 1;
      if (swipedIndex >= 0 && swipedIndex < filteredRestaurants.length) {
        final swipedRestaurant = filteredRestaurants[swipedIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailPage(restaurant: swipedRestaurant),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search restaurants, location, cuisine...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "Choose Your Cuisine",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: allCuisines.map((cuisine) {
                    return GestureDetector(
                      onTap: () => filterByCuisine(cuisine),
                      child: Chip(
                        avatar: Icon(
                          cuisineIcons[cuisine] ?? Icons.restaurant,
                          size: 18,
                          color: selectedCuisine == cuisine
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        label: Text(
                          cuisine,
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedCuisine == cuisine
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        backgroundColor: selectedCuisine == cuisine
                            ? Colors.red[400]
                            : Colors.grey[200],
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(thickness: 1.5),
            Expanded(
              flex: 5,
              child: filteredRestaurants.isEmpty
                  ? Center(
                      child: Text(
                        "No restaurants found",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : TCard(
                      controller: _tCardController,
                      size: const Size(350, 460),
                      cards: filteredRestaurants
                          .map((r) => _buildCard(r))
                          .toList(),
                      onForward: _onSwipe,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
// 2. RestaurantDetailPage — ONLY ADDED 3 NEW BUTTONS + MENU + QR
// ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
class RestaurantDetailPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> hardcodedMenu = [
    {"name": "Grilled Prawns", "price": 649},
    {"name": "Tandoori Chicken", "price": 499},
    {"name": "Mutton Seekh Kebab", "price": 579},
    {"name": "Paneer Tikka", "price": 429},
    {"name": "Veg Platter", "price": 399},
    {"name": "Chicken Biryani", "price": 529},
    {"name": "Veg Biryani", "price": 399},
    {"name": "Dal Makhani", "price": 349},
    {"name": "Butter Naan", "price": 89},
    {"name": "Cold Drinks", "price": 79},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(String location) async {
    final String query = Uri.encodeComponent(location);
    final List<String> androidUrls = [
      "geo:0,0?q=$query", // Opens Google Maps directly
      "https://www.google.com/maps/search/?api=1&query=$query", // Fallback web link
    ];

    bool launched = false;

    for (final url in androidUrls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!launched) {
      // Final fallback: show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please install or open Google Maps app")),
      );
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 6,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(bottom: 20),
              ),
              Text(
                "Menu",
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: hardcodedMenu.length,
                  itemBuilder: (_, i) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        hardcodedMenu[i]['name'],
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: Text(
                        "₹${hardcodedMenu[i]['price']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
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

  void _reserveTable() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Reserve Table",
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                items:
                    ["Table for 2", "Table for 4", "Table for 6", "Table for 8"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (_) {},
                decoration: const InputDecoration(
                  labelText: "Select Table",
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Table Reserved Successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Confirm Booking",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentQR() {
    final name = widget.restaurant['restaurant'] ?? "Restaurant";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Pay Bill - $name",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data:
                  "UPI://pay?pa=cruncchh@upi&pn=${Uri.encodeComponent(name)}&am=999&cu=INR",
              size: 220,
            ),
            const SizedBox(height: 20),
            Text(
              "Scan with any UPI app",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              "₹999",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        (widget.restaurant['image'] != null &&
            widget.restaurant['image'].toString().isNotEmpty)
        ? widget.restaurant['image']
        : 'https://via.placeholder.com/400x300?text=No+Image';

    final location = widget.restaurant['location'] ?? 'Unknown location';
    final rating = widget.restaurant['rating']?.toStringAsFixed(1) ?? 'N/A';
    final cuisines = (widget.restaurant['cuisines'] is List)
        ? (widget.restaurant['cuisines'] as List).join(', ')
        : 'Unknown';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.restaurant['restaurant'] ?? 'Restaurant',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurant['restaurant'] ?? 'Unnamed',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.red[300],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cuisines,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$rating / 5',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // RESPONSIVE BUTTON GRID — NO OVERFLOW EVER
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth > 500;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: isWide ? 4 : 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isWide ? 3.5 : 2.8,
                              children: [
                                _actionButton(
                                  "View Menu",
                                  Icons.menu_book,
                                  Colors.orange[700]!,
                                  _showMenu,
                                ),
                                _actionButton(
                                  "Reserve Table",
                                  Icons.table_restaurant,
                                  Colors.green[700]!,
                                  _reserveTable,
                                ),
                                _actionButton(
                                  "Pay Bill",
                                  Icons.qr_code_2,
                                  Colors.black,
                                  _showPaymentQR,
                                ),
                                _actionButton(
                                  "Open in Maps",
                                  Icons.map,
                                  Colors.red[600]!,
                                  () => _launchMaps(location),
                                ),
                                _actionButton(
                                  "3D View",
                                  Icons.view_in_ar,
                                  Colors.purple[800]!,
                                  () {
                                    ;
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                            ),
                            label: const Text(
                              "Back to Swiping",
                              style: TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
      label: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}
