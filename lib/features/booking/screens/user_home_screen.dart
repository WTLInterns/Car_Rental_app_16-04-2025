import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../auth/blocs/auth_bloc.dart';
import '../../trips/screens/trips_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'cab_booking_screen.dart';
import 'ets_booking_screen.dart';
import '../../profile/screens/notification_screen.dart';
import '../../profile/screens/offers_screen.dart';

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
            backgroundColor: const Color(AppConfig.primaryColorHex),
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
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
            ],
          )
        : null,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(AppConfig.primaryColorHex),
      unselectedItemColor: const Color(AppConfig.mutedTextColorHex),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      elevation: 8,
      backgroundColor: Colors.white,
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
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  late Timer _timer;
  
  // Add these variables for search functionality
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
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
    super.dispose();
  }
  
  // Simplified search method with mock data for testing
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
      // First try the Google Places API
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$query&key=AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w&components=country:in',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Google Places API Response: ${response.body}');
        
        if (data['status'] == 'OK' && (data['predictions'] as List).isNotEmpty) {
          setState(() {
            _searchSuggestions = data['predictions'];
            _isSearching = false;
          });
        } else {
          // Fallback to mock data if API fails or returns no results
          _useMockData(query);
        }
      } else {
        // Fallback to mock data if API request fails
        _useMockData(query);
      }
    } catch (e) {
      print('Exception during API call: $e');
      // Fallback to mock data if API throws exception
      _useMockData(query);
    }
  }
  
  // Helper method to use mock data when API fails
  void _useMockData(String query) {
    // Common Indian cities for testing
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
    
    // Filter mock data based on query
    final filteredCities = mockCities.where((city) => 
      city['description'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    setState(() {
      _searchSuggestions = filteredCities;
      _isSearching = false;
    });
  }
  
  // Updated method to show the search dialog
  void _showSearchDialog(BuildContext context) {
    _searchController.clear(); // Clear previous search
    _searchSuggestions = []; // Clear previous suggestions
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.location_searching, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text('Where do you want to go?', style: TextStyle(fontSize:15,fontWeight: FontWeight.bold)),
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for your destination...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                  const SizedBox(height: 12),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_searchSuggestions.isEmpty && _searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.location_off, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'No results found',
                            style: TextStyle(color: Colors.grey),
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
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.location_on_outlined, color: Colors.blueAccent),
                              title: Text(suggestion['description'] ?? 'Unknown location'),
                              subtitle: Text(
                                suggestion['structured_formatting']?['secondary_text'] ?? '',
                                style: const TextStyle(color: Colors.grey),
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
                  foregroundColor: Colors.red,
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
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Greeting Section with Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(AppConfig.textColorHex),
                                ),
                              ),
                              const SizedBox(height: 4), // Fixed SizedBox
                              const Text(
                                'Where are you going today?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(AppConfig.lightTextColorHex),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(AppConfig.primaryColorHex),
                              borderRadius: BorderRadius.circular(25),
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
                        onTap: () {
                          _showSearchDialog(context);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).round())),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 22,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Where do you want to go?',
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: Color(AppConfig.mutedTextColorHex)
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Cards Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildServiceCard(
                            icon: Icons.directions_car,
                            label: 'Cab',
                            iconColor: Colors.amber,
                            bgColor: Colors.amber.withAlpha((0.2 * 255).round()),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CabBookingScreen(),
                              ),
                            ),
                          ),
                          
                          _buildServiceCard(
                            icon: Icons.badge,
                            label: 'ETS',
                            iconColor: const Color(AppConfig.primaryColorHex),
                            bgColor: const Color(AppConfig.primaryColorHex).withAlpha((0.2 * 255).round()),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EtsBookingScreen(),
                              ),
                            ),
                          ),
                          
                          _buildServiceCard(
                            icon: Icons.check,
                            label: 'Bus',
                            iconColor: const Color(AppConfig.primaryColorHex),
                            bgColor: const Color(AppConfig.primaryColorHex).withAlpha((0.2 * 255).round()),
                            onTap: () {},
                          ),
                          _buildServiceCard(
                            icon: Icons.star,
                            label: 'Flight',
                            iconColor: Colors.green,
                            bgColor: Colors.green.withAlpha((0.2 * 255).round()),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Keep the Featured Rides carousel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Featured Rides',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConfig.textColorHex),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeaturedRides(),
                    ],
                  ),
                ),

                // Premium Service Card
                _buildPremiumServiceCard(),

                // Promotional Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _buildDiscountCard(),
                ),
              ],
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
      borderRadius: BorderRadius.circular(25),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 8), // Fixed SizedBox
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(AppConfig.textColorHex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumServiceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(AppConfig.primaryColorHex).withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(AppConfig.primaryColorHex),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15), // Fixed SizedBox (line 529)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConfig.textColorHex),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Get priority booking and exclusive offers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(AppConfig.lightTextColorHex),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle premium service action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConfig.primaryColorHex),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(AppConfig.primaryColorHex), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Offer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10), // Fixed SizedBox (line 576)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15), // Fixed SizedBox (line 637)
                  Text(
                    'Get 25% off on your next ride',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SAVE25',
                  style: TextStyle(
                    color: const Color(AppConfig.primaryColorHex),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              // Handle offer action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(AppConfig.primaryColorHex),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Book Now'),
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
    },
    {
      'image': 'assets/images/suv.png',
      'title': 'Luxury SUVs',
      'subtitle': 'Travel in style with our luxury fleet',
    },
    {
      'image': 'assets/images/hatchback.png',
      'title': 'Budget Options',
      'subtitle': 'Economy rides that don\'t compromise on quality',
    },
  ];

  Widget _buildFeaturedRides() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 170,
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
        viewportFraction: 0.95,
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
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[300],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        ride['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ride['subtitle'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
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
    );
  }
}
