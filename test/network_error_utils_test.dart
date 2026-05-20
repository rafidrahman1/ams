import 'package:asset_management_system/core/utils/network_error_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syncFailureMessage unwraps nested sync and API errors', () {
    const apiMessage = "ast_ID = 'AST-000101' has already been assigned to an asset.";
    final error = Exception('Sync failed during upload (createAsset): Exception: $apiMessage');

    expect(syncFailureMessage(error), apiMessage);
  });
}
