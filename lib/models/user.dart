class User {
  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        if (phone != null) 'phone': phone,
      };
}
