import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    // Load notifications with a slight delay to simulate fetching
    Future.delayed(const Duration(milliseconds: 800), () {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    // Sample notifications for demonstration
    setState(() {
      _notifications = [
        NotificationItem(
          id: '1',
          title: 'Booking Confirmed',
          message: 'Your cab booking #CAB12345 has been confirmed.',
          date: DateTime.now().subtract(const Duration(minutes: 5)),
          type: 'booking_confirmation',
          isRead: false,
          bookingId: 'CAB12345',
        ),
        NotificationItem(
          id: '2',
          title: 'Driver Assigned',
          message: 'Driver Rahul has been assigned to your booking #CAB12345.',
          date: DateTime.now().subtract(const Duration(hours: 1)),
          type: 'driver_assigned',
          isRead: true,
          bookingId: 'CAB12345',
        ),
        NotificationItem(
          id: '3',
          title: 'Special Offer',
          message: 'Use code WEEKEND25 for 25% off on your next booking!',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: 'promotion',
          isRead: false,
          bookingId: null,
        ),
        NotificationItem(
          id: '4',
          title: 'Trip Completed',
          message: 'Your trip #CAB12340 has been completed. Rate your experience!',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: 'trip_completed',
          isRead: true,
          bookingId: 'CAB12340',
        ),
        NotificationItem(
          id: '5',
          title: 'Payment Successful',
          message: 'Payment of ₹450 for booking #CAB12338 was successful.',
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: 'payment',
          isRead: true,
          bookingId: 'CAB12338',
        ),
      ];
      
      // Sort by date, most recent first
      _notifications.sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
    });
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you when there's something new",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh with a delay
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(seconds: 1));
        _loadNotifications();
        return Future.value();
      },
      child: ListView.builder(
        itemCount: _notifications.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    // Choose icon based on notification type
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'booking_confirmation':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'driver_assigned':
        icon = Icons.person;
        iconColor = Colors.blue;
        break;
      case 'promotion':
        icon = Icons.local_offer;
        iconColor = Colors.amber;
        break;
      case 'trip_completed':
        icon = Icons.flag;
        iconColor = Colors.purple;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          // Handle notification tap based on type
          // For example, navigate to booking details if it's a booking notification
          if (notification.bookingId != null) {
            // Navigate to booking details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Viewing details for ${notification.bookingId}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead ? Colors.white : const Color(0xFFF0F7FF),
            border: notification.isRead
                ? null
                : Border.all(color: const Color(0xFF4A90E2), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A90E2),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA0A0A0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        } else {
          return '${difference.inMinutes} min ago';
        }
      } else {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String type;
  final bool isRead;
  final String? bookingId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    required this.isRead,
    this.bookingId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    String? type,
    bool? isRead,
    String? bookingId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}