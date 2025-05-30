import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'view_ebook.dart';
import 'payment_page.dart';
import 'admin_dashboard.dart' as admin;
import 'physicalbooks.dart' as physical;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VirtualLibraryApp());
}

class VirtualLibraryApp extends StatelessWidget {
  const VirtualLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/adminDashboard': (context) => admin.AdminDashboard(),
        '/physicalBooks': (context) => physical.PhysicalBooksPage(),
        '/success': (context) => const SuccessPage(),
        '/bookSelection': (context) => const BookSelectionPage(),
        '/library': (context) => EbookListPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
      onGenerateRoute: (settings) => PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _getPage(settings.name),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _getPage(String? routeName) {
    switch (routeName) {
      case '/login':
        return const LoginPage();
      case '/register':
        return const RegisterPage();
      case '/success':
        return const SuccessPage();
      case '/bookSelection':
        return const BookSelectionPage();
      case '/library':
        return EbookListPage();
      case '/physicalBooks':
        return physical.PhysicalBooksPage();
      case '/adminDashboard':
        return admin.AdminDashboard();
      default:
        return const WelcomePage();
    }
  }
}



// Welcome Page




class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login.jpg'), // Ensure the correct path
            fit: BoxFit.cover, // Adjusts the image to cover the screen
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VIRTUAL LIBRARY',
                  style: TextStyle(
                    fontSize: 40, // Increased size
                    fontWeight: FontWeight.bold,
                    color: Color.from(alpha: 1, red: 0.914, green: 0.925, blue: 0.933), // Changed color
                    shadows: [
                      Shadow(
                        blurRadius: 12.0,
                        color: Colors.black45,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'Register Now',
                    style: TextStyle(fontSize: 20), // Increased button text size
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 183, 192, 196), // Changed color for contrast
                  ),
                  child: const Text(
                    'Already a user? LOGIN',
                    style: TextStyle(fontSize: 20), // Slightly increased size
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E-Books")),
      body: const Center(child: Text("Welcome to the E-Books Library!")),
    );
  }
}

class BookSelectionPage extends StatelessWidget {
  const BookSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/library.jpg'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // E-Books Section
                _buildOption(
                  context,
                  "📱 E-Books",
                  "Search for the books and download the E-books you want!",
                  "/library", // Navigate to e-book selection page
                  Colors.purple,
                ),
                const SizedBox(height: 40),

                // Physical Books Section
                _buildOption(
                  context,
                  "📚 Books",
                  "Find the books you are  looking for and rent them!",
                  "/physicalBooks", // Navigate to physical book selection page
                  Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, String title, String quote, String route, Color buttonColor) {
    return Column(
      children: [
        Text(
          quote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black45,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, route),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: buttonColor,
          ),
          child: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ],
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/bookSelection'); // Navigate to Book Selection Page
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 100, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Success!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'You have successfully logged in or registered.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Fetch user role from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        String role = userDoc['role'];

        // Navigate based on role
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => admin.AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuccessPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Failed: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildTextField(String label, {required TextEditingController controller, bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter your $label";
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return "Enter a valid email";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login.jpg'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 320,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.9), // Semi-transparent background
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LOGIN',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Email', controller: _emailController, isEmail: true),
                    const SizedBox(height: 10),
                    _buildTextField('Password', controller: _passwordController, isPassword: true),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('LOGIN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Save the user with role 'user' in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'role': 'user', // Normal users only, admins are manually added
        });

        Navigator.pushNamed(context, '/success'); // Navigate on success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Failed: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/login.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('REGISTER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField('NAME', controller: _nameController),
                    _buildTextField('EMAIL', controller: _emailController, isEmail: true),
                    _buildTextField('PASSWORD', controller: _passwordController, isPassword: true),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('REGISTER'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable TextField
Widget _buildTextField(String label,
    {bool isPassword = false, bool isEmail = false, required TextEditingController controller}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      height: 50,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label is required';
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
          if (isPassword && value.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
      ),
    ),
  );
}
