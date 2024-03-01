
class User {
  final String username;
  final String password; // Assume password is handled securely and not stored directly

  User({required this.username, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      
    };
  }
}