import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worldtriplink/core/config/app_theme.dart';
import 'package:worldtriplink/core/utils/app_constants.dart';
import 'package:worldtriplink/core/utils/storage_service.dart';
import 'package:worldtriplink/features/auth/blocs/auth_bloc.dart';
import 'package:worldtriplink/features/auth/screens/login_screen.dart';
import 'package:worldtriplink/features/auth/screens/registration_screen.dart';
import 'package:worldtriplink/features/auth/screens/forgot_password_screen.dart';
import 'package:worldtriplink/features/auth/screens/splash_screen.dart';
import 'package:worldtriplink/features/profile/screens/profile_screen.dart';
import 'package:worldtriplink/features/tracking/screens/tracking_screen.dart';
import 'package:worldtriplink/features/trips/screens/driver_trips_screen.dart';
import 'package:worldtriplink/features/booking/screens/user_home_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.init();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthBloc()),
        // Add other providers as needed
      ],
      child: Consumer<AuthBloc>(
        builder: (context, authBloc, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'World Trip Link',
            theme: AppTheme.lightTheme,
            initialRoute: AppConstants.routeSplash,
            routes: {
              AppConstants.routeSplash: (context) => const SplashScreen(),
              AppConstants.routeLogin: (context) => const LoginScreen(),
              AppConstants.routeRegister: (context) =>
                  const RegistrationScreen(),
              AppConstants.routeForgotPassword: (context) =>
                  const ForgotPasswordScreen(),
              AppConstants.routeUserHome: (context) => const UserHomeScreen(),
              AppConstants.routeDriverTrips: (context) =>
                  const DriverTripsScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppConstants.routeTracking) {
                final args = settings.arguments as Map<String, dynamic>?;

                if (args == null) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Booking data is required for tracking'),
                      ),
                    ),
                  );
                }

                return MaterialPageRoute(
                  builder: (context) => TrackingScreen(bookingData: args),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
