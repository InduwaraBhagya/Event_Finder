import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/api_client.dart';

class EventService {
  final ApiClient _apiClient = ApiClient();

  // Get all events
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

      print('EventService: GET ${AppConfig.baseUrl}$endpoint');

      final response = await _apiClient.get(
        endpoint,
        requiresAuth: false, 
      );

      print('EventService raw response keys: ${response?.keys?.toList()}');

      if (response == null) return [];

      
      List<dynamic>? eventsList;

      if (response['data'] != null) {
        //Your current Vercel backend format
        eventsList = response['data'] as List;
        print('Found events in "data" key: ${eventsList.length}');
      } else if (response['events'] != null) {
        // Fallback: original backend format
        eventsList = response['events'] as List;
        print('Found events in "events" key: ${eventsList.length}');
      } else {
        print(' No events found in response. Keys: ${response.keys.toList()}');
        return [];
      }

      final events = eventsList.map((json) => Event.fromJson(json)).toList();
      print(' Parsed ${events.length} events successfully');
      return events;

    } catch (e) {
      print(' EventService.getEvents error: $e');
      throw Exception('Failed to fetch events: ${e.toString()}');
    }
  }

  //  Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final response = await _apiClient.get(
        AppConfig.featuredEventsEndpoint,
        requiresAuth: false,
      );

      if (response == null) return [];

      List<dynamic>? eventsList =
          response['data'] ?? response['events'];

      if (eventsList == null) return [];
      return eventsList.map((json) => Event.fromJson(json)).toList();

    } catch (e) {
      print(' EventService.getFeaturedEvents error: $e');
      throw Exception('Failed to fetch featured events: ${e.toString()}');
    }
  }

  //  Get single event by ID
  Future<Event> getEventById(String id) async {
    try {
      final response = await _apiClient.get(
        '${AppConfig.eventsEndpoint}/$id',
        requiresAuth: false,
      );

      if (response == null) throw Exception('No response');

      // Try both formats
      final eventData = response['data'] ?? response['event'];
      if (eventData == null) throw Exception('Event not found in response');

      return Event.fromJson(eventData);

    } catch (e) {
      print(' EventService.getEventById error: $e');
      throw Exception('Failed to fetch event: ${e.toString()}');
    }
  }

  //  Search events
  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await _apiClient.get(
        '${AppConfig.eventsEndpoint}/search?q=$query',
        requiresAuth: false,
      );

      if (response == null) return [];

      List<dynamic>? eventsList =
          response['data'] ?? response['events'];

      if (eventsList == null) return [];
      return eventsList.map((json) => Event.fromJson(json)).toList();

    } catch (e) {
      print(' EventService.searchEvents error: $e');
      throw Exception('Failed to search events: ${e.toString()}');
    }
  }

  // Create event 
  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await _apiClient.post(
        AppConfig.organizerEventsEndpoint,
        eventData,
        requiresAuth: true,
      );
      final data = response['data'] ?? response['event'];
      return Event.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  // Update event 
  Future<Event> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      final response = await _apiClient.put(
        '${AppConfig.organizerEventsEndpoint}/$id',
        eventData,
        requiresAuth: true,
      );
      final data = response['data'] ?? response['event'];
      return Event.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _apiClient.delete(
        '${AppConfig.organizerEventsEndpoint}/$id',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to delete event: ${e.toString()}');
    }
  }

  Future<List<Event>> getOrganizerEvents() async {
    try {
      final response = await _apiClient.get(
        AppConfig.organizerEventsEndpoint,
        requiresAuth: true,
      );

      if (response == null) return [];

      List<dynamic>? eventsList =
          response['data'] ?? response['events'];

      if (eventsList == null) return [];
      return eventsList.map((json) => Event.fromJson(json)).toList();

    } catch (e) {
      throw Exception('Failed to fetch organizer events: ${e.toString()}');
    }
  }
}