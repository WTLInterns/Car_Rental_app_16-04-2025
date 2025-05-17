import 'package:equatable/equatable.dart';

import '../models/payment_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentMethodsLoaded extends PaymentState {
  final List<PaymentMethod> paymentMethods;

  const PaymentMethodsLoaded(this.paymentMethods);

  @override
  List<Object> get props => [paymentMethods];
}

class PaymentProcessed extends PaymentState {
  final Payment payment;

  const PaymentProcessed(this.payment);

  @override
  List<Object> get props => [payment];
}

class PaymentVerified extends PaymentState {
  final Payment payment;

  const PaymentVerified(this.payment);

  @override
  List<Object> get props => [payment];
}

class PaymentHistoryLoaded extends PaymentState {
  final List<Payment> payments;

  const PaymentHistoryLoaded(this.payments);

  @override
  List<Object> get props => [payments];
}

class PaymentCancelled extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object> get props => [message];
} 