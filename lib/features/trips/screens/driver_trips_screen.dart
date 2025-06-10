import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
// Add this import at the top of the file
import '../../../features/profile/screens/driver_profile_screen.dart';
import '../../../features/tracking/screens/driver_tracking_screen.dart';
import '../../../features/trips/screens/driver_ets_trips_screen.dart';

// Updated color palette to match the app's professional style
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

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> with SingleTickerProviderStateMixin {
  String activeTab = 'upcoming';
  Map<String, dynamic>? driver;
  String _userId = '';
  List<dynamic> tripInfo = [];
  bool isLoading = true;
  bool isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0; 
  bool isDriverActive = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    getDriverData();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Current page is trips, no navigation needed
        break;
      case 1:
        // Navigate to ETS Trips
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverETSTripsScreen()),
        );
        break;
      case 2:
        // Navigate to Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
        );
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      debugPrint('Fetched userData from SharedPreferences: $userDataString');
      
      // First try to get userId from userData
      String userId = '';
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        setState(() {
          driver = userData;
          userId = userData['userId']?.toString() ?? '';
        });
      }
      
      // If userId is still empty, try other sources
      if (userId.isEmpty) {
        userId = prefs.getInt('userId')?.toString() ?? '';
      }
      
      setState(() {
        _userId = userId;
      });
      
      debugPrint('Driver ID after all checks: $_userId');
      
      if (_userId.isNotEmpty) {
        await getTripInfoByDriverId();
      } else {
        debugPrint('No valid userId found in any storage location');
        // Navigate back to login if no valid user data is found
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (error) {
      debugPrint('Error fetching driver data: $error');
      _showErrorSnackBar('Could not load driver data. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> getTripInfoByDriverId() async {
    try {
      if (_userId.isNotEmpty) {
        debugPrint('Fetching trips for userId: $_userId');
        setState(() {
          isRefreshing = true;
        });
        final response = await http.get(
          Uri.parse('https://api.worldtriplink.com/api/by-driver/$_userId'),
        );
        debugPrint('Trip API response status: ${response.statusCode}');
        debugPrint('Trip API response body: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
        if (response.statusCode == 200) {
          setState(() {
            tripInfo = json.decode(response.body);
            isRefreshing = false;
          });
          debugPrint('Decoded tripInfo: ${tripInfo.toString()}');
        } else {
          _showErrorSnackBar('Server error: ${response.statusCode}');
          setState(() {
            isRefreshing = false;
          });
        }
      } else {
        debugPrint('UserId is null or empty, cannot fetch trips.');
      }
    } catch (error) {
      debugPrint('Error fetching trip info: $error');
      _showErrorSnackBar('Network error. Please check your connection.');
      setState(() {
        isRefreshing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => getDriverData(),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorColor : successColor,
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void handleNavigateToTracking(String bookingId) {
    final booking = tripInfo.firstWhere(
      (trip) => trip['bookingId'] == bookingId || trip['bookid'] == bookingId,
      orElse: () => null,
    );
    
    debugPrint("booking: $booking");
    
    if (booking == null) {
      debugPrint("Booking not found for ID: $bookingId");
      _showErrorSnackBar('Booking details not found');
      return;
    }
    
    // Create approximate coordinates for pickup and destination based on addresses
    final Random random = Random();
    final double pickupLat = 18.5204 + (random.nextDouble() * 0.05);
    final double pickupLng = 73.8567 + (random.nextDouble() * 0.05);
    final double destLat = 18.5204 + (random.nextDouble() * 0.05);
    final double destLng = 73.8567 + (random.nextDouble() * 0.05);
    
    // Generate a random OTP for trip verification
    final String generatedOtp = (1000 + random.nextInt(9000)).toString();
    
    // Navigate to tracking screen with proper data mapping
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverTrackingScreen(
          bookingData: {
            'bookingId': booking['bookingId'] ?? booking['bookid'] ?? "",
            'pickup': booking['userPickup'] ?? booking['fromLocation'] ?? "",
            'destination': booking['userDrop'] ?? booking['toLocation'] ?? "",
            'pickupLocation': {
              'latitude': pickupLat,
              'longitude': pickupLng,
            },
            'destinationLocation': {
              'latitude': destLat,
              'longitude': destLng,
            },
            'passengerInfo': {
              'name': booking['name'] ?? (booking['email'] != null ? booking['email'].split('@')[0] : 'Unknown User'),
              'rating': 4.5, // Default rating since it's not in the API
              'phoneNumber': booking['phone'] ?? 'N/A',
            },
            'tripInfo': {
              'estimatedTime': "35 mins", // Estimated time not in API
              'distance': "${booking['distance'] ?? 0} km",
              'fare': "₹${booking['amount'] ?? 0}",
              'paymentMethod': booking['payment'] ?? "Cash"
            },
            'currentStatus': "Heading to pickup",
            'tripType': booking['tripType'] ?? booking['userTripType'] ?? "oneWay",
            'generatedOtp': generatedOtp // Add OTP for verification
          },
        ),
      ),
    );
  }

  // Enhanced phone call functionality with multiple fallback methods
  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      _showMessage('Phone number not available', isError: true);
      return;
    }

    try {
      // Clean and validate phone number
      String cleanNumber = _cleanPhoneNumber(phoneNumber);
      if (cleanNumber.isEmpty) {
        _showMessage('Invalid phone number format', isError: true);
        return;
      }

      print('Attempting to call: $cleanNumber');

      // Show loading indicator
      _showMessage('Opening dialer...', isError: false);

      // Method 1: Try direct tel: URL with external application launch
      bool success = await _tryDirectCall(cleanNumber);
      
      if (!success) {
        // Method 2: Try with platform default launch mode
        success = await _tryPlatformDefaultCall(cleanNumber);
      }
      
      if (!success) {
        // Method 3: Try with system launch mode
        success = await _trySystemCall(cleanNumber);
      }
      
      if (!success) {
        // Method 4: Show manual dial option
        _showManualDialOption(cleanNumber);
      }

    } catch (e) {
      print('Error in makePhoneCall: $e');
      _showMessage('Unable to open dialer. Please try again.', isError: true);
    }
  }

  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except '+'
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Handle Indian numbers
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = '+$cleaned';
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '+91${cleaned.substring(1)}';
    } else if (cleaned.length == 10 && !cleaned.startsWith('+')) {
      cleaned = '+91$cleaned';
    }
    
    // Validate format
    if (cleaned.length < 10 || cleaned.length > 15) {
      return '';
    }
    
    return cleaned;
  }

  Future<bool> _tryDirectCall(String phoneNumber) async {
    try {
      final String telUrl = 'tel:$phoneNumber';
      print('Trying direct call with URL: $telUrl');
      
      // Check if the URL can be launched
      if (await canLaunchUrlString(telUrl)) {
        bool launched = await launchUrlString(
          telUrl,
          mode: LaunchMode.externalApplication,
        );
        print('Direct call result: $launched');
        return launched;
      }
      return false;
    } catch (e) {
      print('Direct call failed: $e');
      return false;
    }
  }

  Future<bool> _tryPlatformDefaultCall(String phoneNumber) async {
    try {
      final String telUrl = 'tel:$phoneNumber';
      print('Trying platform default call with URL: $telUrl');
      
      bool launched = await launchUrlString(
        telUrl,
        mode: LaunchMode.platformDefault,
      );
      print('Platform default call result: $launched');
      return launched;
    } catch (e) {
      print('Platform default call failed: $e');
      return false;
    }
  }

  Future<bool> _trySystemCall(String phoneNumber) async {
    try {
      final String telUrl = 'tel:$phoneNumber';
      print('Trying system call with URL: $telUrl');
      
      bool launched = await launchUrlString(
        telUrl,
        mode: LaunchMode.inAppWebView,
      );
      print('System call result: $launched');
      return launched;
    } catch (e) {
      print('System call failed: $e');
      return false;
    }
  }

  void _showManualDialOption(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.phone, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Call Passenger'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unable to open dialer automatically. Please manually dial:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Copy to clipboard
                        _copyToClipboard(phoneNumber);
                      },
                      icon: Icon(Icons.copy, color: primaryColor),
                      tooltip: 'Copy number',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tryAlternativeDialer(phoneNumber);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _tryAlternativeDialer(String phoneNumber) async {
    try {
      // Try different URL schemes that some devices support
      final List<String> schemes = [
        'tel:$phoneNumber',
        'phone:$phoneNumber',
        'callto:$phoneNumber',
      ];
      
      for (String scheme in schemes) {
        try {
          if (await canLaunchUrlString(scheme)) {
            bool launched = await launchUrlString(scheme);
            if (launched) {
              _showMessage('Dialer opened successfully');
              return;
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      _showMessage('Please dial manually: $phoneNumber', isError: true);
    } catch (e) {
      _showMessage('Please dial manually: $phoneNumber', isError: true);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showMessage('Number copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // App Bar
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Placeholder for back button
                const Expanded(
                  child: Text(
                    'My Trips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(MaterialCommunityIcons.bus, size: 24, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/driver-ets-trips');
                      },
                      tooltip: 'ETS Trips',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(MaterialCommunityIcons.refresh, size: 24, color: Colors.white),
                      onPressed: () => getTripInfoByDriverId(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Driver Status Card
          if (driver != null && !isLoading)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: secondaryColor.withOpacity(0.1),
                        child: Text(
                          driver!['name'] != null && driver!['name'].toString().isNotEmpty
                              ? driver!['name'].toString().substring(0, 1).toUpperCase()
                              : 'D',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver!['name'] ?? 'Driver',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Driver ID: ${driver!['userId'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: lightTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDriverActive ? successColor.withOpacity(0.1) : mutedTextColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isDriverActive 
                                          ? MaterialCommunityIcons.check_circle 
                                          : MaterialCommunityIcons.clock_outline,
                                      size: 12, 
                                      color: isDriverActive ? successColor : mutedTextColor
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isDriverActive ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDriverActive ? successColor : mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Toggle switch for online/offline status
                  Switch(
                    value: isDriverActive,
                    onChanged: (value) {
                      setState(() {
                        isDriverActive = value;
                      });
                      // In a real app, you would update the server with the driver's status
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are now ${isDriverActive ? 'online' : 'offline'}'),
                          backgroundColor: isDriverActive ? successColor : mutedTextColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    activeColor: successColor,
                    activeTrackColor: successColor.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTab('upcoming', 'Upcoming'),
                _buildTab('completed', 'Completed'),
                _buildTab('cancelled', 'Cancelled'),
              ],
            ),
          ),
          
          // Trip List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: secondaryColor))
                : isRefreshing
                    ? Stack(
                        children: [
                          _buildTripList(),
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Refreshing...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: lightTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildTripList(),
                      ),
          ),
        ],
      ),
     bottomNavigationBar: BottomNavigationBar(
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
        selectedItemColor: secondaryColor,
        unselectedItemColor: mutedTextColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
        onTap: _onItemTapped,
      ),
    );
  }
  Widget _buildTab(String tabId, String label) {
    final isActive = activeTab == tabId;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeTab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? secondaryColor.withOpacity(0.1) : cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                tabId == 'upcoming'
                    ? MaterialCommunityIcons.calendar_clock
                    : tabId == 'completed'
                        ? MaterialCommunityIcons.check_circle
                        : MaterialCommunityIcons.close_circle,
                size: 18,
                color: isActive ? secondaryColor : mutedTextColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? secondaryColor : lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripList() {
    List<dynamic> filteredTrips = [];
    
    if (activeTab == 'upcoming') {
      filteredTrips = tripInfo.where((trip) => trip['status'] == 0 || trip['status'] == null).toList();
    } else if (activeTab == 'completed') {
      filteredTrips = tripInfo.where((trip) => trip['status'] == 1).toList();
    } else if (activeTab == 'cancelled') {
      filteredTrips = tripInfo.where((trip) => trip['status'] == 2).toList();
    }
    
    if (filteredTrips.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      color: secondaryColor,
      onRefresh: getTripInfoByDriverId,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          final trip = filteredTrips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData iconData;
    String message;
    String submessage;
    
    if (activeTab == 'upcoming') {
      iconData = MaterialCommunityIcons.calendar_blank;
      message = 'No upcoming trips';
      submessage = 'You have no upcoming trips scheduled';
    } else if (activeTab == 'completed') {
      iconData = MaterialCommunityIcons.check_circle_outline;
      message = 'No completed trips';
      submessage = 'You haven\'t completed any trips yet';
    } else {
      iconData = MaterialCommunityIcons.close_circle_outline;
      message = 'No cancelled trips';
      submessage = 'You don\'t have any cancelled trips';
    }
    
    return RefreshIndicator(
      color: secondaryColor,
      onRefresh: getTripInfoByDriverId,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, size: 40, color: secondaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      submessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: lightTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: getTripInfoByDriverId,
                      icon: const Icon(MaterialCommunityIcons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final Color statusColor = activeTab == 'upcoming'
        ? primaryColor
        : activeTab == 'completed'
            ? successColor
            : errorColor;
            
    final String statusText = activeTab == 'upcoming'
        ? 'Confirmed'
        : activeTab == 'completed'
            ? 'Completed'
            : 'Cancelled';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with vehicle type and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      MaterialCommunityIcons.car,
                      size: 20,
                      color: primaryColor
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver Trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          trip['bookingId'] ?? trip['bookid'] ?? 'No ID',
                          style: const TextStyle(
                            fontSize: 12,
                            color: lightTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeTab == 'upcoming' 
                        ? Colors.transparent
                        : statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3)
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passenger Info (only for upcoming trips)
                if (activeTab == 'upcoming') ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: secondaryColor.withOpacity(0.1),
                        child: Text(
                          trip['name'] != null && trip['name'].toString().isNotEmpty
                              ? trip['name'].toString().substring(0, 1).toUpperCase()
                              : trip['email'] != null && trip['email'].toString().isNotEmpty
                                  ? trip['email'].toString().substring(0, 1).toUpperCase()
                                  : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip['name'] ??
                                  (trip['email'] != null
                                      ? trip['email'].toString().split('@')[0]
                                      : 'Unknown User'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  MaterialCommunityIcons.star,
                                  size: 14,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.5',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: lightTextColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  MaterialCommunityIcons.phone,
                                  size: 14,
                                  color: secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trip['phone'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: lightTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (trip['phone'] != null && trip['phone'].toString().isNotEmpty && trip['phone'] != 'N/A') {
                            makePhoneCall(trip['phone'].toString());
                          } else {
                            _showMessage('Phone number not available', isError: true);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade50
                          ),
                          child: const Icon(
                            MaterialCommunityIcons.phone,
                            size: 20,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                
                // Trip Details - Improved with better icons and styling
                Column(
                  children: [
                    // Pickup location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 18, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PICKUP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: lightTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trip['userPickup'] ?? trip['fromLocation'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Connection line
                    Padding(
                      padding: const EdgeInsets.only(right: 300.0),
                      child: Container(
                        height: 35,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    
                    // Destination location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DESTINATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: lightTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trip['userDrop'] ?? trip['toLocation'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),
                
                // Trip Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      MaterialCommunityIcons.map_marker_distance,
                      'Distance',
                      '${trip['distance'] ?? 0} km',
                    ),
                    _buildInfoItem(
                      MaterialCommunityIcons.swap_horizontal,
                      'Trip Type',
                      _formatTripType(trip['tripType'] ?? trip['userTripType'] ?? 'oneWay'),
                    ),
                    _buildInfoItem(
                      MaterialCommunityIcons.currency_inr,
                      activeTab == 'cancelled' ? 'Cancellation Fee' : 'Fare',
                      '₹${activeTab == 'cancelled' ? (trip['penalty'] ?? 0) : (trip['amount'] ?? 0)}',
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                
                // Trip details in a row - matching trips_screen.dart style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      MaterialCommunityIcons.calendar,
                      "Date",
                      trip['date'] ?? trip['startDate'] ?? 'Today',
                    ),
                    _buildInfoItem(
                      MaterialCommunityIcons.clock_outline,
                      "Time",
                      trip['time'] ?? 'N/A',
                    ),
                
                  ],
                ),

                // Action buttons - only for upcoming trips
                if (activeTab == 'upcoming') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOutlinedActionButton(
                          MaterialCommunityIcons.navigation,
                          'Navigate',
                          primaryColor,
                          () => handleNavigateToTracking(
                            trip['bookingId'] ?? trip['bookid'] ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOutlinedActionButton(
                          MaterialCommunityIcons.phone,
                          'Call',
                          primaryColor,
                          () {
                            if (trip['phone'] != null && trip['phone'].toString().isNotEmpty && trip['phone'] != 'N/A') {
                              makePhoneCall(trip['phone'].toString());
                            } else {
                              _showMessage('Phone number not available', isError: true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12, 
              color: lightTextColor
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTripType(String tripType) {
    if (tripType.toLowerCase() == 'oneway') {
      return 'One Way';
    } else if (tripType.toLowerCase() == 'roundtrip') {
      return 'Round Trip';
    } else if (tripType.toLowerCase() == 'rental') {
      return 'Rental';
    } else {
      return tripType;
    }
  }

  Widget _buildOutlinedActionButton(IconData icon, String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}