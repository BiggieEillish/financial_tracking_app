import 'package:equatable/equatable.dart';
import '../database/database.dart';

class ExpenseGroupWithItems extends Equatable {
  final ExpenseGroup group;
  final List<ExpenseItem> items;

  const ExpenseGroupWithItems({
    required this.group,
    required this.items,
  });

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.amount * item.quantity);

  String get displayName => group.storeName ?? (items.isNotEmpty ? items.first.description : 'Expense');

  String get primaryCategory {
    if (items.isEmpty) return 'Other';
    final categories = items.map((i) => i.category).toSet();
    return categories.length == 1 ? categories.first : 'Mixed';
  }

  Set<String> get categories => items.map((i) => i.category).toSet();

  int get itemCount => items.length;

  bool get isSingleItem => items.length == 1;

  @override
  List<Object?> get props => [group.id, items];
}
