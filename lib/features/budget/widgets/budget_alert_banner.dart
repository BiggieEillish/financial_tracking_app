import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/constants/app_constants.dart';

class BudgetAlertBanner extends StatelessWidget {
  final List<BudgetAlert> alerts;

  const BudgetAlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: alerts.map((alert) => _buildAlertItem(alert)).toList(),
    );
  }

  Widget _buildAlertItem(BudgetAlert alert) {
    final isCritical = alert.level == AlertLevel.critical;
    final alertColor =
        isCritical ? AppConstants.errorColor : AppConstants.warningColor;
    final icon = isCritical
        ? Icons.error_rounded
        : Icons.warning_amber_rounded;

    final spentText =
        '${AppConstants.currencySymbol}${alert.spent.toStringAsFixed(2)}';
    final limitText =
        '${AppConstants.currencySymbol}${alert.limit.toStringAsFixed(2)}';
    final percentText = '${alert.percentage.toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: alertColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: alertColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${alert.category}: $spentText / $limitText ($percentText)',
              style: AppTextStyles.bodyText2.copyWith(
                color: alertColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
