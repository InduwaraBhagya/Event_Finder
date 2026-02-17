import 'package:flutter/material.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();

  List<Event> _events = [];
  List<Event> _featuredEvents = [];
  List<Event> _filteredEvents = [];
  Event? _selectedEvent;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isFiltered = false; // ✅ Track if filter is active

  String? _selectedCategory;
  DateTime? _selectedDate;
  double? _selectedDistance;

  // ✅ FIXED getter - use _isFiltered flag instead of isEmpty check
  List<Event> get events => _isFiltered ? _filteredEvents : _events;
  List<Event> get featuredEvents => _featuredEvents;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  DateTime? get selectedDate => _selectedDate;
  double? get selectedDistance => _selectedDistance;

  // ✅ Fetch all events
  Future<void> fetchEvents({
    String? category,
    DateTime? date,
    double? maxDistance,
    double? userLat,
    double? userLng,
  }) async {
    print('🔄 EventProvider: fetchEvents called');
    _isLoading = true;
    _errorMessage = null;
    _isFiltered = false; // Reset filter
    notifyListeners();

    try {
      print('📡 EventProvider: Calling EventService.getEvents()');
      _events = await _eventService.getEvents(
        category: category,
        date: date,
        maxDistance: maxDistance,
        userLat: userLat,
        userLng: userLng,
      );
      print('✅ EventProvider: Got ${_events.length} events');
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('❌ EventProvider: Error = $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏁 EventProvider: Done. events=${_events.length}, error=$_errorMessage');
    }
  }

  // ✅ Fetch featured events
  Future<void> fetchFeaturedEvents() async {
    try {
      _featuredEvents = await _eventService.getFeaturedEvents();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // ✅ Search events
  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      clearFilters();
      return;
    }

    _isLoading = true;
    _isFiltered = true;
    notifyListeners();

    try {
      _filteredEvents = await _eventService.searchEvents(query);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _filteredEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Get event by ID
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

  // ✅ Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    if (category == null) {
      _isFiltered = false;
      _filteredEvents = [];
    } else {
      _isFiltered = true;
      _filteredEvents = _events
          .where((event) => event.category == category)
          .toList();
    }
    notifyListeners();
  }

  // ✅ Filter by date
  void filterByDate(DateTime? date) {
    _selectedDate = date;
    if (date == null) {
      _isFiltered = false;
      _filteredEvents = [];
    } else {
      _isFiltered = true;
      _filteredEvents = _events.where((event) {
        return event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day;
      }).toList();
    }
    notifyListeners();
  }

  // ✅ Filter by distance
  void filterByDistance(double? distance) {
    _selectedDistance = distance;
    if (distance == null) {
      _isFiltered = false;
      _filteredEvents = [];
    } else {
      _isFiltered = true;
      _filteredEvents = _events
          .where((event) =>
              event.distance != null && event.distance! <= distance)
          .toList();
      _filteredEvents.sort((a, b) =>
          (a.distance ?? double.infinity)
              .compareTo(b.distance ?? double.infinity));
    }
    notifyListeners();
  }

  // ✅ Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedDate = null;
    _selectedDistance = null;
    _isFiltered = false;
    _filteredEvents = [];
    notifyListeners();
  }

  // ✅ Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ Create event (organizer)
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.createEvent(eventData);
      await fetchEvents();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Update event (organizer)
  Future<bool> updateEvent(String id, Map<String, dynamic> eventData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.updateEvent(id, eventData);
      await fetchEvents();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Delete event (organizer)
  Future<bool> deleteEvent(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.deleteEvent(id);
      _events.removeWhere((event) => event.id == id);
      _filteredEvents.removeWhere((event) => event.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}