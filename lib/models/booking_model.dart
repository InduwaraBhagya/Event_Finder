import 'package:event_finder/models/event_model.dart';

class Booking {
  final String id;
  final String userId;
  final String eventId;
  final Event? event;
  final int numberOfSeats;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'cancelled'
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

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user']?['_id'] ?? '',
      eventId: json['eventId'] ?? json['event']?['_id'] ?? '',
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      numberOfSeats: json['numberOfSeats'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
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
  bool get isCancelled => status == 'cancelled';
}