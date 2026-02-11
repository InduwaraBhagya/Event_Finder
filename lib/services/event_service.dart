import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/api_client.dart';

class EventService {
  final ApiClient _apiClient = ApiClient();

  // Get all events with optional filters
  Future<List<Event>> getEvents({
    String? category,
    DateTime? date,
    double? maxDistance,
    double? userLat,
    double? userLng,
  }) async {
    try {
      String endpoint = AppConfig.eventsEndpoint;
      List<String> queryParams = [];

      if (category != null) queryParams.add('category=$category');
      if (date != null) queryParams.add('date=${date.toIso8601String()}');
      if (maxDistance != null) queryParams.add('maxDistance=$maxDistance');
      if (userLat != null) queryParams.add('userLat=$userLat');
      if (userLng != null) queryParams.add('userLng=$userLng');

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await _apiClient.get(endpoint);
      
      if (response['events'] != null) {
        return (response['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch events: ${e.toString()}');
    }
  }

  // Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final response = await _apiClient.get(AppConfig.featuredEventsEndpoint);
      
      if (response['events'] != null) {
        return (response['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch featured events: ${e.toString()}');
    }
  }

  // Get event by ID
  Future<Event> getEventById(String id) async {
    try {
      final response = await _apiClient.get('${AppConfig.eventsEndpoint}/$id');
      return Event.fromJson(response['event']);
    } catch (e) {
      throw Exception('Failed to fetch event: ${e.toString()}');
    }
  }

  // Search events
  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await _apiClient.get(
        '${AppConfig.eventsEndpoint}/search?q=$query',
      );
      
      if (response['events'] != null) {
        return (response['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search events: ${e.toString()}');
    }
  }

  // Create event (for organizers)
  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _apiClient.post(
        AppConfig.organizerEventsEndpoint,
        eventData,
      );
      return Event.fromJson(response['event']);
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  // Update event (for organizers)
  Future<Event> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      final response = await _apiClient.put(
        '${AppConfig.organizerEventsEndpoint}/$id',
        eventData,
      );
      return Event.fromJson(response['event']);
    } catch (e) {
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  // Delete event (for organizers)
  Future<void> deleteEvent(String id) async {
    try {
      await _apiClient.delete('${AppConfig.organizerEventsEndpoint}/$id');
    } catch (e) {
      throw Exception('Failed to delete event: ${e.toString()}');
    }
  }

  // Get organizer's events
  Future<List<Event>> getOrganizerEvents() async {
    try {
      final response = await _apiClient.get(AppConfig.organizerEventsEndpoint);
      
      if (response['events'] != null) {
        return (response['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch organizer events: ${e.toString()}');
    }
  }
}