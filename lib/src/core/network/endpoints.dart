class Endpoints {
  static const login = "/api/authentication/token";
  static const adminLogin = "/api/authentication/admin/token";
  static const refresh = "/api/authentication/token/refresh";
  static const myAsset = "/api/volunteer/my-asset";
  static const adminAsset = "/api/admin/assets";
  static const assetChecklistByAssetBase = "/api/asset/responses/by-asset";
  static const assetChecklistSubmit = "/api/asset/responses/submit";
  static const assetCreate = "/api/asset/create/by-QR";

  static const campLocations = "/api/location/camp-location";
  static const assetTypes = "/api/asset/type/list";

  static String blocksByCamp(int campId) => "/api/location/block/read/camp/$campId";
}
