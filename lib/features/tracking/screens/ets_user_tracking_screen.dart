import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

class ETSUserTrackingScreen extends StatefulWidget {
  final String? slotId; 
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
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _slotIdController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

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

  String _otpValue = "----";
  String _statusMessage = "Not connected";
  bool _connected = false;
  bool _showOtpSection = false;

  String _mapClickMode = 'pickup'; // 'pickup' or 'drop'

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  BitmapDescriptor? _carIcon;

  Timer? _locationUpdateTimer;
  Timer? _driverCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();

    if (widget.userId != null) {
      _userIdController.text = widget.userId!;
    }
    if (widget.slotId != null) {
      _slotIdController.text = widget.slotId!;
    }
    if (widget.pickupLocationText != null) {
      _pickupController.text = widget.pickupLocationText!;
    }
    if (widget.dropLocationText != null) {
      _dropController.text = widget.dropLocationText!;
    }
    if (widget.pickupCoordinates != null) {
      _pickupLatLng = widget.pickupCoordinates;
    }
    if (widget.dropCoordinates != null) {
      _dropLatLng = widget.dropCoordinates;
    }

    // If coordinates and all text fields are pre-filled, update map and connect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pickupLatLng != null || _dropLatLng != null) {
        _updateMarkers(); // Update markers if any coordinate is present
      }
      if (_pickupLatLng != null && _dropLatLng != null) {
        _drawRoute(); // Draw route if both coordinates are present
      }
      // Auto-connect if all necessary fields are pre-filled
      if (_userIdController.text.isNotEmpty &&
          _slotIdController.text.isNotEmpty &&
          _pickupController.text.isNotEmpty &&
          _dropController.text.isNotEmpty &&
          _pickupLatLng != null && 
          _dropLatLng != null 
          ) {
        _connect();
      }
    });
  }

  Future<void> _loadMarkerIcons() async {
    _pickupIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(30, 30)), 'assets/pickup.png');
    _dropIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(30, 30)), 'assets/drop.png');
    _carIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(40, 40)), 'assets/car.png');
    setState(() {});
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _driverCheckTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Simple autocomplete using Google Places API directly
  Future<void> _handleAutocomplete({required bool isPickup}) async {
    final controller = isPickup ? _pickupController : _dropController;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPickup ? 'Enter Pickup Location' : 'Enter Drop Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type location name...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  final coordinates = await _geocodeAddress(value);
                  if (coordinates != null) {
                    setState(() {
                      if (isPickup) {
                        _pickupLatLng = coordinates;
                      } else {
                        _dropLatLng = coordinates;
                      }
                    });
                    _updateMarkers();
                    if (_pickupLatLng != null && _dropLatLng != null) _drawRoute();
                  }
                }
                Navigator.of(context).pop();
              },
            ),
            SizedBox(height: 10),
            Text(
              'Or click on the map to select location',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final coordinates = await _geocodeAddress(controller.text);
                if (coordinates != null) {
                  setState(() {
                    if (isPickup) {
                      _pickupLatLng = coordinates;
                    } else {
                      _dropLatLng = coordinates;
                    }
                  });
                  _updateMarkers();
                  if (_pickupLatLng != null && _dropLatLng != null) _drawRoute();
                }
              }
              Navigator.of(context).pop();
            },
            child: Text('Set Location'),
          ),
        ],
      ),
    );
  }

  // Geocode address to coordinates using Google Geocoding API
  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleMapsApiKey';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return null;
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleMapsApiKey";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    if (data['status'] == 'OK') {
      return data['results'][0]['formatted_address'];
    }
    return "$lat,$lng";
  }

  void _onMapTap(LatLng latLng) async {
    if (_mapClickMode == 'pickup') {
      final address = await _reverseGeocode(latLng.latitude, latLng.longitude);
      setState(() {
        _pickupLatLng = latLng;
        _pickupController.text = address;
      });
    } else {
      final address = await _reverseGeocode(latLng.latitude, latLng.longitude);
      setState(() {
        _dropLatLng = latLng;
        _dropController.text = address;
      });
    }
    _updateMarkers();
    if (_pickupLatLng != null && _dropLatLng != null) _drawRoute();
  }

  void _updateMarkers() {
    setState(() {});
  }

  Future<void> _drawRoute() async {
    if (_pickupLatLng == null || _dropLatLng == null) return;
    final url =
        'http://router.project-osrm.org/route/v1/driving/${_pickupLatLng!.longitude},${_pickupLatLng!.latitude};${_dropLatLng!.longitude},${_dropLatLng!.latitude}?overview=full&geometries=polyline';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);
    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final polyline = data['routes'][0]['geometry'];
      final points = _decodePolyline(polyline);
      setState(() {
        _routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: points,
        );
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

  Future<void> _connect() async {
    if (_userIdController.text.isEmpty ||
        _slotIdController.text.isEmpty ||
        _pickupController.text.isEmpty ||
        _dropController.text.isEmpty) {
      setState(() {
        _statusMessage = "Please fill in all fields";
      });
      return;
    }
    setState(() {
      _connected = true;
      _statusMessage = "Connected! Waiting for driver...";
    });
    _getUserLocation();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) => _sendUserLocation());
    _driverCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchDriverLocation());
  }

  Future<void> _getUserLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userLatLng = LatLng(pos.latitude, pos.longitude);
    });
    _sendUserLocation();
  }

  Future<void> _sendUserLocation() async {
    if (!_connected || _userLatLng == null) return;
    // Replace with your API endpoint
    await http.post(
      Uri.parse('http://192.168.1.42:8081/api/location/user/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": _userIdController.text,
        "slotId": _slotIdController.text,
        "latitude": _userLatLng!.latitude,
        "longitude": _userLatLng!.longitude,
      }),
    );
  }

  Future<void> _fetchDriverLocation() async {
    // Replace with your API endpoint
    final res = await http.get(Uri.parse(
        'http://192.168.1.42:8081/api/location/driver/${_slotIdController.text}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _driverLatLng = LatLng(data['latitude'], data['longitude']);
        _rideStatus = data['status'] ?? "PENDING";
        _distanceToPickup = data['distanceToPickup'] ?? 0.0;
        _etaToPickup = data['etaToPickup'] ?? 0;
        _totalDistance = data['totalDistance'] ?? 0.0;
        _estimatedRideTime = data['estimatedRideTime'] ?? 0;
        _showOtpSection = _rideStatus == "ARRIVED";
      });
    }
  }

  Future<void> _generateOtp() async {
    // Replace with your API endpoint
    final res = await http.post(
      Uri.parse('http://192.168.1.42:8081/api/location/generateOTP'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": _userIdController.text,
        "slotId": _slotIdController.text,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _otpValue = data['otp'] ?? "----";
      });
    }
  }

  Widget _infoCard(String title, String value, {Color? color}) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: color != null ? Border(top: BorderSide(color: color, width: 4)) : null,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color ?? Colors.blue)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text("ETS - User Location Tracking", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                // Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xfff9f9f9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("User ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(controller: _userIdController, decoration: const InputDecoration(hintText: "Enter your User ID")),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Slot ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(controller: _slotIdController, decoration: const InputDecoration(hintText: "Enter your Slot ID")),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 15),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pickup Location:", style: TextStyle(fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () => _handleAutocomplete(isPickup: true),
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: _pickupController,
                                    decoration: const InputDecoration(
                                      hintText: "Tap to enter pickup location",
                                      suffixIcon: Icon(Icons.search),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Drop Location:", style: TextStyle(fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () => _handleAutocomplete(isPickup: false),
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: _dropController,
                                    decoration: const InputDecoration(
                                      hintText: "Tap to enter drop location",
                                      suffixIcon: Icon(Icons.search),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: _connected ? null : _connect,
                          child: Text("Connect", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Toggle for map click mode
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xfff5f5f5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _mapClickMode = 'pickup'),
                          child: const Text("Set Pickup"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mapClickMode == 'pickup' ? Colors.green : Colors.grey[300],
                            foregroundColor: _mapClickMode == 'pickup' ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => _mapClickMode = 'drop'),
                          child: const Text("Set Drop"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mapClickMode == 'drop' ? Colors.green : Colors.grey[300],
                            foregroundColor: _mapClickMode == 'drop' ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Status
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xffe7f3fe),
                    borderRadius: BorderRadius.circular(4),
                    border: Border(left: BorderSide(color: Colors.blue, width: 5)),
                  ),
                  child: Text(_statusMessage, style: TextStyle(color: Colors.black87)),
                ),
                const SizedBox(height: 15),
                // Ride Info Cards
                if (_connected)
                  Row(
                    children: [
                      _infoCard("Driver Status", _rideStatus, color: _rideStatus == "ARRIVED" ? Colors.orange : _rideStatus == "PICKED_UP" ? Colors.green : _rideStatus == "DROPPED" ? Colors.purple : Colors.blue),
                      _infoCard("Distance to Pickup", "${_distanceToPickup.toStringAsFixed(1)} km"),
                      _infoCard("ETA to Pickup", "${_etaToPickup} min"),
                      _infoCard("Total Ride Distance", "${_totalDistance.toStringAsFixed(1)} km"),
                      _infoCard("Estimated Ride Time", "${_estimatedRideTime} min"),
                    ],
                  ),
                // OTP Section
                if (_showOtpSection)
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        Text("Share this OTP with your driver", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(_otpValue, style: const TextStyle(fontSize: 32, letterSpacing: 5, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        const SizedBox(height: 10),
                        Text("Ask your driver to enter this code to verify pickup", style: TextStyle(fontSize: 14)),
                        ElevatedButton(
                          onPressed: _generateOtp,
                          child: Text("Generate New OTP", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                // Map
                Container(
                  height: 500,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _pickupLatLng ?? const LatLng(20.5937, 78.9629),
                        zoom: _pickupLatLng == null ? 5 : 14,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        if (_pickupLatLng != null)
                          Marker(
                            markerId: MarkerId("pickup"),
                            position: _pickupLatLng!,
                            icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            infoWindow: InfoWindow(title: "Pickup", snippet: _pickupController.text),
                          ),
                        if (_dropLatLng != null)
                          Marker(
                            markerId: MarkerId("drop"),
                            position: _dropLatLng!,
                            icon: _dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            infoWindow: InfoWindow(title: "Drop", snippet: _dropController.text),
                          ),
                        if (_driverLatLng != null)
                          Marker(
                            markerId: MarkerId("driver"),
                            position: _driverLatLng!,
                            icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            infoWindow: InfoWindow(title: "Driver"),
                          ),
                        if (_userLatLng != null)
                          Marker(
                            markerId: MarkerId("user"),
                            position: _userLatLng!,
                            infoWindow: InfoWindow(title: "You"),
                          ),
                      },
                      polylines: _routePolyline != null ? {_routePolyline!} : {},
                      onTap: _onMapTap,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
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
}