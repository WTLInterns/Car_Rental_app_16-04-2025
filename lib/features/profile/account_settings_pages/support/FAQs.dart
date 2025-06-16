import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('FAQs'), // Corrected title
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
