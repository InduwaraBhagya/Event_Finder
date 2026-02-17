import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/booking_provider.dart';
import 'package:event_finder/models/booking_model.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking?'),
        content: Text(
            'Are you sure you want to cancel your booking for\n"${booking.event?.title ?? 'this event'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider =
        Provider.of<BookingProvider>(context, listen: false);
    final success = await provider.cancelBooking(booking.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Booking cancelled successfully'
              : provider.errorMessage ?? 'Failed to cancel booking'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 56, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(provider.errorMessage!,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: provider.fetchBookings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final all = provider.bookings;
          final confirmed =
              all.where((b) => b.isConfirmed).toList();
          final cancelled =
              all.where((b) => b.isCancelled).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(all, 'No bookings yet'),
              _buildList(confirmed, 'No confirmed bookings'),
              _buildList(cancelled, 'No cancelled bookings'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Your booked events will appear here',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          Provider.of<BookingProvider>(context, listen: false)
              .fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (ctx, i) => _buildCard(bookings[i]),
      ),
    );
  }

  Widget _buildCard(Booking booking) {
    final event = booking.event;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final statusColor = booking.isConfirmed
        ? Colors.green
        : booking.isCancelled
            ? Colors.red
            : Colors.orange;

    final statusLabel = booking.isConfirmed
        ? '✓ Confirmed'
        : booking.isCancelled
            ? '✗ Cancelled'
            : '⏳ Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Banner ─────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                  'Booking ID: ${booking.id.substring(booking.id.length > 8 ? booking.id.length - 8 : 0)}',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(
                  event?.title ?? 'Event',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Event details
                if (event != null) ...[
                  _detailRow(Icons.calendar_today,
                      dateFormat.format(event.date)),
                  const SizedBox(height: 6),
                  _detailRow(Icons.access_time, event.time),
                  const SizedBox(height: 6),
                  _detailRow(Icons.location_on, event.location),
                  const SizedBox(height: 6),
                ],

                // Booking details
                _detailRow(Icons.event_seat,
                    '${booking.numberOfSeats} seat(s)'),
                const SizedBox(height: 6),
                _detailRow(
                  Icons.payments,
                  booking.totalPrice == 0
                      ? 'Free'
                      : 'Rs. ${booking.totalPrice.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 6),
                _detailRow(
                  Icons.access_time,
                  'Booked on ${dateFormat.format(booking.bookingDate)}',
                ),

                // Cancel button (only for confirmed)
                if (booking.isConfirmed) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(booking),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 18, color: Colors.red),
                      label: const Text('Cancel Booking',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  TextStyle(color: Colors.grey[700], fontSize: 13)),
        ),
      ],
    );
  }
}