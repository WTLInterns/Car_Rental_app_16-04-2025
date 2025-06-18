import 'package:flutter/material.dart';

const Color indigo = Color(0xFF6366F1);
const Color textSecondary = Color(0xFF64748B);
const Color textPrimary = Color(0xFF1E293B);
const Color primaryLight = Color(0xFF818CF8);
const Color accentColor = Color(0xFF10B981);
const Color backgroundColor = Color(0xFFF8FAFC);

class TermAndConditionScreen extends StatelessWidget {
  const TermAndConditionScreen({Key? key}) : super(key: key);

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
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  TextStyle _subHeaderStyle() => const TextStyle(
        fontSize: 16,
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
                padding: EdgeInsets.only(left: 35),
                child: Text(
                  'Terms & Conditions',
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
                                Icons.description_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Terms & Conditions',
                                style: _headerStyle(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'By using WTL services, you agree to these Terms & Conditions. Please read them carefully.',
                          style: _subHeaderStyle(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms Sections
                  _buildSection(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "1 Acceptance",
                    content:
                        "By downloading, registering, or using the WTL app or website, you accept these Terms & Conditions and our Privacy Policy.",
                  ),

                  _buildSection(
                    icon: Icons.directions_car_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "2 Services",
                    content: "WTL provides:\n"
                        "• Cab bookings (private and shared)\n"
                        "• Outstation and local rentals\n"
                        "• Tour packages\n"
                        "• Corporate car hire services",
                  ),

                  _buildSection(
                    icon: Icons.person_add_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "3 Account Registration",
                    content: "You must:\n"
                        "• Be at least 18 years old\n"
                        "• Provide accurate information\n"
                        "• Maintain account confidentiality\n\n"
                        "WTL reserves the right to suspend accounts for misuse, fraud, or policy violations.",
                  ),

                  _buildSection(
                    icon: Icons.event_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: "4 Bookings",
                    content:
                        "• All bookings are subject to driver and vehicle availability.\n"
                        "• Modifications must be made at least 2 hours prior to the scheduled trip.",
                  ),

                  _buildSection(
                    icon: Icons.payment_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "5 Payments",
                    content:
                        "• All fares must be paid through the app or in cash (if permitted).\n"
                        "• We may use third-party gateways. WTL is not liable for gateway-related delays.",
                  ),

                  _buildSection(
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "6 User Conduct",
                    content: "Users must not:\n"
                        "• Harass drivers or other passengers\n"
                        "• Damage vehicles\n"
                        "• Use abusive language or gestures\n"
                        "• Violate applicable traffic or penal laws",
                  ),

                  _buildSection(
                    icon: Icons.star_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "7 Driver Ratings",
                    content:
                        "WTL allows driver and customer ratings. Persistent low ratings may result in service suspension.",
                  ),

                  _buildSection(
                    icon: Icons.cancel_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: "8 Cancellation by WTL",
                    content:
                        "We may cancel bookings due to safety issues, vehicle breakdown, or force majeure. Full refund or rescheduling will be offered.",
                  ),

                  _buildSection(
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "9 Limitation of Liability",
                    content: "WTL is not liable for:\n"
                        "• Delays caused by traffic, weather, or road conditions\n"
                        "• Items left behind in vehicles\n"
                        "• Personal injury due to misuse or third-party negligence",
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
                          "Last updated on June 9, 2025",
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
