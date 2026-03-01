import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_services.dart'; // Import AuthService
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuthException
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final bioController = TextEditingController();
  DateTime? selectedDate;
  String gender = 'Male';
  bool loading = false;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    // Validate all mandatory fields
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        bioController.text.trim().isEmpty ||
        selectedDate == null ||
        gender.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Mandatory fields to be filled'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Use AuthService for signup
      final error = await AuthService().signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        dob: selectedDate!.toIso8601String(),
        gender: gender,
        bio: bioController.text.trim(),
        imageFile: null, // No image upload in this version
      );

      setState(() => loading = false);

      if (error != null) {
        print('Signup error: $error'); // Log the error for debugging
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Get the current user after successful signup
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Store user data in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'dob': selectedDate!.toIso8601String(),
            'gender': gender,
            'bio': bioController.text.trim(),
            'profilePic': 'https://picsum.photos/100', // Default profile picture
          }, SetOptions(merge: true));
          print('Signup: User ${user.uid} data stored in Firestore');
        }

        // Show success message
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('🎉 Signup successful! Redirecting to login...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Delay navigation to ensure SnackBar is visible
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      print('FirebaseAuthException: ${e.code} - ${e.message}'); // Log Firebase error
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => loading = false);
      print('Unexpected error: $e'); // Log unexpected errors
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        appBar: AppBar(
          title: const Text("Sign Up"),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.restaurant_menu, size: 60, color: Colors.red),
              Text(
                "Let's get Cruncchy!",
                style: GoogleFonts.pacifico(
                  fontSize: 28,
                  color: Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.camera_alt, size: 40),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  hintText: "Enter your full name *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "Enter your email *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "Enter your password *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("DOB: "),
                  Text(
                    selectedDate != null
                        ? "${selectedDate!.toLocal()}".split(' ')[0]
                        : "Not selected *",
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: pickDOB,
                    child: const Text("Pick Date"),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: gender,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  hintText: "Tell us about yourself *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: Text(
                          "Loading...",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : const Text("Create Account"),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}