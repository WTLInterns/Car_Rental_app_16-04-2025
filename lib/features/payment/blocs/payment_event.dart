import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentMethodsEvent extends PaymentEvent {}

class ProcessPaymentEvent extends PaymentEvent {
  final String bookingId;
  final String userId;
  final double amount;
  final String paymentMethod;
  final Map<String, dynamic>? additionalInfo;

  const ProcessPaymentEvent({
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.additionalInfo,
  });

  @override
  List<Object?> get props => [
        bookingId,
        userId,
        amount,
        paymentMethod,
        additionalInfo,
      ];
}

class VerifyPaymentEvent extends PaymentEvent {
  final String paymentId;

  const VerifyPaymentEvent({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

class LoadPaymentHistoryEvent extends PaymentEvent {
  final String userId;

  const LoadPaymentHistoryEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CancelPaymentEvent extends PaymentEvent {
  final String paymentId;
  final String reason;

  const CancelPaymentEvent({
    required this.paymentId,
    required this.reason,
  });

  @override
  List<Object> get props => [paymentId, reason];
}

class ResetPaymentEvent extends PaymentEvent {} 