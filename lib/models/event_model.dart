class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String time;
  final String location;
  final double latitude;
  final double longitude;
  final String organizerId;
  final String organizerName;
  final List<String> images;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final bool isFeatured;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  double? distance; // Distance from user's location (in km)

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.organizerId,
    required this.organizerName,
    required this.images,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    this.isFeatured = false,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    this.distance,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      organizerId: json['organizerId'] ?? json['organizer']?['_id'] ?? '',
      organizerName: json['organizerName'] ?? json['organizer']?['name'] ?? '',
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : [],
      price: (json['price'] ?? 0.0).toDouble(),
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['reviewCount'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'images': images,
      'price': price,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'distance': distance,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? date,
    String? time,
    String? location,
    double? latitude,
    double? longitude,
    String? organizerId,
    String? organizerName,
    List<String>? images,
    double? price,
    int? totalSeats,
    int? availableSeats,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    double? distance,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      images: images ?? this.images,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      distance: distance ?? this.distance,
    );
  }

  bool get isAvailable => availableSeats > 0;
  bool get isFree => price == 0;
  String get imageUrl => images.isNotEmpty ? images.first : '';
}