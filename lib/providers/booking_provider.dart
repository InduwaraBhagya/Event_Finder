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
  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        AppConfig.bookingsEndpoint,
        requiresAuth: true, 
      );

      print('📥 BookingProvider fetchBookings: ${response?.keys?.toList()}');

      if (response == null) {
        _bookings = [];
        return;
      }

      // Handle both "bookings" and "data" response keys
      List<dynamic>? list =
          response['bookings'] ?? response['data'];

      if (list != null) {
        _bookings = list
            .map((json) => Booking.fromJson(json))
            .toList();
        print(' BookingProvider: Loaded ${_bookings.length} bookings');
      } else {
        _bookings = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('❌ BookingProvider fetchBookings: $_errorMessage');
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

      // Try to reflect server's returned booking if available
      // some APIs return the updated object; if so, replace local entry.
      if (response is Map && response['booking'] != null) {
        final updated = Booking.fromJson(response['booking']);
        final idx = _bookings.indexWhere((b) => b.id == bookingId);
        if (idx != -1) {
          _bookings[idx] = updated;
        }
      } else {
        // Optimistically update local state - mark as cancelled (two spellings)
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = _bookings[index]
              .copyWith(status: 'cancelled');
        }
      }

      print(' BookingProvider: Booking $bookingId cancelled locally');

      // refresh from server to keep in sync, but do not block caller
      fetchBookings();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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