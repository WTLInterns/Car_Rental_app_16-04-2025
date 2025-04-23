import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// Updated color palette to match driver_trips_screen.dart
const Color primaryColor = Color(0xFF3057E3);      // Royal blue
const Color secondaryColor = Color(0xFF3057E3);    // Same blue for consistency
const Color accentColor = Color(0xFFFFCC00);       // Yellow/gold accent
const Color backgroundColor = Color(0xFFF3F5F9);   // Light gray background
const Color cardColor = Colors.white;              // White card background
const Color textColor = Color(0xFF333333);         // Dark text
const Color lightTextColor = Color(0xFF666666);    // Medium gray text
const Color mutedTextColor = Color(0xFFAAAAAA);    // Light gray text
const Color successColor = Color(0xFF4CAF50);      // Green for success
const Color errorColor = Color(0xFFE53935);        // Red for errors
const Color warningColor = Color(0xFFFF9800);      // Orange for warnings

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? driver;
  bool isLoading = true;
  int _selectedIndex = 1; // For bottom navigation

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('userData');
      if (driverData != null) {
        setState(() {
          driver = json.decode(driverData);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading driver data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate back to trips screen
      Navigator.pop(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Text(
                                driver?['name'] != null
                                    ? driver!['name'].toString().substring(0, 1).toUpperCase()
                                    : 'D',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (driver?['name'] != null)
                              Text(
                                driver!['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Profile Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Info Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(MaterialCommunityIcons.account_details, 
                                      color: primaryColor, size: 22),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Personal Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  MaterialCommunityIcons.account,
                                  'Name',
                                  driver?['name'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  MaterialCommunityIcons.email_outline,
                                  'Email',
                                  driver?['email'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  MaterialCommunityIcons.phone_outline,
                                  'Phone',
                                  driver?['phone'] ?? 'Not available',
                                ),
                                if (driver?['address'] != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    MaterialCommunityIcons.map_marker_outline,
                                    'Address',
                                    driver?['address'] ?? 'Not available',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Vehicle Information
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(MaterialCommunityIcons.car_info, 
                                      color: primaryColor, size: 22),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Vehicle Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  MaterialCommunityIcons.car,
                                  'Vehicle Model',
                                  driver?['vehicleModel'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  MaterialCommunityIcons.license,
                                  'Vehicle Number',
                                  driver?['vehicleNumber'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  MaterialCommunityIcons.palette,
                                  'Vehicle Color',
                                  driver?['vehicleColor'] ?? 'Not available',
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Account Settings
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(MaterialCommunityIcons.cog_outline, 
                                      color: primaryColor, size: 22),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Account Settings',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                // const SizedBox(height: 16),
                                // ListTile(
                                //   leading: Icon(MaterialCommunityIcons.lock_outline, color: primaryColor),
                                //   title: const Text('Change Password'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to change password screen
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(content: Text('Coming soon'))
                                //     );
                                //   },
                                // ),
                                // const Divider(height: 8),
                                // ListTile(
                                //   leading: Icon(MaterialCommunityIcons.bell_outline, color: primaryColor),
                                //   title: const Text('Notification Settings'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to notification settings
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(content: Text('Coming soon'))
                                //     );
                                //   },
                                // ),
                                // const Divider(height: 8),
                                // ListTile(
                                //   leading: Icon(MaterialCommunityIcons.help_circle_outline, color: primaryColor),
                                //   title: const Text('Help & Support'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to help & support
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(content: Text('Coming soon'))
                                //     );
                                //   },
                                // ),
                                // const Divider(height: 8),
                                // ListTile(
                                //   leading: Icon(MaterialCommunityIcons.information_outline, color: primaryColor),
                                //   title: const Text('About App'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to about app
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(content: Text('Coming soon'))
                                //     );
                                //   },
                                // ),
                                const Divider(height: 8),
                                ListTile(
                                  leading: const Icon(MaterialCommunityIcons.logout, color: errorColor),
                                  title: const Text('Logout', 
                                    style: TextStyle(color: errorColor),
                                  ),
                                  onTap: _logout,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // App Version
                        Center(
                          child: Text(
                            'World Trip Link v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(MaterialCommunityIcons.car_multiple),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(MaterialCommunityIcons.account_circle),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: mutedTextColor,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: mutedTextColor,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: label == 'Phone' ? () => makePhoneCall(value) : null,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: label == 'Phone' ? primaryColor : textColor,
                    decoration: label == 'Phone' ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'Not available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available'))
      );
      return;
    }
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }
}