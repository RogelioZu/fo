import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../config/env.dart';
import 'city_suggestion.dart';
import 'places_service.dart';

/// Implementación de [PlacesService] usando Google Places API.
///
/// Usa **session tokens** para agrupar las búsquedas de autocomplete
/// con su respectiva llamada a Place Details en una sola sesión de
/// facturación, reduciendo costos dramáticamente.
///
/// Flujo de facturación con session tokens:
///   1. Usuario escribe → N llamadas a Autocomplete (gratis con token)
///   2. Usuario selecciona → 1 llamada a Place Details ($0.017)
///   3. Total por sesión: ~$0.017 en vez de $0.00283 × N
class GooglePlacesService implements PlacesService {
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const _uuid = Uuid();

  final http.Client _httpClient;
  String _sessionToken;

  GooglePlacesService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _sessionToken = _uuid.v4();

  /// API key de Google Cloud.
  String get _apiKey => Env.googleMapsApiKey;

  // ─── Autocomplete ───

  @override
  Future<List<CitySuggestion>> searchCities(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final uri = Uri.parse('$_baseUrl/autocomplete/json').replace(
        queryParameters: {
          'input': query.trim(),
          'types': '(cities)',
          'key': _apiKey,
          'sessiontoken': _sessionToken,
        },
      );

      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('Places API error: ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String;

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('Places API status: $status — ${json['error_message']}');
        return [];
      }

      final predictions = json['predictions'] as List<dynamic>? ?? [];

      return predictions.map((p) {
        final prediction = p as Map<String, dynamic>;
        final terms = prediction['terms'] as List<dynamic>? ?? [];

        // Google devuelve los terms en orden: [ciudad, estado, país]
        final city = terms.isNotEmpty ? terms[0]['value'] as String : '';
        final state = terms.length > 2 ? terms[1]['value'] as String : null;
        final country = terms.isNotEmpty
            ? terms[terms.length - 1]['value'] as String
            : '';

        return CitySuggestion(
          placeId: prediction['place_id'] as String,
          city: city,
          state: state,
          country: country,
          fullDescription: prediction['description'] as String? ?? city,
        );
      }).toList();
    } on TimeoutException {
      debugPrint('Places autocomplete timeout');
      return [];
    } catch (e) {
      debugPrint('Places autocomplete error: $e');
      return [];
    }
  }

  // ─── Place Details ───

  @override
  Future<CitySuggestion> getCityDetails(CitySuggestion suggestion) async {
    try {
      final uri = Uri.parse('$_baseUrl/details/json').replace(
        queryParameters: {
          'place_id': suggestion.placeId,
          'fields': 'geometry',
          'key': _apiKey,
          'sessiontoken': _sessionToken,
        },
      );

      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      // Después de Place Details, la sesión se consume → generar nueva
      _sessionToken = _uuid.v4();

      if (response.statusCode != 200) {
        debugPrint('Place Details error: ${response.statusCode}');
        return suggestion;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final result = json['result'] as Map<String, dynamic>?;

      if (result == null) return suggestion;

      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;

      if (location == null) return suggestion;

      return suggestion.copyWith(
        lat: (location['lat'] as num).toDouble(),
        lng: (location['lng'] as num).toDouble(),
      );
    } on TimeoutException {
      debugPrint('Place Details timeout');
      return suggestion;
    } catch (e) {
      debugPrint('Place Details error: $e');
      return suggestion;
    }
  }

  // ─── Session Management ───

  @override
  void startNewSession() {
    _sessionToken = _uuid.v4();
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}
