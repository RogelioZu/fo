import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/event_model.dart';

/// Datasource remoto para operaciones CRUD de eventos contra Supabase.
class EventsRemoteDatasource {
  final SupabaseClient _client;

  EventsRemoteDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ─── Queries ────────────────────────────────────────────────────────────────

  /// Obtiene eventos publicados para una fecha y viewport específicos.
  ///
  /// [date] filtra al día seleccionado.
  /// [bounds] opcional: {south, north, west, east} para filtro por viewport.
  /// [categoryId] opcional: filtra por categoría.
  /// [limit] máximo de resultados (default 100).
  Future<List<Event>> fetchEvents({
    required DateTime date,
    Map<String, double>? bounds,
    String? categoryId,
    int limit = 100,
  }) async {
    try {
      // Inicio y fin del día seleccionado
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      var query = _client
          .from('events')
          .select()
          .eq('status', 'published')
          .eq('is_public', true)
          .gte('start_date', dayStart.toIso8601String())
          .lt('start_date', dayEnd.toIso8601String());

      // Filtro por viewport (bounding box del mapa)
      if (bounds != null) {
        query = query
            .gte('location_lat', bounds['south']!)
            .lte('location_lat', bounds['north']!)
            .gte('location_lng', bounds['west']!)
            .lte('location_lng', bounds['east']!);
      }

      // Filtro por categoría
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final data = await query
          .order('start_date', ascending: true)
          .limit(limit);

      return (data as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      rethrow;
    }
  }

  /// Obtiene todos los eventos del día (sin filtro de viewport).
  /// Útil para la pantalla de Home y Search.
  Future<List<Event>> fetchEventsForDay(DateTime date) async {
    return fetchEvents(date: date);
  }

  /// Obtiene los eventos creados por un usuario específico.
  Future<List<Event>> fetchUserEvents(String userId) async {
    try {
      final data = await _client
          .from('events')
          .select()
          .eq('creator_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching user events: $e');
      rethrow;
    }
  }

  /// Obtiene un evento por su ID.
  Future<Event?> fetchEventById(String eventId) async {
    try {
      final data = await _client
          .from('events')
          .select()
          .eq('id', eventId)
          .maybeSingle();

      if (data == null) return null;
      return Event.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching event by id: $e');
      rethrow;
    }
  }

  // ─── CRUD ───────────────────────────────────────────────────────────────────

  /// Crea un evento nuevo.
  ///
  /// Si [coverImage] no es null, sube la imagen a storage primero
  /// y guarda la URL pública en `image_url`.
  Future<Event> createEvent(Event event, {File? coverImage}) async {
    try {
      String? imageUrl;

      // Subir imagen de portada si existe
      if (coverImage != null) {
        imageUrl = await _uploadCoverImage(coverImage);
      }

      final eventData = event.copyWith(
        imageUrl: imageUrl ?? event.imageUrl,
      ).toJson();

      final response = await _client
          .from('events')
          .insert(eventData)
          .select()
          .single();

      return Event.fromJson(response);
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  /// Actualiza un evento existente.
  Future<Event> updateEvent(Event event, {File? coverImage}) async {
    try {
      String? imageUrl;

      if (coverImage != null) {
        imageUrl = await _uploadCoverImage(coverImage);
      }

      final eventData = event.copyWith(
        imageUrl: imageUrl ?? event.imageUrl,
      ).toJson();

      final response = await _client
          .from('events')
          .update(eventData)
          .eq('id', event.id!)
          .select()
          .single();

      return Event.fromJson(response);
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  /// Publica un draft (cambia status a 'published').
  Future<void> publishEvent(String eventId) async {
    try {
      await _client
          .from('events')
          .update({'status': 'published'})
          .eq('id', eventId);
    } catch (e) {
      debugPrint('Error publishing event: $e');
      rethrow;
    }
  }

  /// Cancela un evento (cambia status a 'cancelled').
  Future<void> cancelEvent(String eventId) async {
    try {
      await _client
          .from('events')
          .update({'status': 'cancelled'})
          .eq('id', eventId);
    } catch (e) {
      debugPrint('Error cancelling event: $e');
      rethrow;
    }
  }

  /// Elimina un evento y su imagen de portada.
  Future<void> deleteEvent(String eventId) async {
    try {
      // Primero obtener la info del evento para borrar la imagen
      final event = await fetchEventById(eventId);
      if (event?.imageUrl != null) {
        await _deleteCoverImage(event!.imageUrl!);
      }

      await _client.from('events').delete().eq('id', eventId);
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  // ─── RSVPs ──────────────────────────────────────────────────────────────────

  /// Confirma asistencia a un evento.
  Future<void> rsvpToEvent(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _client.from('event_rsvps').insert({
        'user_id': userId,
        'event_id': eventId,
      });
    } catch (e) {
      debugPrint('Error RSVPing to event: $e');
      rethrow;
    }
  }

  /// Cancela la asistencia a un evento.
  Future<void> cancelRsvp(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('event_rsvps')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
    } catch (e) {
      debugPrint('Error cancelling RSVP: $e');
      rethrow;
    }
  }

  /// Verifica si el usuario actual confirmó asistencia.
  Future<bool> hasRsvp(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = await _client
          .from('event_rsvps')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint('Error checking RSVP: $e');
      return false;
    }
  }

  /// Obtiene la cantidad de RSVPs de un evento.
  Future<int> getRsvpCount(String eventId) async {
    try {
      final data = await _client
          .from('event_rsvps')
          .select('id')
          .eq('event_id', eventId);

      return (data as List).length;
    } catch (e) {
      debugPrint('Error getting RSVP count: $e');
      return 0;
    }
  }

  // ─── Storage ────────────────────────────────────────────────────────────────

  /// Sube una imagen de portada al bucket 'event-covers'.
  /// Retorna la URL pública.
  Future<String> _uploadCoverImage(File image) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final fileExt = image.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final filePath = '$userId/$fileName';

    await _client.storage
        .from('event-covers')
        .upload(filePath, image);

    return _client.storage
        .from('event-covers')
        .getPublicUrl(filePath);
  }

  /// Elimina una imagen de portada del storage.
  Future<void> _deleteCoverImage(String imageUrl) async {
    try {
      // Extraer el path relativo de la URL pública
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // El path después de 'event-covers' es lo que necesitamos
      final bucketIndex = pathSegments.indexOf('event-covers');
      if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _client.storage.from('event-covers').remove([storagePath]);
      }
    } catch (e) {
      debugPrint('Error deleting cover image: $e');
      // No relanzar — no es crítico si no se borra la imagen
    }
  }
}
