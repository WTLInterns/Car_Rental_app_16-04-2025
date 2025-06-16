import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Safety'), // Corrected title
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
