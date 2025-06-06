class FirstBooking {
  final int id;
  final String fromLocation;
  final String toLocation;
  final String tripType;
  final String startDate;
  final String? returnDate;
  final String time;
  final String distance;
  final String bookingId;
  final String name;
  final String email;
  final String phone;
  final String userPickup;
  final String userDrop;
  final String date;
  final String userTripType;
  final String bookid;

  FirstBooking({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.tripType,
    required this.startDate,
    this.returnDate,
    required this.time,
    required this.distance,
    required this.bookingId,
    required this.name,
    required this.email,
    required this.phone,
    required this.userPickup,
    required this.userDrop,
    required this.date,
    required this.userTripType,
    required this.bookid,
  });

  factory FirstBooking.fromJson(Map<String, dynamic> json) {
    return FirstBooking(
      id: json['id'] ?? 0,
      fromLocation: json['fromLocation']?.toString() ?? '',
      toLocation: json['toLocation']?.toString() ?? '',
      tripType: json['tripType']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      returnDate: json['returnDate']?.toString(),
      time: json['time']?.toString() ?? '',
      distance: json['distance']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      userPickup: json['userPickup']?.toString() ?? '',
      userDrop: json['userDrop']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      userTripType: json['userTripType']?.toString() ?? '',
      bookid: json['bookid']?.toString() ?? '',
    );
  }
}
