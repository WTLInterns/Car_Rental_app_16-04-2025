import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../features/booking/screens/ets_booking_screen.dart';
import '../../../features/tracking/screens/ets_user_tracking_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final bool isCorporateBooking;
  final List<Map<String, dynamic>>? shiftDates;
  final String? corporateName;

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
    this.isCorporateBooking = false,
    this.shiftDates,
    this.corporateName,
  });

  factory ETSTrip.fromJson(Map<String, dynamic> json) {
    // Convert status string to int
    int statusCode = 0;
    if (json['status'] != null) {
      if (json['status'] is int) {
        statusCode = json['status'];
      } else if (json['status'] is String) {
        switch(json['status'].toString().toUpperCase()) {
          case 'CONFIRMED':
            statusCode = 0;
            break;
          case 'ONGOING':
            statusCode = 1;
            break;
          case 'COMPLETED':
            statusCode = 2;
            break;
          case 'CANCELLED':
            statusCode = 3;
            break;
          default:
            statusCode = 0;
        }
      }
    }
    
    // Parse scheduled dates if available
    List<Map<String, dynamic>>? shiftDates;
    if (json['scheduledDates'] != null) {
      shiftDates = List<Map<String, dynamic>>.from(
        json['scheduledDates'].map((date) => {
          'date': date['date'] ?? '',
          'time': '',
          'shift': date['status'] ?? 'PENDING',
          'employees': 0,
          'destinations': []
        })
      );
    }
    
    return ETSTrip(
      bookingId: json['bookId'] ?? json['bookingId'] ?? 'N/A',
      fromLocation: json['pickUpLocation'] ?? json['fromLocation'] ?? json['userPickup'] ?? 'Unknown location',
      toLocation: json['dropLocation'] ?? json['toLocation'] ?? json['userDrop'] ?? 'Unknown location',
      startDate: json['scheduledDates'] != null && json['scheduledDates'].isNotEmpty 
          ? json['scheduledDates'][0]['date'] 
          : json['startDate'] ?? json['date'] ?? 'N/A',
      time: json['time'] ?? json['returnTime'] ?? 'N/A',
      car: (json['cabType'] ?? json['car'] ?? json['vehicleType'] ?? 'cab').toString(),
      amount: json['finalAmount'] is num
          ? (json['finalAmount'] as num).toDouble()
          : double.tryParse(json['finalAmount']?.toString() ?? '') ?? 
              (json['amount'] is num
                  ? (json['amount'] as num).toDouble()
                  : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0),
      status: statusCode,
      name: json['driverName'] ?? 'Assigned Driver',
      phone: json['driverContact'] ?? 'Contact Support',
      distance: json['distance'] is num
          ? (json['distance'] as num).toDouble()
          : double.tryParse(json['distance']?.toString() ?? '') ?? 0.0,
      tripType: json['tripType'] ?? 'oneWay',
      isCorporateBooking: json['isCorporateBooking'] ?? false,
      shiftDates: shiftDates,
      corporateName: json['corporateName'],
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
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For testing, comment out API call and use dummy data instead
      // Uncomment this section when you want to use the real API
      /*
      final response = await http.get(Uri.parse('http://192.168.1.42:8081/schedule/byUserId/$_userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _trips = data.map((tripJson) => ETSTrip.fromJson(tripJson)).toList();
          _isLoading = false;
        });
      } else {
        // Handle API error
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trips: ${response.statusCode}')),
        );
      }
      */
      
      // Using dummy data for testing purposes
      _loadDummyTrips();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  void _loadDummyTrips() {
    // Create sample trips with different statuses for testing
    _trips = [
      // Upcoming trips (status 0)
      ETSTrip(
        bookingId: 'ETS-1001',
        fromLocation: 'pune',
        toLocation: 'mumbai',
        startDate: '2025-06-05',
        time: '09:30 AM',
        car: 'Sedan',
        amount: 350.0,
        status: 0,
        name: 'Rahul Sharma',
        phone: '9876543210',
        distance: 18.5,
      ),
      ETSTrip(
        bookingId: 'ETS-1002',
        fromLocation: 'Baner Road',
        toLocation: 'Magarpatta City',
        startDate: '2025-06-07',
        time: '10:00 AM',
        car: 'SUV',
        amount: 450.0,
        status: 0,
        name: 'Priya Patel',
        phone: '9876123450',
        distance: 22.3,
      ),
      
      // Corporate bookings with multiple shifts (upcoming)
      ETSTrip(
        bookingId: 'ETS-C001',
        fromLocation: 'Infosys Campus, Hinjewadi',
        toLocation: 'Multiple Drop Locations',
        startDate: '2025-06-04',
        time: '06:00 PM',
        car: 'Tempo Traveller',
        amount: 12000.0,
        status: 0,
        name: 'Sanjay Kumar',
        phone: '8765432109',
        distance: 35.0,
        isCorporateBooking: true,
        corporateName: 'Infosys Technologies Ltd',
        tripType: 'corporate',
        shiftDates: [
          {
            'date': '2025-06-04',
            'time': '06:00 PM',
            'shift': 'EVENING',
            'employees': 12,
            'destinations': ['Wakad', 'Aundh', 'Shivaji Nagar']
          },
          {
            'date': '2025-06-05',
            'time': '06:00 PM',
            'shift': 'EVENING',
            'employees': 14,
            'destinations': ['Wakad', 'Aundh', 'Shivaji Nagar']
          },
          {
            'date': '2025-06-06',
            'time': '06:00 PM',
            'shift': 'EVENING',
            'employees': 10,
            'destinations': ['Wakad', 'Aundh', 'Shivaji Nagar']
          },
        ],
      ),
      
      // Completed trips (status 2)
      ETSTrip(
        bookingId: 'ETS-0986',
        fromLocation: 'Pune Airport',
        toLocation: 'Koregaon Park',
        startDate: '2025-05-28',
        time: '14:45 PM',
        car: 'Sedan',
        amount: 380.0,
        status: 2,
        name: 'Amit Desai',
        phone: '7654321098',
        distance: 12.7,
      ),
      ETSTrip(
        bookingId: 'ETS-0973',
        fromLocation: 'Pune Railway Station',
        toLocation: 'Symbiosis College, Model Colony',
        startDate: '2025-05-25',
        time: '11:30 AM',
        car: 'Hatchback',
        amount: 250.0,
        status: 2,
        name: 'Vikram Singh',
        phone: '9123456780',
        distance: 8.4,
      ),
      
      // Corporate booking (completed)
      ETSTrip(
        bookingId: 'ETS-C000',
        fromLocation: 'TCS Campus, Hinjewadi Phase 3',
        toLocation: 'Multiple Drop Locations',
        startDate: '2025-05-20',
        time: '07:00 AM',
        car: 'Tempo Traveller',
        amount: 9800.0,
        status: 2,
        name: 'Rajesh Verma',
        phone: '8123456789',
        distance: 42.0,
        isCorporateBooking: true,
        corporateName: 'Tata Consultancy Services',
        tripType: 'corporate',
        shiftDates: [
          {
            'date': '2025-05-20',
            'time': '07:00 AM',
            'shift': 'MORNING',
            'employees': 16,
            'destinations': ['Kothrud', 'Warje', 'Sinhagad Road']
          },
          {
            'date': '2025-05-21',
            'time': '07:00 AM',
            'shift': 'MORNING',
            'employees': 15,
            'destinations': ['Kothrud', 'Warje', 'Sinhagad Road']
          },
        ],
      ),
      
      // Cancelled trips (status 3)
      ETSTrip(
        bookingId: 'ETS-0954',
        fromLocation: 'FC Road',
        toLocation: 'Aga Khan Palace',
        startDate: '2025-05-18',
        time: '16:30 PM',
        car: 'Sedan',
        amount: 320.0,
        status: 3,
        name: 'Neha Sharma',
        phone: '9871234560',
        distance: 10.2,
      ),
      ETSTrip(
        bookingId: 'ETS-0942',
        fromLocation: 'Phoenix Mall',
        toLocation: 'Amanora Park Town',
        startDate: '2025-05-15',
        time: '19:00 PM',
        car: 'SUV',
        amount: 380.0,
        status: 3,
        name: 'Kunal Mehta',
        phone: '8901234567',
        distance: 7.8,
      ),
    ];
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId =
          prefs.getInt('userId')?.toString() ?? prefs.getString('userId') ?? '123';
    });
    
    // Fetch trips after user ID is loaded
    await _fetchTrips();
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
  
  // Method to refresh trips
  Future<void> _refreshTrips() async {
    await _fetchTrips();
  }

  void _handleDetailsPress(ETSTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ETSUserTrackingScreen(
        slotId: trip.bookingId, // bookingId is used as slotId
        pickupLocationText: trip.fromLocation,
        dropLocationText: trip.toLocation,
        userId: _userId,
        // Example coordinates - in a real app, these would come from the ETSTrip model if available
        // For now, using the hardcoded examples as before. If trip object has actual coordinates, use them.
        pickupCoordinates: LatLng(18.5090, 73.8310), 
        dropCoordinates: LatLng(18.9402, 72.8347),   
      )),
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
        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 40),
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
            child: RefreshIndicator(
              onRefresh: _refreshTrips,
              color: primaryColor,
              child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : filteredTrips.isEmpty
                  ? Stack(
                      children: [
                        _buildNoTrips(),
                        // This ListView is needed for RefreshIndicator to work with an empty list
                        ListView()
                      ],
                    )
                  : ListView.builder(
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
    
    // For corporate bookings with multiple dates
    if (trip.isCorporateBooking && trip.shiftDates != null) {
      return _buildCorporateTripCard(trip, statusText, statusColor);
    }
    
    // Regular trip card (existing code)
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header with booking ID and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (trip.status == 0) // Upcoming trip
                      _buildActionButton(
                        Icons.cancel_outlined,
                        'Cancel',
                        dangerColor,
                        () => _handleCancelPress(trip),
                      ),
                    if (trip.status == 0 && trip.status == 3) // Space between buttons
                      const SizedBox(width: 12),
                    _buildActionButton(
                      Icons.info_outline,
                      'Track',
                      primaryColor,
                      () => _handleDetailsPress(trip),
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

  Widget _buildCorporateTripCard(ETSTrip trip, String statusText, Color statusColor) {
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
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: secondaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CORPORATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Booking ID: ${trip.bookingId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (trip.corporateName != null) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            trip.corporateName!,
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
                        const Icon(Icons.business, size: 14, color: primaryColor),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        Icon(Icons.people, size: 14, color: Colors.blue[400]),
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
                          const Text(
                            'Multiple Drop Locations',
                            style: TextStyle(
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
                
                // Shift dates panel
                const Text(
                  'Scheduled Shifts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // List of shift dates
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: trip.shiftDates!.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
                    itemBuilder: (context, index) {
                      final shift = trip.shiftDates![index];
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  shift['shift'].toString().substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${shift['date']}   • ${shift['time']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    '${shift['shift']} Shift     • ${shift['employees']} Employees',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                    if (trip.status == 0)
                      const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        Icons.info_outline,
                        'Details',
                        primaryColor,
                        () => _handleDetailsPress(trip),
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