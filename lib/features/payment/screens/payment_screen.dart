import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'dart:async'; // For TimeoutException
import '../../../features/booking/screens/user_home_screen.dart';

const String apiBaseUrl = 'https://api.worldtriplink.com/api';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PaymentScreen({super.key, required this.bookingData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _selectedPaymentMethod = 'cash';
  String? _storedUserId;

  // Professional color palette
  final Color primaryColor = const Color(0xFF3057E3);      // Royal blue from the image
  final Color secondaryColor = const Color(0xFF3057E3);    // Same blue for consistency
  final Color accentColor = const Color(0xFFFFCC00);       // Yellow/gold accent
  final Color backgroundColor = const Color(0xFFF3F5F9);   // Light gray background
  final Color cardColor = Colors.white;                    // White card background
  final Color surfaceColor = Colors.white;                 // White for inputs/surfaces
  final Color textColor = const Color(0xFF333333);         // Dark text
  final Color lightTextColor = const Color(0xFF666666);    // Medium gray text
  final Color mutedTextColor = const Color(0xFFAAAAAA);    // Light gray text
  final Color lightAccentColor = const Color(0xFFF0F7FF);  // Light blue background
  final Color successColor = const Color(0xFF4CAF50);      // Green for success messages
  final Color errorColor = const Color(0xFFE53935);        // Red for error messages

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try both 'userId' (int) and 'userData' (json string)
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
      developer.log(
        'Loaded userId from SharedPreferences: $_storedUserId',
        name: 'PaymentScreen',
      );
    } catch (e) {
      debugPrint('Error retrieving user data: $e');
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    developer.log('Starting payment process', name: 'PaymentScreen');
    try {
      // Always fetch userId from SharedPreferences before making the call
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
      developer.log(
        'Effective User ID: $effectiveUserId',
        name: 'PaymentScreen',
      );
      // Only include parameters required by the API
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
        'total': widget.bookingData['totalFare']?.toString() ?? '0',
        'days': widget.bookingData['days']?.toString() ?? '1',
        'driverrate': widget.bookingData['driverRate']?.toString() ?? '0',
        'phone': widget.bookingData['passengerPhone'] ?? '',
        'userId': effectiveUserId,
      };
      final uri = Uri.parse(
        '$apiBaseUrl/bookingConfirm',
      ).replace(queryParameters: requestParams);
      developer.log('POST Request URL: $uri', name: 'PaymentScreen');
      final response = await http
          .post(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      developer.log(
        'Response Status: ${response.statusCode}',
        name: 'PaymentScreen',
      );
      developer.log('Response Body: ${response.body}', name: 'PaymentScreen');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          developer.log(
            'Booking confirmed successfully',
            name: 'PaymentScreen',
          );
          _showBookingConfirmation(data['bookingId'] ?? 'Unknown');
        } else {
          final errorMsg = data['message'] ?? 'Failed to create booking';
          developer.log('Booking failed: $errorMsg', name: 'PaymentScreen');
          _showErrorDialog(errorMsg);
        }
      } else {
        throw Exception(
          'Failed to process payment. Status: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      developer.log('Request timeout occurred', name: 'PaymentScreen');
      _showErrorDialog('Request timed out. Please check your connection.');
    } on http.ClientException catch (e) {
      developer.log('Network error: ${e.message}', name: 'PaymentScreen');
      _showErrorDialog('Network error occurred');
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'PaymentScreen');
      _showErrorDialog('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
      developer.log('Payment process completed', name: 'PaymentScreen');
    }
  }

  void _showBookingConfirmation(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: successColor, size: 28),
                const SizedBox(width: 12),
                const Text('Booking Confirmed'),
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
                                fontSize: 16,
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
                  Navigator.of(context).pop(); // Close the dialog
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
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
                          Icon(
                            Icons.lock_rounded,
                            color: successColor,
                            size: 18,
                          ),
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

                    // Main content - Using Expanded to prevent overflow
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Use responsive layout based on screen width
                            if (constraints.maxWidth > 600) {
                              // Tablet/Desktop layout - Side by side
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left column - Trip Summary
                                  Expanded(flex: 3, child: _buildTripSummary()),
                                  const SizedBox(width: 16),
                                  // Right column - Payment Methods
                                  Expanded(
                                    flex: 4,
                                    child: _buildPaymentMethods(),
                                  ),
                                ],
                              );
                            } else {
                              // Mobile layout - Stacked
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Trip Summary
                                    _buildTripSummary(),
                                    const SizedBox(height: 16),
                                    // Payment Methods
                                    SizedBox(
                                      height: 320, // Fixed height for payment methods
                                      child: _buildPaymentMethods(),
                                    ),
                                    // Add extra space at bottom to prevent footer overlap
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),

                    // Bottom payment button with total amount
                    _buildPaymentFooter(),
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
    final platformFee = widget.bookingData['platformFee'] ?? 0;
    final gst = widget.bookingData['gst'] ?? 0;
    final totalFare = widget.bookingData['totalFare'] ?? 0;

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
        const Divider(),
        _buildFareRow('Total Fare', '₹$totalFare', isTotal: true),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPaymentOption(
                      'UPI',
                      'Pay using Google Pay, PhonePe, etc.',
                      MaterialCommunityIcons.qrcode_scan,
                      'upi',
                    ),
                    const Divider(),
                    _buildPaymentOption(
                      'Cash on Arrival',
                      'Pay directly to the driver',
                      MaterialCommunityIcons.cash,
                      'cash',
                    ),
                  ],
                ),
              ),
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
          color:
              isSelected
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
                color:
                    isSelected
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

  Widget _buildPaymentFooter() {
    final totalFare = widget.bookingData['totalFare'] ?? 0;

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
                  Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 14, color: lightTextColor),
                  ),
                  Text(
                    '₹$totalFare',
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
}
