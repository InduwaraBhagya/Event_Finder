import 'package:flutter/material.dart';
import 'package:event_finder/models/booking_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';

class WishlistProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch user's bookings
  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(AppConfig.bookingsEndpoint);
      
      if (response['bookings'] != null) {
        _bookings = (response['bookings'] as List)
            .map((json) => Booking.fromJson(json))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create booking
  Future<bool> createBooking(String eventId, int numberOfSeats) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        AppConfig.bookingsEndpoint,
        {
          'eventId': eventId,
          'numberOfSeats': numberOfSeats,
        },
      );

      if (response['booking'] != null) {
        final booking = Booking.fromJson(response['booking']);
        _bookings.add(booking);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.delete('${AppConfig.bookingsEndpoint}/$bookingId');
      _bookings.removeWhere((booking) => booking.id == bookingId);
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

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}