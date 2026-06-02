# Asset Management System (AMS)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A Flutter-based mobile app for tracking physical assets, scanning tags (QR or RFID), registering devices, and completing on-site maintenance/checklist workflows with offline-first sync.

## What This Project Does

The Asset Management System helps field teams and operations staff manage assets from one app:

- Sign in as **Volunteer** (email/QR) or **Admin**.
- Scan assets using **QR** or **RFID** hardware flow.
- Register new devices and keep unsynced records locally until upload.
- Open asset profile details and update checklist responses in the field.
- Sync checklist/device updates when network becomes available.

## Core Features

- **Role-based app flows** for volunteer and admin users.
- **QR and RFID scanning** support through native scanner integration.
- **Device registration workflow** with offline queue + later sync.
- **Checklist-driven maintenance workflows** with partial/failure sync feedback.
- **Offline-first local persistence** using `sqflite` cache/storage.
- **Secure token/session handling** with `flutter_secure_storage`.
- **Riverpod architecture** for scalable state management.
- **Localization support** for English and Bengali.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State management**: [Riverpod](https://riverpod.dev)
- **Database/cache**: [sqflite](https://pub.dev/packages/sqflite)
- **Scanning/input**: Native hardware scanner channel, [image_picker](https://pub.dev/packages/image_picker), [file_picker](https://pub.dev/packages/file_picker)
- **Secure/local storage**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Networking**: [http](https://pub.dev/packages/http)

## Project Structure

```text
lib/
├── app/          # App-level bootstrapping and routes
├── components/   # Reusable UI components
├── core/         # Shared utilities, constants, and base services
├── data/         # Models, repositories, and data sources
├── l10n/         # Localization resources
├── pages/        # Feature screens/pages
├── providers/    # Riverpod providers and state wiring
├── theme/        # Theme and style configuration
└── main.dart     # Application entry point
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK

### Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Run with API base URL:

   ```bash
   flutter run --dart-define=API_BASE_URL=https://api-ams.bitflex.xyz
   ```

3. Build release APK:

   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://your-api-url.com
   ```

## Demo Flow

Use this flow to quickly understand how a typical user interacts with AMS:

1. **Authenticate** as volunteer (email/QR) or admin.
2. **Scan or register** devices using QR/RFID.
3. **Review asset details** and current status.
4. **Complete checklist tasks** and fill parameter/remarks fields.
5. **Sync queued updates** (checklists/devices) when online.

## Screenshots

### Authentication

<p>
  <img src="assets/images/project-screen-01.png" alt="Welcome and login options" width="24%" />
  <img src="assets/images/project-screen-11.png" alt="Admin login screen" width="24%" />
</p>

### Home and Asset List

<p>
  <img src="assets/images/project-screen-02.png" alt="Home with asset cards" width="24%" />
  <img src="assets/images/project-screen-10.png" alt="Home with all checked toggle" width="24%" />
  <img src="assets/images/project-screen-17.png" alt="Home with pending sync item" width="24%" />
  <img src="assets/images/project-screen-18.png" alt="Home after successful sync" width="24%" />
</p>

### Scan and Register Device

<p>
  <img src="assets/images/project-screen-06.png" alt="Scan asset options dialog" width="24%" />
  <img src="assets/images/project-screen-05.png" alt="RFID scanner active" width="24%" />
  <img src="assets/images/project-screen-04.png" alt="QR scanner active from home" width="24%" />
  <img src="assets/images/project-screen-19.png" alt="QR scanner active from register device" width="24%" />
</p>

<p>
  <img src="assets/images/project-screen-20.png" alt="Register device screen" width="24%" />
  <img src="assets/images/project-screen-03.png" alt="Scan asset page" width="24%" />
</p>

### Asset Creation

<p>
  <img src="assets/images/project-screen-13.png" alt="Asset create form top section" width="24%" />
  <img src="assets/images/project-screen-14.png" alt="Asset create form details section" width="24%" />
</p>

### Asset Details and Checklist

<p>
  <img src="assets/images/project-screen-16.png" alt="Device details screen" width="24%" />
  <img src="assets/images/project-screen-07.png" alt="Checklist default view" width="24%" />
  <img src="assets/images/project-screen-08.png" alt="Checklist with status dropdown" width="24%" />
  <img src="assets/images/project-screen-09.png" alt="Checklist parameter entry" width="24%" />
</p>

### Sync and Device Actions

<p>
  <img src="assets/images/project-screen-15.png" alt="Delete confirmation dialog" width="24%" />
  <img src="assets/images/project-screen-12.png" alt="Home with register and sync actions" width="24%" />
</p>

## License

This project is licensed under the [MIT License](LICENSE).
