import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _verificationSuccess = false;
  bool _resetSuccess = false;

  // Email validation pattern
  final RegExp _emailPattern = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  Future<void> sendOTP() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Log request for debugging
      debugPrint(
        'Sending OTP request with email: ${_emailController.text}',
      );

      // Changed: Use form-urlencoded format instead of JSON
      final response = await http.post(
        Uri.parse('https://api.worldtriplink.com/carRental/request-reset'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': _emailController.text,
        },
      );

      // Log response for debugging
      debugPrint(
        'OTP response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully. Please check your email.')),
        );
        setState(() {
          _otpSent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: ${response.body}')),
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
      debugPrint('OTP request error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP sent to your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Log request for debugging
      debugPrint(
        'Verifying OTP: ${_otpController.text} for email: ${_emailController.text}',
      );

      // Changed: Use form-urlencoded format instead of JSON
      final response = await http.post(
        Uri.parse('https://api.worldtriplink.com/carRental/verify-otp'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': _emailController.text,
          'otp': _otpController.text,
        },
      );

      // Log response for debugging
      debugPrint(
        'OTP verification response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        // Parse the boolean response from the controller
        final bool isValid = response.body.toLowerCase() == 'true';
        
        if (isValid) {
          setState(() {
            _verificationSuccess = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP verified successfully. You can now reset your password.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying OTP: ${e.toString()}')),
      );
      debugPrint('OTP verification error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    // Validate password fields
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Log request for debugging
      debugPrint('Resetting password for email: ${_emailController.text}');

      // Changed: Use form-urlencoded format instead of JSON
      final response = await http.post(
        Uri.parse('https://api.worldtriplink.com/carRental/reset-password'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': _emailController.text,
          'newPassword': _passwordController.text,
        },
      );

      // Log response for debugging
      debugPrint(
        'Password reset response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _resetSuccess = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully. You can now login with your new password.')),
        );
        
        // Navigate back to login screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(); // Return to login screen
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting password: ${e.toString()}')),
      );
      debugPrint('Password reset error: $e');
    } finally {
      setState(() => _isLoading = false);
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
    final double cardWidth = screenWidth > 600 ? 500 : screenWidth * 0.9;
    final double horizontalPadding = screenWidth > 600 ? 32 : 24;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E3192),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - AppBar().preferredSize.height,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      const Text(
                        'Password Reset',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3192),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      if (_resetSuccess) ...[  
                        // Reset Success UI
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          'Password Reset Successful',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          'You can now login with your new password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: Size(
                              double.infinity,
                              screenHeight * 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (_verificationSuccess) ...[  
                        // Reset Password UI
                        const Text(
                          'Create New Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3192),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          'Please enter your new password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // New Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: const TextStyle(color: Color(0xFF333333)),
                            prefixIcon: const Icon(
                              Icons.lock,
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
                            hintText: 'Enter your new password',
                            hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: const TextStyle(color: Color(0xFF333333)),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
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
                            hintText: 'Confirm your new password',
                            hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Reset Password Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: Size(
                              double.infinity,
                              screenHeight * 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ] else if (!_otpSent) ...[  
                        // Email Field with validation
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_emailPattern.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Color(0xFF333333)),
                            prefixIcon: const Icon(
                              Icons.email,
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
                            hintText: 'Enter your email address',
                            hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                            errorStyle: const TextStyle(color: Colors.red),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Send OTP Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: Size(
                              double.infinity,
                              screenHeight * 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ] else ...[  
                        // OTP Verification UI
                        const Text(
                          'Enter the OTP sent to your email',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '------',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 24,
                              letterSpacing: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF0F7FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        ElevatedButton(
                          onPressed: _isLoading ? null : verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            minimumSize: Size(
                              double.infinity,
                              screenHeight * 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        TextButton(
                          onPressed: _isLoading ? null : sendOTP,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: Color(0xFF4A90E2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
}