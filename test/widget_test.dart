import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/core/network/api_client.dart';
import 'package:asset_management_system/src/core/storage/asset_cache_store.dart';
import 'package:asset_management_system/src/core/storage/toggle_response_queue_store.dart';
import 'package:asset_management_system/src/core/storage/token_storage.dart';
import 'package:asset_management_system/src/features/data/models/asset_checklist_item.dart';
import 'package:asset_management_system/src/features/data/models/volunteer_asset.dart';
import 'package:asset_management_system/src/features/data/repositories/asset_repository.dart';
import 'package:asset_management_system/src/features/data/services/asset_service.dart';
import 'package:asset_management_system/src/features/presentation/providers/asset_provider.dart';
import 'package:asset_management_system/src/features/presentation/providers/auth_provider.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

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
    state = AuthStatus.authenticated;
  }
}

class _RejectedLoginAuthNotifier extends AuthNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> login(String email, String password) async {}
}

class _FakeAssetService extends AssetService {
  _FakeAssetService({
    required this.assets,
    required this.checklists,
    this.failAssets = false,
    this.failChecklistIds = const <String>{},
  }) : super(ApiClient(TokenStorage()));

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
  Future<List<AssetChecklistItem>> fetchChecklistByAssetId(String astId) async {
    if (failChecklistIds.contains(astId)) {
      throw Exception('offline');
    }

    return checklists[astId] ?? const <AssetChecklistItem>[];
  }
}

class _NoopToggleQueueStore extends ToggleResponseQueueStore {
  @override
  Future<int> enqueueAll(Iterable<int> responseIds) async => 0;

  @override
  Future<List<ToggleResponseQueueItem>> loadPending() async =>
      const <ToggleResponseQueueItem>[];

  @override
  Future<void> removeQueuedIds(Iterable<int> queueIds) async {}
}

void main() {
  testWidgets('email form only appears after pressing email login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_TestAuthNotifier.new)],
        child: _localizedApp(const LoginScreen()),
      ),
    );

    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.contactless), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(SquareActionButton).first);
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('failed login stays on login screen and does not show splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_RejectedLoginAuthNotifier.new)],
        child: _localizedApp(const LoginScreen()),
      ),
    );

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

  testWidgets('opening an asset checklist goes through QR/NFC first', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue(
            (context) async => 'AST-000001',
          ),
          myAssetsProvider.overrideWith(
            (ref) async => const [
              VolunteerAsset(
                name: 'Asset 1',
                details: 'Description of Asset 1',
                astId: 'AST-000001',
              ),
              VolunteerAsset(
                name: 'Asset 2',
                details: 'Description of Asset 2',
                astId: 'AST-000002',
              ),
              VolunteerAsset(
                name: 'Asset 3',
                details: 'Description of Asset 3',
                astId: 'AST-000003',
              ),
            ],
          ),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const [
              AssetChecklistItem(
                responseId: 6,
                title: 'Battery Condition',
                response: false,
              ),
              AssetChecklistItem(
                responseId: 7,
                title: 'Rafid er Condition',
                response: false,
              ),
            ],
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

  testWidgets('asset card hides ast id and truncates long description', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        const AssetCardBuilder(
          asset: AssetCardData(
            title: 'Asset A',
            description: 'one two three four five six seven eight nine ten',
            astId: 'AST-000001',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AST-000001'), findsNothing);
    expect(
      find.text('one two three four five six seven eight...'),
      findsOneWidget,
    );
  });

  testWidgets('home scan opens checklist for matching ast id', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue(
            (context) async => '{"ast_ID":"AST-000002"}',
          ),
          myAssetsProvider.overrideWith(
            (ref) async => const [
              VolunteerAsset(
                name: 'Asset 1',
                details: 'Description of Asset 1',
                astId: 'AST-000001',
              ),
              VolunteerAsset(
                name: 'Asset 2',
                details: 'Description of Asset 2',
                astId: 'AST-000002',
              ),
            ],
          ),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const [
              AssetChecklistItem(
                responseId: 6,
                title: 'Battery Condition',
                response: false,
              ),
            ],
          ),
        ],
        child: _localizedApp(const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.byType(AssetChecklistScreen), findsOneWidget);
    expect(find.text('Checklist for Asset 2'), findsOneWidget);
    expect(find.text('Battery Condition'), findsOneWidget);
  });

  testWidgets(
    'home scan with unmatched ast id stays on home and shows mismatch',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            qrScannerLauncherProvider.overrideWithValue(
              (context) async => 'AST-000999',
            ),
            myAssetsProvider.overrideWith(
              (ref) async => const [
                VolunteerAsset(
                  name: 'Asset 1',
                  details: 'Description of Asset 1',
                  astId: 'AST-000001',
                ),
              ],
            ),
            assetChecklistProvider.overrideWith(
              (ref, astId) async => const <AssetChecklistItem>[],
            ),
          ],
          child: _localizedApp(const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan'));
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('does not match'), findsOneWidget);
      expect(find.byType(AssetChecklistScreen), findsNothing);
    },
  );

  testWidgets('home asset list loads more items when scrolling down', (
    WidgetTester tester,
  ) async {
    final assets = List<VolunteerAsset>.generate(
      15,
      (index) => VolunteerAsset(
        name: 'Asset ${index + 1}',
        details: 'Description ${index + 1}',
        astId: 'AST-${(index + 1).toString().padLeft(6, '0')}',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAssetsProvider.overrideWith((ref) async => assets),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const [
              AssetChecklistItem(
                responseId: 1,
                title: 'Battery Condition',
                response: false,
              ),
            ],
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

  testWidgets('home asset list pull down refresh reloads assets', (
    WidgetTester tester,
  ) async {
    var fetchCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAssetsProvider.overrideWith((ref) async {
            fetchCount += 1;
            return const [
              VolunteerAsset(
                name: 'Asset 1',
                details: 'Description of Asset 1',
                astId: 'AST-000001',
              ),
            ];
          }),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const [
              AssetChecklistItem(
                responseId: 1,
                title: 'Battery Condition',
                response: false,
              ),
            ],
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

  testWidgets('mismatched qr code keeps the user on the qr screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue(
            (context) async => 'WRONG-000999',
          ),
          myAssetsProvider.overrideWith(
            (ref) async => const [
              VolunteerAsset(
                name: 'Asset 1',
                details: 'Description of Asset 1',
                astId: 'AST-000001',
              ),
            ],
          ),
          assetChecklistProvider.overrideWith(
            (ref, astId) async => const <AssetChecklistItem>[],
          ),
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

  testWidgets('nfc does not bypass qr matching for checklist access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrScannerLauncherProvider.overrideWithValue(
            (context) async => 'AST-000001',
          ),
        ],
        child: _localizedApp(
          const QrNfcScreen(
            asset: AssetCardData(
              title: 'Asset 1',
              description: 'Description of Asset 1',
              astId: 'AST-000001',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('NFC'));
    await tester.pump();

    expect(find.byType(AssetChecklistScreen), findsNothing);
    expect(
      find.text('Please use QR code matching to open the checklist'),
      findsOneWidget,
    );
  });

  test(
    'asset repository falls back to cached assets and checklist data',
    () async {
      const userKey = 'user@example.com';
      SharedPreferences.setMockInitialValues({});
      final cache = AssetCacheStore();
      final onlineService = _FakeAssetService(
        assets: const [
          VolunteerAsset(
            name: 'Asset 1',
            details: 'Description of Asset 1',
            astId: 'AST-000001',
          ),
        ],
        checklists: const {
          'AST-000001': [
            AssetChecklistItem(
              responseId: 1,
              title: 'Battery Condition',
              response: true,
            ),
          ],
        },
      );

      final onlineRepository = AssetRepository(
        onlineService,
        () async => userKey,
        cache,
        _NoopToggleQueueStore(),
      );
      await onlineRepository.prefetchOfflineData(userKey);

      final offlineRepository = AssetRepository(
        _FakeAssetService(
          assets: const [],
          checklists: const {},
          failAssets: true,
          failChecklistIds: const {'AST-000001'},
        ),
        () async => userKey,
        cache,
        _NoopToggleQueueStore(),
      );

      final cachedAssets = await offlineRepository.fetchMyAssets();
      final cachedChecklist = await offlineRepository.fetchChecklistByAssetId(
        'AST-000001',
      );

      expect(cachedAssets, hasLength(1));
      expect(cachedAssets.first.astId, 'AST-000001');
      expect(cachedChecklist, hasLength(1));
      expect(cachedChecklist.first.title, 'Battery Condition');
      expect(cachedChecklist.first.response, isTrue);
    },
  );
}
