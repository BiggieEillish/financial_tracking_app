import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/models/expense_group_with_items.dart';

class ExpenseGroupCard extends StatelessWidget {
  final ExpenseGroupWithItems group;
  final VoidCallback? onTap;

  const ExpenseGroupCard({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = group.primaryCategory;
    final icon = AppConstants.categoryIcons[category] ?? Icons.category_rounded;
    final color = AppConstants.categoryColors[category] ?? AppConstants.textTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.displayName,
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            category == 'Mixed'
                                ? group.categories.join(', ')
                                : category,
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            ' \u2022 ${_formatDate(group.group.date)}',
                            style: AppTextStyles.caption,
                          ),
                          if (group.itemCount > 1)
                            Container(
                              margin: const EdgeInsets.only(left: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.sm),
                              ),
                              child: Text(
                                '${group.itemCount} items',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${AppConstants.currencySymbol}${group.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.amountMedium.copyWith(
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
