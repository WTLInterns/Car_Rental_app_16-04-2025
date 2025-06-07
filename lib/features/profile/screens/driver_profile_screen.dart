import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../features/trips/screens/driver_trips_screen.dart';
import '../../../features/trips/screens/driver_ets_trips_screen.dart';

// Enhanced color palette with modern gradients
const Color primaryColor = Color(0xFF3057E3);
const Color secondaryColor = Color(0xFF4A90E2);
const Color accentColor = Color(0xFFFFCC00);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color lightTextColor = Color(0xFF64748B);
const Color mutedTextColor = Color(0xFF94A3B8);
const Color successColor = Color(0xFF10B981);
const Color errorColor = Color(0xFFEF4444);
const Color warningColor = Color(0xFFF59E0B);

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? driver;
  bool isLoading = true;
  int _selectedIndex = 2;
  String? _localImagePath;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDriverData();
    _loadLocalImage();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('driver_profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _localImagePath = imagePath;
      });
    }
  }

  Future<void> _saveLocalImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_profile_image', imagePath);
    setState(() {
      _localImagePath = imagePath;
    });
  }

  Future<void> _removeLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_profile_image');
    setState(() {
      _localImagePath = null;
    });
  }

  Future<void> _loadDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('userData');

      if (driverData != null) {
        final userData = json.decode(driverData);
        final driverId = userData['id'] ?? 353;
        await _fetchDriverFromApi(driverId);
      } else {
        await _fetchDriverFromApi(353);
      }
    } catch (error) {
      debugPrint('Error loading driver data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDriverFromApi(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.worldtriplink.com/vendorDriver/$driverId'),
      );

      if (response.statusCode == 200) {
        final apiData = json.decode(response.body);
        final driverInfo = {
          'name': apiData['driverName'],
          'email': apiData['emailId'],
          'phone': apiData['contactNo'],
          'address': apiData['address'],
          'image': apiData['driverImage']?.toString().trim(),
        };

        setState(() {
          driver = driverInfo;
          isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(driverInfo));

        // Start animations after data is loaded
        _animationController.forward();
      } else {
        debugPrint('Failed to load driver data: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching driver data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
    ].request();
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedTextColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePickerOption(
                      icon: MaterialCommunityIcons.camera,
                      label: 'Camera',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    _buildImagePickerOption(
                      icon: MaterialCommunityIcons.image,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    if (_localImagePath != null)
                      _buildImagePickerOption(
                        icon: MaterialCommunityIcons.delete,
                        label: 'Remove',
                        onTap: _removeImage,
                        color: errorColor,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (color ?? primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (color ?? primaryColor).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await _requestPermissions();

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _saveLocalImage(image.path);
        _showSuccessSnackBar('Profile photo updated successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _removeImage() async {
    await _removeLocalImage();
    _showSuccessSnackBar('Profile photo removed successfully!');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverTripsScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverETSTripsScreen()),
        );
        break;
      case 2:
        break;
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(MaterialCommunityIcons.logout, color: errorColor),
            SizedBox(width: 8),
            Text('Logout Confirmation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: mutedTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _showImagePickerDialog,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              child: _localImagePath != null
                  ? CircleAvatar(
                radius: 60,
                backgroundImage: FileImage(File(_localImagePath!)),
              )
                  : (driver?['image'] != null && driver!['image'].isNotEmpty)
                  ? CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(driver!['image']),
              )
                  : CircleAvatar(
                radius: 60,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  driver?['name'] != null
                      ? driver!['name']
                      .toString()
                      .substring(0, 1)
                      .toUpperCase()
                      : 'D',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  MaterialCommunityIcons.camera,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: TextStyle(
                color: lightTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          secondaryColor,
                          primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          _buildProfileImage(),
                          const SizedBox(height: 12),
                          if (driver?['name'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                driver!['name'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(
                        title: 'Personal Information',
                        icon: MaterialCommunityIcons.account_details,
                        children: [
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: MaterialCommunityIcons.account,
                            title: 'Full Name',
                            value: driver?['name'] ?? 'Not available',
                            iconColors: [Colors.purple, Colors.deepPurple],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: MaterialCommunityIcons.email_outline,
                            title: 'Email Address',
                            value: driver?['email'] ?? 'Not available',
                            iconColors: [Colors.blue, Colors.indigo],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: MaterialCommunityIcons.phone_outline,
                            title: 'Phone Number',
                            value: driver?['phone'] ?? 'Not available',
                            hasAction: true,
                            iconColors: [Colors.orange, Colors.deepOrange],
                          ),
                          const SizedBox(height: 12),
                          if (driver?['address'] != null)
                            _buildInfoRow(
                              icon: MaterialCommunityIcons.map_marker_outline,
                              title: 'Address',
                              value: driver?['address'] ?? 'Not available',
                              iconColors: [Colors.teal, Colors.green],
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoCard(
                        title: 'Account Settings',
                        icon: MaterialCommunityIcons.cog_outline,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: errorColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.redAccent, Colors.red],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  MaterialCommunityIcons.logout,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Sign out of your account',
                                style: TextStyle(fontSize: 12),
                              ),
                              onTap: _logout,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'World Trip Link v1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedTextColor,
                              fontWeight: FontWeight.w600,
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(MaterialCommunityIcons.car_multiple),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(MaterialCommunityIcons.bus),
              label: 'ETS Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(MaterialCommunityIcons.account_circle),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: mutedTextColor,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.3), primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool hasAction = false,
    List<Color>? iconColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconColors ?? [primaryColor.withOpacity(0.3), primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: lightTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}