import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/admin_driver_trip_model.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/app_constants.dart';

// Color constants
const Color primaryColor = Color(0xFF3057E3);
const Color secondaryColor = Color(0xFF3057E3);
const Color accentColor = Color(0xFFFFCC00);
const Color backgroundColor = Color(0xFFF3F5F9);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF666666);
const Color mutedTextColor = Color(0xFFAAAAAA);
const Color successColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFE53935);
const Color warningColor = Color(0xFFFF9800);

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  List<AdminDriverTrip> trips = [];
  List<AdminDriverTrip> filteredTrips = [];
  bool isLoading = true;
  String activeTab = 'pending';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Driver information
  String driverName = '';
  String driverEmail = '';
  String driverMobile = '';
  String userId = '';
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadDriverInfo();
    _fetchAdminDriverTrips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverInfo() async {
    try {
      // Use StorageService to get user data
      final userData = StorageService.getObject(AppConstants.keyUserData);
      final storedUserId = StorageService.getInt(AppConstants.keyUserId);
      final storedRole = StorageService.getString(AppConstants.keyUserRole);

      if (userData != null) {
        setState(() {
          driverName = userData['username'] ?? userData['name'] ?? 'Driver';
          driverEmail = userData['email'] ?? '';
          driverMobile = userData['phone'] ?? userData['mobile'] ?? '';
          userId = userData['id']?.toString() ?? storedUserId.toString();
          userRole = userData['role'] ?? storedRole;
        });
      } else {
        // Fallback to individual stored values
        setState(() {
          driverName = 'Driver';
          driverEmail = '';
          driverMobile = '';
          userId = storedUserId > 0 ? storedUserId.toString() : '';
          userRole = storedRole;
        });
      }

      // If userId is still empty, try SharedPreferences directly as fallback
      if (userId.isEmpty || userId == '0') {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        debugPrint('Available SharedPreferences keys: $allKeys');

        for (String key in allKeys) {
          final value = prefs.get(key);
          debugPrint('Key: $key, Value: $value, Type: ${value.runtimeType}');
        }

        // Try different possible keys
        final fallbackUserId = prefs.getString('user_id') ??
                              prefs.getInt('user_id')?.toString() ??
                              prefs.getString('id') ??
                              prefs.getInt('id')?.toString() ?? '';

        if (fallbackUserId.isNotEmpty) {
          setState(() {
            userId = fallbackUserId;
          });
        }
      }

      debugPrint('Driver Info Loaded: $driverName, ID: $userId, Role: $userRole');
    } catch (error) {
      debugPrint('Error loading driver info: $error');
    }
  }

  Future<void> _fetchAdminDriverTrips() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get user ID using StorageService
      String apiUserId = '';

      // Try to get userId from stored user data first
      final userData = StorageService.getObject(AppConstants.keyUserData);
      if (userData != null) {
        apiUserId = userData['id']?.toString() ?? '';
      }

      // If userId is still empty, try the stored userId directly
      if (apiUserId.isEmpty) {
        final storedUserId = StorageService.getInt(AppConstants.keyUserId);
        apiUserId = storedUserId > 0 ? storedUserId.toString() : '';
      }

      // Fallback to SharedPreferences if still empty
      if (apiUserId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        apiUserId = prefs.getInt('userId')?.toString() ??
                   prefs.getString('userId') ??
                   prefs.getString('user_id') ??
                   prefs.getInt('user_id')?.toString() ??
                   prefs.getString('id') ??
                   prefs.getInt('id')?.toString() ?? '';
      }

      if (apiUserId.isEmpty) {
        throw Exception('No user ID found. Please login again.');
      }

      // Update the displayed userId if it's different
      if (userId != apiUserId) {
        setState(() {
          userId = apiUserId;
        });
      }

      debugPrint('Fetching admin driver trips for userId: $apiUserId');

      final response = await http.get(
        Uri.parse('https://api.worldtriplink.com/api/admin-driver/$apiUserId'),
      );

      debugPrint('Admin driver trips API response status: ${response.statusCode}');
      debugPrint('Admin driver trips API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          trips = jsonData.map((json) {
            final trip = AdminDriverTrip.fromJson(json);
            // Validate status
            if (![0, 2, 3].contains(trip.status)) {
              debugPrint('Warning: Invalid status ${trip.status} for trip ${trip.bookingId}');
            }
            return trip;
          }).toList();
          _filterTrips();
          isLoading = false;
        });
        _animationController.forward();
      } else {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching admin driver trips: $error');
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load trips. Please try again.');
    }
  }

  void _filterTrips() {
    setState(() {
      switch (activeTab) {
        case 'pending':
          filteredTrips = trips.where((trip) => trip.status == 0).toList();
          break;
        case 'completed':
          filteredTrips = trips.where((trip) => trip.status == 2).toList();
          break;
        case 'cancelled':
          filteredTrips = trips.where((trip) => trip.status == 3).toList();
          break;
        default:
          filteredTrips = trips; // Fallback to show all trips if tab is unknown
          break;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _fetchAdminDriverTrips(),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Admin Driver',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAdminDriverTrips,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDriverInfoHeader(),
          _buildTabBar(),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : filteredTrips.isEmpty
                    ? _buildEmptyState()
                    : _buildTripsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoHeader() {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Driver Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Driver Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName.isNotEmpty ? driverName : 'Admin Driver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (driverEmail.isNotEmpty)
                      Text(
                        driverEmail,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    if (driverMobile.isNotEmpty)
                      Text(
                        driverMobile,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),

              // User ID Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'ID',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userId.isNotEmpty ? userId : 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Role Badge
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: textColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  userRole.isNotEmpty ? userRole : 'ADMIN_DRIVER',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabButton('Pending', 'pending'),
            _buildTabButton('Completed', 'completed'),
            _buildTabButton('Cancelled', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tabKey) {
    final bool isActive = activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = tabKey;
            _filterTrips();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? primaryColor : lightTextColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Capitalize the first letter of activeTab for display
    String displayTab = activeTab[0].toUpperCase() + activeTab.substring(1);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: mutedTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No $displayTab trips',
            style: TextStyle(
              fontSize: 18,
              color: lightTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trips will appear here when available',
            style: TextStyle(
              fontSize: 14,
              color: mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchAdminDriverTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          final trip = filteredTrips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(AdminDriverTrip trip) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booking ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking: ${trip.bookingId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: trip.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: trip.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    trip.statusText,
                    style: TextStyle(
                      color: trip.statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route information
            Row(
              children: [
                const Icon(Icons.location_on, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${trip.fromLocation}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To: ${trip.toLocation}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Trip details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today,
                    'Date',
                    trip.date,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.access_time,
                    'Time',
                    trip.time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.directions_car,
                    'Car',
                    trip.car.toUpperCase(),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.route,
                    'Distance',
                    '${trip.distance} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: lightTextColor),
                      const SizedBox(width: 8),
                      Text(
                        trip.name,
                        style: const TextStyle(fontSize: 14, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: lightTextColor),
                      const SizedBox(width: 8),
                      Text(
                        trip.phone,
                        style: const TextStyle(fontSize: 14, color: textColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Amount and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${trip.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Row(
                  children: [
                    if (trip.phone.isNotEmpty && trip.phone != 'N/A')
                      ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(trip.phone),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: lightTextColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: mutedTextColor,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}