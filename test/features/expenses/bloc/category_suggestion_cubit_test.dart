import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/category_suggestion_cubit.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/category_suggestion_state.dart';
import 'package:financial_planner_ui_demo/core/models/category_prediction.dart';
import '../../../helpers/mock_repositories.dart';

void main() {
  late MockCategoryClassifierService mockClassifier;

  setUp(() {
    mockClassifier = MockCategoryClassifierService();
  });

  group('CategorySuggestionCubit', () {
    test('initial state has empty suggestions', () {
      final cubit = CategorySuggestionCubit(mockClassifier);
      expect(cubit.state.suggestions, isEmpty);
      cubit.close();
    });

    blocTest<CategorySuggestionCubit, CategorySuggestionState>(
      'emits empty suggestions for empty input',
      build: () => CategorySuggestionCubit(mockClassifier),
      act: (cubit) => cubit.onDescriptionChanged(''),
      expect: () => [const CategorySuggestionState()],
    );

    blocTest<CategorySuggestionCubit, CategorySuggestionState>(
      'emits empty suggestions for whitespace-only input',
      build: () => CategorySuggestionCubit(mockClassifier),
      act: (cubit) => cubit.onDescriptionChanged('   '),
      expect: () => [const CategorySuggestionState()],
    );

    blocTest<CategorySuggestionCubit, CategorySuggestionState>(
      'emits predictions after debounce',
      setUp: () {
        when(() => mockClassifier.predict(any(), topN: any(named: 'topN')))
            .thenReturn([
          const CategoryPrediction(
              category: 'Food & Dining', confidence: 0.85),
          const CategoryPrediction(
              category: 'Shopping', confidence: 0.10),
        ]);
      },
      build: () => CategorySuggestionCubit(mockClassifier),
      act: (cubit) => cubit.onDescriptionChanged('lunch at restaurant'),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const CategorySuggestionState(suggestions: [
          CategoryPrediction(category: 'Food & Dining', confidence: 0.85),
        ]),
      ],
    );

    blocTest<CategorySuggestionCubit, CategorySuggestionState>(
      'filters predictions below confidence threshold of 0.15',
      setUp: () {
        when(() => mockClassifier.predict(any(), topN: any(named: 'topN')))
            .thenReturn([
          const CategoryPrediction(
              category: 'Food & Dining', confidence: 0.50),
          const CategoryPrediction(
              category: 'Shopping', confidence: 0.10),
          const CategoryPrediction(category: 'Other', confidence: 0.05),
        ]);
      },
      build: () => CategorySuggestionCubit(mockClassifier),
      act: (cubit) => cubit.onDescriptionChanged('some text'),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const CategorySuggestionState(suggestions: [
          CategoryPrediction(category: 'Food & Dining', confidence: 0.50),
        ]),
      ],
    );

    blocTest<CategorySuggestionCubit, CategorySuggestionState>(
      'debounces rapid input changes',
      setUp: () {
        when(() => mockClassifier.predict(any(), topN: any(named: 'topN')))
            .thenReturn([
          const CategoryPrediction(
              category: 'Transportation', confidence: 0.90),
        ]);
      },
      build: () => CategorySuggestionCubit(mockClassifier),
      act: (cubit) {
        cubit.onDescriptionChanged('g');
        cubit.onDescriptionChanged('gr');
        cubit.onDescriptionChanged('gra');
        cubit.onDescriptionChanged('grab ride');
      },
      wait: const Duration(milliseconds: 500),
      verify: (_) {
        // Only the last call should trigger predict (after debounce)
        verify(() =>
                mockClassifier.predict(any(), topN: any(named: 'topN')))
            .called(1);
      },
    );
  });
}
