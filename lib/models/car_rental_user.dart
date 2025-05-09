class CarRentalUser {
  final int? id;
  final String? username;
  final String? email;
  final String? phone;
  final String? password;
  final String? role;

  CarRentalUser({
    this.id,
    this.username,
    this.email,
    this.phone,
    this.password,
    this.role,
  });

  factory CarRentalUser.fromJson(Map<String, dynamic> json) {
    return CarRentalUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }

  CarRentalUser copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? password,
    String? role,
  }) {
    return CarRentalUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}