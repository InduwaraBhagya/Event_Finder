import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/screens/auth/login_screen.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/providers/event_provider.dart';
import 'package:event_finder/providers/location_provider.dart';
import 'package:event_finder/providers/booking_provider.dart';
import 'package:event_finder/providers/wishlist_provider.dart';
import 'package:event_finder/screens/splash_screen.dart';
import 'package:event_finder/screens/user/user_home_screen.dart';
import 'package:event_finder/screens/organizer/organizer_home_screen.dart';
import 'package:event_finder/screens/admin/admin_home_screen.dart';
import 'package:event_finder/screens/organizer/create_event_screen.dart';
//import 'package:event_finder/screens/organizer/manage_events_screen.dart';
import 'package:event_finder/screens/user/bookings_screen.dart';
import 'package:event_finder/screens/user/wishlist_screen.dart';
import 'package:event_finder/screens/user/event_list_screen.dart';
import 'package:event_finder/screens/user/near_me_screen.dart'; 
//import 'package:event_finder/screens/organizer/analytics_screen.dart';
import 'package:event_finder/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/user-home': (_) => const UserHomeScreen(),
          '/organizer-home': (_) => const OrganizerHomeScreen(),
          '/admin-home': (_) => const AdminHomeScreen(),
          '/create-event': (_) => const CreateEventScreen(),
          //'/manage-events': (_) => const ManageEventsScreen(),
          '/bookings': (_) => const MyBookingsScreen(),
          '/wishlist': (_) => const WishlistScreen(),
          '/events': (_) => const EventListScreen(),
          '/near-me': (_) => const NearMeScreen(), 
          //'/analytics': (_) => const AnalyticsScreen(),
        },
      ),
    );
  }
}