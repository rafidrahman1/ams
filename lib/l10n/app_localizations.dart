import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset Management System'**
  String get appTitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Assets Management System'**
  String get splashTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout Confirmation'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmationMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @assetTitle1.
  ///
  /// In en, this message translates to:
  /// **'Asset 1'**
  String get assetTitle1;

  /// No description provided for @assetDescription1.
  ///
  /// In en, this message translates to:
  /// **'Description of Asset 1'**
  String get assetDescription1;

  /// No description provided for @assetTitle2.
  ///
  /// In en, this message translates to:
  /// **'Asset 2'**
  String get assetTitle2;

  /// No description provided for @assetDescription2.
  ///
  /// In en, this message translates to:
  /// **'Description of Asset 2'**
  String get assetDescription2;

  /// No description provided for @assetTitle3.
  ///
  /// In en, this message translates to:
  /// **'Asset 3'**
  String get assetTitle3;

  /// No description provided for @assetDescription3.
  ///
  /// In en, this message translates to:
  /// **'Description of Asset 3'**
  String get assetDescription3;

  /// No description provided for @checkList.
  ///
  /// In en, this message translates to:
  /// **'Check List'**
  String get checkList;

  /// No description provided for @qrNfcScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get qrNfcScannerTitle;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @checklistForAsset.
  ///
  /// In en, this message translates to:
  /// **'Checklist for {assetTitle}'**
  String checklistForAsset(Object assetTitle);

  /// No description provided for @verifyAssetLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify asset label'**
  String get verifyAssetLabel;

  /// No description provided for @inspectPhysicalCondition.
  ///
  /// In en, this message translates to:
  /// **'Inspect physical condition'**
  String get inspectPhysicalCondition;

  /// No description provided for @confirmAssetLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm asset location'**
  String get confirmAssetLocation;

  /// No description provided for @markChecklistComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark checklist complete'**
  String get markChecklistComplete;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @remarksHint.
  ///
  /// In en, this message translates to:
  /// **'Add any notes about this checklist...'**
  String get remarksHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @emailAndPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required'**
  String get emailAndPasswordRequired;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Login with\nEmail'**
  String get loginWithEmail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @languageToggleToBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageToggleToBangla;

  /// No description provided for @languageToggleToEnglish.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageToggleToEnglish;

  /// No description provided for @qrScanMismatch.
  ///
  /// In en, this message translates to:
  /// **'QR code does not match the asset label'**
  String get qrScanMismatch;

  /// No description provided for @allChecked.
  ///
  /// In en, this message translates to:
  /// **'All Checked'**
  String get allChecked;

  /// No description provided for @noFullyCheckedAssetsFound.
  ///
  /// In en, this message translates to:
  /// **'No fully checked assets found'**
  String get noFullyCheckedAssetsFound;

  /// No description provided for @noPartiallyCheckedAssetsFound.
  ///
  /// In en, this message translates to:
  /// **'No partially checked assets found'**
  String get noPartiallyCheckedAssetsFound;

  /// No description provided for @noPendingChecklistUpdates.
  ///
  /// In en, this message translates to:
  /// **'No pending checklist updates'**
  String get noPendingChecklistUpdates;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncedChecklistUpdates.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced}/{totalPending} checklist updates'**
  String syncedChecklistUpdates(Object synced, Object totalPending);

  /// No description provided for @syncFailedSuffix.
  ///
  /// In en, this message translates to:
  /// **'({failed} failed)'**
  String syncFailedSuffix(Object failed);

  /// No description provided for @deviceSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully synced {count, plural, =1{1 device} other{{count} devices}}'**
  String deviceSyncSuccess(num count);

  /// No description provided for @deviceSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync {count, plural, =1{1 device} other{{count} devices}}: {failedIds}'**
  String deviceSyncFailed(Object failedIds, num count);

  /// No description provided for @deviceSyncPartial.
  ///
  /// In en, this message translates to:
  /// **'Synced {synced} of {total} devices. Failed: {failedIds}'**
  String deviceSyncPartial(Object synced, Object total, Object failedIds);

  /// No description provided for @astIdAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'{astId} has already been assigned'**
  String astIdAlreadyAssigned(Object astId);

  /// No description provided for @assetCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset Create'**
  String get assetCreateTitle;

  /// No description provided for @assetCreateNotice.
  ///
  /// In en, this message translates to:
  /// **'* Required: Asset ID, Name, Address, Type, Camp, Block'**
  String get assetCreateNotice;

  /// No description provided for @assetCreateImportantNotice.
  ///
  /// In en, this message translates to:
  /// **'• Important: Select Camp FIRST to load available Blocks'**
  String get assetCreateImportantNotice;

  /// No description provided for @assetIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset ID *'**
  String get assetIdLabel;

  /// No description provided for @assetIdHint.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code or enter ID'**
  String get assetIdHint;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter asset name'**
  String get nameHint;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter asset amount'**
  String get amountHint;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @campLabel.
  ///
  /// In en, this message translates to:
  /// **'Camp'**
  String get campLabel;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabel;

  /// No description provided for @addressLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Line'**
  String get addressLineLabel;

  /// No description provided for @addressLineHint.
  ///
  /// In en, this message translates to:
  /// **'Enter address line'**
  String get addressLineHint;

  /// No description provided for @purchaseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDateLabel;

  /// No description provided for @manufactureDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Manufacture Date'**
  String get manufactureDateLabel;

  /// No description provided for @warrantyEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Warranty End'**
  String get warrantyEndLabel;

  /// No description provided for @itemsHeading.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsHeading;

  /// No description provided for @itemColumn.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemColumn;

  /// No description provided for @descriptionColumn.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionColumn;

  /// No description provided for @actionColumn.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionColumn;

  /// No description provided for @enterItemHint.
  ///
  /// In en, this message translates to:
  /// **'Enter item'**
  String get enterItemHint;

  /// No description provided for @enterDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescriptionHint;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItem;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @assetPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset Photo'**
  String get assetPhotoLabel;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get chooseImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @noImageChosen.
  ///
  /// In en, this message translates to:
  /// **'No image chosen'**
  String get noImageChosen;

  /// No description provided for @assetAttachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Attachment'**
  String get assetAttachmentLabel;

  /// No description provided for @chooseAttachment.
  ///
  /// In en, this message translates to:
  /// **'Choose Attachment'**
  String get chooseAttachment;

  /// No description provided for @noAttachmentChosen.
  ///
  /// In en, this message translates to:
  /// **'No attachment chosen'**
  String get noAttachmentChosen;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @assetDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset Details'**
  String get assetDetailsLabel;

  /// No description provided for @assetDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter asset details'**
  String get assetDetailsHint;

  /// No description provided for @createAsset.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAsset;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @assetSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Asset saved locally. Sync from Home screen.'**
  String get assetSavedLocally;

  /// No description provided for @assetIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Asset ID is required (Scan QR code)'**
  String get assetIdRequired;

  /// No description provided for @nameAndAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and address are required'**
  String get nameAndAddressRequired;

  /// No description provided for @typeCampBlockRequired.
  ///
  /// In en, this message translates to:
  /// **'Type, camp, and block are required. Ensure camp is selected first to load available blocks.'**
  String get typeCampBlockRequired;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @errorLoadingTypes.
  ///
  /// In en, this message translates to:
  /// **'Error loading types: {error}'**
  String errorLoadingTypes(Object error);

  /// No description provided for @errorLoadingCamps.
  ///
  /// In en, this message translates to:
  /// **'Error loading camps'**
  String get errorLoadingCamps;

  /// No description provided for @errorLoadingBlocks.
  ///
  /// In en, this message translates to:
  /// **'Error loading blocks:\n{error}'**
  String errorLoadingBlocks(Object error);

  /// No description provided for @noBlocksAvailableForCamp.
  ///
  /// In en, this message translates to:
  /// **'No blocks available for this camp - check if camp/location exists and has blocks'**
  String get noBlocksAvailableForCamp;

  /// No description provided for @errorCapturingImage.
  ///
  /// In en, this message translates to:
  /// **'Error capturing image: {error}'**
  String errorCapturingImage(Object error);

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(Object error);

  /// No description provided for @registerDevice.
  ///
  /// In en, this message translates to:
  /// **'Register device'**
  String get registerDevice;

  /// No description provided for @invalidScanData.
  ///
  /// In en, this message translates to:
  /// **'Invalid scan data'**
  String get invalidScanData;

  /// No description provided for @deviceRegisteredFor.
  ///
  /// In en, this message translates to:
  /// **'Device registered for {assetTitle}'**
  String deviceRegisteredFor(Object assetTitle);

  /// No description provided for @noChecklistItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No checklist items found'**
  String get noChecklistItemsFound;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @statusUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'UNDER MAINTENANCE'**
  String get statusUnderMaintenance;

  /// No description provided for @statusApprovalPending.
  ///
  /// In en, this message translates to:
  /// **'APPROVAL PENDING'**
  String get statusApprovalPending;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get statusInactive;

  /// No description provided for @deviceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Details'**
  String get deviceDetailsTitle;

  /// No description provided for @deviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Device not found'**
  String get deviceNotFound;

  /// No description provided for @recordIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Record ID'**
  String get recordIdLabel;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @imagePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Image Path'**
  String get imagePathLabel;

  /// No description provided for @attachmentPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachment Path'**
  String get attachmentPathLabel;

  /// No description provided for @specificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get specificationLabel;

  /// No description provided for @createdAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAtLabel;

  /// No description provided for @syncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncedLabel;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'(Pending Sync)'**
  String get pendingSync;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @parameterLabel.
  ///
  /// In en, this message translates to:
  /// **'Parameter'**
  String get parameterLabel;

  /// No description provided for @parameterHint.
  ///
  /// In en, this message translates to:
  /// **'Enter checklist parameter'**
  String get parameterHint;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakePhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeImage;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach Image'**
  String get attachImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSelected;

  /// No description provided for @unknownSyncError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred during sync'**
  String get unknownSyncError;

  /// No description provided for @noPendingDevices.
  ///
  /// In en, this message translates to:
  /// **'No pending devices to sync'**
  String get noPendingDevices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
