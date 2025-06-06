import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _featuresController;
  late Animation<double> _heroAnimation;
  late Animation<double> _featuresAnimation;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _featuresController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _heroAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: Curves.easeOutBack,
      ),
    );
    _featuresAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _featuresController,
        curve: Curves.easeOut,
      ),
    );

    _heroController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _featuresController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            _buildVisionSection(),
            _buildFeaturesSection(_featuresAnimation),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5, // Increased height
      child: Stack(
        children: [
          // Background image with increased height
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(
                'assets/about/about.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Background decorative circles
          Positioned(
            top: 90,
            right: -50,
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -75,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _heroAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _heroAnimation.value)),
                  child: Opacity(
                    opacity: _heroAnimation.value.clamp(0.0, 1.0),
                    // Ensure opacity is within bounds
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCompanyLogo(),
                          const SizedBox(height: 4),
                          Text(
                            'Revolutionizing travel with innovation and excellence',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(seconds: 3),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/about/wtl-removebg-preview.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Vision',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            "WTL was founded with a vision of making transportation convenient and hassle-free. We understand the importance of reaching your destination comfortably and on time, whether you're heading to an important business meeting, catching a flight, or simply exploring the city.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.black,
              height: 1.5,
            ),
          ),
          // SizedBox(height: 20),
          // Text(
          //   "Our journey began with the aim of creating a service that would cater to all your transportation needs. At WTL, we're on a mission to redefine the way you experience transportation. With a commitment to safety, reliability, and exceptional service, we have become your trusted partner in getting you to your destination with ease.",
          //   style: TextStyle(
          //     fontSize: 14,
          //     fontWeight: FontWeight.w300,
          //     color: Colors.black,
          //     height: 1.5,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(Animation<double> _featuresAnimation) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Features of WTL Service Company',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AnimatedBuilder(
            animation: _featuresAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _featuresAnimation.value)),
                child: Opacity(
                  opacity: _featuresAnimation.value.clamp(0.0, 1.0),
                  child: _buildFeaturesGrid(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'icon': Icons.security,
        'title': 'Safety First',
        'description':
            'Your safety is our top priority. All our drivers undergo rigorous background checks and are trained to ensure your journey is secure.',
      },
      {
        'icon': Icons.access_time,
        'title': 'Reliability',
        'description':
            'Count on us for punctual and dependable service. We understand the importance of being on time, every time.',
      },
      {
        'icon': Icons.favorite_border,
        'title': 'Comfort',
        'description':
            'Our vehicles are meticulously maintained to offer you a comfortable and enjoyable ride. Sit back, relax, and let us take care of the driving.',
      },
      {
        'icon': Icons.location_on,
        'title': 'Convenience',
        'description':
            "Booking a ride with WTL is a breeze. Use our user-friendly app or website to reserve a cab in seconds, and track your driver's progress in real-time."
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio:
                1.2, // Increased aspect ratio to make cards shorter
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _buildFeatureCard(
              features[index]['icon'] as IconData,
              features[index]['title'] as String,
              features[index]['description'] as String,
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 4000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value.clamp(0.0, 1.0)),
          child: Container(
            padding: EdgeInsets.all(20), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60, // Reduced size
                  height: 60, // Reduced size
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 30, // Reduced icon size
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12), // Reduced spacing
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, // Slightly smaller font
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8), // Reduced spacing
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13, // Slightly smaller font
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4, // Tighter line height
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3, // Limit description lines
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
