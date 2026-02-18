import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/utils/app_theme.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name ?? 'Explorer';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // 1. Colorful Animated AppBar Replacement
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, Colors.deepPurple.shade700],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative Circle 1
                    Positioned(
                      top: -20,
                      right: -20,
                      child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.1)),
                    ),
                    // Greeting Text
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName! 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'What are we doing today?',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  await authProvider.logout();
                },
              ),
            ],
          ),

          // 2. Main Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Actions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Vibrant Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildColorfulAction(
                      context,
                      icon: Icons.event_available_rounded,
                      label: 'Browse Events',
                      color: Colors.blue.shade400,
                      onTap: () => Navigator.pushNamed(context, '/events'),
                    ),
                    _buildColorfulAction(
                      context,
                      icon: Icons.favorite_rounded,
                      label: 'My Wishlist',
                      color: Colors.pink.shade400,
                      onTap: () => Navigator.pushNamed(context, '/wishlist'),
                    ),
                    _buildColorfulAction(
                      context,
                      icon: Icons.confirmation_number_rounded,
                      label: 'Bookings',
                      color: Colors.orange.shade400,
                      onTap: () => Navigator.pushNamed(context, '/bookings'),
                    ),
                    _buildColorfulAction(
                      context,
                      icon: Icons.map_rounded,
                      label: 'Near Me',
                      color: Colors.teal.shade400,
                      onTap: () => Navigator.pushNamed(context, '/events'),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 4. Featured Event Placeholder
                const Text(
                  'Featured for You',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(15),
                    alignment: Alignment.bottomLeft,
                    child: const Text(
                      'Summer Music Festival 2024\nDowntown Arena',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color, // This is a regular Color
    required VoidCallback onTap,
  }) {
    // This helper creates a darker version of the color for the text
    // to ensure it is readable against the light background.
    final Color darkerColor = HSLColor.fromColor(color)
        .withLightness(0.3) // Lowering lightness makes it darker (0.0 to 1.0)
        .toColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4), 
                    blurRadius: 8, 
                    offset: const Offset(0, 4)
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkerColor, // Use the darkened version here
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

}