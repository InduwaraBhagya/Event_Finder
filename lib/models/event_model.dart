// FILE: lib/models/event_model.dart
// FIX: "type 'String' is not a subtype of type 'int' of 'index'"
// ─────────────────────────────────────────────────────────────
// WHAT CHANGED  (everything else is 100% identical to your original):
//   + Added _parseInt()   static helper  (lines ~90-103)
//   + Added _parseDouble() static helper (lines ~105-116)
//   + Added _parseBool()   static helper (lines ~118-126)
//   + fromJson: latitude/longitude  now use _parseDouble()
//   + fromJson: price               now uses  _parseDouble()
//   + fromJson: totalSeats          now uses  _parseInt()   ← main crash fix
//   + fromJson: availableSeats      now uses  _parseInt()   ← main crash fix
//   + fromJson: isFeatured          now uses  _parseBool()
//   + fromJson: reviewCount         now uses  _parseInt()
//   + fromJson: distance            now uses  _parseDouble()

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

  // ════════════════════════════════════════════════════════
  // NEW: Safe type-conversion helpers
  // MongoDB / REST APIs sometimes send numbers as Strings,
  // e.g.  totalSeats: "400"  instead of  totalSeats: 400
  // Direct cast like  json['totalSeats'] ?? 0  then crashes
  // with: type 'String' is not a subtype of type 'int'
  // ════════════════════════════════════════════════════════

  /// Any → int  (null / String / double / int all handled safely)
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

  /// Any → double  (null / String / int / double all handled safely)
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

  /// Any → bool  (null / "true" / "false" / 0 / 1 all handled safely)
  static bool _parseBool(dynamic val, [bool fallback = false]) {
    if (val == null)  return fallback;
    if (val is bool)  return val;
    if (val is int)   return val != 0;
    if (val is String) {
      return val.toLowerCase() == 'true' || val == '1';
    }
    return fallback;
  }

  // ════════════════════════════════════════════════════════
  // fromJson  — numeric fields now use safe parsers
  // ════════════════════════════════════════════════════════
  factory Event.fromJson(Map<String, dynamic> json) {
    // Handle organizer as object or string (unchanged)
    String orgId   = '';
    String orgName = '';

    if (json['organizer'] is Map) {
      orgId   = json['organizer']['_id'] ?? json['organizer']['id'] ?? '';
      orgName = json['organizer']['name'] ?? '';
    } else if (json['organizer'] is String) {
      orgId = json['organizer'];
    }

    if (orgId.isEmpty)   orgId   = json['organizerId']   ?? '';
    if (orgName.isEmpty) orgName = json['organizerName'] ?? 'Unknown Organizer';

    return Event(
      id:          json['_id'] ?? json['id'] ?? '',
      title:       json['title']       ?? '',
      description: json['description'] ?? '',
      category:    _normalizeCategory(json['category']),

      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),

      time:     json['time']     ?? '',
      location: json['location'] ?? '',

      // FIX: was (json['latitude'] ?? 0.0).toDouble() → crashes if String
      latitude:  _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),

      organizerId:   orgId,
      organizerName: orgName,

      // Handle images array safely (unchanged)
      images: json['images'] != null
          ? List<String>.from(
              (json['images'] as List)
                  .where((img) => img != null && img.toString().isNotEmpty))
          : [],

      // FIX: was (json['price'] ?? 0.0).toDouble() → crashes if String
      price: _parseDouble(json['price']),

      // ✅ MAIN FIX — these caused your crash:
      // was: json['totalSeats'] ?? 0  → crashes when API returns "400"
      totalSeats:     _parseInt(json['totalSeats']),
      availableSeats: _parseInt(json['availableSeats']),

      // FIX: was json['isFeatured'] ?? false → crashes if String "true"
      isFeatured: _parseBool(json['isFeatured']),

      // rating unchanged — (json['rating'] as num) handles int & double
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,

      // FIX: was json['reviewCount'] directly → crashes if String "5"
      reviewCount: json['reviewCount'] != null
          ? _parseInt(json['reviewCount'])
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),

      // FIX: was (json['distance'] as num).toDouble() → crashes if String
      distance: json['distance'] != null
          ? _parseDouble(json['distance'])
          : null,

      // Approval fields (unchanged)
      status:    json['status']    ?? 'pending',
      adminNote: json['adminNote'] ?? '',
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