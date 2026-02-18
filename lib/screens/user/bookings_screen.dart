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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Text(
            'Are you sure you want to cancel your booking for\n"${booking.event?.title ?? 'this event'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No, Keep It', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = Provider.of<BookingProvider>(context, listen: false);
    final success = await provider.cancelBooking(booking.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Booking cancelled successfully'
              : provider.errorMessage ?? 'Failed to cancel booking'),
          backgroundColor: success ? Colors.green[700] : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Soft designer background
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('My Bookings', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          if (provider.errorMessage != null) {
            return _buildErrorState(provider);
          }

          final all = provider.bookings;
          final confirmed = all.where((b) => b.isConfirmed).toList();
          final cancelled = all.where((b) => b.isCancelled).toList();

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

  Widget _buildErrorState(BookingProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Text(provider.errorMessage!, textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.fetchBookings,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/4076/4076403.png', // Or a local asset
                height: 150,
              ),
            ),
            const SizedBox(height: 24),
            Text(emptyMessage,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Time to find some exciting events!', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => Provider.of<BookingProvider>(context, listen: false).fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: bookings.length,
        itemBuilder: (ctx, i) => _buildCard(bookings[i]),
      ),
    );
  }

  Widget _buildCard(Booking booking) {
    final event = booking.event;
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    final Color statusColor = booking.isConfirmed
        ? Colors.teal
        : booking.isCancelled
            ? Colors.redAccent
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: statusColor.withOpacity(0.1),
              child: Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    booking.isConfirmed ? 'CONFIRMED' : booking.isCancelled ? 'CANCELLED' : 'PENDING',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                  ),
                  const Spacer(),
                  Text('#${booking.id.substring(booking.id.length - 6).toUpperCase()}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Block
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(DateFormat('MMM').format(event?.date ?? DateTime.now()).toUpperCase(),
                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd').format(event?.date ?? DateTime.now()),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event?.title ?? 'Event Title',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                        ),
                        const SizedBox(height: 8),
                        _detailRow(Icons.location_on_rounded, event?.location ?? 'Venue'),
                        const SizedBox(height: 4),
                        _detailRow(Icons.event_seat_rounded, '${booking.numberOfSeats} Tickets Purchased'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, indent: 16, endIndent: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        booking.totalPrice == 0 ? 'FREE' : 'Rs. ${booking.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  if (booking.isConfirmed)
                    ElevatedButton(
                      onPressed: () => _cancelBooking(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}