import 'package:flutter/material.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/event_service.dart';

class LocationProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  
  List<Event> _events = [];
  List<Event> _featuredEvents = [];
  List<Event> _filteredEvents = [];
  Event? _selectedEvent;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  String? _selectedCategory;
  DateTime? _selectedDate;
  double? _selectedDistance;

  // Getters
  List<Event> get events => _filteredEvents.isNotEmpty ? _filteredEvents : _events;
  List<Event> get featuredEvents => _featuredEvents;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  DateTime? get selectedDate => _selectedDate;
  double? get selectedDistance => _selectedDistance;

  // Fetch all events
  Future<void> fetchEvents({
    String? category,
    DateTime? date,
    double? maxDistance,
    double? userLat,
    double? userLng,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.getEvents(
        category: category,
        date: date,
        maxDistance: maxDistance,
        userLat: userLat,
        userLng: userLng,
      );
      _filteredEvents = _events;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch featured events
  Future<void> fetchFeaturedEvents() async {
    try {
      _featuredEvents = await _eventService.getFeaturedEvents();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Search events
  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      _filteredEvents = _events;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredEvents = await _eventService.searchEvents(query);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get event by ID
  Future<void> fetchEventById(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedEvent = await _eventService.getEventById(id);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    if (category == null) {
      _filteredEvents = _events;
    } else {
      _filteredEvents = _events
          .where((event) => event.category == category)
          .toList();
    }
    notifyListeners();
  }

  // Filter by date
  void filterByDate(DateTime? date) {
    _selectedDate = date;
    if (date == null) {
      _filteredEvents = _events;
    } else {
      _filteredEvents = _events.where((event) {
        return event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day;
      }).toList();
    }
    notifyListeners();
  }

  // Filter by distance
  void filterByDistance(double? distance) {
    _selectedDistance = distance;
    if (distance == null) {
      _filteredEvents = _events;
    } else {
      _filteredEvents = _events
          .where((event) => event.distance != null && event.distance! <= distance)
          .toList();
      
      // Sort by distance
      _filteredEvents.sort((a, b) => 
        (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    }
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedDate = null;
    _selectedDistance = null;
    _filteredEvents = _events;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create event (for organizers)
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.createEvent(eventData);
      await fetchEvents(); // Refresh the list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update event (for organizers)
  Future<bool> updateEvent(String id, Map<String, dynamic> eventData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.updateEvent(id, eventData);
      await fetchEvents(); // Refresh the list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete event (for organizers)
  Future<bool> deleteEvent(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.deleteEvent(id);
      _events.removeWhere((event) => event.id == id);
      _filteredEvents.removeWhere((event) => event.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}