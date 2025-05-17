class User {
  final int? id;
  final String? username;
  final String? email;
  final String? phone;
  final String? role;
  final String? profileImage;

  User({
    this.id,
    this.username,
    this.email,
    this.phone,
    this.role,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['id'],
      username: json['username'] ?? json['name'],
      email: json['email'],
      phone: json['mobile'] ?? json['phone'],
      role: json['role'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? role,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
    );
  }
} 