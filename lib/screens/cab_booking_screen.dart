import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:worldtriplink/screens/select_vehicle_screen.dart';
import 'package:worldtriplink/screens/user_home_screen.dart';

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

class CabBookingScreen extends StatefulWidget {
  const CabBookingScreen({super.key});

  @override
  State<CabBookingScreen> createState() => _CabBookingScreenState();
}

class _CabBookingScreenState extends State<CabBookingScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  String _bookingType = 'oneWay';
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedReturnDate;
  TimeOfDay? _selectedTime;
  String _hours = '';
  LocationData? _currentLocation;

  List<dynamic> _pickupSuggestions = [];
  List<dynamic> _dropSuggestions = [];
  bool _isLoadingLocation = false;
  
  // Color scheme for consistent styling
  final Color primaryColor = const Color(0xFF2E3192);
  final Color accentColor = const Color(0xFFFFCC00);
  final Color lightAccentColor = const Color(0xFFFFF9E0);
  final Color textColor = const Color(0xFF333333);
  final Color lightTextColor = const Color(0xFF666666);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    
    // Set default date and time
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    Location location = Location();
    
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    try {
      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = locationData;
        _isLoadingLocation = false;
      });
      _reverseGeocode(locationData);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }

  Future<void> _reverseGeocode(LocationData location) async {
    try {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}&key=$googleMapsApiKey'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            _pickupController.text = data['results'][0]['formatted_address'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get address: $e')),
      );
    }
  }

  Future<void> _searchPlaces(String query, String type) async {
    if (query.length < 2) {
      setState(() {
        if (type == 'pickup') {
          _pickupSuggestions = [];
        } else {
          _dropSuggestions = [];
        }
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query&key=$googleMapsApiKey&components=country:in'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (type == 'pickup') {
            _pickupSuggestions = data['predictions'] ?? [];
          } else {
            _dropSuggestions = data['predictions'] ?? [];
          }
        });
      }
    } catch (e) {
      // Silently fail on search error
    }
  }

  Future<void> _selectDate(BuildContext context, bool isReturnDate) async {
    final DateTime initialDate = isReturnDate && _selectedDate != null 
        ? _selectedDate!.add(const Duration(days: 1))
        : DateTime.now();
        
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isReturnDate) {
          _selectedReturnDate = picked;
        } else {
          _selectedDate = picked;
          // If return date is before the new selected date, update it
          if (_bookingType == 'roundTrip' && 
              _selectedReturnDate != null && 
              _selectedReturnDate!.isBefore(picked)) {
            _selectedReturnDate = picked.add(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
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
          'Book a Cab',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to UserHomeScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const UserHomeScreen(),
              ),
            );
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTripTypeCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              _buildDateTimeCard(),
              const SizedBox(height: 24),
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeCard() {
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
                Icon(MaterialCommunityIcons.car_multiple, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Trip Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTripTypeButton('One Way', MaterialCommunityIcons.arrow_right_thick, 'oneWay'),
                const SizedBox(width: 8),
                _buildTripTypeButton('Round Trip', MaterialCommunityIcons.autorenew, 'roundTrip'),
                const SizedBox(width: 8),
                _buildTripTypeButton('Rental', MaterialCommunityIcons.car_convertible, 'rental'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeButton(String label, IconData icon, String type) {
    final isSelected = _bookingType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _bookingType = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? lightAccentColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? accentColor : Colors.grey[400], 
                size: 24
              ),
              const SizedBox(height: 8),
              Text(
                label, 
                style: TextStyle(
                  color: isSelected ? textColor : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
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
                Icon(MaterialCommunityIcons.map_marker_path, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Locations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLocationInput('Pickup Location', _pickupController, _pickupSuggestions, 'pickup'),
            const SizedBox(height: 16),
            _buildLocationInput('Drop Location', _dropController, _dropSuggestions, 'drop'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput(String label, TextEditingController controller, 
                            List<dynamic> suggestions, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: lightTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(
              MaterialCommunityIcons.map_marker,
              color: primaryColor.withOpacity(0.7),
              size: 20,
            ),
            suffixIcon: type == 'pickup' ? _buildLocationIcon() : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          onChanged: (value) => _searchPlaces(value, type),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    controller.text = suggestions[index]['description'];
                    setState(() {
                      if (type == 'pickup') {
                        _pickupSuggestions = [];
                      } else {
                        _dropSuggestions = [];
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          MaterialCommunityIcons.map_marker_outline,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestions[index]['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationIcon() {
    return _isLoadingLocation 
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          )
        : IconButton(
            icon: Icon(
              MaterialCommunityIcons.crosshairs_gps,
              color: primaryColor,
            ),
            onPressed: _getCurrentLocation,
            tooltip: 'Use current location',
          );
  }

  Widget _buildDateTimeCard() {
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
                Icon(MaterialCommunityIcons.calendar_clock, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDateTimeRow(
              'Pickup Date',
              _selectedDate != null 
                  ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                  : 'Select date',
              MaterialCommunityIcons.calendar,
              () => _selectDate(context, false),
            ),
            if (_bookingType == 'roundTrip') ...[
              const SizedBox(height: 16),
              _buildDateTimeRow(
                'Return Date',
                _selectedReturnDate != null 
                    ? DateFormat('dd MMM yyyy').format(_selectedReturnDate!)
                    : 'Select return date',
                MaterialCommunityIcons.calendar,
                () => _selectDate(context, true),
              ),
            ],
            const SizedBox(height: 16),
            _buildDateTimeRow(
              'Pickup Time',
              _selectedTime != null 
                  ? _selectedTime!.format(context)
                  : 'Select time',
              MaterialCommunityIcons.clock_outline,
              () => _selectTime(context),
            ),
            if (_bookingType == 'rental') ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rental Duration (hours)',
                    style: TextStyle(
                      color: lightTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter duration in hours',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(
                        MaterialCommunityIcons.timer_outline,
                        color: primaryColor.withOpacity(0.7),
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _hours = value),
                    validator: (value) {
                      if (_bookingType == 'rental') {
                        if (value == null || value.isEmpty) {
                          return 'Please enter rental duration';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Please enter a valid duration';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: lightTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookNow() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    // Additional validation
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup time')),
      );
      return;
    }

    if (_bookingType == 'roundTrip' && _selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a return date')),
      );
      return;
    }

    // Create booking data
    final bookingData = {
      'pickup': _pickupController.text,
      'destination': _dropController.text,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'time': _selectedTime!.format(context),
      'bookingType': _bookingType,
      'hours': _hours,
      'returnDate': _selectedReturnDate != null 
          ? DateFormat('yyyy-MM-dd').format(_selectedReturnDate!)
          : '',
    };

    // Navigate to vehicle selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectVehicleScreen(bookingData: bookingData),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: _handleBookNow,
        child: const Text(
          'Continue to Select Vehicle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}