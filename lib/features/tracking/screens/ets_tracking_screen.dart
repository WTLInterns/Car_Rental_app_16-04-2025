import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

// Professional color palette
const Color primaryColor = Color(0xFF4A90E2);
const Color backgroundColor = Colors.white;
const Color textColor = Color(0xFF333333);

class ETSDriverTrackingScreen extends StatefulWidget {
  final String? etsId;
  final String? driverId;
  final String? slotId;
  final String? fromLocation;
  final String? toLocation;
  final LatLng? pickupCoordinates;
  final LatLng? dropCoordinates;
  
  const ETSDriverTrackingScreen({
    super.key,
    this.etsId,
    this.driverId,
    this.slotId,
    this.fromLocation,
    this.toLocation,
    this.pickupCoordinates,
    this.dropCoordinates,
  });

  @override
  State<ETSDriverTrackingScreen> createState() => _ETSDriverTrackingScreenState();
}

class UserLocationData {
  final String userId;
  final double latitude;
  final double longitude;
  final String pickupLocation;
  final String dropLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final String? rideStatus;

  UserLocationData({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.pickupLocation,
    required this.dropLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.rideStatus,
  });

  factory UserLocationData.fromJson(Map<String, dynamic> json) {
    return UserLocationData(
      userId: json['userId'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      pickupLatitude: json['pickupLatitude']?.toDouble(),
      pickupLongitude: json['pickupLongitude']?.toDouble(),
      dropLatitude: json['dropLatitude']?.toDouble(),
      dropLongitude: json['dropLongitude']?.toDouble(),
      rideStatus: json['rideStatus'],
    );
  }
}

class _ETSDriverTrackingScreenState extends State<ETSDriverTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  
  // Form controllers
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _slotIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  // Map markers and polylines
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  // Map controller and location data
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  Timer? _userCheckTimer; // Fixed naming for clarity
  
  // Connection status
  bool _isConnected = false;
  
  // UI state
  String _statusMessage = "Not connected";
  String _currentRideStatus = "PENDING";
  String? _selectedUserId;
  bool _showOtpVerification = false;
  
  // Users data
  List<UserLocationData> _activeUsers = [];
  
  // Ride information
  double _distanceToPickup = 0.0;
  int _etaToPickup = 0;
  
  // API Base URL
  static const String baseUrl = "https://ets.worldtriplink.com";
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Initialize form fields from widget parameters if available
    if (widget.driverId != null && widget.driverId!.isNotEmpty) {
      _driverIdController.text = widget.driverId!;
    }
    
    if (widget.etsId != null && widget.etsId!.isNotEmpty) {
      _slotIdController.text = widget.etsId!;
    }
    
    await _determinePosition();
    
    // If pickup and drop coordinates are provided, add markers
    if (widget.pickupCoordinates != null && widget.dropCoordinates != null) {
      _addInitialMarkersAndRoute();
    }
  }
  
  void _addInitialMarkersAndRoute() {
    if (widget.pickupCoordinates == null || widget.dropCoordinates == null || !mounted) return;
    
    setState(() {
      // Add pickup marker
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupCoordinates!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Pickup', snippet: widget.fromLocation ?? 'Pickup Location'),
        ),
      );
      
      // Add drop marker
      _markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: widget.dropCoordinates!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Drop', snippet: widget.toLocation ?? 'Drop Location'),
        ),
      );
    });
    
    // Draw route between pickup and drop
    _drawInitialRoute();
  }
  
  // Decode a polyline string into a list of coordinates
  List<List<num>> decodePolyline(String encoded, {int accuracyExponent = 5}) {
    List<List<num>> points = [];
    int index = 0;
    int len = encoded.length;
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
      
      List<num> point = [];
      point.add(lat / pow(10, accuracyExponent));
      point.add(lng / pow(10, accuracyExponent));
      points.add(point);
    }
    
    return points;
  }
  
  Future<void> _drawInitialRoute() async {
    if (widget.pickupCoordinates == null || widget.dropCoordinates == null || !mounted) return;
    
    try {
      final pickupLat = widget.pickupCoordinates!.latitude;
      final pickupLng = widget.pickupCoordinates!.longitude;
      final dropLat = widget.dropCoordinates!.latitude;
      final dropLng = widget.dropCoordinates!.longitude;
      
      final url = 'https://router.project-osrm.org/route/v1/driving/$pickupLng,$pickupLat;$dropLng,$dropLat?overview=full&geometries=polyline';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final polyline = data['routes'][0]['geometry'];
          final List<List<num>> coordinates = decodePolyline(polyline, accuracyExponent: 5);
          
          final List<LatLng> polylineCoordinates = coordinates
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();
          
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('initial_route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            );
          });
        }
      }
    } catch (e) {
      print('Error drawing initial route: $e');
      // Draw fallback straight line
      if (mounted) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('initial_route'),
              points: [
                widget.pickupCoordinates!,
                widget.dropCoordinates!,
              ],
              color: Colors.blue,
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        });
      }
    }
  }
  
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Location services are disabled. Please enable location services.';
          });
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Location permissions are denied.';
            });
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Location permissions are permanently denied.';
          });
        }
        return;
      } 

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        _updateMarkers();
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error accessing location: $e';
        });
      }
    }
  }
  
  void _updateMarkers() {
    if (!mounted) return;
    
    Set<Marker> markers = {};
    
    // Driver marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: InfoWindow(title: 'Driver', snippet: 'ID: ${_driverIdController.text}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    
    // User markers
    for (var user in _activeUsers) {
      // User current location marker
      markers.add(
        Marker(
          markerId: MarkerId('user_${user.userId}'),
          position: LatLng(user.latitude, user.longitude),
          infoWindow: InfoWindow(title: 'User', snippet: user.userId),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
      
      // Pickup location marker
      if (user.pickupLatitude != null && user.pickupLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('pickup_${user.userId}'),
            position: LatLng(user.pickupLatitude!, user.pickupLongitude!),
            infoWindow: InfoWindow(title: 'Pickup', snippet: user.pickupLocation),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      // Drop location marker
      if (user.dropLatitude != null && user.dropLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('drop_${user.userId}'),
            position: LatLng(user.dropLatitude!, user.dropLongitude!),
            infoWindow: InfoWindow(title: 'Drop', snippet: user.dropLocation),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }
    
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }
  
  Future<void> _drawRoute(UserLocationData user) async {
    if (!mounted || user.pickupLatitude == null || user.pickupLongitude == null || 
        user.dropLatitude == null || user.dropLongitude == null) return;
    
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${user.pickupLongitude},${user.pickupLatitude};${user.dropLongitude},${user.dropLatitude}?overview=full&geometries=polyline';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final polyline = data['routes'][0]['geometry'];
          final List<List<num>> coordinates = decodePolyline(polyline, accuracyExponent: 5);
          
          final List<LatLng> polylineCoordinates = coordinates
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();
          
          setState(() {
            _polylines.removeWhere((p) => p.polylineId.value == 'route_${user.userId}');
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route_${user.userId}'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
      // Fallback to straight line
      _drawFallbackRoute(user);
    }
  }
  
  void _drawFallbackRoute(UserLocationData user) {
    if (!mounted || user.pickupLatitude == null || user.pickupLongitude == null || 
        user.dropLatitude == null || user.dropLongitude == null) return;
    
    final polylineCoordinates = [
      LatLng(user.pickupLatitude!, user.pickupLongitude!),
      LatLng(user.dropLatitude!, user.dropLongitude!),
    ];
    
    setState(() {
      _polylines.removeWhere((p) => p.polylineId.value == 'route_${user.userId}');
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${user.userId}'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    });
  }
  
  Future<void> _connect() async {
    if (_driverIdController.text.isEmpty || _slotIdController.text.isEmpty) {
      _updateStatus('Please fill in all fields', Colors.red);
      return;
    }
    
    setState(() {
      _isConnected = true;
      _statusMessage = 'Connected! Getting your location...';
    });
    
    // Start location updates
    _startLocationUpdates();
    
    // Connect to WebSocket - using HTTP polling for now
    _connectToWebSocket();
  }
  
  void _startLocationUpdates() {
    // Cancel any existing timers first
    _cancelTimers();
    
    // Send location updates every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isConnected && _currentPosition != null && mounted) {
        _sendDriverLocation();
      }
    });
  }
  
  void _connectToWebSocket() {
    // Cancel any existing timer first
    _userCheckTimer?.cancel();
    
    // Set up a timer to check for user locations periodically
    _userCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isConnected && mounted) {
        _checkUserLocations();
      }
    });
  }
  
  Future<void> _checkUserLocations() async {
    if (!mounted || !_isConnected) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/location/users/${_slotIdController.text}'),
      );
      
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> userLocationsJson = json.decode(response.body);
        final userLocations = userLocationsJson
            .map((json) => UserLocationData.fromJson(json))
            .toList();
        
        setState(() {
          _activeUsers = userLocations;
        });
        
        _updateMarkers();
        
        // Draw routes for all users
        for (var user in userLocations) {
          if (user.pickupLatitude != null && user.pickupLongitude != null &&
              user.dropLatitude != null && user.dropLongitude != null) {
            _drawRoute(user);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting user locations: $e');
    }
  }
  
  Future<void> _sendDriverLocation() async {
    if (!mounted || _currentPosition == null) return;
    
    final locationData = {
      'userId': '',
      'driverId': _driverIdController.text,
      'slotId': _slotIdController.text,
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'messageType': 'DRIVER_LOCATION',
      'rideStatus': _currentRideStatus
    };
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/location/driver/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(locationData),
      );
      
      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        
        // Update ride info if available
        if (responseData['distanceToPickup'] != null) {
          setState(() {
            _distanceToPickup = responseData['distanceToPickup'].toDouble();
          });
        }
        
        if (responseData['estimatedTimeToPickup'] != null) {
          setState(() {
            _etaToPickup = responseData['estimatedTimeToPickup'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating position data: $e');
    }
  }
  
  Future<void> _updateRideStatus(String status) async {
    if (_selectedUserId == null) {
      _updateStatus('Please select a user first', Colors.red);
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/location/updateStatus'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _selectedUserId,
          'driverId': _driverIdController.text,
          'slotId': _slotIdController.text,
          'status': status,
        }),
      );
      
      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _currentRideStatus = status;
            if (status == 'ARRIVED') {
              _showOtpVerification = true;
            } else if (status == 'PICKED_UP' || status == 'DROPPED') {
              _showOtpVerification = false;
            }
          });
          
          _updateStatus('Ride status updated to: $status', Colors.green);
          
          if (status == 'DROPPED') {
            // Reset after drop-off
            Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _selectedUserId = null;
                  _currentRideStatus = 'PENDING';
                  _showOtpVerification = false;
                });
              }
            });
          }
        } else {
          _updateStatus('Failed to update ride status', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Error updating ride status: $e');
      _updateStatus('Error updating ride status', Colors.red);
    }
  }
  
  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _updateStatus('Please enter the OTP provided by the user', Colors.red);
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/location/verifyOTP'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _selectedUserId,
          'slotId': _slotIdController.text,
          'otp': _otpController.text,
        }),
      );
      
      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          _updateStatus('OTP verified successfully!', Colors.green);
          _otpController.clear();
          _updateRideStatus('PICKED_UP');
        } else {
          _updateStatus('OTP verification failed', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      _updateStatus('Error verifying OTP', Colors.red);
    }
  }
  
  void _selectUser(String userId) {
    setState(() {
      _selectedUserId = userId;
      _showOtpVerification = _currentRideStatus == 'ARRIVED';
    });
    
    // Focus map on selected user
    final user = _activeUsers.firstWhere((u) => u.userId == userId);
    _focusOnUser(user);
  }
  
  Future<void> _focusOnUser(UserLocationData user) async {
    if (!_mapController.isCompleted || !mounted) return;
    
    final controller = await _mapController.future;
    
    List<LatLng> positions = [
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude), // Driver
      LatLng(user.latitude, user.longitude), // User
    ];
    
    if (user.pickupLatitude != null && user.pickupLongitude != null) {
      positions.add(LatLng(user.pickupLatitude!, user.pickupLongitude!));
    }
    
    if (user.dropLatitude != null && user.dropLongitude != null) {
      positions.add(LatLng(user.dropLatitude!, user.dropLongitude!));
    }
    
    final bounds = _calculateBounds(positions);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }
  
  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;
    
    for (final position in positions) {
      minLat = minLat > position.latitude ? position.latitude : minLat;
      maxLat = maxLat < position.latitude ? position.latitude : maxLat;
      minLng = minLng > position.longitude ? position.longitude : minLng;
      maxLng = maxLng < position.longitude ? position.longitude : maxLng;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  void _updateStatus(String message, Color color) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }
  
  // CRITICAL: Cancel all timers and subscriptions to prevent memory leaks
  void _cancelTimers() {
    _locationUpdateTimer?.cancel();
    _userCheckTimer?.cancel();
    _positionStream?.cancel();
  }
  
  @override
  void dispose() {
    // CRITICAL: Cancel all timers and subscriptions before disposing
    _cancelTimers();
    
    _driverIdController.dispose();
    _slotIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ETS - Driver Location Tracking'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            const SizedBox(height: 4),
            _buildRideControls(),
            // Map
            Expanded(child: _buildMap()),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ETS - Driver Location Tracking'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // Connection Form
            _buildConnectionForm(),
          ],
        ),
      );
    }
  }
  
  Widget _buildMap() {
    // Initialize map position at pickup coordinates if available, otherwise use a default location
    final CameraPosition initialPosition = CameraPosition(
      target: widget.pickupCoordinates ?? const LatLng(18.5204, 73.8567), // Default: Pune
      zoom: 14.0,
    );
    
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all()
        ),
        child: GoogleMap(
          initialCameraPosition: initialPosition,
          onMapCreated: (GoogleMapController controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
          },
          markers: _markers,
          polylines: _polylines,
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
  
  Widget _buildConnectionForm() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _driverIdController,
                    decoration: const InputDecoration(
                      labelText: 'Driver ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _slotIdController,
                    decoration: const InputDecoration(
                      labelText: 'Slot ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Connect & Start Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideControls() {
    return Flexible(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16,4,16,8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.grey.shade400, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ride Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Users list
              const Text('Users in this slot:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),

              if (_activeUsers.isEmpty)
                const Text('No active users', style: TextStyle(color: Colors.grey, fontSize: 12))
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _activeUsers.map((user) => _buildUserItem(user)).toList(),
                ),

              // Selected user controls
              if (_selectedUserId != null) _buildSelectedUserControls(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserItem(UserLocationData user) {
    final isSelected = _selectedUserId == user.userId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectUser(user.userId),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: ${user.userId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text('Pickup: ${user.pickupLocation}', style: const TextStyle(fontSize: 12)),
              Text('Drop: ${user.dropLocation}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectedUserControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text('Selected User: $_selectedUserId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateRideStatus('ARRIVED'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark as Arrived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateRideStatus('PICKED_UP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Pick Up User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateRideStatus('DROPPED'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete Ride', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        
        // OTP Verification section
        if (_showOtpVerification) _buildOtpVerification(),
      ],
    );
  }
  
  Widget _buildOtpVerification() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verify OTP from User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ask the user for their OTP to verify pickup'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    hintText: 'Enter OTP',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 3, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Verify'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}