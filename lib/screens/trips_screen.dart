import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:worldtriplink/screens/tracking_screen.dart';

// Professional color palette
const Color primaryColor = Color(0xFF2E3192);
const Color accentColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFFFFCC00);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF666666);
const Color mutedTextColor = Color(0xFF999999);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);
const Color dangerColor = Color(0xFFF44336);

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
      fromLocation: json['fromLocation'] ?? json['userPickup'] ?? 'Unknown location',
      toLocation: json['toLocation'] ?? json['userDrop'] ?? 'Unknown location',
      startDate: json['startDate'] ?? json['date'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
      car: (json['car'] ?? json['vendorCab']?['carName'] ?? 'cab').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] is String ? int.tryParse(json['status']) ?? 0 : json['status'] as int? ?? 0,
      name: json['name'] ?? json['vendorDriver']?['driverName'] ?? 'Unknown',
      phone: json['phone'] ?? json['vendorDriver']?['contactNo'] ?? 'N/A',
      distance: (json['distance'] as num?)?.toDouble(),
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
    // Add sample trip data for testing
    _addSampleTrip();
  }

  void _addSampleTrip() {
    _trips.add(
      Trip(
        bookingId: 'WTL123456',
        fromLocation: 'Mumbai Airport, Terminal 2',
        toLocation: 'Taj Hotel, Colaba, Mumbai',
        startDate: '2023-11-15',
        time: '14:30',
        car: 'Toyota Innova',
        amount: 1500.0,
        status: 0, // Upcoming
        name: 'Rahul Sharma',
        phone: '+91 9876543210',
        distance: 25.5,
        vendorDriver: {
          'driverName': 'Rahul Sharma',
          'contactNo': '+91 9876543210',
          'altContactNo': '+91 9876543211',
          'rating': 4.8,
          'totalTrips': 256,
        },
        vendorCab: {
          'carName': 'Toyota Innova',
          'vehicleNo': 'MH 01 AB 1234',
          'carType': 'SUV',
          'carColor': 'White',
        },
        tripType: 'oneWay',
      ),
    );
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    
    setState(() {
      _userId = prefs.getInt('userId')?.toString() ?? prefs.getString('userId') ?? '';
      if (userDataString != null) {
        try {
          _userData = json.decode(userDataString);
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }
    });
    
    _getUserTripInfo();
  }

  Future<void> _getUserTripInfo() async {
    try {
      print('Fetching trips for user: $_userId');
      final response = await http.get(
        Uri.parse('https://api.worldtriplink.com/api/by-user/$_userId'),
      );
  
      print('API Response: ${response.statusCode}');
      print('Response Body: ${response.body}');
  
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> tripsData;
        
        if (responseData is List) {
          tripsData = responseData;
        } else if (responseData is Map && responseData.containsKey('data') && responseData['data'] is List) {
          tripsData = responseData['data'];
        } else {
          tripsData = [responseData];
        }
        
        print('Decoded JSON: ${tripsData.runtimeType}');
        
        final List<Trip> loadedTrips = tripsData.map((tripJson) {
          print('Processing trip: ${tripJson['bookingId'] ?? tripJson['bookid']}');
          return Trip.fromJson(tripJson);
        }).toList();
  
        print('Successfully loaded ${loadedTrips.length} trips');
        setState(() {
          _trips = loadedTrips;
          _isLoading = false;
        });
      } else {
        print('API Error: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('Error fetching trips: $error');
      setState(() => _isLoading = false);
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

  void _handleTrackPress(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingScreen(
          bookingData: {
            'bookingId': trip.bookingId,
            'pickup': trip.fromLocation,
            'destination': trip.toLocation,
            'tripType': trip.tripType,
            'driverInfo': {
              'name': trip.vendorDriver?['driverName'] ?? trip.name,
              'rating': 4.5, // Default rating
              'vehicleModel': trip.vendorCab?['carName'] ?? trip.car,
              'vehicleColor': 'White', // Default color
              'licensePlate': trip.vendorCab?['vehicleNo'] ?? trip.vendorCab?['rCNo'] ?? 'MH-XX-XXXX',
              'phoneNumber': trip.vendorDriver?['contactNo'] ?? trip.vendorDriver?['altContactNo'] ?? trip.phone,
            },
            'tripInfo': {
              'estimatedTime': '30 mins', // Estimated time
              'distance': trip.distance != null ? '${trip.distance} km' : '10 km',
              'fare': '₹${trip.amount}',
              'paymentMethod': 'Cash', // Default payment method
            },
            'currentStatus': 'On the way',
            'vendorDriver': trip.vendorDriver,
            'vendorCab': trip.vendorCab,
            'carRentalUser': trip.carRentalUser,
          },
        ),
      ),
    );
  }

  void _handleModifyPress(Trip trip) {
    // Implement modify functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modify functionality coming soon')),
    );
  }

  void _handleCancelPress(Trip trip) {
    // Implement cancel functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancel functionality coming soon')),
    );
  }

  void _handleInvoicePress(Trip trip) {
    // Implement invoice functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice functionality coming soon')),
    );
  }

  void _handleRatePress(Trip trip) {
    // Implement rate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate functionality coming soon')),
    );
  }

  void _handleRebookPress(Trip trip) {
    // Implement rebook functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rebook functionality coming soon')),
    );
  }

  void _handleDetailsPress(Trip trip) {
    // Implement details functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details functionality coming soon')),
    );
  }

  void _handleSupportPress(Trip trip) {
    // Implement support functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support functionality coming soon')),
    );
  }

  Widget _buildStatusContainer(String status, Color color) {
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

  Widget _buildActionButton(IconData icon, String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
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
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            color: isActive ? primaryColor : lightTextColor,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              color: tabColors[_activeTab],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _activeTab == 0
                ? 'Book a trip to see it here'
                : 'Your ${tabNames[_activeTab].toLowerCase()} trips will appear here',
            style: const TextStyle(
              fontSize: 14,
              color: lightTextColor,
            ),
          ),
          const SizedBox(height: 30),
          if (_activeTab == 0)
            ElevatedButton(
              onPressed: () {
                // Navigate to booking screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Book a Trip'),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          // Header with trip type and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTripIcon(trip.car),
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trip.car.isNotEmpty
                          ? trip.car
                          : 'Cab Booking',
                      style: const TextStyle(
                        fontSize: 16,
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
          
          // Trip details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking ID
                Row(
                  children: [
                    const Text(
                      'Booking ID: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: lightTextColor,
                      ),
                    ),
                    Text(
                      trip.bookingId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Route information with improved design
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildLocationRow(
                        Icons.location_on_outlined,
                        'From',
                        trip.fromLocation,
                        accentColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 9),
                        child: Container(
                          height: 30,
                          width: 1,
                          color: accentColor.withOpacity(0.3),
                        ),
                      ),
                      _buildLocationRow(
                        Icons.location_on,
                        'To',
                        trip.toLocation,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Trip details in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem(
                      MaterialCommunityIcons.calendar,
                      'Date',
                      trip.startDate,
                    ),
                    _buildDetailItem(
                      MaterialCommunityIcons.clock_outline,
                      'Time',
                      trip.time,
                    ),
                    _buildDetailItem(
                      MaterialCommunityIcons.currency_inr,
                      'Amount',
                      '₹${trip.amount.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 16),
                
                // Action buttons
                _buildActionButtons(trip),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String location, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(height: 8),
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
    );
  }

  // Widget _buildStatusContainer(String status, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: color, width: 1),
  //     ),
  //     child: Text(
  //       status,
  //       style: TextStyle(
  //         color: color,
  //         fontSize: 12,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionButtons(Trip trip) {
    if (trip.status == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.map_marker,
              'Track',
              primaryColor,
              () => _handleTrackPress(trip),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.pencil_outline,
              'Modify',
              accentColor,
              () => _handleModifyPress(trip),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.close,
              'Cancel',
              dangerColor,
              () => _handleCancelPress(trip),
            ),
          ),
        ],
      );
    } else if (trip.status == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.receipt,
              'Invoice',
              primaryColor,
              () => _handleInvoicePress(trip),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.star_outline,
              'Rate',
              accentColor,
              () => _handleRatePress(trip),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.refresh,
              'Rebook',
              successColor,
              () => _handleRebookPress(trip),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.information_outline,
              'Details',
              primaryColor,
              () => _handleDetailsPress(trip),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.refresh,
              'Rebook',
              successColor,
              () => _handleRebookPress(trip),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              MaterialCommunityIcons.help_circle_outline,
              'Support',
              accentColor,
              () => _handleSupportPress(trip),
            ),
          ),
        ],
      );
    }
  }

  // Widget _buildActionButton(IconData icon, String text, Color color, VoidCallback onPressed) {
  //   return ElevatedButton(
  //     onPressed: onPressed,
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: color.withOpacity(0.1),
  //       foregroundColor: color,
  //       elevation: 0,
  //       padding: const EdgeInsets.symmetric(vertical: 10),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         side: BorderSide(color: color.withOpacity(0.3)),
  //       ),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, size: 16),
  //         const SizedBox(height: 4),
  //         Text(
  //           text,
  //           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
        return warningColor; // Yellow for confirmed/upcoming
      case 2:
        return successColor; // Green for completed
      case 3:
        return dangerColor; // Red for cancelled
      default:
        return accentColor; // Blue for other statuses
    }
  }
}