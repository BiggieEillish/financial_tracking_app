import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/database_service.dart';
import 'user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseService _databaseService;

  UserRepositoryImpl(this._databaseService);

  @override
  Future<User?> getUserById(String id) {
    return _databaseService.database.getUserById(id);
  }

  @override
  Future<void> createUser(String id, String name, String email) async {
    final existing = await getUserById(id);
    if (existing != null) return;

    await _databaseService.database.insertUser(
      UsersCompanion.insert(
        id: id,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateUser(String id, String name, String email) async {
    final existing = await getUserById(id);
    if (existing == null) return;

    await _databaseService.database.updateUser(
      UsersCompanion(
        id: Value(id),
        name: Value(name),
        email: Value(email),
        createdAt: Value(existing.createdAt),
      ),
    );
  }
}
