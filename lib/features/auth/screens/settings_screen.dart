import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/repositories/expense_group_repository.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../core/services/category_classifier_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../../expenses/bloc/expense_list_cubit.dart';
import '../../dashboard/bloc/dashboard_cubit.dart';
import '../../budget/bloc/budget_list_cubit.dart';
import '../../reports/bloc/reports_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final authService = context.read<AuthService>();
    final available = await authService.isBiometricAvailable();
    final enabled = await authService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final authService = context.read<AuthService>();
    await authService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New PINs do not match')),
                );
                return;
              }
              if (newPinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits')),
                );
                return;
              }
              final success = await context.read<AuthCubit>().changePin(
                    oldPinController.text,
                    newPinController.text,
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'PIN changed successfully' : 'Incorrect current PIN'),
                    backgroundColor: success ? AppConstants.successColor : AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMockData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Mock Data'),
        content: const Text(
          'This will add ~170 sample expenses across all categories to train '
          'the AI category classifier and populate your dashboard.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Load Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading mock data...')),
    );

    final userId = context.read<AuthCubit>().userId ?? '';
    final repo = context.read<ExpenseGroupRepository>();
    final mockService = MockDataService(repo, userId);
    final count = await mockService.generateMockData();

    // Retrain classifier with new data
    final classifier = context.read<CategoryClassifierService>();
    final groups = await repo.getExpenseGroups(userId);
    await classifier.initialize(groups);

    if (mounted) {
      // Refresh all cubits
      context.read<ExpenseListCubit>().loadExpenses();
      context.read<DashboardCubit>().loadDashboard();
      context.read<BudgetListCubit>().loadBudgets();
      context.read<ReportsCubit>().loadReports();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $count expense groups successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  }

  void _lockApp() {
    context.read<AuthCubit>().lock();
    context.go('/pin-entry');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          Text('Security', style: AppTextStyles.headline3),
          const SizedBox(height: AppSpacing.md),
          Card(
            elevation: AppConstants.defaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin),
                  title: const Text('Change PIN'),
                  subtitle: const Text('Update your 4-digit PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                ),
                if (_biometricAvailable) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Unlock'),
                    subtitle: const Text('Use fingerprint or face to unlock'),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock, color: AppConstants.errorColor),
                  title: const Text('Lock App'),
                  subtitle: const Text('Lock the app immediately'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _lockApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Data', style: AppTextStyles.headline3),
          const SizedBox(height: AppSpacing.md),
          Card(
            elevation: AppConstants.defaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: ListTile(
              leading: Icon(Icons.science_rounded, color: AppConstants.secondaryColor),
              title: const Text('Load Mock Data'),
              subtitle: const Text('Add sample expenses to train AI classifier'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _loadMockData,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('About', style: AppTextStyles.headline3),
          const SizedBox(height: AppSpacing.md),
          Card(
            elevation: AppConstants.defaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Version'),
              subtitle: Text('1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}
