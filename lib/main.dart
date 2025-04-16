import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldtriplink/screens/login_screen.dart';
import 'package:worldtriplink/screens/user_home_screen.dart';
import 'package:worldtriplink/screens/driver_trips_screen.dart';
import 'package:worldtriplink/screens/passenger_details_screen.dart'; // Added import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Trip Link',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E3192)),
        useMaterial3: true,
      ),
      // Display DriverTripsScreen instead of UserHomeScreen
      home: const UserHomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/user-home': (context) => const UserHomeScreen(),
        '/driver-trips': (context) => const DriverTripsScreen(),
      },
    );
  }
}

/* Commenting out AuthCheckScreen for direct UserHomeScreen display
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
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
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : const LoginScreen(),
    );
  }
}
*/
