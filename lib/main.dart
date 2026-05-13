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
import 'data/repositories/auth_repository.dart';
import 'data/repositories/delivery_repository.dart';
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

  final api = useMock ? MockDeliveryApi() : HttpDeliveryApi(baseUrl: baseUrl);

  final prefs = await SharedPreferences.getInstance();
  final locale = LocaleService(prefs);
  await locale.hydrate();

  runApp(TrailRoot(api: api, locale: locale));
}

class TrailRoot extends StatelessWidget {
  const TrailRoot({super.key, required this.api, required this.locale});
  final DeliveryApi api;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final deliveryRepo = DeliveryRepository(api);
    final authRepo = AuthRepository(api);

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
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => MasterPosProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => VendorListProvider(deliveryRepo)),
        ChangeNotifierProvider(create: (_) => VendorDetailProvider(deliveryRepo)),
      ],
      child: const TrailApp(),
    );
  }
}
