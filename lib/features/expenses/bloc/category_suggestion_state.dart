import 'package:equatable/equatable.dart';
import '../../../core/models/category_prediction.dart';

class CategorySuggestionState extends Equatable {
  final List<CategoryPrediction> suggestions;

  const CategorySuggestionState({this.suggestions = const []});

  @override
  List<Object?> get props => [suggestions];
}
