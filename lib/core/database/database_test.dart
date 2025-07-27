import 'package:flutter_test/flutter_test.dart';
import 'database_service.dart';

void main() {
  group('Database Service Tests', () {
    test('Database service singleton pattern', () {
      final instance1 = DatabaseService();
      final instance2 = DatabaseService();
      expect(instance1, equals(instance2));
    });

    test('Database initialization', () async {
      final databaseService = DatabaseService();
      await databaseService.initializeDefaultData();
      // If no exception is thrown, initialization was successful
      expect(true, isTrue);
    });
  });
}
