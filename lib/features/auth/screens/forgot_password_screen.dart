import 'package:flutter/material.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/config/app_config.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';
import '../repositories/auth_repository.dart';

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

  // Create auth repository instance
  final AuthRepository _authRepository = AuthRepository();

  Future<void> _sendOTP() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool success = await _authRepository.requestPasswordReset(_emailController.text);
      
      setState(() {
        _isLoading = false;
        if (success) {
          _otpSent = true;
        }
      });
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully. Please check your email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _verifyOTP() async {
    // Validate OTP format
    final String otp = _otpController.text;
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP sent to your email')),
      );
      return;
    }
    
    // Check if OTP is exactly 6 characters and contains only alphanumeric characters
    if (otp.length != 6 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP must be exactly 6 alphanumeric characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool isValid = await _authRepository.verifyOTP(_emailController.text, _otpController.text);
      
      setState(() {
        _isLoading = false;
        _verificationSuccess = isValid;
      });
      
      if (!mounted) return;
      
      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified successfully. You can now reset your password.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying OTP: ${e.toString()}')),
      );
    }
  }

  Future<void> _resetPassword() async {
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
      final bool success = await _authRepository.resetPassword(_emailController.text, _passwordController.text);
      
      setState(() {
        _isLoading = false;
        _resetSuccess = success;
      });
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully. You can now login with your new password.')),
        );
        
        // Navigate back to login screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reset password. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting password: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get device size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Adjust for different screen sizes
    final double cardWidth = screenWidth > 600 ? 500 : screenWidth * 0.9;
    final double horizontalPadding = screenWidth > 600 ? 32 : 24;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset'),
        centerTitle: true,
        elevation: 0,
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
                          color: Color(AppConfig.primaryColorHex),
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
                        AppButton(
                          text: 'Back to Login',
                          onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.routeLogin),
                          fullWidth: true,
                          type: AppButtonType.primary,
                          size: AppButtonSize.large,
                        ),
                      ] else if (_verificationSuccess) ...[  
                        // Reset Password UI
                        const Text(
                          'Create New Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConfig.primaryColorHex),
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
                        AppTextField(
                          label: 'New Password',
                          hint: 'Enter your new password',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: Icons.lock,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Confirm Password Field
                        AppTextField(
                          label: 'Confirm Password',
                          hint: 'Confirm your new password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Reset Button
                        AppButton(
                          text: 'Reset Password',
                          onPressed: _isLoading ? null : _resetPassword,
                          isLoading: _isLoading,
                          fullWidth: true,
                          type: AppButtonType.primary,
                          size: AppButtonSize.large,
                        ),
                      ] else if (_otpSent) ...[  
                        // OTP Verification UI
                        const Text(
                          'Enter OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConfig.primaryColorHex),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          'We\'ve sent a 6-digit OTP to your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // OTP Field
                        AppTextField(
                          label: 'OTP Code',
                          hint: 'Enter 6-digit OTP',
                          controller: _otpController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.security,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the OTP';
                            }
                            if (value.length != 6) {
                              return 'OTP must be 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Verify Button
                        AppButton(
                          text: 'Verify OTP',
                          onPressed: _isLoading ? null : _verifyOTP,
                          isLoading: _isLoading,
                          fullWidth: true,
                          type: AppButtonType.primary,
                          size: AppButtonSize.large,
                        ),
                        
                        // Resend OTP Link
                        TextButton(
                          onPressed: _isLoading ? null : _sendOTP,
                          child: const Text(
                            'Didn\'t receive the OTP? Resend',
                            style: TextStyle(
                              color: Color(AppConfig.secondaryColorHex),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Initial Email Input UI
                        const Text(
                          'Enter your email to reset your password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Email Field
                        AppTextField(
                          label: 'Email Address',
                          hint: 'Enter your registered email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Send OTP Button
                        AppButton(
                          text: 'Send OTP',
                          onPressed: _isLoading ? null : _sendOTP,
                          isLoading: _isLoading,
                          fullWidth: true,
                          type: AppButtonType.primary,
                          size: AppButtonSize.large,
                        ),
                        
                        // Back to Login Link
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.routeLogin),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Color(AppConfig.secondaryColorHex),
                              fontWeight: FontWeight.w500,
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
  
  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 