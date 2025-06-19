import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../features/tracking/screens/tracking_screen.dart';
import '../../../features/booking/screens/user_home_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

// Professional color palette - matching login screen
const Color primaryColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFF4A90E2);
const Color accentColor = Color(0xFFFFCC00);
const Color backgroundColor = Colors.white;
const Color cardColor = Colors.white;
const Color surfaceColor = Color(0xFFF0F7FF);
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF666666);
const Color mutedTextColor = Color(0xFFA0A0A0);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);
const Color dangerColor = Color(0xFFF44336);
const Color lightAccentColor = Color(0xFFF0F7FF);

class Trip {
  final String bookingId;
  final String fromLocation;
  final String toLocation;
  final String startDate;
  final String time;
  final String car;
  final double amount;
  final int status;
  final String name;
  final String phone;
  final double? distance;
  final Map<String, dynamic>? vendorDriver;
  final Map<String, dynamic>? vendorCab;
  final Map<String, dynamic>? carRentalUser;
  final String tripType;

  Trip({
    required this.bookingId,
    required this.fromLocation,
    required this.toLocation,
    required this.startDate,
    required this.time,
    required this.car,
    required this.amount,
    required this.status,
    required this.name,
    required this.phone,
    this.distance,
    this.vendorDriver,
    this.vendorCab,
    this.carRentalUser,
    this.tripType = 'oneWay',
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      bookingId: json['bookingId'] ?? json['bookid'] ?? 'N/A',
      fromLocation:
      json['fromLocation'] ?? json['userPickup'] ?? 'Unknown location',
      toLocation: json['toLocation'] ?? json['userDrop'] ?? 'Unknown location',
      startDate: json['startDate'] ?? json['date'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
      car: (json['car'] ?? json['vendorCab']?['carName'] ?? 'cab').toString(),
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      status: json['status'] is String
          ? int.tryParse(json['status']) ?? 0
          : json['status'] as int? ?? 0,
      name: json['name'] ?? json['vendorDriver']?['driverName'] ?? 'Unknown',
      phone: json['phone'] ?? json['vendorDriver']?['contactNo'] ?? 'N/A',
      distance: json['distance'] is num
          ? (json['distance'] as num).toDouble()
          : double.tryParse(json['distance']?.toString() ?? '') ?? 0.0,
      vendorDriver: json['vendorDriver'] as Map<String, dynamic>?,
      vendorCab: json['vendorCab'] as Map<String, dynamic>?,
      carRentalUser: json['carRentalUser'] as Map<String, dynamic>?,
      tripType: json['tripType'] ?? json['userTripType'] ?? 'oneWay',
    );
  }

  @override
  String toString() {
    return 'Trip{bookingId: $bookingId, from: $fromLocation, to: $toLocation, date: $startDate, status: $status}';
  }
}

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _activeTab = 0;
  String _userId = '';
  List<Trip> _trips = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    setState(() {
      _userId =
          prefs.getInt('userId')?.toString() ?? prefs.getString('userId') ?? '';
      if (userDataString != null) {
        try {
          _userData = json.decode(userDataString);
        } catch (e) {
          debugPrint('Error decoding user data: $e');
        }
      }
    });

    await _getUserTripInfo();
  }

  Future<void> _getUserTripInfo() async {
    try {
      debugPrint('Fetching trips for user: $_userId');
      final response = await http.get(
        Uri.parse('https://api.worldtriplink.com/api/by-user/$_userId'),
      );

      debugPrint('API Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> tripsData;

        if (responseData is List) {
          tripsData = responseData;
        } else if (responseData is Map &&
            responseData.containsKey('data') &&
            responseData['data'] is List) {
          tripsData = responseData['data'];
        } else {
          tripsData = [responseData];
        }

        debugPrint('Decoded JSON: ${tripsData.runtimeType}');

        final List<Trip> loadedTrips = tripsData.map((tripJson) {
          debugPrint(
              'Processing trip: ${tripJson['bookingId'] ?? tripJson['bookid']}');
          return Trip.fromJson(tripJson);
        }).toList();

        // Sort by startDate in descending order (newest first)
        loadedTrips.sort((b, a) {
          final aDate = DateTime.tryParse(a.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse(b.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate); // Newest first
        });

        // Calculate trip counts
        final upcomingCount =
            loadedTrips.where((trip) => trip.status == 0).length;
        final completedCount =
            loadedTrips.where((trip) => trip.status == 2).length;
        final cancelledCount =
            loadedTrips.where((trip) => trip.status == 3).length;

        // Save counts to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('upcomingTripCount', upcomingCount);
        await prefs.setInt('completedTripCount', completedCount);
        await prefs.setInt('cancelledTripCount', cancelledCount);

        debugPrint(
            'Saved trip counts - Upcoming: $upcomingCount, Completed: $completedCount, Cancelled: $cancelledCount');
        debugPrint('Successfully loaded ${loadedTrips.length} trips');

        setState(() {
          _trips = loadedTrips;
          _isLoading = false;
        });
      } else {
        debugPrint('API Error: ${response.statusCode}');
        setState(() => _isLoading = false);
        _showMessage('Failed to load trips', isError: true);
      }
    } catch (error) {
      debugPrint('Error fetching trips: $error');
      setState(() => _isLoading = false);
      _showMessage('Error fetching trips', isError: true);
    }
  }

  List<Trip> _filterTrips() {
    return _trips.where((trip) {
      switch (_activeTab) {
        case 0: // Upcoming
          return trip.status == 0;
        case 1: // Completed
          return trip.status == 2;
        case 2: // Cancelled
          return trip.status == 3;
        default:
          return false;
      }
    }).toList();
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'N/A') {
      _showMessage('Phone number not available', isError: true);
      return;
    }

    try {
      String cleanNumber = _cleanPhoneNumber(phoneNumber);
      if (cleanNumber.isEmpty) {
        _showMessage('Invalid phone number format', isError: true);
        return;
      }

      debugPrint('Attempting to call: $cleanNumber');
      _showMessage('Opening dialer...', isError: false);

      bool success = await _tryDirectCall(cleanNumber);

      if (!success) {
        success = await _tryPlatformDefaultCall(cleanNumber);
      }

      if (!success) {
        success = await _trySystemCall(cleanNumber);
      }

      if (!success) {
        _showManualDialOption(cleanNumber);
      }
    } catch (e) {
      debugPrint('Error in makePhoneCall: $e');
      _showMessage('Unable to open dialer. Please try again.', isError: true);
    }
  }

  String _cleanPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = '+$cleaned';
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '+91${cleaned.substring(1)}';
    } else if (cleaned.length == 10 && !cleaned.startsWith('+')) {
      cleaned = '+91$cleaned';
    }

    if (cleaned.length < 10 || cleaned.length > 15) {
      return '';
    }

    return cleaned;
  }

  Future<bool> _tryDirectCall(String phoneNumber) async {
    try {
      final String telUrl = 'tel:$phoneNumber';
      debugPrint('Trying direct call with URL: $telUrl');

      if (await canLaunchUrlString(telUrl)) {
        bool launched = await launchUrlString(
          telUrl,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('Direct call result: $launched');
        return launched;
      }
      return false;
    } catch (e) {
      debugPrint('Direct call failed: $e');
      return false;
    }
  }

  Future<bool> _tryPlatformDefaultCall(String phoneNumber) async {
    try {
      final String telUrl = 'tel:$phoneNumber';
      debugPrint('Trying platform default call with URL: $telUrl');

      bool launched = await launchUrlString(
        telUrl,
        mode: LaunchMode.platformDefault,
      );
      debugPrint('Platform default call result: $launched');
      return launched;
    } catch (e) {
      debugPrint('Platform default call failed: $e');
      return false;
    }
  }

  Future<bool> _trySystemCall(String phoneNumber) async {
    try {
      final String telUrl = 'tel:$phoneNumber';
      debugPrint('Trying system call with URL: $telUrl');

      bool launched = await launchUrlString(
        telUrl,
        mode: LaunchMode.inAppWebView,
      );
      debugPrint('System call result: $launched');
      return launched;
    } catch (e) {
      debugPrint('System call failed: $e');
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
              const Text('Call Driver'),
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
                  color: lightAccentColor,
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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? dangerColor : successColor,
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Map<String, double> _extractCoordinatesFromAddress(String address) {
    double latitude = 19.0760;
    double longitude = 72.8777;

    if (address.toLowerCase().contains('pune')) {
      latitude = 18.5204;
      longitude = 73.8567;
    } else if (address.toLowerCase().contains('mumbai')) {
      latitude = 19.0760;
      longitude = 72.8777;
    } else if (address.toLowerCase().contains('delhi')) {
      latitude = 28.6139;
      longitude = 77.2090;
    } else if (address.toLowerCase().contains('bangalore') ||
        address.toLowerCase().contains('bengaluru')) {
      latitude = 12.9716;
      longitude = 77.5946;
    }

    return {'latitude': latitude, 'longitude': longitude};
  }

  void _handleTrackPress(Trip trip) {
    try {
      final double userLatitude =
          trip.carRentalUser?['userlatitude']?.toDouble() ?? 0.0;
      final double userLongitude =
          trip.carRentalUser?['userlongitude']?.toDouble() ?? 0.0;
      final double driverLatitude =
          trip.vendorDriver?['driverLatitude']?.toDouble() ?? 0.0;
      final double driverLongitude =
          trip.vendorDriver?['driverLongitude']?.toDouble() ?? 0.0;

      Map<String, double> pickupCoords = {
        'latitude': userLatitude,
        'longitude': userLongitude
      };

      if (userLatitude == 0.0 || userLongitude == 0.0) {
        pickupCoords = _extractCoordinatesFromAddress(trip.fromLocation);
      }

      Map<String, double> destCoords =
      _extractCoordinatesFromAddress(trip.toLocation);

      final Map<String, dynamic> bookingData = {
        'bookingId': trip.bookingId,
        'pickup': trip.fromLocation,
        'destination': trip.toLocation,
        'tripType': trip.tripType,
        'driverInfo': {
          'name': trip.vendorDriver?['driverName'] ?? trip.name ?? 'Driver',
          'rating': trip.vendorDriver?['rating'] ?? 4.5,
          'vehicleModel': trip.vendorCab?['carName'] ?? trip.car ?? 'Vehicle',
          'vehicleColor': trip.vendorCab?['carColor'] ?? 'White',
          'licensePlate': trip.vendorCab?['vehicleNo'] ??
              trip.vendorCab?['rCNo'] ??
              'Not Available',
          'phoneNumber': trip.vendorDriver?['contactNo'] ??
              trip.vendorDriver?['altContactNo'] ??
              trip.phone ??
              'Not Available',
        },
        'tripInfo': {
          'estimatedTime': '30 mins',
          'distance':
          trip.distance != null ? '${trip.distance} km' : 'Calculating...',
          'fare': '₹${trip.amount.toStringAsFixed(2)}',
          'paymentMethod': 'Cash',
          'status': trip.status,
        },
        'currentStatus': _getTripStatus(trip.status),
        'vendorDriver': trip.vendorDriver ?? {},
        'vendorCab': trip.vendorCab ?? {},
        'carRentalUser': trip.carRentalUser ?? {},
        'pickupLocation': {
          'latitude': pickupCoords['latitude'],
          'longitude': pickupCoords['longitude']
        },
        'destinationLocation': {
          'latitude': destCoords['latitude'],
          'longitude': destCoords['longitude']
        },
        'driverLocation': {
          'latitude': driverLatitude,
          'longitude': driverLongitude
        },
        'userLocation': {
          'latitude': pickupCoords['latitude'],
          'longitude': pickupCoords['longitude']
        },
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingScreen(bookingData: bookingData),
        ),
      );
    } catch (e) {
      _showMessage('Error loading tracking screen: ${e.toString()}',
          isError: true);
    }
  }

  String _getTripStatus(int status) {
    switch (status) {
      case 0:
        return 'Driver Assigned';
      case 1:
        return 'On the way';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  void _handleModifyPress(Trip trip) {
    _showMessage('Modify functionality coming soon');
  }

  void _handleCancelPress(Trip trip) {
    _showMessage('Cancel functionality coming soon');
  }

  void _handleInvoicePress(Trip trip) {
    _showMessage('Invoice functionality coming soon');
  }

  void _handleRatePress(Trip trip) {
    _showMessage('Rate functionality coming soon');
  }

  void _handleRebookPress(Trip trip) {
    _showMessage('Rebook functionality coming soon');
  }

  void _handleDetailsPress(Trip trip) {
    _showMessage('Details functionality coming soon');
  }

  void _handleSupportPress(Trip trip) {
    _showMessage('Support functionality coming soon');
  }

  Widget _buildStatusContainer(String status, Color color) {
    if (status == 'Confirmed') {
      return Text(
        status,
        style: const TextStyle(
          color: successColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon,
      String text,
      Color color,
      VoidCallback onPressed,
      ) {
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

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filterTrips();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserHomeScreen(),
                ),
              );
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabButton('Upcoming', 0),
                  _buildTabButton('Completed', 1),
                  _buildTabButton('Cancelled', 2),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
                : filteredTrips.isEmpty
                ? _buildNoTrips()
                : RefreshIndicator(
              color: primaryColor,
              onRefresh: _getUserTripInfo,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTrips.length,
                itemBuilder: (ctx, index) {
                  final trip = filteredTrips[index];
                  return _buildTripCard(trip);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? primaryColor : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildNoTrips() {
    final tabNames = ['Upcoming', 'Completed', 'Cancelled'];
    final tabIcons = [
      MaterialCommunityIcons.calendar_clock,
      MaterialCommunityIcons.check_circle_outline,
      MaterialCommunityIcons.close_circle_outline,
    ];
    final tabColors = [warningColor, successColor, dangerColor];

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tabIcons[_activeTab],
              size: 70,
              color: tabColors[_activeTab].withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${tabNames[_activeTab]} Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _activeTab == 0
                  ? 'Book a trip to see it here'
                  : 'Your ${tabNames[_activeTab].toLowerCase()} trips will appear here',
              style: const TextStyle(fontSize: 14, color: lightTextColor),
            ),
            const SizedBox(height: 30),
            if (_activeTab == 0)
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: textColor,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book a Trip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      trip.car.isNotEmpty ? trip.car : 'Hatchback',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                _buildStatusContainer(
                  trip.status == 0
                      ? 'Confirmed'
                      : trip.status == 2
                      ? 'Completed'
                      : 'Cancelled',
                  _getStatusColor(trip.status),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.status == 0) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: lightAccentColor,
                        child: Text(
                          trip.name.isNotEmpty
                              ? trip.name.substring(0, 1).toUpperCase()
                              : 'D',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.name,
                              style: const TextStyle(
                                fontSize: 15,
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
                                Text(
                                  '${trip.vendorDriver?['rating'] ?? '4.5'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: lightTextColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(
                                  MaterialCommunityIcons.phone,
                                  size: 14,
                                  color: secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trip.phone,
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
                          if (trip.phone.isNotEmpty && trip.phone != 'N/A') {
                            makePhoneCall(trip.phone);
                          } else {
                            _showMessage('Phone number not available',
                                isError: true);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lightAccentColor,
                          ),
                          child: Icon(
                            MaterialCommunityIcons.phone,
                            size: 20,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                _buildLocationItem(
                  Icons.circle,
                  Colors.blue,
                  trip.fromLocation,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  height: 30,
                  width: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
                _buildLocationItem(
                  Icons.location_on,
                  Colors.red,
                  trip.toLocation,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTripDetailItem("Date", _formatDate(trip.startDate)),
                    const SizedBox(width: 8),
                    _buildTripDetailItem("Time", trip.time),
                    const SizedBox(width: 8),
                    _buildTripDetailItem("Booking ID", trip.bookingId),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.location_on,
                        'Track',
                        Colors.blue,
                            () => _handleTrackPress(trip),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (trip.status == 0) ...[
                      Expanded(
                        child: _buildActionButton(
                          MaterialCommunityIcons.phone,
                          'Call',
                          primaryColor,
                              () {
                            if (trip.phone.isNotEmpty && trip.phone != 'N/A') {
                              makePhoneCall(trip.phone);
                            } else {
                              _showMessage('Phone number not available',
                                  isError: true);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _buildActionButton(
                        trip.status == 0 ? Icons.close : Icons.refresh,
                        trip.status == 0 ? 'Cancel' : 'Rebook',
                        trip.status == 0 ? Colors.red.shade300 : Colors.green,
                            () => trip.status == 0
                            ? _handleCancelPress(trip)
                            : _handleRebookPress(trip),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(IconData icon, Color color, String location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontSize: 15,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: lightTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  IconData _getTripIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return MaterialCommunityIcons.bus;
      case 'flight':
        return MaterialCommunityIcons.airplane;
      case 'toyota innova':
      case 'innova':
        return MaterialCommunityIcons.car_estate;
      case 'sedan':
      case 'toyota etios':
      case 'honda city':
        return MaterialCommunityIcons.car_esp;
      case 'suv':
      case 'mahindra xuv':
        return MaterialCommunityIcons.car_2_plus;
      default:
        return MaterialCommunityIcons.car;
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return warningColor;
      case 2:
        return successColor;
      case 3:
        return dangerColor;
      default:
        return accentColor;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return dateStr;
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}