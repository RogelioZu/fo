import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Estado de la ubicación seleccionada activamente por el usuario.
/// Todos los features que dependan de "nearby" deben watchear este provider.
class SelectedLocation extends Equatable {
  final String city;
  final String country;
  final double? lat;
  final double? lng;

  const SelectedLocation({
    required this.city,
    required this.country,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [city, country, lat, lng];
}

/// Notifier que gestiona la ubicación seleccionada.
/// Se inicializa con la ubicación del perfil del usuario.
class SelectedLocationNotifier extends StateNotifier<SelectedLocation?> {
  SelectedLocationNotifier() : super(null);

  bool get hasLocation => state != null;

  void setLocation({
    required String city,
    required String country,
    double? lat,
    double? lng,
  }) {
    state = SelectedLocation(city: city, country: country, lat: lat, lng: lng);
  }

  /// Inicializa solo si aún no hay ubicación seleccionada.
  void initializeFromProfile({
    required String city,
    required String country,
    double? lat,
    double? lng,
  }) {
    if (state != null) return;
    state = SelectedLocation(city: city, country: country, lat: lat, lng: lng);
  }

  void clear() => state = null;
}

/// Provider global de ubicación seleccionada.
/// Se inicializa automáticamente con la ubicación del perfil del usuario.
final selectedLocationProvider =
    StateNotifierProvider<SelectedLocationNotifier, SelectedLocation?>((ref) {
  final notifier = SelectedLocationNotifier();

  // Inicializar con la ubicación del perfil al arrancar
  final userAsync = ref.watch(currentUserProvider);
  userAsync.whenData((user) {
    if (user != null && user.city != null && user.city!.isNotEmpty) {
      notifier.initializeFromProfile(
        city: user.city!,
        country: user.country ?? '',
        lat: user.lat,
        lng: user.lng,
      );
    }
  });

  return notifier;
});
