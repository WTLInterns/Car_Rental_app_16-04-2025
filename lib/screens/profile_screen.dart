import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'login_screen.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  String _userName = 'User';
  String _userEmail = 'user@example.com';
  String _userPhone = '+91 9876543210';
  final String _membership = 'Gold Member';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user is logged in
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _userName = prefs.getString('username') ?? 'User';
      _userEmail = prefs.getString('email') ?? 'user@example.com';
      _userPhone = prefs.getString('phone') ?? '+91 0000000000';
      _isLoading = false;
    });
    _animationController.forward();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout from your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: lightTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              // Clear all user data
              await prefs.remove('isLoggedIn');
              await prefs.remove('userId');
              await prefs.remove('role');
              await prefs.remove('username');
              await prefs.remove('email');
              await prefs.remove('phone');
              
              // Navigate back to login screen
              Navigator.pushAndRemoveUntil(
                ctx,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _userName.isNotEmpty 
        ? _userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'U';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'My Profile',
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                (route) => false,
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
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Info Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accentColor.withOpacity(0.3), width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: accentColor,
                                  child: Text(
                                    initials.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(MaterialCommunityIcons.camera, size: 20, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(MaterialCommunityIcons.email_outline, size: 16, color: lightTextColor),
                              const SizedBox(width: 6),
                              Text(
                                _userEmail,
                                style: const TextStyle(color: lightTextColor, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(MaterialCommunityIcons.phone_outline, size: 16, color: lightTextColor),
                              const SizedBox(width: 6),
                              Text(
                                _userPhone,
                                style: const TextStyle(color: lightTextColor, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFFFFF9E0),
                          //     borderRadius: BorderRadius.circular(20),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: secondaryColor.withOpacity(0.2),
                          //         blurRadius: 8,
                          //         offset: const Offset(0, 2),
                          //       ),
                          //     ],
                          //   ),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       const Icon(MaterialCommunityIcons.crown, size: 18, color: Color(0xFFFFCC00)),
                          //       const SizedBox(width: 8),
                          //       Text(
                          //         _membership,
                          //         style: const TextStyle(
                          //           color: Color(0xFFE6A700),
                          //           fontWeight: FontWeight.w600,
                          //           fontSize: 14,
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    
                    // Stats Section
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
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
                          _buildStatItem('2', 'Upcoming', MaterialCommunityIcons.calendar_clock, accentColor),
                          _buildDivider(),
                          _buildStatItem('4', 'Completed', MaterialCommunityIcons.check_circle_outline, Colors.green),
                          _buildDivider(),
                          _buildStatItem('5', 'Canceled', MaterialCommunityIcons.close_circle_outline, Colors.red[300]!),
                        ],
                      ),
                    ),
                    
                    // Account Settings
                    _buildSection(
                      title: 'Account Settings',
                      icon: MaterialCommunityIcons.account_cog_outline,
                      children: [
                        _buildMenuItem(
                          icon: MaterialCommunityIcons.account_outline,
                          color: accentColor,
                          title: 'Personal Information',
                          description: 'Update your personal details',
                        ),
                        // _buildMenuItem(
                        //   icon: MaterialCommunityIcons.shield_lock_outline,
                        //   color: Colors.green,
                        //   title: 'Security',
                        //   description: 'Manage your password and security settings',
                        // ),
                        // _buildMenuItem(
                        //   icon: MaterialCommunityIcons.bell_outline,
                        //   color: Colors.orange,
                        //   title: 'Notifications',
                        //   description: 'Configure your notification preferences',
                        // ),
                        // _buildMenuItem(
                        //   icon: MaterialCommunityIcons.credit_card_outline,
                        //   color: Colors.purple,
                        //   title: 'Payment Methods',
                        //   description: 'Manage your payment options',
                        // ),
                      ],
                    ),
                    
                    // Support Section
                    // _buildSection(
                    //   title: 'Support',
                    //   icon: MaterialCommunityIcons.lifebuoy,
                    //   children: [
                    //     _buildMenuItem(
                    //       icon: MaterialCommunityIcons.help_circle_outline,
                    //       color: Colors.teal,
                    //       title: 'Help Center',
                    //       description: 'Get help with your bookings and account',
                    //     ),
                    //     _buildMenuItem(
                    //       icon: MaterialCommunityIcons.message_text_outline,
                    //       color: Colors.indigo,
                    //       title: 'Contact Us',
                    //       description: 'Reach out to our customer support team',
                    //     ),
                    //   ],
                    // ),
                    
                    // Logout Button
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(MaterialCommunityIcons.logout, color: Colors.red[400], size: 20),
                        ),
                        title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Sign out from your account', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _showLogoutConfirmation(context),
                      ),
                    ),
                    
                    // Version Info
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      child: Column(
                        children: [
                          const Text('WorldTripLink', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Version 1.0.0', style: TextStyle(color: mutedTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value, 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: const TextStyle(color: lightTextColor, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1, 
      height: 50, 
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200]
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title, 
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  )
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
              fontSize: 15,
            )
          ),
          subtitle: Text(
            description, 
            style: const TextStyle(
              color: lightTextColor, 
              fontSize: 12
            )
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: () {},
        ),
        Divider(height: 1, indent: 70, color: Colors.grey[200]),
      ],
    );
  }
}