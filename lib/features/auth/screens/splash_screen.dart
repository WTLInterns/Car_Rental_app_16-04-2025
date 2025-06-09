import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/config/app_config.dart';
import '../blocs/auth_bloc.dart';
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

// Navigate to the appropriate screen after 2 seconds
Future.delayed(const Duration(seconds: 2), () {

_checkAuthenticationAndNavigate();

});

}
@override
void dispose() {

_controller.dispose();
super.dispose();

}

Future<void> _checkAuthenticationAndNavigate() async {

// Use the AuthBloc to check authentication
final authBloc = Provider.of<AuthBloc>(context, listen: false);
await authBloc.checkAuthentication();
if (!mounted) return;

// Navigate based on authentication state
if (authBloc.isAuthenticated) {
final role = authBloc.currentUser?.role ?? '';
if (role.toUpperCase() == AppConstants.roleUser) {

Navigator.pushReplacementNamed(context, AppConstants.routeUserHome);

} else if (role.toUpperCase() == AppConstants.roleDriver) {

Navigator.pushReplacementNamed(context, AppConstants.routeDriverTrips);

} else {

// Default to login if role is unknown

Navigator.pushReplacementNamed(context, AppConstants.routeLogin);

}

} else {

Navigator.pushReplacementNamed(context, AppConstants.routeLogin);

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
final double logoSize = isSmallScreen

? screenWidth * 0.6

: screenWidth > 600

? screenWidth * 0.4

: screenWidth * 0.7;
return Scaffold(

backgroundColor: Colors.white,

body: Column(

mainAxisAlignment: MainAxisAlignment.center,

children: [

// Logo in a circular container
Image.asset(
'assets/images/logo.png',

fit: BoxFit.cover, // Makes the image fill the circle

),
SizedBox(height: screenHeight * 0.05),

// Tagline
Text(
'Your Journey, Your Way',

style: TextStyle(

fontSize: isSmallScreen ? 24 : 28,

fontWeight: FontWeight.bold,

color: const Color(AppConfig.primaryColorHex),

fontFamily: 'Serif',

),

textAlign: TextAlign.center,

),
SizedBox(height: screenHeight * 0.08),

// Loading indicator
SizedBox(height: screenHeight * 0.05),
CircularProgressIndicator(

valueColor: AlwaysStoppedAnimation<Color>(
Color(AppConfig.primaryColorHex),

),

strokeWidth: 3,

),

],

),

);

}

}
 