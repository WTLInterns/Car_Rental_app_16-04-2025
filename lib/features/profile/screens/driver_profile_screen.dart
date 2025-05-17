import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../features/trips/screens/driver_trips_screen.dart';
import '../../../features/trips/screens/driver_ets_trips_screen.dart';

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
  int _selectedIndex = 2; // For bottom navigation - set to 2 for Profile

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      // First try to get the driver ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('userData');
      
      if (driverData != null) {
        final userData = json.decode(driverData);
        // Assuming the driver ID is stored in userData
        // You might need to adjust this based on your actual data structure
        final driverId = userData['id'] ?? 353
        ; // Default to 353 if not found
        
        // Fetch driver data from API
        await _fetchDriverFromApi(driverId);
      } else {
        // If no local data, fetch with default ID
        await _fetchDriverFromApi(353);
      }
    } catch (error) {
      debugPrint('Error loading driver data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _fetchDriverFromApi(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.worldtriplink.com/vendorDriver/$driverId'),
      );
      
      if (response.statusCode == 200) {
        final apiData = json.decode(response.body);
        
        // Create a simplified driver object with only the fields we need
        final driverInfo = {
          'name': apiData['driverName'],
          'email': apiData['emailId'],
          'phone': apiData['contactNo'],
          'address': apiData['address'],
          'image': apiData['driverImage']?.toString().trim(),
        };
        
        setState(() {
          driver = driverInfo;
          isLoading = false;
        });
        
        // Optionally save this data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(driverInfo));
      } else {
        debugPrint('Failed to load driver data: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching driver data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to Trips
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverTripsScreen()),
        );
        break;
      case 1:
        // Navigate to ETS Trips
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverETSTripsScreen()),
        );
        break;
      case 2:
        // Already on Profile page
        break;
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
                  expandedHeight: 180.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      '',
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
                            driver?['image'] != null && driver!['image'].isNotEmpty
                                ? CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white,
                                    backgroundImage: NetworkImage(driver!['image']),
                                  )
                                : CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      driver?['name'] != null
                                          ? driver!['name'].toString().substring(0, 1).toUpperCase()
                                          : 'D',
                                      style: TextStyle(
                                        fontSize: 45,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            if (driver?['name'] != null)
                              Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text(
                                  driver!['name'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
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
                                        fontSize: 20,
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
              icon: Icon(MaterialCommunityIcons.bus),
              label: 'ETS Trips',
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: lightTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (label == 'Phone' && value != 'Not available')
                    IconButton(
                      icon: const Icon(Icons.phone, color: primaryColor, size: 20),
                      onPressed: () => makePhoneCall(value),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Remove the first makePhoneCall function definition that's around line 540
  // Keep only the one at line 922-949 which has better error handling
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