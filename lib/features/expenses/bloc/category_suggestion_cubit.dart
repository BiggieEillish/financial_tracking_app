import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/category_classifier_service.dart';
import 'category_suggestion_state.dart';

class CategorySuggestionCubit extends Cubit<CategorySuggestionState> {
  final CategoryClassifierService _classifierService;
  Timer? _debounceTimer;

  static const _debounceDuration = Duration(milliseconds: 400);
  static const _confidenceThreshold = 0.15;

  CategorySuggestionCubit(this._classifierService)
      : super(const CategorySuggestionState());

  void onDescriptionChanged(String text) {
    _debounceTimer?.cancel();

    if (text.trim().isEmpty) {
      emit(const CategorySuggestionState());
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      if (isClosed) return;
      final predictions = _classifierService.predict(text, topN: 3);
      final filtered = predictions
          .where((p) => p.confidence >= _confidenceThreshold)
          .toList();
      emit(CategorySuggestionState(suggestions: filtered));
    });
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
