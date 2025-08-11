import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:async';
import '../../../features/booking/screens/user_home_screen.dart';
import 'package:worldtriplink/features/payment/models/discount_model.dart';
import 'package:worldtriplink/features/payment/models/first_booking_model.dart';
import 'package:worldtriplink/widgets/common/app_text_field.dart';

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
  String? _selectedPaymentType;
  String? _storedUserId;
  late Razorpay _razorpay;

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
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _getUserData();
    _fetchDiscount();
    _selectedPaymentType = 'full'; // Default to full payment
    if (kDebugMode) {
      print('Environment variables: RAZORPAY_KEY=${dotenv.env['RAZORPAY_KEY']}, API_BASE_URL=${dotenv.env['API_BASE_URL']}');
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _applyCoupon() {
    final enteredCode = _couponController.text.trim().toUpperCase();

    if (_discountData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Text('No discount available at the moment.'),
        ),
      );
      return;
    }

    if (enteredCode == _discountData!.couponCode?.toUpperCase()) {
      setState(() {
        _isCouponApplied = true;
        _discountAmount = _discountData!.priceDiscount ?? 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          content: Text('Coupon applied successfully!'),
        ),
      );
    } else {
      setState(() {
        _isCouponApplied = false;
        _discountAmount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Text('Invalid coupon code. Please check and try again.'),
        ),
      );
    }
  }

  Future<void> _fetchDiscount() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.worldtriplink.com/discount/getAll'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (var item in data) {
          final discount = Discount.fromJson(item);
          if (discount.isEnabled?.toLowerCase() == 'true') {
            setState(() {
              _discountData = discount;
              _discountAmount = discount.priceDiscount ?? 0;
            });
            break;
          }
        }
      } else {
        if (kDebugMode) print('Failed to load discount data: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching discount: $e');
    }
  }

  Future<List<FirstBooking>> fetchBookings(String userId) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/by-user/$userId'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => FirstBooking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch bookings: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> loadBookings() async {
    if (_storedUserId == null) return;

    try {
      final fetchedBookings = await fetchBookings(_storedUserId!);
      setState(() {
        bookings = fetchedBookings;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading bookings: $e');
    }
  }

  Future<void> _getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId;

      if (prefs.containsKey('userId')) {
        userId = prefs.getInt('userId')?.toString();
      } else if (prefs.containsKey('userData')) {
        final userData = prefs.getString('userData');
        if (userData != null) {
          final parsedData = json.decode(userData);
          userId = parsedData['id']?.toString();
        }
      }

      setState(() {
        _storedUserId = userId ?? widget.bookingData['userId']?.toString();
      });

      if (_storedUserId != null) {
        await loadBookings();
      }
    } catch (e) {
      if (kDebugMode) print('Error retrieving user data: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (kDebugMode) {
      print('Payment success: paymentId=${response.paymentId}, orderId=${response.orderId}, signature=${response.signature}');
    }
    _processBooking(
      paymentId: response.paymentId!,
      orderId: response.orderId,
      signature: response.signature,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    String errorMessage;
    switch (response.code) {
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'You cancelled the payment. Please try again.';
        break;
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network issue. Please check your internet and try again.';
        break;
      default:
        errorMessage = 'Payment failed: ${response.message ?? 'Unknown error'}. Please try again or contact support.';
    }
    if (kDebugMode) print('Payment error: ${response.code} - ${response.message}');
    _showErrorDialog(errorMessage);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isLoading = false);
    if (kDebugMode) print('External wallet selected: ${response.walletName}');
    _showErrorDialog('Payment via ${response.walletName} is not supported. Please choose another method.');
  }

  Future<void> _processBooking({
    String? paymentId,
    String? orderId,
    String? signature,
  }) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? effectiveUserId = _storedUserId ?? prefs.getInt('userId')?.toString();

      if (effectiveUserId == null && prefs.containsKey('userData')) {
        final userData = prefs.getString('userData');
        if (userData != null) {
          final parsedData = json.decode(userData);
          effectiveUserId = parsedData['id']?.toString();
        }
      }

      effectiveUserId ??= widget.bookingData['userId']?.toString() ?? '0';

      int totalFare = int.tryParse(widget.bookingData['totalFare']?.toString() ?? '0') ?? 0;
      if (_isCouponApplied) {
        totalFare -= _discountAmount;
        if (totalFare < 0) totalFare = 0;
      }

      int paymentAmount = _selectedPaymentMethod == 'Online' && _selectedPaymentType == 'partial'
          ? (totalFare * 0.25).round()
          : totalFare;

      final Map<String, String?> queryParams = {
        'cabId': widget.bookingData['cabId']?.toString() ?? '',
        'modelName': widget.bookingData['vehicleType']?.toString() ?? '',
        'modelType': widget.bookingData['modelType']?.toString() ?? '',
        'seats': widget.bookingData['seats']?.toString() ?? '',
        'fuelType': widget.bookingData['fuelType']?.toString() ?? '',
        'availability': widget.bookingData['availability']?.toString() ?? '',
        'price': widget.bookingData['baseFare']?.toString() ?? '0',
        'pickupLocation': widget.bookingData['pickup']?.toString() ?? '',
        'dropLocation': widget.bookingData['destination']?.toString() ?? '',
        'date': widget.bookingData['date']?.toString() ?? '',
        'returndate': widget.bookingData['returnDate']?.toString(),
        'time': widget.bookingData['time']?.toString() ?? '',
        'tripType': widget.bookingData['bookingType']?.toString() ?? 'oneWay',
        'distance': widget.bookingData['distance']?.toString() ?? '0',
        'name': widget.bookingData['passengerName']?.toString() ?? '',
        'email': widget.bookingData['passengerEmail']?.toString() ?? '',
        'service': widget.bookingData['platformFee']?.toString() ?? '0',
        'gst': widget.bookingData['gst']?.toString() ?? '0',
        'total': totalFare.toString(),
        'days': widget.bookingData['days']?.toString() ?? '1',
        'driverrate': widget.bookingData['driverRate']?.toString() ?? '0',
        'phone': widget.bookingData['passengerPhone']?.toString() ?? '',
        'userId': effectiveUserId,
        'paymentMethod': _selectedPaymentMethod,
        'paymentType': _selectedPaymentMethod == 'Online' ? _selectedPaymentType ?? 'full' : 'cash',
        'paymentStatus': paymentId != null ? 'success' : 'pending',
        'amountPaid': paymentAmount.toString(),
        'remainingAmount': _selectedPaymentType == 'partial' ? (totalFare - paymentAmount).toString() : '0',
        'razorpayOrderId': orderId,
        'razorpayPaymentId': paymentId,
        'razorpaySignature': signature,
      };

      final uri = Uri.parse('${dotenv.env['API_BASE_URL']}/bookingConfirm').replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('Processing booking with URL: $uri');
      }

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Booking response: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _showBookingConfirmation(data['bookingId'] ?? 'Unknown');
        } else {
          _showErrorDialog('Booking failed: ${data['message'] ?? 'Unknown error'}.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      _showErrorDialog('Request timed out. Please check your connection and try again.');
    } catch (e) {
      if (kDebugMode) print('Error processing booking: $e');
      _showErrorDialog('Something went wrong. Please try again or contact support.');
      print('Something went wrong: $e. Please try again or contact support.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);

    try {
      if (!dotenv.isEveryDefined(['RAZORPAY_KEY', 'API_BASE_URL'])) {
        throw Exception('Environment variables not loaded');
      }

      final razorpayKey = dotenv.env['RAZORPAY_KEY']!;
      if (razorpayKey.isEmpty) {
        throw Exception('Razorpay key is empty');
      }

      int totalFare = int.tryParse(widget.bookingData['totalFare']?.toString() ?? '0') ?? 0;
      if (totalFare <= 0) {
        throw Exception('Invalid total fare: $totalFare');
      }

      if (_isCouponApplied) {
        totalFare -= _discountAmount;
        if (totalFare < 0) totalFare = 0;
      }

      int paymentAmount = _selectedPaymentMethod == 'Online' && _selectedPaymentType == 'partial'
          ? (totalFare * 0.25).round()
          : totalFare;

      if (paymentAmount < 100) {
        throw Exception('Payment amount must be at least 100 paise: $paymentAmount');
      }

      if (kDebugMode) {
        print('Total fare: $totalFare, Payment amount: $paymentAmount');
      }

      if (_selectedPaymentMethod == 'Online') {
        var options = {
          'key': razorpayKey,
          'amount': paymentAmount * 100, // Razorpay expects amount in paise
          'name': 'WorldTripLink',
          'description': 'Booking Payment',
          'timeout': 300,
          'prefill': {
            'contact': widget.bookingData['passengerPhone']?.toString() ?? '',
            'email': widget.bookingData['passengerEmail']?.toString() ?? '',
          },
          'external': {'wallets': ['paytm']},
          'retry': {'enabled': true, 'max_count': 3},
          'notes': {
            'userId': _storedUserId ?? widget.bookingData['userId']?.toString() ?? '0',
            'bookingType': widget.bookingData['bookingType'] ?? 'oneWay',
          },
        };

        if (kDebugMode) {
          print('Opening Razorpay with options: ${jsonEncode(options)}');
        }

        _razorpay.open(options);
      } else {
        await _processBooking(paymentId: 'CASH_PAYMENT');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (kDebugMode) print('Error initiating payment: $e');
      _showErrorDialog('Failed to initiate payment: ${e.toString().split(':').last.trim()}.');
    }
  }

  void _showBookingConfirmation(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                            accentColor,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: -20,
                            left: -50,
                            right: -50,
                            child: Container(
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(100),
                                  topRight: Radius.circular(100),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 30,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.airplane_ticket,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const Text(
                                  'BOOKING CONFIRMED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Text(
                            'Woohoo! Your booking is all set!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get ready for an amazing experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Booking ID',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            bookingId,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 1,
                                  child: Row(
                                    children: List.generate(
                                      30,
                                      (index) => Expanded(
                                        child: Container(
                                          height: 1,
                                          color: index.isEven
                                              ? Colors.grey.shade300
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildTicketInfo('📧', 'Email Sent', 'Check inbox'),
                                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                                      _buildTicketInfo('⭐', 'Status', 'Confirmed'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor, accentColor],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                                        (route) => false,
                                      );
                                    },
                                    icon: const Icon(Icons.home, size: 18, color: Colors.white),
                                    label: const Text(
                                      'Back to Home',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                    ),
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
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [successColor, successColor.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: successColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
            const Text('Oops!'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_selectedPaymentMethod == 'Online')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handlePayment();
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFare = int.tryParse(widget.bookingData['totalFare']?.toString() ?? '0') ?? 0;
    final discountedTotal = _isCouponApplied ? totalFare - _discountAmount : totalFare;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 70),
          child: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                  const SizedBox(height: 16),
                  Text('Processing your payment...', style: TextStyle(color: lightTextColor, fontSize: 16)),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.lock_rounded, color: successColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Secure Payment',
                          style: TextStyle(color: successColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
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
                                Expanded(flex: 4, child: _buildPaymentMethods()),
                              ],
                            );
                          } else {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildTripSummary(),
                                  const SizedBox(height: 16),
                                  _buildPaymentMethods(),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
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
                  child: Icon(Icons.directions_car_rounded, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trip Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Icon(Icons.location_on, color: primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PICKUP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: lightTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.bookingData['pickup']?.toString() ?? 'Pickup location',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              Container(width: 2, height: 30, color: Colors.grey.shade300),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.flag, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DROP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: lightTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.bookingData['destination']?.toString() ?? 'Drop location',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
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
              child: _buildDetailItem(Icons.calendar_today, 'Date', widget.bookingData['date']?.toString() ?? ''),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(Icons.access_time, 'Time', widget.bookingData['time']?.toString() ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                  Icons.person, 'Passenger', _getShortName(widget.bookingData['passengerName']?.toString() ?? '')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                  Icons.phone, 'Contact', widget.bookingData['passengerPhone']?.toString() ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailItem(Icons.directions_car, 'Vehicle', widget.bookingData['vehicleType']?.toString() ?? ''),
        if (widget.bookingData['bookingType'] == 'roundTrip' && widget.bookingData['returnDate'] != null) ...[
          const SizedBox(height: 12),
          _buildDetailItem(
              Icons.calendar_today, 'Return Date', widget.bookingData['returnDate']?.toString() ?? ''),
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
              Text(label, style: TextStyle(fontSize: 12, color: lightTextColor)),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareDetails() {
    final total = int.tryParse(widget.bookingData['total']?.toString() ?? '0') ?? 0;
    final platformFee = int.tryParse(widget.bookingData['platformFee']?.toString() ?? '0') ?? 0;
    final gst = int.tryParse(widget.bookingData['gst']?.toString() ?? '0') ?? 0;
    final totalFare = total + platformFee + gst;

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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFareRow('Base Fare', '₹$total'),
        const SizedBox(height: 8),
        _buildFareRow('Platform Fee', '₹$platformFee'),
        const SizedBox(height: 8),
        _buildFareRow('GST (5%)', '₹$gst'),
        const SizedBox(height: 8),
        if (_isCouponApplied) _buildFareRow('Discount', '-₹$_discountAmount'),
        const Divider(),
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
    final totalFare = int.tryParse(widget.bookingData['totalFare']?.toString() ?? '0') ?? 0;
    final discountedTotal = _isCouponApplied ? totalFare - _discountAmount : totalFare;
    final partialAmount = (discountedTotal * 0.25).round();

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentOption('Cash Payment', 'Pay directly to the driver',
                      MaterialCommunityIcons.cash, 'cash'),
                  const SizedBox(height: 10),
                  _buildPaymentOption('Online Payment', 'Pay securely online',
                      MaterialCommunityIcons.credit_card, 'Online'),
                  if (_selectedPaymentMethod == 'Online') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Payment Type',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentTypeOption('Full Payment', 'Pay ₹$discountedTotal', 'full', discountedTotal),
                    const SizedBox(height: 8),
                    _buildPaymentTypeOption('Partial Payment (25%)', 'Pay ₹$partialAmount', 'partial', partialAmount),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, IconData icon, String value) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? lightAccentColor.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: successColor, width: 1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? successColor.withOpacity(0.2) : Colors.grey.shade100,
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
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeOption(String title, String subtitle, String value, int amount) {
    final isSelected = _selectedPaymentType == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? lightAccentColor.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: successColor, width: 1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? successColor.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.payment,
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
              groupValue: _selectedPaymentType,
              onChanged: (value) => setState(() => _selectedPaymentType = value!),
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentFooter(int discountedTotal, int originalTotal) {
    final paymentAmount = _selectedPaymentMethod == 'Online' && _selectedPaymentType == 'partial'
        ? (discountedTotal * 0.25).round()
        : discountedTotal;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  if (_isCouponApplied || _selectedPaymentType == 'partial') ...[
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
                      '₹$paymentAmount',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ] else
                    Text(
                      '₹$originalTotal',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _selectedPaymentMethod == 'cash' ? 'Confirm Booking' : 'Pay Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Please enter a coupon code' : null,
        ),
        Row(
          children: [
            const Text(
              'Coupon Code',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => _buildDialog(context),
              child: const Text('View Code', style: TextStyle(decoration: TextDecoration.underline)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                if (_couponController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.redAccent,
                      content: Center(
                        child: Text("Please enter a coupon code",
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                  return;
                }

                if (bookings.isEmpty) { // Apply coupon for first booking only
                  _applyCoupon();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.redAccent,
                      content: Center(
                        child: Text("Coupon valid for first booking only",
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Apply',
                style: TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        if (_isCouponApplied)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '₹$_discountAmount discount applied!',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, size: 50, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  "Congratulations!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  "You've unlocked ₹$_discountAmount OFF on your first booking!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.lightBlueAccent, Colors.blueAccent]),
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
                          final coupon = _discountData?.couponCode?.toUpperCase() ?? '';
                          Clipboard.setData(ClipboardData(text: coupon));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green,
                              content: Center(
                                child: Text(
                                  "Coupon code copied",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.copy, color: Colors.white),
                      ),
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