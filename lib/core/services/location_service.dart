import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Servicio para obtener la ubicación del usuario y resolver ciudad/país.
class LocationService {
  /// Solicita permisos de ubicación y obtiene la posición actual.
  /// Retorna null si el permiso fue denegado.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  /// Obtiene ciudad y país a partir de coordenadas.
  static Future<({String? city, String? country})?> getCityFromPosition(
    Position position,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return (
          city: place.locality ?? place.subAdministrativeArea,
          country: place.country,
        );
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
    }
    return null;
  }

  /// Solicita permiso, obtiene ubicación, resuelve ciudad/país y retorna todo.
  static Future<({double lat, double lng, String? city, String? country})?>
      requestAndResolveLocation() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final geo = await getCityFromPosition(position);
    return (
      lat: position.latitude,
      lng: position.longitude,
      city: geo?.city,
      country: geo?.country,
    );
  }
}
