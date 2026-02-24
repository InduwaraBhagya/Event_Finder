class AppConfig {
  static const String appName = 'Event Finder';
  static const String appVersion = '1.0.0';

  //API Base URL 
  static const String baseUrl = 'https://evete-finder-backend.vercel.app/api';
  // For iOS Simulator: 'http://localhost:3000/api'
  // For Android Emulator: 'http://10.0.2.2:3000/api'

  static const String apiVersion = 'v1';

  // API Endpoints 
  static const String loginEndpoint             = '/auth/login';
  static const String registerEndpoint          = '/auth/register';
  static const String eventsEndpoint            = '/events';
  static const String featuredEventsEndpoint    = '/events/featured';
  static const String bookingsEndpoint          = '/bookings';
  static const String wishlistEndpoint          = '/wishlist';
  static const String usersEndpoint             = '/users';
  static const String organizerEventsEndpoint   = '/events';   
  static const String adminDashboardEndpoint    = '/admin/dashboard';

  // Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Pagination 
  static const int itemsPerPage = 10;

  //Distance filter options (km) 
  static const List<int> distanceOptions = [5, 10, 25, 50, 100];

  //  Event Categories 
  static const List<String> eventCategories = [
    'Technology',
    'Music',
    'Sports',
    'Arts',
    'Food & Drink',
    'Business',
    'Health',
    'Education',
    'Entertainment',
    'Other',
  ];

  // Date Formats 
  static const String dateFormat     = 'MMM dd, yyyy';
  static const String timeFormat     = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';

  // Storage Keys 
  static const String tokenKey   = 'auth_token';
  static const String userKey    = 'user_data';
  static const String userRoleKey = 'user_role';

  //  User Roles 
  static const String roleAdmin     = 'admin';
  static const String roleOrganizer = 'organizer';
  static const String roleUser      = 'user';
}