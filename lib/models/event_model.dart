
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

  // Normalize category names from database to match UI filter chips
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

  factory Event.fromJson(Map<String, dynamic> json) {
    //  Handle organizer as object or string
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
      time:         json['time']     ?? '',
      location:     json['location'] ?? '',
      latitude:     (json['latitude']  ?? 0.0).toDouble(),
      longitude:    (json['longitude'] ?? 0.0).toDouble(),
      organizerId:  orgId,
      organizerName: orgName,
      //  Handle images array safely
      images: json['images'] != null
          ? List<String>.from(
              (json['images'] as List)
                  .where((img) => img != null && img.toString().isNotEmpty))
          : [],
      price:          (json['price']          ?? 0.0).toDouble(),
      totalSeats:      json['totalSeats']     ?? 0,
      availableSeats:  json['availableSeats'] ?? 0,
      isFeatured:      json['isFeatured']     ?? false,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      reviewCount: json['reviewCount'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      //  NEW: parse approval fields
      status:    json['status']    ?? 'pending',
      adminNote: json['adminNote'] ?? '',
    );
  }

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

  Event copyWith({
    String? id,          String? title,       String? description,
    String? category,    DateTime? date,      String? time,
    String? location,    double? latitude,    double? longitude,
    String? organizerId, String? organizerName,
    List<String>? images, double? price,
    int? totalSeats,     int? availableSeats, bool? isFeatured,
    double? rating,      int? reviewCount,    DateTime? createdAt,
    double? distance,
    String? status,      String? adminNote,
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

  //Getters 
  bool get isAvailable => availableSeats > 0;
  bool get isFree      => price == 0;

  /// First image from the images array (Cloudinary URL or empty string)
  String get imageUrl  => images.isNotEmpty ? images.first : '';

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}