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
  final RegExp _mobilePattern = RegExp(
    r'^[6-9]\d{9}$',
  ); // Indian mobile number pattern

  Future<void> loginUser() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Log request for debugging
      debugPrint(
        'Sending login request with mobile: ${_mobileController.text}',
      );

      final response = await http.post(
        Uri.parse('https://api.worldtriplink.com/auth/login1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': _mobileController.text,
          'password': _passwordController.text,
        }),
      );

      // Check if response is empty or not valid JSON
      if (response.body.isEmpty) {
        throw FormatException('Empty response received from server');
      }

      // Log response for debugging
      debugPrint(
        'Login response: ${response.statusCode} - ${response.body.substring(0, min(100, response.body.length))}',
      );

      // Try to decode JSON with error handling
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw FormatException(
          'Invalid response format: ${response.body.substring(0, min(50, response.body.length))}...',
        );
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
        await prefs.setInt(
          'loginTimestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Unknown user role')));
        }
      } else {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));

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
    // Get device size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Adjust for different screen sizes
    final bool isSmallScreen = screenWidth < 360;
    final double logoHeight = isSmallScreen ? 100 : 140;
    final double cardWidth = screenWidth > 600 ? 500 : screenWidth * 0.9;
    final double horizontalPadding = screenWidth > 600 ? 32 : 24;

    return Scaffold(
      body: SafeArea(
        bottom: false, // Important for iPhones with home indicator
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: screenHeight * 0.03,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F7FA), Colors.white],
              ),
            ),
            child: Center(
              child: Container(
                width: cardWidth,
                padding: EdgeInsets.all(screenWidth * 0.06),
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
                        margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: screenWidth * 0.5,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Welcome Text
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E3192),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Sign in to continue your journey',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

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
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFF4A90E2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F7FF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          hintText: 'Enter your mobile number',
                          hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

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
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF4A90E2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFFA0A0A0),
                            ),
                            onPressed: () {
                              setState(
                                () => _passwordVisible = !_passwordVisible,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F7FF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          hintText: '••••••••••',
                          hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Remember Me & Forgot Password
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.005,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => _rememberMe = !_rememberMe,
                                      ),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFCCCCCC),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child:
                                        _rememberMe
                                            ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Color(0xFF4A90E2),
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: const Color(0xFF666666),
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Forgot password feature coming soon',
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: 4,
                                ),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: const Color(0xFF4A90E2),
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          minimumSize: Size(
                            double.infinity,
                            screenHeight * 0.06,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Color(0xFF333333),
                                )
                                : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: const Color(0xFF333333),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Divider
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFE0E0E0)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFE0E0E0)),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Create Account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => RegistrationScreen(
                                        onBackToLogin:
                                            () => Navigator.pop(context),
                                      ),
                                ),
                              );
                            },
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: const Color(0xFF4A90E2),
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
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
