import 'dart:developer' as developer;

/// Lightweight logger so every catch site has a uniform, greppable trail.
/// Output appears in `flutter logs` / IDE consoles tagged with `app`.
class AppLog {
  AppLog._();

  static void info(String tag, String message) {
    developer.log('[$tag] $message', name: 'app');
  }

  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    developer.log(
      '[$tag] $error',
      name: 'app',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // SEVERE
    );
  }
}
