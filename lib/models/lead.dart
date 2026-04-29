class Lead {
  Lead({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      };
}
