import 'package:flutter/material.dart';
import 'package:event_finder/models/booking_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';

class BookingProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  //  Fetch user's bookings (requires auth token)
  /// Fetch user's bookings
  ///
  /// If [showError] is false the provider will still try to refresh the
  /// internal list but it will *not* replace the existing list or update
  /// `_errorMessage`.  This is useful when we trigger a background refresh
  /// after a mutation (cancel/create) and don't want a transient network
  /// hiccup to blow up the UI.
  Future<void> fetchBookings({bool showError = true}) async {
    _isLoading = true;
    if (showError) _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        AppConfig.bookingsEndpoint,
        requiresAuth: true,
      );

      print('📥 BookingProvider fetchBookings: ${response?.keys?.toList()}');

      if (response == null) {
        if (showError) _bookings = [];
        return;
      }

      // Handle both "bookings" and "data" response keys
      List<dynamic>? list = response['bookings'] ?? response['data'];

      if (list != null) {
        final newList =
            list.map((json) => Booking.fromJson(json)).toList();
        // always update list and clear any stale error message, even when
        // running a background refresh (showError == false).  failing to
        // clear leaves the previous error text stuck in the UI.
        _bookings = newList;
        _errorMessage = null;
        print(' BookingProvider: Loaded ${_bookings.length} bookings');
      } else if (showError) {
        _bookings = [];
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      print('❌ BookingProvider fetchBookings: $msg');
      if (showError) {
        _errorMessage = msg;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a booking
  Future<bool> createBooking(String eventId, int numberOfSeats) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print(' BookingProvider: Creating booking for event $eventId, seats=$numberOfSeats');

      final response = await _apiClient.post(
        AppConfig.bookingsEndpoint,
        {
          'eventId': eventId,
          'numberOfSeats': numberOfSeats,
        },
        requiresAuth: true, //  requires login
      );

      print('📥 BookingProvider createBooking response: ${response?.keys?.toList()}');

      if (response == null) return false;

      // Handle both "booking" and "data" response keys
      final bookingData = response['booking'] ?? response['data'];

      if (bookingData != null) {
        final newBooking = Booking.fromJson(bookingData);
        _bookings.insert(0, newBooking); // Add to top of list
        print(' BookingProvider: Booking created! ID=${newBooking.id}');
        return true;
      }

      // If success field is present and true
      if (response['success'] == true) {
        await fetchBookings(); // Refresh to get latest
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print(' BookingProvider createBooking: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //  Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.delete(
        '${AppConfig.bookingsEndpoint}/$bookingId',
        requiresAuth: true,
      );

      // basic validation – some backends just return { success: true }
      bool success = false;
      if (response is Map) {
        if (response['success'] == true) success = true;
        if (response['booking'] != null) success = true;
      }

      if (!success) {
        _errorMessage = (response is Map)
            ? (response['message'] ?? 'Failed to cancel booking')
            : 'Unknown error';
        return false;
      }

      // reflect server's returned booking if provided (preferred)
      if (response is Map && response['booking'] != null) {
        final updated = Booking.fromJson(response['booking']);
        final idx = _bookings.indexWhere((b) => b.id == bookingId);
        if (idx != -1) {
          _bookings[idx] = updated;
        }
      } else {
        // optimistic fallback – mark cancelled locally
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = _bookings[index].copyWith(status: 'cancelled');
        }
      }

      print(' BookingProvider: Booking $bookingId cancelled locally');

      // kick off a background refresh so we stay in sync.  we suppress any
      // error message so the UI doesn't switch to the error state if the
      // network is flaky or the endpoint returns 404 as shown by the user.
      fetchBookings(showError: false);

      return true;
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      // treat 404 as a non‑fatal case – maybe the booking was already gone on
      // server side.  Still update local state so UI feels responsive.
      if (msg.contains('404')) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = _bookings[index].copyWith(status: 'cancelled');
        }
        fetchBookings(showError: false);
        print(' BookingProvider cancelBooking: received 404, marking locally cancelled');
        return true;
      }

      _errorMessage = msg;
      print(' BookingProvider cancelBooking: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}