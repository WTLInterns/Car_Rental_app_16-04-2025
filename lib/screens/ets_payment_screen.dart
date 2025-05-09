import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'dart:async'; // For TimeoutException
import 'package:worldtriplink/screens/user_home_screen.dart';

const String API_BASE_URL = 'https://api.worldtriplink.com/api';

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
  
  // Add TextEditingController declarations
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      
      if (userData != null) {
        final parsedData = json.decode(userData);
        setState(() {
          _storedUserId = parsedData['id']?.toString() ?? '';
          
          // Load other user data
          if (parsedData['username'] != null) {
            _firstNameController.text = parsedData['username'];
          }
          if (parsedData['lastName'] != null) {
            _lastNameController.text = parsedData['lastName'];
          }
          if (parsedData['email'] != null) {
            _emailController.text = parsedData['email'];
          }
          if (parsedData['phone'] != null) {
            _phoneController.text = parsedData['phone'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePayment() async {
    if (_storedUserId == null || _storedUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID is required. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Log the data being sent
      final requestData = {
        'pickUpLocation': widget.bookingData['pickup'],
        'dropLocation': widget.bookingData['destination'],
        'time': widget.bookingData['time'],
        'returnTime': widget.bookingData['returnTime'],
        'cabType': widget.bookingData['vehicleType'],
        'finalAmount': widget.bookingData['finalAmount'].toString(),
        'baseAmount': widget.bookingData['baseAmount'].toString(),
        'serviceCharge': widget.bookingData['serviceCharge'].toString(),
        'gst': widget.bookingData['gst'].toString(),
        'distance': widget.bookingData['distance'].toString(),
        'sittingExcepatation': widget.bookingData['sittingExcepatation'].toString(),
        'dates': widget.bookingData['date'],
        'userId': _storedUserId,
        'shiftTime': widget.bookingData['shiftTime'],
        'parnterSharing': widget.bookingData['parnterSharing'].toString(),
      };

      debugPrint('Sending booking data: $requestData');

      final baseUrl = 'http://192.168.1.76:8081';
      final response = await http.post(
        Uri.parse('$baseUrl/schedule/etsBookingConfirm'),
        body: requestData,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Booking response: $data');
        
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Booking confirmed successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UserHomeScreen()),
            (route) => false,
          );
        } else {
          throw Exception(data['message'] ?? 'Booking failed');
        }
      } else {
        throw Exception('Failed to confirm booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          'ETS Payment',
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
        _buildFareRow('GST (18%)', '₹$gst'),
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
      elevation: 2,
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
          border: isSelected ? Border.all(color: accentColor, width: 1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? accentColor.withOpacity(0.2)
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

  void _handleProceedToPayment() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get invoice details
      final baseUrl = 'http://192.168.1.76:8081';
      final response = await http.post(
        Uri.parse('$baseUrl/schedule/invoice'),
        body: {
          'baseFare': widget.bookingData['baseFare'].toString(),
          'cabType': widget.bookingData['vehicleType'],
        },
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Convert all price values to integers
        final baseFare = int.parse(data['baseFare'].toString());
        final serviceCharge = int.parse(data['serviceCharge'].toString());
        final gst = int.parse(data['gst'].toString());
        final totalAmount = int.parse(data['totalAmount'].toString());
        
        // Prepare data for payment screen
        final paymentData = {
          ...widget.bookingData,
          'passengerName': '${_firstNameController.text} ${_lastNameController.text}',
          'passengerEmail': _emailController.text,
          'passengerPhone': _phoneController.text,
          'userId': _storedUserId,
          'baseFare': baseFare,
          'serviceCharge': serviceCharge,
          'gst': gst,
          'totalFare': totalAmount,
          'finalAmount': totalAmount,
          'baseAmount': baseFare,
        };

        // Navigate to payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(bookingData: paymentData),
          ),
        );
      } else {
        throw Exception('Failed to get invoice details');
      }
    } catch (e) {
      // Close loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _validateForm() {
    // Implement your validation logic here
    return true; // Placeholder, actual implementation needed
  }
}
