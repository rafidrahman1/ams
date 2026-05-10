import 'dart:convert';

import 'package:asset_management_system/model/asset_checklist_item.dart';
import 'package:asset_management_system/model/location_models.dart';
import 'package:asset_management_system/model/volunteer_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssetCacheStore {
  AssetCacheStore();

  String _sanitizeKey(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'default';

    return normalized.replaceAll(RegExp(r'[^a-z0-9._-]+'), '_');
  }

  String _assetsKey(String userKey) => 'asset_cache_${_sanitizeKey(userKey)}_assets';

  String _checklistKey(String userKey, String astId) => 'asset_cache_${_sanitizeKey(userKey)}_checklist_${_sanitizeKey(astId)}';

  String _campLocationsKey() => 'asset_cache_camp_locations';

  String _assetTypesKey() => 'asset_cache_asset_types';

  String _blocksKey(int campId) => 'asset_cache_blocks_$campId';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<bool> _hasKey(String key) async {
    final prefs = await _prefs();
    return prefs.containsKey(key);
  }

  Future<void> _savePairs(String key, List<IdNamePair> items) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(items.map((item) => {'id': item.id, 'name': item.name}).toList(growable: false)));
  }

  Future<List<IdNamePair>> _loadPairs(String key) async {
    final prefs = await _prefs();
    final rawValue = prefs.getString(key);
    if (rawValue == null || rawValue.isEmpty) {
      return const <IdNamePair>[];
    }

    final decoded = jsonDecode(rawValue);
    final rawItems = decoded is List<dynamic> ? decoded : const <dynamic>[];

    return rawItems.whereType<Map<String, dynamic>>().map((item) => IdNamePair(id: item['id'] as int? ?? 0, name: (item['name'] ?? '').toString())).toList(growable: false);
  }

  Future<void> saveAssets(String userKey, List<VolunteerAsset> assets) async {
    final prefs = await _prefs();
    await prefs.setString(_assetsKey(userKey), jsonEncode(assets.map((asset) => asset.toJson()).toList()));
  }

  Future<List<VolunteerAsset>> loadAssets(String userKey) async {
    final prefs = await _prefs();
    final rawValue = prefs.getString(_assetsKey(userKey));
    if (rawValue == null || rawValue.isEmpty) {
      return const <VolunteerAsset>[];
    }

    final decoded = jsonDecode(rawValue);
    final rawAssets = decoded is List<dynamic> ? decoded : const <dynamic>[];

    return rawAssets.whereType<Map<String, dynamic>>().map(VolunteerAsset.fromCacheJson).toList(growable: false);
  }

  Future<void> saveChecklist(String userKey, String astId, List<AssetChecklistItem> items) async {
    final prefs = await _prefs();
    await prefs.setString(_checklistKey(userKey, astId), jsonEncode(items.map((item) => item.toJson()).toList()));
  }

  Future<List<AssetChecklistItem>> loadChecklist(String userKey, String astId) async {
    final prefs = await _prefs();
    final rawValue = prefs.getString(_checklistKey(userKey, astId));
    if (rawValue == null || rawValue.isEmpty) {
      return const <AssetChecklistItem>[];
    }

    final decoded = jsonDecode(rawValue);
    final rawItems = decoded is List<dynamic> ? decoded : const <dynamic>[];

    return rawItems.whereType<Map<String, dynamic>>().map(AssetChecklistItem.fromCacheJson).toList(growable: false);
  }

  Future<void> saveCampLocations(List<IdNamePair> items) => _savePairs(_campLocationsKey(), items);

  Future<List<IdNamePair>> loadCampLocations() => _loadPairs(_campLocationsKey());

  Future<bool> hasCampLocationsCache() => _hasKey(_campLocationsKey());

  Future<void> saveAssetTypes(List<IdNamePair> items) => _savePairs(_assetTypesKey(), items);

  Future<List<IdNamePair>> loadAssetTypes() => _loadPairs(_assetTypesKey());

  Future<bool> hasAssetTypesCache() => _hasKey(_assetTypesKey());

  Future<void> saveBlocks(int campId, List<IdNamePair> items) => _savePairs(_blocksKey(campId), items);

  Future<List<IdNamePair>> loadBlocks(int campId) => _loadPairs(_blocksKey(campId));

  Future<bool> hasBlocksCache(int campId) => _hasKey(_blocksKey(campId));

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.clear();
  }
}
