import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Stack(
              children: [
                Image.asset(
                  'assets/about/service2.jpg',
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  height: 260,
                  color: Colors.black.withOpacity(0.4),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18),
                        Image.asset(
                          'assets/about/wtl-removebg-preview.png',
                          height: 50,
                          width: 120,
                          fit: BoxFit.fill,
                        ),
                        const Text(
                          'Our Services',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Experience premium travel with our diverse range of services',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // One Way Trip Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/about/service.jpg'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ONE WAY TRIP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book a one-way cab for any city-to-city travel. Affordable pricing, calculated per kilometer. Choose from Hatchback, Sedan, Luxury, or SUV. Flexible pickup and drop timings and Get a best cheap rental car rental from budget.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.deepPurple],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'One-way drop service available in Pune.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/about/service2.jpg'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ROUND WAY TRIP',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Plan your trip with easy return options. Book for same-day or multi-day return journeys. Transparent pricing with packages or per-km rates. Book Reliable Round Trip Cabs for Outstation Travel.",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rental Cab Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.deepPurple],
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Text(
                        'Book Your Round Trip Cab Now and Enjoy Flat Discounts!',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/about/about.jpg'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RENTAL CAB SERVICE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hourly or daily rental options. Unlimited km options available (on request). Ideal for city travel, outstation, or airport transfers.',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Why Choose Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.deepPurple],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Choose WTL?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  _InfoTile(
                    icon: Icons.support_agent,
                    title: '24/7 Support',
                    subtitle:
                    'Round-the-clock customer support to assist you with all your travel needs',
                  ),
                  SizedBox(height: 16),
                  _InfoTile(
                    icon: Icons.schedule,
                    title: 'Punctual Service',
                    subtitle:
                    'Timely pickups and drop-offs to ensure you never miss a schedule',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            // Banner at the bottom
            _buildBanner(),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildBanner() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF9D00FF), // Left (purple)
          Color(0xFFFE2D92), // Right (pink)
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.phone, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Book your ride\nnow! Call us at',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            SizedBox(width: 30),
            Column(
              children: [
                Text(
                  '+91 9112085055',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '+91 9130030054',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}