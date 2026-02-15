import 'package:flutter_test/flutter_test.dart';
import 'package:financial_planner_ui_demo/core/database/database.dart';
import 'package:financial_planner_ui_demo/core/services/notification_service.dart';

void main() {
  late NotificationService notificationService;

  setUp(() {
    notificationService = NotificationService();
  });

  group('NotificationService - checkBudgetThresholds', () {
    test('should return no alerts when spending is under 80%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 700.0, // 70%
        ),
        BudgetWithSpent(
          budget: Budget(
            id: '2',
            userId: 'user1',
            category: 'Transportation',
            limit: 500.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 300.0, // 60%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts, isEmpty);
    });

    test('should return warning alert when spending is exactly 80%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 800.0, // 80%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].category, equals('Food & Dining'));
      expect(alerts[0].limit, equals(1000.0));
      expect(alerts[0].spent, equals(800.0));
      expect(alerts[0].percentage, equals(80.0));
      expect(alerts[0].level, equals(AlertLevel.warning));
    });

    test('should return warning alert when spending is 90%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Shopping',
            limit: 2000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 1800.0, // 90%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].category, equals('Shopping'));
      expect(alerts[0].limit, equals(2000.0));
      expect(alerts[0].spent, equals(1800.0));
      expect(alerts[0].percentage, equals(90.0));
      expect(alerts[0].level, equals(AlertLevel.warning));
    });

    test('should return warning alert when spending is 99%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Entertainment',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 990.0, // 99%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].category, equals('Entertainment'));
      expect(alerts[0].percentage, equals(99.0));
      expect(alerts[0].level, equals(AlertLevel.warning));
    });

    test('should return critical alert when spending is exactly 100%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 1000.0, // 100%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].category, equals('Food & Dining'));
      expect(alerts[0].limit, equals(1000.0));
      expect(alerts[0].spent, equals(1000.0));
      expect(alerts[0].percentage, equals(100.0));
      expect(alerts[0].level, equals(AlertLevel.critical));
    });

    test('should return critical alert when spending is 120%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Transportation',
            limit: 500.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 600.0, // 120%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].category, equals('Transportation'));
      expect(alerts[0].limit, equals(500.0));
      expect(alerts[0].spent, equals(600.0));
      expect(alerts[0].percentage, equals(120.0));
      expect(alerts[0].level, equals(AlertLevel.critical));
    });

    test('should return critical alert when spending is 150%', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Shopping',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 1500.0, // 150%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].percentage, equals(150.0));
      expect(alerts[0].level, equals(AlertLevel.critical));
    });

    test('should skip budgets with zero limit', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 0.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 500.0,
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts, isEmpty);
    });

    test('should skip budgets with negative limit', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Shopping',
            limit: -100.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 50.0,
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts, isEmpty);
    });

    test('should return empty list for empty budget list', () {
      final alerts = notificationService.checkBudgetThresholds([]);

      expect(alerts, isEmpty);
    });

    test('should handle multiple budgets with different thresholds', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 700.0, // 70% - no alert
        ),
        BudgetWithSpent(
          budget: Budget(
            id: '2',
            userId: 'user1',
            category: 'Transportation',
            limit: 500.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 450.0, // 90% - warning
        ),
        BudgetWithSpent(
          budget: Budget(
            id: '3',
            userId: 'user1',
            category: 'Shopping',
            limit: 2000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 2200.0, // 110% - critical
        ),
        BudgetWithSpent(
          budget: Budget(
            id: '4',
            userId: 'user1',
            category: 'Entertainment',
            limit: 0.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 100.0, // skipped - zero limit
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(2));

      // Check Transportation warning
      final transportAlert = alerts.firstWhere(
        (a) => a.category == 'Transportation',
      );
      expect(transportAlert.percentage, equals(90.0));
      expect(transportAlert.level, equals(AlertLevel.warning));

      // Check Shopping critical
      final shoppingAlert = alerts.firstWhere(
        (a) => a.category == 'Shopping',
      );
      expect(shoppingAlert.percentage, closeTo(110.0, 0.01));
      expect(shoppingAlert.level, equals(AlertLevel.critical));
    });

    test('should handle budget with very small limit', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 0.01,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 0.01, // 100%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].percentage, equals(100.0));
      expect(alerts[0].level, equals(AlertLevel.critical));
    });

    test('should handle budget with zero spent', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 0.0, // 0%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts, isEmpty);
    });

    test('should calculate percentage with decimal precision', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 333.33,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 299.997, // ~90%
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].percentage, closeTo(90.0, 0.01));
      expect(alerts[0].level, equals(AlertLevel.warning));
    });

    test('should handle all budgets at exactly 80% threshold', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 800.0,
        ),
        BudgetWithSpent(
          budget: Budget(
            id: '2',
            userId: 'user1',
            category: 'Transportation',
            limit: 500.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 400.0,
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(2));
      expect(alerts.every((a) => a.level == AlertLevel.warning), isTrue);
      expect(alerts.every((a) => a.percentage == 80.0), isTrue);
    });

    test('should handle all budgets at exactly 100% threshold', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 1000.0,
        ),
        BudgetWithSpent(
          budget: Budget(
            id: '2',
            userId: 'user1',
            category: 'Transportation',
            limit: 2000.0,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 2000.0,
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(2));
      expect(alerts.every((a) => a.level == AlertLevel.critical), isTrue);
      expect(alerts.every((a) => a.percentage == 100.0), isTrue);
    });

    test('should preserve all budget information in alerts', () {
      final budgets = [
        BudgetWithSpent(
          budget: Budget(
            id: '1',
            userId: 'user1',
            category: 'Food & Dining',
            limit: 1234.56,
            periodStart: DateTime(2026, 2, 1),
            periodEnd: DateTime(2026, 2, 28),
          ),
          spent: 987.65,
        ),
      ];

      final alerts = notificationService.checkBudgetThresholds(budgets);

      expect(alerts.length, equals(1));
      expect(alerts[0].category, equals('Food & Dining'));
      expect(alerts[0].limit, equals(1234.56));
      expect(alerts[0].spent, equals(987.65));
      expect(alerts[0].percentage, closeTo(80.0, 0.1));
      expect(alerts[0].level, equals(AlertLevel.warning));
    });
  });

  group('NotificationService - singleton pattern', () {
    test('should return same instance', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();
      expect(identical(instance1, instance2), isTrue);
    });
  });
}
