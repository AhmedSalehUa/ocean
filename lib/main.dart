import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/utils/app_log.dart';
import 'data/api/delivery_api.dart';
import 'data/api/http_delivery_api.dart';
import 'data/api/mock_delivery_api.dart';
import 'data/api/offline_cache_store.dart';
import 'data/api/outbox_delivery_api.dart';
import 'data/offline/outbox_store.dart';
import 'data/offline/sync_engine.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/delivery_repository.dart';
import 'features/assistant/assistant_tasks_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/master_pos_provider.dart';
import 'features/vendor_detail/vendor_detail_provider.dart';
import 'features/vendor_list/vendor_list_provider.dart';
import 'services/camera_service.dart';
import 'services/connectivity_service.dart';
import 'services/locale_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLog.error('FlutterError', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    AppLog.error('PlatformDispatcher', error, stack);
    return false;
  };

  try {
    await dotenv.load();
  } catch (e, st) {
    // .env is optional in production; rely on --dart-define.
    AppLog.info('dotenv', 'no .env loaded ($e)');
    AppLog.error('dotenv', e, st);
  }

  await initializeDateFormatting();

  final useMockFromEnv = (dotenv.env['USE_MOCK'] ?? 'true').toLowerCase() == 'true';
  const useMockFromBuild = String.fromEnvironment('USE_MOCK', defaultValue: '');
  final useMock =
      useMockFromBuild.isEmpty ? useMockFromEnv : useMockFromBuild.toLowerCase() == 'true';

  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000';

  final prefs = await SharedPreferences.getInstance();

  final connectivity = ConnectivityService();

  // Offline read cache (Phase 1): GET responses are cached and replayed when
  // the device can't reach the server.
  final offlineCache = OfflineCacheStore(prefs);
  final outbox = OutboxStore(prefs);
  await outbox.load();

  final inner = useMock
      ? MockDeliveryApi()
      : HttpDeliveryApi(baseUrl: baseUrl, cache: offlineCache);
  // Writes queue to the outbox when offline; the sync engine replays them.
  final api = OutboxDeliveryApi(inner: inner, outbox: outbox, connectivity: connectivity);
  // Load the cached JWT into memory now so synchronous consumers (e.g.
  // CachedNetworkImage's httpHeaders) see it on the very first proof image
  // request, not just after the first authenticated Dio call.
  await api.primeAuth();

  final sync = SyncEngine(inner: inner, outbox: outbox, connectivity: connectivity)..start();

  final locale = LocaleService(prefs);
  await locale.hydrate();

  runApp(TrailRoot(
    api: api,
    locale: locale,
    connectivity: connectivity,
    outbox: outbox,
    sync: sync,
  ));
}

class TrailRoot extends StatelessWidget {
  const TrailRoot({
    super.key,
    required this.api,
    required this.locale,
    required this.connectivity,
    required this.outbox,
    required this.sync,
  });
  final DeliveryApi api;
  final LocaleService locale;
  final ConnectivityService connectivity;
  final OutboxStore outbox;
  final SyncEngine sync;

  @override
  Widget build(BuildContext context) {
    final deliveryRepo = DeliveryRepository(api);
    final authRepo = AuthRepository(api);

    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: outbox),
        ChangeNotifierProvider.value(value: sync),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<CameraService>(create: (_) => CameraService()),

        // Repositories
        Provider.value(value: deliveryRepo),
        Provider.value(value: authRepo),

        // State
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => MasterPosProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => VendorListProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => VendorDetailProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => AssistantTasksProvider(deliveryRepo)),
      ],
      child: const TrailApp(),
    );
  }
}
