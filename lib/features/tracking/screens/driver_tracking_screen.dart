import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';  
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

class DriverTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const DriverTrackingScreen({super.key, required this.bookingData});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with SingleTickerProviderStateMixin {
  // Google Maps controller
  final Completer<GoogleMapController> _mapController = Completer();

  // Initial camera position (will be updated with driver's location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(18.5619, 73.9447),
    zoom: 14.0,
  );

  // Location data
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;

  // Route data
  List<LatLng> _driverToPickupRoute = [];
  List<LatLng> _pickupToDestinationRoute = [];

  // Trip info
  String _pickup = '';
  String _destination = '';
  String _distance = 'Calculating...';
  String _duration = 'Calculating...';
  String _bookingId = '';
  Map<String, dynamic> _passengerInfo = {};
  Map<String, dynamic> _tripInfo = {};

  // State variables
  bool _isLoading = true;
  bool _isFetchingRoute = false;
  String _statusMessage = 'Heading to pickup';
  bool _arrivedAtPickup = false;
  bool _tripStarted = false;
  String? _locationError;

  // Odometer and OTP state
  bool _showOdometerModal = false;
  bool _showOtpModal = false;
  String _startOdometer = '';
  String _endOdometer = '';
  String _otp = '';
  String _generatedOtp = '';
  bool _isCompletingTrip = false;
  Map<String, dynamic>? _tripSummary;
  bool _showTripSummary = false;

  // Animation controller for notifications
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  // Location update timer
  Timer? _locationUpdateTimer;
  bool isConnected = false;

  // Controllers and references
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _finalOtpController = TextEditingController();
  final TextEditingController _startOdometerController =
      TextEditingController();
  final TextEditingController _endOdometerController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Location and map state
  final Location _location = Location();
  LatLng? _userLocation;
  bool isMapInitialized = false;

  // Map markers
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Booking data
  late String bookingId;
  late String driverId;

  // Trip info
  String _tripStatus = "Waiting";

  // UI State for workflow steps
  bool _showStartOdometerInput = true;
  bool _showSendOtpButton = false;
  bool _showOtpVerification = false;
  bool _showDestinationInput = false;
  bool _showEndTripButton = false;
  bool _showEndOdometerInput = false;
  bool _showFinalOtpVerification = false;

  // Destination
  String predefinedDestination = "";
  double? destinationLat;
  double? destinationLng;

  // WebSocket config
  final String _websocketUrl = "https://api.worldtriplink.com/ws-trip-tracking/";
  StompClient? _stompClient;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  // Add car icon fields
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueRed,
  );
  double _driverBearing = 0.0; // Track driver heading/bearing
  bool _isCarIconLoaded = false; // Track if car icon is loaded

  // Add these new class variables to store the last successful route
  List<LatLng> _lastSuccessfulRoutePoints = [];
  String _lastRouteOrigin = "";
  String _lastRouteDestination = "";

  @override
  void initState() {
    super.initState();
    _initialize();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Create custom car icon immediately
    _createCustomCarIcon();
  }

  Future<void> _createCustomCarIcon() async {
    debugPrint('🚗 Creating custom car icon');
    try {
      // Set default icon first as fallback
      setState(() {
        _carIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        );
      });

      // Create a custom car icon using canvas
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Paint paint = Paint()..color = Colors.red; // Red car color

      // Draw a car shape (simplified car icon)
      final double size = 60.0; // Increased size
      final Rect rect = Rect.fromLTWH(0, 0, size, size);

      // Car body
      final RRect carBody = RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 10, size - 10, size - 15),
        const Radius.circular(4.0),
      );
      canvas.drawRRect(carBody, paint);

      // Car roof
      final Path roofPath =
          Path()
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
      final ByteData? byteData = await img.toByteData(
        format: ui.ImageByteFormat.png,
      );

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
      debugPrint('❌ Error creating custom car icon: $e');
    }
  }

  void _initialize() async {
    // Extract booking data
    bookingId = widget.bookingData['bookingId'] ?? '';
    driverId = widget.bookingData['driverId'] ?? '';

    debugPrint(
      '🚗 Initializing driver tracking for booking: $bookingId, driver: $driverId',
    );

    // Extract destination if available
    if (widget.bookingData.containsKey('destination')) {
      predefinedDestination = widget.bookingData['destination'] ?? '';
      _destinationController.text = predefinedDestination;
      destinationLat = widget.bookingData['destinationLat'];
      destinationLng = widget.bookingData['destinationLng'];

      if (destinationLat != null && destinationLng != null) {
        _destinationLocation = LatLng(destinationLat!, destinationLng!);
      }
    }

    // Initialize location
    _initializeLocation();

    // Connect to WebSocket
    _connectStompWebSocket();
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
          stompConnectHeaders: {
            'bookingId': bookingId,
            'userId': driverId,
            'userType': 'DRIVER',
          },
          webSocketConnectHeaders: {
            'bookingId': bookingId,
            'userId': driverId,
            'userType': 'DRIVER',
          },
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

    // Subscribe to user location updates
    _stompClient?.subscribe(
      destination: '/topic/booking/$bookingId/user-location',
      callback: (frame) {
        debugPrint('📥 Received user location update: ${frame.body}');
        if (frame.body != null) {
          _handleWebSocketMessage(frame.body!);
        }
      },
    );

    // Subscribe to driver notifications
    _stompClient?.subscribe(
      destination: '/topic/booking/$bookingId/driver-notifications',
      callback: (frame) {
        debugPrint('📥 Received driver notification: ${frame.body}');
        if (frame.body != null) {
          _handleWebSocketMessage(frame.body!);
        }
      },
    );

    // Notify about connection
    _sendConnectionMessage();

    // Start sending location updates
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Connection lost. Reconnecting in $delay seconds...'),
        //   ),
        // );
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
      'bookingId': bookingId,
      'userId': driverId,
      'userType': 'DRIVER',
    };

    _sendWebSocketMessage(connectMessage);
  }

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_stompClient != null && _stompClient!.connected) {
      try {
        final jsonMessage = jsonEncode(message);
        debugPrint('📤 Sending message: $jsonMessage');

        // Use the correct destination path based on message type
        String destination = '/app/driver-location';

        if (message['type'] == 'CONNECT') {
          destination = '/app/connect';
        } else if (message['type'] == 'SEND_OTP') {
          destination = '/app/send-otp';
        } else if (message['type'] == 'VERIFY_OTP') {
          destination = '/app/verify-otp';
        } else if (message['type'] == 'START_TRIP') {
          destination = '/app/start-trip';
        } else if (message['type'] == 'END_TRIP') {
          destination = '/app/end-trip';
        } else if (message['type'] == 'REQUEST_FINAL_OTP') {
          destination = '/app/send-otp';
        } else if (message['type'] == 'VERIFY_FINAL_OTP') {
          destination = '/app/end-trip';
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

      // Check if this is a user location update (may not have explicit type)
      if (data['userType'] == 'USER' &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        _handleUserLocationUpdate(data);
        return;
      }

      switch (messageType) {
        case "USER_LOCATION":
          _handleUserLocationUpdate(data);
          break;
        case "OTP_SENT":
          setState(() {
            _tripStatus = "OTP sent to user";
          });
          break;
        case "OTP_VERIFIED":
          _handleOtpVerified();
          break;
        case "TRIP_STARTED":
          _handleTripStarted(data);
          break;
        case "FINAL_OTP_VERIFIED":
          _handleFinalOtpVerified(data);
          break;
        case "FINAL_OTP_INVALID":
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The final OTP verification failed. Please try again.',
              ),
            ),
          );
          setState(() {
            _showFinalOtpVerification = false;
            _showEndOdometerInput = true;
            _tripStatus = "Final OTP validation failed";
          });
          break;
        default:
          debugPrint('⚠️ Unknown message type: $messageType');
      }
    } catch (e) {
      debugPrint('❌ Error processing WebSocket message: $e');
      debugPrint('📄 Raw message that caused the error: $message');
    }
  }

  void _handleUserLocationUpdate(Map<String, dynamic> data) {
    try {
      // Extract latitude and longitude from the data
      double lat = 0.0;
      double lng = 0.0;

      // Handle different possible formats of latitude/longitude in the message
      if (data['latitude'] != null) {
        lat =
            data['latitude'] is double
                ? data['latitude']
                : double.tryParse(data['latitude'].toString()) ?? 0.0;
      }

      if (data['longitude'] != null) {
        lng =
            data['longitude'] is double
                ? data['longitude']
                : double.tryParse(data['longitude'].toString()) ?? 0.0;
      }

      // Only update if we have valid coordinates
      if (lat != 0.0 && lng != 0.0) {
        debugPrint('📍 User location updated: $lat, $lng');

        if (mounted) {
          setState(() {
            _userLocation = LatLng(lat, lng);
          });

          // Update markers and route with the new location
          _updateMapMarkers();
        }
      } else {
        debugPrint('⚠️ Invalid user location data: $data');
      }
    } catch (e) {
      debugPrint('❌ Error processing user location update: $e');
    }
  }

  void _updateMapMarkers() {
    Set<Marker> markers = {};

    // Add driver marker
    if (_driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: _carIcon,
          infoWindow: const InfoWindow(title: 'You (Driver)'),
          rotation: _driverBearing, // Apply the calculated bearing
          anchor: const Offset(0.5, 0.5), // Center the icon for rotation
          flat: true, // Make the marker flat on the map
          zIndex: 2, // Ensure driver appears above other markers
        ),
      );
    }

    // Add user marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'User'),
        ),
      );
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

    setState(() {
      _markers = markers;
    });

    // Update camera position
    _updateCameraToShowPoints(
      _markers.map((marker) => marker.position).toList(),
    );

    // Update route if we have both driver and user locations
    _updateRoute();
  }

  void _updateRoute() {
    // Skip route updates if we're completing a trip
    if (_isCompletingTrip) {
      debugPrint('ℹ️ Trip is completing, skipping route update');
      return;
    }

    if (_driverLocation == null) {
      debugPrint('⚠️ Cannot update route: driver location is missing');
      return;
    }

    // Determine target location - use destination if in trip, otherwise use user location
    LatLng? target;
    if (_tripStarted && _destinationLocation != null) {
      target = _destinationLocation;
      debugPrint(
        '🎯 Target set to destination: ${_destinationLocation!.latitude}, ${_destinationLocation!.longitude}',
      );
    } else if (_userLocation != null) {
      target = _userLocation;
      debugPrint(
        '🎯 Target set to user location: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
      );
    }

    // If no target, we can't draw a route
    if (target == null) {
      debugPrint('⚠️ Cannot update route: target location is missing');
      return;
    }

    // Check if the driver and target are the same location (within a small threshold)
    double distanceToTarget = _calculateDirectDistance(
      _driverLocation!,
      target,
    );
    if (distanceToTarget < 10) {
      // Less than 10 meters
      debugPrint('ℹ️ Driver is very close to target, no need to update route');

      if (mounted) {
        setState(() {
          // Update status message to reflect arrival
          if (!_tripStarted) {
            _statusMessage = 'Arrived at pickup point';
            _arrivedAtPickup = true;
          } else {
            _statusMessage = 'Arrived at destination';
          }
          _distance = '0 m';
          _duration = '0 min';
        });
      }
      return;
    }

    debugPrint(
      '🛣️ Updating route between driver and ${_tripStarted ? "destination" : "user"}',
    );

    // Create a polyline between driver and target
    Set<Polyline> polylines = {};

    // Add the polyline with enhanced styling
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: [_driverLocation!, target],
        color: Colors.white,
        width: 10, // Wider for shadow effect
        zIndex: 1,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_driverLocation!, target],
        color: const Color(0xFF1A73E8), // Google Maps blue
        width: 6,
        zIndex: 2,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );

    // Calculate distance and ETA
    double distanceInMeters = _calculateDirectDistance(
      _driverLocation!,
      target,
    );
    int estimatedTimeInSeconds = _calculateETA(distanceInMeters);

    if (mounted) {
      setState(() {
        _polylines = polylines;
        _distance = _formatDistance(distanceInMeters);
        _duration = _formatETA(estimatedTimeInSeconds);

        // Update status message based on trip state
        if (!_tripStarted) {
          _statusMessage =
              'To pickup: ${_formatDistance(distanceInMeters)} - ${_formatETA(estimatedTimeInSeconds)}';
        } else {
          _statusMessage =
              'To destination: ${_formatDistance(distanceInMeters)} - ${_formatETA(estimatedTimeInSeconds)}';
        }
      });
    }

    debugPrint('🛣️ Route updated: $_distance, ETA: $_duration');

    // Only try to get a better route if we're more than 50 meters away
    // This prevents excessive API calls when close to the destination
    if (distanceInMeters > 50) {
      // Try to get a better route using Google Directions API
      _getRouteFromGoogleDirections(_driverLocation!, target);
    } else {
      debugPrint(
        'ℹ️ Skipping Google Directions API call, driver is close to target',
      );
    }
  }

  Future<void> _getRouteFromGoogleDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    if (!mounted) return;

    // Skip if we're completing a trip
    if (_isCompletingTrip) {
      debugPrint('ℹ️ Trip is completing, skipping route update');
      return;
    }

    // Set a flag to avoid multiple simultaneous route requests
    if (_isFetchingRoute) {
      debugPrint('⚠️ Already fetching route, skipping this request');
      return;
    }

    // Check if we already have a route for this origin-destination pair
    String originKey =
        "${origin.latitude.toStringAsFixed(5)},${origin.longitude.toStringAsFixed(5)}";
    String destinationKey =
        "${destination.latitude.toStringAsFixed(5)},${destination.longitude.toStringAsFixed(5)}";

    // If we have a cached route for this exact origin-destination pair, use it
    if (_lastSuccessfulRoutePoints.isNotEmpty &&
        originKey == _lastRouteOrigin &&
        destinationKey == _lastRouteDestination) {
      debugPrint(
        'ℹ️ Using cached route (${_lastSuccessfulRoutePoints.length} points)',
      );

      if (mounted) {
        setState(() {
          // Update polylines with the cached route
          _polylines = {
            // Shadow/outline for the route (white, wider)
            Polyline(
              polylineId: const PolylineId('route_shadow'),
              points: _lastSuccessfulRoutePoints,
              color: Colors.white,
              width: 10,
              zIndex: 1,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
            // Main route (solid blue)
            Polyline(
              polylineId: const PolylineId('route'),
              points: _lastSuccessfulRoutePoints,
              color: const Color(0xFF1A73E8), // Google Maps blue
              width: 6,
              zIndex: 2,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };
        });
        return;
      }
    }

    setState(() {
      _isFetchingRoute = true;
    });

    try {
      debugPrint('🌐 Requesting directions from Google API');
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$googleMapsApiKey';

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Google Directions API request timed out');
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Get route
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Get distance and duration from API
          final distanceText = leg['distance']['text'];
          final durationText = leg['duration']['text'];

          // Get encoded polyline
          final polylinePoints = route['overview_polyline']['points'];
          final List<LatLng> points = _decodePolyline(polylinePoints);

          if (points.isNotEmpty && mounted) {
            debugPrint(
              '✅ Got route from Google Directions API: ${points.length} points',
            );

            // Cache this successful route
            _lastSuccessfulRoutePoints = List.from(points);
            _lastRouteOrigin = originKey;
            _lastRouteDestination = destinationKey;

            setState(() {
              // Update with more accurate distance and time
              _distance = distanceText;
              _duration = durationText;

              // Update status message
              if (!_tripStarted) {
                _statusMessage = 'To pickup: $distanceText - $durationText';
              } else {
                _statusMessage =
                    'To destination: $distanceText - $durationText';
              }

              // Update polylines with the actual route
              _polylines = {
                // Shadow/outline for the route (white, wider)
                Polyline(
                  polylineId: const PolylineId('route_shadow'),
                  points: points,
                  color: Colors.white,
                  width: 10,
                  zIndex: 1,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                ),
                // Main route (solid blue)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: points,
                  color: const Color(0xFF1A73E8), // Google Maps blue
                  width: 6,
                  zIndex: 2,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                ),
              };

              _isFetchingRoute = false;
            });

            // Update camera to show the route
            _updateCameraToShowPoints(points);
          }
        } else {
          debugPrint('⚠️ Google Directions API status: ${data['status']}');

          // If API call fails but we have a previous route, use that
          if (_lastSuccessfulRoutePoints.isNotEmpty && mounted) {
            debugPrint('ℹ️ Using last successful route as fallback');
            setState(() {
              _polylines = {
                // Shadow/outline for the route (white, wider)
                Polyline(
                  polylineId: const PolylineId('route_shadow'),
                  points: _lastSuccessfulRoutePoints,
                  color: Colors.white,
                  width: 10,
                  zIndex: 1,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                ),
                // Main route (solid blue)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _lastSuccessfulRoutePoints,
                  color: const Color(0xFF1A73E8), // Google Maps blue
                  width: 6,
                  zIndex: 2,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                ),
              };
              _isFetchingRoute = false;
            });
          } else {
            // If no previous route, keep the straight line
            if (mounted) {
              setState(() {
                _isFetchingRoute = false;
              });
            }
          }
        }
      } else {
        debugPrint('⚠️ Google Directions API error: ${response.statusCode}');

        // If HTTP error but we have a previous route, use that
        if (_lastSuccessfulRoutePoints.isNotEmpty && mounted) {
          debugPrint(
            'ℹ️ Using last successful route as fallback after HTTP error',
          );
          setState(() {
            _polylines = {
              // Shadow/outline for the route (white, wider)
              Polyline(
                polylineId: const PolylineId('route_shadow'),
                points: _lastSuccessfulRoutePoints,
                color: Colors.white,
                width: 10,
                zIndex: 1,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
              // Main route (solid blue)
              Polyline(
                polylineId: const PolylineId('route'),
                points: _lastSuccessfulRoutePoints,
                color: const Color(0xFF1A73E8), // Google Maps blue
                width: 6,
                zIndex: 2,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
            };
            _isFetchingRoute = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _isFetchingRoute = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching Google Directions: $e');

      // If we catch an exception but have a previous route, use that
      if (_lastSuccessfulRoutePoints.isNotEmpty && mounted) {
        debugPrint('ℹ️ Using last successful route as fallback after error');
        setState(() {
          _polylines = {
            // Shadow/outline for the route (white, wider)
            Polyline(
              polylineId: const PolylineId('route_shadow'),
              points: _lastSuccessfulRoutePoints,
              color: Colors.white,
              width: 10,
              zIndex: 1,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
            // Main route (solid blue)
            Polyline(
              polylineId: const PolylineId('route'),
              points: _lastSuccessfulRoutePoints,
              color: const Color(0xFF1A73E8), // Google Maps blue
              width: 6,
              zIndex: 2,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            ),
          };
          _isFetchingRoute = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isFetchingRoute = false;
          });
        }
      }
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

  void _updateCameraToShowPoints(List<LatLng> points) async {
    if (!_mapController.isCompleted || points.isEmpty) return;

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
      final latPadding = (maxLat - minLat) * 0.25;
      final lngPadding = (maxLng - minLng) * 0.25;

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      // Determine if this is a significant change that warrants camera movement
      bool isSignificantChange = !isMapInitialized;

      if (!isSignificantChange && _driverLocation != null) {
        // Check if driver has moved significantly (more than 100 meters)
        final lastPoint = points.last;
        final distance = _calculateDirectDistance(_driverLocation!, lastPoint);
        isSignificantChange = distance > 100;
      }

      if (isSignificantChange) {
        // For initial or significant changes, animate camera
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
        isMapInitialized = true;
      } else {
        // For minor updates, use moveCamera to avoid jitter
        controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      debugPrint('❌ Error updating camera: $e');
    }
  }

  void _initializeLocation() async {
    try {
      await _requestLocationPermission();

      final locationData = await _location.getLocation();
      setState(() {
        _driverLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _isLoading = false;
      });

      // Setup continuous location updates
      _setupLocationUpdates();
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() => _locationError = 'Location permission denied');
    }
  }

  void _setupLocationUpdates() {
    _location.onLocationChanged.listen((locationData) {
      if (!mounted) return;

      // Calculate bearing if we have the previous location
      if (_driverLocation != null) {
        final newLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        _driverBearing = _calculateBearing(
          _driverLocation!.latitude,
          _driverLocation!.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );
        debugPrint('🧭 Driver bearing: $_driverBearing degrees');
      }

      setState(() {
        _driverLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _updateMapMarkers();
      });
    });
  }

  void _startLocationUpdates() {
    // Send location updates every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_driverLocation != null) {
        _sendWebSocketMessage({
          'type': 'DRIVER_LOCATION',
          'bookingId': bookingId,
          'latitude': _driverLocation!.latitude,
          'longitude': _driverLocation!.longitude,
          'userId': driverId,
          'userType': 'DRIVER',
        });
      }
    });
  }

  void _recordStartOdometer() async {
    final startOdometer = _startOdometerController.text.trim();

    if (startOdometer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the starting odometer reading'),
        ),
      );
      return;
    }

    // Store odometer value
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('startOdometer', startOdometer);

    setState(() {
      _showStartOdometerInput = false;
      _showSendOtpButton = true;
      _tripStatus = 'Odometer recorded';
    });
  }

  void _sendOtp() {
    setState(() {
      _tripStatus = 'Sending OTP...';
    });

    // Send OTP request to server
    _sendWebSocketMessage({
      'type': 'SEND_OTP',
      'bookingId': bookingId,
      'action': 'SEND_OTP',
      'driverId': driverId,
    });

    setState(() {
      _showSendOtpButton = false;
      _showOtpVerification = true;
      _tripStatus = 'OTP sent to user';
    });

    // Show a message
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP sent to user')));
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP from the user'),
        ),
      );
      return;
    }

    setState(() {
      _tripStatus = 'Verifying OTP...';
    });

    // Send verification request
    _sendWebSocketMessage({
      'type': 'VERIFY_OTP',
      'bookingId': bookingId,
      'action': 'VERIFY_OTP',
      'otp': otp,
      'driverId': driverId,
    });
  }

  void _startTrip() async {
    final destination =
        predefinedDestination.isNotEmpty
            ? predefinedDestination
            : _destinationController.text.trim();

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the destination')),
      );
      return;
    }

    // Get stored odometer value
    final prefs = await SharedPreferences.getInstance();
    final startOdometer = prefs.getString('startOdometer') ?? '0';

    // If we don't have destination coordinates, try to get them
    if ((destinationLat == null || destinationLng == null) &&
        destination.isNotEmpty) {
      try {
        // This would be a call to get coordinates from the destination name
        // For now, we'll use a placeholder
        destinationLat = 18.5204;
        destinationLng = 73.8567;
      } catch (e) {
        debugPrint('❌ Error getting destination coordinates: $e');
      }
    }

    setState(() {
      _tripStatus = 'Starting trip...';
    });

    // Clear any cached routes since we're starting a new trip
    _lastSuccessfulRoutePoints = [];
    _lastRouteOrigin = "";
    _lastRouteDestination = "";

    // Send trip start message
    _sendWebSocketMessage({
      'type': 'START_TRIP',
      'bookingId': bookingId,
      'action': 'START_TRIP',
      'driverId': driverId,
      'destination': destination,
      'startOdometer': startOdometer,
      'destinationLatitude': destinationLat,
      'destinationLongitude': destinationLng,
    });
  }

  void _endTrip() {
    setState(() {
      _showEndTripButton = false;
      _showEndOdometerInput = true;

      // Clear any cached routes since we're ending the trip
      _lastSuccessfulRoutePoints = [];
      _lastRouteOrigin = "";
      _lastRouteDestination = "";
    });
  }

  void _recordEndOdometer() async {
    final endOdometer = _endOdometerController.text.trim();

    if (endOdometer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the ending odometer reading'),
        ),
      );
      return;
    }

    // Store end odometer value
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('endOdometer', endOdometer);

    setState(() {
      _tripStatus = 'Requesting final verification...';
      _showEndOdometerInput = false;
      _showFinalOtpVerification = true;
    });

    // Request final OTP
    _sendWebSocketMessage({
      'type': 'REQUEST_FINAL_OTP',
      'bookingId': bookingId,
      'action': 'REQUEST_FINAL_OTP',
      'driverId': driverId,
    });
  }

  void _verifyFinalOtp() async {
    final finalOtp = _finalOtpController.text.trim();

    if (finalOtp.isEmpty || finalOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit final OTP from the user'),
        ),
      );
      return;
    }

    // Get the stored odometer readings
    final prefs = await SharedPreferences.getInstance();
    final startOdometer = prefs.getString('startOdometer') ?? '0';
    final endOdometer = prefs.getString('endOdometer') ?? '0';

    setState(() {
      _tripStatus = 'Completing trip...';
    });

    // Send final verification request
    _sendWebSocketMessage({
      'type': 'VERIFY_FINAL_OTP',
      'bookingId': bookingId,
      'action': 'END_TRIP',
      'otp': finalOtp,
      'startOdometer': double.parse(startOdometer),
      'endOdometer': double.parse(endOdometer),
      'driverId': driverId,
    });
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

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _animationController.dispose();
    _otpController.dispose();
    _finalOtpController.dispose();
    _startOdometerController.dispose();
    _endOdometerController.dispose();
    _destinationController.dispose();

    // Clear map controller resources
    _mapController.future
        .then((controller) {
          controller.dispose();
        })
        .catchError((e) {
          debugPrint('Error disposing map controller: $e');
        });

    if (_stompClient != null) {
      debugPrint('🔌 Closing STOMP WebSocket connection');
      _stompClient!.deactivate();
    }

    super.dispose();
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
        title: const Padding(
          padding: EdgeInsets.only(left: 70),
          child: Text('Driver Tracking'),
        ),
        backgroundColor: const Color(0xFF002B80),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: _getTripStatusColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusBadgeText(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        _shouldUseWhiteText() ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
              _updateMapMarkers();
            },
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(8, 20),
          ),

          // Booking ID and Status Badge
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF002B80).withOpacity(0.9),
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
                          fontSize: 13
                        ),
                      ),
                      Text(
                        bookingId,
                        style: const TextStyle(color: Colors.white,fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getTripStatusColor(),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _tripStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Route Information Card
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Colors.blue[700],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.green[700],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _duration,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.route,
                            color: Colors.orange[700],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _distance,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_tripStarted && _destination.isNotEmpty) ...[
                    const Divider(height: 16, thickness: 0.5),
                    Row(
                      children: [
                        Icon(Icons.place, color: Colors.red[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _destination,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Trip Summary (if completed)
          if (_showTripSummary)
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start Odometer: ${_tripSummary?['startOdometer']} km',
                    ),
                    Text('End Odometer: ${_tripSummary?['endOdometer']} km'),
                    Text('Distance Traveled: ${_tripSummary?['distance']}'),
                    Text('Fare: ${_tripSummary?['fare']}'),
                    Text('Duration: ${_tripSummary?['duration']}'),
                  ],
                ),
              ),
            ),

          // Driver Control Panel
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Driver Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Start Odometer Input
                  if (_showStartOdometerInput) ...[
                    const Text(
                      'Step 1: Enter Starting Odometer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _startOdometerController,
                      decoration: const InputDecoration(
                        labelText: 'Start Odometer (km)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _recordStartOdometer,
                      icon: const Icon(Icons.check),
                      label: const Text('Record Start Reading'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],

                  // Send OTP Button
                  if (_showSendOtpButton) ...[
                    const Text(
                      'Step 2: Send OTP to User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _sendOtp,
                      icon: const Icon(Icons.send),
                      label: const Text('Send OTP to User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],

                  // OTP Verification
                  if (_showOtpVerification) ...[
                    const Text(
                      'Step 3: Verify OTP from User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-digit OTP from user',
                        border: OutlineInputBorder(),
                        hintText: 'Enter the 6-digit OTP shown by user',
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 20, letterSpacing: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _verifyOtp,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Verify OTP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],

                  // Set Destination
                  if (_showDestinationInput) ...[
                    const Text(
                      'Step 4: Set Destination',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(),
                        hintText: 'Enter destination',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _startTrip,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],

                  // End Trip Button
                  if (_showEndTripButton)
                    ElevatedButton.icon(
                      onPressed: _endTrip,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text('End Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                  // End Odometer Input
                  if (_showEndOdometerInput) ...[
                    const Text(
                      'Step 5: End Trip',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _endOdometerController,
                      decoration: const InputDecoration(
                        labelText: 'End Odometer (km)',
                        border: OutlineInputBorder(),
                        hintText: 'Enter final odometer reading',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _recordEndOdometer,
                      icon: const Icon(Icons.check),
                      label: const Text('Record End Reading'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],

                  // Verify Final OTP Button
                  if (_showFinalOtpVerification) ...[
                    const Text(
                      'Step 6: Final OTP Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _finalOtpController,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-digit Final OTP from user',
                        border: OutlineInputBorder(),
                        hintText: 'Enter the 6-digit final OTP shown by user',
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 20, letterSpacing: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _verifyFinalOtp,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Complete Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTripStatusColor() {
    switch (_tripStatus) {
      case 'OTP sent to user':
      case 'Waiting for final verification':
        return Colors.orange;
      case 'OTP verified':
        return Colors.green;
      case 'Trip in progress':
        return Colors.blue;
      case 'Trip completed':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  String _getStatusBadgeText() {
    switch (_tripStatus) {
      case 'OTP sent to user':
        return 'OTP Sent';
      case 'OTP verified':
        return 'OTP Verified';
      case 'Trip in progress':
        return 'Trip In Progress';
      case 'Trip completed':
        return 'Trip Completed';
      case 'Verifying OTP...':
        return 'Verifying OTP';
      case 'Waiting for final verification':
        return 'Final Verification';
      default:
        return _tripStatus;
    }
  }

  bool _shouldUseWhiteText() {
    // Use white text for dark backgrounds
    return _tripStatus == 'OTP verified' ||
        _tripStatus == 'Trip in progress' ||
        _tripStatus == 'Trip completed';
  }

  void _handleOtpVerified() {
    setState(() {
      _tripStatus = 'OTP verified';
      _showOtpVerification = false;

      // Check if we should show destination input or go directly to trip in progress
      if (predefinedDestination.isNotEmpty &&
          destinationLat != null &&
          destinationLng != null) {
        _startTrip();
      } else {
        _showDestinationInput = true;
      }
    });
  }

  void _handleTripStarted(Map<String, dynamic> data) {
    setState(() {
      _tripStatus = 'Trip in progress';
      _showDestinationInput = false;
      _showEndTripButton = true;
      _tripStarted = true;

      // Update destination text if available
      if (data['destination'] != null) {
        _destination = data['destination'].toString();
      }

      if (data['destinationLatitude'] != null &&
          data['destinationLongitude'] != null) {
        try {
          double destLat =
              data['destinationLatitude'] is double
                  ? data['destinationLatitude']
                  : double.parse(data['destinationLatitude'].toString());

          double destLng =
              data['destinationLongitude'] is double
                  ? data['destinationLongitude']
                  : double.parse(data['destinationLongitude'].toString());

          _destinationLocation = LatLng(destLat, destLng);
          debugPrint('✅ Destination set to: $destLat, $destLng');

          // Clear any cached routes since we're changing destinations
          _lastSuccessfulRoutePoints = [];
          _lastRouteOrigin = "";
          _lastRouteDestination = "";

          // Force update markers
          _updateMapMarkers();

          // Force update route with a small delay to ensure markers are updated first
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _updateRoute();
            }
          });
        } catch (e) {
          debugPrint('❌ Error parsing destination coordinates: $e');
        }
      }
    });
  }

  void _handleFinalOtpVerified(Map<String, dynamic> data) {
    // Close any open OTP popups/dialogs first
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      return route.isFirst;
    });

    SharedPreferences.getInstance().then((prefs) {
      final startOdometer = prefs.getString('startOdometer') ?? '0';
      final endOdometer = prefs.getString('endOdometer') ?? '0';

      setState(() {
        _tripStatus = 'Trip completed';
        _showFinalOtpVerification = false;
        _tripStarted = false; // Mark trip as not started anymore
        _isCompletingTrip = true;

        // Clear route, destination, and markers
        _polylines = {};
        _destinationLocation = null;
        _markers = {}; // Clear all markers

        // Only keep driver marker
        if (_driverLocation != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: _driverLocation!,
              icon: _carIcon,
              infoWindow: const InfoWindow(title: 'You (Driver)'),
              rotation: _driverBearing,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              zIndex: 2,
            ),
          );
        }

        // Show a trip summary
        _tripSummary = {
          'startOdometer': startOdometer,
          'endOdometer': endOdometer,
          'distance':
              '${(double.parse(endOdometer) - double.parse(startOdometer)).toStringAsFixed(1)} km',
          'fare':
              '₹${((double.parse(endOdometer) - double.parse(startOdometer)) * 10).toStringAsFixed(0)}',
          'duration': data['tripDuration'] ?? 'Not available',
        };
        _showTripSummary = true;

        // Update status message
        _statusMessage = 'Trip completed';
        _distance = '0 m';
        _duration = '0 min';
      });

      // Reset the map camera to focus on driver's current location
      _mapController.future.then((controller) {
        if (_driverLocation != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_driverLocation!, 15),
          );
        }
      });
    });
  }

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
}
