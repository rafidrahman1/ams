import 'dart:convert';
import 'dart:io';

import 'package:asset_management_system/core/storage/asset_cache_store.dart';
import 'package:asset_management_system/core/storage/local_database.dart';

import '../models/asset_checklist_item.dart';
import '../models/location_models.dart';
import '../models/volunteer_asset.dart';
import '../services/asset_service.dart';

class AssetRepository {
  final AssetService service;
  final Future<String?> Function() getUserKey;
  final LocalDatabase db;
  final AssetCacheStore cache;

  // In-memory cache for assets with timestamp to prevent rapid re-fetches
  List<VolunteerAsset>? _cachedAssets;
  DateTime? _assetsCacheTime;
  static const Duration _assetsCacheDuration = Duration(minutes: 5);

  AssetRepository(this.service, this.getUserKey, this.db) : cache = AssetCacheStore();

  AssetRepository.withCache(this.service, this.getUserKey, this.db, this.cache);

  Future<String?> _resolvedUserKey() async {
    final key = (await getUserKey())?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<List<VolunteerAsset>> fetchMyAssets() async {
    final userKey = await _resolvedUserKey();

    // Check if we have a fresh in-memory cache
    final now = DateTime.now();
    if (_cachedAssets != null && _assetsCacheTime != null && now.difference(_assetsCacheTime!).inSeconds < _assetsCacheDuration.inSeconds) {
      return _cachedAssets!;
    }

    try {
      final assets = await service.fetchMyAssets();
      if (userKey != null) {
        await db.saveAssets(userKey, assets);
      }
      // Update in-memory cache
      _cachedAssets = assets;
      _assetsCacheTime = DateTime.now();
      return assets;
    } catch (_) {
      if (userKey != null) {
        final cachedAssets = await db.loadAssets(userKey);
        if (cachedAssets.isNotEmpty) {
          // Update in-memory cache with local database data
          _cachedAssets = cachedAssets;
          _assetsCacheTime = DateTime.now();
          return cachedAssets;
        }
      }

      rethrow;
    }
  }

  Future<List<VolunteerAsset>> fetchAdminAssets() async {
    final userKey = await _resolvedUserKey();

    if (userKey == null) {
      return const <VolunteerAsset>[];
    }

    return db.loadAssets(userKey);
  }

  Future<AssetChecklist> fetchChecklistByAssetId(String astId) async {
    final userKey = await _resolvedUserKey();

    try {
      final checklist = await service.fetchChecklistByAssetId(astId);
      if (userKey != null) {
        await db.saveChecklist(userKey, astId, checklist.items);
      }

      return userKey != null ? await _applyPendingSubmission(userKey, astId, checklist) : checklist;
    } catch (_) {
      if (userKey != null) {
        final cachedItems = await db.loadChecklist(userKey, astId);
        if (cachedItems.isNotEmpty) {
          final cachedChecklist = AssetChecklist(items: cachedItems);
          return _applyPendingSubmission(userKey, astId, cachedChecklist);
        }
      }

      rethrow;
    }
  }

  Future<AssetChecklist> _applyPendingSubmission(String userKey, String astId, AssetChecklist checklist) async {
    final payloadJson = await db.loadLatestChecklistSubmissionPayload(userKey, astId);
    if (payloadJson == null || payloadJson.trim().isEmpty || checklist.items.isEmpty) {
      return checklist;
    }

    try {
      final payload = jsonDecode(payloadJson);
      if (payload is! Map<String, dynamic>) return checklist;

      final status = (payload['status'] ?? checklist.status).toString();
      final remark = (payload['remark'] ?? checklist.remark).toString();

      final items = payload['items'] as List<dynamic>? ?? const <dynamic>[];

      final latestStates = <int, bool>{};
      for (final it in items.whereType<Map<String, dynamic>>()) {
        final featureId = _asInt(it['feature_id'] ?? it['featureId']);
        if (featureId != 0) {
          latestStates[featureId] = _asBool(it['response']);
        }
      }

      final updatedItems = latestStates.isEmpty
          ? checklist.items
          : checklist.items
                .map(
                  (item) => latestStates.containsKey(item.featureId)
                      ? AssetChecklistItem(featureId: item.featureId, title: item.title, response: latestStates[item.featureId]!)
                      : item,
                )
                .toList(growable: false);

      return AssetChecklist(items: updatedItems, status: status, remark: remark);
    } catch (_) {
      return checklist;
    }
  }

  Future<List<IdNamePair>> fetchCampLocations() async {
    try {
      final campLocations = await service.fetchCampLocations();
      await cache.saveCampLocations(campLocations);
      return campLocations;
    } catch (_) {
      if (await cache.hasCampLocationsCache()) {
        return cache.loadCampLocations();
      }

      rethrow;
    }
  }

  Future<List<IdNamePair>> fetchBlocks(int campId) async {
    try {
      final blocks = await service.fetchBlocks(campId);
      await cache.saveBlocks(campId, blocks);
      return blocks;
    } catch (_) {
      if (await cache.hasBlocksCache(campId)) {
        return cache.loadBlocks(campId);
      }

      rethrow;
    }
  }

  Future<List<IdNamePair>> fetchAssetTypes() async {
    try {
      final assetTypes = await service.fetchAssetTypes();
      await cache.saveAssetTypes(assetTypes);
      return assetTypes;
    } catch (_) {
      if (await cache.hasAssetTypesCache()) {
        return cache.loadAssetTypes();
      }

      rethrow;
    }
  }

  Future<void> prefetchOfflineData(String userKey, {bool isAdmin = false}) async {
    final trimmedUserKey = userKey.trim();
    if (trimmedUserKey.isEmpty) {
      return;
    }

    if (isAdmin) {
      await _prefetchAdminLookupData();
      return;
    }

    try {
      final assets = await service.fetchMyAssets();
      await db.saveAssets(trimmedUserKey, assets);

      for (final asset in assets) {
        final astId = asset.astId.trim();
        if (astId.isEmpty) {
          continue;
        }

        try {
          final checklist = await service.fetchChecklistByAssetId(astId);
          await db.saveChecklist(trimmedUserKey, astId, checklist.items);
        } catch (_) {
          final cachedChecklist = await db.loadChecklist(trimmedUserKey, astId);
          if (cachedChecklist.isNotEmpty) {
            await db.saveChecklist(trimmedUserKey, astId, cachedChecklist);
          }
        }
      }
    } catch (_) {
      // Best effort: login should still succeed even if the prefetch fails.
    }
  }

  Future<void> _prefetchAdminLookupData() async {
    List<IdNamePair> campLocations = const <IdNamePair>[];

    try {
      campLocations = await service.fetchCampLocations();
      await cache.saveCampLocations(campLocations);
    } catch (_) {
      if (await cache.hasCampLocationsCache()) {
        campLocations = await cache.loadCampLocations();
      }
    }

    try {
      final assetTypes = await service.fetchAssetTypes();
      await cache.saveAssetTypes(assetTypes);
    } catch (_) {
      // Keep previously cached asset types if the refresh is unavailable.
    }

    for (final campLocation in campLocations) {
      try {
        final blocks = await service.fetchBlocks(campLocation.id);
        await cache.saveBlocks(campLocation.id, blocks);
      } catch (_) {
        // Best effort: preserve any cached blocks already stored for this camp.
      }
    }
  }

  Future<int> queueChecklistSubmission({
    required String astId,
    required String status,
    required String remark,
    required String parameter,
    required String image,
    String? imagePath,
    required List<({int featureId, bool response})> items,
  }) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) return 0;

    final payloadJson = jsonEncode({
      'ast_ID': astId,
      'status': status,
      'remark': remark,
      'parameter': parameter,
      'image': image,
      'image_path': imagePath ?? '',
      'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(growable: false),
    });
    return db.enqueueChecklistSubmission(userKey, astId, payloadJson);
  }

  Future<void> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required String parameter,
    required String image,
    String? imagePath,
    required List<({int featureId, bool response})> items,
  }) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) {
      throw Exception('Missing session');
    }

    final payload = {
      'ast_ID': astId,
      'status': status,
      'remark': remark,
      'parameter': parameter,
      'image': image,
      'image_path': imagePath ?? '',
      'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(),
    };

    final imagePayload = await _resolveChecklistImageForUpload(image: image, imagePath: imagePath);

    try {
      final responseBody = await service.submitChecklist(astId: astId, status: status, remark: remark, parameter: parameter, image: imagePayload, items: items);

      if (!_isSyncVerified(submission: payload, response: responseBody)) {
        throw Exception('Sync verification failed');
      }

      // Keep the local cache aligned with what the user just submitted.
      final updatedChecklist = items.map((i) => AssetChecklistItem(featureId: i.featureId, title: '', response: i.response)).toList(growable: false);
      // We don't have titles here; preserve cached titles by merging with last cached checklist if possible.
      final cached = await db.loadChecklist(userKey, astId);
      if (cached.isNotEmpty) {
        final titleMap = {for (final c in cached) c.featureId: c.title};
        await db.saveChecklist(
          userKey,
          astId,
          updatedChecklist.map((i) => AssetChecklistItem(featureId: i.featureId, title: titleMap[i.featureId] ?? '', response: i.response)).toList(growable: false),
        );
      } else {
        await db.saveChecklist(userKey, astId, updatedChecklist);
      }
    } catch (_) {
      // Offline / failure: queue for later sync instead of failing the UI.
      await queueChecklistSubmission(astId: astId, status: status, remark: remark, parameter: parameter, image: image, imagePath: imagePath, items: items);
    }
  }

  Future<ToggleSyncResult> syncQueuedResponses() async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    final pending = await db.loadPendingChecklistSubmissions(userKey);
    if (pending.isEmpty) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    var syncedCount = 0;
    var failedCount = 0;
    final removableQueueIds = <int>[];

    // For each asset, only submit the latest queued payload.
    final latestByAsset = <String, ChecklistSubmissionQueueItem>{};
    for (final item in pending) {
      latestByAsset[item.astId] = item;
    }

    for (final entry in latestByAsset.entries) {
      final queueItem = entry.value;
      try {
        final payload = jsonDecode(queueItem.payloadJson);
        if (payload is! Map<String, dynamic>) {
          failedCount += 1;
          await db.recordChecklistSubmissionSyncFailure(queueItem.queueId, 'Invalid checklist payload');
          continue;
        }

        final astId = (payload['ast_ID'] ?? queueItem.astId).toString();
        final status = (payload['status'] ?? '').toString();
        final remark = (payload['remark'] ?? '').toString();
        final parameter = (payload['parameter'] ?? '').toString();
        final image = (payload['image'] ?? '').toString();
        final imagePath = (payload['image_path'] ?? '').toString();
        final itemsRaw = payload['items'] as List<dynamic>? ?? const <dynamic>[];
        final items = <({int featureId, bool response})>[];
        for (final it in itemsRaw.whereType<Map<String, dynamic>>()) {
          final featureId = _asInt(it['feature_id'] ?? it['featureId']);
          if (featureId == 0) continue;
          items.add((featureId: featureId, response: _asBool(it['response'])));
        }

        final imagePayload = await _resolveChecklistImageForUpload(image: image, imagePath: imagePath);
        final responseBody = await service.submitChecklist(astId: astId, status: status, remark: remark, parameter: parameter, image: imagePayload, items: items);
        if (_isSyncVerified(submission: payload, response: responseBody)) {
          syncedCount += 1;
          removableQueueIds.add(queueItem.queueId);
        } else {
          failedCount += 1;
          await db.recordChecklistSubmissionSyncFailure(queueItem.queueId, 'Sync verification failed');
        }
      } catch (e) {
        failedCount += 1;
        await db.recordChecklistSubmissionSyncFailure(queueItem.queueId, e.toString());
      }
    }

    if (removableQueueIds.isNotEmpty) {
      await db.markQueuedChecklistSubmissionsSynced(removableQueueIds);
    }

    return ToggleSyncResult(totalPending: pending.length, synced: syncedCount, failed: failedCount);
  }

  bool _isSyncVerified({required Map<String, dynamic> submission, required Map<String, dynamic> response}) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) return false;

    // Check status
    final submittedStatus = submission['status']?.toString();
    final receivedStatus = data['asset_status']?.toString();
    if (submittedStatus != receivedStatus) return false;

    // Check remark - API uses 'remakk' based on user sample
    final submittedRemark = submission['remark']?.toString();
    final receivedRemark = (data['remakk'] ?? data['remark'])?.toString();
    if (submittedRemark != receivedRemark) return false;

    // Check items
    final submittedItems = submission['items'] as List<dynamic>? ?? [];
    final receivedFeatures = data['features'] as List<dynamic>? ?? [];

    if (submittedItems.length != receivedFeatures.length) return false;

    final submittedMap = {for (final item in submittedItems.whereType<Map<String, dynamic>>()) _asInt(item['feature_id']): _asBool(item['response'])};

    for (final feature in receivedFeatures.whereType<Map<String, dynamic>>()) {
      final fid = _asInt(feature['feature_id']);
      final res = _asBool(feature['response']);
      if (submittedMap[fid] != res) return false;
    }

    return true;
  }

  Future<void> clearCache(String userKey) async {
    await db.clearUserData(userKey);
  }

  Future<Map<String, dynamic>> createAsset({
    required String name,
    required String details,
    required String addressLine,
    required String astId,
    String? status,
    String? assetType,
    String? location,
    String? block,
    List<Map<String, dynamic>>? specifications,
    String? warrantyEnd,
    String? amount,
    String? purchaseDate,
    String? manufactureDate,
    String? imagePath,
    String? attachmentPath,
  }) async {
    return service.createAsset(
      name: name,
      details: details,
      addressLine: addressLine,
      astId: astId,
      status: status,
      assetType: assetType,
      location: location,
      block: block,
      specifications: specifications,
      warrantyEnd: warrantyEnd,
      amount: amount,
      purchaseDate: purchaseDate,
      manufactureDate: manufactureDate,
      imagePath: imagePath,
      attachmentPath: attachmentPath,
    );
  }

  Future<int> saveRegisteredDeviceLocally({
    required String name,
    required String details,
    required String addressLine,
    required String astId,
    String? status,
    String? assetType,
    String? location,
    String? block,
    String? imagePath,
    String? warrantyEnd,
    String? specification,
    String? amount,
    String? purchaseDate,
    String? manufactureDate,
    String? assetAttachment,
  }) async {
    final deviceData = RegisteredDeviceData(
      name: name,
      details: details,
      addressLine: addressLine,
      astId: astId,
      status: status,
      assetType: assetType,
      location: location,
      block: block,
      imagePath: imagePath,
      warrantyEnd: warrantyEnd,
      specification: specification,
      amount: amount,
      purchaseDate: purchaseDate,
      manufactureDate: manufactureDate,
      assetAttachment: assetAttachment,
      createdAt: DateTime.now(),
      synced: false,
    );
    return db.insertRegisteredDevice(deviceData);
  }

  Future<void> syncRegisteredDevice(int deviceId) async {
    final device = await db.getRegisteredDeviceById(deviceId);
    if (device == null) {
      throw Exception('Device not found');
    }

    final assetType = device.assetType?.trim();
    final location = device.location?.trim();
    final block = device.block?.trim();

    if (assetType == null || assetType.isEmpty || location == null || location.isEmpty || block == null || block.isEmpty) {
      throw Exception(
        'Sync failed: missing required fields locally. '
        'asset_type=${assetType ?? 'null'} location=${location ?? 'null'} block=${block ?? 'null'}',
      );
    }

    final normalizedAstId = _normalizeAstId(device.astId);
    if (normalizedAstId == null) {
      throw Exception('Asset ID is missing for this device');
    }

    final normalizedName = device.name.trim().isEmpty ? 'Asset $normalizedAstId' : device.name.trim();
    final normalizedAddressLine = device.addressLine.trim().isEmpty ? (device.details.trim().isEmpty ? 'N/A' : device.details.trim()) : device.addressLine.trim();

    final normalizedDetails = device.details.trim().isEmpty ? normalizedName : device.details.trim();

    final specifications = _normalizeSpecifications(device.specification);

    // The local file picker path might become unavailable by the time the user taps Sync
    // (e.g. temp files cleared, permission changes). Only attempt uploads + verification
    // when the files actually exist right now.
    String? imagePathForUpload = device.imagePath;
    if (imagePathForUpload?.trim().isNotEmpty ?? false) {
      try {
        if (!await File(imagePathForUpload!).exists()) {
          imagePathForUpload = null;
        }
      } catch (_) {
        imagePathForUpload = null;
      }
    }

    String? attachmentPathForUpload = device.assetAttachment;
    if (attachmentPathForUpload?.trim().isNotEmpty ?? false) {
      try {
        if (!await File(attachmentPathForUpload!).exists()) {
          attachmentPathForUpload = null;
        }
      } catch (_) {
        attachmentPathForUpload = null;
      }
    }

    Map<String, dynamic> responseBody;
    try {
      responseBody = await service.createAsset(
        name: normalizedName,
        details: normalizedDetails,
        addressLine: normalizedAddressLine,
        astId: normalizedAstId,
        status: device.status,
        assetType: device.assetType,
        location: device.location,
        block: device.block,
        imagePath: imagePathForUpload,
        specifications: specifications,
        warrantyEnd: _normalizeApiDate(device.warrantyEnd),
        amount: device.amount,
        purchaseDate: _normalizeApiDate(device.purchaseDate),
        manufactureDate: _normalizeApiDate(device.manufactureDate),
        attachmentPath: attachmentPathForUpload,
      );
    } catch (e) {
      final msg = e.toString();

      // Some backends respond "Data not found" when `block` doesn't belong to the selected `location`.
      // Retry once by omitting `block` (sending it as null) to unblock valid creations.
      final shouldRetryWithoutBlock = device.block != null && device.block!.trim().isNotEmpty && msg.toLowerCase().contains('data not found');

      if (!shouldRetryWithoutBlock) {
        throw Exception('Sync failed during upload (createAsset): ${e.toString()}');
      }

      try {
        responseBody = await service.createAsset(
          name: normalizedName,
          details: normalizedDetails,
          addressLine: normalizedAddressLine,
          astId: normalizedAstId,
          status: device.status,
          assetType: device.assetType,
          location: device.location,
          block: null,
          imagePath: imagePathForUpload,
          specifications: specifications,
          warrantyEnd: _normalizeApiDate(device.warrantyEnd),
          amount: device.amount,
          purchaseDate: _normalizeApiDate(device.purchaseDate),
          manufactureDate: _normalizeApiDate(device.manufactureDate),
          attachmentPath: attachmentPathForUpload,
        );
      } catch (e2) {
        throw Exception('Sync failed during upload (createAsset) after retry-without-block: ${e2.toString()}');
      }
    }

    final isVerified = _isAssetCreationVerified(
      device: device,
      response: responseBody,
      submittedName: normalizedName,
      submittedDetails: normalizedDetails,
      submittedAddressLine: normalizedAddressLine,
      submittedAstId: normalizedAstId,
      submittedSpecifications: specifications,
      uploadedImagePath: imagePathForUpload,
      uploadedAttachmentPath: attachmentPathForUpload,
    );
    if (!isVerified) {
      final data = responseBody['data'];
      throw Exception('Sync failed during verification (response mismatch). data=${data.toString()}');
    }

    await db.markRegisteredDeviceSynced(deviceId);
  }

  bool _isAssetCreationVerified({
    required RegisteredDeviceData device,
    required Map<String, dynamic> response,
    required String submittedName,
    required String submittedDetails,
    required String submittedAddressLine,
    required String submittedAstId,
    required List<Map<String, dynamic>>? submittedSpecifications,
    required String? uploadedImagePath,
    required String? uploadedAttachmentPath,
  }) {
    if (response['code'] != 200) return false;

    final data = response['data'];
    if (data is! Map<String, dynamic>) return false;

    if (_normalized(_readValue(data, const ['ast_ID', 'ast_id', 'astId'])) != _normalized(submittedAstId)) return false;
    if (_normalized(_readValue(data, const ['name'])) != _normalized(submittedName)) return false;
    if (_normalized(_readValue(data, const ['details'])) != _normalized(submittedDetails)) return false;

    // Some backends return null for address/block even when we send them.
    final responseAddressLine = _readValue(data, const ['address_line', 'addressLine']);
    if (submittedAddressLine.trim().isNotEmpty && responseAddressLine != null) {
      if (_normalized(responseAddressLine) != _normalized(submittedAddressLine)) return false;
    }

    // Status is often overridden by the backend workflow (e.g. request ACTIVE but backend sets APPROVAL PENDING),
    // so we don't strict-verify it here.

    final responseAssetType = _readValue(data, const ['asset_type', 'assetType']);
    if (device.assetType?.trim().isNotEmpty ?? false) {
      if (responseAssetType != null && _normalized(responseAssetType) != _normalized(device.assetType)) return false;
    }

    final responseLocation = _readValue(data, const ['location']);
    if (device.location?.trim().isNotEmpty ?? false) {
      if (responseLocation != null && _normalized(responseLocation) != _normalized(device.location)) return false;
    }
    final responseBlock = _readValue(data, const ['block']);
    if ((device.block?.trim().isNotEmpty ?? false) && responseBlock != null) {
      if (_normalized(responseBlock) != _normalized(device.block)) return false;
    }
    if (device.amount?.trim().isNotEmpty ?? false) {
      if (_normalized(_readValue(data, const ['amount'])) != _normalized(device.amount)) return false;
    }

    final normalizedWarranty = _normalizeApiDate(device.warrantyEnd);
    if (normalizedWarranty != null && normalizedWarranty.isNotEmpty) {
      if (_normalizedDate(_readValue(data, const ['warranty_end', 'warrantyEnd'])) != normalizedWarranty) return false;
    }
    final normalizedPurchaseDate = _normalizeApiDate(device.purchaseDate);
    if (normalizedPurchaseDate != null && normalizedPurchaseDate.isNotEmpty) {
      if (_normalizedDate(_readValue(data, const ['purchase_date', 'purchaseDate'])) != normalizedPurchaseDate) return false;
    }
    final normalizedManufactureDate = _normalizeApiDate(device.manufactureDate);
    if (normalizedManufactureDate != null && normalizedManufactureDate.isNotEmpty) {
      if (_normalizedDate(_readValue(data, const ['manufacture_date', 'manufactureDate'])) != normalizedManufactureDate) return false;
    }

    // `specification` can be returned either as structured JSON (list/object) or as a plain string.
    // Only verify when the response looks structured; otherwise, treat it as informational.
    if (submittedSpecifications != null && submittedSpecifications.isNotEmpty) {
      final specValue = _readValue(data, const ['specification', 'specifications']);
      final looksStructured = specValue is List || (specValue is String && (specValue.trim().startsWith('[') || specValue.trim().startsWith('{')));
      if (looksStructured) {
        final submittedSpecs = _normalizeSpecificationEntriesForCompare(submittedSpecifications);
        final responseSpecs = _normalizeSpecificationEntriesForCompare(_parseSpecificationsFromResponse(specValue));
        if (submittedSpecs != responseSpecs) return false;
      }
    }

    // Server returns URLs for files; ensure those fields are present when a file was submitted.
    if ((uploadedImagePath?.trim().isNotEmpty ?? false) && _normalized(_readValue(data, const ['image', 'image_url'])).isEmpty) return false;
    if ((uploadedAttachmentPath?.trim().isNotEmpty ?? false)) {
      final attachmentsValue = _readValue(data, const ['asset_attach', 'asset_attachment', 'asset_attachments']);
      if (!_hasAttachmentData(attachmentsValue)) return false;
    }

    return true;
  }

  Object? _readValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key)) return source[key];
    }
    return null;
  }

  Future<String> _resolveChecklistImageForUpload({required String image, String? imagePath}) async {
    final inlineImage = image.trim();
    if (inlineImage.isNotEmpty) {
      return inlineImage;
    }

    final path = imagePath?.trim() ?? '';
    if (path.isEmpty) {
      return '';
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        return '';
      }
      final bytes = await file.readAsBytes();
      return 'data:${_mimeTypeFromPath(path)};base64,${base64Encode(bytes)}';
    } catch (_) {
      return '';
    }
  }

  String _mimeTypeFromPath(String path) {
    final loweredPath = path.toLowerCase();
    if (loweredPath.endsWith('.png')) return 'image/png';
    if (loweredPath.endsWith('.jpg') || loweredPath.endsWith('.jpeg')) return 'image/jpeg';
    if (loweredPath.endsWith('.webp')) return 'image/webp';
    if (loweredPath.endsWith('.gif')) return 'image/gif';
    return 'image/png';
  }

  bool _hasAttachmentData(Object? attachmentsValue) {
    if (attachmentsValue == null) return false;
    if (attachmentsValue is List) return attachmentsValue.isNotEmpty;
    if (attachmentsValue is String) return attachmentsValue.trim().isNotEmpty;
    if (attachmentsValue is Map) return attachmentsValue.isNotEmpty;
    return attachmentsValue.toString().trim().isNotEmpty;
  }

  List<Map<String, dynamic>> _parseSpecificationsFromResponse(Object? responseValue) {
    if (responseValue is List) {
      return responseValue.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (responseValue is String) {
      final trimmed = responseValue.trim();
      if (trimmed.isEmpty) return const <Map<String, dynamic>>[];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
        }
      } catch (_) {
        return const <Map<String, dynamic>>[];
      }
    }
    return const <Map<String, dynamic>>[];
  }

  String _normalizeSpecificationEntriesForCompare(List<Map<String, dynamic>> entries) {
    final pairs = entries.map((e) => '${_normalized(e['name'])}|${_normalized(e['description'])}').where((e) => e.isNotEmpty && e != '|').toList(growable: false);
    pairs.sort();
    return pairs.join('||');
  }

  List<Map<String, dynamic>>? _normalizeSpecifications(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        final normalized = <Map<String, dynamic>>[];
        var fallbackId = 1;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final name = (item['name'] ?? '').toString().trim();
            if (name.isEmpty) continue;
            normalized.add({'id': _asInt(item['id']) == 0 ? fallbackId : _asInt(item['id']), 'name': name, 'description': (item['description'] ?? '').toString()});
            fallbackId += 1;
          } else {
            final name = item.toString().trim();
            if (name.isEmpty) continue;
            normalized.add({'id': fallbackId, 'name': name, 'description': ''});
            fallbackId += 1;
          }
        }
        return normalized.isEmpty ? null : normalized;
      }
    } catch (_) {
      // Fall back to plain-text format.
    }

    return <Map<String, dynamic>>[
      {'id': 1, 'name': trimmed, 'description': ''},
    ];
  }

  String? _normalizeAstId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final fromAstId = decoded['ast_ID'] ?? decoded['ast_id'] ?? decoded['astId'];
        final astId = fromAstId?.toString().trim();
        if (astId != null && astId.isNotEmpty) {
          return astId;
        }
      }
    } catch (_) {
      // Keep plain IDs as-is.
    }

    return trimmed;
  }

  String? _normalizeApiDate(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      final month = parsed.month.toString().padLeft(2, '0');
      final day = parsed.day.toString().padLeft(2, '0');
      return '${parsed.year}-$month-$day';
    }

    final isDateOnly =
        trimmed.length == 10 &&
        trimmed[4] == '-' &&
        trimmed[7] == '-' &&
        int.tryParse(trimmed.substring(0, 4)) != null &&
        int.tryParse(trimmed.substring(5, 7)) != null &&
        int.tryParse(trimmed.substring(8, 10)) != null;
    return isDateOnly ? trimmed : null;
  }

  String _normalized(Object? value) => (value?.toString() ?? '').trim();

  String _normalizedDate(Object? value) => _normalizeApiDate(value?.toString()) ?? '';

  Future<List<RegisteredDeviceData>> getUnsyncedRegisteredDevices() async {
    return db.getUnyncedRegisteredDevices();
  }

  Future<RegisteredDeviceData?> getRegisteredDeviceById(int id) async {
    return db.getRegisteredDeviceById(id);
  }

  Future<void> deleteRegisteredDevice(int id) async {
    await db.deleteRegisteredDevice(id);
  }

  Future<void> deleteAsset(String astId) async {
    final userKey = await _resolvedUserKey();
    if (userKey != null) {
      await db.deleteAsset(userKey, astId);
    }
  }
}

class ToggleSyncResult {
  final int totalPending;
  final int synced;
  final int failed;

  const ToggleSyncResult({required this.totalPending, required this.synced, required this.failed});
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
