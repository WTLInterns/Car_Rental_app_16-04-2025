class CarRentalBooking {
  final int id;
  final String pickUpLocation;
  final String bookId;
  final String dropLocation;
  final String time;
  final String returnTime;
  final String cabType;
  final int? vendorId;
  final int vendorDriverId;
  final int? vendor;
  final String baseAmount;
  final String finalAmount;
  final String? serviceCharge;
  final String gst;
  final String distance;
  final int sittingExpectation; // Fixed typo
  final int partnerSharing;
  final int? shiftTime;
  final List<String> dateOfList;
  final String bookingType;
  final int? status;
  final int? slotId;
  final dynamic carRentaluser;
  final int carRentalUserId;
  final List<ScheduledDate> scheduledDates;
  final dynamic user;

  CarRentalBooking({
    required this.id,
    required this.pickUpLocation,
    required this.bookId,
    required this.dropLocation,
    required this.time,
    required this.returnTime,
    required this.cabType,
    this.vendorId,
    required this.vendorDriverId,
    this.vendor,
    required this.baseAmount,
    required this.finalAmount,
    this.serviceCharge,
    required this.gst,
    required this.distance,
    required this.sittingExpectation,
    required this.partnerSharing,
    this.shiftTime,
    required this.dateOfList,
    required this.bookingType,
    this.status,
    this.slotId,
    this.carRentaluser,
    required this.carRentalUserId,
    required this.scheduledDates,
    this.user,
  });

  factory CarRentalBooking.fromJson(Map<String, dynamic> json) {
    return CarRentalBooking(
      id: json['id'] ?? 0,
      pickUpLocation: json['pickUpLocation'] ?? '',
      bookId: json['bookId'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      time: json['time'] ?? '',
      returnTime: json['returnTime'] ?? '',
      cabType: json['cabType'] ?? '',
      vendorId: json['vendorId'],
      vendorDriverId: json['vendorDriverId'] ?? 0,
      vendor: json['vendor'],
      baseAmount: json['baseAmount']?.toString() ?? '0',
      finalAmount: json['finalAmount']?.toString() ?? '0',
      serviceCharge: json['serviceCharge']?.toString(),
      gst: json['gst']?.toString() ?? '0',
      distance: json['distance']?.toString() ?? '0',
      sittingExpectation: json['sittingExcepatation'] ?? 0,
      partnerSharing: json['partnerSharing'] ?? 0,
      shiftTime: json['shiftTime'],
      dateOfList: List<String>.from(json['dateOfList'] ?? []),
      bookingType: json['bookingType'] ?? 'regular',
      status: json['status'],
      slotId: json['slotId'],
      carRentaluser: json['carRentaluser'],
      carRentalUserId: json['carRentalUserId'] ?? 0,
      scheduledDates: (json['scheduledDates'] as List<dynamic>?)
          ?.map((e) => ScheduledDate.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickUpLocation': pickUpLocation,
      'bookId': bookId,
      'dropLocation': dropLocation,
      'time': time,
      'returnTime': returnTime,
      'cabType': cabType,
      'vendorId': vendorId,
      'vendorDriverId': vendorDriverId,
      'vendor': vendor,
      'baseAmount': baseAmount,
      'finalAmount': finalAmount,
      'serviceCharge': serviceCharge,
      'gst': gst,
      'distance': distance,
      'sittingExpectation': sittingExpectation,
      'partnerSharing': partnerSharing,
      'shiftTime': shiftTime,
      'dateOfList': dateOfList,
      'bookingType': bookingType,
      'status': status,
      'slotId': slotId,
      'carRentaluser': carRentaluser,
      'carRentalUserId': carRentalUserId,
      'scheduledDates': scheduledDates.map((e) => e.toJson()).toList(),
      'user': user,
    };
  }
}

class ScheduledDate {
  final int id;
  final String date;
  final String status;
  final int? slotId;

  ScheduledDate({
    required this.id,
    required this.date,
    required this.status,
    this.slotId,
  });

  factory ScheduledDate.fromJson(Map<String, dynamic> json) {
    return ScheduledDate(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      slotId: json['slotId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'slotId': slotId,
    };
  }
}