import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Privacy Policy'), // Corrected title
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
