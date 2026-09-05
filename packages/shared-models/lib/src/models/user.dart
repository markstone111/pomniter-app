/// Authenticated or anonymous user profile.
class User {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final bool isAnonymous;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
        'isAnonymous': isAnonymous,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isAnonymous: json['isAnonymous'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
