import 'package:flutter/material.dart';

class AdminDriverTrip {
  final int id;
  final String fromLocation;
  final String toLocation;
  final String tripType;
  final String startDate;
  final String? returnDate;
  final String time;
  final String distance;
  final String? userId;
  final String bookingId;
  final String name;
  final String email;
  final String phone;
  final String userPickup;
  final String userDrop;
  final String date;
  final String userTripType;
  final String bookid;
  final String car;
  final String baseAmount;
  final double amount;
  final int status;
  final String driverBhata;
  final double nightCharges;
  final double gst;
  final double serviceCharge;
  final String? offer;
  final double offerPartial;
  final String? offerAmount;
  final String txnId;
  final String? payment;
  final String? dateEnd;
  final String? timeEnd;
  final String bookingType;
  final String? description;
  final String? carrier;
  final String? companyName;
  final double collection;
  final String? driverEnterOtpTimePreStarted;
  final String? odoometerStarted;
  final String? odoometerEnterTimeStarted;
  final String? driverEnterOtpTimePostTrip;
  final String? odometerEnding;
  final String? odoometerEnterTimeEnding;
  final String? packageName;
  final String? vendorCab;
  final String? vendorDriver;
  final String? penalty;

  AdminDriverTrip({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.tripType,
    required this.startDate,
    this.returnDate,
    required this.time,
    required this.distance,
    this.userId,
    required this.bookingId,
    required this.name,
    required this.email,
    required this.phone,
    required this.userPickup,
    required this.userDrop,
    required this.date,
    required this.userTripType,
    required this.bookid,
    required this.car,
    required this.baseAmount,
    required this.amount,
    required this.status,
    required this.driverBhata,
    required this.nightCharges,
    required this.gst,
    required this.serviceCharge,
    this.offer,
    required this.offerPartial,
    this.offerAmount,
    required this.txnId,
    this.payment,
    this.dateEnd,
    this.timeEnd,
    required this.bookingType,
    this.description,
    this.carrier,
    this.companyName,
    required this.collection,
    this.driverEnterOtpTimePreStarted,
    this.odoometerStarted,
    this.odoometerEnterTimeStarted,
    this.driverEnterOtpTimePostTrip,
    this.odometerEnding,
    this.odoometerEnterTimeEnding,
    this.packageName,
    this.vendorCab,
    this.vendorDriver,
    this.penalty,
  });

  factory AdminDriverTrip.fromJson(Map<String, dynamic> json) {
    return AdminDriverTrip(
      id: json['id'] ?? 0,
      fromLocation: json['fromLocation'] ?? '',
      toLocation: json['toLocation'] ?? '',
      tripType: json['tripType'] ?? 'oneWay',
      startDate: json['startDate'] ?? '',
      returnDate: json['returnDate'],
      time: json['time'] ?? '',
      distance: json['distance']?.toString() ?? '0',
      userId: json['userId']?.toString(),
      bookingId: json['bookingId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userPickup: json['userPickup'] ?? '',
      userDrop: json['userDrop'] ?? '',
      date: json['date'] ?? '',
      userTripType: json['userTripType'] ?? 'oneWay',
      bookid: json['bookid'] ?? '',
      car: json['car'] ?? '',
      baseAmount: json['baseAmount']?.toString() ?? '0',
      amount: (json['amount'] is num) 
          ? (json['amount'] as num).toDouble() 
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] is num ? (json['status'] as num).toInt() : 0,
      driverBhata: json['driverBhata']?.toString() ?? '0',
      nightCharges: (json['nightCharges'] is num) 
          ? (json['nightCharges'] as num).toDouble() 
          : double.tryParse(json['nightCharges']?.toString() ?? '0') ?? 0.0,
      gst: (json['gst'] is num) 
          ? (json['gst'] as num).toDouble() 
          : double.tryParse(json['gst']?.toString() ?? '0') ?? 0.0,
      serviceCharge: (json['serviceCharge'] is num) 
          ? (json['serviceCharge'] as num).toDouble() 
          : double.tryParse(json['serviceCharge']?.toString() ?? '0') ?? 0.0,
      offer: json['offer'],
      offerPartial: (json['offerPartial'] is num) 
          ? (json['offerPartial'] as num).toDouble() 
          : double.tryParse(json['offerPartial']?.toString() ?? '0') ?? 0.0,
      offerAmount: json['offerAmount']?.toString(),
      txnId: json['txnId']?.toString() ?? '0',
      payment: json['payment'],
      dateEnd: json['dateEnd'],
      timeEnd: json['timeEnd'],
      bookingType: json['bookingType'] ?? '',
      description: json['description'],
      carrier: json['carrier'],
      companyName: json['companyName'],
      collection: (json['collection'] is num) 
          ? (json['collection'] as num).toDouble() 
          : double.tryParse(json['collection']?.toString() ?? '0') ?? 0.0,
      driverEnterOtpTimePreStarted: json['driverEnterOtpTimePreStarted'],
      odoometerStarted: json['odoometerStarted'],
      odoometerEnterTimeStarted: json['odoometerEnterTimeStarted'],
      driverEnterOtpTimePostTrip: json['driverEnterOtpTimePostTrip'],
      odometerEnding: json['odometerEnding'],
      odoometerEnterTimeEnding: json['odoometerEnterTimeEnding'],
      packageName: json['packageName'],
      vendorCab: json['vendorCab'],
      vendorDriver: json['vendorDriver'],
      penalty: json['penalty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'tripType': tripType,
      'startDate': startDate,
      'returnDate': returnDate,
      'time': time,
      'distance': distance,
      'userId': userId,
      'bookingId': bookingId,
      'name': name,
      'email': email,
      'phone': phone,
      'userPickup': userPickup,
      'userDrop': userDrop,
      'date': date,
      'userTripType': userTripType,
      'bookid': bookid,
      'car': car,
      'baseAmount': baseAmount,
      'amount': amount,
      'status': status,
      'driverBhata': driverBhata,
      'nightCharges': nightCharges,
      'gst': gst,
      'serviceCharge': serviceCharge,
      'offer': offer,
      'offerPartial': offerPartial,
      'offerAmount': offerAmount,
      'txnId': txnId,
      'payment': payment,
      'dateEnd': dateEnd,
      'timeEnd': timeEnd,
      'bookingType': bookingType,
      'description': description,
      'carrier': carrier,
      'companyName': companyName,
      'collection': collection,
      'driverEnterOtpTimePreStarted': driverEnterOtpTimePreStarted,
      'odoometerStarted': odoometerStarted,
      'odoometerEnterTimeStarted': odoometerEnterTimeStarted,
      'driverEnterOtpTimePostTrip': driverEnterOtpTimePostTrip,
      'odometerEnding': odometerEnding,
      'odoometerEnterTimeEnding': odoometerEnterTimeEnding,
      'packageName': packageName,
      'vendorCab': vendorCab,
      'vendorDriver': vendorDriver,
      'penalty': penalty,
    };
  }

  // Helper methods for status
  String get statusText {
    switch (status) {
      case 0:
        return 'Pending';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 0:
        return const Color(0xFFFF9800); // Orange for pending
      case 2:
        return const Color(0xFF4CAF50); // Red for cancelled
      case 3:
        return const Color(0xFFE53935); // Green for completed
      default:
        return const Color(0xFF666666); // Gray for unknown
    }
  }
}