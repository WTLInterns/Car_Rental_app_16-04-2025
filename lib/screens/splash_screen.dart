import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldtriplink/screens/login_screen.dart';
import 'package:worldtriplink/screens/user_home_screen.dart';
import 'package:worldtriplink/screens/driver_trips_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate to the appropriate screen after 3 seconds
    Future.delayed(const Duration(seconds: 2), () {
      _checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final loginTimestamp = prefs.getInt('loginTimestamp') ?? 0;
    final role = prefs.getString('role') ?? '';

    // Check if login is still valid (20 days)
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyDaysInMillis = 20 * 24 * 60 * 60 * 1000;
    final isLoginValid = (now - loginTimestamp) < twentyDaysInMillis;

    if (isLoggedIn && isLoginValid) {
      // Navigate based on user role
      if (role.toUpperCase() == 'USER') {
        Navigator.pushReplacementNamed(context, '/user-home');
      } else if (role.toUpperCase() == 'DRIVER') {
        Navigator.pushReplacementNamed(context, '/driver-trips');
      } else {
        // Default to login if role is unknown
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Clear login data if expired
      if (isLoggedIn && !isLoginValid) {
        await prefs.setBool('isLoggedIn', false);
      }
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get device size for responsive design
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Different logo sizes based on device size
    final bool isSmallScreen = screenWidth < 360;
    final double logoSize =
        isSmallScreen
            ? screenWidth * 0.6
            : screenWidth > 600
            ? screenWidth * 0.4
            : screenWidth * 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false, // Important for iPhones with home indicator
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: screenHeight * 0.05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo in a circular container
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(
                    logoSize * 0.15,
                  ), // Proportional padding
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                // Tagline
                Text(
                  'Your Journey, Your Way',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E3192),
                    fontFamily: 'Serif',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.08),
                // Indicator dots
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     _buildDot(true),
                //     const SizedBox(width: 8),
                //     _buildDot(false),
                //     const SizedBox(width: 8),
                //     _buildDot(false),
                //   ],
                // ),
                // Loading indicator
                SizedBox(height: screenHeight * 0.05),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E3192),
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildDot(bool isActive) {
  //   return Container(
  //     width: 10,
  //     height: 10,
  //     decoration: BoxDecoration(
  //       color:
  //           isActive
  //               ? const Color(0xFF2E3192)
  //               : const Color(0xFF2E3192).withOpacity(0.5),
  //       shape: BoxShape.circle,
  //     ),
  //   );
  // }
}
