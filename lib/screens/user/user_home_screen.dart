import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/providers/event_provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Logout — clears stack and goes to /login ──────────
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false, 
      );
    }
  }

  // ── Confirmation dialog before logout ─────────────────
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Logout'),
        ]),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);   
              _logout();            
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Logout'),
          ),
        ],
      ),
    );
  }

  // ── Category image map ────────────────────────────────
  static const Map<String, String> _categoryImages = {
    'Technology':    'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=600&q=80',
    'Music':         'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=600&q=80',
    'Sports':        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=600&q=80',
    'Arts':          'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=600&q=80',
    'Food & Drink':  'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80',
    'Business':      'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&q=80',
    'Health':        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80',
    'Education':     'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=600&q=80',
    'Entertainment': 'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=600&q=80',
    'Other':         'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=600&q=80',
  };

  // ── Best image for event (3-level fallback) ───────────
  String _getEventImage(Event event) {
    if (event.images.isNotEmpty) {
      final img = event.images.first;
      if (img.isNotEmpty && img.startsWith('http') &&
          !img.contains('placeholder')) return img;
    }
    if (event.imageUrl.isNotEmpty && event.imageUrl.startsWith('http') &&
        !event.imageUrl.contains('placeholder')) return event.imageUrl;
    return _categoryImages[event.category] ?? _categoryImages['Other']!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.user == null && !authProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', (route) => false);
          });
        }

        final userName = authProvider.user?.name ?? 'Explorer';

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          body: CustomScrollView(
            slivers: [

              // ── Header ───────────────────────────────
              SliverAppBar(
                expandedHeight: 230.0,
                floating: false,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          Colors.deepPurple.shade800,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30, right: -30,
                          child: CircleAvatar(
                            radius: 90,
                            backgroundColor: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        Positioned(
                          bottom: -20, left: -20,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.07),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Discover amazing events near you',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(children: [
                                  const SizedBox(width: 14),
                                  Icon(Icons.search,
                                      color: Colors.grey.shade400, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      onChanged: (v) => setState(
                                          () => _searchQuery = v.toLowerCase()),
                                      decoration: InputDecoration(
                                        hintText: 'Search events...',
                                        hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                      ),
                                    ),
                                  ),
                               
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: Icon(Icons.close,
                                            color: Colors.grey.shade400,
                                            size: 18),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 14),
                                ]),
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
                    tooltip: 'Logout',
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),

              // ── Body ─────────────────────────────────
              Consumer<EventProvider>(
                builder: (ctx, eventProvider, _) {
                  final allEvents = eventProvider.events;

                  // Filter by search query
                  final filteredEvents = _searchQuery.isEmpty
                      ? allEvents
                      : allEvents.where((e) {
                          return e.title
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              e.category
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              e.location
                                  .toLowerCase()
                                  .contains(_searchQuery);
                        }).toList();

                  final featuredEvents =
                      allEvents.where((e) => e.isFeatured).toList();

                  // ── Search results ──────────────────
                  if (_searchQuery.isNotEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(children: [
                            Icon(Icons.search,
                                size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              '${filteredEvents.length} result(s) for "$_searchQuery"',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          if (filteredEvents.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(children: [
                                  Icon(Icons.search_off,
                                      size: 56,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No events found for "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Colors.grey.shade500),
                                  ),
                                ]),
                              ),
                            )
                          else
                            ...filteredEvents
                                .map((e) => _upcomingEventCard(e, context)),
                          const SizedBox(height: 30),
                        ]),
                      ),
                    );
                  }

                  // ── Normal home ─────────────────────
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // Explore grid
                        const Text('Explore',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          childAspectRatio: 1.2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                          
                            _actionCard(
                              icon: Icons.event_available_rounded,
                              label: 'Browse Events',
                              color: Colors.blue.shade400,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/events'),
                            ),
                            _actionCard(
                              icon: Icons.favorite_rounded,
                              label: 'My Wishlist',
                              color: Colors.pink.shade400,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/wishlist'),
                            ),
                            _actionCard(
                              icon: Icons.confirmation_number_rounded,
                              label: 'My Bookings',
                              color: Colors.orange.shade400,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/bookings'),
                            ),
                            _actionCard(
                              icon: Icons.map_rounded,
                              label: 'Near Me',
                              color: Colors.teal.shade400,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/near-me'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Featured Events
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Featured Events',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/events'),
                              child: Text('See All',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (eventProvider.isLoading)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ))
                        else if (featuredEvents.isEmpty)
                          _featuredFallback(context)
                        else
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: featuredEvents.length,
                              itemBuilder: (_, i) =>
                                  _featuredCard(featuredEvents[i], context),
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Upcoming Events
                        const Text('Upcoming Events',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        if (!eventProvider.isLoading && allEvents.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(children: [
                                Icon(Icons.event_busy,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text('No events yet',
                                    style: TextStyle(
                                        color: Colors.grey.shade500)),
                              ]),
                            ),
                          )
                        else
                          ...allEvents
                              .take(5)
                              .map((e) => _upcomingEventCard(e, context)),

                        const SizedBox(height: 30),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Action card ───────────────────────────────────────
  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final darker = HSLColor.fromColor(color).withLightness(0.3).toColor();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darker,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Featured card ─────────────────────────────────────
  Widget _featuredCard(Event event, BuildContext context) {
    final imageUrl = _getEventImage(event);

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/event-detail', arguments: event),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Image with 3-level fallback
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (ctx, error, stack) {
                    final fallback = _categoryImages[event.category] ??
                        _categoryImages['Other']!;
                    if (imageUrl != fallback) {
                      return Image.network(fallback,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                color:
                                    AppTheme.primaryColor.withOpacity(0.15),
                                child: Icon(Icons.event,
                                    size: 48,
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.4)),
                              ));
                    }
                    return Container(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      child: Icon(Icons.event,
                          size: 48,
                          color: AppTheme.primaryColor.withOpacity(0.4)),
                    );
                  },
                ),
              ),

              // Gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
              ),

              // Info
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(event.category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 5),
                    Text(event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white70, size: 10),
                      const SizedBox(width: 4),
                      Text(DateFormat('MMM dd, yyyy').format(event.date),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ]),
                  ],
                ),
              ),

              // Star badge
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withOpacity(0.4), blurRadius: 6)
                    ],
                  ),
                  child:
                      const Icon(Icons.star, color: Colors.white, size: 12),
                ),
              ),

              // Price badge
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isFree
                        ? Colors.green.shade600
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.isFree
                        ? 'FREE'
                        : 'Rs.${event.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Featured fallback ─────────────────────────────────
  Widget _featuredFallback(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/events'),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: NetworkImage(
                'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800'),
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
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: const Text(
            'Discover Amazing Events\nTap to explore →',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
      ),
    );
  }

  // ── Upcoming event card ───────────────────────────────
  Widget _upcomingEventCard(Event event, BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/event-detail', arguments: event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // Date box
          Container(
            width: 52, height: 62,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('dd').format(event.date),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
                Text(DateFormat('MMM').format(event.date),
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(event.category,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.isFree
                        ? '🎉 Free'
                        : 'Rs. ${event.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: event.isFree
                            ? Colors.green
                            : AppTheme.primaryColor),
                  ),
                ]),
              ],
            ),
          ),

          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}