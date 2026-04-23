import 'dart:convert';

import 'package:asset_management_system/src/features/data/models/asset_checklist_item.dart';
import 'package:asset_management_system/src/features/data/models/volunteer_asset.dart';
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

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

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

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.clear();
  }
}
