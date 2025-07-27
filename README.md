# Financial Planner UI Demo

A comprehensive Flutter application for personal financial planning with features including expense tracking, budget management, receipt scanning with OCR, and detailed financial analytics.

## 🚀 Features

- **Dashboard**: Overview of financial status with charts and summaries
- **Expense Tracking**: Add, edit, and categorize expenses
- **Budget Management**: Create and monitor budgets for different categories
- **Receipt Scanner**: Scan receipts using camera with OCR text recognition
- **Financial Reports**: Detailed analytics and spending breakdowns
- **Database Storage**: Local SQLite database for data persistence

## 📱 Screenshots

*Add screenshots of your app here once you have them*

## 🛠️ Tech Stack

- **Framework**: Flutter 3.5.0+
- **Language**: Dart
- **Database**: SQLite with Drift ORM
- **Navigation**: Go Router
- **Camera**: Camera plugin with ML Kit OCR
- **State Management**: Provider/Riverpod (based on your implementation)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: 3.5.0 or higher
- **Dart SDK**: 3.5.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Git**

## 🔧 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/financial-planner-ui-demo.git
cd financial-planner-ui-demo
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Database Code

This project uses Drift ORM which requires code generation:

```bash
flutter packages pub run build_runner build
```

### 4. Platform-Specific Setup

#### Android
- Ensure you have Android SDK installed
- The app requires camera permissions for receipt scanning
- Minimum SDK version: 21 (Android 5.0)

#### iOS (macOS only)
- Install Xcode and iOS Simulator
- Run `cd ios && pod install` to install iOS dependencies
- Camera permissions will be requested at runtime

#### Web
- No additional setup required
- Note: Camera features may be limited in web browsers

### 5. Run the Application

```bash
# For development
flutter run

# For specific platforms
flutter run -d android    # Android
flutter run -d ios        # iOS
flutter run -d chrome     # Web
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── database/         # Database models and services
│   ├── navigation/       # Routing configuration
│   └── services/         # Camera, OCR, PDF services
├── features/
│   ├── auth/            # Authentication screens
│   ├── budget/          # Budget management
│   ├── camera/          # Camera functionality
│   ├── dashboard/       # Main dashboard
│   ├── expenses/        # Expense tracking
│   ├── profile/         # User profile
│   └── reports/         # Financial reports
├── shared/
│   ├── constants/       # App constants
│   └── widgets/         # Reusable widgets
└── main.dart           # App entry point
```

## 🔐 Permissions

The app requires the following permissions:

- **Camera**: For scanning receipts
- **Storage**: For saving images and PDFs
- **Internet**: For potential future features

## 🚨 Important Notes

### For Contributors
- This is a demo/UI project - not production-ready
- Database is local SQLite - no cloud sync
- OCR functionality requires Google ML Kit
- Camera features may not work in web browsers

### Known Issues
- Camera resource cleanup warnings in Android logs (non-critical)
- Some Android back navigation warnings (can be fixed with manifest updates)

### Development Status
- ✅ Core functionality implemented
- ✅ Database integration complete
- ✅ Camera and OCR working
- 🔄 UI/UX improvements ongoing
- 📋 Additional features planned

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Drift team for the excellent database solution
- Google ML Kit for OCR capabilities
- All contributors and testers

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](../../issues) page
2. Create a new issue with detailed information
3. Include your Flutter version and platform details

---

**Note**: This is a demo project showcasing Flutter development capabilities. For production use, additional security, testing, and deployment considerations would be necessary.
