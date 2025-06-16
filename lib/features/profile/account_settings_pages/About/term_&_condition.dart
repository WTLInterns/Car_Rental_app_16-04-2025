import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);

class TermAndConditionScreen extends StatefulWidget {
  const TermAndConditionScreen({super.key});

  @override
  State<TermAndConditionScreen> createState() => _TermAndConditionScreenState();
}

class _TermAndConditionScreenState extends State<TermAndConditionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Term & Condition'), // Corrected title
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
