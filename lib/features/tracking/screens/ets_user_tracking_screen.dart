import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String googleMapsApiKey = "AIzaSyAKjmBSUJ3XR8uD10vG2ptzqLJAZnOlzqI";
const String baseUrl = "https://ets.worldtriplink.com";

const Color primaryColor = Color(0xFF3F51B5); // Blue


class ETSUserTrackingScreen extends StatefulWidget {
  final int? slotId;
  final String? pickupLocationText;
  final String? dropLocationText;
  final String? userId;
  final LatLng? pickupCoordinates;
  final LatLng? dropCoordinates;

  const ETSUserTrackingScreen({
    super.key,
    this.slotId,
    this.pickupLocationText,
    this.dropLocationText,
    this.userId,
    this.pickupCoordinates,
    this.dropCoordinates,
  });

  @override
  State<ETSUserTrackingScreen> createState() => _ETSUserTrackingScreenState();
}

class _ETSUserTrackingScreenState extends State<ETSUserTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  LatLng? _userLatLng;
  LatLng? _driverLatLng;
  Polyline? _routePolyline;

  String _rideStatus = "PENDING";
  double _distanceToPickup = 0.0;
  int _etaToPickup = 0;
  double _totalDistance = 0.0;
  int _estimatedRideTime = 0;

  String _otpValue = "";
  bool _connected = false;
  bool _showOtpSection = false;

  String _userId = "";
  String _slotId = "";
  String _pickupLocation = "";
  String _dropLocation = "";

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  BitmapDescriptor? _carIcon;

  Timer? _locationUpdateTimer;
  Timer? _driverUpdateTimer;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadMarkerIcons();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pickupLatLng != null || _dropLatLng != null) {
        _updateMarkers();
        _fitMapToShowAllMarkers();
      }
      if (_pickupLatLng != null && _dropLatLng != null) {
        _drawRoute();
      }
      if (_userId.isNotEmpty && _slotId.isNotEmpty && _pickupLatLng != null && _dropLatLng != null) {
        _connect();
      }
    });
  }

  void _initializeData() {
    _userId = widget.userId ?? "";
    _slotId = widget.slotId?.toString() ?? "";
    _pickupLocation = widget.pickupLocationText ?? "";
    _dropLocation = widget.dropLocationText ?? "";
    _pickupLatLng = widget.pickupCoordinates;
    _dropLatLng = widget.dropCoordinates;
  }

  Future<void> _loadMarkerIcons() async {
    try {
      _pickupIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(30, 30)), 'assets/pickup.png');
      _dropIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(30, 30)), 'assets/drop.png');
      _carIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(40, 40)), 'assets/car.png');
    } catch (e) {
      print('Error loading custom icons: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _driverUpdateTimer?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _handleDriverLocationUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      if (data['latitude'] != null && data['longitude'] != null) {
        _driverLatLng = LatLng(data['latitude'], data['longitude']);
      }
      if (data['rideStatus'] != null) {
        _rideStatus = data['rideStatus'];
        _showOtpSection = _rideStatus == "ARRIVED";

        if (_rideStatus == "ARRIVED" && _otpValue.isEmpty) {
          _generateOtp();
        }
      }
      if (data['distanceToPickup'] != null) {
        _distanceToPickup = data['distanceToPickup'].toDouble();
      }
      if (data['estimatedTimeToPickup'] != null) {
        _etaToPickup = data['estimatedTimeToPickup'];
      }
      if (data['totalRideDistance'] != null) {
        _totalDistance = data['totalRideDistance'].toDouble();
      }
      if (data['estimatedRideTime'] != null) {
        _estimatedRideTime = data['estimatedRideTime'];
      }
    });
  }

  Future<void> _connect() async {
    if (_userId.isEmpty || _slotId.isEmpty || _pickupLatLng == null || _dropLatLng == null) {
      return;
    }

    setState(() {
      _connected = true;
    });

    await _getUserLocation();

    _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _sendUserLocation());

    _fetchDriverLocation();
    _driverUpdateTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _fetchDriverLocation());
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userLatLng = LatLng(pos.latitude, pos.longitude);
          });
          _sendUserLocation();
        }
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  Future<void> _sendUserLocation() async {
    if (!_connected || _userLatLng == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/location/user/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": _userId,
          "slotId": _slotId,
          "latitude": _userLatLng!.latitude,
          "longitude": _userLatLng!.longitude,
          "pickupLocation": _pickupLocation,
          "dropLocation": _dropLocation,
          "pickupLatitude": _pickupLatLng?.latitude ?? 0,
          "pickupLongitude": _pickupLatLng?.longitude ?? 0,
          "dropLatitude": _dropLatLng?.latitude ?? 0,
          "dropLongitude": _dropLatLng?.longitude ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['driverLocation'] != null) {
          _handleDriverLocationUpdate(data);
        }
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  Future<void> _fetchDriverLocation() async {
    if (!_connected || _slotId.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/location/driver/$_slotId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _handleDriverLocationUpdate(data);
        _fetchRideDetails();
      }
    } catch (e) {
      print('Error fetching driver location: $e');
      if (_driverLatLng == null && _pickupLatLng != null) {
        final simulatedDriverLat = _pickupLatLng!.latitude - 0.002;
        final simulatedDriverLng = _pickupLatLng!.longitude - 0.002;
        if (mounted) {
          setState(() {
            _driverLatLng = LatLng(simulatedDriverLat, simulatedDriverLng);
            _rideStatus = "APPROACHING";
            _showOtpSection = false;
          });
          _calculateApproximateValues();
        }
      }
    }
  }

  Future<void> _fetchRideDetails() async {
    if (!_connected || _slotId.isEmpty || _userId.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/location/ride/$_slotId/$_userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            if (data['distanceToPickup'] != null) {
              _distanceToPickup = data['distanceToPickup'].toDouble();
            }
            if (data['estimatedTimeToPickup'] != null) {
              _etaToPickup = data['estimatedTimeToPickup'];
            }
            if (data['totalRideDistance'] != null) {
              _totalDistance = data['totalRideDistance'].toDouble();
            }
            if (data['estimatedRideTime'] != null) {
              _estimatedRideTime = data['estimatedRideTime'];
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching ride details: $e');
      _calculateApproximateValues();
    }
  }

  void _calculateApproximateValues() {
    if (_driverLatLng != null && _pickupLatLng != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _driverLatLng!.latitude,
        _driverLatLng!.longitude,
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
      );

      if (mounted) {
        setState(() {
          _distanceToPickup = distanceInMeters / 1000;
          _etaToPickup = (distanceInMeters / 1000 / 30 * 60).round();

          if (_pickupLatLng != null && _dropLatLng != null) {
            final totalDistanceInMeters = Geolocator.distanceBetween(
              _pickupLatLng!.latitude,
              _pickupLatLng!.longitude,
              _dropLatLng!.latitude,
              _dropLatLng!.longitude,
            );

            _totalDistance = totalDistanceInMeters / 1000;
            _estimatedRideTime = (totalDistanceInMeters / 1000 / 40 * 60).round();
          }
        });
      }
    }
  }

  Future<void> _generateOtp() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/location/generateOTP'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": _userId,
          "slotId": _slotId,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _otpValue = data['otp'] ?? "";
          });
        }
      }
    } catch (e) {
      print('Error generating OTP: $e');
      if (mounted) {
        setState(() {
          _otpValue = (1000 + math.Random().nextInt(9000)).toString();
        });
      }
    }
  }

  Future<void> _updateMarkers() async {
    if (mounted) setState(() {});
  }

  Future<void> _fitMapToShowAllMarkers() async {
    if (_mapController == null) return;

    List<LatLng> points = [];
    if (_pickupLatLng != null) points.add(_pickupLatLng!);
    if (_dropLatLng != null) points.add(_dropLatLng!);
    if (_driverLatLng != null) points.add(_driverLatLng!);
    if (_userLatLng != null) points.add(_userLatLng!);

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 16.0),
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  Future<void> _drawRoute() async {
    if (_pickupLatLng == null || _dropLatLng == null) return;

    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${_pickupLatLng!.longitude},${_pickupLatLng!.latitude};${_dropLatLng!.longitude},${_dropLatLng!.latitude}?overview=full&geometries=polyline';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final polyline = data['routes'][0]['geometry'];
        final points = _decodePolyline(polyline);
        if (mounted) {
          setState(() {
            _routePolyline = Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue.shade600,
              width: 4,
              points: points,
            );
          });
        }
      } else {
        _drawDirectLine();
      }
    } catch (e) {
      print('Route API error: $e');
      _drawDirectLine();
    }
  }

  void _drawDirectLine() {
    if (_pickupLatLng == null || _dropLatLng == null) return;

    if (mounted) {
      setState(() {
        _routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue.shade600,
          width: 4,
          points: [_pickupLatLng!, _dropLatLng!],
        );
      });

      final distanceInMeters = Geolocator.distanceBetween(
        _pickupLatLng!.latitude,
        _pickupLatLng!.longitude,
        _dropLatLng!.latitude,
        _dropLatLng!.longitude,
      );

      setState(() {
        _totalDistance = distanceInMeters / 1000;
        _estimatedRideTime = (distanceInMeters / 1000 / 40 * 60).round();
      });
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    List<LatLng> points = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Color _getStatusColor() {
    switch (_rideStatus) {
      case "ARRIVED":
        return Colors.orange;
      case "PICKED_UP":
        return Colors.green;
      case "DROPPED":
        return Colors.purple;
      case "APPROACHING":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText() {
    switch (_rideStatus) {
      case "ARRIVED":
        return "Driver Arrived";
      case "PICKED_UP":
        return "Ride Started";
      case "DROPPED":
        return "Trip Completed";
      case "APPROACHING":
        return "Driver Approaching";
      default:
        return "Waiting for Driver";
    }
  }

  Widget _buildCompactInfoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String title, String location, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.75;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          Container(
            height: mapHeight,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLatLng ?? const LatLng(28.6139, 77.2090),
                zoom: _pickupLatLng == null ? 10 : 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fitMapToShowAllMarkers();
                });
              },
              markers: {
                if (_pickupLatLng != null)
                  Marker(
                    markerId: const MarkerId("pickup"),
                    position: _pickupLatLng!,
                    icon: _pickupIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(
                        title: "Pickup", snippet: _pickupLocation),
                  ),
                if (_dropLatLng != null)
                  Marker(
                    markerId: const MarkerId("drop"),
                    position: _dropLatLng!,
                    icon: _dropIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(
                        title: "Drop", snippet: _dropLocation),
                  ),
                if (_driverLatLng != null)
                  Marker(
                    markerId: const MarkerId("driver"),
                    position: _driverLatLng!,
                    icon: _carIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: "Driver"),
                  ),
                if (_userLatLng != null)
                  Marker(
                    markerId: const MarkerId("user"),
                    position: _userLatLng!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue),
                    infoWindow: const InfoWindow(title: "You"),
                  ),
              },
              polylines: _routePolyline != null ? {_routePolyline!} : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              mapType: MapType.normal,
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.radio_button_checked, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusDisplayText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ride #$_slotId',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _userId,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildLocationRow('From', _pickupLocation, Icons.location_on, Colors.green),
                        const SizedBox(height: 8),
                        _buildLocationRow('To', _dropLocation, Icons.flag, Colors.red),

                        const SizedBox(height: 16),

                        if (_connected) ...[
                          _buildCompactInfoRow(
                            "Distance to Pickup",
                            "${_distanceToPickup.toStringAsFixed(1)} km",
                            "ETA to Pickup",
                            "$_etaToPickup min",
                          ),
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            "Total Distance",
                            "${_totalDistance.toStringAsFixed(1)} km",
                            "Estimated Time",
                            "$_estimatedRideTime min",
                          ),
                        ],

                        if (_showOtpSection) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.orange.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Share OTP with Driver",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _otpValue.isNotEmpty ? _otpValue : "Generating...",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _generateOtp,
                                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                                  label: const Text(
                                    "Regenerate",
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}