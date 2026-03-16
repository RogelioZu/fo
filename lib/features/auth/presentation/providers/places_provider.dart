import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/places/google_places_service.dart';
import '../../../../core/services/places/places_service.dart';

/// Provider del servicio de Google Places.
///
/// Se usa en el setup de ubicación y puede reutilizarse
/// en cualquier feature que necesite autocompletar ciudades.
final placesServiceProvider = Provider<PlacesService>((ref) {
  final service = GooglePlacesService();
  ref.onDispose(() => service.dispose());
  return service;
});
