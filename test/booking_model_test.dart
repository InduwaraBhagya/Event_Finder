import 'package:flutter_test/flutter_test.dart';
import 'package:event_finder/models/booking_model.dart';
import 'package:event_finder/models/event_model.dart';

void main() {
  group('Booking.fromJson', () {
    test('parses when event field is a string id', () {
      final json = {
        '_id': 'b1',
        'userId': 'u1',
        'event': 'e123',
        'numberOfSeats': 2,
        'totalPrice': 100.0,
        'status': 'confirmed',
        'bookingDate': '2026-03-08T12:00:00Z',
      };

      final booking = Booking.fromJson(json);
      expect(booking.eventId, 'e123');
      expect(booking.event?.id, 'e123');
      expect(booking.numberOfSeats, 2);
    });

    test('parses when event field is a map with nested _id', () {
      final json = {
        '_id': 'b2',
        'userId': 'u2',
        'event': {'_id': 'e456', 'title': 'Test Event'},
        'numberOfSeats': '3',
        'totalPrice': '150',
      };

      final booking = Booking.fromJson(json);
      expect(booking.eventId, 'e456');
      expect(booking.event?.id, 'e456');
      expect(booking.numberOfSeats, 3);
      expect(booking.totalPrice, 150.0);
    });

    test('isCancelled handles both spellings', () {
      final b1 = Booking.fromJson({'status': 'cancelled'});
      final b2 = Booking.fromJson({'status': 'canceled'});
      expect(b1.isCancelled, isTrue);
      expect(b2.isCancelled, isTrue);
    });

    test('falls back gracefully when booking json is malformed', () {
      final json = {'random': 'value'};
      final booking = Booking.fromJson(json);
      expect(booking.id, '');
      expect(booking.eventId, '');
      expect(booking.numberOfSeats, 1);
      expect(booking.totalPrice, 0.0);
    });
  });

  group('Event.fromJson', () {
    test('handles a plain string id', () {
      final event = Event.fromJson('evt1');
      expect(event.id, 'evt1');
      expect(event.title, '');
    });

    test('ignores invalid input gracefully', () {
      final event = Event.fromJson(123);
      expect(event.id, '');
    });
  });
}
