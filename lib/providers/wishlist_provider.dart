import 'package:flutter/material.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';

class WishlistProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Event> _wishlistEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get wishlistEvents => _wishlistEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  //  Check if event is in wishlist
  bool isInWishlist(String eventId) {
    return _wishlistEvents.any((event) => event.id == eventId);
  }

  //  Fetch wishlist - handles "wishlist" key from backend
  Future<void> fetchWishlist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        AppConfig.wishlistEndpoint,
        requiresAuth: true, 
      );

      print('📥 WishlistProvider: ${response?.keys?.toList()}');

      if (response == null) {
        _wishlistEvents = [];
        return;
      }

      //  Backend returns "wishlist" key (array of events)
      final List<dynamic>? list =
          response['wishlist'] ?? response['data'] ?? response['events'];

      if (list != null) {
        _wishlistEvents = list
            .where((item) => item != null)
            .map((json) => Event.fromJson(json as Map<String, dynamic>))
            .toList();
        print(' WishlistProvider: ${_wishlistEvents.length} events loaded');
      } else {
        _wishlistEvents = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print(' WishlistProvider fetchWishlist: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //  Add to wishlist with optimistic update
  Future<bool> addToWishlist(Event event) async {
    // Optimistic add
    if (!isInWishlist(event.id)) {
      _wishlistEvents.insert(0, event);
      notifyListeners();
    }

    try {
      await _apiClient.post(
        AppConfig.wishlistEndpoint,
        {'eventId': event.id},
        requiresAuth: true,
      );
      print(' WishlistProvider: Added ${event.title}');
      return true;
    } catch (e) {
      // Rollback optimistic add on error
      _wishlistEvents.removeWhere((e) => e.id == event.id);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      print(' WishlistProvider addToWishlist: $_errorMessage');
      return false;
    }
  }

  //  Remove from wishlist with optimistic update
  Future<bool> removeFromWishlist(String eventId) async {
    // Save for rollback
    final removed = _wishlistEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Not found'),
    );

    // Optimistic remove
    _wishlistEvents.removeWhere((e) => e.id == eventId);
    notifyListeners();

    try {
      await _apiClient.delete(
        '${AppConfig.wishlistEndpoint}/$eventId',
        requiresAuth: true,
      );
      print(' WishlistProvider: Removed $eventId');
      return true;
    } catch (e) {
      // Rollback on error
      _wishlistEvents.insert(0, removed);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      print(' WishlistProvider removeFromWishlist: $_errorMessage');
      return false;
    }
  }

  // Toggle wishlist (add or remove)
  Future<bool> toggleWishlist(Event event) async {
    if (isInWishlist(event.id)) {
      return removeFromWishlist(event.id);
    } else {
      return addToWishlist(event);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}