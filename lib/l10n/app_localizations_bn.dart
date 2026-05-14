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
  String get logoutConfirmationTitle => 'লগ আউট নিশ্চিতকরণ';

  @override
  String get logoutConfirmationMessage =>
      'আপনি কি নিশ্চিতভাবে লগ আউট করতে চান?';

  @override
  String get cancel => 'বাতিল';

  @override
  String get scan => 'স্ক্যান';

  @override
  String get adminLogin => 'অ্যাডমিন লগইন';

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
  String get qrNfcScannerTitle => 'QR স্ক্যানার';

  @override
  String get qrCode => 'QR কোড';

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
  String get noInternetConnection =>
      'ইন্টারনেট সংযোগ নেই। অনুগ্রহ করে নেটওয়ার্ক পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get loading => 'লোড হচ্ছে...';

  @override
  String get loginWithEmail => 'ভলান্টিয়ার\nলগইন';

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

  @override
  String get qrScanMismatch => 'QR কোড অ্যাসেট লেবেলের সাথে মেলে না';

  @override
  String get allChecked => 'সবগুলো সম্পন্ন';

  @override
  String get noFullyCheckedAssetsFound =>
      'সম্পূর্ণভাবে সম্পন্ন কোনো অ্যাসেট পাওয়া যায়নি';

  @override
  String get noPartiallyCheckedAssetsFound =>
      'আংশিকভাবে সম্পন্ন কোনো অ্যাসেট পাওয়া যায়নি';

  @override
  String get noPendingChecklistUpdates => 'চেকলিস্টে কোনো অপেক্ষমাণ আপডেট নেই';

  @override
  String get sync => 'সিঙ্ক';

  @override
  String syncedChecklistUpdates(Object synced, Object totalPending) {
    return 'চেকলিস্ট আপডেট সিঙ্ক হয়েছে $synced/$totalPending';
  }

  @override
  String syncFailedSuffix(Object failed) {
    return '($failed টি ব্যর্থ)';
  }

  @override
  String deviceSyncSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ডিভাইস সফলভাবে সিঙ্ক হয়েছে',
      one: '১টি ডিভাইস সফলভাবে সিঙ্ক হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String deviceSyncFailed(Object failedIds, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি ডিভাইস',
      one: '১টি ডিভাইস',
    );
    return '$_temp0 সিঙ্ক করতে ব্যর্থ: $failedIds';
  }

  @override
  String deviceSyncPartial(Object synced, Object total, Object failedIds) {
    return '$syncedটি থেকে $totalটি ডিভাইস সিঙ্ক হয়েছে। ব্যর্থ: $failedIds';
  }

  @override
  String astIdAlreadyAssigned(Object astId) {
    return '$astId ইতিমধ্যে বরাদ্দ করা হয়েছে';
  }

  @override
  String get assetCreateTitle => 'অ্যাসেট তৈরি';

  @override
  String get assetCreateNotice =>
      '* আবশ্যক: অ্যাসেট আইডি, নাম, ঠিকানা, ধরন, ক্যাম্প, ব্লক';

  @override
  String get assetCreateImportantNotice =>
      '• গুরুত্বপূর্ণ: ব্লক লোড করতে প্রথমে ক্যাম্প নির্বাচন করুন';

  @override
  String get assetIdLabel => 'অ্যাসেট আইডি *';

  @override
  String get assetIdHint => 'QR কোড স্ক্যান করুন অথবা আইডি লিখুন';

  @override
  String get nameLabel => 'নাম *';

  @override
  String get nameHint => 'অ্যাসেটের নাম লিখুন';

  @override
  String get typeLabel => 'ধরন';

  @override
  String get amountLabel => 'পরিমাণ';

  @override
  String get amountHint => 'অ্যাসেটের পরিমাণ লিখুন';

  @override
  String get statusLabel => 'অবস্থা';

  @override
  String get campLabel => 'ক্যাম্প';

  @override
  String get blockLabel => 'ব্লক';

  @override
  String get addressLineLabel => 'ঠিকানার লাইন';

  @override
  String get addressLineHint => 'ঠিকানার লাইন লিখুন';

  @override
  String get purchaseDateLabel => 'ক্রয়ের তারিখ';

  @override
  String get manufactureDateLabel => 'উৎপাদনের তারিখ';

  @override
  String get warrantyEndLabel => 'ওয়ারেন্টি শেষ';

  @override
  String get itemsHeading => 'আইটেমসমূহ';

  @override
  String get itemColumn => 'আইটেম';

  @override
  String get descriptionColumn => 'বিবরণ';

  @override
  String get actionColumn => 'অ্যাকশন';

  @override
  String get enterItemHint => 'আইটেম লিখুন';

  @override
  String get enterDescriptionHint => 'বিবরণ লিখুন';

  @override
  String get deleteItem => 'মুছুন';

  @override
  String get addItem => 'আইটেম যোগ করুন';

  @override
  String get assetPhotoLabel => 'অ্যাসেটের ছবি';

  @override
  String get chooseImage => 'ছবি নির্বাচন করুন';

  @override
  String get takePhoto => 'ছবি তুলুন';

  @override
  String get noImageChosen => 'কোনো ছবি নির্বাচিত হয়নি';

  @override
  String get assetAttachmentLabel => 'সংযুক্তি আপলোড';

  @override
  String get chooseAttachment => 'ফাইল নির্বাচন করুন';

  @override
  String get noAttachmentChosen => 'কোনো সংযুক্তি নির্বাচিত হয়নি';

  @override
  String get remove => 'অপসারণ';

  @override
  String get assetDetailsLabel => 'অ্যাসেটের বিস্তারিত';

  @override
  String get assetDetailsHint => 'অ্যাসেটের বিস্তারিত লিখুন';

  @override
  String get createAsset => 'তৈরি করুন';

  @override
  String get saving => 'সংরক্ষণ হচ্ছে...';

  @override
  String get goBack => 'ফিরে যান';

  @override
  String get assetSavedLocally =>
      'অ্যাসেট লোকালভাবে সংরক্ষিত হয়েছে। হোম স্ক্রিন থেকে সিঙ্ক করুন।';

  @override
  String get assetIdRequired => 'অ্যাসেট আইডি আবশ্যক (QR কোড স্ক্যান করুন)';

  @override
  String get nameAndAddressRequired => 'নাম এবং ঠিকানা আবশ্যক';

  @override
  String get typeCampBlockRequired =>
      'ধরন, ক্যাম্প, এবং ব্লক আবশ্যক। উপলভ্য ব্লক লোড করতে প্রথমে ক্যাম্প নির্বাচন করুন।';

  @override
  String errorPrefix(Object error) {
    return 'ত্রুটি: $error';
  }

  @override
  String errorLoadingTypes(Object error) {
    return 'ধরন লোড করতে সমস্যা হয়েছে: $error';
  }

  @override
  String get errorLoadingCamps => 'ক্যাম্প লোড করতে সমস্যা হয়েছে';

  @override
  String errorLoadingBlocks(Object error) {
    return 'ব্লক লোড করতে সমস্যা হয়েছে:\n$error';
  }

  @override
  String get noBlocksAvailableForCamp =>
      'এই ক্যাম্পের জন্য কোনো ব্লক নেই - ক্যাম্প/লোকেশন আছে কি না এবং সেখানে ব্লক আছে কি না যাচাই করুন';

  @override
  String errorCapturingImage(Object error) {
    return 'ছবি ধারণ করতে সমস্যা হয়েছে: $error';
  }

  @override
  String errorPickingImage(Object error) {
    return 'ছবি নির্বাচন করতে সমস্যা হয়েছে: $error';
  }

  @override
  String get registerDevice => 'ডিভাইস নিবন্ধন করুন';

  @override
  String get invalidScanData => 'স্ক্যান ডেটা সঠিক নয়';

  @override
  String deviceRegisteredFor(Object assetTitle) {
    return '$assetTitle-এর জন্য ডিভাইস নিবন্ধিত হয়েছে';
  }

  @override
  String get noChecklistItemsFound => 'কোনো চেকলিস্ট আইটেম পাওয়া যায়নি';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusUnderMaintenance => 'UNDER MAINTENANCE';

  @override
  String get statusApprovalPending => 'APPROVAL PENDING';

  @override
  String get statusInactive => 'INACTIVE';

  @override
  String get deviceDetailsTitle => 'ডিভাইসের বিবরণ';

  @override
  String get deviceNotFound => 'ডিভাইস পাওয়া যায়নি';

  @override
  String get recordIdLabel => 'রেকর্ড আইডি';

  @override
  String get detailsLabel => 'বিবরণ';

  @override
  String get locationLabel => 'লোকেশন';

  @override
  String get imagePathLabel => 'ছবির পথ';

  @override
  String get attachmentPathLabel => 'সংযুক্তির পথ';

  @override
  String get specificationLabel => 'স্পেসিফিকেশন';

  @override
  String get createdAtLabel => 'তৈরি হয়েছে';

  @override
  String get syncedLabel => 'সিঙ্ক হয়েছে';

  @override
  String get yesLabel => 'হ্যাঁ';

  @override
  String get noLabel => 'না';

  @override
  String get pendingSync => '(সিঙ্ক অপেক্ষমাণ)';

  @override
  String get closeLabel => 'বন্ধ করুন';

  @override
  String get parameterLabel => 'প্যারামিটার';

  @override
  String get parameterHint => 'চেকলিস্টের প্যারামিটার লিখুন';

  @override
  String get retakePhoto => 'আবার তুলুন';

  @override
  String get camera => 'ক্যামেরা';

  @override
  String get changeImage => 'পরিবর্তন করুন';

  @override
  String get attachImage => 'ছবি যুক্ত করুন';

  @override
  String get removeImage => 'ছবি অপসারণ করুন';

  @override
  String get imageSelected => 'ছবি নির্বাচিত হয়েছে';

  @override
  String get unknownSyncError => 'সিঙ্ক করার সময় অজানা ত্রুটি ঘটেছে';

  @override
  String get noPendingDevices => 'সিঙ্ক করার জন্য কোনো অপেক্ষমাণ ডিভাইস নেই';
}
