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
import 'data/repositories/auth_repository.dart';
import 'data/repositories/delivery_repository.dart';
import 'features/assistant/assistant_tasks_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/master_pos_provider.dart';
import 'features/vendor_detail/vendor_detail_provider.dart';
import 'features/vendor_list/vendor_list_provider.dart';
import 'services/camera_service.dart';
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
  final cache = OfflineCacheStore(prefs);

  final api =
      useMock ? MockDeliveryApi() : HttpDeliveryApi(baseUrl: baseUrl, cache: cache);
  // Load the cached JWT into memory now so synchronous consumers (e.g.
  // CachedNetworkImage's httpHeaders) see it on the very first proof image
  // request, not just after the first authenticated Dio call.
  await api.primeAuth();

  final locale = LocaleService(prefs);
  await locale.hydrate();

  // Restore a previous session (token + user) before the first frame so a
  // returning user lands straight in the app — online or offline.
  final authRepo = AuthRepository(api);
  final authProvider = AuthProvider(authRepo, prefs, cache: cache);
  await authProvider.restore();

  runApp(TrailRoot(
    api: api,
    locale: locale,
    authRepo: authRepo,
    authProvider: authProvider,
  ));
}

class TrailRoot extends StatelessWidget {
  const TrailRoot({
    super.key,
    required this.api,
    required this.locale,
    required this.authRepo,
    required this.authProvider,
  });
  final DeliveryApi api;
  final LocaleService locale;
  final AuthRepository authRepo;
  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    final deliveryRepo = DeliveryRepository(api);

    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider.value(value: locale),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<CameraService>(create: (_) => CameraService()),

        // Repositories
        Provider.value(value: deliveryRepo),
        Provider.value(value: authRepo),

        // State
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => MasterPosProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => VendorListProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => VendorDetailProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => AssistantTasksProvider(deliveryRepo)),
      ],
      child: const TrailApp(),
    );
  }
}
