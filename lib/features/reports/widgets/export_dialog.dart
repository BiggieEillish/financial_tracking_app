import 'package:flutter/material.dart';

import '../../../shared/constants/app_constants.dart';

/// A dialog that lets the user choose an export format (CSV or PDF) and
/// a date range, then invokes [onExport] with the selected values.
class ExportDialog extends StatefulWidget {
  /// Called when the user taps the Export button.
  ///
  /// [format] is either `'CSV'` or `'PDF'`.
  /// [startDate] and [endDate] define the selected date range.
  final void Function(String format, DateTime startDate, DateTime endDate)
      onExport;

  const ExportDialog({super.key, required this.onExport});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _selectedFormat = 'CSV';
  late DateTime _startDate;
  late DateTime _endDate;

  /// Formats a [DateTime] as `dd MMM yyyy` (e.g. `01 Feb 2026`).
  String _formatDisplayDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = _monthNames[dt.month - 1];
    final y = dt.year.toString();
    return '$d $m $y';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Export Expenses',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Format selection
            Text(
              'Export Format',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.table_chart,
                            size: 20, color: Colors.green[700]),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('CSV (Spreadsheet)'),
                      ],
                    ),
                    value: 'CSV',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() => _selectedFormat = value!);
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            AppConstants.defaultBorderRadius),
                        topRight: Radius.circular(
                            AppConstants.defaultBorderRadius),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.picture_as_pdf,
                            size: 20, color: Colors.red[700]),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('PDF (Document)'),
                      ],
                    ),
                    value: 'PDF',
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() => _selectedFormat = value!);
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(
                            AppConstants.defaultBorderRadius),
                        bottomRight: Radius.circular(
                            AppConstants.defaultBorderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date range
            Text(
              'Date Range',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildDateField(
                    label: 'End Date',
                    date: _endDate,
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onExport(
                      _selectedFormat,
                      _startDate,
                      _endDate,
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius:
              BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppConstants.primaryColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _formatDisplayDate(date),
                    style: AppTextStyles.bodyText2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
