import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/config/app_config.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_text_field.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  // Validation patterns
  final RegExp _mobilePattern =
      RegExp(r'^[6-9]\d{9}$'); // Indian mobile number pattern

  @override
  void initState() {
    super.initState();
    // Load saved credentials (now using our Auth bloc)
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authBloc = Provider.of<AuthBloc>(context, listen: false);
    final rememberMe = authBloc.getRememberMe();

    if (rememberMe) {
      final savedMobile = authBloc.getSavedMobile();

      setState(() {
        _mobileController.text = savedMobile;
        _rememberMe = rememberMe;
      });
    }
  }

  void _login() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authBloc = Provider.of<AuthBloc>(context, listen: false);

    try {
      await authBloc.login(
        _mobileController.text,
        _passwordController.text,
        _rememberMe,
      );

      if (!mounted) return;

      // Handle navigation based on auth state
      if (authBloc.state.status == AuthStatus.authenticated) {
        final role = authBloc.currentUser?.role ?? '';

        if (role.toUpperCase() == AppConstants.roleUser) {
          Navigator.pushReplacementNamed(context, AppConstants.routeUserHome);
        } else if (role.toUpperCase() == AppConstants.roleDriver) {
          Navigator.pushReplacementNamed(
              context, AppConstants.routeDriverTrips);
        } else if (role.toUpperCase() == AppConstants.roleAdminDriver) {
          Navigator.pushReplacementNamed(
              context, AppConstants.routeAdminDriverHome);
        } else {
          // Handle unknown roles
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown user role')),
          );
        }
      } else if (authBloc.state.status == AuthStatus.error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red,
              content: Text(
            'Invalid phone number or password. Please try again!',
            style: TextStyle(fontSize: 12),
          )), //authBloc.state.errorMessage ??
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
    final bool isSmallScreen = screenWidth < 360;
    final double logoHeight = isSmallScreen ? 100 : 140;
    final double cardWidth = screenWidth > 600 ? 500 : screenWidth * 0.9;
    final double horizontalPadding = screenWidth > 600 ? 32 : 24;

    return Scaffold(
      body: SafeArea(
        bottom: false, // Important for iPhones with home indicator
        child: Consumer<AuthBloc>(
          builder: (context, authBloc, _) {
            final isLoading = authBloc.isLoading;
            return SingleChildScrollView(
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
                            margin:
                                EdgeInsets.only(bottom: screenHeight * 0.02),
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
                              color: const Color(AppConfig.primaryColorHex),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Sign in to continue your journey',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(AppConfig.lightTextColorHex),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Mobile Number Field with AppTextField widget
                          AppTextField(
                            label: 'Mobile Number',
                            hint: 'Enter your mobile number',
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone,
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
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Password Field with AppTextField widget
                          AppTextField(
                            label: 'Password',
                            hint: '••••••••••',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
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
                                // Remember Me
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _rememberMe = !_rememberMe);
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFCCCCCC),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: _rememberMe
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Color(AppConfig
                                                    .secondaryColorHex),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me',
                                        style: TextStyle(
                                          color: const Color(
                                              AppConfig.lightTextColorHex),
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Forgot Password
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context,
                                        AppConstants.routeForgotPassword);
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
                                      color: const Color(
                                          AppConfig.secondaryColorHex),
                                      fontWeight: FontWeight.w500,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // Login Button using AppButton
                          AppButton(
                            text: 'Login',
                            onPressed: isLoading ? null : _login,
                            isLoading: isLoading,
                            fullWidth: true,
                            type: AppButtonType.primary,
                            size: AppButtonSize.large,
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xFFE0E0E0)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Or continue with',
                                  style: TextStyle(
                                    color: const Color(
                                        AppConfig.mutedTextColorHex),
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
                                "Don't have an account?",
                                style: TextStyle(
                                  color:
                                      const Color(AppConfig.lightTextColorHex),
                                  fontSize: isSmallScreen ? 11 : 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AppConstants.routeRegister);
                                },
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: const Color(
                                        AppConfig.secondaryColorHex),
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 11 : 13,
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
          },
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
