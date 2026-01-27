import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/data/block_credentials.dart';
import 'package:panchayat_mitra/data/locations.dart';
import 'package:panchayat_mitra/data/panchayat_credentials.dart';
import 'package:panchayat_mitra/screens/home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole = 'Panchayat Admin';
  String? _selectedBlock;
  String? _selectedPanchayat;
  List<String> _blocks = [];
  List<String> _panchayats = [];
  bool _isLoading = false;
  String? _selectedBlockAdmin;
  final List<String> _roles = [
    'Super Admin',
    'District Admin',
    'Block Admin',
    'Panchayat Admin',
  ];

  @override
  void initState() {
    super.initState();
    _blocks = locationData.keys.toList();
  }

  void _onBlockSelected(String? block) {
    if (block != null && locationData.containsKey(block)) {
      setState(() {
        _selectedBlock = block;
        _panchayats = locationData[block]!;
        _selectedPanchayat = null; // Reset panchayat selection
      });
    }
  }

  @override
  Future<void> _login() async {
    print('Login button pressed');
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedRole == null ||
        (_selectedRole == 'Panchayat Admin' &&
            (_selectedBlock == null || _selectedPanchayat == null))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Only try to sign in. Do not create a new user.
      await auth.signInWithEmailAndPassword(email: email, password: password);

      // For existing users, check if their document exists and create it if not.
      final userDoc = firestore.collection('users').doc(auth.currentUser!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        final userData = {'email': email, 'role': _selectedRole};
        if (_selectedRole == 'Panchayat Admin') {
          userData['block'] = _selectedBlock!;
          userData['panchayat'] = _selectedPanchayat!;
        } else if (_selectedRole == 'Block Admin') {
          userData['block'] = _selectedBlockAdmin!;
        }
        await userDoc.set(userData);
      } else {
        // If the document exists, update it with the latest role and location info.
        final Map<String, dynamic> userDataToUpdate = {'role': _selectedRole};
        if (_selectedRole == 'Panchayat Admin') {
          userDataToUpdate['block'] = _selectedBlock!;
          userDataToUpdate['panchayat'] = _selectedPanchayat!;
        } else if (_selectedRole == 'Block Admin') {
          userDataToUpdate['block'] = _selectedBlockAdmin!;
        }
        await userDoc.update(userDataToUpdate);
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Login Error: $e');
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
      appBar: AppBar(title: const Text('Admin Login')),
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
          SafeArea(
            child: SingleChildScrollView(
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
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Admin Type',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      items: _roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRole = newValue;
                          _emailController.clear();
                          _passwordController.clear();
                          // Reset block and panchayat when role changes
                          _selectedBlock = null;
                          _selectedPanchayat = null;
                          _panchayats = [];
                          _selectedBlockAdmin = null;
                        });
                      },
                    ),
                    if (_selectedRole == 'Block Admin') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedBlockAdmin,
                        decoration: const InputDecoration(
                          labelText: 'Block',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        items: blockCredentials.map((credential) {
                          return DropdownMenuItem<String>(
                            value: credential.block,
                            child: Text(credential.block),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedBlockAdmin = newValue;
                            if (newValue != null) {
                              final credential = blockCredentials.firstWhere(
                                (cred) => cred.block == newValue,
                              );
                              _emailController.text = credential.userId;
                            }
                          });
                        },
                      ),
                    ],
                    if (_selectedRole == 'Panchayat Admin') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedBlock,
                        decoration: const InputDecoration(
                          labelText: 'Block',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        items: _blocks.map((String block) {
                          return DropdownMenuItem<String>(
                            value: block,
                            child: Text(block),
                          );
                        }).toList(),
                        onChanged: _onBlockSelected,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedBlock != null)
                        DropdownButtonFormField<String>(
                          value: _selectedPanchayat,
                          decoration: const InputDecoration(
                            labelText: 'Panchayat',
                            labelStyle: TextStyle(color: Colors.black),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                          ),
                          items: _panchayats.map((String panchayat) {
                            return DropdownMenuItem<String>(
                              value: panchayat,
                              child: Text(panchayat),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedPanchayat = newValue;
                              if (newValue != null) {
                                final credential = panchayatCredentials
                                    .firstWhere(
                                      (cred) =>
                                          cred.block == _selectedBlock &&
                                          cred.panchayat == newValue,
                                    );
                                _emailController.text = credential.email;
                              }
                            });
                          },
                        ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'User ID',
                        labelStyle: TextStyle(color: Colors.black),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
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
