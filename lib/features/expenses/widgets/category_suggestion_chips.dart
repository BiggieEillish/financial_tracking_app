import 'package:flutter/material.dart';
import '../../../core/models/category_prediction.dart';
import '../../../shared/constants/app_constants.dart';

class CategorySuggestionChips extends StatelessWidget {
  final List<CategoryPrediction> suggestions;
  final ValueChanged<String> onCategorySelected;

  const CategorySuggestionChips({
    super.key,
    required this.suggestions,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                'Suggested categories',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: suggestions.map((prediction) {
              final color =
                  AppConstants.categoryColors[prediction.category] ??
                      Colors.grey;
              final icon =
                  AppConstants.categoryIcons[prediction.category] ??
                      Icons.category;
              final percent = (prediction.confidence * 100).toInt();

              return ActionChip(
                avatar: Icon(icon, size: 18, color: color),
                label: Text(
                  '${prediction.category} ($percent%)',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
                onPressed: () => onCategorySelected(prediction.category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
