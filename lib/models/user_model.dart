class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profileImage;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImage,
    this.token,
  });

  /// Create User from JSON (Backend response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '', // Handle both 'id' and '_id'
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phone: json['phone'],
      profileImage: json['profileImage'],
      token: json['token'],
    );
  }

  /// Convert User to JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImage': profileImage,
      'token': token,
    };
  }

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user is organizer
  bool get isOrganizer => role.toLowerCase() == 'organizer';

  /// Check if user is regular user
  bool get isUser => role.toLowerCase() == 'user';

  /// Create a copy of User with some fields updated
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? profileImage,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      token: token ?? this.token,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }
}