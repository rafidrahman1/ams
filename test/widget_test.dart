import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/core/network/api_client.dart';
import 'package:asset_management_system/src/core/storage/local_database.dart';
import 'package:asset_management_system/src/core/storage/token_storage.dart';
import 'package:asset_management_system/src/features/data/models/asset_checklist_item.dart';
import 'package:asset_management_system/src/features/data/models/volunteer_asset.dart';
import 'package:asset_management_system/src/features/data/repositories/asset_repository.dart';
import 'package:asset_management_system/src/features/data/services/asset_service.dart';
import 'package:asset_management_system/src/features/presentation/providers/asset_provider.dart';
import 'package:asset_management_system/src/features/presentation/providers/auth_provider.dart';
import 'package:asset_management_system/src/features/presentation/providers/nfc_scanner_provider.dart';
import 'package:asset_management_system/src/features/presentation/providers/qr_scanner_provider.dart';
import 'package:asset_management_system/src/features/presentation/screens/asset_checklist_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/home_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/login_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/qr_nfc_screen.dart';
import 'package:asset_management_system/src/features/presentation/screens/splash_screen.dart';
import 'package:asset_management_system/src/features/presentation/widgets/asset_card_builder.dart';
import 'package:asset_management_system/src/features/presentation/widgets/square_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _localizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('bn')],
    home: child,
  );
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> login(String email, String password) async {
    state = AuthStatus.authenticatedVolunteer;
  }
}

class _RejectedLoginAuthNotifier extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> login(String email, String password) async {}
}

class _FakeAssetService extends AssetService {
  _FakeAssetService({required this.assets, required this.checklists, this.failAssets = false, this.failChecklistIds = const <String>{}}) : super(ApiClient(TokenStorage()));

  final List<VolunteerAsset> assets;
  final Map<String, List<AssetChecklistItem>> checklists;
  final bool failAssets;
  final Set<String> failChecklistIds;

  @override
  Future<List<VolunteerAsset>> fetchMyAssets() async {
    if (failAssets) {
      throw Exception('offline');
    }

    return assets;
  }

  @override
  Future<AssetChecklist> fetchChecklistByAssetId(String astId) async {
    if (failChecklistIds.contains(astId)) {
      throw Exception('offline');
    }

    return AssetChecklist(items: checklists[astId] ?? const <AssetChecklistItem>[]);
  }

  @override
  Future<Map<String, dynamic>> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required String parameter,
    required String image,
    required List<({int featureId, bool response})> items,
  }) async {
    return {
      'code': 200,
      'data': {
        'asset_status': status,
        'remark': remark,
        'parameter': parameter,
        'image': image,
        'features': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(),
      },
    };
  }
}

class _MemoryLocalDatabase extends LocalDatabase {
  final Map<String, List<VolunteerAsset>> _assets = {};
  final Map<String, List<AssetChecklistItem>> _checklists = {};
  final List<Map<String, dynamic>> _submissions = [];
  int _nextQueueId = 1;

  @override
  Future<void> saveAssets(String userKey, List<VolunteerAsset> assets) async {
    _assets[userKey] = assets;
  }

  @override
  Future<List<VolunteerAsset>> loadAssets(String userKey) async {
    return _assets[userKey] ?? [];
  }

  @override
  Future<void> saveChecklist(String userKey, String astId, List<AssetChecklistItem> items) async {
    _checklists['$userKey-$astId'] = items;
  }

  @override
  Future<List<AssetChecklistItem>> loadChecklist(String userKey, String astId) async {
    return _checklists['$userKey-$astId'] ?? [];
  }

  @override
  Future<int> enqueueChecklistSubmission(String userKey, String astId, String payloadJson) async {
    _submissions.add({
      'id': _nextQueueId++,
      'user_key': userKey,
      'ast_id': astId,
      'payload_json': payloadJson,
      'synced_at': null,
      'retry_count': 0,
      'last_error': null,
      'next_retry_at': null,
    });
    return 1;
  }

  @override
  Future<List<ChecklistSubmissionQueueItem>> loadPendingChecklistSubmissions(String userKey) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _submissions
        .where((s) {
          if (s['user_key'] != userKey || s['synced_at'] != null) return false;
          final next = s['next_retry_at'] as int?;
          return next == null || next <= now;
        })
        .map(
          (s) => ChecklistSubmissionQueueItem(
            queueId: s['id'] as int,
            astId: s['ast_id'] as String,
            payloadJson: s['payload_json'] as String,
            retryCount: (s['retry_count'] as int?) ?? 0,
            lastError: s['last_error'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> recordChecklistSubmissionSyncFailure(int queueId, String errorMessage) async {
    for (final s in _submissions) {
      if (s['id'] == queueId) {
        final prev = (s['retry_count'] as int?) ?? 0;
        final next = prev + 1;
        s['retry_count'] = next;
        s['last_error'] = errorMessage.length > 500 ? '${errorMessage.substring(0, 497)}...' : errorMessage;
        s['next_retry_at'] = DateTime.now().millisecondsSinceEpoch + LocalDatabase.backoffMsForAttempt(next);
        break;
      }
    }
  }

  @override
  Future<void> markQueuedChecklistSubmissionsSynced(Iterable<int> queueIds) async {
    final idSet = queueIds.toSet();
    for (final s in _submissions) {
      if (idSet.contains(s['id'])) {
        s['synced_at'] = 1;
      }
    }
  }

  @override
  Future<String?> loadLatestChecklistSubmissionPayload(String userKey, String astId) async {
    for (final s in _submissions.reversed) {
      if (s['user_key'] == userKey && s['ast_id'] == astId) {
        return s['payload_json'] as String;
      }
    }
    return null;
  }

  @override
  Future<void> clearAll() async {
    _assets.clear();
    _checklists.clear();
    _submissions.clear();
  }
}

class _SingleChecklistThenOfflineService extends AssetService {
  _SingleChecklistThenOfflineService({required this.assets, required this.checklists}) : super(ApiClient(TokenStorage()));

  final List<VolunteerAsset> assets;
  final Map<String, List<AssetChecklistItem>> checklists;
  int _checklistFetchCount = 0;

  @override
  Future<List<VolunteerAsset>> fetchMyAssets() async => assets;

  @override
  Future<AssetChecklist> fetchChecklistByAssetId(String astId) async {
    _checklistFetchCount += 1;
    if (_checklistFetchCount > 1) {
      throw Exception('offline');
    }

    return AssetChecklist(items: checklists[astId] ?? const <AssetChecklistItem>[]);
  }

  @override
  Future<Map<String, dynamic>> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required String parameter,
    required String image,
    required List<({int featureId, bool response})> items,
  }) async {
    return {
      'code': 200,
      'data': {
        'asset_status': status,
        'remark': remark,
        'parameter': parameter,
        'image': image,
        'features': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(),
      },
    };
  }
}

class _RecordingAssetService extends AssetService {
  _RecordingAssetService() : super(ApiClient(TokenStorage()));

  final bool failSubmit = false;
  final List<String> submittedAstIds = <String>[];

  @override
  Future<List<VolunteerAsset>> fetchMyAssets() async => const <VolunteerAsset>[];

  @override
  Future<AssetChecklist> fetchChecklistByAssetId(String astId) async => const AssetChecklist(items: <AssetChecklistItem>[]);

  @override
  Future<Map<String, dynamic>> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required String parameter,
    required String image,
    required List<({int featureId, bool response})> items,
  }) async {
    submittedAstIds.add(astId);
    if (failSubmit) {
      throw Exception('sync failed');
    }
    return {
      'code': 200,
      'data': {
        'asset_status': status,
        'remark': remark,
        'parameter': parameter,
        'image': image,
        'features': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(),
      },
    };
  }
}

void main() {
  testWidgets('email form only appears after pressing email login', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [authProvider.overrideWith(_TestAuthNotifier.new)], child: _localizedApp(const LoginScreen())));

    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.contactless), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(SquareActionButton).first);
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('failed login stays on login screen and does not show splash', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [authProvider.overrideWith(_RejectedLoginAuthNotifier.new)], child: _localizedApp(const LoginScreen())));

    await tester.tap(find.byType(SquareActionButton).first);
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('opening an asset checklist goes through QR/NFC first', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue((context) async => 'AST-000001'),
          myAssetsProvider.overrideWith(
            (ref) async => const [
              VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001'),
              VolunteerAsset(name: 'Asset 2', details: 'Description of Asset 2', astId: 'AST-000002'),
              VolunteerAsset(name: 'Asset 3', details: 'Description of Asset 3', astId: 'AST-000003'),
            ],
          ),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const AssetChecklist(
              items: [
                AssetChecklistItem(featureId: 6, title: 'Battery Condition', response: false),
                AssetChecklistItem(featureId: 7, title: 'Rafid er Condition', response: false),
              ],
            ),
          ),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Check List'), findsNWidgets(3));

    await tester.tap(find.text('Check List').first);
    await tester.pumpAndSettle();

    expect(find.byType(QrNfcScreen), findsOneWidget);
    expect(find.text('QR/NFC Scanner'), findsOneWidget);

    await tester.tap(find.text('QR Code'));
    await tester.pumpAndSettle();

    expect(find.text('Checklist for Asset 1'), findsOneWidget);
    expect(find.text('Battery Condition'), findsOneWidget);
    expect(find.text('Rafid er Condition'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('asset card hides ast id and truncates long description', (WidgetTester tester) async {
    await tester.pumpWidget(
      _localizedApp(
        const AssetCardBuilder(
          asset: AssetCardData(title: 'Asset A', description: 'one two three four five six seven eight nine ten', astId: 'AST-000001'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AST-000001'), findsNothing);
    expect(find.text('one two three four five six seven eight...'), findsOneWidget);
  });

  testWidgets('home scan opens checklist for matching ast id', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue((context) async => '{"ast_ID":"AST-000002"}'),
          myAssetsProvider.overrideWith(
            (ref) async => const [
              VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001'),
              VolunteerAsset(name: 'Asset 2', details: 'Description of Asset 2', astId: 'AST-000002'),
            ],
          ),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const AssetChecklist(items: [AssetChecklistItem(featureId: 6, title: 'Battery Condition', response: false)]),
          ),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('QR Code'), findsOneWidget);
    expect(find.text('NFC'), findsOneWidget);

    await tester.tap(find.text('QR Code'));
    await tester.pumpAndSettle();

    expect(find.byType(AssetChecklistScreen), findsOneWidget);
    expect(find.text('Checklist for Asset 2'), findsOneWidget);
    expect(find.text('Battery Condition'), findsOneWidget);
  });

  testWidgets('home scan opens checklist for matching nfc_ast_id', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nfcScannerLauncherProvider.overrideWithValue((context) async => '{"astId":"AST-000002"}'),
          myAssetsProvider.overrideWith(
            (ref) async => const [
              VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001'),
              VolunteerAsset(name: 'Asset 2', details: 'Description of Asset 2', astId: 'AST-000002'),
            ],
          ),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const AssetChecklist(items: [AssetChecklistItem(featureId: 6, title: 'Battery Condition', response: false)]),
          ),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NFC'));
    await tester.pumpAndSettle();

    expect(find.byType(AssetChecklistScreen), findsOneWidget);
    expect(find.text('Checklist for Asset 2'), findsOneWidget);
    expect(find.text('Battery Condition'), findsOneWidget);
  });

  testWidgets('home scan with unmatched ast id stays on home and shows mismatch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue((context) async => 'AST-000999'),
          myAssetsProvider.overrideWith((ref) async => const [VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001')]),
          assetChecklistProvider.overrideWith((ref, astId) async => const AssetChecklist(items: <AssetChecklistItem>[])),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('QR Code'));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('does not match'), findsOneWidget);
    expect(find.byType(AssetChecklistScreen), findsNothing);
  });

  testWidgets('home asset list loads more items when scrolling down', (WidgetTester tester) async {
    final assets = List<VolunteerAsset>.generate(
      15,
      (index) => VolunteerAsset(name: 'Asset ${index + 1}', details: 'Description ${index + 1}', astId: 'AST-${(index + 1).toString().padLeft(6, '0')}'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAssetsProvider.overrideWith((ref) async => assets),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const AssetChecklist(items: [AssetChecklistItem(featureId: 1, title: 'Battery Condition', response: false)]),
          ),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Asset 11'), findsOneWidget);
  });

  testWidgets('home asset list pull down refresh reloads assets', (WidgetTester tester) async {
    var fetchCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAssetsProvider.overrideWith((ref) async {
            fetchCount += 1;
            return const [VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001')];
          }),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const AssetChecklist(items: [AssetChecklistItem(featureId: 1, title: 'Battery Condition', response: false)]),
          ),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(fetchCount, 1);

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(fetchCount, greaterThanOrEqualTo(2));
  });

  testWidgets('admin home device card opens stored db details', (WidgetTester tester) async {
    final device = RegisteredDeviceData(
      id: 1,
      astId: 'AST-000777',
      name: 'Generator',
      details: 'Backup generator for building A',
      addressLine: 'Warehouse 4',
      status: 'ACTIVE',
      assetType: 'Electrical',
      location: 'Main Camp',
      block: 'Block B',
      imagePath: '/tmp/generator.jpg',
      warrantyEnd: '2026-12-31',
      specification: '{"capacity":"20kVA"}',
      amount: '120000',
      purchaseDate: '2026-01-10',
      manufactureDate: '2025-12-01',
      assetAttachment: '/tmp/generator.pdf',
      createdAt: DateTime(2026, 4, 29),
      synced: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminAssetsProvider.overrideWith((ref) async => const <VolunteerAsset>[]),
          unsyncedRegisteredDevicesProvider.overrideWith((ref) async => [device]),
          registeredDeviceProvider.overrideWith((ref, id) async => id == device.id ? device : null),
        ],
        child: _localizedApp(const HomeScreen(isAdmin: true)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Generator'), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Device Details'), findsOneWidget);
    expect(find.text('AST-000777'), findsOneWidget);
    expect(find.text('Backup generator for building A'), findsOneWidget);
    expect(find.text('Warehouse 4'), findsOneWidget);
  });

  testWidgets('mismatched qr code keeps the user on the qr screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue((context) async => 'WRONG-000999'),
          myAssetsProvider.overrideWith((ref) async => const [VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001')]),
          assetChecklistProvider.overrideWith((ref, astId) async => const AssetChecklist(items: <AssetChecklistItem>[])),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Check List').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('QR Code'));
    await tester.pumpAndSettle();

    expect(find.byType(QrNfcScreen), findsOneWidget);
    expect(find.textContaining('does not match'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('matching nfc scan opens checklist from qr_nfc_screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nfcScannerLauncherProvider.overrideWithValue((context) async => 'AST-000001'),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const AssetChecklist(items: [AssetChecklistItem(featureId: 1, title: 'Battery Condition', response: false)]),
          ),
        ],
        child: _localizedApp(
          const QrNfcScreen(
            asset: AssetCardData(title: 'Asset 1', description: 'Description of Asset 1', astId: 'AST-000001'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('NFC'));
    await tester.pumpAndSettle();

    expect(find.byType(AssetChecklistScreen), findsOneWidget);
    expect(find.text('Checklist for Asset 1'), findsOneWidget);
  });

  testWidgets('mismatched nfc scan keeps user on qr_nfc_screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [nfcScannerLauncherProvider.overrideWithValue((context) async => 'WRONG-000999')],
        child: _localizedApp(
          const QrNfcScreen(
            asset: AssetCardData(title: 'Asset 1', description: 'Description of Asset 1', astId: 'AST-000001'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('NFC'));
    await tester.pumpAndSettle();

    expect(find.byType(QrNfcScreen), findsOneWidget);
    expect(find.byType(AssetChecklistScreen), findsNothing);
    expect(find.textContaining('does not match'), findsOneWidget);
  });

  test('asset repository falls back to cached assets and checklist data', () async {
    const userKey = 'user@example.com';
    final db = _MemoryLocalDatabase();
    final onlineService = _FakeAssetService(
      assets: const [VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001')],
      checklists: const {
        'AST-000001': [AssetChecklistItem(featureId: 1, title: 'Battery Condition', response: true)],
      },
    );

    final onlineRepository = AssetRepository(onlineService, () async => userKey, db);
    await onlineRepository.prefetchOfflineData(userKey, isAdmin: false);

    final offlineRepository = AssetRepository(
      _FakeAssetService(assets: const [], checklists: const {}, failAssets: true, failChecklistIds: const {'AST-000001'}),
      () async => userKey,
      db,
    );

    final cachedAssets = await offlineRepository.fetchMyAssets();
    final cachedChecklist = await offlineRepository.fetchChecklistByAssetId('AST-000001');

    expect(cachedAssets, hasLength(1));
    expect(cachedAssets.first.astId, 'AST-000001');
    expect(cachedChecklist.items, hasLength(1));
    expect(cachedChecklist.items.first.title, 'Battery Condition');
    expect(cachedChecklist.items.first.response, isTrue);
  });

  test('asset repository keeps the last toggled checklist state when offline sync is pending', () async {
    const userKey = 'user@example.com';
    final db = _MemoryLocalDatabase();
    await db.enqueueChecklistSubmission(userKey, 'AST-000001', '{"ast_ID":"AST-000001","status":"ACTIVE","remark":"","items":[{"feature_id":1,"response":true}]}');

    final service = _SingleChecklistThenOfflineService(
      assets: const [VolunteerAsset(name: 'Asset 1', details: 'Description of Asset 1', astId: 'AST-000001')],
      checklists: const {
        'AST-000001': [AssetChecklistItem(featureId: 1, title: 'Battery Condition', response: false)],
      },
    );

    final repository = AssetRepository(service, () async => userKey, db);

    final firstChecklist = await repository.fetchChecklistByAssetId('AST-000001');
    final secondChecklist = await repository.fetchChecklistByAssetId('AST-000001');

    expect(firstChecklist.items, hasLength(1));
    expect(firstChecklist.items.first.response, isTrue);
    expect(secondChecklist.items, hasLength(1));
    expect(secondChecklist.items.first.response, isTrue);
  });

  test('sync submits the latest queued payload per asset', () async {
    final service = _RecordingAssetService();
    final db = _MemoryLocalDatabase();
    const userKey = 'user@example.com';
    const astId = 'AST-000001';

    await db.enqueueChecklistSubmission(userKey, astId, '{"ast_ID":"AST-000001","status":"ACTIVE","remark":"","items":[{"feature_id":42,"response":true}]}');

    final repository = AssetRepository(service, () async => userKey, db);

    await repository.syncQueuedResponses();

    expect(service.submittedAstIds, [astId]);
  });
}
