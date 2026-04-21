// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Asset Management System';

  @override
  String get splashTitle => 'Assets Management System';

  @override
  String get homeTitle => 'Home';

  @override
  String get logout => 'Logout';

  @override
  String get scan => 'Scan';

  @override
  String get assets => 'Assets';

  @override
  String get assetTitle1 => 'Asset 1';

  @override
  String get assetDescription1 => 'Description of Asset 1';

  @override
  String get assetTitle2 => 'Asset 2';

  @override
  String get assetDescription2 => 'Description of Asset 2';

  @override
  String get assetTitle3 => 'Asset 3';

  @override
  String get assetDescription3 => 'Description of Asset 3';

  @override
  String get checkList => 'Check List';

  @override
  String get qrNfcScannerTitle => 'QR/NFC Scanner';

  @override
  String get qrCode => 'QR Code';

  @override
  String get nfc => 'NFC';

  @override
  String checklistForAsset(Object assetTitle) {
    return 'Checklist for $assetTitle';
  }

  @override
  String get verifyAssetLabel => 'Verify asset label';

  @override
  String get inspectPhysicalCondition => 'Inspect physical condition';

  @override
  String get confirmAssetLocation => 'Confirm asset location';

  @override
  String get markChecklistComplete => 'Mark checklist complete';

  @override
  String get remarks => 'Remarks';

  @override
  String get remarksHint => 'Add any notes about this checklist...';

  @override
  String get save => 'Save';

  @override
  String get emailAndPasswordRequired => 'Email and password are required';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get nfcLoginNotConnected => 'NFC login is not connected yet';

  @override
  String get loading => 'Loading...';

  @override
  String get loginWithEmail => 'Login with\nEmail';

  @override
  String get loginWithNfc => 'Login with\nNFC';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get login => 'Login';

  @override
  String get languageToggleToBangla => 'বাংলা';

  @override
  String get languageToggleToEnglish => 'EN';
}
