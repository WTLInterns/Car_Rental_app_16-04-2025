import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:worldtriplink/features/payment/models/discount_model.dart';
import 'package:worldtriplink/features/payment/models/first_booking_model.dart';
import 'package:worldtriplink/widgets/common/app_text_field.dart';
import 'dart:async';
import '../../../features/booking/screens/user_home_screen.dart';

const String apiBaseUrl = 'https://api.worldtriplink.com/api';

class PaymentScreen extends StatefulWidget {
 final Map<String, dynamic> bookingData;

 const PaymentScreen({super.key, required this.bookingData});

 @override
 State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
 List<FirstBooking> bookings = [];
 bool _isLoading = false;
 String _selectedPaymentMethod = 'cash';
 String? _storedUserId;

 final TextEditingController _couponController = TextEditingController();
 Discount? _discountData;
 int _discountAmount = 0;
 bool _isCouponApplied = false;

 // Colors
 final Color primaryColor = const Color(0xFF4A90E2);
 final Color secondaryColor = const Color(0xFF4A90E2);
 final Color accentColor = const Color(0xFF4A90E2);
 final Color backgroundColor = const Color(0xFFF3F5F9);
 final Color cardColor = Colors.white;
 final Color surfaceColor = Colors.white;
 final Color textColor = const Color(0xFF333333);
 final Color lightTextColor = const Color(0xFF666666);
 final Color mutedTextColor = const Color(0xFFAAAAAA);
 final Color lightAccentColor = const Color(0xFFF0F7FF);
 final Color successColor = const Color(0xFF4CAF50);
 final Color errorColor = const Color(0xFFE53935);

 @override
 void initState() {
  super.initState();
  _getUserData();
  _fetchDiscount();
 }

 @override
 void dispose() {
  _couponController.dispose();
  super.dispose();
 }

 void _applyCoupon() {
  final enteredCode = _couponController.text.trim().toUpperCase();

  if (_discountData != null) {
   final actualCode = _discountData!.couponCode?.toUpperCase() ?? '';

   if (enteredCode == actualCode) {
    setState(() {
     _isCouponApplied = true;
     _discountAmount = _discountData!.priceDiscount ?? 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(
      backgroundColor: Colors.green,
         content: Text('Coupon applied successfully!')),
    );
    return;
   }
  }

  setState(() {
   _isCouponApplied = false;
   _discountAmount = 0;
  });

  ScaffoldMessenger.of(context).showSnackBar(
   const SnackBar(content: Text('Invalid coupon code.')),
  );
 }

 Future<void> _fetchDiscount() async {
  try {
   final response = await http
       .get(Uri.parse('https://api.worldtriplink.com/discount/getAll'));

   if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    print(response.body);
    for (var item in data) {
     final discount = Discount.fromJson(item);
     final isEnabled = discount.isEnabled?.toLowerCase() == 'true';

     if (isEnabled) {
      setState(() {
       _discountData = discount;
       _discountAmount = discount.priceDiscount ?? 0;
      });
      break;
     }
    }
   } else {
    if (kDebugMode) {
     print('Failed to load discount data. Status: ${response.statusCode}');
    }
   }
  } catch (e) {
   if (kDebugMode) {
    print('Error fetching discount: $e');
   }
  }
 }

 // API Functions
 Future<List<FirstBooking>> fetchBookings(String userId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/by-user/$userId'));

  if (response.statusCode == 200) {
   try {
    final List<dynamic> data = jsonDecode(response.body);
    print('Raw booking data: $data');
    return data.map((item) => FirstBooking.fromJson(item)).toList();
   } catch (e) {
    print('Error while parsing booking data: $e');
    print('Response body: ${response.body}');
    rethrow;
   }
  } else {
   throw Exception(
       'Failed to fetch bookings. Status code: ${response.statusCode}');
  }
 }

 Future<void> loadBookings() async {
  if (_storedUserId == null) return;

  try {
   final fetchedBookings = await fetchBookings(_storedUserId!);
   setState(() {
    bookings = fetchedBookings;
   });
   if (kDebugMode) {
    print('Bookings loaded: ${bookings.length}');
   }
  } catch (e) {
   if (kDebugMode) {
    print('Error loading bookings: $e');
   }
  }
 }

 Future<void> _getUserData() async {
  try {
   final prefs = await SharedPreferences.getInstance();
   String? userId;

   if (prefs.containsKey('userId')) {
    userId = prefs.getInt('userId')?.toString();
   }

   if ((userId == null || userId.isEmpty) && prefs.containsKey('userData')) {
    final userData = prefs.getString('userData');
    if (userData != null) {
     final parsedData = json.decode(userData);
     if (parsedData['id'] != null) {
      userId = parsedData['id'].toString();
     }
    }
   }

   setState(() {
    _storedUserId = userId;
   });

   if (kDebugMode) {
    print('Loaded userId from SharedPreferences: $_storedUserId');
   }

   if (userId != null && userId.isNotEmpty) {
    await loadBookings();
   }
  } catch (e) {
   if (kDebugMode) {
    print('Error retrieving user data: $e');
   }
  }
 }

 Future<void> _handlePayment() async {
  setState(() => _isLoading = true);

  try {
   final prefs = await SharedPreferences.getInstance();
   String? effectiveUserId = _storedUserId;

   if (prefs.containsKey('userId')) {
    effectiveUserId = prefs.getInt('userId')?.toString();
   }

   if ((effectiveUserId == null || effectiveUserId.isEmpty) &&
       prefs.containsKey('userData')) {
    final userData = prefs.getString('userData');
    if (userData != null) {
     final parsedData = json.decode(userData);
     if (parsedData['id'] != null) {
      effectiveUserId = parsedData['id'].toString();
     }
    }
   }

   effectiveUserId =
       effectiveUserId ?? widget.bookingData['userId']?.toString() ?? '0';

   if (kDebugMode) {
    print('Effective User ID: $effectiveUserId');
   }

   // Calculate total fare with discount if applied
   int totalFare =
       int.tryParse(widget.bookingData['totalFare']?.toString() ?? '0') ?? 0;
   if (_isCouponApplied) {
    totalFare -= _discountAmount;
    if (totalFare < 0) totalFare = 0;
   }

   final Map<String, String> requestParams = {
    'tripType': widget.bookingData['bookingType'] ?? 'oneWay',
    'pickupLocation': widget.bookingData['pickup'] ?? '',
    'dropLocation': widget.bookingData['destination'] ?? '',
    'date': widget.bookingData['date'] ?? '',
    'time': widget.bookingData['time'] ?? '',
    'Returndate': widget.bookingData['returnDate'] ?? '',
    'cabId': widget.bookingData['cabId']?.toString() ?? '',
    'modelName': widget.bookingData['vehicleType'] ?? '',
    'modelType': widget.bookingData['modelType'] ?? '',
    'seats': widget.bookingData['seats']?.toString() ?? '',
    'fuelType': widget.bookingData['fuelType'] ?? '',
    'availability': widget.bookingData['availability'] ?? '',
    'price': widget.bookingData['baseFare']?.toString() ?? '0',
    'distance': widget.bookingData['distance']?.toString() ?? '0',
    'name': widget.bookingData['passengerName'] ?? '',
    'email': widget.bookingData['passengerEmail'] ?? '',
    'service': widget.bookingData['platformFee']?.toString() ?? '0',
    'gst': widget.bookingData['gst']?.toString() ?? '0',
    'total': totalFare.toString(),
    'days': widget.bookingData['days']?.toString() ?? '1',
    'driverrate': widget.bookingData['driverRate']?.toString() ?? '0',
    'phone': widget.bookingData['passengerPhone'] ?? '',
    'userId': effectiveUserId,
   };

   final uri = Uri.parse('$apiBaseUrl/bookingConfirm')
       .replace(queryParameters: requestParams);

   if (kDebugMode) {
    print('POST Request URL: $uri');
   }

   final response = await http.post(uri, headers: {
    'Accept': 'application/json'
   }).timeout(const Duration(seconds: 15));

   if (kDebugMode) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
   }

   if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
     _showBookingConfirmation(data['bookingId'] ?? 'Unknown');
    } else {
     final errorMsg = data['message'] ?? 'Failed to create booking';
     _showErrorDialog(errorMsg);
    }
   } else {
    throw Exception(
        'Failed to process payment. Status: ${response.statusCode}');
   }
  } on TimeoutException {
   _showErrorDialog('Request timed out. Please check your connection.');
  } on http.ClientException catch (e) {
   _showErrorDialog('Network error occurred: ${e.message}');
  } catch (e) {
   _showErrorDialog('An unexpected error occurred: $e');
  } finally {
   setState(() => _isLoading = false);
  }
 }

 void _showBookingConfirmation(String bookingId) {
  showDialog(
   context: context,
   barrierDismissible: false,
   builder: (context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Row(
     children: [
      Icon(Icons.check_circle, color: successColor, size: 28),
      const SizedBox(width: 12),
      const Text(
       'Booking Confirmed',
       style: TextStyle(fontSize: 20),
      ),
     ],
    ),
    content: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      const Text(
       'Your booking has been confirmed!',
       style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 16),
      Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
        color: lightAccentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
         color: accentColor.withOpacity(0.3),
         width: 1,
        ),
       ),
       child: Row(
        children: [
         Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
           color: accentColor.withOpacity(0.2),
           shape: BoxShape.circle,
          ),
          child: Icon(
           Icons.confirmation_number,
           color: primaryColor,
           size: 24,
          ),
         ),
         const SizedBox(width: 12),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             'Booking ID',
             style: TextStyle(
              fontSize: 14,
              color: lightTextColor,
             ),
            ),
            Text(
             bookingId,
             style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
             ),
            ),
           ],
          ),
         ),
        ],
       ),
      ),
     ],
    ),
    actions: [
     TextButton(
      onPressed: () {
       Navigator.of(context).pop();
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
         builder: (context) => const UserHomeScreen(),
        ),
            (route) => false,
       );
      },
      style: TextButton.styleFrom(
       foregroundColor: primaryColor,
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
       shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
       'BACK TO HOME',
       style: TextStyle(fontWeight: FontWeight.bold),
      ),
     ),
    ],
   ),
  );
 }

 void _showErrorDialog(String message) {
  showDialog(
   context: context,
   builder: (context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Row(
     children: [
      Icon(Icons.error_outline, color: errorColor, size: 28),
      const SizedBox(width: 12),
      const Text('Payment Failed'),
     ],
    ),
    content: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Text(message, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 16),
      Text(
       'Payment Method: ${_selectedPaymentMethod.toUpperCase()}',
       style: TextStyle(fontSize: 14, color: lightTextColor),
      ),
      Text(
       'Amount: ₹${widget.bookingData['totalFare'] ?? '0'}',
       style: TextStyle(fontSize: 14, color: lightTextColor),
      ),
     ],
    ),
    actions: [
     TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
       foregroundColor: primaryColor,
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
       shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
       'TRY AGAIN',
       style: TextStyle(fontWeight: FontWeight.bold),
      ),
     ),
    ],
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final totalFare =
      int.tryParse(widget.bookingData['totalFare']?.toString() ?? '0') ?? 0;
  final discountedTotal =
  _isCouponApplied ? totalFare - _discountAmount : totalFare;

  return Scaffold(
   backgroundColor: backgroundColor,
   appBar: AppBar(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    title: const Padding(
     padding: EdgeInsets.only(left: 70),
     child: Text(
      'Payment',
      style: TextStyle(fontWeight: FontWeight.bold),
     ),
    ),
    leading: IconButton(
     icon: const Icon(Icons.arrow_back),
     onPressed: () => Navigator.pop(context),
    ),
   ),
   body: _isLoading
       ? Center(
    child: Column(
     mainAxisSize: MainAxisSize.min,
     children: [
      CircularProgressIndicator(
       valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
      const SizedBox(height: 16),
      Text(
       'Processing your payment...',
       style: TextStyle(color: lightTextColor, fontSize: 16),
      ),
     ],
    ),
   )
       : SafeArea(
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      // Header with secure payment badge
      Padding(
       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
       child: Row(
        children: [
         Icon(Icons.lock_rounded, color: successColor, size: 18),
         const SizedBox(width: 8),
         Text(
          'Secure Payment',
          style: TextStyle(
           color: successColor,
           fontWeight: FontWeight.w500,
          ),
         ),
        ],
       ),
      ),

      // Main content
      Expanded(
       child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: LayoutBuilder(
         builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
           return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Expanded(flex: 3, child: _buildTripSummary()),
             const SizedBox(width: 16),
             Expanded(
                 flex: 4, child: _buildPaymentMethods()),
            ],
           );
          } else {
           return SingleChildScrollView(
            child: Column(
             children: [
              _buildTripSummary(),
              const SizedBox(height: 16),
              SizedBox(
               height: 180,
               child: _buildPaymentMethods(),
              ),
              const SizedBox(height: 20),
             ],
            ),
           );
          }
         },
        ),
       ),
      ),

      // Bottom payment button with total amount
      _buildPaymentFooter(discountedTotal, totalFare),
     ],
    ),
   ),
  );
 }

 Widget _buildTripSummary() {
  return Card(
   elevation: 2,
   shadowColor: Colors.black.withOpacity(0.1),
   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
   child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     mainAxisSize: MainAxisSize.min,
     children: [
      Row(
       children: [
        Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
          color: lightAccentColor,
          borderRadius: BorderRadius.circular(8),
         ),
         child: Icon(
          Icons.directions_car_rounded,
          color: primaryColor,
          size: 18,
         ),
        ),
        const SizedBox(width: 12),
        Text(
         'Trip Summary',
         style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
         ),
        ),
       ],
      ),
      const SizedBox(height: 16),
      _buildLocationInfo(),
      const SizedBox(height: 16),
      const Divider(thickness: 1),
      const SizedBox(height: 12),
      _buildCompactTripDetails(),
      const SizedBox(height: 16),
      const Divider(thickness: 1),
      const SizedBox(height: 12),
      _buildFareDetails(),
     ],
    ),
   ),
  );
 }

 Widget _buildLocationInfo() {
  return Column(
   children: [
    // Pickup location
    Row(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Container(
       padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
       ),
       child: Icon(
        Icons.location_on,
        color: primaryColor,
        size: 18,
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
          'PICKUP',
          style: TextStyle(
           fontSize: 11,
           fontWeight: FontWeight.bold,
           color: lightTextColor,
          ),
         ),
         const SizedBox(height: 4),
         Text(
          widget.bookingData['pickup'] ?? 'Pickup location',
          style: TextStyle(
           fontSize: 14,
           fontWeight: FontWeight.w500,
           color: textColor,
          ),
         ),
        ],
       ),
      ),
     ],
    ),

    // Connection line
    Padding(
     padding: const EdgeInsets.only(left: 14),
     child: Row(
      children: [
       Container(
        width: 2,
        height: 30,
        color: Colors.grey.shade300,
       ),
      ],
     ),
    ),

    // Drop location
    Row(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Container(
       padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
       ),
       child: Icon(
        Icons.flag,
        color: accentColor,
        size: 18,
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
          'DROP',
          style: TextStyle(
           fontSize: 11,
           fontWeight: FontWeight.bold,
           color: lightTextColor,
          ),
         ),
         const SizedBox(height: 4),
         Text(
          widget.bookingData['destination'] ?? 'Drop location',
          style: TextStyle(
           fontSize: 14,
           fontWeight: FontWeight.w500,
           color: textColor,
          ),
         ),
        ],
       ),
      ),
     ],
    ),
   ],
  );
 }

 Widget _buildCompactTripDetails() {
  return Column(
   children: [
    Row(
     children: [
      Expanded(
       child: _buildDetailItem(
        Icons.calendar_today,
        'Date',
        widget.bookingData['date'] ?? '',
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: _buildDetailItem(
        Icons.access_time,
        'Time',
        widget.bookingData['time'] ?? '',
       ),
      ),
     ],
    ),
    const SizedBox(height: 12),
    Row(
     children: [
      Expanded(
       child: _buildDetailItem(
        Icons.person,
        'Passenger',
        _getShortName(widget.bookingData['passengerName'] ?? ''),
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: _buildDetailItem(
        Icons.phone,
        'Contact',
        widget.bookingData['passengerPhone'] ?? '',
       ),
      ),
     ],
    ),
    const SizedBox(height: 12),
    _buildDetailItem(
     Icons.directions_car,
     'Vehicle',
     widget.bookingData['vehicleType'] ?? '',
    ),
    if (widget.bookingData['bookingType'] == 'roundTrip' &&
        widget.bookingData['returnDate'] != null) ...[
     const SizedBox(height: 12),
     _buildDetailItem(
      Icons.calendar_today,
      'Return Date',
      widget.bookingData['returnDate'] ?? '',
     ),
    ],
   ],
  );
 }

 String _getShortName(String fullName) {
  if (fullName.isEmpty) return '';
  final parts = fullName.split(' ');
  if (parts.length <= 2) return fullName;
  return '${parts[0]} ${parts[1]}';
 }

 Widget _buildDetailItem(IconData icon, String label, String value) {
  return Row(
   children: [
    Container(
     padding: const EdgeInsets.all(8),
     decoration: BoxDecoration(
      color: lightAccentColor,
      borderRadius: BorderRadius.circular(8),
     ),
     child: Icon(icon, color: primaryColor, size: 16),
    ),
    const SizedBox(width: 10),
    Expanded(
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Text(
        label,
        style: TextStyle(fontSize: 12, color: lightTextColor),
       ),
       Text(
        value,
        style: TextStyle(
         fontSize: 14,
         fontWeight: FontWeight.w500,
         color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
       ),
      ],
     ),
    ),
   ],
  );
 }

 Widget _buildFareDetails() {
  final baseFare =
      int.tryParse(widget.bookingData['baseFare']?.toString() ?? '0') ?? 0;
  final platformFee =
      int.tryParse(widget.bookingData['platformFee']?.toString() ?? '0') ?? 0;
  final gst = int.tryParse(widget.bookingData['gst']?.toString() ?? '0') ?? 0;
  final totalFare = baseFare + platformFee + gst;

  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Row(
     children: [
      Container(
       padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(
        color: lightAccentColor,
        borderRadius: BorderRadius.circular(8),
       ),
       child: Icon(Icons.receipt_long, color: primaryColor, size: 16),
      ),
      const SizedBox(width: 10),
      Text(
       'Fare Details',
       style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
       ),
      ),
     ],
    ),
    const SizedBox(height: 12),
    _buildFareRow('Base Fare', '₹$baseFare'),
    const SizedBox(height: 8),
    _buildFareRow('Platform Fee', '₹$platformFee'),
    const SizedBox(height: 8),
    _buildFareRow('GST (5%)', '₹$gst'),
    const SizedBox(height: 8),
    if (_isCouponApplied) _buildFareRow('Discount', '-₹$_discountAmount'),
    const Divider(),
    // Total Fare calculation
    _buildFareRow(
     'Total Fare',
     '₹${_isCouponApplied ? (totalFare - _discountAmount) : totalFare}',
     isTotal: true,
    ),
    const Divider(),
    const SizedBox(height: 8),
    _buildCouponCode(),
    const Divider(),
   ],
  );
 }

 Widget _buildFareRow(String label, String value, {bool isTotal = false}) {
  return Row(
   mainAxisAlignment: MainAxisAlignment.spaceBetween,
   children: [
    Text(
     label,
     style: TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
      color: isTotal ? textColor : lightTextColor,
     ),
    ),
    Text(
     value,
     style: TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
      color: isTotal ? primaryColor : textColor,
     ),
    ),
   ],
  );
 }

 Widget _buildPaymentMethods() {
  return Card(
   elevation: 4,
   shadowColor: Colors.black.withOpacity(0.1),
   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
   child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Row(
       children: [
        Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
          color: lightAccentColor,
          borderRadius: BorderRadius.circular(8),
         ),
         child: Icon(Icons.payment, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
         'Payment Method',
         style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
         ),
        ),
       ],
      ),
      const SizedBox(height: 16),
      Column(
       children: [
        _buildPaymentOption(
         'Cash on Arrival',
         'Pay directly to the driver',
         MaterialCommunityIcons.cash,
         'cash',
        ),
       ],
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildPaymentOption(
     String title,
     String subtitle,
     IconData icon,
     String value,
     ) {
  final isSelected = _selectedPaymentMethod == value;

  return InkWell(
   onTap: () => setState(() => _selectedPaymentMethod = value),
   borderRadius: BorderRadius.circular(12),
   child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
     color: isSelected
         ? lightAccentColor.withOpacity(0.5)
         : Colors.transparent,
     borderRadius: BorderRadius.circular(12),
     border: isSelected ? Border.all(color: successColor, width: 1) : null,
    ),
    child: Row(
     children: [
      Container(
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(
        color: isSelected
            ? successColor.withOpacity(0.2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
       ),
       child: Icon(
        icon,
        size: 24,
        color: isSelected ? primaryColor : Colors.grey.shade600,
       ),
      ),
      const SizedBox(width: 16),
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
          title,
          style: TextStyle(
           fontWeight: FontWeight.bold,
           fontSize: 15,
           color: isSelected ? primaryColor : textColor,
          ),
         ),
         const SizedBox(height: 4),
         Text(
          subtitle,
          style: TextStyle(color: lightTextColor, fontSize: 13),
         ),
        ],
       ),
      ),
      Radio<String>(
       value: value,
       groupValue: _selectedPaymentMethod,
       onChanged: (value) {
        if (value != null) {
         setState(() => _selectedPaymentMethod = value);
        }
       },
       activeColor: primaryColor,
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildPaymentFooter(int discountedTotal, int originalTotal) {
  return Container(
   padding: const EdgeInsets.all(16),
   decoration: BoxDecoration(
    color: cardColor,
    boxShadow: [
     BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, -4),
     ),
    ],
   ),
   child: SafeArea(
    top: false,
    child: Row(
     children: [
      // Price display
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
         const Text(
          'Total Amount',
          style: TextStyle(fontSize: 14, color: Colors.grey),
         ),
         if (_isCouponApplied) ...[
          Text(
           '₹$originalTotal',
           style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
           ),
          ),
          const SizedBox(height: 4),
          Text(
           '₹$discountedTotal',
           style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
           ),
          ),
         ] else
          Text(
           '₹$originalTotal',
           style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
           ),
          ),
        ],
       ),
      ),
      // Pay button
      Expanded(
       child: ElevatedButton(
        onPressed: _handlePayment,
        style: ElevatedButton.styleFrom(
         backgroundColor: primaryColor,
         foregroundColor: Colors.white,
         padding: const EdgeInsets.symmetric(vertical: 16),
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
         ),
         elevation: 0,
        ),
        child: Text(
         _selectedPaymentMethod == 'cash'
             ? 'Confirm Booking'
             : 'Pay Now',
         style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
         ),
        ),
       ),
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildCouponCode() {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.end,
   children: [
    AppTextField(
     controller: _couponController,
     label: 'Have a Coupon Code?',
     hint: 'Enter Coupon Code',
     validator: (value) {
      if (value == null || value.trim().isEmpty) {
       return 'Please enter a coupon code';
      }
      return null;
     },
    ),
    Row(
     children: [
      const Text(
       'Coupon Code',
       style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
      ),
      TextButton(
       onPressed: () => _buildDialog(context),
       child: const Text(
        'View details',
        style: TextStyle(decoration: TextDecoration.underline),
       ),
      ),
      const Spacer(),
      TextButton(
       onPressed: () {
        if (_couponController.text.trim().isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
           duration: Duration(seconds: 1),
           backgroundColor: Colors.redAccent,
           content: Center(
            child: Text(
             "Please enter a coupon code",
             style: TextStyle(fontWeight: FontWeight.w800),
            ),
           ),
          ),
         );
         return;
        }

        if (bookings.isEmpty) {
         _applyCoupon();
        } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
           duration: Duration(seconds: 1),
              backgroundColor: Colors.redAccent,
              content: Center(
                  child: Text(
                   "You Are Already Used This Coupon Code",
                   style: TextStyle(fontWeight: FontWeight.w800),
                  ))),
         );
        }
       },
       child: const Text(
        'Apply',
        style: TextStyle(
         color: Colors.lightBlue,
         fontWeight: FontWeight.w800,
        ),
       ),
      ),
     ],
    ),
    if (_isCouponApplied)
     Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
       '₹$_discountAmount discount applied!',
       style: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
       ),
      ),
     ),
   ],
  );
 }

 Future<void> _buildDialog(BuildContext context) {
  return showDialog<void>(
   context: context,
   builder: (BuildContext context) {
    return Dialog(
     shape:
     RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
     child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
        const Icon(Icons.celebration, size: 50, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
         "Congratulations!",
         style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
         ),
        ),
        const SizedBox(height: 8),
        Text(
         "You've unlocked ₹$_discountAmount OFF on your first booking!",
         textAlign: TextAlign.center,
         style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // Promo Code Box with gradient
        Container(
         padding:
         const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
         decoration: BoxDecoration(
          gradient: const LinearGradient(
           colors: [Colors.lightBlueAccent, Colors.blueAccent],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
           BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
           ),
          ],
         ),
         child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           Text(
            _discountData?.couponCode?.toUpperCase() ?? '',
            style: const TextStyle(
             fontSize: 18,
             letterSpacing: 2,
             fontWeight: FontWeight.bold,
             color: Colors.white,
            ),
           ),
           const SizedBox(width: 10),
           GestureDetector(
            onTap: () {
             final coupon =
                 _discountData?.couponCode?.toUpperCase() ?? '';
             Clipboard.setData(ClipboardData(text: coupon));
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                  content: Center(
                      child: Text("Coupon code copied!", style: TextStyle(fontSize:15,fontWeight: FontWeight.w800),))),
             );
             Navigator.pop(context);
            },
            child: const Icon(Icons.copy, color: Colors.white),
           )
          ],
         ),
        ),
       ],
      ),
     ),
    );
   },
  );
 }
}
