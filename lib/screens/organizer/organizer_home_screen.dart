import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/providers/event_provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:intl/intl.dart';

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final organizerName = authProvider.user?.name ?? 'Organizer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Colorful Header ───────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30, right: -30,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: -20,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    // Greeting
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.event_note_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Welcome back,',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14)),
                                    Text(organizerName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('🎯 Organizer Dashboard',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
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
            onPressed: () async {
              await authProvider.logout();

              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',   // make sure this route exists
                  (route) => false,
                );
              }
            },
          ),
        ],
                  ),

          // ── Content ───────────────────────────────────
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              final events = eventProvider.events;

              // Stats
              final totalEvents = events.length;
              final totalSeats = events.fold<int>(0, (s, e) => s + e.totalSeats);
              final bookedSeats = events.fold<int>(
                  0, (s, e) => s + (e.totalSeats - e.availableSeats));
              final totalRevenue = events.fold<double>(
                  0, (s, e) => s + (e.isFree ? 0 : e.price * (e.totalSeats - e.availableSeats)));

              return SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Row ────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Expanded(child: _miniStat('My Events', '$totalEvents',
                            Icons.event_rounded, const Color(0xFF6A11CB))),
                        const SizedBox(width: 10),
                        Expanded(child: _miniStat('Bookings', '$bookedSeats',
                            Icons.confirmation_number_rounded, const Color(0xFF2575FC))),
                        const SizedBox(width: 10),
                        Expanded(child: _miniStat('Revenue',
                            'Rs.${totalRevenue.toStringAsFixed(0)}',
                            Icons.payments_rounded, Colors.green.shade600)),
                      ],
                    ),
                  ),

                  // ── Quick Actions ────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _actionCard(
                          label: 'Create Event',
                          icon: Icons.add_circle_rounded,
                          gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          onTap: () => Navigator.pushNamed(context, '/create-event'),
                        ),
                        //_actionCard(
                          //label: 'My Events',
                          //icon: Icons.event_note_rounded,
                          //gradient: [Colors.orange.shade400, Colors.deepOrange.shade400],
                          //onTap: () => Navigator.pushNamed(context, '/manage-events'),
                        //),
                        //_actionCard(
                        //  label: 'Bookings',
                        //  icon: Icons.confirmation_number_rounded,
                          //gradient: [Colors.teal.shade400, Colors.cyan.shade500],
                         // onTap: () => Navigator.pushNamed(context, '/bookings'),
                        //),
                        //_actionCard(
                         // label: 'Analytics',
                         // icon: Icons.bar_chart_rounded,
                          //gradient: [Colors.pink.shade400, Colors.red.shade400],
                         // onTap: () => Navigator.pushNamed(context, '/analytics'),
                        //),
                      ],
                    ),
                  ),

                  // ── My Events Header ─────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Events',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        if (eventProvider.isLoading)
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF6A11CB)),
                          )
                        else
                          GestureDetector(
                            onTap: () => eventProvider.fetchEvents(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A11CB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      size: 14, color: Color(0xFF6A11CB)),
                                  SizedBox(width: 4),
                                  Text('Refresh',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6A11CB),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Loading ──────────────────────────
                  if (eventProvider.isLoading && events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6A11CB))),
                    )

                  // ── Error ────────────────────────────
                  else if (eventProvider.errorMessage != null && events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              size: 56, color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text(eventProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => eventProvider.fetchEvents(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A11CB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )

                  // ── Empty ────────────────────────────
                  else if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No events yet',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Tap "Create Event" to get started',
                              style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/create-event'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Your First Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A11CB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )

                  // ── Events List ──────────────────────
                  else
                    ...events.map((event) => _OrganizerEventCard(event: event)),

                  const SizedBox(height: 100),
                ]),
              );
            },
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-event'),
        backgroundColor: const Color(0xFF6A11CB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Event',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Mini Stat ─────────────────────────────────────────
  Widget _miniStat(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(title,
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Action Card ───────────────────────────────────────
  Widget _actionCard({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: gradient.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, bottom: -10,
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Organizer Event Card ──────────────────────────────────────────────────────
class _OrganizerEventCard extends StatelessWidget {
  const _OrganizerEventCard({required this.event});
  final Event event;

  static const Map<String, String> _categoryImages = {
    'Technology': 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=500&q=80',
    'Music':      'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=500&q=80',
    'Sports':     'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=500&q=80',
    'Arts':       'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=500&q=80',
    'Food & Drink':'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500&q=80',
    'Business':   'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=500&q=80',
    'Health':     'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&q=80',
    'Education':  'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=500&q=80',
    'Entertainment':'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=500&q=80',
    'Other':      'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=500&q=80',
  };

  String get _imageUrl {
    if (event.imageUrl.isNotEmpty &&
        !event.imageUrl.contains('placeholder') &&
        (event.imageUrl.startsWith('http://') ||
            event.imageUrl.startsWith('https://'))) {
      return event.imageUrl;
    }
    return _categoryImages[event.category] ?? _categoryImages['Other']!;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(event.date);
    final bookedSeats = event.totalSeats - event.availableSeats;
    final fillPercent = event.totalSeats > 0
        ? bookedSeats / event.totalSeats
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 130,
                        color: Colors.purple.shade50,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6A11CB), strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (ctx, error, trace) {
                      final fallback = _categoryImages[event.category] ??
                          _categoryImages['Other']!;
                      if (_imageUrl != fallback) {
                        return Image.network(fallback,
                            fit: BoxFit.cover,
                            height: 130,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              height: 130,
                              color: Colors.purple.shade50,
                              child: Icon(Icons.event_rounded,
                                  size: 48,
                                  color: Colors.purple.shade200),
                            ));
                      }
                      return Container(
                        height: 130,
                        color: Colors.purple.shade50,
                        child: Icon(Icons.event_rounded,
                            size: 48, color: Colors.purple.shade200),
                      );
                    },
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                // Featured
                if (event.isFeatured)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 11),
                          SizedBox(width: 4),
                          Text('Featured',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                // Status badge
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.isAvailable
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.isAvailable ? 'Active' : 'Sold Out',
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

          // ── Info ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A11CB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(event.category,
                          style: const TextStyle(
                              color: Color(0xFF6A11CB),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      event.isFree
                          ? '🎉 FREE'
                          : 'Rs. ${event.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6A11CB)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(event.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),

                // Date + Location
                Row(children: [
                  Icon(Icons.calendar_today,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(width: 10),
                  Icon(Icons.access_time,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(event.time,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(event.location,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 12),

                // Seats fill bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$bookedSeats / ${event.totalSeats} booked',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text('${(fillPercent * 100).toStringAsFixed(0)}% full',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fillPercent > 0.8
                                ? Colors.red
                                : Colors.green.shade600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPercent.toDouble(),
                    backgroundColor: Colors.grey.shade200,
                    color: fillPercent > 0.8
                        ? Colors.red
                        : const Color(0xFF6A11CB),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),

                // Edit button
              //  SizedBox(
                //  width: double.infinity,
                  //child: ElevatedButton.icon(
                    //onPressed: () => Navigator.pushNamed(
                      //context,
                      //'//manage-events',
                      //arguments: event,
                    //),
                   // icon: const Icon(Icons.edit_rounded, size: 16),
                    //label: const Text('Manage Event'),
                    //style: ElevatedButton.styleFrom(
                     // backgroundColor: const Color(0xFF6A11CB),
                      //foregroundColor: Colors.white,
                      //shape: RoundedRectangleBorder(
                        //  borderRadius: BorderRadius.circular(12)),
                      //padding: const EdgeInsets.symmetric(vertical: 10),
                    //),
                  //),
                //),
              ],
            ),
          ),
        ],
      ),
    );
  }
}