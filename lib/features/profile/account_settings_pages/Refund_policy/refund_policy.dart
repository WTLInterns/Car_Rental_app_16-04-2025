import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF4A90E2);

class RefundPolicyScreen extends StatefulWidget {
  const RefundPolicyScreen({super.key});

  @override
  State<RefundPolicyScreen> createState() => _RefundPolicyScreenState();
}

class _RefundPolicyScreenState extends State<RefundPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Refund Policy'), // Corrected title
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
