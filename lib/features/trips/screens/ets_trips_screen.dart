import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../features/booking/screens/ets_booking_screen.dart';
import '../../../features/tracking/screens/ets_user_tracking_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Professional color palette - matching login screen
const Color primaryColor = Color(0xFF3F51B5); // Blue
const Color secondaryColor = Color(0xFF4A90E2); // Blue
const Color accentColor = Color(0xFFFFCC00); // Yellow/gold accent

// Background colors
const Color backgroundColor = Colors.white; // White background
const Color cardColor = Colors.white; // White card background
const Color surfaceColor = Color(0xFFF0F7FF); // Light blue surface color

// Text colors
const Color textColor = Color(0xFF333333); // Dark text
const Color lightTextColor = Color(0xFF666666); // Medium gray text
const Color mutedTextColor = Color(0xFFA0A0A0); // Light gray text

// Status colors
const Color successColor = Color(0xFF4CAF50); // Green for success states
const Color warningColor = Color(0xFFFF9800); // Orange for warning states
const Color dangerColor = Color(0xFFF44336); // Red for error/danger states

// Accent shade
const Color lightAccentColor =
    Color(0xFFF0F7FF); // Light blue for subtle highlights

class CarRentalBooking {
  final int id;
  final String pickUpLocation;
  final String bookId;
  final String dropLocation;
  final String time;
  final String returnTime;
  final String cabType;
  final int? vendorId;
  final int vendorDriverId;
  final int? vendor;
  final String baseAmount;
  final String finalAmount;
  final String? serviceCharge;
  final String gst;
  final String distance;
  final int sittingExpectation;
  final int partnerSharing;
  final int? shiftTime;
  final List<String> dateOfList;
  final String bookingType;
  final int? status;
  final int? slotId;
  final dynamic carRentaluser;
  final int carRentalUserId;
  final List<ScheduledDate> scheduledDates;
  final dynamic user;
  final Map<String, dynamic>? vendorDriver; // Added to store driver info

  CarRentalBooking({
    required this.id,
    required this.pickUpLocation,
    required this.bookId,
    required this.dropLocation,
    required this.time,
    required this.returnTime,
    required this.cabType,
    this.vendorId,
    required this.vendorDriverId,
    this.vendor,
    required this.baseAmount,
    required this.finalAmount,
    this.serviceCharge,
    required this.gst,
    required this.distance,
    required this.sittingExpectation,
    required this.partnerSharing,
    this.shiftTime,
    required this.dateOfList,
    required this.bookingType,
    this.status,
    this.slotId,
    this.carRentaluser,
    required this.carRentalUserId,
    required this.scheduledDates,
    this.user,
    this.vendorDriver,
  });

  factory CarRentalBooking.fromJson(Map<String, dynamic> json) {
    return CarRentalBooking(
      id: json['id'] ?? 0,
      pickUpLocation: json['pickUpLocation'] ?? '',
      bookId: json['bookId'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      time: json['time'] ?? '',
      returnTime: json['returnTime'] ?? '',
      cabType: json['cabType'] ?? '',
      vendorId: json['vendorId'],
      vendorDriverId: json['vendorDriverId'] ?? 0,
      vendor: json['vendor'],
      baseAmount: json['baseAmount']?.toString() ?? '0',
      finalAmount: json['finalAmount']?.toString() ?? '0',
      serviceCharge: json['serviceCharge']?.toString(),
      gst: json['gst']?.toString() ?? '0',
      distance: json['distance']?.toString() ?? '0',
      sittingExpectation: json['sittingExcepatation'] ?? 0,
      partnerSharing: json['partnerSharing'] ?? 0,
      shiftTime: json['shiftTime'],
      dateOfList: List<String>.from(json['dateOfList'] ?? []),
      bookingType: json['bookingType'] ?? 'regular',
      status: json['status'],
      slotId: json['slotId'],
      carRentaluser: json['carRentaluser'],
      carRentalUserId: json['carRentalUserId'] ?? 0,
      scheduledDates: (json['scheduledDates'] as List<dynamic>?)
              ?.map((e) => ScheduledDate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      user: json['user'],
      vendorDriver: json['vendorDriver'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickUpLocation': pickUpLocation,
      'bookId': bookId,
      'dropLocation': dropLocation,
      'time': time,
      'returnTime': returnTime,
      'cabType': cabType,
      'vendorId': vendorId,
      'vendorDriverId': vendorDriverId,
      'vendor': vendor,
      'baseAmount': baseAmount,
      'finalAmount': finalAmount,
      'serviceCharge': serviceCharge,
      'gst': gst,
      'distance': distance,
      'sittingExpectation': sittingExpectation,
      'partnerSharing': partnerSharing,
      'shiftTime': shiftTime,
      'dateOfList': dateOfList,
      'bookingType': bookingType,
      'status': status,
      'slotId': slotId,
      'carRentaluser': carRentaluser,
      'carRentalUserId': carRentalUserId,
      'scheduledDates': scheduledDates.map((e) => e.toJson()).toList(),
      'user': user,
      'vendorDriver': vendorDriver,
    };
  }
}

class ScheduledDate {
  final int id;
  final String date;
  final String status;
  final int? slotId;

  ScheduledDate({
    required this.id,
    required this.date,
    required this.status,
    this.slotId,
  });

  factory ScheduledDate.fromJson(Map<String, dynamic> json) {
    return ScheduledDate(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      slotId: json['slotId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'slotId': slotId,
    };
  }
}

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
  final LatLng? pickupCoordinates;
  final LatLng? dropCoordinates;
  final int? slotId;
  final Map<String, dynamic>? vendorDriver;

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
    this.pickupCoordinates,
    this.dropCoordinates,
    this.slotId,
    this.vendorDriver,
  });

  factory ETSTrip.fromJson(Map<String, dynamic> json) {
    int statusCode = 0;
    if (json['status'] != null) {
      if (json['status'] is int) {
        statusCode = json['status'];
      } else if (json['status'] is String) {
        switch (json['status'].toString().toUpperCase()) {
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

    List<Map<String, dynamic>>? shiftDates;
    if (json['scheduledDates'] != null) {
      shiftDates =
          List<Map<String, dynamic>>.from(json['scheduledDates'].map((date) => {
                'date': date['date'] ?? '',
                'time': '',
                'shift': date['status'] ?? 'PENDING',
                'employees': 0,
                'destinations': [],
                'slotId': date['slotId'],
              }));
    }

    LatLng? pickupCoordinates;
    LatLng? dropCoordinates;
    if (json['pickupCoordinates'] != null &&
        json['pickupCoordinates']['latitude'] != null &&
        json['pickupCoordinates']['longitude'] != null) {
      pickupCoordinates = LatLng(
        json['pickupCoordinates']['latitude'].toDouble(),
        json['pickupCoordinates']['longitude'].toDouble(),
      );
    }
    if (json['dropCoordinates'] != null &&
        json['dropCoordinates']['latitude'] != null &&
        json['dropCoordinates']['longitude'] != null) {
      dropCoordinates = LatLng(
        json['dropCoordinates']['latitude'].toDouble(),
        json['dropCoordinates']['longitude'].toDouble(),
      );
    }

    return ETSTrip(
      bookingId: json['bookId'] ?? json['bookingId'] ?? 'N/A',
      fromLocation: json['pickUpLocation'] ??
          json['fromLocation'] ??
          json['userPickup'] ??
          'Unknown location',
      toLocation: json['dropLocation'] ??
          json['toLocation'] ??
          json['userDrop'] ??
          'Unknown location',
      startDate:
          json['scheduledDates'] != null && json['scheduledDates'].isNotEmpty
              ? json['scheduledDates'][0]['date']
              : json['startDate'] ?? json['date'] ?? 'N/A',
      time: json['time'] ?? json['returnTime'] ?? 'N/A',
      car: (json['cabType'] ?? json['car'] ?? json['vehicleType'] ?? 'cab')
          .toString(),
      amount: json['finalAmount'] is num
          ? (json['finalAmount'] as num).toDouble()
          : double.tryParse(json['finalAmount']?.toString() ?? '') ??
              (json['amount'] is num
                  ? (json['amount'] as num).toDouble()
                  : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0),
      status: statusCode,
      name: json['vendorDriver']?['driverName'] ?? 'Wait',
      phone: json['vendorDriver']?['contactNo'] ?? 'And Refresh',
      distance: json['distance'] is num
          ? (json['distance'] as num).toDouble()
          : double.tryParse(json['distance']?.toString() ?? '') ?? 0.0,
      tripType: json['tripType'] ?? 'oneWay',
      isCorporateBooking: json['isCorporateBooking'] ?? false,
      shiftDates: shiftDates,
      corporateName: json['corporateName'],
      pickupCoordinates: pickupCoordinates,
      dropCoordinates: dropCoordinates,
      slotId: json['slotId'],
      vendorDriver: json['vendorDriver'],
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

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      const String apiKey = 'AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w';
      final String encodedAddress = Uri.encodeComponent(address);
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(
            location['lat'].toDouble(),
            location['lng'].toDouble(),
          );
        } else {
          print('Geocoding failed: ${data['status']}');
          return null;
        }
      } else {
        print('Geocoding API error: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://ets.worldtriplink.com/schedule/byUserId/$_userId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('API Response: ${response.body}');
        print(_userId);
        setState(() {
          _trips = data.map((tripJson) => ETSTrip.fromJson(tripJson)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load trips: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId')?.toString() ??
          prefs.getString('userId') ??
          '123';
    });
    await _fetchTrips();
  }

  List<ETSTrip> _filterTrips() {
// Filter trips based on the active tab
    List<ETSTrip> filtered = _trips.where((trip) {
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

// Sort filtered trips by startDate in descending order (latest first)
    filtered.sort((a, b) {
// Handle null or empty dates
      if (a.startDate.isEmpty && b.startDate.isEmpty) return 0;
      if (a.startDate.isEmpty) return 1; // Move empty dates to the end
      if (b.startDate.isEmpty) return -1;

      try {
        final DateTime dateA = DateFormat('yyyy-MM-dd').parse(a.startDate);
        final DateTime dateB = DateFormat('yyyy-MM-dd').parse(b.startDate);
        return dateB.compareTo(dateA); // Descending order
      } catch (e) {
        print('Error parsing date: $e');
        return 0; // If parsing fails, maintain original order
      }
    });

    return filtered;
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

  Future<void> _refreshTrips() async {
    await _fetchTrips();
  }

  void _handleDetailsPress(ETSTrip trip) async {
    LatLng pickupCoords =
        trip.pickupCoordinates ?? const LatLng(18.5090, 73.8310);
    LatLng dropCoords = trip.dropCoordinates ?? const LatLng(18.9402, 72.8347);

    if (trip.pickupCoordinates == null) {
      final geocodedPickup = await _geocodeAddress(trip.fromLocation);
      if (geocodedPickup != null) {
        pickupCoords = geocodedPickup;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Using fallback pickup coordinates')),
        );
      }
    }
    if (trip.dropCoordinates == null) {
      final geocodedDrop = await _geocodeAddress(trip.toLocation);
      if (geocodedDrop != null) {
        dropCoords = geocodedDrop;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Using fallback drop coordinates')),
        );
      }
    }

    print('vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
    print(trip.slotId);
    print('vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ETSUserTrackingScreen(
          slotId: trip.slotId,
          pickupLocationText: trip.fromLocation,
          dropLocationText: trip.toLocation,
          userId: _userId,
          pickupCoordinates: pickupCoords,
          dropCoordinates: dropCoords,
        ),
      ),
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
      IconData icon, String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
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

  Widget _buildInfoItem(IconData icon, String label, dynamic value) {
    if (value is String) {
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
    } else if (value is List<Map<String, dynamic>>?) {
      bool _isDropdownVisible = false;
      String? _selectedDate;

      return StatefulBuilder(
        builder: (context, setState) {
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDropdownVisible = !_isDropdownVisible;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMMM d, yyyy')
                                .format(DateTime.parse(_selectedDate!))
                            : 'Dates',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isDropdownVisible
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: textColor,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDropdownVisible)
                Container(
                  width: 150,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: value != null && value.isNotEmpty
                        ? value.map<Widget>((dateObj) {
                            final date = dateObj['date'] as String;
                            return ListTile(
                              title: Text(
                                DateFormat('MMMM d, yyyy')
                                    .format(DateTime.parse(date)),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  _isDropdownVisible = false;
                                });
                              },
                            );
                          }).toList()
                        : [
                            const ListTile(
                              title: Text(
                                'No dates available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
            ],
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
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
                            ListView(),
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
        currentIndex: 1,
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

    if (trip.isCorporateBooking && trip.shiftDates != null) {
      return _buildCorporateTripCard(trip, statusText, statusColor);
    }

    final driverName = trip.vendorDriver?['driverName'] ?? 'Wait';
    final contactNo = trip.vendorDriver?['contactNo'] ?? 'And Refresh';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.only(
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                _buildStatusContainer(statusText, statusColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        Icon(Icons.location_on,
                            size: 14, color: Colors.red[400]),
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
                          const Divider(),
                          Text(
                            'DriverName: $driverName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ContactNo: $contactNo',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon:
                                    const Icon(Icons.call, color: Colors.green),
                                onPressed: () async {
                                  final Uri callUri =
                                      Uri(scheme: 'tel', path: contactNo);
                                  if (await canLaunchUrl(callUri)) {
                                    await launchUrl(callUri);
                                  } else {
                                    throw 'Could not launch $callUri';
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
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
                        trip.shiftDates,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (trip.status == 0)
                      _buildActionButton(
                        Icons.cancel_outlined,
                        'Cancel',
                        dangerColor,
                        () => _handleCancelPress(trip),
                      ),
                    if (trip.status == 0 || trip.status == 3)
                      const SizedBox(width: 12),
                    _buildActionButton(
                      Icons.info_outline,
                      'Track',
                      primaryColor,
                      () => _handleDetailsPress(trip),
                    ),
                    if (trip.status == 2 || trip.status == 3)
                      const SizedBox(width: 12),
                    if (trip.status == 2 || trip.status == 3)
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

  Widget _buildCorporateTripCard(
      ETSTrip trip, String statusText, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.business,
                            size: 14, color: primaryColor),
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
                const Text(
                  'Scheduled Shifts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: trip.shiftDates?.length ?? 0,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey[300]),
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
                Row(
                  children: [
                    if (trip.status == 0)
                      Expanded(
                        child: _buildActionButton(
                          Icons.cancel_outlined,
                          'Cancel',
                          dangerColor,
                          () => _handleCancelPress(trip),
                        ),
                      ),
                    if (trip.status == 0) const SizedBox(width: 12),
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
}
