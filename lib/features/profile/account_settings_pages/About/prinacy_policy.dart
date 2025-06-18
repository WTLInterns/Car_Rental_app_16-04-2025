import 'package:flutter/material.dart';

const Color indigo = Color(0xFF6366F1);
const Color textSecondary = Color(0xFF64748B);
const Color textPrimary = Color(0xFF1E293B);
const Color primaryLight = Color(0xFF818CF8);
const Color accentColor = Color(0xFF10B981);
const Color backgroundColor = Color(0xFFF8FAFC);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  // Text styles
  TextStyle _titleStyle() => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  TextStyle _contentStyle() => const TextStyle(
    fontSize: 14,
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
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: EdgeInsets.only(left: 50),
                child: Text(
                  'Privacy Policy',
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
                                'Your Privacy Matters',
                                style: _headerStyle(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We are committed to protecting your personal information and being transparent about how we collect, use, and share your data.',
                          style: _subHeaderStyle(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Policy Sections
                  _buildSection(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: "1. Introduction",
                    content:
                    "Welcome to WTL (“WTL,” “we,” “our,” or “us”). We are a cab booking and rental service provider based in Kharadi, Pune. Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and protect your information through our mobile application 'WTL' and our website.\n\nBy using our app or website, you agree to the terms outlined in this policy. If you do not agree, please refrain from using our services.",
                  ),

                  _buildSection(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "2. Information We Collect",
                    content:
                    "a. Personal Information\n"
                        "• Full name\n"
                        "• Phone number\n"
                        "• Email address\n"
                        "• Postal/Billing address\n"
                        "• Government-issued IDs (in certain cases for KYC)\n\n"
                        "b. Device and Technical Information\n"
                        "• IP address\n"
                        "• Browser and OS details\n"
                        "• Location (with permission)\n"
                        "• App usage statistics\n\n"
                        "c. Payment Data\n"
                        "• Bank/card details (if stored)\n"
                        "• Transaction information\n\n"
                        "d. Communications\n"
                        "• Customer service chat/email\n"
                        "• Survey or feedback responses",
                  ),

                  _buildSection(
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: "3. How We Use Your Information",
                    content:
                    "• To process bookings, rentals, and payments\n"
                        "• To improve our services and customer support\n"
                        "• To ensure rider and driver safety\n"
                        "• For marketing (only with consent)\n"
                        "• For legal compliance and dispute resolution",
                  ),

                  _buildSection(
                    icon: Icons.share_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: "4. Sharing of Information",
                    content:
                    "We may share your data with:\n"
                        "• Payment processors like Razorpay, Paytm\n"
                        "• Service providers (SMS, email delivery, hosting)\n"
                        "• Law enforcement or regulatory agencies\n"
                        "• Drivers (contact info for booking coordination)\n\n"
                        "We never sell your data to third parties.",
                  ),

                  _buildSection(
                    icon: Icons.delete_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: "5. Retention & Deletion",
                    content:
                    "We retain personal data as long as necessary for the purpose for which it was collected or as required by law. You may request deletion by contacting us at: info@worldtriplink.com",
                  ),

                  _buildSection(
                    icon: Icons.cookie_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: "6. Cookies and Tracking",
                    content:
                    "Cookies and app trackers help us improve service delivery and performance analytics. You can control tracking preferences in your browser or phone settings.",
                  ),

                  _buildSection(
                    icon: Icons.child_care_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "7. Children’s Privacy",
                    content:
                    "Our services are not intended for individuals under 18. We do not knowingly collect personal information from minors.",
                  ),

                  _buildSection(
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "8. Data Security",
                    content:
                    "• SSL Encryption\n"
                        "• Secure server storage\n"
                        "• Periodic audits and security reviews\n"
                        "• Role-based access control",
                  ),

                  _buildSection(
                    icon: Icons.gavel_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: "9. Your Rights",
                    content:
                    "You may:\n"
                        "• Request access, correction, or deletion of data\n"
                        "• Object to processing for marketing\n"
                        "• Withdraw consent anytime",
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