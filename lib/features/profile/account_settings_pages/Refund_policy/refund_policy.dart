import 'package:flutter/material.dart';

const Color indigo = Color(0xFF6366F1);
const Color textSecondary = Color(0xFF64748B);
const Color textPrimary = Color(0xFF1E293B);
const Color primaryLight = Color(0xFF818CF8);
const Color accentColor = Color(0xFF10B981);
const Color backgroundColor = Color(0xFFF8FAFC);

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({Key? key}) : super(key: key);

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
                padding: EdgeInsets.only(left: 50),
                child: Text(
                  'Refund Policy',
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
                                'Our Refund Commitment',
                                style: _headerStyle(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We strive to ensure fair and transparent refund processes for our services. Below are the details of our refund policy.',
                          style: _subHeaderStyle(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Refund Policy Sections
                  _buildSection(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "1. Eligibility",
                    content:
                    "Refunds are permitted in the following scenarios:\n"
                        "• Driver did not show up\n"
                        "• Service was canceled by WTL\n"
                        "• Pre-paid trip canceled within cancellation window",
                  ),

                  _buildSection(
                    icon: Icons.block_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "2. Non-refundable Cases",
                    content: "No refunds will be provided for:\n"
                        "• Customer no-shows\n"
                        "• Last-minute cancellations (within 1 hour)\n"
                        "• Disputed cash payments",
                  ),

                  _buildSection(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: "3. Refund Timeline",
                    content: "• Refunds are initiated within 3 business days\n"
                        "• Refunds reflect within 7-10 business days\n"
                        "• Refund method matches original payment method",
                  ),

                  _buildSection(
                    icon: Icons.contact_support_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: "4. Contact for Refunds",
                    content:
                    "Please email: refunds@worldtriplink.com or call +91 91300 30054 with trip ID and payment receipt.",
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
