import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show cos, sqrt, asin, Random, pi, atan2, sin;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

// Professional color palette - matching the trips screen
const Color primaryColor = Color(0xFF4A90E2);      // Blue
const Color secondaryColor = Color(0xFF4A90E2);    // Blue
const Color accentColor = Color(0xFFFFCC00);       // Yellow/gold accent
const Color backgroundColor = Colors.white;
const Color textColor = Color(0xFF333333);         // Dark text
const Color lightTextColor = Color(0xFF666666);    // Medium gray text
const Color successColor = Color(0xFF4CAF50);      // Green for success states

class ETSUserTrackingScreen extends StatefulWidget {
  final String? etsId;
  final String? fromLocation;
  final String? toLocation;
  final String? userId;
  final String? driverId;
  final LatLng? pickupCoordinates;
  final LatLng? dropCoordinates;

  const ETSUserTrackingScreen({
    super.key, 
    this.etsId,
    this.fromLocation,
    this.toLocation,
    this.userId,
    this.driverId,
    this.pickupCoordinates,
    this.dropCoordinates,
  });

  @override
  State<ETSUserTrackingScreen> createState() => _ETSUserTrackingScreenState();
}

class _ETSUserTrackingScreenState extends State<ETSUserTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Trip ID
  late String _etsId;
  late String _userId;
  late String _driverId;
  
  // Markers for user, driver, pickup and drop locations
  final Set<Marker> _markers = {};
  
  // Polylines for route
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  
  // Current user location
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Custom marker icon
  BitmapDescriptor driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  BitmapDescriptor pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor dropIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  
  // Mock driver location (Pune)
  final LatLng _driverLocation = const LatLng(18.5204, 73.8567);
  
  // Mock pickup and drop locations
  LatLng _pickupLocation = const LatLng(18.5090, 73.8310); // Will be set to user's current location
  // Mumbai coordinates (Chhatrapati Shivaji Terminus)
  LatLng _dropLocation = const LatLng(18.9402, 72.8347);
  
  // Trip details
  final String _driverName = "Rahul Sharma";
  final String _driverPhone = "+91 9876543210";
  final String _vehicleNumber = "MH 12 AB 1234";
  final String _vehicleModel = "Toyota Innova";
  final String _estimatedArrival = "10 mins";
  final String _dropLocationName = "Mumbai CST, Mumbai";

  // OTP verification
  bool _rideStarted = false;
  String _otp = "";
  final TextEditingController _otpController = TextEditingController();
  LatLng _activeRouteEnd = const LatLng(18.5314, 73.8778); // Initially set to drop location
  
  @override
  void initState() {
    super.initState();
    // Initialize trip details
    _etsId = widget.etsId ?? 'ETS12345'; // Default ID if not provided
    _userId = widget.userId ?? 'User123';
    _driverId = widget.driverId ?? 'Driver123';
    
    // Set pickup and drop locations if provided
    if (widget.pickupCoordinates != null) {
      _pickupLocation = widget.pickupCoordinates!;
    }
    if (widget.dropCoordinates != null) {
      _dropLocation = widget.dropCoordinates!;
    }
    
    // Load custom car icon
    _loadCustomCarIcon();
    _determinePosition();
    // Generate 4-digit OTP
    _generateOTP();
  }
  
  // Load custom car icon for driver marker
  void _loadCustomCarIcon() {
    try {
      _createCarIcon().then((bitmapDescriptor) {
        if (mounted) {
          setState(() {
            driverIcon = bitmapDescriptor;
          });
        }
      });
    } catch (e) {
      print("Exception in loading car icon: $e");
      _createDefaultCarIcon();
    }
  }
  
  // Create a default car icon using BitmapDescriptor if image loading fails
  void _createDefaultCarIcon() {
    setState(() {
      // Yellow car-like marker
      driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    });
  }
  
  // Create a custom car icon using canvas
  Future<BitmapDescriptor> _createCarIcon() async {
    // Define canvas size
    const size = 120.0;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Draw the car shape
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    // Car body (rectangle with rounded corners)
    final bodyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 30, 100, 40),
        const Radius.circular(20),
      ));
    canvas.drawPath(bodyPath, paint);
    
    // Front window
    final Paint windowPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(45, 35, 20, 20),
      windowPaint,
    );
    
    // Rear window
    canvas.drawRect(
      Rect.fromLTWH(70, 35, 20, 20),
      windowPaint,
    );
    
    // Wheels
    final Paint wheelPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(30, 75), 15, wheelPaint);
    canvas.drawCircle(Offset(90, 75), 15, wheelPaint);
    
    // Wheel rims
    final Paint rimPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(30, 75), 8, rimPaint);
    canvas.drawCircle(Offset(90, 75), 8, rimPaint);
    
    // Headlights
    final Paint lightPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(10, 45), 5, lightPaint);
    canvas.drawCircle(Offset(110, 45), 5, lightPaint);
    
    // Convert canvas to image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    
    // Convert image to bytes
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception("Failed to convert image to bytes");
    }
    
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
  
  void _generateOTP() {
    // Generate a random 4-digit number for OTP
    Random random = Random();
    String otp = '';
    for (int i = 0; i < 4; i++) {
      otp += random.nextInt(10).toString();
    }
    _otp = otp;
    print("Generated OTP: $_otp"); // For testing purposes
  }
  
  @override
  void dispose() {
    _positionStream?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // Determine the current position and check permissions
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    } 
    
    // Get current position
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _pickupLocation = LatLng(position.latitude, position.longitude);
      
      // Create markers and polyline after setting pickup location
      _createMarkers();
      _getPolyline();
    });
    
    // Listen to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
        setState(() {
          _currentPosition = position;
          _updateUserMarker();
        });
      });
  }
  
  // Create all markers
  void _createMarkers() {
    // Clear existing markers
    _markers.clear();
    
    if (_rideStarted) {
      // Driver marker at pickup location when ride started
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _pickupLocation,
          icon: driverIcon,
          anchor: const Offset(0.5, 0.5), // Center the icon at the position
          infoWindow: const InfoWindow(
            title: 'Driver',
            snippet: 'Driver has arrived',
          ),
        ),
      );
      
      // Add drop marker with higher z-index for better visibility
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLocation,
          icon: dropIcon,
          zIndex: 2,
          infoWindow: const InfoWindow(
            title: 'Drop',
            snippet: 'Drop Location',
          ),
        ),
      );
    } else {
      // Driver marker with car icon (still approaching)
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation,
          icon: driverIcon,
          anchor: const Offset(0.5, 0.5), // Center the icon at the position
          rotation: _calculateBearing(_driverLocation, _pickupLocation), // Rotate car to face destination
          infoWindow: const InfoWindow(
            title: 'Driver',
            snippet: 'Driver Location',
          ),
        ),
      );
    
    // Pickup marker (user's current location)
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
          icon: pickupIcon,
        infoWindow: const InfoWindow(
          title: 'Pickup',
          snippet: 'Pickup Location',
        ),
      ),
    );
    
      // Drop marker with lower opacity before ride starts
    _markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: _dropLocation,
          icon: dropIcon,
          alpha: 0.7,
        infoWindow: const InfoWindow(
          title: 'Drop',
          snippet: 'Drop Location',
        ),
      ),
    );
    }
  }
  
  // Update user marker as location changes
  void _updateUserMarker() {
    if (_currentPosition != null) {
      _markers.removeWhere((marker) => marker.markerId.value == 'user');
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Your Location',
          ),
        ),
      );
      
      // If ride started and driver's position needs updating (to show movement)
      if (_rideStarted) {
        // In a real app, this would be updated from server/driver locations
        // For demo, just keep the driver at pickup
        _updateDriverPosition();
      }
    }
  }
  
  // Get polyline between pickup and drop locations
  void _getPolyline() async {
    // Determine start and end points based on ride status
    final LatLng startPoint = _rideStarted ? _pickupLocation : _driverLocation;
    final LatLng endPoint = _rideStarted ? _dropLocation : _pickupLocation;
    
    _activeRouteEnd = endPoint; // Store active destination
    
    // Use direct API call to Google Directions
    final String originStr = "${startPoint.latitude},${startPoint.longitude}";
    final String destStr = "${endPoint.latitude},${endPoint.longitude}";
    
    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originStr'
        '&destination=$destStr'
        '&key=$googleMapsApiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Extract encoded polyline from response
          final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          
          // Decode the polyline
          polylineCoordinates = _decodePolyline(encodedPolyline);
          
          // Create polyline from coordinates
          setState(() {
            _polylines.clear(); // Clear existing polylines
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: primaryColor,
                points: polylineCoordinates,
                width: 5,
              ),
            );
          });
        } else {
          // If no route found, create direct line
          polylineCoordinates = [startPoint, endPoint];
          
          setState(() {
            _polylines.clear(); // Clear existing polylines
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: primaryColor,
                points: polylineCoordinates,
                width: 5,
              ),
            );
          });
        }
      } else {
        // API error, fallback to direct line
        polylineCoordinates = [startPoint, endPoint];
        
        setState(() {
          _polylines.clear(); // Clear existing polylines
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: primaryColor,
              points: polylineCoordinates,
              width: 5,
            ),
          );
        });
      }
    } catch (e) {
      print("Error fetching directions: $e");
      // Error, fallback to direct line
      polylineCoordinates = [startPoint, endPoint];
      
      setState(() {
        _polylines.clear(); // Clear existing polylines
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: primaryColor,
            points: polylineCoordinates,
            width: 5,
          ),
        );
      });
    }
    
    // Update camera to focus on the new route
    _updateCameraForRoute();
  }
  
  // Update camera position to focus on current route
  Future<void> _updateCameraForRoute() async {
    if (!_controller.isCompleted) return;
    
    final GoogleMapController controller = await _controller.future;
    
    // Create a list of important positions to include
    List<LatLng> positions = _rideStarted 
      ? [_pickupLocation, _dropLocation] 
      : [_driverLocation, _pickupLocation];
    
    // Calculate bounds
    double minLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    
    // Add padding proportional to the distance
    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;
    
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;
    
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }
  
  // Helper method to decode encoded polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      double latDouble = lat / 1e5;
      double lngDouble = lng / 1e5;
      points.add(LatLng(latDouble, lngDouble));
    }
    
    return points;
  }
  
  // Animate camera to current user location
  Future<void> _animateToUser() async {
    if (_currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }
  
  // Calculate distance between two coordinates
  double _calculateDistance(LatLng start, LatLng end) {
    const double p = 0.017453292519943295; // Math.PI / 180
    double a = 0.5 - cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) * cos(end.latitude * p) *
            (1 - cos((end.longitude - start.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
  
  // Go to overview mode showing all markers
  Future<void> _goToOverview() async {
    final GoogleMapController controller = await _controller.future;
    
    // Create a list of positions to include
    List<LatLng> positions = _rideStarted
        ? [_pickupLocation, _dropLocation] // During ride, focus on route
        : [_pickupLocation, _dropLocation, _driverLocation]; // Before ride, include driver
    
    if (_currentPosition != null) {
      positions.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    
    // Calculate bounds
    double minLat = positions.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = positions.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = positions.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = positions.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    
    // Add padding
    minLat -= 0.02;
    maxLat += 0.02;
    minLng -= 0.02;
    maxLng += 0.02;
    
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }

  // OTP verification dialog
  void _showOTPDialog() {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, color: primaryColor),
              SizedBox(width: 10),
              const Text('Enter OTP', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter the 4-digit OTP to start your ride',
                style: TextStyle(fontSize: 14, color: lightTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'OTP: $_otp',
                  style: const TextStyle(
                    color: primaryColor, 
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Increased font size
                    letterSpacing: 2, // Added letter spacing for better readability
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                maxLength: 4,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'XXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking ID: $_etsId',
                style: const TextStyle(
                  color: textColor, 
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL', style: TextStyle(color: textColor)),
            ),
            ElevatedButton(
              onPressed: () {
                // Accept any OTP input
                if (_otpController.text.length == 4) {
                  Navigator.pop(context);
                  _startRide();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a 4-digit OTP'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        );
      },
    );
  }
  
  // Start the ride after OTP verification
  void _startRide() {
                  setState(() {
                    _rideStarted = true;
                  });
    
    // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP verified successfully. Ride started!'),
                      backgroundColor: successColor,
                    ),
                  );
    
    // Create markers with updated state
    _createMarkers();
    
    // Update the route to show from pickup to drop
    _getPolyline();
    
    // Move the driver to pickup location
    _updateDriverPosition();
    
    // Focus camera on the route to drop location
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateCameraForRoute();
    });
  }
  
  // Update driver position from current location to pickup location
  void _updateDriverPosition() {
    // Remove old driver marker
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    
    // Add new driver marker at pickup location
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: _pickupLocation, // Driver has arrived at pickup
        icon: driverIcon,
        infoWindow: const InfoWindow(
          title: 'Driver',
          snippet: 'Driver has arrived',
        ),
                    ),
                  );
                }

  // Action buttons in the bottom panel
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Show call dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Call Driver'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Do you want to call $_driverName at $_driverPhone?'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: textColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Driver ID: $_driverId',
                                  style: const TextStyle(fontSize: 12, color: textColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('CALL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text(
                'Call Driver',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (!_rideStarted)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showOTPDialog,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text(
                  'Enter OTP',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // In a real app, this would confirm arrival at destination
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have arrived at your destination!'),
                      backgroundColor: successColor,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Arrived',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Pickup and drop details
  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Icon(
                    _rideStarted ? Icons.check_circle : Icons.circle, 
                    size: 12, 
                    color: _rideStarted ? successColor : primaryColor
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[300],
                  ),
                  Icon(Icons.location_on, size: 14, color: Colors.red[400]),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rideStarted ? 'Starting Point' : 'Pickup Location',
                      style: const TextStyle(
                        fontSize: 14,
                        color: lightTextColor,
                      ),
                    ),
                    Text(
                      widget.fromLocation ?? (_rideStarted ? 'Pickup Completed' : 'Your Current Location'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _rideStarted ? successColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Drop Location',
                          style: TextStyle(
                            fontSize: 14,
                            color: lightTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_rideStarted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.navigation, size: 12, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Navigating',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          widget.toLocation ?? _dropLocationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_rideStarted) 
                          const SizedBox(width: 8),
                        if (_rideStarted)
                          Text(
                            '(${_dropLocation.latitude.toStringAsFixed(4)}, ${_dropLocation.longitude.toStringAsFixed(4)})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trip Tracking',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ID: $_etsId',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(204),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _pickupLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    _updateCameraForRoute(); // Use the new function for better camera control
                  },
                ),
          
          // Trip information panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Driver details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 30, color: primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _vehicleModel,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _rideStarted 
                                    ? successColor.withAlpha(26)
                                    : Colors.orange.withAlpha(26),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _rideStarted ? Icons.directions_car : Icons.access_time,
                                    size: 16,
                                    color: _rideStarted ? successColor : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _rideStarted ? "In progress" : "Waiting",
                                    style: TextStyle(
                                      color: _rideStarted ? successColor : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn(
                              'Vehicle Number',
                              _vehicleNumber,
                              Icons.directions_car,
                            ),
                            _buildInfoColumn(
                              'ETA',
                              _rideStarted ? '2.5 hrs to drop' : _estimatedArrival,
                              Icons.access_time,
                            ),
                            _buildInfoColumn(
                              'Total Distance',
                              '${_calculateDistance(_rideStarted ? _pickupLocation : _driverLocation, 
                                                 _rideStarted ? _dropLocation : _pickupLocation).toStringAsFixed(1)} km',
                              Icons.route,
                              coordinates: _rideStarted ? _dropLocation : _pickupLocation,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Pickup and drop details
                  _buildLocationDetails(),
                  
                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _animateToUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }
  
  Widget _buildInfoColumn(String title, String value, IconData icon, {LatLng? coordinates}) {
    return InkWell(
      onTap: coordinates == null ? null : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coordinates: (${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)})'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Column(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      ),
    );
  }

  // Calculate bearing between two points to rotate car icon
  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * pi / 180;
    double startLng = start.longitude * pi / 180;
    double endLat = end.latitude * pi / 180;
    double endLng = end.longitude * pi / 180;
    
    double dLng = endLng - startLng;
    
    double y = sin(dLng) * cos(endLat);
    double x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
    
    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;
    
    return bearing;
  }
}
