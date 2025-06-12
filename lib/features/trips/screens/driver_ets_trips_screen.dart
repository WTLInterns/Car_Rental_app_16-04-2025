import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/profile/screens/driver_profile_screen.dart';
import '../../../features/tracking/screens/ets_tracking_screen.dart';
import '../../../features/trips/screens/driver_trips_screen.dart';

// Updated color palette to match the app's professional style
const Color primaryColor = Color(0xFF3057E3); // Royal blue
const Color secondaryColor = Color(0xFF3057E3); // Same blue for consistency
const Color accentColor = Color(0xFF00796B); // Professional teal
const Color backgroundColor = Color(0xFFF3F5F9); // Light gray background
const Color cardColor = Colors.white; // White card background
const Color textColor = Color(0xFF333333); // Dark text
const Color lightTextColor = Color(0xFF666666); // Medium gray text
const Color mutedTextColor = Color(0xFF666666); // Muted text
const Color successColor = Color(0xFF4CAF50); // Green for success
const Color errorColor = Color(0xFFE53935); // Red for errors
const Color warningColor = Color(0xFFFF9800); // Orange for warnings

class DummyETSTrip {
  final String bookingId;
  final String totalBookings;
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
  final String? etsId;
  final String? slotId;
  final String? pickupLocation;
  final String? dropLocation;

  double? get pickupLatitude => pickupLats.isNotEmpty ? pickupLats[0] : null;

  double? get pickupLongitude => pickupLngs.isNotEmpty ? pickupLngs[0] : null;

  double? get dropLatitude => destLats.isNotEmpty ? destLats[0] : null;

  double? get dropLongitude => destLngs.isNotEmpty ? destLngs[0] : null;

  DummyETSTrip({
    required this.bookingId,
    required this.totalBookings,
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
    this.slotId,
    this.pickupLocation,
    this.dropLocation,
  });
}

class DriverETSTripsScreen extends StatefulWidget {
  const DriverETSTripsScreen({super.key});

  @override
  State<DriverETSTripsScreen> createState() => _DriverETSTripsScreenState();
}

class _DriverETSTripsScreenState extends State<DriverETSTripsScreen>
    with SingleTickerProviderStateMixin {
  String activeTab = 'upcoming';
  Map<String, dynamic>? driver;
  String _userId = '';
  bool isLoading = true;
  bool isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 1;
  bool isDriverActive = true;
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
    // Fetch driver data and trips sequentially
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await getDriverData();
    if (_userId.isNotEmpty) {
      await fetchETSTrips();
    } else {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Invalid user ID. Please log in again.');
    }
    _animationController.forward();
  }

  Future<void> getDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      debugPrint('Fetched userData from SharedPreferences: $userDataString');

      String userId = '';
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        setState(() {
          driver = userData;
          userId = userData['userId']?.toString() ?? '';
        });
      }

      if (userId.isEmpty) {
        userId = prefs.getInt('userId')?.toString() ?? '';
      }

      setState(() {
        _userId = userId;
      });

      debugPrint('Driver ID after all checks: $_userId');

      if (_userId.isEmpty) {
        debugPrint('No valid userId found in any storage location');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (error) {
      debugPrint('Error fetching driver data: $error');
      _showErrorSnackBar('Could not load driver data. Please try again.');
    }
  }

  Future<void> fetchETSTrips() async {
    if (_userId.isEmpty) {
      debugPrint('Cannot fetch trips: userId is empty');
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
      _showErrorSnackBar('User ID not found. Please log in again.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final uri = Uri.parse(
          'https://ets.worldtriplink.com/schedule/driver/$_userId/slots');
      debugPrint('Fetching ETS trips from: $uri');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        // Add authentication headers if required, e.g.:
        // 'Authorization': 'Bearer ${yourToken}',
      });

      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? slots = data['slots'];
        List<DummyETSTrip> trips = [];

        if (slots == null || slots.isEmpty) {
          debugPrint('No slots found in API response');
          setState(() {
            _dummyETSTrips = trips;
          });
          return;
        }

        for (var slot in slots) {
          final bookings = slot['bookings'] as List<dynamic>? ?? [];
          for (var booking in bookings) {
            final userName = booking['userName']?.toString() ?? 'Unknown';
            final phone = booking['phone']?.toString() ?? 'N/A';
            final pickupLocation =
                booking['pickupLocation']?.toString() ?? 'Unknown Location';
            final dropLocation =
                booking['dropLocation']?.toString() ?? 'Unknown Location';
            final pickupTime = booking['pickupTime']?.toString() ?? 'N/A';
            final bookingStatus =
                booking['status']?.toString().toLowerCase() ?? 'unknown';
            final bookingId = booking['bookingId']?.toString() ?? '0';
            final totalBookings = slot['totalBookings']?.toString() ?? '0';
            final slotDate = slot['date']?.toString() ?? 'N/A';
            final slotId = slot['slotId']?.toString();

            String uiStatus = 'upcoming';
            if (bookingStatus == 'pending') {
              uiStatus = 'upcoming';
            } else if (bookingStatus == 'completed') {
              uiStatus = 'completed';
            } else if (bookingStatus == 'cancelled') {
              uiStatus = 'cancelled';
            }

            trips.add(DummyETSTrip(
              bookingId: bookingId,
              totalBookings: totalBookings,
              passengerNames: [userName],
              passengerPhones: [phone],
              pickups: [pickupLocation],
              destinations: [dropLocation],
              pickupLats: [0.0],
              pickupLngs: [0.0],
              destLats: [0.0],
              destLngs: [0.0],
              status: uiStatus,
              fare: 'N/A',
              date: slotDate,
              time: pickupTime,
              passengerCount: 1,
              slotId: slotId,
              pickupLocation: pickupLocation,
              dropLocation: dropLocation,
            ));
          }
        }

        setState(() {
          _dummyETSTrips = trips;
        });
      } else {
        debugPrint('API request failed with status: ${response.statusCode}');
        _showErrorSnackBar(
            'Failed to fetch ETS trips. Status: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching ETS trips: $error');
      _showErrorSnackBar('Could not fetch ETS trips. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
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
          onPressed: () => _initializeData(),
        ),
      ),
    );
  }

  void handleNavigateToETSTracking(DummyETSTrip trip) {
    final pickupLat = trip.pickupLatitude ?? 12.9716;
    final pickupLng = trip.pickupLongitude ?? 77.5946;
    final dropLat = trip.dropLatitude ?? 13.0827;
    final dropLng = trip.dropLongitude ?? 77.5851;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ETSDriverTrackingScreen(
          driverId: _userId,
          etsId: trip.etsId,
          slotId: trip.slotId,
          fromLocation: trip.pickupLocation,
          toLocation: trip.dropLocation,
          pickupCoordinates: LatLng(pickupLat, pickupLng),
          dropCoordinates: LatLng(dropLat, dropLng),
        ),
      ),
    );
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      _showErrorSnackBar('Phone number not available');
      return;
    }

    final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final String telUrl = 'tel:$sanitizedNumber';

    try {
      if (await canLaunchUrlString(telUrl)) {
        await launchUrlString(telUrl);
      } else {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
      _showErrorSnackBar(
          'Error launching phone dialer. Please try manually dialing $sanitizedNumber');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverTripsScreen()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
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
                  icon: const Icon(Icons.arrow_back,
                      size: 24, color: Colors.white),
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
                  icon: const Icon(MaterialCommunityIcons.refresh,
                      size: 24, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isRefreshing = true;
                    });
                    _initializeData();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
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
                          driver!['name'] != null &&
                              driver!['name'].toString().isNotEmpty
                              ? driver!['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase()
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
                            driver!['name']?.toString() ?? 'Driver',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Driver ID: $_userId',
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDriverActive
                                      ? successColor.withOpacity(0.1)
                                      : mutedTextColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isDriverActive
                                          ? MaterialCommunityIcons.check_circle
                                          : MaterialCommunityIcons
                                          .clock_outline,
                                      size: 12,
                                      color: isDriverActive
                                          ? successColor
                                          : mutedTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isDriverActive ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDriverActive
                                            ? successColor
                                            : mutedTextColor,
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
                  Switch(
                    value: isDriverActive,
                    onChanged: (value) {
                      setState(() {
                        isDriverActive = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'You are now ${isDriverActive ? 'online' : 'offline'}'),
                          backgroundColor:
                          isDriverActive ? successColor : mutedTextColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    activeColor: successColor,
                    inactiveTrackColor: mutedTextColor.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
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
          Expanded(
            child: isLoading
                ? const Center(
                child: CircularProgressIndicator(color: secondaryColor))
                : isRefreshing
                ? Stack(
              children: [
                _buildTrip(),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  secondaryColor),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
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
              child: _buildTrip(),
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

  Widget _buildTrip() {
    List<DummyETSTrip> filteredTrips = [];

    if (activeTab == 'upcoming') {
      filteredTrips =
          _dummyETSTrips.where((trip) => trip.status == 'upcoming').toList();
    } else if (activeTab == 'completed') {
      filteredTrips =
          _dummyETSTrips.where((trip) => trip.status == 'completed').toList();
    } else if (activeTab == 'cancelled') {
      filteredTrips =
          _dummyETSTrips.where((trip) => trip.status == 'cancelled').toList();
    }

    if (filteredTrips.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: secondaryColor,
      onRefresh: _initializeData,
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
      submessage = _userId.isEmpty
          ? 'Please log in to view your trips.'
          : 'You have no upcoming ETS trips scheduled.';
    } else if (activeTab == 'completed') {
      iconData = MaterialCommunityIcons.check_circle_outline;
      message = 'No completed ETS trips';
      submessage = 'You haven\'t completed any ETS trips yet.';
    } else {
      iconData = MaterialCommunityIcons.close_circle_outline;
      message = 'No cancelled ETS trips';
      submessage = 'You don\'t have any cancelled ETS trips.';
    }

    return RefreshIndicator(
      color: secondaryColor,
      onRefresh: _initializeData,
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
                        _initializeData();
                      },
                      icon: const Icon(MaterialCommunityIcons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
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
    final Color statusColor = trip.status == 'upcoming'
        ? successColor
        : trip.status == 'completed'
        ? successColor
        : errorColor;
    final String statusText = trip.status == 'upcoming'
        ? 'Confirmed'
        : trip.status == 'completed'
        ? 'Completed'
        : 'Cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ETS label, Booking ID, and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ETS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TotalBookings: ${trip.totalBookings}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${trip.date}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 16),
            // Passenger Information
            Row(
              children: [
                const Icon(
                  MaterialCommunityIcons.account,
                  size: 20,
                  color: secondaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Slot ID: ${trip.slotId ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: lightTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Passenger',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.passengerNames.isNotEmpty
                            ? trip.passengerNames[0]
                            : 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Phone Number
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            MaterialCommunityIcons.phone_outline,
                            size: 20,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: lightTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            trip.passengerPhones.isNotEmpty
                                ? trip.passengerPhones[0]
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => makePhoneCall(
                                trip.passengerPhones.isNotEmpty
                                    ? trip.passengerPhones[0]
                                    : ''),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Pickup and Drop-off Locations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      MaterialCommunityIcons.map_marker,
                      size: 20,
                      color: successColor,
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: successColor.withOpacity(0.3),
                    ),
                    const Icon(
                      MaterialCommunityIcons.map_marker_check,
                      size: 20,
                      color: errorColor,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.pickupLocation ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Drop-off Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.dropLocation ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),
            // Pickup Time
            Row(
              children: [
                const Icon(
                  MaterialCommunityIcons.clock_outline,
                  size: 20,
                  color: secondaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.time,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (trip.status == 'upcoming') ...[
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOutlinedActionButton(
                      MaterialCommunityIcons.map_marker_multiple,
                      'View Route',
                      secondaryColor,
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Route viewer will be available in the next update.'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
              color: lightTextColor,
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

  Widget _buildOutlinedActionButton(
      IconData icon, String text, Color color, VoidCallback onPressed) {
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