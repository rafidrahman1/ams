# Asset Management System (AMS)

A robust and efficient Asset Management System built with Flutter, designed to streamline the tracking and maintenance of assets using modern mobile technologies.

## 🚀 Features

- **Multi-Modal Identification**: 
  - **QR Code Scanning**: High-performance QR scanning using `mobile_scanner`.
  - **NFC Support**: Read asset data directly from NFC tags for quick access.
- **Asset Management**:
  - Detailed asset profiles and status tracking.
  - Interactive **Checklist System** for maintenance and verification.
- **State Management**: Robust architecture powered by **Riverpod**.
- **Offline Capabilities**:
  - **Local Caching**: Seamless performance even without internet using `sqflite`.
  - **Secure Storage**: Sensitive information (tokens, credentials) managed via `flutter_secure_storage`.
- **Localization**: Full support for multiple languages, including **Bengali (বাংলা)**.
- **Environment Configuration**: Easy environment switching using Dart defines.
- **Custom UI**: Beautiful splash screen and intuitive user interface.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Scanning**: [mobile_scanner](https://pub.dev/packages/mobile_scanner) & [nfc_manager](https://pub.dev/packages/nfc_manager)
- **Storage**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) & [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Networking**: [http](https://pub.dev/packages/http)

## 📁 Project Structure

```text
lib/
├── l10n/               # Localization files (ARB, generated Dart)
└── src/
    ├── core/           # Core configurations, storage, and utilities
    │   ├── config/     # App environment configurations
    │   └── storage/    # Database and secure storage logic
    └── features/       # Feature-based modules
        ├── data/       # Models and repositories
        └── presentation/ # UI Screens, Widgets, and Providers
```

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK: `^3.11.4`
- Dart SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/asset_management_system.git
   cd asset_management_system
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   You must provide the `API_BASE_URL` via `--dart-define`.

   **Development**:
   ```bash
   flutter run --dart-define=API_BASE_URL=https://api-ams.bitflex.xyz
   ```

   **Release Build**:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://your-api-url.com
   ```

## 📸 Screenshots

*(Add your screenshots here to showcase the app)*

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

---
Built with ❤️ by [Your Name/Bitflex]
