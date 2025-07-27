# Database Setup for Financial Planner

This directory contains the SQLite database setup using Drift for the Financial Planner app.

## Files

- `database.dart` - Main database schema and table definitions
- `database_service.dart` - Service layer for database operations
- `database_test.dart` - Tests for database functionality

## Setup Instructions

1. **Install dependencies** (already done):
   ```bash
   flutter pub get
   ```

2. **Generate database code**:
   ```bash
   flutter packages pub run build_runner build
   ```

3. **Run tests**:
   ```bash
   flutter test lib/core/database/database_test.dart
   ```

## Database Schema

### Tables

1. **Users** - Store user information
   - id (Primary Key)
   - email
   - name
   - createdAt

2. **Expenses** - Store expense records
   - id (Primary Key)
   - userId (Foreign Key to Users)
   - amount
   - category
   - description
   - date
   - receiptImage (optional)

3. **Budgets** - Store budget limits
   - id (Primary Key)
   - userId (Foreign Key to Users)
   - category
   - limit
   - periodStart
   - periodEnd

4. **Categories** - Store expense categories
   - id (Primary Key)
   - name
   - icon
   - color

## Usage

```dart
// Get database service instance
final databaseService = DatabaseService();

// Initialize database (called in main.dart)
await databaseService.initializeDefaultData();

// Access database directly if needed
final database = databaseService.database;
```

## Next Steps

After code generation, you can:
1. Add CRUD operations to the service
2. Connect the database to your UI screens
3. Add data models and repositories
4. Implement state management

## Troubleshooting

If you get build errors:
1. Make sure all dependencies are installed
2. Run `flutter clean` then `flutter pub get`
3. Run `flutter packages pub run build_runner clean`
4. Run `flutter packages pub run build_runner build` 