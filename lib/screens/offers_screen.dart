import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/services.dart';
import 'package:worldtriplink/screens/user_home_screen.dart';

// Professional color palette
const Color primaryColor = Color(0xFF4A90E2); 

const Color accentColor = Color(0xFF4A90E2);
const Color secondaryColor = Color(0xFFFFCC00);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF666666);
const Color mutedTextColor = Color(0xFF999999);

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  final List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> _allOffers = [
    {
      'id': '1',
      'type': 'cab',
      'title': 'Weekend Getaway',
      'discount': '20% OFF',
      'description':
          'Book a cab for weekend trips and get 20% off on your ride.',
      'validTill': 'June 30, 2023',
      'minBooking': '₹500',
      'code': 'WEEKEND20',
      'color': accentColor,
      'bgColor': const Color(0xFFF0F7FF),
      'image': 'assets/images/cab_offer.png',
    },
    {
      'id': '2',
      'type': 'flight',
      'title': 'International Flights',
      'discount': '15% OFF',
      'description':
          'Book international flights and get 15% off on your booking.',
      'validTill': 'July 15, 2023',
      'minBooking': '₹5000',
      'code': 'FLYNOW15',
      'color': const Color(0xFF4CAF50),
      'bgColor': const Color(0xFFE6FFE6),
      'image': 'assets/images/flight_offer.png',
    },
    {
      'id': '3',
      'type': 'hotel',
      'title': 'Luxury Stays',
      'discount': '25% OFF',
      'description':
          'Book luxury hotels and get 25% off on your stay of 3 nights or more.',
      'validTill': 'August 31, 2023',
      'minBooking': '3 nights',
      'code': 'LUXURY25',
      'color': const Color(0xFFFF6B6B),
      'bgColor': const Color(0xFFFFF0F0),
      'image': 'assets/images/hotel_offer.png',
    },
    {
      'id': '4',
      'type': 'cab',
      'title': 'First Ride Discount',
      'discount': '30% OFF',
      'description': 'New user? Get 30% off on your first cab booking with us.',
      'validTill': 'December 31, 2023',
      'minBooking': '₹300',
      'code': 'FIRST30',
      'color': accentColor,
      'bgColor': const Color(0xFFF0F7FF),
      'image': 'assets/images/cab_offer.png',
    },
    {
      'id': '5',
      'type': 'hotel',
      'title': 'Weekend Escape',
      'discount': '15% OFF',
      'description': 'Book a hotel for weekend stays and enjoy 15% discount.',
      'validTill': 'September 30, 2023',
      'minBooking': '2 nights',
      'code': 'WEEKEND15',
      'color': const Color(0xFFFF6B6B),
      'bgColor': const Color(0xFFFFF0F0),
      'image': 'assets/images/hotel_offer.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadOffers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadOffers() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _offers.addAll(_allOffers);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _filterOffers() {
    if (_selectedTab == 0) return _offers;
    final type = ['all', 'cab', 'hotel', 'flight'][_selectedTab];
    return _offers.where((offer) => offer['type'] == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOffers = _filterOffers();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Offers & Deals',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeScreen()),
              );
            },
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
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: primaryColor),
          )
        : filteredOffers.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildOfferList(filteredOffers),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildTab('All', 0, MaterialCommunityIcons.tag_multiple_outline),
            _buildTab('Cabs', 1, MaterialCommunityIcons.car_outline),
            _buildTab('Hotels', 2, MaterialCommunityIcons.bed_outline),
            _buildTab('Flights', 3, MaterialCommunityIcons.airplane_takeoff),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? primaryColor : lightTextColor,
              ),
              const SizedBox(height: 4),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? primaryColor : lightTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferList(List<Map<String, dynamic>> offers) {
    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildFeaturedOffer(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Available Offers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildOfferCard(offers[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedOffer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, accentColor],
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          'LIMITED TIME',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Summer Special',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Get 30% off on all cab bookings this summer season!',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'SUMMER30',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    // Copy promo code to clipboard
                                    _copyPromoCode(context, 'SUMMER30');
                                  },
                                  child: const Icon(
                                    MaterialCommunityIcons.content_copy,
                                    color: Colors.white,
                                    size: 14,
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
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '30%\nOFF',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with discount badge
            Container(
              height: 100,
              decoration: BoxDecoration(color: offer['bgColor']),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: offer['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getIcon(offer['type']),
                                    color: offer['color'],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${offer['type'][0].toUpperCase()}${offer['type'].substring(1)} Offer',
                                      style: TextStyle(
                                        color: offer['color'],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                offer['title'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: offer['color'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            offer['discount'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Offer details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['description'],
                    style: const TextStyle(
                      color: lightTextColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Offer details row - Fix overflow by making it wrap
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _buildOfferDetail(
                        MaterialCommunityIcons.calendar_range,
                        'Valid till',
                        offer['validTill'],
                      ),
                      _buildOfferDetail(
                        MaterialCommunityIcons.currency_inr,
                        'Min. booking',
                        offer['minBooking'],
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Promo code and apply button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: offer['color'].withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  offer['code'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: offer['color'],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  // Copy promo code to clipboard
                                  _copyPromoCode(context, offer['code']);
                                },
                                child: Icon(
                                  MaterialCommunityIcons.content_copy,
                                  color: offer['color'],
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: offer['color'],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferDetail(IconData icon, String label, String value) {
    return SizedBox(
      width: 120, // Fixed width to prevent overflow
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: mutedTextColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: mutedTextColor),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              MaterialCommunityIcons.tag_off_outline,
              size: 60,
              color: mutedTextColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No offers available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new offers',
            style: TextStyle(fontSize: 14, color: mutedTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedTab = 0;
              });
            },
            icon: const Icon(MaterialCommunityIcons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'cab':
        return MaterialCommunityIcons.car;
      case 'flight':
        return MaterialCommunityIcons.airplane;
      case 'hotel':
        return MaterialCommunityIcons.bed;
      default:
        return MaterialCommunityIcons.tag;
    }
  }

  void _copyPromoCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promo code $code copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
