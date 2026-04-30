import 'dart:convert';
import 'dart:io';

import 'package:asset_management_system/src/core/network/api_client.dart';
import 'package:asset_management_system/src/core/network/endpoints.dart';

import '../models/asset_checklist_item.dart';
import '../models/location_models.dart';
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

  Future<AssetChecklist> fetchChecklistByAssetId(String astId) async {
    final res = await client.get('${Endpoints.assetChecklistByAssetBase}/$astId', auth: true);
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('Failed to load asset checklist');
    }

    final data = body['data'];
    final responses = data is Map<String, dynamic> ? data['items'] as List<dynamic>? ?? const <dynamic>[] : const <dynamic>[];

    final items = responses.whereType<Map<String, dynamic>>().map(AssetChecklistItem.fromJson).toList();

    String status = 'ACTIVE';
    String remark = '';
    String parameter = '';
    String image = '';
    if (data is Map<String, dynamic>) {
      status = (data['status'] ?? 'ACTIVE').toString();
      remark = (data['remark'] ?? '').toString();
      parameter = (data['parameter'] ?? '').toString();
      image = (data['image'] ?? '').toString();
    }

    return AssetChecklist(items: items, status: status, remark: remark, parameter: parameter, image: image);
  }

  Future<List<IdNamePair>> fetchCampLocations() async {
    final res = await client.get(Endpoints.campLocations, auth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('Failed to load camp locations');
    }
    final items = body['data'] as List<dynamic>? ?? const <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map(IdNamePair.fromJson).toList();
  }

  Future<List<IdNamePair>> fetchBlocks(int campId) async {
    final res = await client.get(Endpoints.blocksByCamp(campId), auth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('Failed to load blocks');
    }
    final items = body['data'] as List<dynamic>? ?? const <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map(IdNamePair.fromJson).toList();
  }

  Future<List<IdNamePair>> fetchAssetTypes() async {
    final res = await client.get(Endpoints.assetTypes, auth: true);
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception('Failed to load asset types');
    }
    final items = body['data'] as List<dynamic>? ?? const <dynamic>[];
    return items.whereType<Map<String, dynamic>>().map(IdNamePair.fromJson).toList();
  }

  Future<Map<String, dynamic>> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required String parameter,
    required String image,
    required List<({int featureId, bool response})> items,
  }) async {
    final res = await client.post(
      Endpoints.assetChecklistSubmit,
      auth: true,
      body: {
        'ast_ID': astId,
        'status': status,
        'remark': remark,
        'parameter': parameter,
        'image': image,
        'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(growable: false),
      },
    );
    final body = jsonDecode(res.body);

    if (res.statusCode != 200 || body is! Map<String, dynamic> || body['code'] != 200) {
      throw Exception('Failed to submit checklist');
    }

    return body;
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
    final normalizedAstId = astId.trim();

    final fields = <String, String>{
      'name': name,
      'details': details,
      'address_line': addressLine,
      'ast_ID': normalizedAstId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (assetType != null && assetType.isNotEmpty) 'asset_type': assetType,
      if (location != null && location.isNotEmpty) 'location': location,
      if (block != null && block.isNotEmpty) 'block': block,
      if (warrantyEnd != null && warrantyEnd.isNotEmpty) 'warranty_end': warrantyEnd,
      if (amount != null && amount.isNotEmpty) 'amount': amount,
      if (purchaseDate != null && purchaseDate.isNotEmpty) 'purchase_date': purchaseDate,
      if (manufactureDate != null && manufactureDate.isNotEmpty) 'manufacture_date': manufactureDate,
    };

    if (specifications != null && specifications.isNotEmpty) {
      fields['specification'] = jsonEncode(specifications);
    }

    final Map<String, String> filePaths = {};
    if (imagePath != null) filePaths['image'] = imagePath;
    if (attachmentPath != null && attachmentPath.isNotEmpty) filePaths['asset_attachment'] = attachmentPath;

    final res = await client.postFormDataWithFile(Endpoints.assetCreate, fields: fields, filePaths: filePaths.isNotEmpty ? filePaths : null, auth: true);

    final body = jsonDecode(res.body);

    if ((res.statusCode != 200 && res.statusCode != 201) || body is! Map<String, dynamic> || body['code'] != 200) {
      throw Exception(body is Map<String, dynamic> ? (body['response']?.toString() ?? 'Failed to create asset') : 'Failed to create asset');
    }

    return body;
  }
}
