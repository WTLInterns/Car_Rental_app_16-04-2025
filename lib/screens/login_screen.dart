import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Add this import for min function
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldtriplink/screens/registration_screen.dart';
import 'package:worldtriplink/screens/user_home_screen.dart';
import 'package:worldtriplink/screens/driver_trips_screen.dart';
import 'package:flutter/services.dart'; // For input formatters

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _rememberMe = false;
  
  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  // Validation patterns
  final RegExp _mobilePattern = RegExp(r'^[6-9]\d{9}$'); // Indian mobile number pattern

  Future<void> loginUser() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Log request for debugging
      debugPrint('Sending login request with mobile: ${_mobileController.text}');
      
      final response = await http.post(
        Uri.parse('https://api.worldtriplink.com/auth/login1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': _mobileController.text,
          'password': _passwordController.text
        }),
      );

      // Check if response is empty or not valid JSON
      if (response.body.isEmpty) {
        throw FormatException('Empty response received from server');
      }

      // Log response for debugging
      debugPrint('Login response: ${response.statusCode} - ${response.body.substring(0, min(100, response.body.length))}');

      // Try to decode JSON with error handling
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Invalid response format: ${response.body.substring(0, min(50, response.body.length))}...');
      }
      
      // Inside the loginUser method, after successful login validation
      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', data['userId']);
        await prefs.setString('role', data['role']);
        await prefs.setBool('isLoggedIn', true);
        
        // Store complete user data
        final userData = {
          'userId': data['userId'],
          'role': data['role'],
          'name': data['username'] ?? '',
          'email': data['email'] ?? '',
        };
        await prefs.setString('userData', json.encode(userData));
        
        // Store login timestamp for 20-day validity
        await prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);
        
        if (_rememberMe) {
          await prefs.setBool('rememberMe', true);
          // Store credentials if remember me is checked
          await prefs.setString('savedMobile', _mobileController.text);
        } else {
          // Clear saved credentials if remember me is unchecked
          await prefs.remove('savedMobile');
          await prefs.remove('rememberMe');
        }
        
        // Role-based navigation
        if (data['role'].toString().toUpperCase() == 'USER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserHomeScreen()),
          );
        } else if (data['role'].toString().toUpperCase() == 'DRIVER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverTripsScreen()),
          );
        } else {
          // Handle unknown roles
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown user role')),
          );
        }
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      // More descriptive error message
      String errorMessage = 'Error: ${e.toString()}';
      if (e is FormatException) {
        errorMessage = 'Server response error: ${e.message}';
      } else if (e is http.ClientException) {
        errorMessage = 'Network error: Unable to connect to server';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      
      // Log the error for debugging
      debugPrint('Login error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Check for saved credentials
    _loadSavedCredentials();
  }
  
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    
    if (rememberMe) {
      final savedMobile = prefs.getString('savedMobile') ?? '';
      
      setState(() {
        _mobileController.text = savedMobile;
        _rememberMe = rememberMe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5F7FA), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 200,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      // Welcome Text
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3192),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue your journey',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Mobile Number Field with validation
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          if (!_mobilePattern.hasMatch(value)) {
                            return 'Please enter a valid Indian mobile number';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: const TextStyle(color: Color(0xFF333333)),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFF4A90E2)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F7FF),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          hintText: 'Enter your mobile number',
                          hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field with validation
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color(0xFF333333)),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4A90E2)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFFA0A0A0),
                            ),
                            onPressed: () {
                              setState(() => _passwordVisible = !_passwordVisible);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F7FF),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          hintText: '••••••••••',
                          hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCCCCCC)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _rememberMe
                                      ? const Icon(Icons.check, size: 14, color: Color(0xFF4A90E2))
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Forgot password feature coming soon')),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Color(0xFF4A90E2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF333333))
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFE0E0E0)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(color: Color(0xFF999999)),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFE0E0E0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Create Account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrationScreen(
                                    onBackToLogin: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Color(0xFF4A90E2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}