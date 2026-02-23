import 'package:flutter/material.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:intl/intl.dart';

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({super.key});

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> {
  final _apiClient = ApiClient();
  List<Event> _myEvents = [];
  bool _isLoading = false;

  static const Map<String, String> _categoryImages = {
    'Technology':    'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=400&q=80',
    'Music':         'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&q=80',
    'Sports':        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&q=80',
    'Arts':          'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=400&q=80',
    'Food & Drink':  'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
    'Business':      'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400&q=80',
    'Health':        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
    'Education':     'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400&q=80',
    'Entertainment': 'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=400&q=80',
    'Other':         'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=400&q=80',
  };

  @override
  void initState() {
    super.initState();
    _loadMyEvents();
  }

  Future<void> _loadMyEvents() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(
        '${AppConfig.eventsEndpoint}/organizer/my-events',
        requiresAuth: true,
      );
      // Backend returns events in res['events'] or res['data']
      final list = res['events'] ?? res['data'] ?? [];
      setState(() {
        _myEvents = (list as List).map((e) => Event.fromJson(e)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getImageUrl(Event event) {
    if (event.imageUrl.isNotEmpty &&
        (event.imageUrl.startsWith('http://') ||
         event.imageUrl.startsWith('https://'))) {
      return event.imageUrl;
    }
    return _categoryImages[event.category] ?? _categoryImages['Other']!;
  }

  @override
  Widget build(BuildContext context) {
    final pending  = _myEvents.where((e) => e.isPending).length;
    final approved = _myEvents.where((e) => e.isApproved).length;
    final rejected = _myEvents.where((e) => e.isRejected).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('My Events',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMyEvents,
              tooltip: 'Refresh'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : RefreshIndicator(
              onRefresh: _loadMyEvents,
              color: Colors.deepPurple,
              child: _myEvents.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Stats row
                        Row(children: [
                          _statBox('Pending',  pending,  Colors.orange),
                          const SizedBox(width: 8),
                          _statBox('Approved', approved, Colors.green),
                          const SizedBox(width: 8),
                          _statBox('Rejected', rejected, Colors.red),
                        ]),
                        const SizedBox(height: 20),
                        ..._myEvents.map(_buildEventCard),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEventCard(Event event) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (event.isApproved) {
      statusColor = Colors.green.shade700;
      statusIcon  = Icons.check_circle_rounded;
      statusLabel = '✅ Approved — Live on events page!';
    } else if (event.isRejected) {
      statusColor = Colors.red.shade700;
      statusIcon  = Icons.cancel_rounded;
      statusLabel = '❌ Rejected by admin';
    } else {
      statusColor = Colors.orange.shade700;
      statusIcon  = Icons.hourglass_top_rounded;
      statusLabel = '⏳ Waiting for admin approval…';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Image with status badge
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          child: Stack(children: [
            SizedBox(
              height: 130, width: double.infinity,
              child: Image.network(_getImageUrl(event), fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey))),
            ),
            Positioned(top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(event.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel,
                  style: TextStyle(color: statusColor,
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),

        
            if (event.isRejected) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.feedback_rounded, size: 15, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text('Reason from Admin',
                        style: TextStyle(color: Colors.red.shade700,
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    event.adminNote.isNotEmpty
                        ? event.adminNote
                        : 'No reason provided. Please contact admin.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ]),
              ),
            ],

            // Approved: show live notice
            if (event.isApproved) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.public_rounded, size: 15, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Your event is visible to all users',
                    style: TextStyle(color: Colors.green.shade700,
                        fontWeight: FontWeight.w600, fontSize: 12),
                  )),
                ]),
              ),
            ],

            const SizedBox(height: 12),

            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(event.category,
                  style: const TextStyle(color: Colors.deepPurple,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),

            // Title
            Text(event.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),

            // Date & location
            Row(children: [
              Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(DateFormat('MMM dd, yyyy').format(event.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.location_on, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(child: Text(event.location,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 10),

            // Price & seats
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                event.isFree ? '🎉 FREE' : 'Rs. ${event.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: Colors.deepPurple, fontSize: 15),
              ),
              Text('${event.totalSeats} seats',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _statBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 24,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(children: [
      const SizedBox(height: 100),
      Center(child: Column(children: [
        Icon(Icons.event_note_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No events yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Text('Create an event — admin will review before it goes live.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ])),
    ]);
  }
}