// FILE: lib/screens/organizer/create_event_screen.dart
// Organizer creates event → saved as 'pending' → admin must approve
// After approval it appears on the public events list

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _apiClient      = ApiClient();
  final _pageController = PageController();

  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _latCtrl      = TextEditingController();
  final _lngCtrl      = TextEditingController();
  final _priceCtrl    = TextEditingController(text: '0');
  final _seatsCtrl    = TextEditingController();

  String     _selectedCategory = 'Technology';
  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;
  bool       _isFree      = false;
  bool       _isLoading   = false;
  int        _currentPage = 0;

  final List<String> _categories = [
    'Technology', 'Music', 'Sports', 'Arts',
    'Food & Drink', 'Business', 'Health', 'Education',
    'Entertainment', 'Other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Technology':    Icons.computer,
    'Music':         Icons.music_note,
    'Sports':        Icons.sports,
    'Arts':          Icons.palette,
    'Food & Drink':  Icons.restaurant,
    'Business':      Icons.business_center,
    'Health':        Icons.favorite,
    'Education':     Icons.school,
    'Entertainment': Icons.theater_comedy,
    'Other':         Icons.event,
  };

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();    _descCtrl.dispose();
    _locationCtrl.dispose(); _latCtrl.dispose();
    _lngCtrl.dispose();      _priceCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor)),
        child: child!,
      ),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  bool _validatePage() {
    if (_currentPage == 0) {
      if (_titleCtrl.text.trim().length < 5) {
        _showError('Title must be at least 5 characters'); return false;
      }
      if (_descCtrl.text.trim().length < 20) {
        _showError('Description must be at least 20 characters'); return false;
      }
    } else if (_currentPage == 1) {
      if (_selectedDate == null) { _showError('Please select a date'); return false; }
      if (_selectedTime == null) { _showError('Please select a time'); return false; }
      if (_locationCtrl.text.trim().isEmpty) { _showError('Please enter the location'); return false; }
      if (_latCtrl.text.trim().isEmpty || _lngCtrl.text.trim().isEmpty) {
        _showError('Please enter GPS coordinates'); return false;
      }
    } else if (_currentPage == 2) {
      if (!_isFree && double.tryParse(_priceCtrl.text.trim()) == null) {
        _showError('Please enter a valid price'); return false;
      }
      if ((int.tryParse(_seatsCtrl.text.trim()) ?? 0) < 1) {
        _showError('Please enter valid number of seats'); return false;
      }
    }
    return true;
  }

  void _nextPage() {
    if (!_validatePage()) return;
    if (_currentPage < 2) {
      setState(() => _currentPage++);
      _pageController.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitEvent();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // ── Submit event ──────────────────────────────────────────────
  // Sends JSON body to POST /api/events
  // Backend sets status='pending' automatically
  // organizer is taken from auth token on backend (req.user.id)
  Future<void> _submitEvent() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final seats = int.tryParse(_seatsCtrl.text.trim())    ?? 0;
      final price = _isFree ? 0.0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0.0);

      final body = <String, dynamic>{
        'title':          _titleCtrl.text.trim(),
        'description':    _descCtrl.text.trim(),
        'category':       _selectedCategory,
        'date':           _selectedDate!.toIso8601String(),
        'time':           _formatTime(_selectedTime!),
        'location':       _locationCtrl.text.trim(),
        'latitude':       double.tryParse(_latCtrl.text.trim())  ?? 0.0,
        'longitude':      double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
        'price':          price,
        'totalSeats':     seats,
        'availableSeats': seats,
        'images':         [],
        // NOTE: organizer & organizerName are set by backend from auth token
        // status is set to 'pending' by backend automatically
      };

      print('📡 POST → ${AppConfig.eventsEndpoint}');
      print('📦 Body → $body');

      final response = await _apiClient.post(
        AppConfig.eventsEndpoint,   // e.g. '/api/events'
        body,
        requiresAuth: true,
      );

      print('✅ Response: $response');

      if (mounted) {
        setState(() => _isLoading = false);
        // Backend returns event in response['event'] or response['data']
        final title = response['event']?['title'] ??
            response['data']?['title'] ??
            _titleCtrl.text;
        _showPendingDialog(title);
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) setState(() => _isLoading = false);
      final raw = e.toString().replaceAll('Exception: ', '');
      if (raw.contains('404')) {
        _showError('404: Check AppConfig.eventsEndpoint in app_config.dart');
      } else if (raw.contains('401') || raw.toLowerCase().contains('unauthorized')) {
        _showError('Session expired. Please log out and log in again.');
      } else if (raw.contains('403')) {
        _showError('Only organizers can create events. Check your account role.');
      } else if (raw.contains('400')) {
        _showError('Missing required fields: $raw');
      } else {
        _showError('Error: $raw');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, maxLines: 5)),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Pending dialog — replaces old "Event Created!" green dialog ──
  // Clearly tells organizer it needs admin approval first
  void _showPendingDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Orange hourglass — NOT green checkmark
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.orange.shade50, shape: BoxShape.circle),
            child: Icon(Icons.hourglass_top_rounded,
                color: Colors.orange.shade600, size: 72),
          ),
          const SizedBox(height: 20),
          const Text('Submitted for Review! 🕐',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('"$title" has been sent to admin for approval.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 16),
          // Info box explaining what happens next
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 15),
                  SizedBox(width: 6),
                  Text('What happens next:',
                      style: TextStyle(color: Colors.blue,
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
                SizedBox(height: 8),
                Text('✅  Approved → Event goes live on events page',
                    style: TextStyle(color: Colors.blue, fontSize: 12)),
                SizedBox(height: 4),
                Text('❌  Rejected → Check "My Events" to see why',
                    style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
          ),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK, Got it!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = ['Basic Info', 'Date & Location', 'Tickets'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Create Event',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: Colors.grey[200],
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: Column(children: [
        // Step indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final isActive = i == _currentPage;
              final isDone   = i < _currentPage;
              return Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 36 : 32, height: isActive ? 36 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? Colors.green
                        : isActive ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}', style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                if (i < 2)
                  Container(width: 50, height: 2,
                      color: i < _currentPage ? Colors.green : Colors.grey.shade300),
              ]);
            }),
          ),
        ),
        Text(stepTitles[_currentPage],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 8),

        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [_buildPage1(), _buildPage2(), _buildPage3()],
          ),
        ),

        // Bottom buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: Row(children: [
            if (_currentPage > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _prevPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('← Back', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPage == 2
                      ? Colors.orange.shade600
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Submitting...', style: TextStyle(fontSize: 15)),
                        ])
                    : Text(
                        _currentPage == 2 ? '🚀  Submit for Approval' : 'Continue →',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // PAGE 1 — Basic Info
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _card(children: [
        _label('Event Title *'),
        _tf(_titleCtrl, hint: 'e.g. Tech Conference 2026', icon: Icons.title),
        const SizedBox(height: 16),
        _label('Category *'),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: _dec(hint: 'Select category', icon: Icons.category),
          items: _categories.map((c) => DropdownMenuItem(
            value: c,
            child: Row(children: [
              Icon(_categoryIcons[c], size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 10), Text(c),
            ]),
          )).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
        const SizedBox(height: 16),
        _label('Description *'),
        _tf(_descCtrl,
            hint: 'Describe your event (min 20 characters)...',
            icon: Icons.description, maxLines: 4),
      ]),
    );
  }

  // PAGE 2 — Date & Location
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _card(children: [
        _label('Date & Time *'),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _pickDate,
            child: _pickerBox(
              icon: Icons.calendar_today, label: 'Date',
              value: _selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                  : 'Tap to select',
              hasValue: _selectedDate != null),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: _pickTime,
            child: _pickerBox(
              icon: Icons.access_time, label: 'Time',
              value: _selectedTime != null
                  ? _formatTime(_selectedTime!) : 'Tap to select',
              hasValue: _selectedTime != null),
          )),
        ]),
        const SizedBox(height: 16),
        _label('Venue / Location *'),
        _tf(_locationCtrl, hint: 'e.g. BMICH, Colombo', icon: Icons.location_on),
        const SizedBox(height: 16),
        _label('GPS Coordinates *'),
        const Text('Right-click Google Maps → copy coordinates',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _tf(_latCtrl, hint: 'Latitude', icon: Icons.my_location,
              keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
          const SizedBox(width: 12),
          Expanded(child: _tf(_lngCtrl, hint: 'Longitude', icon: Icons.my_location,
              keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _latCtrl.text = '6.9271'; _lngCtrl.text = '79.8612';
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Set to Colombo, Sri Lanka'),
              behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
            ));
          },
          child: Row(children: [
            Icon(Icons.tips_and_updates, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text('Use Colombo, Sri Lanka coordinates',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12,
                    decoration: TextDecoration.underline)),
          ]),
        ),
      ]),
    );
  }

  // PAGE 3 — Tickets & Summary
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _card(children: [
          Container(
            decoration: BoxDecoration(
              color: _isFree ? Colors.green.withOpacity(0.08) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _isFree ? Colors.green : Colors.grey[300]!),
            ),
            child: SwitchListTile(
              title: const Text('Free Event', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_isFree ? 'Free for attendees' : 'Set price below',
                  style: const TextStyle(fontSize: 12)),
              value: _isFree, activeColor: Colors.green,
              onChanged: (v) => setState(() { _isFree = v; if (v) _priceCtrl.text = '0'; }),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isFree) ...[
            _label('Ticket Price (Rs.) *'),
            _tf(_priceCtrl, hint: 'e.g. 1500',
                icon: Icons.monetization_on, keyboard: TextInputType.number),
            const SizedBox(height: 16),
          ],
          _label('Total Seats *'),
          _tf(_seatsCtrl, hint: 'e.g. 200',
              icon: Icons.event_seat, keyboard: TextInputType.number),
        ]),
        const SizedBox(height: 16),
        _card(children: [
          const Text('Event Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _reviewRow(Icons.title,          'Title',    _titleCtrl.text),
          _reviewRow(Icons.category,       'Category', _selectedCategory),
          _reviewRow(Icons.calendar_today, 'Date',
              _selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'Not set'),
          _reviewRow(Icons.access_time, 'Time',
              _selectedTime != null ? _formatTime(_selectedTime!) : 'Not set'),
          _reviewRow(Icons.location_on, 'Location', _locationCtrl.text),
          _reviewRow(Icons.payments,    'Price',
              _isFree ? 'Free' : 'Rs. ${_priceCtrl.text}'),
          _reviewRow(Icons.event_seat,  'Seats', _seatsCtrl.text),
          const SizedBox(height: 12),
          // Admin approval notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Admin must approve before this event is visible on the events page.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              )),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _tf(TextEditingController ctrl, {
    required String hint, required IconData icon,
    int maxLines = 1, TextInputType keyboard = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
        onChanged: (_) => setState(() {}),
        decoration: _dec(hint: hint, icon: icon),
      );

  Widget _pickerBox({required IconData icon, required String label,
      required String value, required bool hasValue}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: hasValue
              ? AppTheme.primaryColor.withOpacity(0.5) : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: hasValue ? AppTheme.primaryColor : Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(
                color: hasValue ? Colors.black87 : Colors.grey[500],
                fontWeight: FontWeight.w500, fontSize: 13)),
          ])),
        ]),
      );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );

  InputDecoration _dec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[350]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _reviewRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppTheme.primaryColor),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text('$label:',
          style: TextStyle(color: Colors.grey[600], fontSize: 13))),
      Expanded(child: Text(value.isEmpty ? '—' : value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}