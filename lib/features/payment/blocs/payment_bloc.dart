import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_exception.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;

  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(PaymentInitial()) {
    on<LoadPaymentMethodsEvent>(_onLoadPaymentMethods);
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<VerifyPaymentEvent>(_onVerifyPayment);
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
    on<CancelPaymentEvent>(_onCancelPayment);
    on<ResetPaymentEvent>(_onResetPayment);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethodsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      
      final paymentMethods = await _paymentRepository.getPaymentMethods();
      
      emit(PaymentMethodsLoaded(paymentMethods));
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      
      final payment = await _paymentRepository.processPayment(
        bookingId: event.bookingId,
        userId: event.userId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        additionalInfo: event.additionalInfo,
      );
      
      emit(PaymentProcessed(payment));
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> _onVerifyPayment(
    VerifyPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      
      final payment = await _paymentRepository.verifyPayment(event.paymentId);
      
      emit(PaymentVerified(payment));
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      
      final payments = await _paymentRepository.getPaymentHistory(event.userId);
      
      emit(PaymentHistoryLoaded(payments));
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  Future<void> _onCancelPayment(
    CancelPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentLoading());
      
      final success = await _paymentRepository.cancelPayment(
        event.paymentId,
        event.reason,
      );
      
      if (success) {
        emit(PaymentCancelled());
      } else {
        emit(PaymentError('Failed to cancel payment'));
      }
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  void _onResetPayment(
    ResetPaymentEvent event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentInitial());
  }

  // Helper to handle errors
  void _handleError(String message, dynamic error) {
    if (error is AppException) {
      emit(PaymentError(error.message));
    } else {
      emit(PaymentError('$message: ${error.toString()}'));
    }
  }
} 