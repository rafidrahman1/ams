// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'অ্যাসেট ম্যানেজমেন্ট সিস্টেম';

  @override
  String get splashTitle => 'অ্যাসেটস ম্যানেজমেন্ট সিস্টেম';

  @override
  String get homeTitle => 'হোম';

  @override
  String get logout => 'লগ আউট';

  @override
  String get scan => 'স্ক্যান';

  @override
  String get assets => 'অ্যাসেটসমূহ';

  @override
  String get assetTitle1 => 'অ্যাসেট ১';

  @override
  String get assetDescription1 => 'অ্যাসেট ১-এর বিবরণ';

  @override
  String get assetTitle2 => 'অ্যাসেট ২';

  @override
  String get assetDescription2 => 'অ্যাসেট ২-এর বিবরণ';

  @override
  String get assetTitle3 => 'অ্যাসেট ৩';

  @override
  String get assetDescription3 => 'অ্যাসেট ৩-এর বিবরণ';

  @override
  String get checkList => 'চেকলিস্ট';

  @override
  String get qrNfcScannerTitle => 'QR/NFC স্ক্যানার';

  @override
  String get qrCode => 'QR কোড';

  @override
  String get nfc => 'NFC';

  @override
  String checklistForAsset(Object assetTitle) {
    return '$assetTitle-এর জন্য চেকলিস্ট';
  }

  @override
  String get verifyAssetLabel => 'অ্যাসেট লেবেল যাচাই করুন';

  @override
  String get inspectPhysicalCondition => 'ভৌত অবস্থা পরীক্ষা করুন';

  @override
  String get confirmAssetLocation => 'অ্যাসেটের অবস্থান নিশ্চিত করুন';

  @override
  String get markChecklistComplete => 'চেকলিস্ট সম্পন্ন হিসেবে চিহ্নিত করুন';

  @override
  String get remarks => 'মন্তব্য';

  @override
  String get remarksHint => 'এই চেকলিস্ট সম্পর্কে নোট যোগ করুন...';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get emailAndPasswordRequired => 'ইমেইল এবং পাসওয়ার্ড আবশ্যক';

  @override
  String get invalidEmailOrPassword => 'ইমেইল বা পাসওয়ার্ড ভুল';

  @override
  String get nfcLoginNotConnected => 'NFC লগইন এখনও সংযুক্ত করা হয়নি';

  @override
  String get loading => 'লোড হচ্ছে...';

  @override
  String get loginWithEmail => 'ইমেইল দিয়ে\nলগইন';

  @override
  String get loginWithNfc => 'NFC দিয়ে\nলগইন';

  @override
  String get email => 'ইমেইল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get loggingIn => 'লগইন হচ্ছে...';

  @override
  String get login => 'লগইন';

  @override
  String get languageToggleToBangla => 'বাংলা';

  @override
  String get languageToggleToEnglish => 'EN';
}
