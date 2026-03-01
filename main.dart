import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'social_home.dart';
import 'fooder.dart';
import 'profile.dart';
import 'search_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
        scaffoldBackgroundColor: Colors.red[50],
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthWrapper(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const CruncchApp(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Future<User?> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = FirebaseAuth.instance.authStateChanges().first;
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = await _authFuture;
    if (mounted) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/signup');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class CruncchApp extends StatelessWidget {
  const CruncchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final List<Widget> _pages = [
    const Center(child: AnimatedTaglineWidget()),
    const FooderPage(),
    const ProfilePage(),
    const Center(child: Text("🔥 Bite Dares coming soon")),
  ];

  void _onPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CruncchSocialPage(
          restaurantName: 'Sample Restaurant',
          onInvitesSent: _handleInvitesSent,
        ),
      ),
    );
  }

  void _handleInvitesSent(List<String> invites) {
    // Handle the invited users (e.g., show a confirmation)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invited: ${invites.join(", ")}')));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 1,
        backgroundColor: Colors.white,
        title: Stack(
          children: [
            Center(
              child: Text(
                'Cruncch',
                style: GoogleFonts.pacifico(
                  color: Colors.redAccent.shade400,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[50]!, Colors.red[100]!], // Cream-red gradient
          ),
        ),
        child: _pages[_index],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _onPost,
              label: const Text('Cruncch Social'),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (int idx) {
          setState(() {
            _index = idx;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Fooder',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot_rounded),
            label: 'Bite Dares',
          ),
        ],
      ),
    );
  }
}

class AnimatedTaglineWidget extends StatefulWidget {
  const AnimatedTaglineWidget({super.key});

  @override
  State<AnimatedTaglineWidget> createState() => _AnimatedTaglineWidgetState();
}

class _AnimatedTaglineWidgetState extends State<AnimatedTaglineWidget> {
  final List<String> taglines = [
    "Swipe cravings, not dates.",
    "Where every bite is a dare.",
    "Powered by food. Driven by Cruncch.",
    "AI thinks you're hungry... it's right.",
    "Your tastebuds just matched a challenge.",
  ];

  int _currentIndex = 0;
  double _opacity = 1.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTaglineRotation();
  }

  void _startTaglineRotation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() => _opacity = 0.0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % taglines.length;
            _opacity = 1.0;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cookie, size: 64, color: Colors.red),
        const SizedBox(height: 20),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: _opacity,
          child: Text(
            taglines[_currentIndex],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
