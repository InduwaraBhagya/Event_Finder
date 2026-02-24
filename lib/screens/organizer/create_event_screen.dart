// FILE: lib/screens/organizer/create_event_screen.dart
// CHANGED FROM ORIGINAL:
//   1. Added: dart:io import
//   2. Added: image_picker import
//   3. Added: _picker, _imageFile fields
//   4. Added: _pickImage(), _showImageSourceSheet(), _sourceBtn() methods
//   5. _submitEvent(): sends multipart if image selected, JSON if not
//   6. _buildPage1(): added image picker section at top
//   7. _buildPage3(): added image status row in summary
// Everything else is IDENTICAL to your original file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';          // NEW
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
  final _picker         = ImagePicker();                  // NEW

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
  File?      _imageFile;                                  // NEW

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

  // ════════════════════════════════════════════════════════════
  // NEW: Image picker methods
  // ════════════════════════════════════════════════════════════

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source:       source,
        imageQuality: 85,     // compress slightly to reduce upload time
        maxWidth:     1200,
        maxHeight:    800,
      );
      if (picked != null) setState(() => _imageFile = File(picked.path));
    } catch (e) {
      _showError('Could not pick image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Text('Event Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _sourceBtn(
                icon: Icons.photo_library_rounded, label: 'Gallery',
                color: Colors.blue.shade600,
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              _sourceBtn(
                icon: Icons.camera_alt_rounded, label: 'Camera',
                color: Colors.green.shade600,
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              if (_imageFile != null)
                _sourceBtn(
                  icon: Icons.delete_outline_rounded, label: 'Remove',
                  color: Colors.red.shade600,
                  onTap: () { Navigator.pop(context); setState(() => _imageFile = null); },
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sourceBtn({
    required IconData icon, required String label,
    required Color color, required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      );

  // ════════════════════════════════════════════════════════════
  // ORIGINAL methods — unchanged
  // ════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════
  // CHANGED: _submitEvent
  // If image selected → sends multipart/form-data → backend
  //   uploads to Cloudinary via multer → URL saved in images[]
  // If no image → sends normal JSON (same as before)
  // ApiClient reads token from StorageService internally — no
  // AuthProvider needed here
  // ════════════════════════════════════════════════════════════
  Future<void> _submitEvent() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final seats = int.tryParse(_seatsCtrl.text.trim())    ?? 0;
      final price = _isFree ? 0.0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0.0);

      Map<String, dynamic> response;

      if (_imageFile != null) {
        // ── WITH IMAGE ────────────────────────────────────────
        // multipart/form-data → backend multer → Cloudinary
        // req.file.path on backend = Cloudinary URL
        // saved in event.images[0]
        response = await _apiClient.postMultipart(
          AppConfig.eventsEndpoint,
          fields: {
            'title':          _titleCtrl.text.trim(),
            'description':    _descCtrl.text.trim(),
            'category':       _selectedCategory,
            'date':           _selectedDate!.toIso8601String(),
            'time':           _formatTime(_selectedTime!),
            'location':       _locationCtrl.text.trim(),
            'latitude':       _latCtrl.text.trim().isEmpty ? '0' : _latCtrl.text.trim(),
            'longitude':      _lngCtrl.text.trim().isEmpty ? '0' : _lngCtrl.text.trim(),
            'price':          price.toString(),
            'totalSeats':     seats.toString(),
            'availableSeats': seats.toString(),
          },
          imageFile:    _imageFile,
          fileFieldName: 'image',   // ← must match upload.single('image') in your routes/events.js
          requiresAuth: true,
        );
      } else {
        // ── WITHOUT IMAGE ─────────────────────────────────────
        // Same JSON POST as your original code
        response = await _apiClient.post(
          AppConfig.eventsEndpoint,
          {
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
          },
          requiresAuth: true,
        );
      }

      print('✅ Response: $response');

      if (mounted) {
        setState(() => _isLoading = false);
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

  void _showPendingDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
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
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
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

  // ════════════════════════════════════════════════════════════
  // BUILD — identical to original
  // ════════════════════════════════════════════════════════════
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
                          Text('Uploading...', style: TextStyle(fontSize: 15)),
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

  // ════════════════════════════════════════════════════════════
  // PAGE 1 — CHANGED: image picker added at top, rest identical
  // ════════════════════════════════════════════════════════════
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _card(children: [

        // ── NEW: Image upload ─────────────────────────────────
        _label('Event Image (Optional)'),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imageFile != null
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                width: _imageFile != null ? 2 : 1.5,
              ),
            ),
            child: _imageFile != null
                // Preview of picked image
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.file(_imageFile!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.black.withOpacity(0.5),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('Tap to change',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  )
                // Empty placeholder
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 48,
                        color: AppTheme.primaryColor.withOpacity(0.4)),
                    const SizedBox(height: 10),
                    Text('Tap to add event image',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Uploaded to Cloudinary  •  JPG or PNG',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11)),
                  ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── ORIGINAL fields unchanged ─────────────────────────
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

  // ════════════════════════════════════════════════════════════
  // PAGE 2 — identical to original
  // ════════════════════════════════════════════════════════════
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
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
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

  // ════════════════════════════════════════════════════════════
  // PAGE 3 — CHANGED: image row added in summary, rest identical
  // ════════════════════════════════════════════════════════════
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
              title: const Text('Free Event',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_isFree ? 'Free for attendees' : 'Set price below',
                  style: const TextStyle(fontSize: 12)),
              value: _isFree, activeColor: Colors.green,
              onChanged: (v) => setState(() {
                _isFree = v; if (v) _priceCtrl.text = '0';
              }),
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
          // NEW: image status in summary
          _reviewRow(Icons.image_rounded, 'Image',
              _imageFile != null ? '✅ Image selected' : 'No image (optional)'),
          // ORIGINAL rows unchanged
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

  // ════════════════════════════════════════════════════════════
  // Helpers — identical to original
  // ════════════════════════════════════════════════════════════
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
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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