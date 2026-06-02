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
  <img src="screenshots/Screenshot_2026-06-02_at_10.55.23_AM-518cb848-1138-4452-be17-14359bf79212.png" alt="Welcome and login options" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.17.18_AM-c52ac6fe-e360-485a-a61f-e1ec7937d129.png" alt="Admin login screen" width="24%" />
</p>

### Home and Asset List

<p>
  <img src="screenshots/Screenshot_2026-06-02_at_11.06.10_AM-9b19fd8c-5e03-4b81-8ff9-ea5a3246663b.png" alt="Home with asset cards" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.16.54_AM-eb10d168-84c8-4db5-8043-a64f5b6e95c6.png" alt="Home with all checked toggle" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.20.43_AM-5538bc82-df40-4ee1-92df-5f201786a406.png" alt="Home with pending sync item" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.20.55_AM-c60007bb-7ea7-46e2-b214-d9764b6fcb41.png" alt="Home after successful sync" width="24%" />
</p>

### Scan and Register Device

<p>
  <img src="screenshots/Screenshot_2026-06-02_at_11.09.57_AM-66698e68-afe0-482f-a4a5-8badaf782006.png" alt="Scan asset options dialog" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.07.20_AM-151ed667-8725-4a28-ab56-5e3adcc5a33a.png" alt="RFID scanner active" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.06.54_AM-d63ce364-e985-4fcb-b0e7-f9c60fa263d1.png" alt="QR scanner active from home" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.44.53_AM-1857aaaa-35b9-49d5-8075-9fcb99858ea7.png" alt="QR scanner active from register device" width="24%" />
</p>

<p>
  <img src="screenshots/Screenshot_2026-06-02_at_11.45.49_AM-8708ea9a-d1ef-4526-bae5-e139458a4c45.png" alt="Register device screen" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.06.37_AM-4799ce82-a613-4a55-b38e-0d1601fe7e1e.png" alt="Scan asset page" width="24%" />
</p>

### Asset Creation

<p>
  <img src="screenshots/Screenshot_2026-06-02_at_11.18.45_AM-296e2b26-df2f-4f6b-812d-8329e6fd5ab1.png" alt="Asset create form top section" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.19.02_AM-18ef3472-d1ef-48ee-b46b-dbdb27ca0117.png" alt="Asset create form details section" width="24%" />
</p>

### Asset Details and Checklist

<p>
  <img src="screenshots/Screenshot_2026-06-02_at_11.20.21_AM-fca66b0b-aaba-45c1-8247-8d86be2d6b80.png" alt="Device details screen" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.14.38_AM-777c3f74-0b5e-4ef4-ab6c-de217db44959.png" alt="Checklist default view" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.15.00_AM-aa54e9e4-445d-4060-b354-9f8d40635883.png" alt="Checklist with status dropdown" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.15.21_AM-b36e3d3c-2209-4633-a99c-2970569e0192.png" alt="Checklist parameter entry" width="24%" />
</p>

### Sync and Device Actions

<p>
  <img src="screenshots/Screenshot_2026-06-02_at_11.20.08_AM-102dcb34-89cb-4c00-b6b5-20e5de0987c6.png" alt="Delete confirmation dialog" width="24%" />
  <img src="screenshots/Screenshot_2026-06-02_at_11.17.51_AM-1143cf25-4dae-4152-a7ca-0b86bbcb1834.png" alt="Home with register and sync actions" width="24%" />
</p>

## License

This project is licensed under the [MIT License](LICENSE).
