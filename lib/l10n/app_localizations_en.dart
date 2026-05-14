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
  String get logoutConfirmationTitle => 'Logout Confirmation';

  @override
  String get logoutConfirmationMessage => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get scan => 'Scan';

  @override
  String get adminLogin => 'Admin Login';

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
  String get qrNfcScannerTitle => 'QR Scanner';

  @override
  String get qrCode => 'QR Code';

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
  String get noInternetConnection =>
      'No internet connection. Please check your network and try again.';

  @override
  String get loading => 'Loading...';

  @override
  String get loginWithEmail => 'Volunteer\nLogin';

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

  @override
  String get qrScanMismatch => 'QR code does not match the asset label';

  @override
  String get allChecked => 'All Checked';

  @override
  String get noFullyCheckedAssetsFound => 'No fully checked assets found';

  @override
  String get noPartiallyCheckedAssetsFound =>
      'No partially checked assets found';

  @override
  String get noPendingChecklistUpdates => 'No pending checklist updates';

  @override
  String get sync => 'Sync';

  @override
  String syncedChecklistUpdates(Object synced, Object totalPending) {
    return 'Synced $synced/$totalPending checklist updates';
  }

  @override
  String syncFailedSuffix(Object failed) {
    return '($failed failed)';
  }

  @override
  String deviceSyncSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return 'Successfully synced $_temp0';
  }

  @override
  String deviceSyncFailed(Object failedIds, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return 'Failed to sync $_temp0: $failedIds';
  }

  @override
  String deviceSyncPartial(Object synced, Object total, Object failedIds) {
    return 'Synced $synced of $total devices. Failed: $failedIds';
  }

  @override
  String astIdAlreadyAssigned(Object astId) {
    return '$astId has already been assigned';
  }

  @override
  String get assetCreateTitle => 'Asset Create';

  @override
  String get assetCreateNotice =>
      '* Required: Asset ID, Name, Address, Type, Camp, Block';

  @override
  String get assetCreateImportantNotice =>
      '• Important: Select Camp FIRST to load available Blocks';

  @override
  String get assetIdLabel => 'Asset ID *';

  @override
  String get assetIdHint => 'Scan QR code or enter ID';

  @override
  String get nameLabel => 'Name *';

  @override
  String get nameHint => 'Enter asset name';

  @override
  String get typeLabel => 'Type';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountHint => 'Enter asset amount';

  @override
  String get statusLabel => 'Status';

  @override
  String get campLabel => 'Camp';

  @override
  String get blockLabel => 'Block';

  @override
  String get addressLineLabel => 'Address Line';

  @override
  String get addressLineHint => 'Enter address line';

  @override
  String get purchaseDateLabel => 'Purchase Date';

  @override
  String get manufactureDateLabel => 'Manufacture Date';

  @override
  String get warrantyEndLabel => 'Warranty End';

  @override
  String get itemsHeading => 'Items';

  @override
  String get itemColumn => 'Item';

  @override
  String get descriptionColumn => 'Description';

  @override
  String get actionColumn => 'Action';

  @override
  String get enterItemHint => 'Enter item';

  @override
  String get enterDescriptionHint => 'Enter description';

  @override
  String get deleteItem => 'Delete';

  @override
  String get addItem => 'Add Item';

  @override
  String get assetPhotoLabel => 'Asset Photo';

  @override
  String get chooseImage => 'Choose Image';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get noImageChosen => 'No image chosen';

  @override
  String get assetAttachmentLabel => 'Upload Attachment';

  @override
  String get chooseAttachment => 'Choose Attachment';

  @override
  String get noAttachmentChosen => 'No attachment chosen';

  @override
  String get remove => 'Remove';

  @override
  String get assetDetailsLabel => 'Asset Details';

  @override
  String get assetDetailsHint => 'Enter asset details';

  @override
  String get createAsset => 'Create';

  @override
  String get saving => 'Saving...';

  @override
  String get goBack => 'Go Back';

  @override
  String get assetSavedLocally => 'Asset saved locally. Sync from Home screen.';

  @override
  String get assetIdRequired => 'Asset ID is required (Scan QR code)';

  @override
  String get nameAndAddressRequired => 'Name and address are required';

  @override
  String get typeCampBlockRequired =>
      'Type, camp, and block are required. Ensure camp is selected first to load available blocks.';

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String errorLoadingTypes(Object error) {
    return 'Error loading types: $error';
  }

  @override
  String get errorLoadingCamps => 'Error loading camps';

  @override
  String errorLoadingBlocks(Object error) {
    return 'Error loading blocks:\n$error';
  }

  @override
  String get noBlocksAvailableForCamp =>
      'No blocks available for this camp - check if camp/location exists and has blocks';

  @override
  String errorCapturingImage(Object error) {
    return 'Error capturing image: $error';
  }

  @override
  String errorPickingImage(Object error) {
    return 'Error picking image: $error';
  }

  @override
  String get registerDevice => 'Register device';

  @override
  String get invalidScanData => 'Invalid scan data';

  @override
  String deviceRegisteredFor(Object assetTitle) {
    return 'Device registered for $assetTitle';
  }

  @override
  String get noChecklistItemsFound => 'No checklist items found';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusUnderMaintenance => 'UNDER MAINTENANCE';

  @override
  String get statusApprovalPending => 'APPROVAL PENDING';

  @override
  String get statusInactive => 'INACTIVE';

  @override
  String get deviceDetailsTitle => 'Device Details';

  @override
  String get deviceNotFound => 'Device not found';

  @override
  String get recordIdLabel => 'Record ID';

  @override
  String get detailsLabel => 'Details';

  @override
  String get locationLabel => 'Location';

  @override
  String get imagePathLabel => 'Image Path';

  @override
  String get attachmentPathLabel => 'Attachment Path';

  @override
  String get specificationLabel => 'Specification';

  @override
  String get createdAtLabel => 'Created At';

  @override
  String get syncedLabel => 'Synced';

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get pendingSync => '(Pending Sync)';

  @override
  String get closeLabel => 'Close';

  @override
  String get parameterLabel => 'Parameter';

  @override
  String get parameterHint => 'Enter checklist parameter';

  @override
  String get retakePhoto => 'Retake';

  @override
  String get camera => 'Camera';

  @override
  String get changeImage => 'Change';

  @override
  String get attachImage => 'Attach Image';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get imageSelected => 'Image selected';

  @override
  String get unknownSyncError => 'Unknown error occurred during sync';

  @override
  String get noPendingDevices => 'No pending devices to sync';
}
