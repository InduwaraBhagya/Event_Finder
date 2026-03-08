import 'package:event_finder/models/event_model.dart';

class Booking {
  final String id;
  final String userId;
  final String eventId;
  final Event? event;
  final int numberOfSeats;
  final double totalPrice;
  final String status; 
  final DateTime bookingDate;
  final String? paymentId;
  final String? qrCode;

  Booking({
    required this.id,
    required this.userId,
    required this.eventId,
    this.event,
    required this.numberOfSeats,
    required this.totalPrice,
    required this.status,
    required this.bookingDate,
    this.paymentId,
    this.qrCode,
  });

  // helpers for numeric parsing (similar to Event)
  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      final t = val.trim();
      if (t.isEmpty) return fallback;
      return int.tryParse(t) ?? double.tryParse(t)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static double _parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      final t = val.trim();
      if (t.isEmpty) return fallback;
      return double.tryParse(t) ?? fallback;
    }
    return fallback;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    // event field can either be a full map or just an id string depending on
    // what the backend returns (booking creation often returns only the id).
    Event? evt;
    if (json['event'] is Map<String, dynamic>) {
      evt = Event.fromJson(json['event']);
    } else if (json['event'] is String) {
      // create a minimal placeholder using the ID only
      evt = Event.fromJson(json['event']);
    }

    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user']?['_id'] ?? '',
      // determine event id carefully – the API may supply either a separate
      // field, an object, or just the string id itself.
      eventId: json['eventId'] ??
          (json['event'] is Map ? json['event']['_id'] ?? '' :
           json['event'] is String ? json['event'] : ''),
      event: evt,
      numberOfSeats: _parseInt(json['numberOfSeats'], 1),
      totalPrice: _parseDouble(json['totalPrice'], 0.0),
      status: json['status'] ?? 'pending',
      bookingDate: json['bookingDate'] != null 
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      paymentId: json['paymentId'],
      qrCode: json['qrCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'numberOfSeats': numberOfSeats,
      'totalPrice': totalPrice,
      'status': status,
      'bookingDate': bookingDate.toIso8601String(),
      'paymentId': paymentId,
      'qrCode': qrCode,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? eventId,
    Event? event,
    int? numberOfSeats,
    double? totalPrice,
    String? status,
    DateTime? bookingDate,
    String? paymentId,
    String? qrCode,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      event: event ?? this.event,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      bookingDate: bookingDate ?? this.bookingDate,
      paymentId: paymentId ?? this.paymentId,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled =>
      status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'canceled';
}