class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime timestamp;
  final String? transactionId;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.timestamp,
    this.transactionId,
    this.metadata,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['payment_method'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      transactionId: json['transaction_id'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'transaction_id': transactionId,
      'metadata': metadata,
    };
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? paymentMethod,
    String? status,
    DateTime? timestamp,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      transactionId: transactionId ?? this.transactionId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String type;
  final String? icon;
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isActive = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'is_active': isActive,
    };
  }
} 