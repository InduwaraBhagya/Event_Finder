// ============================================================
// FILE: lib/screens/admin/admin_home_screen.dart
// Admin dashboard with Approve / Reject workflow
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/providers/event_provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiClient = ApiClient();

  List<Event> _pendingEvents   = [];
  List<Event> _approvedEvents  = [];
  List<Event> _rejectedEvents  = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllEvents());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllEvents() async {
    setState(() => _isLoading = true);
    try {
      // Load all statuses
      final allRes = await _apiClient.get(
        '${AppConfig.eventsEndpoint}/admin/all',
        requiresAuth: true,
      );
      final all = (allRes['events'] as List)
          .map((e) => Event.fromJson(e))
          .toList();

      setState(() {
        _pendingEvents  = all.where((e) => e.status == 'pending').toList();
        _approvedEvents = all.where((e) => e.status == 'approved').toList();
        _rejectedEvents = all.where((e) => e.status == 'rejected').toList();
      });
    } catch (e) {
      _showSnack('Failed to load events: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Approve an event ──────────────────────────────────────────
  Future<void> _approveEvent(Event event) async {
    final confirm = await _showConfirmDialog(
      title: 'Approve Event',
      message: 'Approve "${event.title}"?\nIt will be visible to all users.',
      confirmLabel: 'Approve',
      confirmColor: Colors.green.shade700,
    );
    if (!confirm) return;

    try {
      await _apiClient.patch(
        '${AppConfig.eventsEndpoint}/${event.id}/approve',
        {'note': 'Approved by admin'},
        requiresAuth: true,
      );
      _showSnack('✅ "${event.title}" approved!');
      _loadAllEvents();
    } catch (e) {
      _showSnack('Failed to approve: $e', isError: true);
    }
  }

  // ── Reject an event ───────────────────────────────────────────
  Future<void> _rejectEvent(Event event) async {
    final reason = await _showRejectDialog(event.title);
    if (reason == null) return; // cancelled

    try {
      await _apiClient.patch(
        '${AppConfig.eventsEndpoint}/${event.id}/reject',
        {'reason': reason},
        requiresAuth: true,
      );
      _showSnack('🚫 "${event.title}" rejected. Organizer notified.');
      _loadAllEvents();
    } catch (e) {
      _showSnack('Failed to reject: $e', isError: true);
    }
  }

  // ── Delete an event ───────────────────────────────────────────
  Future<void> _deleteEvent(Event event) async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Event',
      message: 'Permanently delete "${event.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red.shade700,
    );
    if (!confirm) return;

    try {
      await _apiClient.delete(
        '${AppConfig.eventsEndpoint}/${event.id}',
        requiresAuth: true,
      );
      _showSnack('🗑️ Event deleted.');
      _loadAllEvents();
    } catch (e) {
      _showSnack('Failed to delete: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade700,
                             Colors.deepPurple.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 70, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Dashboard',
                          style: TextStyle(color: Colors.white,
                              fontSize: 26, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Event Approval Management',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAllEvents,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Pending  '),
                    _countBadge(_pendingEvents.length, Colors.orange),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Approved  '),
                    _countBadge(_approvedEvents.length, Colors.green),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Rejected  '),
                    _countBadge(_rejectedEvents.length, Colors.red),
                  ]),
                ),
              ],
            ),
          ),

          // ── Stats row ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                _statChip('⏳ Pending',  _pendingEvents.length,  Colors.orange),
                const SizedBox(width: 8),
                _statChip('✅ Approved', _approvedEvents.length, Colors.green),
                const SizedBox(width: 8),
                _statChip('❌ Rejected', _rejectedEvents.length, Colors.red),
              ]),
            ),
          ),

          // ── Tab content ──────────────────────────────────────
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    color: Colors.deepPurple))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingList(),
                      _buildApprovedList(),
                      _buildRejectedList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Pending tab ───────────────────────────────────────────────
  Widget _buildPendingList() {
    if (_pendingEvents.isEmpty) {
      return _emptyState(
          icon: Icons.check_circle_outline,
          title: 'No Pending Events',
          subtitle: 'All events have been reviewed!',
          color: Colors.orange);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _pendingEvents.length,
      itemBuilder: (_, i) => _AdminEventCard(
        event: _pendingEvents[i],
        mode: CardMode.pending,
        onApprove: () => _approveEvent(_pendingEvents[i]),
        onReject:  () => _rejectEvent(_pendingEvents[i]),
        onDelete:  () => _deleteEvent(_pendingEvents[i]),
      ),
    );
  }

  // ── Approved tab ──────────────────────────────────────────────
  Widget _buildApprovedList() {
    if (_approvedEvents.isEmpty) {
      return _emptyState(
          icon: Icons.event_available,
          title: 'No Approved Events',
          subtitle: 'Approve pending events to show them here.',
          color: Colors.green);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _approvedEvents.length,
      itemBuilder: (_, i) => _AdminEventCard(
        event: _approvedEvents[i],
        mode: CardMode.approved,
        onDelete: () => _deleteEvent(_approvedEvents[i]),
      ),
    );
  }

  // ── Rejected tab ──────────────────────────────────────────────
  Widget _buildRejectedList() {
    if (_rejectedEvents.isEmpty) {
      return _emptyState(
          icon: Icons.block,
          title: 'No Rejected Events',
          subtitle: 'Rejected events will appear here.',
          color: Colors.red);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _rejectedEvents.length,
      itemBuilder: (_, i) => _AdminEventCard(
        event: _rejectedEvents[i],
        mode: CardMode.rejected,
        onDelete: () => _deleteEvent(_rejectedEvents[i]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _countBadge(int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style: const TextStyle(color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text('$count',
              style: TextStyle(color: color, fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: color, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 72, color: color.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Reject dialog — asks admin to type a reason
  Future<String?> _showRejectDialog(String eventTitle) async {
    final ctrl = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Event',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Rejecting "$eventTitle"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Reason for rejection *',
              hintText: 'e.g. Missing event details, inappropriate content...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This reason will be visible to the organizer.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().length < 5) return;
              Navigator.pop(context, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white),
            child: const Text('Reject & Notify'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Card mode enum
// ════════════════════════════════════════════════════════════════
enum CardMode { pending, approved, rejected }

// ════════════════════════════════════════════════════════════════
// _AdminEventCard
// ════════════════════════════════════════════════════════════════
class _AdminEventCard extends StatelessWidget {
  const _AdminEventCard({
    required this.event,
    required this.mode,
    this.onApprove,
    this.onReject,
    this.onDelete,
  });

  final Event event;
  final CardMode mode;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

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

  Color get _statusColor {
    switch (mode) {
      case CardMode.pending:  return Colors.orange.shade700;
      case CardMode.approved: return Colors.green.shade700;
      case CardMode.rejected: return Colors.red.shade700;
    }
  }

  String get _statusLabel {
    switch (mode) {
      case CardMode.pending:  return '⏳ Pending Review';
      case CardMode.approved: return '✅ Approved';
      case CardMode.rejected: return '❌ Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(event.date);
    final imageUrl = (event.imageUrl.isNotEmpty &&
            (event.imageUrl.startsWith('http://') ||
             event.imageUrl.startsWith('https://')))
        ? event.imageUrl
        : (_categoryImages[event.category] ?? _categoryImages['Other']!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image + status badge
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          child: Stack(children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey))),
            ),
            // Status badge (top left)
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            // Delete button (top right)
            Positioned(
              top: 10, right: 10,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Category + organizer name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(event.category,
                      style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(event.organizerName ?? 'Unknown',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ]),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(event.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),

            // Date + location row
            Row(children: [
              Icon(Icons.calendar_today,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(dateStr,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.location_on,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(event.location,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),

            // Admin rejection note
            if (mode == CardMode.rejected &&
                event.adminNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${event.adminNote}',
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ],

            const Divider(height: 20),

            // Price + action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event.isFree
                      ? '🎉 FREE'
                      : 'Rs. ${event.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.deepPurple),
                ),
                // Pending: show Approve + Reject buttons
                if (mode == CardMode.pending)
                  Row(children: [
                    _actionBtn(
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      color: Colors.red.shade700,
                      onTap: onReject,
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      color: Colors.green.shade700,
                      onTap: onApprove,
                    ),
                  ]),
                // Approved: show seats info
                if (mode == CardMode.approved)
                  Text(
                    '${event.availableSeats}/${event.totalSeats} seats',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}