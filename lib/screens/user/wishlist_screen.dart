import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/wishlist_provider.dart';
import 'package:event_finder/providers/booking_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
    });
  }

  // ── Remove from wishlist with undo snackbar ───────────
  Future<void> _removeFromWishlist(Event event) async {
    final provider =
        Provider.of<WishlistProvider>(context, listen: false);
    final success = await provider.removeFromWishlist(event.id);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${event.title} removed from wishlist' : 'Failed to remove',
          ),
          backgroundColor: success ? Colors.black87 : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          action: success
              ? SnackBarAction(
                  label: 'UNDO',
                  textColor: AppTheme.primaryColor,
                  onPressed: () => provider.addToWishlist(event),
                )
              : null,
        ),
      );
    }
  }

  // ── Quick Book from wishlist ──────────────────────────
  Future<void> _quickBook(Event event) async {
    if (!event.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, this event is sold out'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (_, provider, __) {
              if (provider.wishlistEvents.isEmpty) return const SizedBox();
              return TextButton.icon(
                onPressed: () => _showClearAllDialog(provider),
                icon: const Icon(Icons.delete_sweep,
                    color: Colors.red, size: 20),
                label: const Text('Clear All',
                    style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          // Loading
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (provider.errorMessage != null) {
            return _buildError(provider);
          }

          final events = provider.wishlistEvents;

          // Empty State
          if (events.isEmpty) {
            return _buildEmptyState();
          }

          // Wishlist Items
          return RefreshIndicator(
            onRefresh: provider.fetchWishlist,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Count Banner ───────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  child: Text(
                    '${events.length} saved event${events.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

                // ── List ───────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (ctx, i) => _buildCard(events[i], provider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Wishlist Card ─────────────────────────────────────
  Widget _buildCard(Event event, WishlistProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Remove', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _removeFromWishlist(event);
        return false; // We handle removal ourselves via provider
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 110,
                  height: 130,
                  child: event.imageUrl.isNotEmpty
                      ? Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _thumbPlaceholder(event.category),
                        )
                      : _thumbPlaceholder(event.category),
                ),
              ),

              // ── Info ─────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Date
                      Row(children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(dateFormat.format(event.date),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),

                      // Location
                      Row(children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),

                      // Price + Book button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price
                          Text(
                            event.isFree
                                ? 'Free'
                                : 'Rs.${event.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          // Book / Sold Out
                          event.isAvailable
                              ? GestureDetector(
                                  onTap: () => _quickBook(event),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Book Now',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Sold Out',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Remove Heart Button ───────────────
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: GestureDetector(
                  onTap: () => _removeFromWishlist(event),
                  child: const Icon(Icons.favorite,
                      color: Colors.red, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Thumbnail placeholder ──────────────────────────────
  Widget _thumbPlaceholder(String category) {
    final icons = {
      'Technology': Icons.computer,
      'Music': Icons.music_note,
      'Sports': Icons.sports,
      'Arts': Icons.palette,
      'Food & Drink': Icons.restaurant,
      'Business': Icons.business_center,
      'Health': Icons.favorite,
      'Education': Icons.school,
      'Entertainment': Icons.theater_comedy,
    };
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.08),
      child: Center(
        child: Icon(
          icons[category] ?? Icons.event,
          size: 36,
          color: AppTheme.primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated heart icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 72,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Wishlist is Empty',
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Save events you love by tapping the ♡ heart icon on any event.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────
  Widget _buildError(WishlistProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.fetchWishlist,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clear All Dialog ───────────────────────────────────
  void _showClearAllDialog(WishlistProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Wishlist?'),
        content: Text(
          'Remove all ${provider.wishlistEvents.length} events from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final events =
                  List<Event>.from(provider.wishlistEvents);
              for (final e in events) {
                await provider.removeFromWishlist(e.id);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wishlist cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}