import 'city_suggestion.dart';

/// Contrato abstracto del servicio de búsqueda de ciudades.
///
/// Permite intercambiar la implementación (Google Places, GeoDB, etc.)
/// sin afectar el resto de la app.
abstract class PlacesService {
  /// Busca ciudades que coincidan con [query].
  ///
  /// Retorna una lista de [CitySuggestion] con nombre, estado y país.
  /// Usa session tokens para optimizar costos de facturación.
  Future<List<CitySuggestion>> searchCities(String query);

  /// Obtiene los detalles (lat/lng) de un lugar por su [placeId].
  ///
  /// Retorna la [CitySuggestion] original enriquecida con coordenadas.
  /// Esta llamada finaliza la sesión del session token.
  Future<CitySuggestion> getCityDetails(CitySuggestion suggestion);

  /// Inicia una nueva sesión de autocompletado.
  ///
  /// Debe llamarse al iniciar una nueva búsqueda (cuando el usuario
  /// limpia el campo o abre la pantalla).
  void startNewSession();

  /// Libera recursos del servicio.
  void dispose();
}
