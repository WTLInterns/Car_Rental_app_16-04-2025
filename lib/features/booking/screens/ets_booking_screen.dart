import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import '../../../features/booking/screens/ets_select_vehicle_screen.dart';
import '../../../features/trips/screens/ets_trips_screen.dart';

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";

class EtsBookingScreen extends StatefulWidget {
  const EtsBookingScreen({super.key});

  @override
  State<EtsBookingScreen> createState() => _EtsBookingScreenState();
}

class _EtsBookingScreenState extends State<EtsBookingScreen> with SingleTickerProviderStateMixin {
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isOneWay = true;

  List<DateTime> _selectedDates = [];
  final List<DateTime> _holidays = [
    DateTime(2025, 4, 2),
    DateTime(2025, 4, 14),
    DateTime(2025, 5, 1),
    DateTime(2025, 8, 15),
    DateTime(2025, 10, 2),
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  List<dynamic> _pickupSuggestions = [];
  List<dynamic> _dropSuggestions = [];
  bool _isLoadingLocation = false;
  String? _activeField;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _selectedTime = TimeOfDay.now();
    _pickupController.addListener(() => setState(() {}));
    _dropController.addListener(() => setState(() {}));
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _changeMonth(int increment) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + increment);
    });
  }

  Widget _buildCustomCalendar(StateSetter setState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _changeMonth(-1)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              DateFormat('MMMM yyyy').format(currentMonth),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _changeMonth(1)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(const Color(0xFF81D4FA), 'Selected'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.red[100]!, 'Holiday/Sunday'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: day == 'S' ? Colors.red[300] : Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(
                height: 200,
                child: Column(
                  children: [
                    for (int i = 0; i < 5; i++) _buildCalendarWeekRow(currentMonth, i, setState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Animation<double> safeAnimation = _fadeInAnimation;
    try {
      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Animation initialization error: $e');
      safeAnimation = const AlwaysStoppedAnimation<double>(1.0);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Employee Transport',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(1, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A237E),
                      const Color(0xFF0277BD),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  image: DecorationImage(
                    image: const AssetImage('assets/images/Service-employee-transfer.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(13),
                      BlendMode.dstATop,
                    ),
                    onError: (exception, stackTrace) {
                      debugPrint('Error loading background pattern: $exception');
                    },
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: kToolbarHeight + 80),
                Expanded(
                  child: FadeTransition(
                    opacity: safeAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car_rounded,
                                      color: Theme.of(context).primaryColor,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Book Your Ride',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Complete the form to reserve your transportation',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isOneWay = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _isOneWay ? Theme.of(context).primaryColor : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'One Way',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _isOneWay ? Colors.white : Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isOneWay = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: !_isOneWay ? Theme.of(context).primaryColor : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Round Trip',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: !_isOneWay ? Colors.white : Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildInputField(
                                icon: Icons.location_pin,
                                iconColor: const Color(0xFF4CAF50),
                                label: 'Pickup Location',
                                controller: _pickupController,
                                hint: 'Enter pickup location',
                                isActive: _activeField == 'pickup',
                                onTap: () => setState(() => _activeField = 'pickup'),
                              ),
                              _buildInputField(
                                icon: Icons.flag,
                                iconColor: const Color(0xFF2196F3),
                                label: 'Drop Location',
                                controller: _dropController,
                                hint: 'Enter drop location',
                                isActive: _activeField == 'drop',
                                onTap: () => setState(() => _activeField = 'drop'),
                              ),
                              _buildDatePicker(context),
                              if (_selectedDates.isNotEmpty) _buildSelectedDates(),
                              _buildTimePicker(context),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.8, end: 1.0),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutBack,
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_pickupController.text.isEmpty || _dropController.text.isEmpty) {
                                          _showErrorSnackBar('Please enter pickup and drop locations');
                                          return;
                                        }
                                        if (_selectedDates.isEmpty) {
                                          _showErrorSnackBar('Please select at least one date');
                                          return;
                                        }
                                        if (_selectedTime == null) {
                                          _showErrorSnackBar('Please select a pickup time');
                                          return;
                                        }
                                        _fetchVehicleAvailability();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 5,
                                        shadowColor: const Color(0xFF4CAF50).withAlpha(64),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.white.withAlpha(200),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Search Available Vehicles',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            elevation: 8,
            backgroundColor: Colors.white,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey[600],
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'Trips',
              ),
            ],
            onTap: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ETSTripsScreen()),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'About ETS Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'The Employee Transportation Service (ETS) provides safe and reliable transportation for company employees.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Available 24/7\n• Professional drivers\n• Multiple vehicle options\n• Real-time tracking\n• Secure and comfortable',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isPickup = label.contains('Pickup');
    final type = isPickup ? 'pickup' : 'drop';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Theme.of(context).primaryColor : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? Theme.of(context).primaryColor.withAlpha(128) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: controller,
                  onTap: onTap,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: isActive ? iconColor : Colors.grey[400]),
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? SizedBox(width: isPickup ? 80 : 40)
                        : isPickup && _isLoadingLocation
                        ? SizedBox(width: 40)
                        : isPickup
                        ? SizedBox(width: 40)
                        : null,
                  ),
                  onChanged: (value) => _searchPlaces(value, type),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                        onPressed: () {
                          controller.clear();
                          _searchPlaces('', type);
                        },
                        constraints: BoxConstraints(maxWidth: 32),
                        padding: EdgeInsets.zero,
                      ),
                    if (isPickup)
                      _isLoadingLocation
                          ? Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      )
                          : IconButton(
                        icon: Icon(Icons.my_location, color: const Color(0xFF0066CC), size: 22),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Use current location',
                        constraints: BoxConstraints(maxWidth: 32),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if ((isPickup && _pickupSuggestions.isNotEmpty) || (!isPickup && _dropSuggestions.isNotEmpty))
            _buildSuggestionsList(isPickup ? _pickupSuggestions : _dropSuggestions, controller, type),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFFFF9800)),
              const SizedBox(width: 8),
              Text(
                'Pickup Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
              const Spacer(),
              if (_selectedDates.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selectedDates = []),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDates.isNotEmpty ? const Color(0xFFFF9800).withAlpha(32) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _selectedDates.isNotEmpty ? const Color(0xFFFF9800) : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDates.isEmpty ? 'Select Dates' : 'Selected ${_selectedDates.length} date(s)',
                      style: TextStyle(
                        color: _selectedDates.isEmpty ? Colors.grey[400] : Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_selectedDates.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withAlpha(16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(_selectedDates[0]),
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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

  Widget _buildSelectedDates() {
    final DateTime displayMonth = _selectedDates.isNotEmpty
        ? DateTime(_selectedDates[0].year, _selectedDates[0].month, 1)
        : DateTime.now();
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final firstWeekDay = firstDayOfMonth.weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Dates:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(displayMonth),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    children: [
                      for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                        Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: day == 'S' ? Colors.red[300] : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    childAspectRatio: 2.0,
                    shrinkWrap: true,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    padding: EdgeInsets.zero,
                    children: [
                      for (int i = 0; i < firstWeekDay; i++)
                        _buildCalendarCell(null, isSunday: i == 0),
                      for (int day = 1; day <= daysInMonth; day++)
                        _buildCalendarCell(
                          day,
                          isSelected: _selectedDates.any((selectedDate) =>
                          selectedDate.year == displayMonth.year &&
                              selectedDate.month == displayMonth.month &&
                              selectedDate.day == day),
                          isSunday: DateTime(displayMonth.year, displayMonth.month, day).weekday == DateTime.sunday,
                          isHoliday: _holidays.any((holiday) =>
                          holiday.year == displayMonth.year &&
                              holiday.month == displayMonth.month &&
                              holiday.day == day),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text(
                'Pickup Time',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTime != null ? const Color(0xFF2196F3).withAlpha(128) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: _selectedTime != null ? const Color(0xFF2196F3) : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime == null
                        ? DateFormat('h:mm a').format(DateTime.now())
                        : _formatTimeDisplay(_selectedTime!),
                    style: TextStyle(
                      color: _selectedTime == null ? Colors.grey[600] : Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withAlpha(16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPeriodText(_selectedTime!),
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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

  String _getPeriodText(TimeOfDay time) {
    if (time.hour < 12) return 'Morning';
    if (time.hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectDate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Dates',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCustomCalendar(setState),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('CANCEL', style: TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            this.setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CONFIRM'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchVehicleAvailability() async {
    if (!_animationController.isAnimating && _animationController.status != AnimationStatus.completed) {
      _animationController.forward();
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Searching for available vehicles...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we process your request',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final baseUrl = 'https://ets.worldtriplink.com';
      final Uri uri = Uri.parse('$baseUrl/schedule/etsCab1');
      List<String> formattedDates = _selectedDates.map((date) => DateFormat('yyyy-MM-dd').format(date)).toList();
      String formattedTime = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : '';

      Map<String, dynamic> queryParams = {
        'pickUpLocation': _pickupController.text,
        'dropLocation': _dropController.text,
        'time': formattedTime,
        'shiftTime': formattedTime,
      };

      Uri uriWithParams = uri.replace(queryParameters: queryParams);
      String uriString = uriWithParams.toString();
      for (String date in formattedDates) {
        uriString += '&dates=$date';
      }

      debugPrint('Calling API: $uriString');
      final response = await http.post(
        Uri.parse(uriString),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (!mounted) return;

        final bookingData = {
          'pickup': data['pickUpLocation'],
          'destination': data['dropLocation'],
          'dates': formattedDates,
          'time': data['time'],
          'bookingType': _isOneWay ? 'oneWay' : 'roundTrip',
          'distance': data['distace']?.toString() ?? '0',
          'sourceCity': data['sourceCity'],
          'destinationCity': data['destinationCity'],
          'sourceState': data['sourceState'],
          'destinationState': data['destinationState'],
          'hatchback': data['hatchback']?.toString() ?? '0',
          'sedan': data['sedan']?.toString() ?? '0',
          'suv': data['suv']?.toString() ?? '0',
          'shiftTime': data['shiftTime'],
          'returnTime': data['returnTime'] ?? data['time'],
        };

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EtsSelectVehicleScreen(bookingData: bookingData, dates: bookingData['dates'] as List<String>),
          ),
        );
      } else {
        if (!mounted) return;
        _showErrorDialog(context, 'Server Error', 'The server returned an error: ${response.statusCode}. Please try again later.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(context, 'Connection Error', 'Could not connect to the server. Please check your internet connection and try again.');
      debugPrint('API Error: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildCalendarWeekRow(DateTime currentMonth, int weekIndex, StateSetter setState) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekDay = firstDayOfMonth.weekday % 7;

    return Row(
      children: List.generate(7, (dayIndex) {
        final dayNumber = (weekIndex * 7 + dayIndex + 1) - firstWeekDay;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[100]!)),
            ),
          );
        }

        final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
        final isSunday = date.weekday == DateTime.sunday;
        final isHoliday = _holidays.any((holiday) =>
        holiday.year == date.year && holiday.month == date.month && holiday.day == date.day);
        final isSelected = _selectedDates.any((selectedDate) =>
        selectedDate.year == date.year && selectedDate.month == date.month && selectedDate.day == date.day);
        final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

        return Expanded(
          child: GestureDetector(
            onTap: isPast
                ? null
                : () {
              setState(() {
                if (isSelected) {
                  _selectedDates.removeWhere((selectedDate) =>
                  selectedDate.year == date.year &&
                      selectedDate.month == date.month &&
                      selectedDate.day == date.day);
                } else {
                  _selectedDates.add(date);
                }
              });
            },
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF81D4FA)
                    : (isHoliday || isSunday) && !isPast
                    ? Colors.red[50]
                    : Colors.white,
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Center(
                child: Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast
                        ? Colors.grey[400]
                        : (isHoliday || isSunday)
                        ? Colors.red[400]
                        : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) setState(() => _selectedTime = picked);
  }

  Widget _buildCalendarCell(int? day, {bool isSelected = false, bool isSunday = false, bool isHoliday = false}) {
    if (day == null) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), color: Colors.white),
      );
    }
    Color cellColor = Colors.white;
    if (isSelected) {
      cellColor = const Color(0xFF81D4FA);
    } else if (isHoliday || isSunday) {
      cellColor = Colors.red[50]!;
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : (isHoliday || isSunday) ? Colors.red[400] : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }
    try {
      final locationData = await location.getLocation();
      setState(() => _isLoadingLocation = false);
      _reverseGeocode(locationData);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Could not get location. Please try again.');
    }
  }

  Future<void> _reverseGeocode(LocationData location) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$googleMapsApiKey',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            _pickupController.text = data['results'][0]['formatted_address'];
            _activeField = 'pickup';
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Could not get address. Please enter manually.');
    }
  }

  Future<void> _searchPlaces(String query, String type) async {
    if (query.isEmpty) {
      setState(() => type == 'pickup' ? _pickupSuggestions = [] : _dropSuggestions = []);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleMapsApiKey&components=country:in',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => type == 'pickup' ? _pickupSuggestions = data['predictions'] ?? [] : _dropSuggestions = data['predictions'] ?? []);
      }
    } catch (e) {}
  }

  Widget _buildSuggestionsList(List<dynamic> suggestions, TextEditingController controller, String type) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(16), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              controller.text = suggestions[index]['description'];
              setState(() => type == 'pickup' ? _pickupSuggestions = [] : _dropSuggestions = []);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: type == 'pickup' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestions[index]['description'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}