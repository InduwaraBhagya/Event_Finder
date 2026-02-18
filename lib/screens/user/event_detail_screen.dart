import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/providers/booking_provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/providers/wishlist_provider.dart';
import 'package:event_finder/screens/user/bookings_screen.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _selectedSeats = 1;
  Event get event => widget.event;

  // ✅ Category-based placeholder images (same as event list)
  final Map<String, String> _categoryImages = {
    'Technology': 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&q=80',
    'Music': 'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=800&q=80',
    'Sports': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&q=80',
    'Arts': 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800&q=80',
    'Food & Drink': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80',
    'Business': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&q=80',
    'Health': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
    'Education': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&q=80',
    'Entertainment': 'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=800&q=80',
    'Other': 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80',
  };

  // ✅ Get image URL with fallback
  String _getEventImageUrl() {
    if (event.imageUrl.isNotEmpty && 
        !event.imageUrl.contains('placeholder')) {
      return event.imageUrl;
    }
    return _categoryImages[event.category] ?? _categoryImages['Other']!;
  }

  IconData _getCategoryIcon() {
    const icons = {
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
    return icons[event.category] ?? Icons.event;
  }

  // ── Book Event ────────────────────────────────────────
  Future<void> _bookEvent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // ✅ Check login using isLoggedIn (NOT isAuthenticated)
    if (!authProvider.isLoggedIn) {
      _showSnack('Please login to book events', isError: true);
      return;
    }

    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _confirmRow(Icons.event_seat, 'Seats', '$_selectedSeats'),
            const SizedBox(height: 6),
            _confirmRow(
              Icons.payments,
              'Total',
              event.isFree
                  ? 'Free'
                  : 'Rs. ${(event.price * _selectedSeats).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 6),
            _confirmRow(Icons.calendar_today, 'Date',
                DateFormat('MMM dd, yyyy').format(event.date)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Make booking
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final success =
        await bookingProvider.createBooking(event.id, _selectedSeats);

    if (success && mounted) {
      // Success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 64),
              ),
              const SizedBox(height: 16),
              const Text('Booking Confirmed!',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You booked $_selectedSeats seat(s) for',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(event.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyBookingsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View My Bookings',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } else if (!success && mounted) {
      _showSnack(
          bookingProvider.errorMessage ?? 'Booking failed. Try again.',
          isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _confirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final totalPrice = event.price * _selectedSeats;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Image ─────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ Image with proper error handling
                  Image.network(
                    _getEventImageUrl(),
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (ctx, error, trace) {
                      // Fallback to category icon
                      return Container(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        child: Center(
                          child: Icon(_getCategoryIcon(),
                              size: 80,
                              color: AppTheme.primaryColor.withOpacity(0.4)),
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
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              // ❤️ Wishlist heart button
              Consumer<WishlistProvider>(
                builder: (ctx, wishlistProvider, _) {
                  final isWishlisted =
                      wishlistProvider.isInWishlist(event.id);
                  return GestureDetector(
                    onTap: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      if (!authProvider.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to save events'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      await wishlistProvider.toggleWishlist(event);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Colors.white,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Event Content ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Featured badges
                  Row(children: [
                    _chip(event.category, AppTheme.primaryColor),
                    if (event.isFeatured) ...[
                      const SizedBox(width: 8),
                      _chip('⭐ Featured', Colors.orange),
                    ],
                  ]),
                  const SizedBox(height: 12),

                  // Title
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Rating (if exists)
                  if (event.rating != null && event.rating! > 0)
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(event.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(width: 4),
                      Text('(${event.reviewCount ?? 0} reviews)',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ]),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Date & Time
                  _infoRow(Icons.calendar_today, 'Date & Time',
                      '${dateFormat.format(event.date)}\nat ${event.time}'),
                  const SizedBox(height: 16),

                  // Location
                  _infoRow(Icons.location_on, 'Location', event.location),
                  const SizedBox(height: 16),

                  // Organizer
                  _infoRow(Icons.person, 'Organizer', event.organizerName),
                  const SizedBox(height: 16),

                  // Available Seats
                  _infoRow(
                    Icons.event_seat,
                    'Available Seats',
                    event.isAvailable
                        ? '${event.availableSeats} seats left'
                        : 'Sold Out',
                    valueColor:
                        event.isAvailable ? Colors.green : Colors.red,
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  const Text('About This Event',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.description,
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          height: 1.5)),

                  const SizedBox(height: 24),

                  // ── Seat Selector ─────────────────
                  if (event.isAvailable) ...[
                    const Text('Select Number of Seats',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Seats',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                          Row(children: [
                            _seatBtn(
                              Icons.remove,
                              _selectedSeats > 1
                                  ? () => setState(() => _selectedSeats--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Text('$_selectedSeats',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                            _seatBtn(
                              Icons.add,
                              _selectedSeats < event.availableSeats &&
                                      _selectedSeats < 10
                                  ? () => setState(() => _selectedSeats++)
                                  : null,
                            ),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '$_selectedSeats seat(s) × ${event.isFree ? 'Free' : 'Rs.${event.price.toStringAsFixed(0)}'}',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text('Total Amount',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            event.isFree
                                ? 'Free'
                                : 'Rs. ${totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Book Now Button ────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Consumer<BookingProvider>(
          builder: (ctx, bookingProvider, _) {
            if (!event.isAvailable) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Sold Out',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ),
              );
            }

            return SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed:
                    bookingProvider.isLoading ? null : _bookEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: bookingProvider.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bookmark_add, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            event.isFree
                                ? 'Book Free Ticket'
                                : 'Book Now · Rs.${(event.price * _selectedSeats).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 3),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: valueColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seatBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null ? Colors.white : Colors.grey),
      ),
    );
  }
}