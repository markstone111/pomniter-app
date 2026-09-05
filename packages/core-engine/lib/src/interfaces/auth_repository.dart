import 'package:pomniter_shared_models/pomniter_shared_models.dart';

/// Abstract contract for user authentication and session management.
abstract interface class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signInWithEmail(String email, String password);
  Future<User> registerWithEmail(String email, String password);
  Future<User> signInAnonymously();
  Future<void> signOut();
}
