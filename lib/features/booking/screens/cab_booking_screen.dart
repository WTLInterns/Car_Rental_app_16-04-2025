import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_constants.dart';
import '../blocs/booking_bloc.dart';
import '../blocs/booking_event.dart';
import '../blocs/booking_state.dart';
import 'select_vehicle_screen.dart';
import 'user_home_screen.dart';

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

class CabBookingScreen extends StatefulWidget {
  final String? initialDropLocation;

  const CabBookingScreen({super.key, this.initialDropLocation});

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
  String _selectedPackage = '';
  LocationData? _currentLocation;

  List<dynamic> _pickupSuggestions = [];
  List<dynamic> _dropSuggestions = [];
  bool _isLoadingLocation = false;
  String? _pickupPlaceId; // To store pickup place ID
  String? _dropPlaceId;   // To store drop place ID
  double? _distanceInKm;  // To store calculated distance in kilometers

  // Color scheme for consistent styling
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
  final Color pickupIconColor = const Color(0xFF3057E3);
  final Color dropIconColor = const Color(0xFFFF5B5B);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Set default date and time
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();

    // Set drop location if provided from home screen
    if (widget.initialDropLocation != null &&
        widget.initialDropLocation!.isNotEmpty) {
      _dropController.text = widget.initialDropLocation!;
    }

    // Add listeners to text controllers to update UI when text changes
    _pickupController.addListener(() {
      setState(() {});
    });
    _dropController.addListener(() {
      setState(() {});
    });
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
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?'
              'latlng=${location.latitude},${location.longitude}&key=$googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            _pickupController.text = data['results'][0]['formatted_address'];
            _pickupPlaceId = data['results'][0]['place_id'];
            if (_dropPlaceId != null) {
              _calculateDistance();
            }
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
    if (query.isEmpty) {
      setState(() {
        if (type == 'pickup') {
          _pickupSuggestions = [];
          _pickupPlaceId = null;
        } else {
          _dropSuggestions = [];
          _dropPlaceId = null;
        }
        _distanceInKm = null;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
              'input=$query&key=$googleMapsApiKey&components=country:in',
        ),
      );

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

  Future<void> _calculateDistance() async {
    if (_pickupPlaceId == null || _dropPlaceId == null) {
      setState(() => _distanceInKm = null);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json?'
              'origins=place_id:$_pickupPlaceId&destinations=place_id:$_dropPlaceId'
              '&key=$googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rows'].isNotEmpty &&
            data['rows'][0]['elements'].isNotEmpty &&
            data['rows'][0]['elements'][0]['status'] == 'OK') {
          final distance = data['rows'][0]['elements'][0]['distance']['value'];
          setState(() {
            _distanceInKm = distance / 1000.0;
          });
        } else {
          setState(() => _distanceInKm = null);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Could not calculate distance')),
          // );
        }
      }
    } catch (e) {
      setState(() => _distanceInKm = null);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error calculating distance: $e')),
      // );
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
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
              surface: surfaceColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: cardColor,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodBorderSide:
              BorderSide(color: secondaryColor.withOpacity(0.2)),
              dayPeriodColor: surfaceColor,
              dayPeriodTextColor: primaryColor,
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hourMinuteColor: surfaceColor,
              hourMinuteTextColor: primaryColor,
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
        title: const Padding(
          padding: EdgeInsets.only(left: 70),
          child: Text(
            'Booking',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Type
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Trip Type",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildTripTypeButton(
                              'One Way',
                              Icons.arrow_forward,
                              'oneWay',
                            ),
                            const SizedBox(width: 12),
                            _buildTripTypeButton(
                              'Round Trip',
                              Icons.sync,
                              'roundTrip',
                            ),
                            const SizedBox(width: 12),
                            _buildTripTypeButton(
                              'Rental',
                              Icons.car_rental,
                              'rental',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Pickup & Drop
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pickup & Drop",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_bookingType == 'rental') ...[
                          Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Select Package",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedPackage.isNotEmpty
                                              ? _selectedPackage
                                              : null,
                                          hint: const Text("Choose a Package..."),
                                          isExpanded: true,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: "4hrs/40Km",
                                              child: Text(
                                                "4hrs/40Km - Perfect for city tours",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "8hrs/80Km",
                                              child: Text(
                                                "8hrs/80Km - Ideal for outstation trips",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedPackage = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 32,
                            thickness: 1,
                            color: Colors.grey[200],
                          ),
                        ],
                        // Pickup location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Icon(
                                  Icons.circle,
                                  color: pickupIconColor,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pickup",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Stack(
                                    alignment: Alignment.centerRight,
                                    children: [
                                      TextFormField(
                                        controller: _pickupController,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "  Enter pickup location",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300)),
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 12),
                                          suffixIcon: _pickupController
                                              .text.isNotEmpty
                                              ? const SizedBox(width: 80)
                                              : _isLoadingLocation
                                              ? const SizedBox(width: 40)
                                              : const SizedBox(width: 40),
                                        ),
                                        onChanged: (value) =>
                                            _searchPlaces(value, 'pickup'),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_pickupController.text.isNotEmpty)
                                            IconButton(
                                              icon: Icon(Icons.clear,
                                                  size: 18,
                                                  color: Colors.grey[400]),
                                              onPressed: () {
                                                _pickupController.clear();
                                                _pickupPlaceId = null;
                                                _searchPlaces('', 'pickup');
                                                setState(() =>
                                                _distanceInKm = null);
                                              },
                                              constraints: const BoxConstraints(
                                                  maxWidth: 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                          _isLoadingLocation
                                              ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                                  secondaryColor),
                                            ),
                                          )
                                              : IconButton(
                                            icon: Icon(
                                              Icons.my_location,
                                              color: pickupIconColor,
                                              size: 22,
                                            ),
                                            onPressed: _getCurrentLocation,
                                            tooltip: 'Use current location',
                                            constraints:
                                            const BoxConstraints(
                                                maxWidth: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (_pickupSuggestions.isNotEmpty)
                                    _buildSuggestionsList(
                                        _pickupSuggestions,
                                        _pickupController,
                                        'pickup'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(
                            height: 32,
                            thickness: 1,
                            color: Colors.grey[200]),
                        // Drop location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Icon(
                                  Icons.location_on,
                                  color: dropIconColor,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Drop",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Stack(
                                    alignment: Alignment.centerRight,
                                    children: [
                                      TextFormField(
                                        controller: _dropController,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Enter drop location",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300)),
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 12),
                                          suffixIcon:
                                          _dropController.text.isNotEmpty
                                              ? const SizedBox(width: 40)
                                              : null,
                                        ),
                                        onChanged: (value) =>
                                            _searchPlaces(value, 'drop'),
                                      ),
                                      if (_dropController.text.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.clear,
                                              size: 18,
                                              color: Colors.grey[400]),
                                          onPressed: () {
                                            _dropController.clear();
                                            _dropPlaceId = null;
                                            _searchPlaces('', 'drop');
                                            setState(() => _distanceInKm = null);
                                          },
                                          constraints: const BoxConstraints(
                                              maxWidth: 32),
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                  if (_dropSuggestions.isNotEmpty)
                                    _buildSuggestionsList(
                                        _dropSuggestions,
                                        _dropController,
                                        'drop'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Date & Time
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date & Time",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Date",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _selectDate(context, false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.transparent,
                                      ),
                                      child: Text(
                                        _selectedDate != null
                                            ? DateFormat('dd MMM yyyy')
                                            .format(_selectedDate!)
                                            : "Select date",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedDate != null
                                              ? textColor
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 12,
                          thickness: 1,
                          color: Colors.grey[400],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.access_time,
                                color: Colors.purple[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Time",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _selectTime(context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.transparent,
                                      ),
                                      child: Text(
                                        _selectedTime != null
                                            ? _selectedTime!.format(context)
                                            : "Select time",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedTime != null
                                              ? textColor
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_bookingType == 'roundTrip') ...[
                          Divider(
                              height: 32,
                              thickness: 1,
                              color: Colors.grey[200]),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.calendar_today,
                                    color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Return Date",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _selectDate(context, true),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(
                                          _selectedReturnDate != null
                                              ? DateFormat('dd MMM yyyy')
                                              .format(_selectedReturnDate!)
                                              : "Select return date",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedReturnDate != null
                                                ? textColor
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Book Now Button
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
                    onPressed: _handleBookNow,
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeButton(String label, IconData icon, String type) {
    final isSelected = _bookingType == type;

    IconData iconToUse = icon;
    if (type == 'oneWay') {
      iconToUse = Icons.arrow_forward;
    } else if (type == 'roundTrip') {
      iconToUse = Icons.sync;
    } else if (type == 'rental') {
      iconToUse = Icons.car_rental;
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _bookingType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (Colors.grey[100]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  iconToUse,
                  color: isSelected
                      ? Colors.white
                      : (primaryColor),
                  size: 14,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (Colors.grey[800]),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(
      List<dynamic> suggestions,
      TextEditingController controller,
      String type,
      ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              controller.text = suggestions[index]['description'];
              setState(() {
                if (type == 'pickup') {
                  _pickupSuggestions = [];
                  _pickupPlaceId = suggestions[index]['place_id'];
                } else {
                  _dropSuggestions = [];
                  _dropPlaceId = suggestions[index]['place_id'];
                }
              });
              if (_pickupPlaceId != null && _dropPlaceId != null) {
                await _calculateDistance();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    MaterialCommunityIcons.map_marker_outline,
                    color: secondaryColor,
                    size: 16,
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
    );
  }

  void _handleBookNow() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );
      return;
    }

    if (_pickupController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup location')),
      );
      return;
    }
    if (_dropController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter drop location')),
      );
      return;
    }
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
    if (_bookingType == 'rental' && _selectedPackage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Choose a Package')),
      );
      return;
    }

    if (_bookingType == 'rental' &&
        _selectedPackage == '4hrs/40Km' && _distanceInKm! > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Choose a drop location under 40 km')),
      );
      return;
    }

    final bookingData = {
      'pickup': _pickupController.text,
      'destination': _dropController.text,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'time': _selectedTime!.format(context),
      'bookingType': _bookingType,
      'selectedPackage': _selectedPackage,
      'returnDate': _selectedReturnDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedReturnDate!)
          : '',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectVehicleScreen(bookingData: bookingData),
      ),
    );
  }
}