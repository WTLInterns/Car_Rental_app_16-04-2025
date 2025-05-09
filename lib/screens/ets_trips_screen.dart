import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:worldtriplink/screens/ets_booking_screen.dart';
import 'package:worldtriplink/screens/ets_tracking_screen.dart';

// Professional color palette - matching login screen
const Color primaryColor = Color(0xFF4A90E2);      // Blue (updated to match home screen)
const Color secondaryColor = Color(0xFF4A90E2);    // Blue
const Color accentColor = Color(0xFFFFCC00);       // Yellow/gold accent

// Background colors
const Color backgroundColor = Colors.white;   // White background (updated)
const Color cardColor = Colors.white;              // White card background
const Color surfaceColor = Color(0xFFF0F7FF);      // Light blue surface color

// Text colors
const Color textColor = Color(0xFF333333);         // Dark text
const Color lightTextColor = Color(0xFF666666);    // Medium gray text
const Color mutedTextColor = Color(0xFFA0A0A0);    // Light gray text

// Status colors
const Color successColor = Color(0xFF4CAF50);      // Green for success states
const Color warningColor = Color(0xFFFF9800);      // Orange for warning states
const Color dangerColor = Color(0xFFF44336);       // Red for error/danger states

// Accent shade
const Color lightAccentColor = Color(0xFFF0F7FF);  // Light blue for subtle highlights

class ETSTrip {
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
  final String tripType;

  ETSTrip({
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
    this.tripType = 'oneWay',
  });

  factory ETSTrip.fromJson(Map<String, dynamic> json) {
    return ETSTrip(
      bookingId: json['bookingId'] ?? json['bookid'] ?? 'N/A',
      fromLocation:
          json['fromLocation'] ?? json['userPickup'] ?? 'Unknown location',
      toLocation: json['toLocation'] ?? json['userDrop'] ?? 'Unknown location',
      startDate: json['startDate'] ?? json['date'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
      car: (json['car'] ?? json['vehicleType'] ?? 'cab').toString(),
      amount:
          json['amount'] is num
              ? (json['amount'] as num).toDouble()
              : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      status:
          json['status'] is String
              ? int.tryParse(json['status']) ?? 0
              : json['status'] as int? ?? 0,
      name: json['driverName'] ?? 'Unknown',
      phone: json['driverContact'] ?? 'N/A',
      distance:
          json['distance'] is num
              ? (json['distance'] as num).toDouble()
              : double.tryParse(json['distance']?.toString() ?? '') ?? 0.0,
      tripType: json['tripType'] ?? 'oneWay',
    );
  }
}

class ETSTripsScreen extends StatefulWidget {
  const ETSTripsScreen({super.key});

  @override
  State<ETSTripsScreen> createState() => _ETSTripsScreenState();
}

class _ETSTripsScreenState extends State<ETSTripsScreen> {
  int _activeTab = 0;
  String _userId = '';
  List<ETSTrip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Add sample trip data for testing
    _addSampleTrips();
  }

  void _addSampleTrips() {
    _trips = [
      ETSTrip(
        bookingId: 'ETS123456',
        fromLocation: 'Office HQ, Mumbai',
        toLocation: 'Airport Terminal 2, Mumbai',
        startDate: '2024-04-20',
        time: '08:30',
        car: 'Toyota Innova',
        amount: 1200.0,
        status: 0, // Upcoming
        name: 'Rahul Sharma',
        phone: '+91 9876543210',
        distance: 22.5,
        tripType: 'oneWay',
      ),
      ETSTrip(
        bookingId: 'ETS123457',
        fromLocation: 'Office HQ, Mumbai',
        toLocation: 'Taj Hotel, Colaba, Mumbai',
        startDate: '2024-04-15',
        time: '14:30',
        car: 'Toyota Etios',
        amount: 800.0,
        status: 2, // Completed
        name: 'Suresh Kumar',
        phone: '+91 9876543211',
        distance: 18.5,
        tripType: 'oneWay',
      ),
      ETSTrip(
        bookingId: 'ETS123458',
        fromLocation: 'Office HQ, Mumbai',
        toLocation: 'Bandra Kurla Complex, Mumbai',
        startDate: '2024-04-10',
        time: '09:15',
        car: 'Toyota Innova',
        amount: 950.0,
        status: 3, // Cancelled
        name: 'Amit Patel',
        phone: '+91 9876543212',
        distance: 12.0,
        tripType: 'oneWay',
      ),
    ];
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId =
          prefs.getInt('userId')?.toString() ?? prefs.getString('userId') ?? '';
    });
  }

  List<ETSTrip> _filterTrips() {
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

  String _getTripStatus(int status) {
    switch (status) {
      case 0:
        return 'Confirmed';
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

  void _handleDetailsPress(ETSTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ETSTrackingScreen()),
    );
  }

  void _handleCancelPress(ETSTrip trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancel functionality coming soon')),
    );
  }

  void _handleRebookPress(ETSTrip trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rebook functionality coming soon')),
    );
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
          'My ETS Trips',
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
              Navigator.pop(context);
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
              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab navigation
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
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTrips.length,
                    itemBuilder: (ctx, index) {
                      final trip = filteredTrips[index];
                      return _buildTripCard(trip);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Since we're on the Trips tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Trips',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Navigate back to ETS Booking Screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EtsBookingScreen()),
            );
          }
        },
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
    final tabText = _activeTab == 0 
        ? 'upcoming' 
        : _activeTab == 1 
            ? 'completed' 
            : 'cancelled';
            
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.car_rental,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No $tabText trips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your $tabText trips will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(ETSTrip trip) {
    final statusText = _getTripStatus(trip.status);
    final statusColor = trip.status == 0 
        ? warningColor 
        : trip.status == 2 
            ? successColor 
            : dangerColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header with booking ID and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking ID: ${trip.bookingId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                _buildStatusContainer(statusText, statusColor),
              ],
            ),
          ),
          // Trip details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 12, color: primaryColor),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        Icon(Icons.location_on, size: 14, color: Colors.red[400]),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.fromLocation,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            trip.toLocation,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Trip info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.calendar_today,
                        'Date',
                        trip.startDate,
                      ),
                      _buildInfoItem(
                        Icons.access_time,
                        'Time',
                        trip.time,
                      ),
                      _buildInfoItem(
                        Icons.directions_car,
                        'Vehicle',
                        trip.car,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    if (trip.status == 0) // Upcoming trip
                      Expanded(
                        child: _buildActionButton(
                          Icons.cancel_outlined,
                          'Cancel',
                          dangerColor,
                          () => _handleCancelPress(trip),
                        ),
                      ),
                    if (trip.status == 0 && trip.status == 3) // Space between buttons
                      const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        Icons.info_outline,
                        'Track',
                        primaryColor,
                        () => _handleDetailsPress(trip),
                      ),
                    ),
                    if (trip.status == 2 || trip.status == 3) // Completed or cancelled trip
                      const SizedBox(width: 12),
                    if (trip.status == 2 || trip.status == 3) // Completed or cancelled trip
                      Expanded(
                        child: _buildActionButton(
                          Icons.refresh,
                          'Rebook',
                          successColor,
                          () => _handleRebookPress(trip),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
    );
  }
}