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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Technology', 'icon': Icons.biotech_rounded},
    {'name': 'Music', 'icon': Icons.music_note_rounded},
    {'name': 'Sports', 'icon': Icons.sports_basketball_rounded},
    {'name': 'Arts', 'icon': Icons.palette_rounded},
    {'name': 'Food & Drink', 'icon': Icons.restaurant_rounded},
    {'name': 'Business', 'icon': Icons.business_center_rounded},
    {'name': 'Health', 'icon': Icons.favorite_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Entertainment', 'icon': Icons.theater_comedy},
    {'name': 'Other', 'icon': Icons.category},
  ];

  //  Category-specific placeholder images from Unsplash
  final Map<String, String> _categoryImages = {
    'Technology': 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=500&q=80',
    'Music': 'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=500&q=80',
    'Sports': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=500&q=80',
    'Arts': 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=500&q=80',
    'Food & Drink': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500&q=80',
    'Business': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=500&q=80',
    'Health': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500&q=80',
    'Education': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=500&q=80',
    'Entertainment': 'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=500&q=80',
    'Other': 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=500&q=80',
  };

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

  //  Get image URL with category-based fallback
  String _getEventImageUrl(Event event) {
    // If event has an image URL, use it
    if (event.imageUrl.isNotEmpty && 
        !event.imageUrl.contains('placeholder')) {
      return event.imageUrl;
    }
    // Otherwise use category-specific placeholder
    return _categoryImages[event.category] ?? _categoryImages['Other']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          // ── Header & Search ──────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      Colors.deepPurple.shade700
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Events',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      Text('Find what fuels your passion',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                height: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: _buildSearchBar(),
              ),
            ),
          ),

          // ── Category Chips ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) =>
                      _buildCategoryChip(_categories[i]),
                ),
              ),
            ),
          ),

          // ── Events List ──────────────────────────────
          Consumer<EventProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (provider.errorMessage != null) {
                return SliverFillRemaining(
                    child: _buildError(provider.errorMessage!));
              }
              final events = provider.events;
              if (events.isEmpty) {
                return SliverFillRemaining(child: _buildEmpty());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildEventCard(events[i]),
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search amazing events...',
          prefixIcon:
              const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ── Category Chip ─────────────────────────────────────
  Widget _buildCategoryChip(Map<String, dynamic> category) {
    final bool isSelected = _selectedCategory == category['name'];
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => _onCategorySelected(category['name']),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [
                    AppTheme.primaryColor,
                    Colors.blue.shade700
                  ])
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey.shade300),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color:
                            AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(category['icon'],
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                category['name'],
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Event Card ────────────────────────────────────────
  Widget _buildEventCard(Event event) {
    final dateFormat = DateFormat('MMM dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Hero Image with proper error handling
                  _buildHeroImage(event),

                  // Event Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges row
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _badge(event.category,
                                Colors.blue.shade700),
                            if (event.isFeatured)
                              _badge('⭐ Popular',
                                  Colors.orange.shade700),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          event.title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Date + Time
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today,
                                  size: 14,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(event.date),
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(event.time,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12)),
                        ]),
                        const SizedBox(height: 8),

                        // Location
                        Row(children: [
                          Icon(Icons.location_on_rounded,
                              size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),

                        const Divider(height: 24),

                        // Price + View Details Button
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('PRICE',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.bold)),
                                Text(
                                  event.isFree
                                      ? 'FREE'
                                      : 'Rs. ${event.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryColor),
                                ),
                              ],
                            ),

                            // View Details Button
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EventDetailScreen(
                                            event: event)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              child: const Text('View Details',
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ❤️ Wishlist Button (top-right)
              Positioned(
                top: 15,
                right: 15,
                child: _buildWishlistButton(event),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Image ────────────────────────────────────────
  Widget _buildHeroImage(Event event) {
    final imageUrl = _getEventImageUrl(event);

    return Hero(
      tag: 'event-img-${event.id}',
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200], // fallback background
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ Image with error handling
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                );
              },
              errorBuilder: (ctx, error, trace) {
                // Fallback to category icon if image fails
                return Container(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(event.category),
                      size: 60,
                      color: AppTheme.primaryColor.withOpacity(0.4),
                    ),
                  ),
                );
              },
            ),

            // Dark gradient overlay
            Container(
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
          ],
        ),
      ),
    );
  }

  // ── Wishlist Button ───────────────────────────────────
  Widget _buildWishlistButton(Event event) {
    return Consumer<WishlistProvider>(
      builder: (ctx, wishlistProvider, _) {
        final bool isWishlisted =
            wishlistProvider.isInWishlist(event.id);
        return GestureDetector(
          onTap: () async {
            await wishlistProvider.toggleWishlist(event);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(isWishlisted
                        ? 'Removed from wishlist'
                        : '❤️ Added to wishlist'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(
              isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: isWishlisted ? Colors.redAccent : Colors.grey,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  // ── Badge ─────────────────────────────────────────────
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  // ── Get Category Icon ─────────────────────────────────
  IconData _getCategoryIcon(String category) {
    final iconMap = {
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
    return iconMap[category] ?? Icons.event;
  }

  // ── Error Widget ──────────────────────────────────────
  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty Widget ──────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != 'All'
                  ? 'No "$_selectedCategory" events found'
                  : 'No events available',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != 'All'
                  ? 'Try selecting a different category'
                  : 'Check back later for new events',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_selectedCategory != 'All') ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _onCategorySelected('All'),
                icon: const Icon(Icons.clear),
                label: const Text('Show All Events'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}