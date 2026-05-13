import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` so the UI never imports the plugin directly.
class LocationService {
  Future<GpsFix?> currentFix({Duration timeout = const Duration(seconds: 8)}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
    );
    return GpsFix(lat: pos.latitude, lng: pos.longitude, accuracyMeters: pos.accuracy);
  }
}

class GpsFix {
  final double lat;
  final double lng;
  final double accuracyMeters;
  const GpsFix({required this.lat, required this.lng, required this.accuracyMeters});

  String get pretty => '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}
