import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/profile/screens/driver_profile_screen.dart';
import '../../../features/tracking/screens/ets_tracking_screen.dart';
import '../../../features/trips/screens/driver_trips_screen.dart';
// Updated color palette to match the app's professional style
const Color primaryColor = Color(0xFF3057E3);      // Royal blue
const Color secondaryColor = Color(0xFF3057E3);    // Same blue for consistency
const Color accentColor = Color(0xFFFFCC00);       // Yellow/gold accent
const Color backgroundColor = Color(0xFFF3F5F9);   // Light gray background
const Color cardColor = Colors.white;              // White card background
const Color textColor = Color(0xFF333333);         // Dark text
const Color lightTextColor = Color(0xFF666666);    // Medium gray text
const Color mutedTextColor = Color(0xFF666666);    // Muted text
const Color successColor = Color(0xFF4CAF50);      // Green for success
const Color errorColor = Color(0xFFE53935);        // Red for errors
const Color warningColor = Color(0xFFFF9800);      // Orange for warnings

class DummyETSTrip {
  final String bookingId;
  final List<String> passengerNames;
  final List<String> passengerPhones;
  final List<String> pickups;
  final List<String> destinations;
  final List<double> pickupLats;
  final List<double> pickupLngs;
  final List<double> destLats;
  final List<double> destLngs;
  final String status;
  final String fare;
  final String date;
  final String time;
  final int passengerCount;
  
  // Added fields needed for tracking navigation
  final String? etsId;
  final String? pickupLocation;
  final String? dropLocation;

  // Getters to simplify access for single-passenger trips
  double? get pickupLatitude => pickupLats.isNotEmpty ? pickupLats[0] : null;
  double? get pickupLongitude => pickupLngs.isNotEmpty ? pickupLngs[0] : null;
  double? get dropLatitude => destLats.isNotEmpty ? destLats[0] : null;
  double? get dropLongitude => destLngs.isNotEmpty ? destLngs[0] : null;

  DummyETSTrip({
    required this.bookingId,
    required this.passengerNames,
    required this.passengerPhones,
    required this.pickups,
    required this.destinations,
    required this.pickupLats,
    required this.pickupLngs,
    required this.destLats,
    required this.destLngs,
    required this.status,
    required this.fare,
    required this.date,
    required this.time,
    required this.passengerCount,
    this.etsId,
    this.pickupLocation,
    this.dropLocation,
  });
}

class DriverETSTripsScreen extends StatefulWidget {
  const DriverETSTripsScreen({super.key});

  @override
  State<DriverETSTripsScreen> createState() => _DriverETSTripsScreenState();
}

class _DriverETSTripsScreenState extends State<DriverETSTripsScreen> with SingleTickerProviderStateMixin {
  String activeTab = 'upcoming';
  Map<String, dynamic>? driver;
  String _userId = '';
  String driverId = ''; // Added driver ID for tracking
  bool isLoading = true;
  bool isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 1; 
  bool isDriverActive = true;
  bool isList = true;

  // Generate dummy ETS trips
  List<DummyETSTrip> _dummyETSTrips = [];

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
    _generateDummyETSTrips();
    getDriverData();
  }

  void _generateDummyETSTrips() {
    final random = Random();
    
    // Create several dummy ETS trips
    _dummyETSTrips = [
      DummyETSTrip(
        bookingId: 'ETS001',
        passengerNames: ['John Smith', 'Maria Garcia', 'David Lee'],
        passengerPhones: ['+91 9871234560', '+91 9871234561', '+91 9871234562'],
        pickups: ['Hinjewadi Phase 1', 'Baner Road', 'Aundh'],
        destinations: ['Magarpatta City', 'Koregaon Park', 'Kalyani Nagar'],
        pickupLats: [18.5912 + random.nextDouble() * 0.01, 18.5597 + random.nextDouble() * 0.01, 18.5679 + random.nextDouble() * 0.01],
        pickupLngs: [73.7380 + random.nextDouble() * 0.01, 73.7997 + random.nextDouble() * 0.01, 73.8143 + random.nextDouble() * 0.01],
        destLats: [18.5158 + random.nextDouble() * 0.01, 18.5362 + random.nextDouble() * 0.01, 18.5471 + random.nextDouble() * 0.01],
        destLngs: [73.9272 + random.nextDouble() * 0.01, 73.8978 + random.nextDouble() * 0.01, 73.9062 + random.nextDouble() * 0.01],
        status: 'upcoming',
        fare: '₹750',
        date: '2024-04-18',
        time: '09:30',
        passengerCount: 3,
      ),
      DummyETSTrip(
        bookingId: 'ETS002',
        passengerNames: ['Sarah Johnson', 'Michael Brown', 'Linda Davis', 'Robert Wilson'],
        passengerPhones: ['+91 9871234563', '+91 9871234564', '+91 9871234565', '+91 9871234566'],
        pickups: ['Viman Nagar', 'Kharadi', 'Hadapsar', 'Magarpatta'],
        destinations: ['Shivajinagar', 'FC Road', 'JM Road', 'Deccan'],
        pickupLats: [18.5679 + random.nextDouble() * 0.01, 18.5509 + random.nextDouble() * 0.01, 18.5089 + random.nextDouble() * 0.01, 18.5158 + random.nextDouble() * 0.01],
        pickupLngs: [73.9143 + random.nextDouble() * 0.01, 73.9437 + random.nextDouble() * 0.01, 73.9260 + random.nextDouble() * 0.01, 73.9272 + random.nextDouble() * 0.01],
        destLats: [18.5314 + random.nextDouble() * 0.01, 18.5236 + random.nextDouble() * 0.01, 18.5226 + random.nextDouble() * 0.01, 18.5182 + random.nextDouble() * 0.01],
        destLngs: [73.8446 + random.nextDouble() * 0.01, 73.8415 + random.nextDouble() * 0.01, 73.8470 + random.nextDouble() * 0.01, 73.8385 + random.nextDouble() * 0.01],
        status: 'upcoming',
        fare: '₹950',
        date: '2024-04-19',
        time: '10:00',
        passengerCount: 4,
      ),
      DummyETSTrip(
        bookingId: 'ETS003',
        passengerNames: ['Emily Wilson', 'James Taylor'],
        passengerPhones: ['+91 9871234567', '+91 9871234568'],
        pickups: ['Wakad', 'Pimple Saudagar'],
        destinations: ['Camp', 'Kondhwa'],
        pickupLats: [18.5907 + random.nextDouble() * 0.01, 18.5895 + random.nextDouble() * 0.01],
        pickupLngs: [73.7652 + random.nextDouble() * 0.01, 73.8222 + random.nextDouble() * 0.01],
        destLats: [18.5162 + random.nextDouble() * 0.01, 18.4706 + random.nextDouble() * 0.01],
        destLngs: [73.8735 + random.nextDouble() * 0.01, 73.8903 + random.nextDouble() * 0.01],
        status: 'completed',
        fare: '₹550',
        date: '2024-04-15',
        time: '16:30',
        passengerCount: 2,
      ),
      DummyETSTrip(
        bookingId: 'ETS004',
        passengerNames: ['Jennifer Moore', 'Thomas Anderson', 'Jessica Allen'],
        passengerPhones: ['+91 9871234569', '+91 9871234570', '+91 9871234571'],
        pickups: ['Baner', 'Balewadi', 'Sus Road'],
        destinations: ['Koregaon Park', 'Kalyani Nagar', 'Viman Nagar'],
        pickupLats: [18.5597 + random.nextDouble() * 0.01, 18.5741 + random.nextDouble() * 0.01, 18.5832 + random.nextDouble() * 0.01],
        pickupLngs: [73.7997 + random.nextDouble() * 0.01, 73.7870 + random.nextDouble() * 0.01, 73.7975 + random.nextDouble() * 0.01],
        destLats: [18.5362 + random.nextDouble() * 0.01, 18.5471 + random.nextDouble() * 0.01, 18.5679 + random.nextDouble() * 0.01],
        destLngs: [73.8978 + random.nextDouble() * 0.01, 73.9062 + random.nextDouble() * 0.01, 73.9143 + random.nextDouble() * 0.01],
        status: 'cancelled',
        fare: '₹650',
        date: '2024-04-16',
        time: '11:15',
        passengerCount: 3,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to regular Trips
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverTripsScreen()),
        );
        break;
      case 1:
        // Current page is ETS trips, no navigation needed
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
      
      if (_userId.isEmpty) {
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

  void handleNavigateToETSTracking(DummyETSTrip trip) {
    // Extract coordinates from trip data
    // For demo purposes, generating coordinates around Bangalore if not available
    final pickupLat = trip.pickupLatitude ?? 12.9716;
    final pickupLng = trip.pickupLongitude ?? 77.5946;
    final dropLat = trip.dropLatitude ?? 13.0827;
    final dropLng = trip.dropLongitude ?? 77.5851;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ETSDriverTrackingScreen(
          etsId: trip.etsId,
          driverId: driverId,
          fromLocation: trip.pickupLocation,
          toLocation: trip.dropLocation,
          pickupCoordinates: LatLng(pickupLat, pickupLng),
          dropCoordinates: LatLng(dropLat, dropLng),
        ),
      ),
    );
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('Phone number not available');
      return;
    }
    
    // Sanitize phone number - remove spaces and special characters except '+'
    final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final String telUrl = 'tel:$sanitizedNumber';
    
    try {
      // Use the more reliable launchUrlString
      if (await canLaunchUrlString(telUrl)) {
        await launchUrlString(telUrl);
      } else {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
      _showErrorSnackBar('Error launching phone dialer. Please try manually dialing $sanitizedNumber');
    }
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/driver-trips');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Expanded(
                  child: Text(
                    'ETS Trips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(MaterialCommunityIcons.refresh, size: 24, color: Colors.white),
                  onPressed: () => setState(() { isRefreshing = false; }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
    List<DummyETSTrip> filteredTrips = [];
    
    if (activeTab == 'upcoming') {
      filteredTrips = _dummyETSTrips.where((trip) => trip.status == 'upcoming').toList();
    } else if (activeTab == 'completed') {
      filteredTrips = _dummyETSTrips.where((trip) => trip.status == 'completed').toList();
    } else if (activeTab == 'cancelled') {
      filteredTrips = _dummyETSTrips.where((trip) => trip.status == 'cancelled').toList();
    }
    
    if (filteredTrips.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      color: secondaryColor,
      onRefresh: () async {
        setState(() {
          isRefreshing = true;
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        setState(() {
          isRefreshing = false;
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          final trip = filteredTrips[index];
          return _buildETSTripCard(trip);
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
      message = 'No upcoming ETS trips';
      submessage = 'You have no upcoming ETS trips scheduled';
    } else if (activeTab == 'completed') {
      iconData = MaterialCommunityIcons.check_circle_outline;
      message = 'No completed ETS trips';
      submessage = 'You haven\'t completed any ETS trips yet';
    } else {
      iconData = MaterialCommunityIcons.close_circle_outline;
      message = 'No cancelled ETS trips';
      submessage = 'You don\'t have any cancelled ETS trips';
    }
    
    return RefreshIndicator(
      color: secondaryColor,
      onRefresh: () async {
        setState(() {
          isRefreshing = true;
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        setState(() {
          isRefreshing = false;
        });
      },
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
                      onPressed: () {
                        setState(() {
                          isRefreshing = true;
                        });
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) {
                            setState(() {
                              isRefreshing = false;
                            });
                          }
                        });
                      },
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

  Widget _buildETSTripCard(DummyETSTrip trip) {
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
          // Header with ETS badge and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ETS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57C00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Employee Transport Service',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              trip.bookingId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                // Passenger count info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MaterialCommunityIcons.account_group,
                        size: 16,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.passengerCount} Passengers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                // Passenger list - expanded for upcoming trips
                if (activeTab == 'upcoming') ...[
                  const Text(
                    'Passengers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trip.passengerCount,
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.primaries[index % Colors.primaries.length].withOpacity(0.2),
                                child: Text(
                                  trip.passengerNames[index].isNotEmpty 
                                      ? trip.passengerNames[index].substring(0, 1)
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.primaries[index % Colors.primaries.length],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip.passengerNames[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.passengerPhones[index],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: lightTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => makePhoneCall(trip.passengerPhones[index]),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: secondaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    MaterialCommunityIcons.phone,
                                    size: 16,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Simplified passenger info for completed/cancelled trips
                  Text(
                    'Passengers: ${trip.passengerNames.join(", ")}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Trip Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      MaterialCommunityIcons.calendar,
                      "Date",
                      trip.date,
                    ),
                    _buildInfoItem(
                      MaterialCommunityIcons.clock_outline,
                      "Time",
                      trip.time,
                    ),
                    _buildInfoItem(
                      MaterialCommunityIcons.currency_inr,
                      "Fare",
                      trip.fare,
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
                          () => handleNavigateToETSTracking(trip),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOutlinedActionButton(
                          MaterialCommunityIcons.map_marker_multiple,
                          'View Route',
                          secondaryColor,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Route viewer will be available in the next update.'),
                              ),
                            );
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

  Widget _buildOutlinedActionButton(IconData icon, String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
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