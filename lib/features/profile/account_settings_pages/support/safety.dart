import 'package:flutter/material.dart';

const Color indigo = Color(0xFF6366F1);
const Color textSecondary = Color(0xFF64748B);
const Color textPrimary = Color(0xFF1E293B);
const Color primaryLight = Color(0xFF818CF8);
const Color accentColor = Color(0xFF10B981);
const Color backgroundColor = Color(0xFFF8FAFC);

class SafetyPolicyScreen extends StatelessWidget {
  const SafetyPolicyScreen({Key? key}) : super(key: key);

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
                padding: EdgeInsets.only(left: 55),
                child: Text(
                  'Safety Policy',
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
                                Icons.security_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Our Safety Commitment',
                                style: _headerStyle(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your safety is our priority. We implement strict safety standards and provide support to ensure a secure travel experience.',
                          style: _subHeaderStyle(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Safety Policy Sections
                  _buildSection(
                    icon: Icons.directions_car_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "1. Vehicle & Driver Standards",
                    content: "• All vehicles undergo routine inspections\n"
                        "• Drivers are background-verified\n"
                        "• Drivers undergo behavior and safety training",
                  ),

                  _buildSection(
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "2. User Guidelines",
                    content: "• Always wear a seatbelt\n"
                        "• Share your ride with trusted contacts using app options\n"
                        "• Avoid booking through unofficial channels",
                  ),

                  _buildSection(
                    icon: Icons.emergency_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: "3. Emergency Support",
                    content: "• SOS button available in the app\n"
                        "• 24x7 support helpline: +91 91300 30054",
                  ),

                  _buildSection(
                    icon: Icons.medical_services_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "4. Covid-19 & Hygiene",
                    content: "• Regular sanitization of cabs\n"
                        "• Masks recommended for both drivers and passengers\n"
                        "• Hand sanitizers available in cabs (subject to availability)",
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