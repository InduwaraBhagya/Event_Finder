
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
  double? distance;

  final String status;
  final String adminNote;

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
    this.isFeatured  = false,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    this.distance,
    this.status    = 'pending',
    this.adminNote = '',
  });

  // ── Normalize category names (unchanged) ─────────────────
  static String _normalizeCategory(String? raw) {
    if (raw == null || raw.isEmpty) return 'Other';
    switch (raw.toLowerCase().trim()) {
      case 'art':
      case 'arts':
      case 'arts & culture':
        return 'Arts';
      case 'food':
      case 'food & drink':
      case 'food and drink':
      case 'food & wine':
        return 'Food & Drink';
      case 'tech':
      case 'technology':
        return 'Technology';
      case 'music':
        return 'Music';
      case 'sport':
      case 'sports':
        return 'Sports';
      case 'business':
      case 'networking':
        return 'Business';
      case 'health':
      case 'wellness':
      case 'health & wellness':
        return 'Health';
      case 'education':
      case 'educational':
        return 'Education';
      case 'entertainment':
        return 'Entertainment';
      default:
        return raw;
    }
  }

 
  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null)   return fallback;
    if (val is int)    return val;
    if (val is double) return val.toInt();
    if (val is String) {
      final t = val.trim();
      if (t.isEmpty) return fallback;
      return int.tryParse(t) ?? double.tryParse(t)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static double _parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null)   return fallback;
    if (val is double) return val;
    if (val is int)    return val.toDouble();
    if (val is String) {
      final t = val.trim();
      if (t.isEmpty) return fallback;
      return double.tryParse(t) ?? fallback;
    }
    return fallback;
  }

  static bool _parseBool(dynamic val, [bool fallback = false]) {
    if (val == null)  return fallback;
    if (val is bool)  return val;
    if (val is int)   return val != 0;
    if (val is String) {
      return val.toLowerCase() == 'true' || val == '1';
    }
    return fallback;
  }


  // Accepts a dynamic input so callers can pass a map or even a plain id string
  factory Event.fromJson(dynamic json) {
    // If the caller just provided an ID (e.g. booking response returned
    // `event: "abcd1234"`), treat it as a minimal event object instead
    if (json is String) {
      return Event(
        id: json,
        title: '',
        description: '',
        category: 'Other',
        date: DateTime.now(),
        time: '',
        location: '',
        latitude: 0.0,
        longitude: 0.0,
        organizerId: '',
        organizerName: '',
        images: [],
        price: 0.0,
        totalSeats: 0,
        availableSeats: 0,
        createdAt: DateTime.now(),
      );
    }

    if (json is! Map<String, dynamic>) {
      // unexpected type, return a blank event to avoid crashes
      return Event(
        id: '',
        title: '',
        description: '',
        category: 'Other',
        date: DateTime.now(),
        time: '',
        location: '',
        latitude: 0.0,
        longitude: 0.0,
        organizerId: '',
        organizerName: '',
        images: [],
        price: 0.0,
        totalSeats: 0,
        availableSeats: 0,
        createdAt: DateTime.now(),
      );
    }

    final Map<String, dynamic> map = json;

    // Handle organizer as object or string (unchanged)
    String orgId   = '';
    String orgName = '';

    if (map['organizer'] is Map) {
      orgId   = map['organizer']['_id'] ?? map['organizer']['id'] ?? '';
      orgName = map['organizer']['name'] ?? '';
    } else if (map['organizer'] is String) {
      orgId = map['organizer'];
    }

    if (orgId.isEmpty)   orgId   = map['organizerId']   ?? '';
    if (orgName.isEmpty) orgName = map['organizerName'] ?? 'Unknown Organizer';

    return Event(
      id:          map['_id'] ?? map['id'] ?? '',
      title:       map['title']       ?? '',
      description: map['description'] ?? '',
      category:    _normalizeCategory(map['category']),

      date: map['date'] != null
          ? DateTime.tryParse(map['date']) ?? DateTime.now()
          : DateTime.now(),

      time:     map['time']     ?? '',
      location: map['location'] ?? '',

      // FIX: was (map['latitude'] ?? 0.0).toDouble() → crashes if String
      latitude:  _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),

      organizerId:   orgId,
      organizerName: orgName,

      // Handle images array safely (unchanged)
      images: map['images'] != null
          ? List<String>.from(
              (map['images'] as List)
                  .where((img) => img != null && img.toString().isNotEmpty))
          : [],

      price: _parseDouble(map['price']),

      totalSeats:     _parseInt(map['totalSeats']),
      availableSeats: _parseInt(map['availableSeats']),

      isFeatured: _parseBool(map['isFeatured']),

      rating: map['rating'] != null
          ? (map['rating'] as num).toDouble()
          : null,

      reviewCount: map['reviewCount'] != null
          ? _parseInt(map['reviewCount'])
          : null,

      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),

      distance: map['distance'] != null
          ? _parseDouble(map['distance'])
          : null,

      // Approval fields (unchanged)
      status:    map['status']    ?? 'pending',
      adminNote: map['adminNote'] ?? '',
    );
  }

  // ── toJson (unchanged) ────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id':             id,
      'title':          title,
      'description':    description,
      'category':       category,
      'date':           date.toIso8601String(),
      'time':           time,
      'location':       location,
      'latitude':       latitude,
      'longitude':      longitude,
      'organizerId':    organizerId,
      'organizerName':  organizerName,
      'images':         images,
      'price':          price,
      'totalSeats':     totalSeats,
      'availableSeats': availableSeats,
      'isFeatured':     isFeatured,
      'rating':         rating,
      'reviewCount':    reviewCount,
      'createdAt':      createdAt.toIso8601String(),
      'distance':       distance,
      'status':         status,
      'adminNote':      adminNote,
    };
  }

  // ── copyWith (unchanged) ──────────────────────────────────
  Event copyWith({
    String? id,           String? title,        String? description,
    String? category,     DateTime? date,       String? time,
    String? location,     double? latitude,     double? longitude,
    String? organizerId,  String? organizerName,
    List<String>? images, double? price,
    int? totalSeats,      int? availableSeats,  bool? isFeatured,
    double? rating,       int? reviewCount,     DateTime? createdAt,
    double? distance,
    String? status,       String? adminNote,
  }) {
    return Event(
      id:             id             ?? this.id,
      title:          title          ?? this.title,
      description:    description    ?? this.description,
      category:       category       ?? this.category,
      date:           date           ?? this.date,
      time:           time           ?? this.time,
      location:       location       ?? this.location,
      latitude:       latitude       ?? this.latitude,
      longitude:      longitude      ?? this.longitude,
      organizerId:    organizerId    ?? this.organizerId,
      organizerName:  organizerName  ?? this.organizerName,
      images:         images         ?? this.images,
      price:          price          ?? this.price,
      totalSeats:     totalSeats     ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      isFeatured:     isFeatured     ?? this.isFeatured,
      rating:         rating         ?? this.rating,
      reviewCount:    reviewCount    ?? this.reviewCount,
      createdAt:      createdAt      ?? this.createdAt,
      distance:       distance       ?? this.distance,
      status:         status         ?? this.status,
      adminNote:      adminNote      ?? this.adminNote,
    );
  }

  // ── Getters (unchanged) ───────────────────────────────────
  bool get isAvailable => availableSeats > 0;
  bool get isFree      => price == 0;

  /// First image from the images array (Cloudinary URL or empty string)
  String get imageUrl => images.isNotEmpty ? images.first : '';

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}