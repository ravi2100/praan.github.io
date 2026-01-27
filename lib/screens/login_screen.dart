import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/screens/register_screen.dart';
import 'package:panchayat_mitra/screens/admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginWithEmail = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String email;
      final password = _passwordController.text;
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      UserCredential userCredential;

      if (_isLoginWithEmail) {
        email = _emailController.text;
      } else {
        final mobile = _mobileController.text;
        final users = await firestore
            .collection('users')
            .where('mobile', isEqualTo: mobile)
            .limit(1)
            .get();
        if (users.docs.isEmpty) {
          throw Exception('User not found');
        }
        email = users.docs.first.data()['email'];
      }

      try {
        // Try to sign in first.
        userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException {
        rethrow;
      }

      // For existing users, check if their document exists and create it if not.
      final userDoc = firestore
          .collection('users')
          .doc(userCredential.user!.uid);
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({'email': email, 'role': 'Citizen'});
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to login: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay
          Container(color: Colors.white.withOpacity(0.1)),
          // Login Form
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100), // Adjust spacing as needed
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150, // Adjust the height as needed
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'जिला प्रशासन पाकुड़',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 48), // Adjust spacing as needed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _isLoginWithEmail,
                        onChanged: (value) {
                          setState(() {
                            _isLoginWithEmail = value!;
                          });
                        },
                      ),
                      const Text('Email'),
                      Radio<bool>(
                        value: false,
                        groupValue: _isLoginWithEmail,
                        onChanged: (value) {
                          setState(() {
                            _isLoginWithEmail = value!;
                          });
                        },
                      ),
                      const Text('Mobile'),
                    ],
                  ),
                  if (_isLoginWithEmail)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      style: const TextStyle(color: Colors.black),
                    )
                  else
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register as Citizen',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
