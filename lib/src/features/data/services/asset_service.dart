import 'dart:convert';

import 'package:asset_management_system/src/core/network/api_client.dart';
import 'package:asset_management_system/src/core/network/endpoints.dart';

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

    return items
        .whereType<Map<String, dynamic>>()
        .map(VolunteerAsset.fromAssignmentJson)
        .toList();
  }
}
