import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Contact Info Cards
            _buildContactCard(
              icon: Icons.location_on,
              title: 'Our Location',
              content: 'Kharadi, Pune, Maharashtra\n411014',
            ),
            const SizedBox(height: 20),

            _buildContactCard(
              icon: Icons.phone,
              title: 'Phone Number',
              content: '+91 9730545491',
            ),
            const SizedBox(height: 20),

            _buildContactCard(
              icon: Icons.email,
              title: 'Email Address',
              content: 'info@withoutism.com',
            ),
            const SizedBox(height: 20),

            _buildContactCard(
              icon: Icons.access_time,
              title: 'Working Hours',
              content: 'Monday - Friday: 9:00 AM - 6:00 PM',
            ),
            const SizedBox(height: 40),

            // Divider
            const Divider(thickness: 1),
            const SizedBox(height: 30),

            // Message Form
            const Text(
              'Send us a Message',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildContactForm(),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle form submission
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue, // Use your brand color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Send Message',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Your Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}