class CategoryPrediction {
  final String category;
  final double confidence;

  const CategoryPrediction({
    required this.category,
    required this.confidence,
  });

  @override
  String toString() =>
      'CategoryPrediction(category: $category, confidence: ${confidence.toStringAsFixed(3)})';
}
