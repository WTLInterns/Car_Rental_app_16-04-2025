import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:worldtriplink/screens/ets_select_vehicle_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

const String googleMapsApiKey = "AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w";
class EtsBookingScreen extends StatefulWidget {
  const EtsBookingScreen({super.key});

  @override
  State<EtsBookingScreen> createState() => _EtsBookingScreenState();
}

class _EtsBookingScreenState extends State<EtsBookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  List<DateTime> _selectedDates = [];
  TimeOfDay? _selectedTime;
  bool _isOneWay = true;
  
  // Add these new variables for Google Maps integration
  List<dynamic> _pickupSuggestions = [];
  List<dynamic> _dropSuggestions = [];
  bool _isLoadingLocation = false;
  LocationData? _currentLocation;

  // List to store government holidays
  final List<DateTime> _holidays = [
    DateTime(2024, 4, 2),
    DateTime(2024, 4, 14),
  ];
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 232, 232, 238),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 120, // Increase height to accommodate all three lines
        title: Container(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Employee',
                    textStyle: const TextStyle(
                        color: Color.fromARGB(255, 249, 249, 250),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      shadows: [
                        BoxShadow(
                          color: Colors.black54,
                         
                          offset: Offset(1, 1),
                        ),
                      ],
                      // shadows: [Shadow(color: Colors.black54, blurRadius: 3.0, offset: Offset(1, 1))],
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
                displayFullTextOnTap: true,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Transportation',
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 249, 249, 250),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
 shadows: [
                        BoxShadow(
                          color: Colors.black54,
                         
                          offset: Offset(1, 1),
                        ),
                      ],                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                  displayFullTextOnTap: true,
                  isRepeatingAnimation: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 80.0),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Service',
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 249, 249, 250),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
 shadows: [
                        BoxShadow(
                          color: Colors.black54,
                         
                          offset: Offset(1, 1),
                        ),
                      ],                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                  displayFullTextOnTap: true,
                  isRepeatingAnimation: false,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0066CC), Color(0xFF4CAF50)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Corporate car image - using the image you provided
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/Service-employee-transfer.jpg', // Make sure this image exists in your assets
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 180),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Book Your Ride',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          icon: Icons.location_pin,
                          label: 'Pickup Location',
                          controller: _pickupController,
                          hint: 'Enter pickup location',
                        ),
                        _buildInputField(
                          icon: Icons.flag,
                          label: 'Drop Location',
                          controller: _dropController,
                          hint: 'Enter drop location',
                        ),
                        _buildDatePicker(context),
                        if (_selectedDates.isNotEmpty) _buildSelectedDates(),
                        _buildTimePicker(context),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate inputs
                                if (_pickupController.text.isEmpty || _dropController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter pickup and drop locations'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (_selectedDates.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select at least one date'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (_selectedTime == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a pickup time'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Prepare booking data
                                final bookingData = {
                                  'pickup': _pickupController.text,
                                  'destination': _dropController.text,
                                  'date': DateFormat('yyyy-MM-dd').format(_selectedDates[0]),
                                  'time': _selectedTime!.format(context),
                                  'bookingType': _isOneWay ? 'oneWay' : 'roundTrip',
                                  'returnDate': _selectedDates.length > 1 ? 
                                      DateFormat('yyyy-MM-dd').format(_selectedDates[1]) : '',
                                };
                                
                                // Navigate to EtsSelectVehicleScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EtsSelectVehicleScreen(bookingData: bookingData),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                shadowColor: Colors.greenAccent.withOpacity(0.4),
                              ),
                              child: const Text(
                                'Search Available Vehicles',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final isPickup = label.contains('Pickup');
    final type = isPickup ? 'pickup' : 'drop';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, color: const Color(0xFF0066CC)),
                    hintText: hint,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
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
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF0066CC)),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.my_location,
                                color: const Color(0xFF0066CC),
                                size: 22,
                              ),
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
            _buildSuggestionsList(
              isPickup ? _pickupSuggestions : _dropSuggestions,
              controller,
              type,
            ),
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
          Text(
            'Pickup Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF0066CC)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDates.isEmpty 
                        ? 'Select Dates' 
                        : 'Selected ${_selectedDates.length} date(s)',
                    style: TextStyle(color: Colors.grey[800]),
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
    // Get the month and year to display (from the first selected date or current date)
    final DateTime displayMonth = _selectedDates.isNotEmpty 
        ? DateTime(_selectedDates[0].year, _selectedDates[0].month, 1)
        : DateTime.now();
    
    // Calculate first day of month and days in month
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final firstWeekDay = firstDayOfMonth.weekday % 7; // 0 = Sunday, 6 = Saturday
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Dates:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.grey),
                onPressed: () {},
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(
              children: [
                // Month and year header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(7),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy').format(displayMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.grey),
                        onPressed: () {},
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                // Days of week header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      for (final day in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
                        Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: day == 'Sun' ? Colors.red : Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Calendar grid - dynamically generated based on selected dates
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  childAspectRatio: 1.2,
                  children: [
                    // Generate empty cells for days before the 1st of the month
                    for (int i = 0; i < firstWeekDay; i++)
                      _buildCalendarCell(null, isSunday: i == 0),
                    
                    // Generate cells for each day of the month
                    for (int day = 1; day <= daysInMonth; day++)
                      _buildCalendarCell(
                        day, 
                        isSelected: _selectedDates.any((selectedDate) =>
                          selectedDate.year == displayMonth.year &&
                          selectedDate.month == displayMonth.month &&
                          selectedDate.day == day
                        ), 
                        isSunday: DateTime(displayMonth.year, displayMonth.month, day).weekday == DateTime.sunday
                      ),
                    
                    // Fill remaining cells in the grid if needed
                    for (int i = 0; i < (42 - daysInMonth - firstWeekDay); i++)
                      _buildCalendarCell(null),
                  ],
                ),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('CANCEL', style: TextStyle(color: Colors.indigo)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('OK', style: TextStyle(color: Colors.indigo)),
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
          // Trip type toggle buttons
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell( // Changed from GestureDetector to InkWell for better feedback
                    onTap: () {
                      setState(() {
                        _isOneWay = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isOneWay ? Colors.blue : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: _isOneWay ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell( // Changed from GestureDetector to InkWell
                    onTap: () {
                      setState(() {
                        _isOneWay = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isOneWay ? Colors.white : Colors.blue,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      child: Icon(
                        Icons.sync,
                        color: _isOneWay ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Pickup Time',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF0066CC)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Select Time',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





  Future<void> _selectDate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Multiple Dates'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCustomCalendar(setState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.setState(() {});
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomCalendar(StateSetter setState) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    
    return Expanded(
      child: Column(
        children: [
          // Month header with print icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                DateFormat('MMMM yyyy').format(currentMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Table-style calendar
          Table(
            border: TableBorder.all(color: Colors.grey[300]!),
            children: [
              // Days of week header
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                children: [
                  for (final day in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: day == 'Sun' ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Calendar rows - we'll generate 6 rows to cover all possible month layouts
              for (int week = 0; week < 6; week++)
                _buildCalendarWeekRow(now, week, setState),
            ],
          ),
        ],
      ),
    );
  }
  
  TableRow _buildCalendarWeekRow(DateTime now, int weekIndex, StateSetter setState) {
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // Calculate the first day to display in the first week
    final firstWeekDay = firstDayOfMonth.weekday % 7; // 0 = Sunday, 6 = Saturday
    
    return TableRow(
      children: List.generate(7, (dayIndex) {
        final dayNumber = (weekIndex * 7 + dayIndex + 1) - firstWeekDay;
        
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          // Empty cell or day from next/previous month
          return const TableCell(child: SizedBox(height: 40));
        }
        
        final date = DateTime(now.year, now.month, dayNumber);
        final isSunday = date.weekday == DateTime.sunday;
        final isHoliday = _holidays.any((holiday) =>
            holiday.year == date.year &&
            holiday.month == date.month &&
            holiday.day == date.day);
        final isSelected = _selectedDates.any((selectedDate) =>
            selectedDate.year == date.year &&
            selectedDate.month == date.month &&
            selectedDate.day == date.day);
        final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
        
        // Show small text below the day number (like "15" in the image)
        String? smallText;
        if (isHoliday) {
          smallText = 'Holiday';
        }
        
        return TableCell(
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
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF81D4FA) // Light blue like in the image
                    : (isHoliday || isSunday) && !isPast
                        ? Colors.red[100] // Light red for holidays and Sundays
                        : Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: isPast
                          ? Colors.grey[400]
                          : (isHoliday || isSunday)
                              ? Colors.red
                              : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (smallText != null)
                    Text(
                      smallText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[700],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
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
              primary: Color(0xFF0066CC),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Widget _buildCalendarCell(int? day, {bool isSelected = false, bool isSunday = false}) {
    if (day == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          color: Colors.white,
        ),
      );
    }
    
    // For the selected dates view, we just want to show the cells without interaction
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        color: isSelected 
            ? const Color(0xFF81D4FA) // Light blue for selected dates
            : isSunday 
                ? const Color(0xFFFFCDD2) // Light red for Sundays
                : Colors.white,
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? Colors.black87 
                : isSunday 
                    ? Colors.red 
                    : Colors.black87,
          ),
        ),
      ),
    );
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
        SnackBar(content: Text('Could not get location: $e'))
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
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get address: $e'))
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
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
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
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: const Color(0xFF0066CC),
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestions[index]['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
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
}
