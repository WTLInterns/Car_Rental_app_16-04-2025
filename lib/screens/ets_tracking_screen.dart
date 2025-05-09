import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Use the same Google Maps API key as in other screens
const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

// Define LocationCluster class at the top level
class LocationCluster {
  final LatLng center;
  final List<int> passengerIndices;
  final double radius;
  final bool isPickup; // true for pickup cluster, false for drop cluster

  LocationCluster(this.center, this.passengerIndices, this.radius, this.isPickup);
}

class ETSTrackingScreen extends StatefulWidget {
  const ETSTrackingScreen({super.key});

  @override
  State<ETSTrackingScreen> createState() => _ETSTrackingScreenState();
}

class _ETSTrackingScreenState extends State<ETSTrackingScreen> {
  // Controllers and references
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _passengerCountController = TextEditingController();
  final List<TextEditingController> _userIdControllers = [];
  final List<TextEditingController> _pickupControllers = [];
  final List<TextEditingController> _dropControllers = [];
  final TextEditingController _otpController = TextEditingController();

  // Location and map state
  final Location _location = Location();
  LatLng? _userLocation;
  CameraPosition? _initialCameraPosition;

  // Map markers and routes
  Set<Marker> _markers = {};
  Map<String, Polyline> _routes = {}; // Add this for routes
  Map<String, Map<String, dynamic>> _routeInfo = {}; // Add this for route info

  // UI state
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String _locationError = "";
  bool _isMapInitialized = false;
  bool _showPassengerForm = true;
  bool _showPassengerDetails = false;
  bool _tripStarted = false;
  bool _showOtpVerification = false;
  int _passengerCount = 0;
  String _generatedOtp = "";
  bool _isVerifyingOtp = false;
  bool _otpVerified = false;
  
  // Nearby locations and users
  List<Map<String, dynamic>> _nearbyLocations = [];
  List<Map<String, dynamic>> _nearbyUsers = [];
  
  // Autocomplete results
  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _dropSuggestions = [];
  int _activeSuggestionField = -1; // -1: none, 0-n: index of passenger
  bool _showPickupSuggestions = false;
  bool _showDropSuggestions = false;

  // Professional color palette - matching other screens
  final Color primaryColor = const Color(0xFF4A90E2); // Blue
  final Color backgroundColor = Colors.white;
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF333333);
  final Color accentColor = const Color(0xFFFFCC00); // Yellow/gold accent
  final Color successColor = const Color(0xFF4CAF50); // Green

  // Add these new variables in the _ETSTrackingScreenState class
  final List<Color> _userColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  int _currentPickupIndex = 0;
  bool _isNavigating = false;
  Timer? _locationUpdateTimer;
  final TextEditingController _otpInputController = TextEditingController();
  bool _showOtpDialog = false;

  // Add these new state variables in the _ETSTrackingScreenState class
  bool _isPickingUp = true; // true for pickup, false for drop
  Map<int, bool> _passengerInCar = {}; // Track which passengers are in car
  Map<int, bool> _passengerDropped = {}; // Track which passengers are dropped
  Map<int, String> _passengerStatus = {}; // Track status for each passenger

  // Add these new state variables
  List<int> _pickupSequence = []; // Store optimal pickup sequence
  Map<int, double> _pickupDistances = {}; // Store distances to pickups
  bool _isFirstPickup = true; // Track if this is the first pickup

  // Add these new variables to track route optimization
  Map<int, double> _dropDistances = {}; // Store distances to drop points
  List<int> _optimizedSequence = []; // Store optimized pickup-drop sequence
  bool _isOptimizingRoute = false;

  // Add these variables to your state class
  List<LocationCluster> _pickupClusters = [];
  List<LocationCluster> _dropClusters = [];
  Map<int, int> _passengerToPickupClusterMap = {};
  Map<int, int> _passengerToDropClusterMap = {};
  Set<Circle> _clusterCircles = {};

  // Traffic factors for different times of day
  double _getTrafficFactor() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Rush hours: 7-9 AM and 5-7 PM typically have high traffic
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
      return 0.7; // 70% slower during rush hour
    } 
    // Mid-day has moderate traffic
    else if (hour >= 10 && hour <= 16) {
      return 0.3; // 30% slower during mid-day
    } 
    // Late night/early morning has least traffic
    else {
      return 0.1; // 10% slower during off-hours
    }
  }

  // Traffic-aware route calculation
  Future<void> _getTrafficAwareRoute(LatLng origin, LatLng destination, String routeId) async {
    try {
      // Format coordinates for API request
      final String originStr = "${origin.latitude},${origin.longitude}";
      final String destStr = "${destination.latitude},${destination.longitude}";
      
      // Make API request to Google Directions API with traffic model
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr'
          '&destination=$destStr'
          '&key=$googleMapsApiKey'
          '&departure_time=now' // Use current time for traffic calculation
          '&traffic_model=best_guess' // Use Google's best guess for traffic
        )
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Extract route information
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Extract polyline points
          final String encodedPolyline = route['overview_polyline']['points'];
          final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);
          
          // Extract distance and duration (with traffic)
          final distance = leg['distance']['text'];
          final duration = leg['duration_in_traffic'] != null 
              ? leg['duration_in_traffic']['text'] 
              : leg['duration']['text'];
          final distanceValue = leg['distance']['value']; // in meters
          final durationValue = leg['duration_in_traffic'] != null 
              ? leg['duration_in_traffic']['value'] 
              : leg['duration']['value']; // in seconds
          
          // Create a polyline with traffic aware color
          final Color trafficColor = _getTrafficColor(durationValue, distanceValue);
          
          final Polyline polyline = Polyline(
            polylineId: PolylineId(routeId),
            points: polylinePoints,
            color: trafficColor,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line
          );
          
          // Store route information
          setState(() {
            _routes[routeId] = polyline;
            _routeInfo[routeId] = {
              'distance': distance,
              'duration': duration,
              'distanceValue': distanceValue,
              'durationValue': durationValue,
              'hasTraffic': true,
            };
          });
          
          // Update the map to show the route
          final controller = await _mapController.future;
          
          // Calculate bounds to show both origin and destination
          final LatLngBounds bounds = _calculateBounds([origin, destination, ...polylinePoints]);
          
          // Animate camera to show the entire route
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
          );
          
          return;
        }
      }
      
      // Fall back to regular routing if traffic-aware fails
      _getDirectionsAndDrawRoute(origin, destination, routeId);
      
    } catch (e) {
      debugPrint('Error getting traffic-aware directions: $e');
      // Fall back to regular routing
      _getDirectionsAndDrawRoute(origin, destination, routeId);
    }
  }
  
  // Get color based on traffic conditions
  Color _getTrafficColor(int durationValue, int distanceValue) {
    // Calculate average speed in km/h
    final double avgSpeedKmh = (distanceValue / 1000) / (durationValue / 3600);
    
    // Determine color based on average speed
    if (avgSpeedKmh < 20) {
      return Colors.red; // Heavy traffic - slow speed
    } else if (avgSpeedKmh < 40) {
      return Colors.orange; // Moderate traffic
    } else if (avgSpeedKmh < 60) {
      return Colors.yellow; // Light traffic
    } else {
      return Colors.green; // Free flowing traffic
    }
  }
  
  // Add this variable to your state class at the top
  bool _useTrafficAwareRouting = false;
  
  // Add this to your UI code in build method, just above the trip progress card
  Widget _buildTrafficToggle() {
    return Positioned(
      bottom: (_tripStarted && _routes.isNotEmpty) ? 230 : 80,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.traffic,
                color: _useTrafficAwareRouting ? primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Switch(
                value: _useTrafficAwareRouting,
                activeColor: primaryColor,
                onChanged: (value) {
                  setState(() {
                    _useTrafficAwareRouting = value;
                  });
                  
                  if (value && _userLocation != null) {
                    // Re-calculate current route with traffic awareness
                    if (_isPickingUp && _pickupSequence.isNotEmpty) {
                      _showNearestPickupRoute();
                    } else if (!_isPickingUp) {
                      final dropMarker = _markers.firstWhere(
                        (m) => m.markerId.value == 'drop_$_currentPickupIndex',
                        orElse: () => Marker(markerId: MarkerId('dummy')),
                      );
                      
                      if (dropMarker.markerId.value != 'dummy') {
                        _getTrafficAwareRoute(
                          _userLocation!,
                          dropMarker.position,
                          'route_to_drop_$_currentPickupIndex',
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      debugPrint('📍 Initializing location services');
      await _requestLocationPermission();

      if (_hasLocationPermission) {
        debugPrint('✅ Location permission granted, getting current location');
        final locationData = await _location.getLocation();
        final lat = locationData.latitude;
        final lng = locationData.longitude;

        debugPrint('📍 User location: lat=$lat, lng=$lng');

        setState(() {
          _userLocation = LatLng(lat!, lng!);
          
          // Set initial camera position based on user's actual location
          _initialCameraPosition = CameraPosition(
            target: _userLocation!,
            zoom: 16.0, // Higher zoom for better visibility
          );
          _isLoading = false;
        });

        // Setup continuous location updates
        _setupLocationUpdates();
        
        // Generate sample nearby locations
        _generateNearbyLocations();
        
        // Generate sample nearby users
        _generateNearbyUsers();
      } else {
        debugPrint('❌ Location permission denied');
        setState(() {
          _locationError = 'Location permission is required to track your position';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing location: $e');
      setState(() {
        _locationError = 'Could not access location: $e';
        _isLoading = false;
      });
    }
  }

// Fetch directions and draw route between two points
Future<void> _getDirectionsAndDrawRoute(LatLng origin, LatLng destination, String routeId) async {
  try {
    // Format coordinates for API request
    final String originStr = "${origin.latitude},${origin.longitude}";
    final String destStr = "${destination.latitude},${destination.longitude}";
    
    // Make API request to Google Directions API
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&key=$googleMapsApiKey'
      )
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        // Extract route information
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final steps = leg['steps'];
        
        // Extract polyline points
        final String encodedPolyline = route['overview_polyline']['points'];
        final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);
        
        // Extract distance and duration
        final distance = leg['distance']['text'];
        final duration = leg['duration']['text'];
        final distanceValue = leg['distance']['value']; // in meters
        final durationValue = leg['duration']['value']; // in seconds
        
        // Create a polyline
        final Polyline polyline = Polyline(
          polylineId: PolylineId(routeId),
          points: polylinePoints,
          color: primaryColor,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line
        );
        
        // Store route information
        setState(() {
          _routes[routeId] = polyline;
          _routeInfo[routeId] = {
            'distance': distance,
            'duration': duration,
            'distanceValue': distanceValue,
            'durationValue': durationValue,
          };
        });
        
        // Update the map to show the route
        final controller = await _mapController.future;
        
        // Calculate bounds to show both origin and destination
        final LatLngBounds bounds = _calculateBounds([origin, destination, ...polylinePoints]);
        
        // Animate camera to show the entire route
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
        );
        
        return;
      }
    }
    
    debugPrint('Error getting directions: ${response.statusCode}');
  } catch (e) {
    debugPrint('Error getting directions: $e');
  }
}

// Helper method to decode encoded polyline points
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

// Helper method to calculate bounds for a list of LatLng points
LatLngBounds _calculateBounds(List<LatLng> points) {
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;
  
  for (var point in points) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }
  
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

void _updateRoutes() {
  if (_userLocation == null) return;
  
  // Update routes to all pickup locations
  for (int i = 0; i < _passengerCount; i++) {
    // Find the marker for this pickup
    final pickupMarkerId = 'pickup_$i';
    final pickupMarker = _markers.firstWhere(
      (m) => m.markerId.value == pickupMarkerId,
      orElse: () => Marker(markerId: MarkerId('dummy')),
    );
    
    if (pickupMarker.markerId.value != 'dummy') {
      _getDirectionsAndDrawRoute(
        _userLocation!,
        pickupMarker.position,
        'route_to_pickup_$i',
      );
    }
  }
}

void _generateNearbyUsers() {
    if (_userLocation == null) return;
    
    // In a real app, this would be an API call to get nearby users
    // For demo purposes, we're creating sample data
    _nearbyUsers = [
      {
        'id': 'USR001',
        'name': 'John D.',
        'distance': 1.2,
        'location': _getNearbyRandomLocation(_userLocation!, 1200),
      },
      {
        'id': 'USR002',
        'name': 'Sarah M.',
        'distance': 0.8,
        'location': _getNearbyRandomLocation(_userLocation!, 800),
      },
      {
        'id': 'USR003',
        'name': 'Robert K.',
        'distance': 1.5,
        'location': _getNearbyRandomLocation(_userLocation!, 1500),
      },
      {
        'id': 'USR004',
        'name': 'Emily T.',
        'distance': 0.5,
        'location': _getNearbyRandomLocation(_userLocation!, 500),
      },
    ];
  }
  
  Future<void> _getPlaceSuggestions(String input, bool isPickup, int passengerIndex) async {
  if (input.length < 3) {
    setState(() {
      if (isPickup) {
        _showPickupSuggestions = false;
      } else {
        _showDropSuggestions = false;
      }
    });
    return;
  }
  
  try {
    // Make actual API call to Google Places API
    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleMapsApiKey&sessiontoken=${DateTime.now().millisecondsSinceEpoch}'
        '&components=country:in'; // Restrict to India, change as needed
    
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    
    if (data['status'] == 'OK') {
      final List<Map<String, dynamic>> suggestions = [];
      
      for (var prediction in data['predictions']) {
        suggestions.add({
          'place_id': prediction['place_id'],
          'description': prediction['description'],
        });
      }
      
      setState(() {
        if (isPickup) {
          _pickupSuggestions = suggestions;
          _showPickupSuggestions = true;
          _showDropSuggestions = false;
        } else {
          _dropSuggestions = suggestions;
          _showDropSuggestions = true;
          _showPickupSuggestions = false;
        }
      });
    } else {
      debugPrint('Error getting place suggestions: ${data['status']}');
    }
  } catch (e) {
    debugPrint('Error getting place suggestions: $e');
  }
}

// Handle place selection from suggestions
void _handlePlaceSelection(Map<String, dynamic> place, bool isPickup, int passengerIndex) async {
  try {
    // Get place details to get coordinates
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${place['place_id']}&fields=geometry&key=$googleMapsApiKey';
    
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    
    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];
      
      // Create a marker for this location
      final LatLng placeLocation = LatLng(lat, lng);
      
      setState(() {
        if (isPickup) {
          _pickupControllers[passengerIndex].text = place['description'];
          _showPickupSuggestions = false;
          
          // Store the actual location for this pickup
          if (_markers.any((m) => m.markerId.value == 'pickup_$passengerIndex')) {
            _markers.removeWhere((m) => m.markerId.value == 'pickup_$passengerIndex');
          }
          
          _markers.add(
            Marker(
              markerId: MarkerId('pickup_$passengerIndex'),
              position: placeLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: 'Pickup ${passengerIndex+1}', snippet: place['description']),
            ),
          );
          
          // Draw route from user location to pickup location
          if (_userLocation != null) {
            _getDirectionsAndDrawRoute(
              _userLocation!, 
              placeLocation, 
              'route_to_pickup_$passengerIndex'
            );
          }
        } else {
          _dropControllers[passengerIndex].text = place['description'];
          _showDropSuggestions = false;
          
          // Store the actual location for this drop
          if (_markers.any((m) => m.markerId.value == 'drop_$passengerIndex')) {
            _markers.removeWhere((m) => m.markerId.value == 'drop_$passengerIndex');
          }
          
          _markers.add(
            Marker(
              markerId: MarkerId('drop_$passengerIndex'),
              position: placeLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: 'Drop ${passengerIndex+1}', snippet: place['description']),
            ),
          );
        }
      });
    } else {
      debugPrint('Error getting place details: ${data['status']}');
    }
  } catch (e) {
    debugPrint('Error handling place selection: $e');
  }
  }

  // Verify OTP entered by driver
  void _verifyOtp() {
    final enteredOtp = _otpController.text.trim();
    
    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }
    
    setState(() {
      _isVerifyingOtp = true;
    });
    
    // In a real app, you would verify this with your backend
    // For demo purposes, we'll simulate verification
    Future.delayed(const Duration(seconds: 1), () {
      // Generate a random OTP for demo if not already generated
      if (_generatedOtp.isEmpty) {
        _generatedOtp = (1000 + Random().nextInt(9000)).toString();
      }
      
      final bool isValid = enteredOtp == _generatedOtp;
      
      setState(() {
        _isVerifyingOtp = false;
        _otpVerified = isValid;
        
        if (isValid) {
          _showOtpVerification = false;
          _tripStarted = true;
          _updateMapMarkers();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP verified successfully! Trip started.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
      });
    });
  }

  Future<void> _requestLocationPermission() async {
    debugPrint('🔐 Requesting location permission');
    final status = await Permission.location.request();
    final isGranted = status.isGranted;

    debugPrint('📱 Location permission status: $status (granted: $isGranted)');
    setState(() => _hasLocationPermission = isGranted);

    if (!isGranted) {
      setState(() => _locationError = 'Location permission denied');
    }
  }

 void _setupLocationUpdates() {
  debugPrint('🔄 Setting up continuous location updates');
  _location.onLocationChanged.listen((locationData) {
    if (!mounted) return;

    final lat = locationData.latitude;
    final lng = locationData.longitude;

    // Only update for significant changes to reduce unnecessary updates
    if (_userLocation == null ||
        (_calculateDistance(_userLocation!.latitude, _userLocation!.longitude,
                lat!, lng!) >
            10)) {
      // More than 10 meters change
      setState(() {
        _userLocation = LatLng(lat!, lng!);
        _updateMapMarkers();
      });

      // Update camera position if map is initialized
      if (_isMapInitialized) {
        _updateCamera();
      }
      
      // Update routes when location changes significantly
      if (_tripStarted) {
        _updateRoutes();
      }
    }
  });
}
  
  // Calculate distance between two coordinates in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

 void _updateMapMarkers() {
  if (!mounted) return;

  Set<Marker> markers = {};
  debugPrint('🗺️ Updating map markers');

  // Add user marker
  if (_userLocation != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
    debugPrint(
      '📍 Added user marker at: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
    );
  }
  
  // Keep existing pickup and drop markers
  for (var marker in _markers) {
    if (marker.markerId.value != 'user') {
      markers.add(marker);
    }
  }

  // Update the markers in the state
  setState(() {
    _markers = markers;
  });

  // Only update camera when necessary to prevent constant zooming
  if (!_isMapInitialized) {
    _updateCamera();
  }
}
  
  void _updateCamera() async {
    if (!_mapController.isCompleted) {
      debugPrint('⚠️ Cannot update camera: map controller not initialized');
      return;
    }

    final controller = await _mapController.future;
    debugPrint('🔍 Updating camera position');

    if (_userLocation != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation!,
            zoom: 16.0, // Higher zoom for better visibility
          ),
        ),
      );
      _isMapInitialized = true;
    }
  }
  
  // Generate random nearby location for demo purposes
  LatLng _getNearbyRandomLocation(LatLng center, double radiusInMeters) {
    final random = Random();
    
    // Convert radius from meters to degrees
    final radiusInDegrees = radiusInMeters / 111000; // roughly 111km per degree
    
    final u = random.nextDouble();
    final v = random.nextDouble();
    
    final w = radiusInDegrees * sqrt(u);
    final t = 2 * pi * v;
    
    final x = w * cos(t);
    final y = w * sin(t);
    
    // Adjust the x-coordinate for the shrinking of the east-west distances
    final newX = x / cos(center.latitude * pi / 180);
    
    final newLatitude = center.latitude + y;
    final newLongitude = center.longitude + newX;
    
    return LatLng(newLatitude, newLongitude);
  }
  
  // Generate sample nearby locations for demo
  void _generateNearbyLocations() {
    if (_userLocation == null) return;
    
    // In a real app, this would be an API call to get nearby locations
    // For demo purposes, we're creating sample data
    _nearbyLocations = [
      {
        'name': 'Central Business District',
        'distance': 2.3,
        'eta': '8 mins',
        'location': _getNearbyRandomLocation(_userLocation!, 2300),
      },
      {
        'name': 'Airport Terminal 2',
        'distance': 5.7,
        'eta': '15 mins',
        'location': _getNearbyRandomLocation(_userLocation!, 5700),
      },
      {
        'name': 'Tech Park',
        'distance': 3.1,
        'eta': '10 mins',
        'location': _getNearbyRandomLocation(_userLocation!, 3100),
      },
      {
        'name': 'City Mall',
        'distance': 1.8,
        'eta': '6 mins',
        'location': _getNearbyRandomLocation(_userLocation!, 1800),
      },
    ];
  }

  void _handlePassengerCountSubmit() {
    final count = int.tryParse(_passengerCountController.text);
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid passenger count')),
      );
      return;
    }
    
    setState(() {
      _passengerCount = count;
      _showPassengerForm = false;
      _showPassengerDetails = true;
      
      // Initialize controllers for each passenger
      _userIdControllers.clear();
      _pickupControllers.clear();
      _dropControllers.clear();
      
      for (int i = 0; i < count; i++) {
        _userIdControllers.add(TextEditingController());
        _pickupControllers.add(TextEditingController());
        _dropControllers.add(TextEditingController());
      }
    });
  }
  
  void _handleStartTrip() {
    bool isValid = true;
    for (int i = 0; i < _passengerCount; i++) {
      if (_userIdControllers[i].text.isEmpty ||
          _pickupControllers[i].text.isEmpty ||
          _dropControllers[i].text.isEmpty) {
        isValid = false;
        break;
      }
    }
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all passenger details')),
      );
      return;
    }
    
    setState(() {
      _showPassengerDetails = false;
      _tripStarted = true;
      _updateMapMarkers();
    });
    
    // Group nearby locations
    _groupNearbyLocations();
    
    // Calculate optimal pickup sequence
    _calculateOptimalPickupSequence();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip started! Calculating optimal route...')),
    );
  }

  // Update the OTP verification dialog to only show for pickup
  void _showOtpVerificationDialog(int passengerIndex) {
    if (!_isPickingUp) return; // Only show OTP dialog for pickup
    
    setState(() {
      _showOtpDialog = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Verify Pickup OTP for Passenger ${passengerIndex + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter the 4-digit OTP provided by the passenger',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpInputController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'Enter 4-digit OTP',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showOtpDialog = false;
                _otpInputController.clear();
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handleOtpVerification(passengerIndex),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  // Update the OTP verification handler with improved route optimization
  void _handleOtpVerification(int passengerIndex) {
    if (_otpInputController.text.length == 4) {
      Navigator.pop(context);
      setState(() {
        _showOtpDialog = false;
        _otpInputController.clear();
        
        // Update passenger status to 'In Car' after pickup verification
        _passengerInCar[passengerIndex] = true;
        _updatePassengerStatus(passengerIndex, 'In Car');
        
        // Remove this pickup from sequence
        _pickupSequence.remove(passengerIndex);
        
        // Calculate optimal route considering both pickup and drop points
        _calculateOptimalRoute(passengerIndex);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup verified successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 4-digit OTP')),
      );
    }
  }

  // Add this method for optimal route calculation
  void _calculateOptimalRoute(int currentPassengerIndex) {
    if (_userLocation == null) return;
    
    setState(() {
      _isOptimizingRoute = true;
    });
    
    // Get current passenger's drop location
    final currentDropMarker = _markers.firstWhere(
      (m) => m.markerId.value == 'drop_$currentPassengerIndex',
      orElse: () => Marker(markerId: MarkerId('dummy')),
    );
    
    if (currentDropMarker.markerId.value == 'dummy') return;
    
    // Calculate distances to all remaining pickup points
    Map<int, double> remainingPickupDistances = {};
    for (final pickupIndex in _pickupSequence) {
      final pickupMarker = _markers.firstWhere(
        (m) => m.markerId.value == 'pickup_$pickupIndex',
        orElse: () => Marker(markerId: MarkerId('dummy')),
      );
      
      if (pickupMarker.markerId.value != 'dummy') {
        // Calculate distance from current drop location to next pickup
        final distance = _calculateDistance(
          currentDropMarker.position.latitude,
          currentDropMarker.position.longitude,
          pickupMarker.position.latitude,
          pickupMarker.position.longitude,
        );
        
        remainingPickupDistances[pickupIndex] = distance;
      }
    }
    
    // Sort remaining pickups by distance from current drop location
    final sortedPickups = remainingPickupDistances.keys.toList()
      ..sort((a, b) => remainingPickupDistances[a]!.compareTo(remainingPickupDistances[b]!));
    
    // Update the pickup sequence
    setState(() {
      _pickupSequence = sortedPickups;
      _isOptimizingRoute = false;
    });
    
    // Navigate to drop location
    _navigateToDropLocation(currentPassengerIndex);
  }

  // Update the navigation to drop location with improved route handling
  void _navigateToDropLocation(int passengerIndex) {
    final dropMarker = _markers.firstWhere(
      (m) => m.markerId.value == 'drop_$passengerIndex',
      orElse: () => Marker(markerId: MarkerId('dummy')),
    );
    
    if (dropMarker.markerId.value != 'dummy') {
      setState(() {
        _isPickingUp = false;
        _isNavigating = true;
      });
      
      // Clear existing routes
      setState(() {
        _routes.clear();
        _routeInfo.clear();
      });
      
      // Draw route to drop location, using traffic-aware routing if enabled
      if (_userLocation != null) {
        if (_useTrafficAwareRouting) {
          _getTrafficAwareRoute(
            _userLocation!,
            dropMarker.position,
            'route_to_drop_$passengerIndex',
          );
        } else {
          _getDirectionsAndDrawRoute(
            _userLocation!,
            dropMarker.position,
            'route_to_drop_$passengerIndex',
          );
        }
      }
      
      // Update camera with smooth animation
      _mapController.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: dropMarker.position,
              zoom: 16.0,
            ),
          ),
        );
      });
      
      // Monitor distance to drop location with improved accuracy
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_userLocation != null) {
          final distance = _calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            dropMarker.position.latitude,
            dropMarker.position.longitude,
          );
          
          // Update UI with current distance
          setState(() {
            _dropDistances[passengerIndex] = distance;
          });
          
          if (distance < 50) { // Within 50 meters
            timer.cancel();
            // Automatically mark as dropped when near location
            setState(() {
              _passengerDropped[passengerIndex] = true;
              _updatePassengerStatus(passengerIndex, 'Dropped');
              
              // Move to next pickup if any
              if (_pickupSequence.isNotEmpty) {
                _currentPickupIndex = _pickupSequence.first;
                _isPickingUp = true;
                _showNearestPickupRoute();
                
                // Show notification for next pickup
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Moving to pickup location: ${_pickupControllers[_currentPickupIndex].text}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                // All pickups handled, show completion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All passengers have been handled!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      });
    }
  }

  // Add this helper method for status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Waiting':
        return Colors.orange;
      case 'In Car':
        return Colors.blue;
      case 'Dropped':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Add this method to update passenger status
  void _updatePassengerStatus(int index, String status) {
    setState(() {
      _passengerStatus[index] = status;
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _passengerCountController.dispose();
    for (var controller in _userIdControllers) {
      controller.dispose();
    }
    for (var controller in _pickupControllers) {
      controller.dispose();
    }
    for (var controller in _dropControllers) {
      controller.dispose();
    }
    
    // Clear map controller resources
    _mapController.future
        .then((controller) {
          controller.dispose();
        })
        .catchError((e) {
          debugPrint('Error disposing map controller: $e');
        });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              const Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    if (_locationError.isNotEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Location Tracking'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Location Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _locationError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _locationError = "";
                    });
                    _initializeLocation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ETS Trip Tracking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Map - Only build when initialCameraPosition is available
            _initialCameraPosition == null
                ? const Center(child: CircularProgressIndicator())
                :GoogleMap(
  initialCameraPosition: _initialCameraPosition!,
  myLocationEnabled: true,
  myLocationButtonEnabled: true,
  compassEnabled: true,
  markers: _markers,
  polylines: Set<Polyline>.of(_routes.values),
  circles: _clusterCircles,
  onMapCreated: (GoogleMapController controller) {
    _mapController.complete(controller);
    debugPrint('🗺️ Google Map controller created');

    // Force update markers when map is created
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _updateMapMarkers();
      }
    });
  },
  zoomControlsEnabled: true,
  mapToolbarEnabled: true,
  minMaxZoomPreference: const MinMaxZoomPreference(
    8,
    20,
  ), // Limit zoom levels for better UX
),

            // Passenger count form
            if (_showPassengerForm)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter Passenger Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passengerCountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Number of Passengers',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.people),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handlePassengerCountSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Passenger details form with autocomplete
            if (_showPassengerDetails)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Details for $_passengerCount Passengers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Stack(
                            children: [
                              ListView.builder(
                                itemCount: _passengerCount,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Passenger ${index + 1}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _userIdControllers[index],
                                          decoration: InputDecoration(
                                            labelText: 'User ID',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            prefixIcon: const Icon(Icons.person),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _pickupControllers[index],
                                          decoration: InputDecoration(
                                            labelText: 'Pickup Location',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            prefixIcon: const Icon(Icons.location_on),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _pickupControllers[index].clear();
                                                  _showPickupSuggestions = false;
                                                });
                                              },
                                            ),
                                          ),
                                          onChanged: (value) {
                                            _getPlaceSuggestions(value, true, index);
                                          },
                                          onTap: () {
                                            setState(() {
                                              _activeSuggestionField = index;
                                              _showDropSuggestions = false;
                                              if (_pickupControllers[index].text.length >= 3) {
                                                _getPlaceSuggestions(_pickupControllers[index].text, true, index);
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _dropControllers[index],
                                          decoration: InputDecoration(
                                            labelText: 'Drop Location',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            prefixIcon: const Icon(Icons.location_on),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _dropControllers[index].clear();
                                                  _showDropSuggestions = false;
                                                });
                                              },
                                            ),
                                          ),
                                          onChanged: (value) {
                                            _getPlaceSuggestions(value, false, index);
                                          },
                                          onTap: () {
                                            setState(() {
                                              _activeSuggestionField = index;
                                              _showPickupSuggestions = false;
                                              if (_dropControllers[index].text.length >= 3) {
                                                _getPlaceSuggestions(_dropControllers[index].text, false, index);
                                              }
                                            });
                                          },
                                        ),
                                        const Divider(height: 24),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              // Pickup suggestions
                              if (_showPickupSuggestions && _activeSuggestionField >= 0)
                                Positioned(
                                  top: 120 + (_activeSuggestionField * 180), // Approximate position
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _pickupSuggestions.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(_pickupSuggestions[index]['description']),
                                          onTap: () {
                                            _handlePlaceSelection(
                                              _pickupSuggestions[index],
                                              true,
                                              _activeSuggestionField,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              
                              // Drop suggestions
                              if (_showDropSuggestions && _activeSuggestionField >= 0)
                                Positioned(
                                  top: 170 + (_activeSuggestionField * 180), // Approximate position
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _dropSuggestions.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(_dropSuggestions[index]['description']),
                                          onTap: () {
                                            _handlePlaceSelection(
                                              _dropSuggestions[index],
                                              false,
                                              _activeSuggestionField,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleStartTrip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Start Trip'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            // OTP Verification
            if (_showOtpVerification)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verify Passenger OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask the passenger for their OTP and enter it below to start the trip.',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter OTP',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Verify OTP'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Trip started info panel
if (_tripStarted && _routes.isNotEmpty)
  Positioned(
    bottom: 16,
    left: 16,
    right: 16,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trip Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isNavigating ? primaryColor : successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isNavigating ? 'NAVIGATING' : 'ACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isNavigating && _userLocation != null) ...[
              Text(
                'Distance to ${_isPickingUp ? "Pickup" : "Drop"}: ${_formatDistance(_getCurrentDistance())}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (_isOptimizingRoute)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Optimizing route...',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            ],
            ..._routes.entries.map((entry) {
              final routeId = entry.key;
              final info = _routeInfo[routeId];
              
              if (info == null) return const SizedBox.shrink();
              
              final passengerIndex = int.tryParse(
                routeId.split('_').last,
              ) ?? 0;
              
              final isCurrentPassenger = passengerIndex == _currentPickupIndex;
              final status = _passengerStatus[passengerIndex] ?? 'Waiting';
              final distance = _dropDistances[passengerIndex];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _userColors[passengerIndex % _userColors.length],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${passengerIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                    Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'User ID: ${_userIdControllers[passengerIndex].text}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _userColors[passengerIndex % _userColors.length],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                      child: Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pickup: ${_pickupControllers[passengerIndex].text}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Drop: ${_dropControllers[passengerIndex].text}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (distance != null && !_isPickingUp && isCurrentPassenger)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Distance to drop: ${_formatDistance(distance)}',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                      ),
                    ),
                    const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${info['distance']} • ${info['duration']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                            ),
                            if (isCurrentPassenger && _isPickingUp) ...[
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () => _showOtpVerificationDialog(passengerIndex),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                ),
                                child: const Text('Verify Pickup OTP'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (isCurrentPassenger)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (_pickupClusters.isNotEmpty || _dropClusters.isNotEmpty) ...[
              const Divider(height: 24),
              _buildClusterInfo(),
            ],
          ],
        ),
      ),
    ),
  ),

            // Traffic toggle
            _buildTrafficToggle(),
            
            // Add traffic toggle
            if (_tripStarted)
              _buildTrafficToggle(),
              
            // Add fuel efficiency button
            if (_tripStarted && _pickupSequence.length > 1)
              Positioned(
                bottom: (_tripStarted && _routes.isNotEmpty) ? 230 : 80,
                left: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: _optimizeRouteForFuelEfficiency,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco,
                            color: successColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Optimize Fuel',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Add this helper method for distance formatting
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  // Add this method to get current distance
  double _getCurrentDistance() {
    if (_userLocation == null) return 0;
    
    final currentMarker = _isPickingUp
        ? _markers.firstWhere(
            (m) => m.markerId.value == 'pickup_$_currentPickupIndex',
            orElse: () => Marker(markerId: MarkerId('dummy')),
          )
        : _markers.firstWhere(
            (m) => m.markerId.value == 'drop_$_currentPickupIndex',
            orElse: () => Marker(markerId: MarkerId('dummy')),
          );
    
    if (currentMarker.markerId.value != 'dummy') {
      return _calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        currentMarker.position.latitude,
        currentMarker.position.longitude,
      );
    }
    
    return 0;
  }

  // Add this method for smart pickup sequence
  void _calculateOptimalPickupSequence() {
    if (_userLocation == null) return;
    
    // Calculate distances to all pickup points
    _pickupDistances.clear();
    for (int i = 0; i < _passengerCount; i++) {
      final pickupMarker = _markers.firstWhere(
        (m) => m.markerId.value == 'pickup_$i',
        orElse: () => Marker(markerId: MarkerId('dummy')),
      );
      
      if (pickupMarker.markerId.value != 'dummy') {
        final distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          pickupMarker.position.latitude,
          pickupMarker.position.longitude,
        );
        
        _pickupDistances[i] = distance;
      }
    }
    
    // Sort pickups by distance
    _pickupSequence = _pickupDistances.keys.toList()
      ..sort((a, b) => _pickupDistances[a]!.compareTo(_pickupDistances[b]!));
    
    // Start with nearest pickup
    setState(() {
      _currentPickupIndex = _pickupSequence.first;
      _isFirstPickup = true;
    });
    
    // Show only the nearest pickup route initially
    _showNearestPickupRoute();
  }

  // Add this method to show only nearest pickup route
  void _showNearestPickupRoute() {
    if (_pickupSequence.isEmpty) return;
    
    final nearestPickupIndex = _pickupSequence.first;
    final pickupMarker = _markers.firstWhere(
      (m) => m.markerId.value == 'pickup_$nearestPickupIndex',
      orElse: () => Marker(markerId: MarkerId('dummy')),
    );
    
    if (pickupMarker.markerId.value != 'dummy' && _userLocation != null) {
      // Clear existing routes
      setState(() {
        _routes.clear();
        _routeInfo.clear();
      });
      
      // Draw route only to nearest pickup, using traffic-aware routing if enabled
      if (_useTrafficAwareRouting) {
        _getTrafficAwareRoute(
          _userLocation!,
          pickupMarker.position,
          'route_to_pickup_$nearestPickupIndex',
        );
      } else {
        _getDirectionsAndDrawRoute(
          _userLocation!,
          pickupMarker.position,
          'route_to_pickup_$nearestPickupIndex',
        );
      }
      
      // Update camera
      _mapController.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: pickupMarker.position,
              zoom: 16.0,
            ),
          ),
        );
      });
    }
  }

  // Add this method to show all remaining pickup routes
  void _showAllRemainingPickupRoutes() {
    if (_userLocation == null) return;
    
    // Clear existing routes
    setState(() {
      _routes.clear();
      _routeInfo.clear();
    });
    
    // Draw routes to all remaining pickups
    for (final pickupIndex in _pickupSequence) {
      final pickupMarker = _markers.firstWhere(
        (m) => m.markerId.value == 'pickup_$pickupIndex',
        orElse: () => Marker(markerId: MarkerId('dummy')),
      );
      
      if (pickupMarker.markerId.value != 'dummy') {
        _getDirectionsAndDrawRoute(
          _userLocation!,
          pickupMarker.position,
          'route_to_pickup_$pickupIndex',
        );
      }
    }
  }

  // Add this method to group nearby locations
  void _groupNearbyLocations() {
    if (_userLocation == null) return;
    
    // Clear existing clusters
    _pickupClusters.clear();
    _dropClusters.clear();
    _passengerToPickupClusterMap.clear();
    _passengerToDropClusterMap.clear();
    _clusterCircles.clear();
    
    // Maximum radius for clustering (20km)
    const double maxClusterRadius = 20000; // meters
    
    // Group pickup locations
    _groupLocations(true, maxClusterRadius);
    
    // Group drop locations
    _groupLocations(false, maxClusterRadius);
    
    // Draw cluster boundaries
    _drawClusterBoundaries();
    
    // Update the map
    setState(() {});
  }

  // Helper method to group locations
  void _groupLocations(bool isPickup, double maxRadius) {
    final clusters = isPickup ? _pickupClusters : _dropClusters;
    final clusterMap = isPickup ? _passengerToPickupClusterMap : _passengerToDropClusterMap;
    
    for (int i = 0; i < _passengerCount; i++) {
      final markerId = isPickup ? 'pickup_$i' : 'drop_$i';
      final marker = _markers.firstWhere(
        (m) => m.markerId.value == markerId,
        orElse: () => Marker(markerId: MarkerId('dummy')),
      );
      
      if (marker.markerId.value != 'dummy') {
        bool addedToCluster = false;
        
        for (int j = 0; j < clusters.length; j++) {
          final cluster = clusters[j];
          final distance = _calculateDistance(
            cluster.center.latitude,
            cluster.center.longitude,
            marker.position.latitude,
            marker.position.longitude,
          );
          
          if (distance <= maxRadius) {
            final updatedIndices = [...cluster.passengerIndices, i];
            final newCenter = _calculateClusterCenter(updatedIndices, isPickup);
            
            clusters[j] = LocationCluster(
              newCenter,
              updatedIndices,
              maxRadius,
              isPickup,
            );
            clusterMap[i] = j;
            addedToCluster = true;
            break;
          }
        }
        
        if (!addedToCluster) {
          clusters.add(LocationCluster(
            marker.position,
            [i],
            maxRadius,
            isPickup,
          ));
          clusterMap[i] = clusters.length - 1;
        }
      }
    }
  }

  // Helper method to calculate cluster center
  LatLng _calculateClusterCenter(List<int> passengerIndices, bool isPickup) {
    double totalLat = 0;
    double totalLng = 0;
    int count = 0;
    
    for (final index in passengerIndices) {
      final markerId = isPickup ? 'pickup_$index' : 'drop_$index';
      final marker = _markers.firstWhere(
        (m) => m.markerId.value == markerId,
        orElse: () => Marker(markerId: MarkerId('dummy')),
      );
      
      if (marker.markerId.value != 'dummy') {
        totalLat += marker.position.latitude;
        totalLng += marker.position.longitude;
        count++;
      }
    }
    
    return LatLng(totalLat / count, totalLng / count);
  }

  // Method to draw cluster boundaries
  void _drawClusterBoundaries() {
    _clusterCircles.clear();
    
    // Draw pickup clusters
    for (int i = 0; i < _pickupClusters.length; i++) {
      final cluster = _pickupClusters[i];
      _clusterCircles.add(
        Circle(
          circleId: CircleId('pickup_cluster_$i'),
          center: cluster.center,
          radius: cluster.radius,
          fillColor: Colors.green.withOpacity(0.1),
          strokeColor: const Color.fromARGB(255, 93, 166, 95).withOpacity(0.3),
          strokeWidth: 2,
        ),
      );
    }
    
    // Draw drop clusters
    for (int i = 0; i < _dropClusters.length; i++) {
      final cluster = _dropClusters[i];
      _clusterCircles.add(
        Circle(
          circleId: CircleId('drop_cluster_$i'),
          center: cluster.center,
          radius: cluster.radius,
          strokeColor: Colors.red.withOpacity(0.3),
          strokeWidth: 2,
        ),
      );
    }
  }

  Widget _buildClusterInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Clusters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        ..._pickupClusters.map((cluster) {
          return Card(
                  child: Padding(
              padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Cluster ${_pickupClusters.indexOf(cluster) + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Passengers: ${cluster.passengerIndices.length}',
                    style: TextStyle(color: textColor),
                  ),
                  Text(
                    'Center: ${cluster.center.latitude.toStringAsFixed(4)}, ${cluster.center.longitude.toStringAsFixed(4)}',
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _navigateToCluster(cluster),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Navigate to Cluster'),
              ),
          ],
        ),
      ),
          );
        }).toList(),
        ..._dropClusters.map((cluster) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drop Cluster ${_dropClusters.indexOf(cluster) + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Passengers: ${cluster.passengerIndices.length}',
                    style: TextStyle(color: textColor),
                  ),
                  Text(
                    'Center: ${cluster.center.latitude.toStringAsFixed(4)}, ${cluster.center.longitude.toStringAsFixed(4)}',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _navigateToCluster(LocationCluster cluster) {
    // Implement navigation to cluster center
    if (_userLocation == null) return;
    
    // Get directions to cluster center
    _getDirectionsAndDrawRoute(
      _userLocation!,
      cluster.center,
      'route_to_cluster_${cluster.isPickup ? "pickup" : "drop"}_${cluster.isPickup ? _pickupClusters.indexOf(cluster) : _dropClusters.indexOf(cluster)}',
    );
    
    // Update camera to show cluster
    _mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: cluster.center,
            zoom: 12.0, // Zoom out to show entire cluster
          ),
        ),
      );
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${cluster.isPickup ? "pickup" : "drop"} cluster with ${cluster.passengerIndices.length} ${cluster.passengerIndices.length == 1 ? "passenger" : "passengers"}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // New method to calculate fuel efficiency for a route
  double _calculateFuelEfficiency(List<LatLng> routePoints) {
    if (routePoints.isEmpty || routePoints.length < 2) return 0;
    
    double totalDistance = 0;
    double totalFuel = 0;
    
    // Factors affecting fuel consumption
    const double baseFuelConsumption = 0.08; // liters per km
    const double stopStartPenalty = 0.02; // Additional consumption for stop-start
    const double highwayBonus = 0.01; // Reduction for highway driving
    
    for (int i = 0; i < routePoints.length - 1; i++) {
      // Calculate distance between points
      final distance = _calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      ) / 1000; // Convert to km
      
      // Determine if this segment is likely highway or city
      // Simplistic approach: longer segments are more likely highways
      final bool isHighway = distance > 1.0; // segments > 1km are highways
      
      // Calculate fuel for this segment
      double segmentFuel = distance * baseFuelConsumption;
      
      // Apply modifiers
      if (i > 0 && distance < 0.1) {
        // Short segments likely mean stop-start traffic
        segmentFuel += distance * stopStartPenalty;
      }
      
      if (isHighway) {
        // Highway driving is more efficient
        segmentFuel -= distance * highwayBonus;
      }
      
      totalDistance += distance;
      totalFuel += segmentFuel;
    }
    
    // Return liters per km efficiency
    return totalDistance > 0 ? totalFuel / totalDistance : 0;
  }
  
  // New method to optimize route for fuel efficiency
  Future<void> _optimizeRouteForFuelEfficiency() async {
    if (_userLocation == null || _pickupSequence.isEmpty) return;
    
    setState(() {
      _isOptimizingRoute = true;
    });
    
    // Get all possible route combinations
    List<List<int>> possibleRoutes = _generatePossibleRoutes(_pickupSequence);
    
    Map<String, double> routeEfficiencies = {};
    
    // Evaluate each route
    for (final route in possibleRoutes) {
      List<LatLng> routePoints = [_userLocation!];
      
      // Gather all route points
      for (final idx in route) {
        final pickupMarker = _markers.firstWhere(
          (m) => m.markerId.value == 'pickup_$idx',
          orElse: () => Marker(markerId: MarkerId('dummy')),
        );
        
        if (pickupMarker.markerId.value != 'dummy') {
          routePoints.add(pickupMarker.position);
        }
        
        // If passenger is in car, add drop point too
        if (_passengerInCar[idx] == true) {
          final dropMarker = _markers.firstWhere(
            (m) => m.markerId.value == 'drop_$idx',
            orElse: () => Marker(markerId: MarkerId('dummy')),
          );
          
          if (dropMarker.markerId.value != 'dummy') {
            routePoints.add(dropMarker.position);
          }
        }
      }
      
      // Calculate efficiency for this route
      final efficiency = _calculateFuelEfficiency(routePoints);
      routeEfficiencies[route.join('-')] = efficiency;
    }
    
    // Find the most efficient route
    if (routeEfficiencies.isNotEmpty) {
      final mostEfficientKey = routeEfficiencies.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
      
      final mostEfficientRoute = mostEfficientKey.split('-')
        .map((e) => int.parse(e))
        .toList();
      
      setState(() {
        _pickupSequence = mostEfficientRoute;
        _currentPickupIndex = _pickupSequence.first;
        _isOptimizingRoute = false;
      });
      
      // Update the route display
      _showNearestPickupRoute();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Route optimized for fuel efficiency'),
          duration: const Duration(seconds: 2),
        )
      );
    } else {
      setState(() {
        _isOptimizingRoute = false;
      });
    }
  }
  
  // Generate all possible routes (for small number of pickups)
  List<List<int>> _generatePossibleRoutes(List<int> pickups) {
    // For simplicity, limit to first 5 pickups to avoid excessive computations
    final limitedPickups = pickups.take(5).toList();
    
    // For very few pickups, generate all permutations
    if (limitedPickups.length <= 3) {
      return _generatePermutations(limitedPickups);
    }
    
    // For more pickups, use a heuristic approach
    List<List<int>> routes = [];
    
    // Start with the greedy approach (current sequence)
    routes.add(List.from(limitedPickups));
    
    // Try some swaps to find potentially better routes
    for (int i = 0; i < limitedPickups.length - 1; i++) {
      for (int j = i + 1; j < limitedPickups.length; j++) {
        List<int> swapped = List.from(limitedPickups);
        final temp = swapped[i];
        swapped[i] = swapped[j];
        swapped[j] = temp;
        routes.add(swapped);
      }
    }
    
    return routes;
  }
  
  // Generate all permutations of a list
  List<List<int>> _generatePermutations(List<int> items) {
    List<List<int>> result = [];
    
    void permute(List<int> current, List<int> remaining) {
      if (remaining.isEmpty) {
        result.add(List.from(current));
        return;
      }
      
      for (int i = 0; i < remaining.length; i++) {
        List<int> newRemaining = List.from(remaining);
        int item = newRemaining.removeAt(i);
        
        List<int> newCurrent = List.from(current)..add(item);
        permute(newCurrent, newRemaining);
      }
    }
    
    permute([], items);
    return result;
  }
}