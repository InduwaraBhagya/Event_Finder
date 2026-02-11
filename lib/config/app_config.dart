class AppConfig {
  // App Info
  static const String appName = 'Event Finder';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  // For Android Emulator:
  static const String baseUrl = 'http://192.168.1.7:3000/api';
  
  // For iOS Simulator use:
  // static const String baseUrl = 'http://localhost:3000/api';
  
  // For Physical Device (replace with your computer's IP):
  // static const String baseUrl = 'http://YOUR_IP:3000/api';
  
  static const String apiVersion = 'v1';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String eventsEndpoint = '/events';
  static const String featuredEventsEndpoint = '/events/featured';
  static const String bookingsEndpoint = '/bookings';
  static const String wishlistEndpoint = '/wishlist';
  static const String usersEndpoint = '/users';
  static const String organizerEventsEndpoint = '/organizer/events';
  static const String adminDashboardEndpoint = '/admin/dashboard';
  
  // Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with your key
  
  // Pagination
  static const int itemsPerPage = 10;
  
  // Distance filter options (in kilometers)
  static const List<int> distanceOptions = [5, 10, 25, 50, 100];
  
  // Event Categories
  static const List<String> eventCategories = [
    'Music',
    'Sports',
    'Arts',
    'Technology',
    'Food & Drink',
    'Business',
    'Health',
    'Education',
    'Entertainment',
    'Other'
  ];
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String userRoleKey = 'user_role';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleOrganizer = 'organizer';
  static const String roleUser = 'user';
}