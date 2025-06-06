import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../../core/config/app_config.dart';
import '../../auth/blocs/auth_bloc.dart';
import '../../trips/screens/trips_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'cab_booking_screen.dart';
import 'ets_booking_screen.dart';
import '../../profile/screens/notification_screen.dart';
import '../../profile/screens/offers_screen.dart';

// Consistent color palette matching offers_screen.dart
const Color primaryColor = Color(0xFF4A90E2); 
const Color accentColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFFFFCC00);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF666666);
const Color mutedTextColor = Color(0xFF999999);

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      const _HomeContent(),
      const TripsScreen(),
      const OffersScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
        ? AppBar(
            backgroundColor: primaryColor,
            elevation: 0,
            title: const Center(
              child: Text(
                'World Trip Link',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : null,
      body: Container(
        color: backgroundColor,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedTextColor,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _animation = kAlwaysCompleteAnimation;
  
  // Search functionality variables
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Page controller listener
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
    
    // Auto-scroll timer
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Search functionality
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$query&key=AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w&components=country:in',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && (data['predictions'] as List).isNotEmpty) {
          setState(() {
            _searchSuggestions = data['predictions'];
            _isSearching = false;
          });
        } else {
          _useMockData(query);
        }
      } else {
        _useMockData(query);
      }
    } catch (e) {
      _useMockData(query);
    }
  }
  
  void _useMockData(String query) {
    final List<Map<String, dynamic>> mockCities = [
      {
        'description': 'Mumbai, Maharashtra, India',
        'structured_formatting': {'secondary_text': 'Maharashtra, India'}
      },
      {
        'description': 'Delhi, India',
        'structured_formatting': {'secondary_text': 'India'}
      },
      {
        'description': 'Bangalore, Karnataka, India',
        'structured_formatting': {'secondary_text': 'Karnataka, India'}
      },
      {
        'description': 'Hyderabad, Telangana, India',
        'structured_formatting': {'secondary_text': 'Telangana, India'}
      },
      {
        'description': 'Chennai, Tamil Nadu, India',
        'structured_formatting': {'secondary_text': 'Tamil Nadu, India'}
      },
      {
        'description': 'Kolkata, West Bengal, India',
        'structured_formatting': {'secondary_text': 'West Bengal, India'}
      },
      {
        'description': 'Pune, Maharashtra, India',
        'structured_formatting': {'secondary_text': 'Maharashtra, India'}
      },
      {
        'description': 'Ahmedabad, Gujarat, India',
        'structured_formatting': {'secondary_text': 'Gujarat, India'}
      },
      {
        'description': 'Jaipur, Rajasthan, India',
        'structured_formatting': {'secondary_text': 'Rajasthan, India'}
      },
    ];
    
    final filteredCities = mockCities.where((city) => 
      city['description'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    setState(() {
      _searchSuggestions = filteredCities;
      _isSearching = false;
    });
  }
  
  void _showSearchDialog(BuildContext context) {
    _searchController.clear();
    _searchSuggestions = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: cardColor,
            title: Row(
              children: [
                Icon(Icons.location_searching, color: primaryColor),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Where do you want to go?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for your destination...',
                        hintStyle: TextStyle(color: mutedTextColor),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          setDialogState(() {
                            _isSearching = true;
                          });
                          await _searchPlaces(value);
                          setDialogState(() {
                            _isSearching = false;
                          });
                        } else {
                          setDialogState(() {
                            _searchSuggestions = [];
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isSearching)
                    Center(child: CircularProgressIndicator(color: primaryColor))
                  else if (_searchSuggestions.isEmpty && _searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.location_off, size: 40, color: mutedTextColor),
                          const SizedBox(height: 10),
                          Text(
                            'No results found',
                            style: TextStyle(color: mutedTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: backgroundColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(Icons.location_on_outlined, color: primaryColor),
                              title: Text(
                                suggestion['description'] ?? 'Unknown location',
                                style: const TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                suggestion['structured_formatting']?['secondary_text'] ?? '',
                                style: TextStyle(color: lightTextColor),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CabBookingScreen(
                                      dropLocation: suggestion['description'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: mutedTextColor,
                ),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthBloc>(
      builder: (context, authBloc, _) {
        final userName = authBloc.currentUser?.username ?? 'User';
        
        return FadeTransition(
          opacity: _animation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // Greeting Section with Search
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $userName',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Where are you going today?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: lightTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => _showSearchDialog(context),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 22,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Where do you want to go?',
                                  style: TextStyle(
                                    fontSize: 16, 
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Services Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Our Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildServiceCard(
                              icon: MaterialCommunityIcons.car,
                              label: 'Cab',
                              iconColor: Colors.amber,
                              bgColor: Colors.amber.withOpacity(0.1),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CabBookingScreen(),
                                ),
                              ),
                            ),
                            
                            _buildServiceCard(
                              icon: MaterialCommunityIcons.badge_account,
                              label: 'ETS',
                              iconColor: primaryColor,
                              bgColor: primaryColor.withOpacity(0.1),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EtsBookingScreen(),
                                ),
                              ),
                            ),
                            
                            _buildServiceCard(
                              icon: MaterialCommunityIcons.bus,
                              label: 'Bus',
                              iconColor: const Color(0xFF4CAF50),
                              bgColor: const Color(0xFF4CAF50).withOpacity(0.1),
                              onTap: () {},
                            ),
                            
                            _buildServiceCard(
                              icon: MaterialCommunityIcons.airplane,
                              label: 'Flight',
                              iconColor: const Color(0xFFFF6B6B),
                              bgColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Featured Rides Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            'Featured Rides',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFeaturedRides(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Premium Service Card
                 // _buildPremiumServiceCard(),

                  const SizedBox(height: 16),

                  // Promotional Cards
                  _buildDiscountCard(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumServiceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              MaterialCommunityIcons.star_circle,
              color: primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get priority booking and exclusive offers',
                  style: TextStyle(
                    fontSize: 14,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(75),
              ),
            ),
          ),
          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SPECIAL OFFER',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Get 25% off on your next ride',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use code SAVE25 to get discount',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '25%\nOFF',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // List of featured ride images
  final List<Map<String, dynamic>> featuredRides = [
    {
      'image': 'assets/images/sedan.png',
      'title': 'Premium Sedans',
      'subtitle': 'Comfortable rides at affordable prices',
      'color': const Color(0xFF4CAF50),
    },
    {
      'image': 'assets/images/suv.png',
      'title': 'Luxury SUVs',
      'subtitle': 'Travel in style with our luxury fleet',
      'color': primaryColor,
    },
    {
      'image': 'assets/images/hatchback.png',
      'title': 'Budget Options',
      'subtitle': 'Economy rides that don\'t compromise on quality',
      'color': const Color(0xFFFF6B6B),
    },
  ];

  Widget _buildFeaturedRides() {
    return SizedBox(
      height: 220, // Increased height to prevent RenderFlex overflow
      child: CarouselSlider(
        options: CarouselOptions(
          height: 200, // Ensure this matches or is less than the SizedBox height
          enlargeCenterPage: true,
          enableInfiniteScroll: true,
          viewportFraction: 0.9,
          initialPage: 0,
          autoPlay: true,
          aspectRatio: 16 / 9,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
        ),
        items: featuredRides.map((ride) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (ride['color'] ?? primaryColor).withOpacity(0.1),
                              (ride['color'] ?? primaryColor).withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      // Car image
                      Positioned(
                        right: 0,
                        bottom: 0,
                        top: 0,
                        child: Image.asset(
                          ride['image'],
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (ride['color'] ?? primaryColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                MaterialCommunityIcons.car,
                                color: (ride['color'] ?? primaryColor),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ride['title'],
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ride['subtitle'],
                              style: TextStyle(
                                color: lightTextColor,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CabBookingScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (ride['color'] ?? primaryColor),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                ),
                                child: const Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decorative elements
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: (ride['color'] ?? primaryColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}