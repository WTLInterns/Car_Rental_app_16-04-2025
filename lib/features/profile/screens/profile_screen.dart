import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:worldtriplink/features/profile/account_settings_screen/Contact_Us.dart';
import 'package:worldtriplink/features/profile/account_settings_screen/about_screen.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../features/booking/screens/user_home_screen.dart';
import '../../../features/auth/models/user_model.dart';

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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'User';
  String _userEmail = 'user@example.com';
  String _userPhone = '+91 9876543210';
  final String _membership = 'Gold Member';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _userId;
  User? _userProfile;

  // Image picker
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

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
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? imagePath = prefs.getString('profile_image');

      if (imagePath != null && File(imagePath).existsSync()) {
        setState(() {
          _imageFile = File(imagePath);
          _imagePath = imagePath;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    }

    final result = await permission.request();
    return result == PermissionStatus.granted;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request appropriate permissions
      Permission permission;
      if (source == ImageSource.camera) {
        permission = Permission.camera;
      } else {
        permission = Permission.photos;
      }

      bool hasPermission = await _requestPermission(permission);

      if (!hasPermission) {
        _showPermissionDialog(source);
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Verify the file exists and is readable
        if (!await imageFile.exists()) {
          throw Exception('Selected image file does not exist');
        }

        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Save the image path to SharedPreferences
        await prefs.setString('profile_image', imageFile.path);

        setState(() {
          _imageFile = imageFile;
          _imagePath = imageFile.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDialog(ImageSource source) {
    String message = source == ImageSource.camera
        ? 'Camera permission is required to take photos. Please enable it in app settings.'
        : 'Photo library permission is required to select images. Please enable it in app settings.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePickerOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildImagePickerOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: accentColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
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

    // Get user ID from shared preferences
    _userId = prefs.getInt('userId');

    if (_userId != null) {
      try {
        // Fetch user profile from API
        final response = await http.get(
          Uri.parse('https://api.worldtriplink.com/auth/getProfile/${_userId}'),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          _userProfile = User.fromJson(data);

          setState(() {
            _userName = _userProfile?.username ?? 'User';
            _userEmail = _userProfile?.email ?? 'user@example.com';
            _userPhone = _userProfile?.phone ?? '+91 0000000000';

            // Update shared preferences with latest data
            prefs.setString('username', _userName);
            prefs.setString('email', _userEmail);
            prefs.setString('phone', _userPhone);

            _isLoading = false;
          });
        } else {
          // If API call fails, use data from shared preferences
          setState(() {
            _userName = prefs.getString('username') ?? 'User';
            _userEmail = prefs.getString('email') ?? 'user@example.com';
            _userPhone = prefs.getString('phone') ?? '+91 0000000000';
            _isLoading = false;
          });
        }
      } catch (e) {
        // If API call fails, use data from shared preferences
        setState(() {
          _userName = prefs.getString('username') ?? 'User';
          _userEmail = prefs.getString('email') ?? 'user@example.com';
          _userPhone = prefs.getString('phone') ?? '+91 0000000000';
          _isLoading = false;
        });
        debugPrint('Error fetching profile: $e');
      }
    } else {
      // If no user ID, use data from shared preferences
      setState(() {
        _userName = prefs.getString('username') ?? 'User';
        _userEmail = prefs.getString('email') ?? 'user@example.com';
        _userPhone = prefs.getString('phone') ?? '+91 0000000000';
        _isLoading = false;
      });
    }

    _animationController.forward();
  }

  // Add method to update profile
  Future<void> _updateProfile(User updatedUser) async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse(
            'https://api.worldtriplink.com/auth/update-profile/${_userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedUser.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _userProfile = User.fromJson(data);

        // Update shared preferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('username', _userProfile?.username ?? 'User');
        prefs.setString('email', _userProfile?.email ?? 'user@example.com');
        prefs.setString('phone', _userProfile?.phone ?? '+91 0000000000');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

        // Reload user data to refresh UI
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.body}')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
      setState(() => _isLoading = false);
      debugPrint('Error updating profile: $e');
    }
  }

  // Add method to show edit profile dialog
  void _showEditProfileDialog() {
    final TextEditingController nameController =
        TextEditingController(text: _userName);
    final TextEditingController emailController =
        TextEditingController(text: _userEmail);
    final TextEditingController phoneController =
        TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
            child: Text("Edit Profile",
                style: TextStyle(fontWeight: FontWeight.bold))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(
                    MaterialCommunityIcons.account_outline,
                    color: Colors.blueAccent,
                  ),
                  filled: true,
                  fillColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(
                    MaterialCommunityIcons.email_outline,
                    color: Colors.blueAccent,
                  ),
                  filled: true,
                  fillColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: const Icon(
                    MaterialCommunityIcons.phone_outline,
                    color: Colors.blueAccent,
                  ),
                  filled: true,
                  fillColor: Colors.blueAccent.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2.0,
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Cancel", style: TextStyle(color: lightTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // Create updated user object
              final updatedUser = (_userProfile ?? User()).copyWith(
                username: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
              );

              Navigator.pop(ctx);
              _updateProfile(updatedUser);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text("Are you sure you want to logout from your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Cancel", style: TextStyle(color: lightTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
              await prefs.remove('profile_image');

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
        ? _userName
            .split(' ')
            .map((n) => n.isNotEmpty ? n[0] : '')
            .take(2)
            .join()
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
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 20),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 24),
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
                                  border: Border.all(
                                      color: accentColor.withOpacity(0.3),
                                      width: 3),
                                ),
                                child: _imageFile != null
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: FileImage(_imageFile!),
                                      )
                                    : CircleAvatar(
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
                              Positioned(
                                bottom: 0,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _showImagePicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D4AA),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
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
                              const Icon(MaterialCommunityIcons.email_outline,
                                  size: 16, color: lightTextColor),
                              const SizedBox(width: 6),
                              Text(
                                _userEmail,
                                style: const TextStyle(
                                    color: lightTextColor, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(MaterialCommunityIcons.phone_outline,
                                  size: 16, color: lightTextColor),
                              const SizedBox(width: 6),
                              Text(
                                _userPhone,
                                style: const TextStyle(
                                    color: lightTextColor, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Stats Section
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
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
                          _buildStatItem(
                              '2',
                              'Upcoming',
                              MaterialCommunityIcons.calendar_clock,
                              accentColor),
                          _buildDivider(),
                          _buildStatItem(
                              '4',
                              'Completed',
                              MaterialCommunityIcons.check_circle_outline,
                              Colors.green),
                          _buildDivider(),
                          _buildStatItem(
                              '5',
                              'Canceled',
                              MaterialCommunityIcons.close_circle_outline,
                              Colors.red[300]!),
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
                          onTap: _showEditProfileDialog,
                        ),
                        _buildMenuItem(
                          icon: MaterialCommunityIcons.account_outline,
                          color: accentColor,
                          title: 'Contact Us',
                          description: "We'd love to hear from you",
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContactScreen(),
                                ));
                          },
                        ),
                        // _buildMenuItem(
                        //   icon: MaterialCommunityIcons.account_outline,
                        //   color: accentColor,
                        //   title: 'Services',
                        //   description:
                        //       'Experience premium travel with our diverse range of services',
                        //   onTap: _showEditProfileDialog,
                        // ),
                        _buildMenuItem(
                          icon: MaterialCommunityIcons.account_outline,
                          color: accentColor,
                          title: 'About WTL',
                          description:
                              'Revolutionizing travel with innovation and excellence',
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AboutScreen(),
                                ));
                          },
                        ),
                      ],
                    ),

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
                          child: Icon(MaterialCommunityIcons.logout,
                              color: Colors.red[400], size: 20),
                        ),
                        title: const Text('Logout',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
                        subtitle: const Text('Sign out from your account',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _showLogoutConfirmation(context),
                      ),
                    ),

                    // Version Info
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      child: Column(
                        children: [
                          const Text('WorldTripLink',
                              style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Version 1.0.0',
                              style: TextStyle(
                                  color: mutedTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: lightTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
        width: 1,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.grey[200]);
  }

  Widget _buildSection(
      {required String title,
      required List<Widget> children,
      required IconData icon}) {
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
                Text(title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    )),
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
    VoidCallback? onTap,
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
          title: Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
                fontSize: 15,
              )),
          subtitle: Text(description,
              style: const TextStyle(color: lightTextColor, fontSize: 12)),
          trailing:
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: onTap,
        ),
        Divider(height: 1, indent: 70, color: Colors.grey[200]),
      ],
    );
  }
}
