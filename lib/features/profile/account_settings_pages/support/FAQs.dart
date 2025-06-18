import 'package:flutter/material.dart';

const Color indigo = Color(0xFF6366F1);
const Color textSecondary = Color(0xFF64748B);
const Color textPrimary = Color(0xFF1E293B);
const Color primaryLight = Color(0xFF818CF8);
const Color accentColor = Color(0xFF10B981);
const Color backgroundColor = Color(0xFFF8FAFC);

class FAQsScreen extends StatelessWidget {
  const FAQsScreen({Key? key}) : super(key: key);

  // Text styles
  TextStyle _titleStyle() => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  TextStyle _contentStyle() => const TextStyle(
    fontSize: 15,
    color: textSecondary,
    height: 1.7,
    letterSpacing: 0.1,
  );

  TextStyle _headerStyle() => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  TextStyle _subHeaderStyle() => const TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 40,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Fare Charges Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.monetization_on_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Our Fare Policy',
                                style: _headerStyle(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We strive to provide transparent and fair pricing for all our services to ensure a seamless travel experience.',
                          style: _subHeaderStyle(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fare Policy Sections
                  _buildSection(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "1. Base Fare Structure",
                    content: "• Minimum fare: ₹100 (varies by city/vehicle)\n"
                        "• Per km rate:\n"
                        "  ○ Hatchback: ₹11/km\n"
                        "  ○ Sedan: ₹12/km\n"
                        "  ○ SUV: ₹15/km",
                  ),

                  _buildSection(
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "2. Additional Charges",
                    content: "• Night Charges (10 PM–6 AM): +10%\n"
                        "• Waiting time: ₹2/min after 10 mins grace\n"
                        "• Toll, Parking, State Taxes: As applicable",
                  ),

                  _buildSection(
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: "3. Surge Pricing",
                    content: "• Applies during high-demand periods (festivals, weekends)\n"
                        "• Surge factor ranges from 1.1x to 2x",
                  ),

                  _buildSection(
                    icon: Icons.directions_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "4. Outstation Trips",
                    content: "• Minimum kilometers per day: 250 km\n"
                        "• Driver allowance: ₹300/day",
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: indigo.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: indigo,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Effective Date: June 2025",
                          style: _contentStyle().copyWith(
                            fontWeight: FontWeight.w600,
                            color: indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Last updated on June 17, 2025",
                          style: _contentStyle().copyWith(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(title, style: _titleStyle()),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                content,
                style: _contentStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}