import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/config/app_config.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';
import '../repositories/auth_repository.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

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
      // Create auth repository instance
      final authRepository = AuthRepository();

      // Prepare registration data
      final Map<String, dynamic> registrationData = {
        'userName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'gender': _gender.toLowerCase(),
      };

      // Call registration endpoint
      final response = await authRepository.register(registrationData);

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Registration successful! You can now login.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushReplacementNamed(
                    context, AppConstants.routeLogin);
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      // Show error message
      print('Registration failed: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Center(child: Text('Mobile number already exists')),
            backgroundColor: Colors.redAccent),
      );
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
                      icon: const Icon(Icons.arrow_back,
                          color: Color(AppConfig.lightTextColorHex)),
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppConstants.routeLogin),
                    ),
                    title: const Text('Create Account',
                        style: TextStyle(
                            color: Color(AppConfig.textColorHex),
                            fontSize: 20)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(AppConfig.primaryColorHex),
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
                          color: Color(AppConfig.textColorHex))),
                  const SizedBox(height: 8),
                  const Text('Join us and start your journey',
                      style:
                          TextStyle(color: Color(AppConfig.lightTextColorHex))),
                  const SizedBox(height: 30),

                  // Name Fields
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'First Name',
                          controller: _firstNameController,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter first name' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter last name' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  AppTextField(
                    label: 'Email Address',
                    hint: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Field
                  AppTextField(
                    label: 'Phone Number',
                    hint: '10-digit mobile number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) =>
                        value!.length != 10 ? 'Invalid phone number' : null,
                  ),
                  const SizedBox(height: 20),

                  // Gender Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(AppConfig.textColorHex),
                        ),
                      ),
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
                  AppTextField(
                    label: 'Password',
                    hint: 'Minimum 8 characters',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    onChanged: _calculatePasswordStrength,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
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
                  Text(
                    'Password Strength: $_passwordStrength',
                    style: TextStyle(color: _strengthColor),
                  ),
                  const SizedBox(height: 30),

                  // Sign Up Button using AppButton
                  AppButton(
                    text: 'Sign Up',
                    onPressed: _isLoading ? null : _handleRegistration,
                    isLoading: _isLoading,
                    fullWidth: true,
                    type: AppButtonType.primary,
                    size: AppButtonSize.large,
                  ),

                  const SizedBox(height: 20),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                            color: Color(AppConfig.lightTextColorHex)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, AppConstants.routeLogin),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(AppConfig.secondaryColorHex),
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
        backgroundColor: isSelected
            ? const Color(AppConfig.secondaryColorHex)
            : Colors.white,
        foregroundColor: isSelected
            ? Colors.white
            : const Color(AppConfig.lightTextColorHex),
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
