import 'dart:convert';

import 'package:asset_management_system/src/core/storage/local_database.dart';

import '../models/asset_checklist_item.dart';
import '../models/location_models.dart';
import '../models/volunteer_asset.dart';
import '../services/asset_service.dart';

class AssetRepository {
  final AssetService service;
  final Future<String?> Function() getUserKey;
  final LocalDatabase db;

  AssetRepository(this.service, this.getUserKey, this.db);

  Future<String?> _resolvedUserKey() async {
    final key = (await getUserKey())?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<List<VolunteerAsset>> fetchMyAssets() async {
    final userKey = await _resolvedUserKey();

    try {
      final assets = await service.fetchMyAssets();
      if (userKey != null) {
        await db.saveAssets(userKey, assets);
      }
      return assets;
    } catch (_) {
      if (userKey != null) {
        final cachedAssets = await db.loadAssets(userKey);
        if (cachedAssets.isNotEmpty) {
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
    return service.fetchCampLocations();
  }

  Future<List<IdNamePair>> fetchBlocks() async {
    return service.fetchBlocks();
  }

  Future<List<IdNamePair>> fetchAssetTypes() async {
    return service.fetchAssetTypes();
  }

  Future<void> prefetchOfflineData(String userKey, {bool isAdmin = false}) async {
    final trimmedUserKey = userKey.trim();
    if (trimmedUserKey.isEmpty) {
      return;
    }

    if (isAdmin) {
      // Admin assets are sourced locally only; there is no remote list API.
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

  Future<int> queueChecklistSubmission({required String astId, required String status, required String remark, required List<({int featureId, bool response})> items}) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) return 0;

    final payloadJson = jsonEncode({
      'ast_ID': astId,
      'status': status,
      'remark': remark,
      'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(growable: false),
    });
    return db.enqueueChecklistSubmission(userKey, astId, payloadJson);
  }

  Future<void> submitChecklist({required String astId, required String status, required String remark, required List<({int featureId, bool response})> items}) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) {
      throw Exception('Missing session');
    }

    final payload = {
      'ast_ID': astId,
      'status': status,
      'remark': remark,
      'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(),
    };

    try {
      final responseBody = await service.submitChecklist(astId: astId, status: status, remark: remark, items: items);

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
      await queueChecklistSubmission(astId: astId, status: status, remark: remark, items: items);
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
          continue;
        }

        final astId = (payload['ast_ID'] ?? queueItem.astId).toString();
        final status = (payload['status'] ?? '').toString();
        final remark = (payload['remark'] ?? '').toString();
        final itemsRaw = payload['items'] as List<dynamic>? ?? const <dynamic>[];
        final items = <({int featureId, bool response})>[];
        for (final it in itemsRaw.whereType<Map<String, dynamic>>()) {
          final featureId = _asInt(it['feature_id'] ?? it['featureId']);
          if (featureId == 0) continue;
          items.add((featureId: featureId, response: _asBool(it['response'])));
        }

        final responseBody = await service.submitChecklist(astId: astId, status: status, remark: remark, items: items);
        if (_isSyncVerified(submission: payload, response: responseBody)) {
          syncedCount += 1;
          removableQueueIds.add(queueItem.queueId);
        } else {
          failedCount += 1;
        }
      } catch (_) {
        failedCount += 1;
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

    final normalizedAstId = _normalizeAstId(device.astId);
    if (normalizedAstId == null) {
      throw Exception('Asset ID is missing for this device');
    }

    final normalizedName = device.name.trim().isEmpty ? 'Asset $normalizedAstId' : device.name.trim();
    final normalizedAddressLine = device.addressLine.trim().isEmpty
        ? (device.details.trim().isEmpty ? 'N/A' : device.details.trim())
        : device.addressLine.trim();

    final normalizedDetails = device.details.trim().isEmpty ? normalizedName : device.details.trim();

    final specifications = _normalizeSpecifications(device.specification);

    final responseBody = await service.createAsset(
      name: normalizedName,
      details: normalizedDetails,
      addressLine: normalizedAddressLine,
      astId: normalizedAstId,
      status: device.status,
      assetType: device.assetType,
      location: device.location,
      block: device.block,
      imagePath: device.imagePath,
      specifications: specifications,
      warrantyEnd: _normalizeApiDate(device.warrantyEnd),
      amount: device.amount,
      purchaseDate: _normalizeApiDate(device.purchaseDate),
      manufactureDate: _normalizeApiDate(device.manufactureDate),
      attachmentPath: device.assetAttachment,
    );

    if (!_isAssetCreationVerified(device: device, response: responseBody)) {
      throw Exception('Asset sync verification failed: Response data mismatch');
    }

    await db.markRegisteredDeviceSynced(deviceId);
  }

  bool _isAssetCreationVerified({required RegisteredDeviceData device, required Map<String, dynamic> response}) {
    if (response['code'] != 200) return false;

    final data = response['data'];
    if (data is! Map<String, dynamic>) return false;

    final expectedAstId = _normalizeAstId(device.astId);
    if (expectedAstId == null || expectedAstId.isEmpty) return false;

    if (_normalized(data['ast_ID']) != _normalized(expectedAstId)) return false;
    if (_normalized(data['name']) != _normalized(device.name)) return false;
    if (_normalized(data['status']) != _normalized(device.status)) return false;
    if (_normalized(data['address_line']) != _normalized(device.addressLine)) return false;
    if (_normalized(data['details']) != _normalized(device.details)) return false;
    if (_normalized(data['asset_type']) != _normalized(device.assetType)) return false;
    if (_normalized(data['location']) != _normalized(device.location)) return false;
    if (_normalized(data['block']) != _normalized(device.block)) return false;
    if (_normalized(data['amount']) != _normalized(device.amount)) return false;
    if (_normalizedDate(data['warranty_end']) != _normalizedDate(device.warrantyEnd)) return false;
    if (_normalizedDate(data['purchase_date']) != _normalizedDate(device.purchaseDate)) return false;
    if (_normalizedDate(data['manufacture_date']) != _normalizedDate(device.manufactureDate)) return false;

    final submittedSpecs = _normalizeSpecificationForCompare(device.specification);
    final responseSpecs = _normalizeSpecificationForCompare(data['specification']?.toString());
    if (submittedSpecs != responseSpecs) return false;

    // Server returns URLs for files; ensure those fields are present when a file was submitted.
    if ((device.imagePath?.trim().isNotEmpty ?? false) && _normalized(data['image']).isEmpty) return false;
    if ((device.assetAttachment?.trim().isNotEmpty ?? false)) {
      final attachments = data['asset_attach'];
      if (attachments is! List || attachments.isEmpty) return false;
    }

    return true;
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
            normalized.add({
              'id': _asInt(item['id']) == 0 ? fallbackId : _asInt(item['id']),
              'name': name,
              'description': (item['description'] ?? '').toString(),
            });
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
      {'id': 1, 'name': trimmed, 'description': ''}
    ];
  }

  String _normalizeSpecificationForCompare(String? raw) {
    final list = _normalizeSpecifications(raw) ?? const <Map<String, dynamic>>[];
    if (list.isEmpty) return '';

    final pairs = list
        .map((e) => '${_normalized(e['name'])}|${_normalized(e['description'])}')
        .where((e) => e.isNotEmpty && e != '|')
        .toList(growable: false);
    pairs.sort();
    return pairs.join('||');
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
