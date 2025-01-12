# NewLedger

NewLedger is a modern expense tracking and financial management application built with Flutter. It helps users manage their personal and shared expenses with features like expense splitting, receipt scanning, and detailed financial analytics.

## Features

### Core Functionality
- 💰 Track personal and shared expenses
- 👥 Split expenses with friends and family
- 📊 Detailed expense analytics and reporting
- 📷 Receipt scanning and storage
- 📱 Cross-platform support (iOS, Android)

### User Experience
- 🌙 Dark/Light theme support
- 🎨 Modern, intuitive interface
- 📊 Visual expense breakdowns
- 🔍 Advanced expense filtering
- 💱 Multi-currency support

### Technical Features
- 📱 Built with Flutter
- 💾 Local data persistence with Hive
- 📸 Camera integration for receipts
- 🔒 Secure data storage
- 🔄 State management with Provider

## Screenshots
[Add your app screenshots here]

## Installation

1. Ensure you have Flutter installed on your machine. For installation instructions, visit [Flutter's official documentation](https://flutter.dev/docs/get-started/install).

2. Clone the repository:
```git clone https://github.com/YangLin14/NewLedger2.git```

3. Navigate to project directory and install dependencies:
```cd NewLedger2```
```flutter pub get```

4. Run the app:
```flutter run```

## Project Structure

```
lib/
├── views/                    # UI screens
│   ├── splash_view.dart      # Launch screen
│   ├── vault_view.dart       # Main expense list
│   ├── profile_view.dart     # User settings
│   ├── add_expense_view.dart # Add new expenses
│   ├── split_details_view.dart # Expense splitting
│   └── category_detail_view.dart # Category management
├── widgets/                  # Reusable components
│   ├── collaborator_dialog.dart  # User collaboration
│   └── ...
└── ...
```

## Key Features Explained

### Expense Management
- Add and track expenses with detailed information
- Categorize expenses for better organization
- Attach receipts using device camera
- Add notes and additional details to expenses

### Expense Splitting
- Split expenses among multiple users
- Track individual shares and balances
- Manage group expenses efficiently
- Settlement tracking and history

### Categories and Analytics
- Custom expense categories
- Detailed spending analytics
- Visual representations of expenses
- Time-based expense tracking

## Development Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode
- iOS Simulator / Android Emulator
- Physical device (optional)

### Running in Development
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Contributing

We welcome contributions to NewLedger! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## System Requirements

- **iOS**: iOS 12.0 or higher
- **Android**: Android 5.0 (API level 21) or higher
- **Flutter**: Latest stable version
- **Dart**: Latest stable version

## Dependencies

Key packages used in this project:
- `provider`: For state management
- `hive`: Local database storage
- `camera`: Device camera access
- `path_provider`: File system access
- `intl`: Internationalization support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@newledger.com or join our Slack channel.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who have helped shape NewLedger
- Our beta testers for their valuable feedback

---

Made with ❤️ by Fong-Yu (Yang) Lin