import 'dart:io';

import '../datasources/events_remote_datasource.dart';
import '../models/event_model.dart';

/// Repositorio de eventos — capa de abstracción sobre el datasource.
///
/// Centraliza el manejo de errores y facilita la inyección
/// de dependencias y testing.
class EventsRepository {
  final EventsRemoteDatasource _datasource;

  EventsRepository({EventsRemoteDatasource? datasource})
      : _datasource = datasource ?? EventsRemoteDatasource();

  // ─── Queries ────────────────────────────────────────────────────────────────

  /// Obtiene eventos filtrados por fecha, viewport y categoría.
  Future<List<Event>> getEvents({
    required DateTime date,
    Map<String, double>? bounds,
    String? categoryId,
    int limit = 100,
  }) {
    return _datasource.fetchEvents(
      date: date,
      bounds: bounds,
      categoryId: categoryId,
      limit: limit,
    );
  }

  /// Obtiene eventos del día (sin filtro de viewport).
  Future<List<Event>> getEventsForDay(DateTime date) {
    return _datasource.fetchEventsForDay(date);
  }

  /// Obtiene los eventos de un usuario.
  Future<List<Event>> getUserEvents(String userId) {
    return _datasource.fetchUserEvents(userId);
  }

  /// Obtiene un evento por ID.
  Future<Event?> getEventById(String eventId) {
    return _datasource.fetchEventById(eventId);
  }

  // ─── CRUD ───────────────────────────────────────────────────────────────────

  /// Crea un nuevo evento (opcionalmente con imagen de portada).
  Future<Event> createEvent(Event event, {File? coverImage}) {
    return _datasource.createEvent(event, coverImage: coverImage);
  }

  /// Actualiza un evento existente.
  Future<Event> updateEvent(Event event, {File? coverImage}) {
    return _datasource.updateEvent(event, coverImage: coverImage);
  }

  /// Publica un draft.
  Future<void> publishEvent(String eventId) {
    return _datasource.publishEvent(eventId);
  }

  /// Cancela un evento.
  Future<void> cancelEvent(String eventId) {
    return _datasource.cancelEvent(eventId);
  }

  /// Elimina un evento.
  Future<void> deleteEvent(String eventId) {
    return _datasource.deleteEvent(eventId);
  }

  // ─── RSVPs ──────────────────────────────────────────────────────────────────

  /// RSVP a un evento.
  Future<void> rsvpToEvent(String eventId) {
    return _datasource.rsvpToEvent(eventId);
  }

  /// Cancelar RSVP.
  Future<void> cancelRsvp(String eventId) {
    return _datasource.cancelRsvp(eventId);
  }

  /// Verificar si hay RSVP.
  Future<bool> hasRsvp(String eventId) {
    return _datasource.hasRsvp(eventId);
  }

  /// Obtener cantidad de RSVPs.
  Future<int> getRsvpCount(String eventId) {
    return _datasource.getRsvpCount(eventId);
  }
}
