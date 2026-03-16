import 'package:equatable/equatable.dart';

/// Representa una sugerencia de ciudad del autocomplete.
///
/// Se usa tanto en el onboarding (selección de ciudad del usuario)
/// como en cualquier feature que necesite buscar ciudades.
class CitySuggestion extends Equatable {
  /// ID único del lugar en Google Places.
  final String placeId;

  /// Nombre principal de la ciudad (ej: "Monterrey").
  final String city;

  /// Estado o región (ej: "Nuevo León").
  final String? state;

  /// País (ej: "México").
  final String country;

  /// Descripción completa formateada (ej: "Monterrey, Nuevo León, México").
  final String fullDescription;

  /// Latitud (disponible tras llamar a getPlaceDetails).
  final double? lat;

  /// Longitud (disponible tras llamar a getPlaceDetails).
  final double? lng;

  const CitySuggestion({
    required this.placeId,
    required this.city,
    this.state,
    required this.country,
    required this.fullDescription,
    this.lat,
    this.lng,
  });

  /// Crea una copia con campos modificados.
  CitySuggestion copyWith({
    String? placeId,
    String? city,
    String? state,
    String? country,
    String? fullDescription,
    double? lat,
    double? lng,
  }) {
    return CitySuggestion(
      placeId: placeId ?? this.placeId,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      fullDescription: fullDescription ?? this.fullDescription,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  List<Object?> get props => [placeId, city, state, country, lat, lng];
}
