import 'dart:convert';

import 'package:asset_management_system/src/core/network/api_client.dart';
import 'package:asset_management_system/src/core/network/endpoints.dart';

import '../models/asset_checklist_item.dart';
import '../models/volunteer_asset.dart';

class AssetService {
  final ApiClient client;

  AssetService(this.client);

  Future<List<VolunteerAsset>> fetchMyAssets() async {
    final res = await client.get(Endpoints.myAsset, auth: true);
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('Failed to load assets');
    }

    final items = body['data'] as List<dynamic>? ?? const <dynamic>[];

    return items.whereType<Map<String, dynamic>>().map(VolunteerAsset.fromAssignmentJson).toList();
  }

  Future<List<AssetChecklistItem>> fetchChecklistByAssetId(String astId) async {
    final res = await client.get('${Endpoints.assetChecklistByAssetBase}/$astId', auth: true);
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('Failed to load asset checklist');
    }

    final data = body['data'];
    final responses = data is Map<String, dynamic> ? data['items'] as List<dynamic>? ?? const <dynamic>[] : const <dynamic>[];

    return responses.whereType<Map<String, dynamic>>().map(AssetChecklistItem.fromJson).toList();
  }

  Future<void> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required List<({int featureId, bool response})> items,
  }) async {
    final res = await client.post(
      Endpoints.assetChecklistSubmit,
      auth: true,
      body: {
        'ast_ID': astId,
        'status': status,
        'remark': remark,
        'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(growable: false),
      },
    );
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body is! Map<String, dynamic> || body['code'] != 200) {
      throw Exception('Failed to submit checklist');
    }
  }
}
