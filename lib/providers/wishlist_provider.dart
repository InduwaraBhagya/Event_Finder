// FILE: lib/providers/wishlist_provider.dart

import 'package:flutter/material.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';

class WishlistProvider with ChangeNotifier {
  // ✅ FIX: ApiClient uses instance methods, not static
  // Create one instance and reuse it for all calls
  final _api = ApiClient();

  List<Event>               _wishlistEvents  = [];
  final Map<String, String> _wishlistItemIds = {};  // eventId → wishlistItemId

  bool    _isLoading    = false;
  String? _errorMessage;

  List<Event> get wishlistEvents  => _wishlistEvents;
  bool        get isLoading       => _isLoading;
  String?     get errorMessage    => _errorMessage;

  bool isInWishlist(String eventId) =>
      _wishlistEvents.any((e) => e.id == eventId);

  // ══════════════════════════════════════════════════════
  // FETCH WISHLIST
  // Backend returns:
  //   { data: [ { _id: "wishlistItemId", event: { _id, title, ... } } ] }
  // ══════════════════════════════════════════════════════
  Future<void> fetchWishlist() async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get(               // ✅ instance call
        AppConfig.wishlistEndpoint,
        requiresAuth: true,
      );

      debugPrint('📥 WishlistProvider keys: ${response?.keys?.toList()}');

      if (response == null) {
        _wishlistEvents = [];
        return;
      }

      final List<dynamic>? items =
          response['data'] ?? response['wishlist'] ?? response['events'];

      if (items != null) {
        _wishlistEvents = [];
        _wishlistItemIds.clear();

        for (final item in items) {
          if (item == null) continue;

          final eventJson = item['event'] as Map<String, dynamic>?;
          if (eventJson == null) continue;

          try {
            final event = Event.fromJson(eventJson);
            _wishlistEvents.add(event);

            final wishlistItemId = item['_id']?.toString() ?? '';
            if (wishlistItemId.isNotEmpty) {
              _wishlistItemIds[event.id] = wishlistItemId;
            }
          } catch (e) {
            debugPrint('⚠️  Failed to parse wishlist event: $e');
          }
        }

        debugPrint('✅ Wishlist: ${_wishlistEvents.length} events loaded');
      } else {
        _wishlistEvents = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('❌ fetchWishlist: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════
  // ADD TO WISHLIST
  // ══════════════════════════════════════════════════════
  Future<bool> addToWishlist(Event event) async {
    // Optimistic add
    if (!isInWishlist(event.id)) {
      _wishlistEvents.insert(0, event);
      notifyListeners();
    }

    try {
      final response = await _api.post(              // ✅ instance call
        AppConfig.wishlistEndpoint,
        {'eventId': event.id},
        requiresAuth: true,
      );

      final newItemId = response?['data']?['_id']?.toString() ?? '';
      if (newItemId.isNotEmpty) {
        _wishlistItemIds[event.id] = newItemId;
      }

      debugPrint('✅ Added to wishlist: ${event.title} | itemId: $newItemId');
      return true;
    } catch (e) {
      // Rollback on error
      _wishlistEvents.removeWhere((ev) => ev.id == event.id);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint('❌ addToWishlist: $_errorMessage');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════
  // REMOVE FROM WISHLIST
  // ══════════════════════════════════════════════════════
  Future<bool> removeFromWishlist(String eventId) async {
    Event? removed;
    try {
      removed = _wishlistEvents.firstWhere((e) => e.id == eventId);
    } catch (_) {
      return false;
    }

    final wishlistItemId = _wishlistItemIds[eventId] ?? '';

    // Optimistic remove
    _wishlistEvents.removeWhere((e) => e.id == eventId);
    _wishlistItemIds.remove(eventId);
    notifyListeners();

    try {
      if (wishlistItemId.isNotEmpty) {
        await _api.delete(                           // ✅ instance call
          '${AppConfig.wishlistEndpoint}/$wishlistItemId',
          requiresAuth: true,
        );
      } else {
        await _api.delete(                           // ✅ instance call
          '${AppConfig.wishlistEndpoint}/$eventId',
          requiresAuth: true,
        );
      }

      debugPrint('✅ Removed from wishlist: $eventId');
      return true;
    } catch (e) {
      // Rollback on error
      _wishlistEvents.insert(0, removed!);
      _wishlistItemIds[eventId] = wishlistItemId;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint('❌ removeFromWishlist: $_errorMessage');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════
  // TOGGLE WISHLIST
  // ══════════════════════════════════════════════════════
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