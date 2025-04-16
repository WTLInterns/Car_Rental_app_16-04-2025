import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Add this import for min function
import 'package:flutter/services.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const RegistrationScreen({super.key, required this.onBackToLogin});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _gender = '';
  String _passwordStrength = 'Weak';
  Color _strengthColor = Colors.red;
  bool _passwordVisible = false;
  bool _isLoading = false;

  void _calculatePasswordStrength(String value) {
    int strength = 0;
    if (value.isNotEmpty) strength++;
    if (value.length >= 8) strength++;
    if (value.contains(RegExp(r'[A-Z]'))) strength++;
    if (value.contains(RegExp(r'[a-z]'))) strength++;
    if (value.contains(RegExp(r'[0-9]'))) strength++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) strength++;

    setState(() {
      if (strength <= 2) {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.red;
      } else if (strength <= 4) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate gender selection
    if (_gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Print request data for debugging
      debugPrint('Sending registration request with data: ${_firstNameController.text}, ${_lastNameController.text}, ${_emailController.text}, ${_phoneController.text}, ${_gender.toLowerCase()}');
      
      final response = await http.post(
        Uri.parse('https://api.worldtriplink.com/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'gender': _gender.toLowerCase(),
        }),
      );
      
      // Check if response is empty
      if (response.body.isEmpty) {
        throw FormatException('Empty response received from server');
      }
      
      // Log response for debugging
      debugPrint('Registration response: ${response.statusCode} - ${response.body.substring(0, min(100, response.body.length))}');
      
      // Try to decode JSON with error handling
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Invalid response format: ${response.body.substring(0, min(50, response.body.length))}...');
      }
      
      if (response.statusCode == 200 && data['id'] != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Registration successful! You can now login.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onBackToLogin();
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Registration failed')),
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
      debugPrint('Registration error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5F7FA), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF666666)),
                      onPressed: widget.onBackToLogin,
                    ),
                    title: const Text('Create Account',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 20)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3192),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Text('WTL',
                          style: TextStyle(color: Colors.white, fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  const Text('Create Account',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333))),
                  const SizedBox(height: 8),
                  const Text('Join us and start your journey',
                      style: TextStyle(color: Color(0xFF666666))),
                  const SizedBox(height: 30),

                  // Name Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            labelStyle: const TextStyle(color: Color(0xFF666666)),
                            filled: true,
                            fillColor: const Color(0xFFF0F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter first name' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            labelStyle: const TextStyle(color: Color(0xFF666666)),
                            filled: true,
                            fillColor: const Color(0xFFF0F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter last name' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Color(0xFF666666)),
                      filled: true,
                      fillColor: const Color(0xFFF0F7FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter email' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Color(0xFF666666)),
                      filled: true,
                      fillColor: const Color(0xFFF0F7FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (value) => value!.length != 10
                        ? 'Invalid phone number'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Gender Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gender',
                          style: TextStyle(color: Color(0xFF666666))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _GenderButton(
                            label: 'Male',
                            isSelected: _gender == 'Male',
                            onPressed: () => setState(() => _gender = 'Male'),
                          ),
                          const SizedBox(width: 8),
                          _GenderButton(
                            label: 'Female',
                            isSelected: _gender == 'Female',
                            onPressed: () => setState(() => _gender = 'Female'),
                          ),
                          const SizedBox(width: 8),
                          _GenderButton(
                            label: 'Other',
                            isSelected: _gender == 'Other',
                            onPressed: () => setState(() => _gender = 'Other'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    onChanged: _calculatePasswordStrength,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFF666666)),
                      filled: true,
                      fillColor: const Color(0xFFF0F7FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF666666),
                        ),
                        onPressed: () =>
                            setState(() => _passwordVisible = !_passwordVisible),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter password' : null,
                  ),
                  const SizedBox(height: 10),

                  // Password Strength
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 4,
                          color: _strengthColor.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 4,
                          color: _strengthColor.withOpacity(
                              _passwordStrength == 'Weak' ? 0.3 : 1),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 4,
                          color: _strengthColor.withOpacity(
                              _passwordStrength == 'Strong' ? 1 : 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Password Strength: $_passwordStrength',
                      style: TextStyle(color: _strengthColor)),
                  const SizedBox(height: 30),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
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
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF4A90E2) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF666666),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFFCCCCCC),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}