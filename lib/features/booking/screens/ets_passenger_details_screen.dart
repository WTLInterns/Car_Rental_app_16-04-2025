import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/payment/screens/ets_payment_screen.dart';
import 'dart:convert';
import '../../../features/booking/screens/ets_select_vehicle_screen.dart';
import 'package:http/http.dart' as http;

class EtsPassengerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final List<String> dates;

  const EtsPassengerDetailsScreen({super.key, required this.bookingData, required this.dates});

  @override
  State<EtsPassengerDetailsScreen> createState() => _EtsPassengerDetailsScreenState();
}

class _EtsPassengerDetailsScreenState extends State<EtsPassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _userId = '';
  bool _isLoading = true;

  // Color scheme for consistent styling - matching the app's professional style
  final Color primaryColor = const Color(0xFF3F51B5);      // Royal blue from the image
  final Color secondaryColor = const Color(0xFF3057E3);    // Same blue for consistency
  final Color accentColor = const Color(0xFFFFCC00);       // Yellow/gold accent
  final Color backgroundColor = const Color(0xFFF3F5F9);   // Light gray background
  final Color cardColor = Colors.white;                    // White card background
  final Color surfaceColor = Colors.white;                 // White for inputs/surfaces
  final Color textColor = const Color(0xFF333333);         // Dark text
  final Color lightTextColor = const Color(0xFF666666);    // Medium gray text
  final Color mutedTextColor = const Color(0xFFAAAAAA);    // Light gray text
  final Color lightAccentColor = const Color(0xFFF0F7FF);  // Light blue background

  Map<String, String> _errors = {
    'firstName': '',
    'lastName': '',
    'email': '',
    'phone': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchAndFillUserProfile();
    _fetchInvoice();
  }

  Future<void> _fetchAndFillUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      String? userId;
      if (userData != null) {
        final parsedData = json.decode(userData);
        userId = parsedData['id']?.toString();
        if (userId != null) {
          _userId = userId;
          final response = await http.get(Uri.parse('https://api.worldtriplink.com/auth/getProfile/$userId'));
          if (response.statusCode == 200) {
            final profile = json.decode(response.body);
            setState(() {
              _firstNameController.text = profile['userName'] ?? '';
              _lastNameController.text = profile['lastName'] ?? '';
              _emailController.text = profile['email'] ?? '';
              _phoneController.text = profile['phone'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchInvoice() async {
    try {
      // Use dynamic base fare and cab type from booking data
      final baseFare = widget.bookingData['baseFare'] ?? '2416';
      final cabType = widget.bookingData['modelType']?.toUpperCase() ?? 'SUV';
      final response = await http.post(Uri.parse('https://ets.worldtriplink.com/schedule/invoice?baseFare=$baseFare&cabType=$cabType'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          widget.bookingData['totalAmount'] = data['totalAmount'].toString();
          widget.bookingData['totalFare'] = data['totalAmount'].toString();
          widget.bookingData['baseFare'] = data['baseFare'].toString();
          widget.bookingData['serviceCharge'] = data['serviceCharge'].toString();
          widget.bookingData['platformFee'] = data['serviceCharge'].toString();
          widget.bookingData['gst'] = data['gst'].toString();
          widget.bookingData['finalAmount'] = data['totalAmount'].toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch invoice details: ${response.statusCode}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching invoice: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  bool _validateForm() {
    bool isValid = true;
    final newErrors = <String, String>{
      'firstName': '',
      'lastName': '',
      'email': '',
      'phone': '',
    };

    if (_firstNameController.text.trim().isEmpty) {
      newErrors['firstName'] = 'First name is required';
      isValid = false;
    }

    if (_lastNameController.text.trim().isEmpty) {
      newErrors['lastName'] = 'Last name is required';
      isValid = false;
    }

    if (_emailController.text.trim().isEmpty) {
      newErrors['email'] = 'Email is required';
      isValid = false;
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_emailController.text)) {
      newErrors['email'] = 'Please enter a valid email';
      isValid = false;
    }

    if (_phoneController.text.trim().isEmpty) {
      newErrors['phone'] = 'Phone number is required';
      isValid = false;
    } else if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())) {
      newErrors['phone'] = 'Please enter a valid 10-digit phone number';
      isValid = false;
    }

    setState(() => _errors = newErrors);
    return isValid;
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

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Create updated booking data with passenger details
      final updatedBookingData = {
        ...widget.bookingData,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'userId': _userId,
        'dates': widget.dates,
      };

      // Navigate to ETSPaymentScreen with the updated booking data
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ETSPaymentScreen(bookingData: updatedBookingData, dates: widget.dates), // Pass dates here
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper to format currency values with two decimal points
  String _formatAmount(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return amount.toStringAsFixed(2);
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
          'ETS Passenger Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Replace the current route with EtsSelectVehicleScreen
            Navigator.pop(
              context,
              MaterialPageRoute(
                builder: (context) => EtsSelectVehicleScreen(bookingData: widget.bookingData, dates: widget.dates), // Pass dates back if needed
              ),
            );
          },
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTripSummary(),
                    const SizedBox(height: 24),
                    _buildPassengerForm(),
                    const SizedBox(height: 24),
                    _buildProceedButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildTripSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  color: primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trip Summary',
                  style: TextStyle(
                    fontSize: 18,
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
            const SizedBox(height: 16),
            _buildTripDetails(),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
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

  Widget _buildTripDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                Icons.calendar_today,
                'Date(s)', // Changed label to indicate multiple dates
                widget.dates.join(', '), // Display all selected dates
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                Icons.access_time,
                'Time',
                widget.bookingData['time'] ?? '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                Icons.directions_car,
                'Vehicle',
                widget.bookingData['vehicleType'] ?? '',
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                Icons.swap_horiz,
                'Trip Type',
                _getTripTypeLabel(),
              ),
            ),
          ],
        ),
        if (widget.bookingData['bookingType'] == 'roundTrip' &&
            widget.bookingData['returnDate'] != null) ...[
          const SizedBox(height: 16),
          _buildDetailItem(
            Icons.calendar_today,
            'Return Date',
            widget.bookingData['returnDate'],
          ),
        ],
        if (widget.bookingData['bookingType'] == 'rental' &&
            widget.bookingData['hours'] != null) ...[
          const SizedBox(height: 16),
          _buildDetailItem(Icons.timer, 'Hours', widget.bookingData['hours']),
        ],
      ],
    );
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
        const SizedBox(width: 8),
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
                style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTripTypeLabel() {
    switch (widget.bookingData['bookingType']) {
      case 'oneWay':
        return 'One Way';
      case 'roundTrip':
        return 'Round Trip';
      case 'rental':
        return 'Rental';
      default:
        return 'One Way';
    }
  }

  Widget _buildFareDetails() {
    final baseFare = _formatAmount(widget.bookingData['baseFare']);
    final serviceCharge = _formatAmount(widget.bookingData['serviceCharge'] ?? widget.bookingData['platformFee']);
    final gst = _formatAmount(widget.bookingData['gst']);
    final totalFare = _formatAmount(widget.bookingData['totalAmount'] ?? widget.bookingData['totalFare']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, color: primaryColor, size: 20),
            const SizedBox(width: 8),
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
        _buildFareRow('Service Charge', '₹$serviceCharge'),
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

  Widget _buildPassengerForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Passenger Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      error: _errors['firstName'] ?? '',
                      keyboardType: TextInputType.name,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      error: _errors['lastName'] ?? '',
                      keyboardType: TextInputType.name,
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                error: _errors['email'] ?? '',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                error: _errors['phone'] ?? '',
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String error,
    required TextInputType keyboardType,
    required IconData icon,
    bool required = true,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade700, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            errorText: error.isNotEmpty ? error : null,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleProceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Proceed to Payment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}