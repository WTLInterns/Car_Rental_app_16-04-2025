import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:convert';

// Professional color palette (same as driver_trips_screen.dart)
const Color primaryColor = Color(0xFF2E3192);
const Color secondaryColor = Color(0xFF4A90E2);
const Color accentColor = Color(0xFFFFCC00);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF666666);
const Color mutedTextColor = Color(0xFF999999);
const Color successColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFFF5252);
const Color warningColor = Color(0xFFFF9800);

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
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            child: const Text('Logout', style: TextStyle(color: errorColor)),
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
          ? const Center(child: CircularProgressIndicator(color: secondaryColor))
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
                            secondaryColor,
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
                                  color: secondaryColor,
                                ),
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
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  Icons.person,
                                  'Name',
                                  driver?['name'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  Icons.email,
                                  'Email',
                                  driver?['email'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  Icons.phone,
                                  'Phone',
                                  driver?['phone'] ?? 'Not available',
                                ),
                                if (driver?['address'] != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    Icons.location_on,
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
                                const Text(
                                  'Vehicle Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  MaterialCommunityIcons.car,
                                  'Vehicle Model',
                                  driver?['vehicleModel'] ?? 'Not available',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  MaterialCommunityIcons.car_info,
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
                                // const Text(
                                //   'Account Settings',
                                //   style: TextStyle(
                                //     fontSize: 18,
                                //     fontWeight: FontWeight.bold,
                                //     color: textColor,
                                //   ),
                                // ),
                                // const SizedBox(height: 16),
                                // ListTile(
                                //   leading: const Icon(Icons.lock, color: secondaryColor),
                                //   title: const Text('Change Password'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to change password screen
                                //   },
                                // ),
                                // const Divider(height: 8),
                                // ListTile(
                                //   leading: const Icon(Icons.notifications, color: secondaryColor),
                                //   title: const Text('Notification Settings'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to notification settings
                                //   },
                                // ),
                                // const Divider(height: 8),
                                // ListTile(
                                //   leading: const Icon(Icons.help, color: secondaryColor),
                                //   title: const Text('Help & Support'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to help & support
                                //   },
                                // ),
                                // const Divider(height: 8),
                                // ListTile(
                                //   leading: const Icon(Icons.info, color: secondaryColor),
                                //   title: const Text('About App'),
                                //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                //   onTap: () {
                                //     // Navigate to about app
                                //   },
                                // ),
                                const Divider(height: 8),
                                ListTile(
                                  leading: const Icon(Icons.logout, color: errorColor),
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
          selectedItemColor: secondaryColor,
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
        Icon(icon, color: secondaryColor, size: 20),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}