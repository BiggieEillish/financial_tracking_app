import '../database/database.dart';

abstract class UserRepository {
  Future<User?> getUserById(String id);
  Future<void> createUser(String id, String name, String email);
  Future<void> updateUser(String id, String name, String email);
}
