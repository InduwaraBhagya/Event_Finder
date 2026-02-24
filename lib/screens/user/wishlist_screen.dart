// FILE: lib/screens/user/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/wishlist_provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/screens/user/event_detail_screen.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {

  // ── Category fallback images (Unsplash) ──────────────
  // Used ONLY when event has no uploaded image
  static const Map<String, String> _categoryImages = {
    'Technology':    'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=500&q=80',
    'Music':         'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=500&q=80',
    'Sports':        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=500&q=80',
    'Arts':          'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=500&q=80',
    'Food & Drink':  'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500&q=80',
    'Business':      'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=500&q=80',
    'Health':        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&q=80',
    'Education':     'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=500&q=80',
    'Entertainment': 'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=500&q=80',
    'Other':         'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=500&q=80',
  };

  // ── Category gradient colors ──────────────────────────
  static const Map<String, List<Color>> _catGradients = {
    'Music':         [Color(0xFF667EEA), Color(0xFF764BA2)],
    'Sports':        [Color(0xFF11998E), Color(0xFF38EF7D)],
    'Technology':    [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    'Arts':          [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
    'Food & Drink':  [Color(0xFFFF8008), Color(0xFFFFC837)],
    'Business':      [Color(0xFF4776E6), Color(0xFF8E54E9)],
    'Health':        [Color(0xFFDA4453), Color(0xFF89216B)],
    'Education':     [Color(0xFF00B09B), Color(0xFF96C93D)],
    'Entertainment': [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    'Other':         [Color(0xFF8360C3), Color(0xFF2EBF91)],
  };

  static const Map<String, IconData> _catIcons = {
    'Music':         Icons.music_note_rounded,
    'Sports':        Icons.sports_soccer_rounded,
    'Technology':    Icons.computer_rounded,
    'Arts':          Icons.palette_rounded,
    'Food & Drink':  Icons.restaurant_rounded,
    'Business':      Icons.business_center_rounded,
    'Health':        Icons.favorite_rounded,
    'Education':     Icons.school_rounded,
    'Entertainment': Icons.theater_comedy_rounded,
    'Other':         Icons.event_rounded,
  };

  List<Color> _gradient(String cat) =>
      _catGradients[cat] ?? [const Color(0xFF8360C3), const Color(0xFF2EBF91)];
  Color _primary(String cat) => _gradient(cat).first;

  String _imageUrl(Event event) {
    if (event.imageUrl.isNotEmpty) return event.imageUrl;
    return _categoryImages[event.category] ??
        'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=500&q=80';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
    });
  }

  Future<void> _remove(Event event) async {
    final provider = Provider.of<WishlistProvider>(context, listen: false);
    final success = await provider.removeFromWishlist(event.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? '${event.title} removed' : 'Failed to remove'),
      backgroundColor: success ? Colors.black87 : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: success
          ? SnackBarAction(
              label: 'UNDO',
              textColor: Colors.amber,
              onPressed: () => provider.addToWishlist(event),
            )
          : null,
    ));
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [

              // ── Gradient AppBar ─────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                          Colors.purple.shade800,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Row(children: [
                              const Icon(Icons.favorite_rounded,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 10),
                              const Text('My Wishlist',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (!provider.isLoading &&
                                  provider.wishlistEvents.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _showClearAllDialog(provider),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.4)),
                                    ),
                                    child: const Row(children: [
                                      Icon(Icons.delete_sweep_rounded,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Clear All',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                title: const Text('My Wishlist',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),

              // ── Loading ───────────────────────────────────────
              if (provider.isLoading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator())),

              // ── Error ─────────────────────────────────────────
              if (!provider.isLoading && provider.errorMessage != null)
                SliverFillRemaining(child: _buildError(provider)),

              // ── Empty ─────────────────────────────────────────
              if (!provider.isLoading &&
                  provider.errorMessage == null &&
                  provider.wishlistEvents.isEmpty)
                SliverFillRemaining(child: _buildEmpty()),

              // ── Count + Cards ─────────────────────────────────
              if (!provider.isLoading &&
                  provider.wishlistEvents.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppTheme.primaryColor,
                            Colors.purple.shade700,
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${provider.wishlistEvents.length} saved event${provider.wishlistEvents.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) =>
                          _buildCard(provider.wishlistEvents[i], provider),
                      childCount: provider.wishlistEvents.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(Event event, WishlistProvider provider) {
    final gradient = _gradient(event.category);
    final primary  = gradient.first;
    final dateStr  = DateFormat('EEE, MMM dd · yyyy').format(event.date);
    final imgUrl   = _imageUrl(event); // real image or Unsplash fallback

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFEE0979)]),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_rounded, color: Colors.white, size: 30),
              SizedBox(height: 4),
              Text('Remove',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ]),
      ),
      confirmDismiss: (_) async {
        await _remove(event);
        return false;
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Image ───────────────────────────────────
            Stack(children: [
            
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  imgUrl,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    // Show gradient shimmer while loading
                    return Container(
                      height: 170,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient)),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) =>
                      _gradientFallback(event, gradient),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: primary.withOpacity(0.4), blurRadius: 8)
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_catIcons[event.category] ?? Icons.event_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(event.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),

              // Remove heart (top right)
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: () => _remove(event),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.red, size: 20),
                  ),
                ),
              ),

              // Event title on image (bottom left)
              Positioned(
                bottom: 10, left: 12, right: 56,
                child: Text(
                  event.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4)
                      ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),

            // ── Info section ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Date row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_month_rounded,
                        size: 14, color: primary),
                  ),
                  const SizedBox(width: 8),
                  Text(dateStr,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 8),

                // Location row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.place_rounded,
                        size: 14, color: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

            
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: event))),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Gradient fallback (only if network fails) ─────────
  Widget _gradientFallback(Event event, List<Color> gradient) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient)),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_catIcons[event.category] ?? Icons.event_rounded,
              color: Colors.white.withOpacity(0.8), size: 52),
          const SizedBox(height: 8),
          Text(event.category,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.red.shade100, Colors.pink.shade50]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded,
                size: 72, color: Colors.red),
          ),
          const SizedBox(height: 24),
          const Text('Nothing Saved Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Tap the ♡ on any event to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Colors.purple.shade700]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────
  Widget _buildError(WishlistProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: provider.fetchWishlist,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Clear All dialog ──────────────────────────────────
  void _showClearAllDialog(WishlistProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Clear Wishlist?'),
        ]),
        content: Text(
            'Remove all ${provider.wishlistEvents.length} saved events?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final events = List<Event>.from(provider.wishlistEvents);
              for (final e in events) {
                await provider.removeFromWishlist(e.id);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Wishlist cleared'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}