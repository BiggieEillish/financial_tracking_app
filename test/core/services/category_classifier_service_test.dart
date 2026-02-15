import 'package:flutter_test/flutter_test.dart';
import 'package:financial_planner_ui_demo/core/services/category_classifier_service.dart';

void main() {
  late CategoryClassifierService service;

  setUp(() {
    service = CategoryClassifierService();
  });

  group('tokenize', () {
    test('lowercases and splits on whitespace', () {
      final tokens = service.tokenize('Hello World');
      expect(tokens, ['hello', 'world']);
    });

    test('strips punctuation', () {
      final tokens = service.tokenize('lunch at restaurant!');
      expect(tokens, ['lunch', 'at', 'restaurant']);
    });

    test('strips numbers', () {
      final tokens = service.tokenize('item 123 price');
      expect(tokens, ['item', 'price']);
    });

    test('drops single-char tokens', () {
      final tokens = service.tokenize('I ate a meal');
      expect(tokens, ['ate', 'meal']);
    });

    test('returns empty list for empty string', () {
      expect(service.tokenize(''), isEmpty);
    });

    test('returns empty list for numbers only', () {
      expect(service.tokenize('123 456'), isEmpty);
    });

    test('handles multiple spaces', () {
      final tokens = service.tokenize('  hello   world  ');
      expect(tokens, ['hello', 'world']);
    });
  });

  group('training and prediction', () {
    test('isModelReady is false before initialization', () {
      expect(service.isModelReady, false);
    });

    test('predict returns empty list when model not ready', () {
      expect(service.predict('food'), isEmpty);
    });

    test('predict returns empty list for empty input', () async {
      await service.initialize([]);
      expect(service.predict(''), isEmpty);
    });

    test('predicts correct category after training', () async {
      await service.initialize([]);

      // Train with multiple examples on top of seed data
      for (int i = 0; i < 10; i++) {
        service.trainOnExpense(
            'lunch at restaurant nasi lemak', 'Food & Dining');
      }

      final predictions = service.predict('lunch at mamak restaurant');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Food & Dining');
    });

    test('returns multiple predictions sorted by confidence', () async {
      await service.initialize([]);

      final predictions = service.predict('restaurant food', topN: 3);
      expect(predictions.length, lessThanOrEqualTo(3));
      // Confidence should be sorted descending
      for (int i = 0; i < predictions.length - 1; i++) {
        expect(predictions[i].confidence,
            greaterThanOrEqualTo(predictions[i + 1].confidence));
      }
    });

    test('confidence values sum to approximately 1.0 for all categories',
        () async {
      await service.initialize([]);

      // Get all predictions (topN = large number)
      final predictions = service.predict('lunch', topN: 100);
      final sum =
          predictions.fold<double>(0, (sum, p) => sum + p.confidence);
      expect(sum, closeTo(1.0, 0.01));
    });

    test('incremental training improves predictions', () async {
      await service.initialize([]);

      // Initially, seed data should provide some prediction
      final before = service.predict('grab ride home');
      expect(before, isNotEmpty);

      // Train more on transportation
      for (int i = 0; i < 10; i++) {
        service.trainOnExpense('grab ride home office', 'Transportation');
      }

      final after = service.predict('grab ride home');
      expect(after, isNotEmpty);
      expect(after.first.category, 'Transportation');
    });
  });

  group('seed data / cold start', () {
    test('provides predictions from seed data alone', () async {
      await service.initialize([]);

      expect(service.isModelReady, true);

      final foodPredictions =
          service.predict('nasi lemak restaurant lunch');
      expect(foodPredictions, isNotEmpty);
      expect(foodPredictions.first.category, 'Food & Dining');
    });

    test('seed data covers transportation', () async {
      await service.initialize([]);

      final predictions = service.predict('grab ride taxi');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Transportation');
    });

    test('seed data covers bills', () async {
      await service.initialize([]);

      final predictions = service.predict('electricity bill tenaga');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Bills & Utilities');
    });

    test('seed data covers shopping', () async {
      await service.initialize([]);

      final predictions = service.predict('lazada shopee online');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Shopping');
    });

    test('seed data covers entertainment', () async {
      await service.initialize([]);

      final predictions = service.predict('netflix spotify streaming');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Entertainment');
    });

    test('seed data covers health', () async {
      await service.initialize([]);

      final predictions = service.predict('doctor clinic hospital');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Health & Medical');
    });

    test('seed data covers education', () async {
      await service.initialize([]);

      final predictions = service.predict('tuition university course');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Education');
    });

    test('seed data covers travel', () async {
      await service.initialize([]);

      final predictions =
          service.predict('flight airasia hotel booking');
      expect(predictions, isNotEmpty);
      expect(predictions.first.category, 'Travel');
    });
  });

  group('CategoryPrediction', () {
    test('prediction has category and confidence', () async {
      await service.initialize([]);
      final predictions = service.predict('restaurant lunch');
      expect(predictions, isNotEmpty);
      final first = predictions.first;
      expect(first.category, isNotEmpty);
      expect(first.confidence, greaterThan(0));
      expect(first.confidence, lessThanOrEqualTo(1.0));
    });
  });
}
