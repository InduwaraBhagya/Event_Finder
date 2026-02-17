import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/event_provider.dart';
import 'package:event_finder/providers/wishlist_provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/screens/user/event_detail_screen.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _selectedCategory = 'All');
    final provider = Provider.of<EventProvider>(context, listen: false);
    provider.clearFilters();
    await provider.fetchEvents();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    final provider = Provider.of<EventProvider>(context, listen: false);
    if (query.isEmpty) {
      provider.clearFilters();
    } else {
      provider.searchEvents(query);
    }
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    final provider = Provider.of<EventProvider>(context, listen: false);
    if (category == 'All') {
      provider.filterByCategory(null);
    } else {
      provider.filterByCategory(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // ── Category Chips ───────────────────────
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All'),
                _chip('Technology'),
                _chip('Music'),
                _chip('Sports'),
                _chip('Arts'),
                _chip('Food & Drink'),
                _chip('Business'),
                _chip('Health'),
                _chip('Education'),
                _chip('Entertainment'),
                _chip('Other'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Events List ──────────────────────────
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return _buildError(provider.errorMessage!);
                }
                final events = provider.events;
                if (events.isEmpty) {
                  return _buildEmpty();
                }
                return RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (ctx, i) => _buildCard(events[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Chip ────────────────────────────
  Widget _chip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(category),
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── Error Widget ─────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty Widget ─────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != 'All'
                  ? 'No "$_selectedCategory" events'
                  : _searchController.text.isNotEmpty
                      ? 'No results for "${_searchController.text}"'
                      : 'No events found',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != 'All'
                  ? 'Try a different category'
                  : 'Pull down to refresh',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (_selectedCategory != 'All')
              OutlinedButton.icon(
                onPressed: () => _onCategorySelected('All'),
                icon: const Icon(Icons.clear),
                label: const Text('Show All Events'),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Event Card ───────────────────────────────
  Widget _buildCard(Event event) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Image with Heart Button on top ───
            Stack(
              children: [
                // Event image / placeholder
                _buildImage(event),

                // ❤️ Wishlist heart button (top-right of image)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Consumer<WishlistProvider>(
                    builder: (ctx, wishlistProvider, _) {
                      final isWishlisted =
                          wishlistProvider.isInWishlist(event.id);
                      return GestureDetector(
                        onTap: () async {
                          await wishlistProvider.toggleWishlist(event);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isWishlisted
                                        ? 'Removed from wishlist'
                                        : '❤️ Added to wishlist',
                                  ),
                                  backgroundColor: isWishlisted
                                      ? Colors.black87
                                      : Colors.pink[600],
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : Colors.grey,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Event Info ───────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Featured badges
                  Row(
                    children: [
                      _badge(event.category, AppTheme.primaryColor),
                      if (event.isFeatured) ...[
                        const SizedBox(width: 8),
                        _badge('⭐ Featured', Colors.orange),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    event.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date & Time
                  Row(children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(dateFormat.format(event.date),
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(event.time,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),

                  // Location
                  Row(children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Price & Seats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Row(children: [
                        Icon(Icons.payments,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          event.isFree
                              ? 'Free'
                              : 'Rs. ${event.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ]),

                      // Seats badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: event.isAvailable
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              event.isAvailable
                                  ? Icons.event_seat
                                  : Icons.block,
                              size: 13,
                              color: event.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.isAvailable
                                  ? '${event.availableSeats} left'
                                  : 'Sold Out',
                              style: TextStyle(
                                color: event.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildImage(Event event) {
    if (event.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.network(
          event.imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(event.category),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }
    return _placeholder(event.category);
  }

  Widget _placeholder(String category) {
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: 180,
        width: double.infinity,
        color: AppTheme.primaryColor.withOpacity(0.07),
        child: Center(
          child: Icon(
            icons[category] ?? Icons.event,
            size: 60,
            color: AppTheme.primaryColor.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}