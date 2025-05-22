import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../features/booking/screens/passenger_details_screen.dart';
import '../../../features/booking/screens/cab_booking_screen.dart';

const String apiBaseUrl = 'https://api.worldtriplink.com/api';

class SelectVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const SelectVehicleScreen({super.key, required this.bookingData});

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  String _selectedCategory = 'HatchBack';
  bool _isLoading = true;
  String _tripDistance = '0';
  Map<String, dynamic>? _tripInfo;

  // Color scheme for consistent styling - matching the app's professional style
  final Color primaryColor =
      const Color(0xFF3057E3); // Royal blue from the image
  final Color secondaryColor =
      const Color(0xFF3057E3); // Same blue for consistency
  final Color accentColor = const Color(0xFFFFCC00); // Yellow/gold accent
  final Color backgroundColor =
      const Color(0xFFF3F5F9); // Light gray background
  final Color cardColor = Colors.white; // White card background
  final Color surfaceColor = Colors.white; // White for inputs/surfaces
  final Color textColor = const Color(0xFF333333); // Dark text
  final Color lightTextColor = const Color(0xFF666666); // Medium gray text
  final Color mutedTextColor = const Color(0xFFAAAAAA); // Light gray text
  final Color lightAccentColor =
      const Color(0xFFF0F7FF); // Light blue background

  // Vehicle data organized by category
  Map<String, List<Vehicle>> _vehicleData = {
    'HatchBack': [],
    'Sedan': [],
    'SedanPremium': [],
    'SUV': [],
    'SUVPlus': [],
  };

  // Track availability by category
  Map<String, bool> _noVehiclesAvailable = {
    'HatchBack': true,
    'Sedan': true,
    'SedanPremium': true,
    'SUV': true,
    'SUVPlus': true,
  };

  // Map of vehicle images by category
  final Map<String, String> _vehicleImages = {
    'hatchback': 'assets/images/hatchback.png',
    'sedan': 'assets/images/sedan.png',
    'sedanpremium': 'assets/images/sedan_premium.png',
    'suv': 'assets/images/suv.png',
    'suvplus': 'assets/images/suv_plus.png',
  };

  // Map of category icons
  final Map<String, IconData> _categoryIcons = {
    'HatchBack': MaterialCommunityIcons.car_hatchback,
    'Sedan': MaterialCommunityIcons.car_2_plus,
    'SedanPremium': MaterialCommunityIcons.car_sports,
    'SUV': MaterialCommunityIcons.car_estate,
    'SUVPlus': MaterialCommunityIcons.car_3_plus,
  };

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/cab1'),
        body: {
          'tripType': widget.bookingData['bookingType'],
          'pickupLocation': widget.bookingData['pickup'],
          'dropLocation': widget.bookingData['destination'],
          'date': widget.bookingData['date'],
          'time': widget.bookingData['time'],
          'hours': widget.bookingData['hours'] ?? '',
          'Returndate': widget.bookingData['returnDate'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tripInfo = data;
          _tripDistance = data['distance']?.toString() ?? '0';
          _processVehicleData(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _processVehicleData(Map<String, dynamic> data) {
    if (data['tripinfo'] == null || data['tripinfo'].isEmpty) {
      return;
    }

    final tripDetails = data['tripinfo'][0];
    final calculatedDistance = double.tryParse(_tripDistance) ?? 150;

    // Reset availability
    final newNoVehiclesAvailable = Map<String, bool>.from(_noVehiclesAvailable);
    final newVehicleData = <String, List<Vehicle>>{};

    // Initialize empty lists for each category
    for (var category in _vehicleData.keys) {
      newVehicleData[category] = [];
    }

    // HatchBack vehicles
    if (tripDetails['hatchback'] > 0) {
      newNoVehiclesAvailable['HatchBack'] = false;
      newVehicleData['HatchBack'] = [
        Vehicle(
          type: 'Maruti Swift',
          price: (calculatedDistance * tripDetails['hatchback']).round(),
          pricePerKm: tripDetails['hatchback'],
          capacity: '2 bags',
          features: [
            'Petrol',
            'USB Charging',
            'Air Conditioning',
            'Music System',
          ],
          rating: 4,
          rides: 198,
          arrivalTime: '3 mins',
          available: true,
          modelType: 'hatchback',
          seats: '4',
          imageUrl:
              _vehicleImages['hatchback'] ?? 'assets/images/hatchback.png',
        ),
      ];
    }

    // Sedan vehicles
    if (tripDetails['sedan'] > 0) {
      newNoVehiclesAvailable['Sedan'] = false;
      newVehicleData['Sedan'] = [
        Vehicle(
          type: 'Maruti Swift Dzire',
          price: (calculatedDistance * tripDetails['sedan']).round(),
          pricePerKm: tripDetails['sedan'],
          capacity: '3 bags',
          features: [
            'Diesel',
            'USB Charging',
            'Air Conditioning',
            'Music System',
          ],
          rating: 4,
          rides: 220,
          arrivalTime: '5 mins',
          available: true,
          modelType: 'sedan',
          seats: '4',
          imageUrl: _vehicleImages['sedan'] ?? 'assets/images/sedan.png',
        ),
      ];
    }

    // SedanPremium vehicles
    if (tripDetails['sedanpremium'] > 0) {
      newNoVehiclesAvailable['SedanPremium'] = false;
      newVehicleData['SedanPremium'] = [
        Vehicle(
          type: 'Honda City',
          price: (calculatedDistance * tripDetails['sedanpremium']).round(),
          pricePerKm: tripDetails['sedanpremium'],
          capacity: '4 bags',
          features: [
            'Diesel',
            'USB Charging',
            'Air Conditioning',
            'Music System',
            'Leather Seats',
          ],
          rating: 4,
          rides: 180,
          arrivalTime: '7 mins',
          available: true,
          modelType: 'sedanpremium',
          seats: '5',
          imageUrl: _vehicleImages['sedanpremium'] ??
              'assets/images/sedan_premium.png',
        ),
      ];
    }

    // SUV vehicles
    if (tripDetails['suv'] > 0) {
      newNoVehiclesAvailable['SUV'] = false;
      newVehicleData['SUV'] = [
        Vehicle(
          type: 'Toyota Innova',
          price: (calculatedDistance * tripDetails['suv']).round(),
          pricePerKm: tripDetails['suv'],
          capacity: '5 bags',
          features: [
            'Diesel',
            'USB Charging',
            'Air Conditioning',
            'Music System',
            'Spacious',
          ],
          rating: 4,
          rides: 250,
          arrivalTime: '10 mins',
          available: true,
          modelType: 'suv',
          seats: '7',
          imageUrl: _vehicleImages['suv'] ?? 'assets/images/suv.png',
        ),
      ];
    }

    // SUVPlus vehicles
    if (tripDetails['suvplus'] > 0) {
      newNoVehiclesAvailable['SUVPlus'] = false;
      newVehicleData['SUVPlus'] = [
        Vehicle(
          type: 'Toyota Fortuner',
          price: (calculatedDistance * tripDetails['suvplus']).round(),
          pricePerKm: tripDetails['suvplus'],
          capacity: '6 bags',
          features: [
            'Diesel',
            'USB Charging',
            'Air Conditioning',
            'Music System',
            'Premium Interior',
          ],
          rating: 4,
          rides: 150,
          arrivalTime: '15 mins',
          available: true,
          modelType: 'suvplus',
          seats: '7',
          imageUrl: _vehicleImages['suvplus'] ?? 'assets/images/suv_plus.png',
        ),
      ];
    }

    setState(() {
      _vehicleData = newVehicleData;
      _noVehiclesAvailable = newNoVehiclesAvailable;

      // Set first available category as selected
      for (var category in _vehicleData.keys) {
        if (!newNoVehiclesAvailable[category]!) {
          _selectedCategory = category;
          break;
        }
      }
    });
  }

  void _handleVehicleSelect(Vehicle vehicle) {
    // Calculate fare components
    final distance = double.tryParse(_tripDistance) ?? 0;
    final baseFare = vehicle.price;
    final platformFee = (baseFare * 0.10).round(); // 10% platform fee
    final gst = (baseFare * 0.05).round(); // 5% GST (changed from 18%)
    final totalFare = baseFare + platformFee + gst;

    // Prepare data for passenger details screen
    final bookingDetails = {
      ...widget.bookingData,
      'vehicleType': vehicle.type,
      'price': '₹${vehicle.price}',
      'baseFare': baseFare.toString(),
      'platformFee': platformFee,
      'gst': gst,
      'totalFare': totalFare,
      'modelType': vehicle.modelType,
      'distance': _tripDistance,
      'seats': vehicle.seats,
      'imageUrl': vehicle.imageUrl,
    };

    // Navigate to passenger details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PassengerDetailsScreen(bookingData: bookingDetails),
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
        title: const Center(
          child: Text(
            'Select Vehicle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to CabBookingScreen
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (context) => const CabBookingScreen()),
            );
          },
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Finding the best vehicles for you...',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildTripSummary(),
                Expanded(child: _buildVehicleList()),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : _buildCategoryNavBar(),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trip Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  MaterialCommunityIcons.map_marker_path,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.bookingData['pickup'] ?? 'Pickup',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      height: 20,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.bookingData['destination'] ?? 'Destination',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: lightAccentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_tripDistance km',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.bookingData['date'] ?? 'Date',
                    style: TextStyle(color: lightTextColor, fontSize: 12),
                  ),
                  Text(
                    widget.bookingData['time'] ?? 'Time',
                    style: TextStyle(color: lightTextColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Trip Type: ${widget.bookingData['bookingType'] == 'oneWay' ? 'One Way' : widget.bookingData['bookingType'] == 'roundTrip' ? 'Round Trip' : 'Rental'}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: primaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCategoryNavItem('HatchBack', 'Hatchback'),
          _buildCategoryNavItem('Sedan', 'Sedan'),
          _buildCategoryNavItem('SedanPremium', 'Premium'),
          _buildCategoryNavItem('SUV', 'SUV'),
          _buildCategoryNavItem('SUVPlus', 'SUV+'),
        ],
      ),
    );
  }

  Widget _buildCategoryNavItem(String category, String label) {
    final isSelected = _selectedCategory == category;
    final isAvailable = !_noVehiclesAvailable[category]!;

    return InkWell(
      onTap: isAvailable
          ? () => setState(() => _selectedCategory = category)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
          color: isSelected ? Colors.blue[50] : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcons[category] ?? MaterialCommunityIcons.car,
              color: isAvailable
                  ? (isSelected ? primaryColor : lightTextColor)
                  : Colors.grey.shade300,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isAvailable
                    ? (isSelected ? textColor : lightTextColor)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    final vehicles = _vehicleData[_selectedCategory] ?? [];

    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MaterialCommunityIcons.car_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles available in this category',
              style: TextStyle(color: lightTextColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select another category',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) => _buildVehicleCard(vehicles[index]),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle image
                SizedBox(
                  width: 100,
                  height: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      // color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        vehicle.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _categoryIcons[_selectedCategory] ??
                              MaterialCommunityIcons.car,
                          size: 32,
                          color: primaryColor,
                        ),
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
                        vehicle.type,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            MaterialCommunityIcons.seat,
                            size: 16,
                            color: lightTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${vehicle.seats} Seats',
                            style: TextStyle(
                              color: lightTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            MaterialCommunityIcons.bag_suitcase,
                            size: 16,
                            color: lightTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.capacity,
                            style: TextStyle(
                              color: lightTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${vehicle.rating}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${vehicle.rides} rides)',
                            style: TextStyle(
                              color: lightTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${vehicle.price}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '₹${vehicle.pricePerKm}/km',
                        style: TextStyle(color: lightTextColor, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MaterialCommunityIcons.clock_outline,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            vehicle.arrivalTime,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'Features',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vehicle.features
                  .map(
                    (feature) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _handleVehicleSelect(vehicle),
                child: const Text(
                  'Select This Vehicle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Show vehicle details dialog
                  showDialog(
                    context: context,
                    builder: (context) => _buildVehicleDetailsDialog(vehicle),
                  );
                },
                icon: Icon(
                  MaterialCommunityIcons.information_outline,
                  size: 18,
                  color: primaryColor,
                ),
                label: Text(
                  'View Details',
                  style: TextStyle(color: primaryColor, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsDialog(Vehicle vehicle) {
    return AlertDialog(backgroundColor: Colors.white,
      title: Text(
        vehicle.type,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 220,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(vehicle.imageUrl, fit: BoxFit.fill),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Capacity', '${vehicle.seats} Seats'),
            _buildDetailRow('Luggage', vehicle.capacity),
            _buildDetailRow(
              'Price',
              '₹${vehicle.price} (₹${vehicle.pricePerKm}/km)',
            ),
            _buildDetailRow(
              'Rating',
              '${vehicle.rating} (${vehicle.rides} rides)',
            ),
            _buildDetailRow('Arrival Time', vehicle.arrivalTime),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              'Features',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            ...vehicle.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(feature),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              'Fare Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            _buildFareRow('Base Fare', '₹${vehicle.price}'),
            _buildFareRow(
              'Platform Fee (10%)',
              '₹${(vehicle.price * 0.10).round()}',
            ),
            _buildFareRow('GST (5%)', '₹${(vehicle.price * 0.05).round()}'),
            const Divider(),
            _buildFareRow(
              'Total Fare',
              '₹${vehicle.price + (vehicle.price * 0.05).round() + (vehicle.price * 0.10).round()}',
              isBold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: primaryColor)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _handleVehicleSelect(vehicle);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: lightTextColor, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? textColor : lightTextColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? primaryColor : textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class Vehicle {
  final String type;
  final int price;
  final int pricePerKm;
  final String capacity;
  final List<String> features;
  final int rating;
  final int rides;
  final String arrivalTime;
  final bool available;
  final String modelType;
  final String seats;
  final String imageUrl;

  Vehicle({
    required this.type,
    required this.price,
    required this.pricePerKm,
    required this.capacity,
    required this.features,
    required this.rating,
    required this.rides,
    required this.arrivalTime,
    required this.available,
    required this.modelType,
    required this.seats,
    required this.imageUrl,
  });
}
