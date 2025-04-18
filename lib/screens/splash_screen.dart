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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the appropriate screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _checkLoginStatus();
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo in a circular container
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Tagline
            const Text(
              'Your Journey, Your Way',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3192),
                fontFamily: 'Serif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            // Indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(true),
                const SizedBox(width: 8),
                _buildDot(false),
                const SizedBox(width: 8),
                _buildDot(false),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDot(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E3192) : const Color(0xFF2E3192).withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}