import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Add Google Maps API key
const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const TrackingScreen({super.key, required this.bookingData});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Controllers and references
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _feedbackController = TextEditingController();

  // Location and map state
  final Location _location = Location();
  LatLng? _userLocation;
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  CameraPosition? _initialCameraPosition;

  // Map markers and routes
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // UI state
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _tripStarted = false;
  bool _tripCompleted = false;
  bool _showFeedback = false;
  bool _isMapInitialized = false;

  // Trip info
  String _tripStatus = "Waiting for driver";
  String _distance = "Calculating...";
  String _eta = "Calculating...";
  String _locationError = "";
  String _bookingId = "";
  String _userId = "";
  String _destination = "Waiting for driver to set destination...";
  String _driverInfo = "Connecting to driver...";

  // User rating
  int _userRating = 0;

  // OTP info
  String _otp = "------";
  bool _showOtp = false;

  // STOMP WebSocket
  StompClient? _stompClient;
  Timer? _locationUpdateTimer;

  // WebSocket config
  final String _websocketUrl = "http://192.168.1.14:8080/ws-trip-tracking";

  // Connection status
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  // New route-related variables
  List<LatLng> _routePoints = [];
  String _estimatedDistance = "Calculating...";
  String _estimatedTime = "Calculating...";
  String _driverEta = "Calculating...";

  // Add BitmapDescriptor field to store the car icon
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  double _driverBearing = 0.0; // Track driver heading/bearing
  bool _isCarIconLoaded = false; // Track if car icon is loaded

  @override
  void initState() {
    super.initState();
    debugPrint('🚗 TrackingScreen initialized');
    _initialize();
    
    // Create custom car icon immediately
    _createCustomCarIcon();
  }

  Future<void> _createCustomCarIcon() async {
    debugPrint('🚗 Creating custom car icon');
    try {
      // Set default icon first as fallback
      setState(() {
        _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      });
      
      // Create a custom car icon using canvas
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Paint paint = Paint()..color = Colors.red; // Red car color
      
      // Draw a car shape (simplified car icon)
      final double size = 40.0; // Increased size
      final Rect rect = Rect.fromLTWH(0, 0, size, size);
      
      // Car body
      final RRect carBody = RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 10, size - 10, size - 15),
        const Radius.circular(4.0),
      );
      canvas.drawRRect(carBody, paint);
      
      // Car roof
      final Path roofPath = Path()
        ..moveTo(size / 2 - 7, 10)
        ..lineTo(size / 2 + 7, 10)
        ..lineTo(size / 2 + 5, 3)
        ..lineTo(size / 2 - 5, 3)
        ..close();
      canvas.drawPath(roofPath, paint);
      
      // Car wheels
      final Paint wheelPaint = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(10, size - 6), 3.5, wheelPaint);
      canvas.drawCircle(Offset(size - 10, size - 6), 3.5, wheelPaint);
      
      // Headlights
      final Paint headlightPaint = Paint()..color = Colors.yellow;
      canvas.drawCircle(Offset(5, 12), 1.5, headlightPaint);
      canvas.drawCircle(Offset(size - 5, 12), 1.5, headlightPaint);
      
      // Convert to image
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image img = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List uint8List = byteData.buffer.asUint8List();
        
        if (mounted) {
          setState(() {
            _carIcon = BitmapDescriptor.fromBytes(uint8List);
            _isCarIconLoaded = true;
            debugPrint('✅ Custom car icon created successfully');
          });
          
          // Force refresh markers when icon is loaded
          if (_driverLocation != null) {
            _updateMapMarkers();
          }
        }
      } else {
        debugPrint('⚠️ Failed to create custom car icon: byteData is null');
      }
    } catch (e) {
      debugPrint('⚠️ Error creating custom car icon: $e');
    }
  }

  void _initialize() async {
    // Extract booking data from the passed parameters
    _bookingId = widget.bookingData['bookingId'] ?? '';

    // Load userId from SharedPreferences
    await _loadUserData();

    debugPrint(
      '📱 Initializing tracking for booking: $_bookingId, user: $_userId',
    );
    debugPrint('📦 Booking data: ${jsonEncode(widget.bookingData)}');

    // Initialize location
    await _initializeLocation();

    // Connect to WebSocket with STOMP
    _connectStompWebSocket();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First try to get userId as int (old format)
      var id = prefs.getInt('userId');
      if (id != null) {
        _userId = id.toString();
      } else {
        // Then try as string (new format)
        _userId = prefs.getString('userId') ?? '';
      }

      // If still empty, try to get from userData JSON
      if (_userId.isEmpty) {
        final userDataStr = prefs.getString('userData');
        if (userDataStr != null && userDataStr.isNotEmpty) {
          try {
            final userData = jsonDecode(userDataStr);
            _userId = userData['userId']?.toString() ?? '';
          } catch (e) {
            debugPrint('❌ Error parsing userData JSON: $e');
          }
        }
      }

      debugPrint('👤 Loaded userId from SharedPreferences: $_userId');
    } catch (e) {
      debugPrint('❌ Error loading userId from SharedPreferences: $e');
    }
  }

  void _connectStompWebSocket() {
    try {
      debugPrint('🔌 Attempting to connect to STOMP WebSocket server...');
      debugPrint('🌐 WebSocket URL: $_websocketUrl');

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: _websocketUrl,
          onConnect: _onStompConnect,
          onDisconnect: (p0) {
            debugPrint('🔌 STOMP WebSocket disconnected');
            _isConnected = false;
            _handleReconnect();
          },
          onStompError: (error) {
            debugPrint('❌ STOMP error: ${error.body}');
            _isConnected = false;
          },
          onWebSocketError: (error) {
            debugPrint('❌ WebSocket error: $error');
            _isConnected = false;
            _handleReconnect();
          },
          stompConnectHeaders: {'bookingId': _bookingId, 'userId': _userId},
          webSocketConnectHeaders: {'bookingId': _bookingId, 'userId': _userId},
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      debugPrint('❌ Error connecting to STOMP WebSocket: $e');
      _isConnected = false;
      _handleReconnect();
    }
  }

  void _onStompConnect(StompFrame frame) {
    debugPrint('✅ Connected to STOMP server: ${frame.body}');
    _isConnected = true;
    _reconnectAttempts = 0;

    // Subscribe to driver location updates
    _stompClient?.subscribe(
      destination: '/topic/booking/$_bookingId/driver-location',
      callback: (frame) {
        debugPrint('📥 Received driver location update: ${frame.body}');
        if (frame.body != null) {
          _handleWebSocketMessage(frame.body!);
        }
      },
    );

    // Subscribe to user notifications
    _stompClient?.subscribe(
      destination: '/topic/booking/$_bookingId/user-notifications',
      callback: (frame) {
        debugPrint('📥 Received user notification: ${frame.body}');
        if (frame.body != null) {
          _handleWebSocketMessage(frame.body!);
        }
      },
    );

    // Notify about connection
    _sendConnectionMessage();

    _startLocationUpdates();
  }

  void _handleReconnect() {
    if (!mounted) return;

    _reconnectAttempts++;
    final delay = min(30, pow(2, _reconnectAttempts)).toInt();
    debugPrint(
      '🔄 Attempting to reconnect in $delay seconds (attempt $_reconnectAttempts)',
    );

    // Show snackbar on UI thread
    if (mounted) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection lost. Reconnecting in $delay seconds...'),
          ),
        );
      });
    }

    Future.delayed(Duration(seconds: delay), () {
      if (mounted && !_isConnected) {
        _connectStompWebSocket();
      }
    });
  }

  void _sendConnectionMessage() {
    final connectMessage = {
      'type': 'CONNECT',
      'bookingId': _bookingId,
      'userId': _userId,
      'userType': 'USER',
    };

    _sendWebSocketMessage(connectMessage);
  }

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_stompClient != null && _stompClient!.connected) {
      try {
        final jsonMessage = jsonEncode(message);
        debugPrint('📤 Sending message: $jsonMessage');

        // Use the correct destination path based on message type
        String destination = '/app/user-location';

        if (message['type'] == 'CONNECT') {
          destination = '/app/connect';
        } else if (message['type'] == 'SEND_OTP') {
          destination = '/app/send-otp';
        } else if (message['type'] == 'STORE_FINAL_OTP') {
          destination = '/app/send-otp';
        }

        _stompClient!.send(
          destination: destination,
          body: jsonMessage,
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        debugPrint('❌ Error sending message: $e');
      }
    } else {
      debugPrint('❌ Cannot send message: STOMP client not connected');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      debugPrint("🔍 Received WebSocket message: $data");

      // Handle message based on action or type
      final messageType = data['type'] ?? data['action'];

      // Check if this is a driver location update (may not have explicit type)
      if (data['userType'] == 'DRIVER' && data['latitude'] != null && data['longitude'] != null) {
        _handleDriverLocationUpdate(data);
        return;
      }

      switch (messageType) {
        case "DRIVER_LOCATION":
          _handleDriverLocationUpdate(data);
          break;
        case "OTP_SENT":
          _handleOtpSent(data);
          break;
        case "OTP_VERIFIED":
          setState(() {
            _tripStatus = 'OTP Verified';
            _showOtp = false;
          });
          break;
        case "TRIP_STARTED":
          _handleTripStarted(data);
          break;
        case "REQUEST_FINAL_OTP":
          _handleRequestFinalVerification(data);
          break;
        case "TRIP_ENDED":
          _handleTripCompleted(data);
          break;
        default:
          debugPrint('⚠️ Unknown message type: $messageType');
      }
    } catch (e) {
      debugPrint('❌ Error processing WebSocket message: $e');
      debugPrint('📄 Raw message that caused the error: $message');
    }
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> data) {
    try {
      // Extract latitude and longitude from the data
      double lat = 0.0;
      double lng = 0.0;
      
      // Handle different possible formats of latitude/longitude in the message
      if (data['latitude'] != null) {
        lat = data['latitude'] is double 
            ? data['latitude'] 
            : double.tryParse(data['latitude'].toString()) ?? 0.0;
      }
      
      if (data['longitude'] != null) {
        lng = data['longitude'] is double 
            ? data['longitude'] 
            : double.tryParse(data['longitude'].toString()) ?? 0.0;
      }
      
      // Only update if we have valid coordinates
      if (lat != 0.0 && lng != 0.0) {
        debugPrint('📍 Driver location updated to: $lat, $lng');
        
        // Calculate bearing if we have the previous location
        if (_driverLocation != null) {
          _driverBearing = _calculateBearing(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
            lat,
            lng,
          );
          debugPrint('🧭 Driver bearing: $_driverBearing degrees');
        }
        
        // Create a local variable for the new location
        final newDriverLocation = LatLng(lat, lng);
        
        // Update the driver location in the state
        if (mounted) {
          setState(() {
            _driverLocation = newDriverLocation;
            
            // Extract driver information if available
            if (data['driverName'] != null) {
              _driverInfo = "${data['driverName']} • ";
              if (data['vehicleInfo'] != null) {
                _driverInfo += "${data['vehicleInfo']} • ";
              }
              _driverInfo += "${_driverEta ?? 'Calculating ETA...'}";
            } else if (data['driverId'] != null) {
              _driverInfo = "Driver ID: ${data['driverId']} • ${_driverEta ?? 'Calculating ETA...'}";
            }
          });
        }
        
        // Force update markers immediately to ensure driver is displayed
        // This is called outside setState to avoid nested setState calls
        if (mounted) {
          _updateMapMarkers();
        }
        
        // Update route whenever driver location changes
        if (_userLocation != null && mounted) {
          _updateRoute();
        } else {
          debugPrint('⚠️ Cannot update route: user location is null');
        }
      } else {
        debugPrint('⚠️ Invalid driver location data: $data');
      }
    } catch (e) {
      debugPrint('❌ Error processing driver location update: $e');
    }
  }

  void _handleRequestFinalVerification(Map<String, dynamic> data) {
    debugPrint('🔐 Request for final verification received: $data');

    // Generate a new OTP
    String newOtp = _generateOTP();

    setState(() {
      _tripStatus = 'Final Verification';
      _otp = newOtp;
      _showOtp = true; // Make sure OTP is visible
    });

    // Use a post-frame callback to show the OTP dialog after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOTPDialog(newOtp);
    });

    // Send OTP to server
    debugPrint('📤 Sending new OTP to server: $newOtp');
    Map<String, dynamic> message = {
      'type': 'STORE_FINAL_OTP',
      'action': 'STORE_FINAL_OTP',
      'bookingId': _bookingId,
      'userId': _userId,
      'otp': newOtp,
    };
    _sendWebSocketMessage(message);
  }

  void _showOTPDialog(String otp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Final Verification OTP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please show this OTP to your driver:'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Text(
                otp,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Do not close this dialog until the driver verifies the OTP.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _submitFeedback() {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    // Send feedback to the server
    final feedbackMessage = {
      'type': 'FEEDBACK',
      'bookingId': _bookingId,
      'userId': _userId,
      'rating': _userRating,
      'comment': _feedbackController.text,
    };

    debugPrint(
      '⭐ Submitting feedback: rating=$_userRating, comment=${_feedbackController.text}',
    );
    _sendWebSocketMessage(feedbackMessage);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );

    setState(() => _showFeedback = false);

    // Navigate back to previous screen
    debugPrint('🔙 Returning to previous screen after feedback');
    Navigator.pop(context);
  }

  void _startLocationUpdates() {
    debugPrint(
      '🔄 Starting periodic location updates to server (every 5 seconds)',
    );
    // Send location updates every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        // Cancel the timer if the widget is no longer mounted
        _locationUpdateTimer?.cancel();
        return;
      }
      
      if (_userLocation != null) {
        final locationUpdateMessage = {
          'type': 'USER_LOCATION',
          'bookingId': _bookingId,
          'latitude': _userLocation!.latitude,
          'longitude': _userLocation!.longitude,
          'userId': _userId,
          'userType': 'USER',
        };

        debugPrint('📤 Sending location update to server');
        _sendWebSocketMessage(locationUpdateMessage);
      } else {
        debugPrint('⚠️ Cannot send location update: user location is null');
      }
    });
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

    // Always add driver marker if location is available
    if (_driverLocation != null) {
      // Use current icon (either custom or default if custom failed)
      final driverIcon = _carIcon;
      
      debugPrint(
        '🚗 Adding driver marker at: ${_driverLocation!.latitude}, ${_driverLocation!.longitude} with bearing: $_driverBearing',
      );
      
      // Create the driver marker with custom icon
      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation!,
        icon: driverIcon,
        infoWindow: const InfoWindow(title: 'Driver'),
        visible: true, // Explicitly set to true
        zIndex: 2, // Ensure driver appears above other markers
        rotation: _driverBearing, // Apply the calculated bearing
        anchor: const Offset(0.5, 0.5), // Center the icon for rotation
        flat: true, // Make the marker flat on the map
      );
      
      // Add the marker to the set
      markers.add(driverMarker);
      
      debugPrint('✅ Driver marker added with custom icon');
    } else {
      debugPrint('⚠️ Driver location is null, cannot add driver marker');
    }

    // Add destination marker
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Update the markers in the state
    if (mounted) {
      setState(() {
        _markers = markers;
      });
      
      debugPrint('🗺️ Map now has ${markers.length} markers');
    }

    // Only update camera when necessary to prevent constant zooming
    if (!_isMapInitialized || _markers.isEmpty) {
      _updateCamera();
    }
  }

  void _updateRoute() async {
    if (_driverLocation == null || _userLocation == null) {
      debugPrint('⚠️ Cannot update route: missing locations');
      return;
    }

    debugPrint('🛣️ Updating route between driver and user');
    try {
      // Get route between driver and user location
      List<LatLng> points = await _getRoutePoints(
        _driverLocation!,
        _tripStarted
            ? (_destinationLocation ?? _userLocation!)
            : _userLocation!,
      );

      if (points.isEmpty) {
        debugPrint('⚠️ No route points returned, using fallback direct route');
        // Fallback to direct line if route calculation fails
        _createFallbackRoute();
        return;
      }

      // Calculate distance and ETA
      double distance = await _calculateRouteDistance(
        _driverLocation!,
        _tripStarted
            ? (_destinationLocation ?? _userLocation!)
            : _userLocation!,
      );

      int estimatedTimeInSeconds = _calculateETA(distance);
      String eta = _formatETA(estimatedTimeInSeconds);

      setState(() {
        _routePoints = points;
        _estimatedDistance = _formatDistance(distance);
        _estimatedTime = eta;

        // Enhanced polylines styling for professional look
        _polylines = {
          // Shadow/outline for the route (white, wider)
          Polyline(
            polylineId: const PolylineId('route_shadow'),
            points: points,
            color: Colors.white,
            width: 10, // Slightly wider for better shadow effect
            zIndex: 1, // Place below the main route
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
          // Main route (solid blue)
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF1A73E8), // Google Maps blue color
            width: 6, // Slightly wider for better visibility
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            zIndex: 2, // Place above the shadow
          ),
        };

        // Update driver ETA info
        _driverEta = '$_estimatedDistance away - $_estimatedTime';

        // Update the driver info text to include new ETA if we have driver info
        if (_driverInfo.isNotEmpty && !_driverInfo.startsWith("Connecting")) {
          _driverInfo =
              _driverInfo.split(" • ").take(2).join(" • ") + " • $_driverEta";
        }
      });

      debugPrint(
        '🛣️ Route updated: $_estimatedDistance, ETA: $_estimatedTime',
      );

      // Update camera to show the entire route
      _zoomToShowRoutePoints(points);
    } catch (e) {
      debugPrint('❌ Error updating route: $e');
      
      // Fallback to simple direct line if route calculation fails
      _createFallbackRoute();
    }
  }
  
  void _createFallbackRoute() {
    if (_driverLocation == null || _userLocation == null) return;
    
    debugPrint('⚠️ Creating fallback direct route');
    
    // Create a simple direct line between driver and user
    List<LatLng> points = [
      _driverLocation!,
      _tripStarted ? (_destinationLocation ?? _userLocation!) : _userLocation!,
    ];
    
    // Calculate direct distance
    double distance = _calculateDirectDistance(_driverLocation!, 
      _tripStarted ? (_destinationLocation ?? _userLocation!) : _userLocation!);
    
    setState(() {
      _routePoints = points;
      _estimatedDistance = _formatDistance(distance);
      _estimatedTime = _formatETA(_calculateETA(distance));
      
      // Enhanced polylines for fallback route
      _polylines = {
        // Shadow/outline
        Polyline(
          polylineId: const PolylineId('direct_route_shadow'),
          points: points,
          color: Colors.white,
          width: 10,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: 1,
        ),
        // Main route (dashed blue)
        Polyline(
          polylineId: const PolylineId('direct_route'),
          points: points,
          color: const Color(0xFF1A73E8), // Google Maps blue color
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: 2,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(5),
          ], // Dashed pattern for fallback route
        ),
      };
      
      // Update driver ETA info
      _driverEta = '$_estimatedDistance away - $_estimatedTime';
    });
    
    // Update camera to show both points
    _zoomToShowRoutePoints(points);
  }

  Future<List<LatLng>> _getRoutePoints(
    LatLng origin,
    LatLng destination,
  ) async {
    // Use Google Directions API to get route points
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$googleMapsApiKey';

    debugPrint('🌐 Requesting directions from Google API');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Decode the polyline points
          final List<LatLng> points = [];

          // Get route
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Get encoded polyline
          final polylinePoints = route['overview_polyline']['points'];
          points.addAll(_decodePolyline(polylinePoints));

          debugPrint(
            '🛣️ Got ${points.length} route points from Google Directions API',
          );
          return points;
        } else {
          debugPrint('⚠️ Google Directions API status: ${data['status']}');
          return [];
        }
      } else {
        debugPrint('⚠️ Google Directions API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching Google Directions: $e');
      return [];
    }
  }

  Future<double> _calculateRouteDistance(
    LatLng origin,
    LatLng destination,
  ) async {
    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=${origin.latitude},${origin.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            // Return distance in meters
            return element['distance']['value'].toDouble();
          }
        }
      }
      // Fallback: calculate direct distance if API fails
      return _calculateDirectDistance(origin, destination);
    } catch (e) {
      debugPrint('Error calculating route distance: $e');
      return _calculateDirectDistance(origin, destination);
    }
  }

  double _calculateDirectDistance(LatLng origin, LatLng destination) {
    // Calculate direct distance using the Haversine formula
    const double earthRadius = 6371000; // meters

    final double lat1 = origin.latitude * (pi / 180);
    final double lon1 = origin.longitude * (pi / 180);
    final double lat2 = destination.latitude * (pi / 180);
    final double lon2 = destination.longitude * (pi / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // distance in meters
  }

  int _calculateETA(double distanceInMeters) {
    // Calculate ETA in seconds based on average speed
    // Assuming an average speed of 30 km/h in urban areas
    const double averageSpeedKmH = 30.0; // km/h
    const double averageSpeedMS = averageSpeedKmH * 1000 / 3600; // m/s
    return (distanceInMeters / averageSpeedMS).round();
  }

  String _formatETA(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final int minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final int hours = (seconds / 3600).floor();
      final int minutes = ((seconds % 3600) / 60).round();
      return '$hours h $minutes min';
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

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

      final p = LatLng(lat / 1E5, lng / 1E5);
      points.add(p);
    }

    return points;
  }

  void _zoomToShowRoutePoints(List<LatLng> points) async {
    if (!_mapController.isCompleted || points.isEmpty) {
      return;
    }

    try {
      final controller = await _mapController.future;

      // Calculate bounds to include all route points
      double minLat = points[0].latitude;
      double maxLat = points[0].latitude;
      double minLng = points[0].longitude;
      double maxLng = points[0].longitude;

      for (final point in points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      // Add padding around the route
      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Use a smoother animation with less padding for better visibility
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 70),
      );
      debugPrint('🗺️ Camera updated to show route');
    } catch (e) {
      debugPrint('❌ Error updating camera: $e');
    }
  }

  void _updateCamera() async {
    if (!_mapController.isCompleted) {
      debugPrint('⚠️ Cannot update camera: map controller not initialized');
      return;
    }

    final controller = await _mapController.future;
    debugPrint('🔍 Updating camera position');

    // Collect all important points to show
    List<LatLng> points = [];
    if (_userLocation != null) points.add(_userLocation!);
    if (_driverLocation != null) points.add(_driverLocation!);
    if (_destinationLocation != null && _tripStarted) points.add(_destinationLocation!);

    // Only update camera if we have points to show
    if (points.length >= 2) {
      debugPrint('🗺️ Setting camera to show multiple points');
      
      // Calculate bounds to include all points with padding
      LatLngBounds bounds = _getBounds(points);
      
      // Add padding to ensure points aren't at the edge of the screen
      // Use a smoother animation for better user experience
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80), // Reduced padding for better view
      );
      _isMapInitialized = true;
    } else if (points.isNotEmpty) {
      debugPrint(
        '🗺️ Setting camera to single point: (${points.first.latitude},${points.first.longitude})',
      );

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: points.first,
            zoom: 16.0, // Higher zoom for better visibility of single point
            bearing: _driverBearing, // Align map with driver direction for better orientation
          ),
        ),
      );
      _isMapInitialized = true;
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (final point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _handleOtpSent(Map<String, dynamic> data) {
    final otp = data['otp'] ?? '------';
    debugPrint('🔢 OTP received: $otp');
    setState(() {
      // Clear the existing OTP first
      _otp = '';
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _otp = otp;
            _showOtp = true;
            _tripStatus = 'OTP Received';
          });
        }
      });
    });
  }

  void _handleTripStarted(Map<String, dynamic> data) {
    debugPrint('🚀 Trip started');
    setState(() {
      _tripStatus = 'Trip in Progress';
      _tripStarted = true;

      if (data['destination'] != null) {
        _destination = data['destination'];
        debugPrint('🏁 Destination set: $_destination');
      }

      if (data['destinationLatitude'] != null &&
          data['destinationLongitude'] != null) {
        final destLat = double.parse(data['destinationLatitude'].toString());
        final destLng = double.parse(data['destinationLongitude'].toString());
        debugPrint('📍 Destination coordinates: lat=$destLat, lng=$destLng');

        _destinationLocation = LatLng(destLat, destLng);
        _updateMapMarkers();
      }
    });
  }

  void _handleTripCompleted(Map<String, dynamic> data) {
    debugPrint('🏁 Trip completed');
    setState(() {
      _tripStatus = 'Trip Completed';
      _tripCompleted = true;
      _showFeedback = true;
      _showOtp = false;
    });
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
            zoom: 14.0,
          );
          _isLoading = false;
        });

        // Setup continuous location updates
        _setupLocationUpdates();
      } else {
        debugPrint('❌ Location permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing location: $e');
      setState(() {
        _locationError = 'Could not access location';
        _isLoading = false;
      });
    }
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

      // Only log significant changes to reduce console spam
      if (_userLocation == null ||
          (_userLocation!.latitude - lat!).abs() > 0.0001 ||
          (_userLocation!.longitude - lng!).abs() > 0.0001) {
        debugPrint('📍 User location updated: lat=$lat, lng=$lng');
      }

      setState(() {
        _userLocation = LatLng(lat!, lng!);
      });
      
      // Update markers with the new location
      _updateMapMarkers();
    });
  }

  // Generate a 6-digit OTP
  String _generateOTP() {
    final Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send message to WebSocket server
  void _sendMessage(String message) {
    if (_stompClient != null && _stompClient!.connected) {
      _stompClient!.send(
        destination: '/app/send-message',
        body: message,
        headers: {'content-type': 'application/json'},
      );
      debugPrint('📤 Sent message to server: $message');
    } else {
      debugPrint('❌ Cannot send message: WebSocket not connected');
    }
  }

  // Add a method to calculate bearing between two coordinates
  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    startLat = _degreesToRadians(startLat);
    startLng = _degreesToRadians(startLng);
    endLat = _degreesToRadians(endLat);
    endLng = _degreesToRadians(endLng);

    double dLong = endLng - startLng;

    double y = sin(dLong) * cos(endLat);
    double x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLong);

    double bearing = atan2(y, x);
    bearing = _radiansToDegrees(bearing);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  double _radiansToDegrees(double radians) {
    return radians * 180.0 / pi;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [const SizedBox(width: 8), const Text('Tracking')],
        ),
        backgroundColor: const Color(0xFF007BFF),
        actions: [
          if (_showOtp)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // Show OTP in a more visible dialog when tapped
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Verification OTP'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Show this code to your driver:'),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _otp,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OTP: $_otp',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Map - Only build when initialCameraPosition is available
            _initialCameraPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                  initialCameraPosition: _initialCameraPosition!,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, // Hide default button for cleaner UI
                  compassEnabled: false, // Hide compass for cleaner UI
                  markers: _markers,
                  polylines: _polylines,
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
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false, // Disable map toolbar for cleaner UI
                  minMaxZoomPreference: const MinMaxZoomPreference(8, 20), // Limit zoom levels for better UX
                ),
            // Booking ID and Status Badge
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Booking: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _bookingId,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBadgeColor(),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        _getStatusBadgeText(),
                        style: TextStyle(
                          color:
                              _shouldUseWhiteText()
                                  ? Colors.white
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child:
                    _showFeedback
                        ? _buildFeedbackPanel()
                        : _buildTrackingInfoPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInfoPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trip Details with Distance, ETA and Status
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.route,
                          iconColor: Colors.blue,
                          title: 'Distance',
                          value: _estimatedDistance,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.access_time,
                          iconColor: Colors.green,
                          title: 'ETA',
                          value: _estimatedTime,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.directions_car,
                          iconColor: Colors.orange,
                          title: 'Status',
                          value: _tripStatus,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Destination and Driver Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destination',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _destination,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Driver Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Driver',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (_tripStarted)
                                GestureDetector(
                                  onTap: () {
                                    _callDriver();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007BFF),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.phone,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Call',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            _driverInfo,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // OTP Display
          if (_showOtp)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your OTP Code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(
                    'Show this code to your driver for verification',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _otp,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeedbackPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Trip Feedback',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          const Text(
            'Rate your experience',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Rating Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _userRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () {
                  setState(() => _userRating = index + 1);
                },
              );
            }),
          ),

          const SizedBox(height: 16),

          // Comments Field
          TextField(
            controller: _feedbackController,
            decoration: InputDecoration(
              hintText: 'Share your experience',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_userRating == 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
                  return;
                }

                // Send feedback to the server
                final feedbackMessage = {
                  'type': 'FEEDBACK',
                  'bookingId': _bookingId,
                  'userId': _userId,
                  'rating': _userRating,
                  'comment': _feedbackController.text,
                };

                debugPrint(
                  '⭐ Submitting feedback: rating=$_userRating, comment=${_feedbackController.text}',
                );
                _sendWebSocketMessage(feedbackMessage);

                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );

                setState(() => _showFeedback = false);

                // Navigate back to previous screen
                debugPrint('🔙 Returning to previous screen after feedback');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.send),
                  SizedBox(width: 8),
                  Text('Submit Feedback'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBadgeColor() {
    switch (_tripStatus) {
      case 'OTP Received':
      case 'Final Verification':
        return const Color(0xFFFFC107); // amber
      case 'OTP Verified':
        return const Color(0xFF28A745); // green
      case 'Trip in Progress':
        return const Color(0xFF007BFF); // blue
      case 'Trip Completed':
        return const Color(0xFF6C757D); // gray
      default:
        return const Color(0xFFE9ECEF); // light gray
    }
  }

  String _getStatusBadgeText() {
    switch (_tripStatus) {
      case 'OTP Received':
        return 'OTP Received';
      case 'OTP Verified':
        return 'OTP Verified';
      case 'Trip in Progress':
        return 'Trip In Progress';
      case 'Trip Completed':
        return 'Trip Completed';
      case 'Final Verification':
        return 'Final Verification';
      default:
        return 'Waiting for driver';
    }
  }

  bool _shouldUseWhiteText() {
    // Use white text for dark backgrounds
    return _tripStatus == 'OTP Verified' ||
        _tripStatus == 'Trip in Progress' ||
        _tripStatus == 'Trip Completed';
  }

  void _callDriver() async {
    // This would typically use a phone number from the WebSocket data
    String driverPhone = '+1234567890'; // Placeholder, should come from API
    try {
      await launchUrlString('tel:$driverPhone');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  @override
  void dispose() {
    // Cancel timers and close connections
    _locationUpdateTimer?.cancel();
    _stompClient?.deactivate();
    super.dispose();
  }
}
