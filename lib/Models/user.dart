class UserResponse {
  final bool status;
  final User user;

  UserResponse({
    required this.status,
    required this.user,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      status: json['status'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'user': user.toJson(),
    };
  }
}

class User {
  final int id;
  final String name;
  final String slug;
  final String email;
  final String? emailVerifiedAt;
  final String role;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.slug,
    required this.email,
    this.emailVerifiedAt,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      role: json['role'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'role': role,
      'created_at': createdAt,
    };
  }
}
