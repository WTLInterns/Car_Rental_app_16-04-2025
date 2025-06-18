import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:worldtriplink/features/profile/account_settings_pages/About/about_scrren.dart';
import 'package:worldtriplink/features/profile/account_settings_pages/Refund_policy/refund_policy.dart';
import 'package:worldtriplink/features/profile/account_settings_pages/support/support.dart';

const Color primaryColor = Color(0xFF4A90E2);
const Color accentColor = Color(0xFF50C878);
const Color textColor = Color(0xFF1A1A1A);
const Color lightTextColor = Color(0xFF6B7280);
const Color cardColor = Colors.white;

class AccountSettingScreen extends StatefulWidget {
  const AccountSettingScreen({super.key});

  @override
  State<AccountSettingScreen> createState() => _AccountSettingScreenState();
}

class _AccountSettingScreenState extends State<AccountSettingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
    _checkLocationServiceStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkLocationServiceStatus();
    }
  }

  Future<void> _checkLocationServiceStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        serviceEnabled = permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever;
      }
      if (mounted) {
        setState(() {
          _locationEnabled = serviceEnabled;
        });
      }
    } catch (e) {
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error checking location status: $e')),
      //   );
      // }
    }
  }

  Future<void> _handleLocationToggle(bool value) async {
    try {
      if (mounted) {
        setState(() {
          _locationEnabled = value;
        });
      }

      if (value) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            if (mounted) {
              setState(() {
                _locationEnabled = false;
              });
            }
            return;
          }
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() {
              _locationEnabled = false;
            });
          }
          return;
        }
      } else {
        await Geolocator.openLocationSettings();
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (mounted) {
          setState(() {
            _locationEnabled = serviceEnabled;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _locationEnabled = value;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationEnabled = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Color(0xFF6AB0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Your Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customize your profile, manage services, or learn more about us.',
                    style: TextStyle(
                      fontSize: 14,
                      color: lightTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: MaterialCommunityIcons.briefcase_outline,
                    color: primaryColor,
                    title: 'About',
                    description:
                        'Discover our premium travel services and offerings.',
                    onTap: () => _navigateToScreen(AboutScreen()),
                  ),
                  const SizedBox(height: 6),
                  _buildMenuItem(
                    icon: MaterialCommunityIcons.headset,
                    color: primaryColor,
                    title: 'Support',
                    description: 'Contact our team for assistance.',
                    onTap: () => _navigateToScreen(const SupportScreen()),
                  ),
                  const SizedBox(height: 6),
                  _buildMenuItem(
                    icon: MaterialCommunityIcons.cash_refund,
                    color: primaryColor,
                    title: 'Refund Policy',
                    description:
                        'Understand our refund and cancellation policies.',
                    onTap: () => _navigateToScreen(const RefundPolicyScreen()),
                  ),
                  const SizedBox(height: 6),
                  _buildLocationSection(
                    title: 'Location Services',
                    icon: MaterialCommunityIcons.map_marker_outline,
                    value: _locationEnabled,
                    onChanged: _handleLocationToggle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: lightTextColor,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: lightTextColor, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        // Reduced padding
        leading: Icon(icon, size: 24, color: primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: const Text(
          'Enable to use location-based features',
          style: TextStyle(
            color: lightTextColor,
            fontSize: 10,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: primaryColor,
          activeTrackColor: primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
