// FILE: lib/screens/organizer/create_event_screen.dart
// PURPLE COLORFUL REDESIGN — all purple shades throughout

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:event_finder/services/api_client.dart';
import 'package:event_finder/config/app_config.dart';
import 'package:event_finder/utils/app_theme.dart';
import 'package:intl/intl.dart';

// ── Purple palette ─────────────────────────────────────
const _p1 = Color(0xFF6C3CE1); // deep purple
const _p2 = Color(0xFF9B59B6); // medium purple
const _p3 = Color(0xFFBB8FCE); // light purple
const _p4 = Color(0xFFF3E5F5); // lavender bg
const _p5 = Color(0xFF4A148C); // darkest purple
const _pGrad = [Color(0xFF6C3CE1), Color(0xFFB06AB3)]; // main gradient

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _apiClient      = ApiClient();
  final _pageController = PageController();
  final _picker         = ImagePicker();

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
  File?      _imageFile;

  final List<String> _categories = [
    'Technology', 'Music', 'Sports', 'Arts',
    'Food & Drink', 'Business', 'Health', 'Education',
    'Entertainment', 'Other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Technology':    Icons.computer_rounded,
    'Music':         Icons.music_note_rounded,
    'Sports':        Icons.sports_soccer_rounded,
    'Arts':          Icons.palette_rounded,
    'Food & Drink':  Icons.restaurant_rounded,
    'Business':      Icons.business_center_rounded,
    'Health':        Icons.favorite_rounded,
    'Education':     Icons.school_rounded,
    'Entertainment': Icons.theater_comedy_rounded,
    'Other':         Icons.event_rounded,
  };

  // Purple shades per category
  final Map<String, List<Color>> _catColors = {
    'Technology':    [Color(0xFF6C3CE1), Color(0xFF9B59B6)],
    'Music':         [Color(0xFF7B2D8B), Color(0xFFB06AB3)],
    'Sports':        [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    'Arts':          [Color(0xFF8E24AA), Color(0xFFBA68C8)],
    'Food & Drink':  [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    'Business':      [Color(0xFF4527A0), Color(0xFF7E57C2)],
    'Health':        [Color(0xFF880E4F), Color(0xFFAD1457)],
    'Education':     [Color(0xFF311B92), Color(0xFF512DA8)],
    'Entertainment': [Color(0xFF6A0080), Color(0xFF9C27B0)],
    'Other':         [Color(0xFF4A148C), Color(0xFF6C3CE1)],
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1200, maxHeight: 800);
      if (picked != null) setState(() => _imageFile = File(picked.path));
    } catch (e) {
      _showError('Could not pick image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _p3.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _pGrad),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.image_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Add Event Image',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _sourceBtn(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                colors: [Color(0xFF6C3CE1), Color(0xFF9B59B6)],
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              _sourceBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              if (_imageFile != null)
                _sourceBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove',
                  colors: [Color(0xFFAD1457), Color(0xFFC2185B)],
                  onTap: () { Navigator.pop(context); setState(() => _imageFile = null); },
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sourceBtn({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 66, height: 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: colors.first.withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: colors.first,
                  fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _p1)),
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
            colorScheme: const ColorScheme.light(primary: _p1)),
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
      if (_titleCtrl.text.trim().length < 5) { _showError('Title must be at least 5 characters'); return false; }
      if (_descCtrl.text.trim().length < 20)  { _showError('Description must be at least 20 characters'); return false; }
    } else if (_currentPage == 1) {
      if (_selectedDate == null)               { _showError('Please select a date'); return false; }
      if (_selectedTime == null)               { _showError('Please select a time'); return false; }
      if (_locationCtrl.text.trim().isEmpty)   { _showError('Please enter the location'); return false; }
      if (_latCtrl.text.trim().isEmpty || _lngCtrl.text.trim().isEmpty) { _showError('Please enter GPS coordinates'); return false; }
    } else if (_currentPage == 2) {
      if (!_isFree && double.tryParse(_priceCtrl.text.trim()) == null) { _showError('Please enter a valid price'); return false; }
      if ((int.tryParse(_seatsCtrl.text.trim()) ?? 0) < 1)             { _showError('Please enter valid number of seats'); return false; }
    }
    return true;
  }

  void _nextPage() {
    if (!_validatePage()) return;
    if (_currentPage < 2) {
      setState(() => _currentPage++);
      _pageController.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _submitEvent();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitEvent() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final seats = int.tryParse(_seatsCtrl.text.trim())    ?? 0;
      final price = _isFree ? 0.0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0.0);
      Map<String, dynamic> response;
      if (_imageFile != null) {
        response = await _apiClient.postMultipart(
          AppConfig.eventsEndpoint,
          fields: {
            'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(),
            'category': _selectedCategory, 'date': _selectedDate!.toIso8601String(),
            'time': _formatTime(_selectedTime!), 'location': _locationCtrl.text.trim(),
            'latitude': _latCtrl.text.trim().isEmpty ? '0' : _latCtrl.text.trim(),
            'longitude': _lngCtrl.text.trim().isEmpty ? '0' : _lngCtrl.text.trim(),
            'price': price.toString(), 'totalSeats': seats.toString(),
            'availableSeats': seats.toString(),
          },
          imageFile: _imageFile, fileFieldName: 'image', requiresAuth: true,
        );
      } else {
        response = await _apiClient.post(AppConfig.eventsEndpoint, {
          'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(),
          'category': _selectedCategory, 'date': _selectedDate!.toIso8601String(),
          'time': _formatTime(_selectedTime!), 'location': _locationCtrl.text.trim(),
          'latitude': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
          'longitude': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
          'price': price, 'totalSeats': seats, 'availableSeats': seats, 'images': [],
        }, requiresAuth: true);
      }
      if (mounted) {
        setState(() => _isLoading = false);
        final title = response['event']?['title'] ?? response['data']?['title'] ?? _titleCtrl.text;
        _showPendingDialog(title);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      final raw = e.toString().replaceAll('Exception: ', '');
      if (raw.contains('404'))        _showError('404: Check AppConfig.eventsEndpoint');
      else if (raw.contains('401'))   _showError('Session expired. Please log in again.');
      else if (raw.contains('403'))   _showError('Only organizers can create events.');
      else if (raw.contains('400'))   _showError('Missing required fields: $raw');
      else                            _showError('Error: $raw');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, maxLines: 4)),
      ]),
      backgroundColor: const Color(0xFFAD1457),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showPendingDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _pGrad),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: _p1.withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Colors.white, size: 52),
          ),
          const SizedBox(height: 20),
          const Text('Submitted for Review!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('"$title" has been sent to admin.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9B59B6), fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _p4,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _p3.withOpacity(0.5)),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info_outline, color: _p1, size: 14),
                SizedBox(width: 6),
                Text('What happens next:',
                    style: TextStyle(color: _p1, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              SizedBox(height: 8),
              Text('✅  Approved → Event goes live', style: TextStyle(color: _p2, fontSize: 12)),
              SizedBox(height: 4),
              Text('❌  Rejected → Check "My Events" for reason',
                  style: TextStyle(color: _p2, fontSize: 12)),
            ]),
          ),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _pGrad),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _p1.withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('OK, Got it! 🎉',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final stepLabels = ['Basic Info', 'Date & Location', 'Tickets'];
    final stepIcons  = [Icons.edit_note_rounded, Icons.place_rounded, Icons.confirmation_num_rounded];

    return Scaffold(
      backgroundColor: _p4,
      body: Column(children: [

        // ── Purple gradient header ─────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_p5, _p1, _p2],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(children: [

                // Top row
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Create Event',
                        style: TextStyle(color: Colors.white,
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_currentPage + 1} / 3',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 20),

                // Step pills
                Row(children: List.generate(3, (i) {
                  final isActive = i == _currentPage;
                  final isDone   = i < _currentPage;
                  return Expanded(
                    child: Row(children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                              vertical: isActive ? 10 : 8),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.white
                                : isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isActive
                                ? [BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_rounded : stepIcons[i],
                                size: 14,
                                color: isDone ? _p1 : isActive ? _p1 : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(stepLabels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDone ? _p1 : isActive ? _p1 : Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      if (i < 2)
                        Container(
                          width: 10, height: 2,
                          color: i < _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                    ]),
                  );
                })),
                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 5,
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Pages ──────────────────────────────────────
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [_buildPage1(), _buildPage2(), _buildPage3()],
          ),
        ),

        // ── Bottom nav ─────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12,
                offset: Offset(0, -4))],
          ),
          child: Row(children: [
            if (_currentPage > 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _prevPage,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _p1,
                    side: const BorderSide(color: _p1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _pGrad),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                      color: _p1.withOpacity(0.45),
                      blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                      : Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == 2 ? '🚀  Submit for Approval' : 'Continue',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            if (_currentPage < 2) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 1 — Basic Info
  // ══════════════════════════════════════════════════════
  Widget _buildPage1() {
    final catColors = _catColors[_selectedCategory] ?? _pGrad;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(children: [

        // Image picker
        _purpleCard(
          icon: Icons.image_rounded,
          title: 'Event Image',
          subtitle: 'Optional',
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: double.infinity, height: 165,
              decoration: BoxDecoration(
                color: _imageFile != null ? null : _p4,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _imageFile != null ? _p1 : _p3.withOpacity(0.5),
                  width: _imageFile != null ? 2 : 1.5,
                ),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.file(_imageFile!, fit: BoxFit.cover),
                        Positioned(bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [_p5.withOpacity(0.8), Colors.transparent],
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text('Tap to change',
                                    style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    )
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: _pGrad),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                              color: _p1.withOpacity(0.35),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.add_photo_alternate_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text('Tap to add event image',
                          style: TextStyle(color: _p2,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('JPG or PNG (up to 5MB)',
                          style: TextStyle(color: _p3, fontSize: 11)),
                    ]),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Title & description
        _purpleCard(
          icon: Icons.edit_note_rounded,
          title: 'Event Details',
          subtitle: 'Tell us about your event',
          child: Column(children: [
            _purpleField(
              controller: _titleCtrl,
              label: 'Event Title *',
              hint: 'e.g. Tech Conference 2026',
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 14),
            _purpleField(
              controller: _descCtrl,
              label: 'Description *',
              hint: 'Describe your event (min 20 characters)...',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Category chips
        _purpleCard(
          icon: _categoryIcons[_selectedCategory] ?? Icons.category_rounded,
          title: 'Category',
          subtitle: _selectedCategory,
          iconColors: catColors,
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = cat == _selectedCategory;
              final colors = _catColors[cat] ?? _pGrad;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: colors)
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : _p3.withOpacity(0.5),
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: colors.first.withOpacity(0.4),
                            blurRadius: 8, offset: const Offset(0, 3))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.04),
                            blurRadius: 4)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _categoryIcons[cat] ?? Icons.event_rounded,
                      size: 13,
                      color: isSelected ? Colors.white : _p2,
                    ),
                    const SizedBox(width: 5),
                    Text(cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : _p1,
                        )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 2 — Date & Location
  // ══════════════════════════════════════════════════════
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(children: [

        _purpleCard(
          icon: Icons.calendar_month_rounded,
          title: 'Date & Time',
          subtitle: 'When does it happen?',
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: _purplePickerBox(
                  icon: Icons.calendar_today_rounded, label: 'Date',
                  value: _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : 'Tap to select',
                  hasValue: _selectedDate != null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: _purplePickerBox(
                  icon: Icons.access_time_rounded, label: 'Time',
                  value: _selectedTime != null
                      ? _formatTime(_selectedTime!)
                      : 'Tap to select',
                  hasValue: _selectedTime != null,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        _purpleCard(
          icon: Icons.place_rounded,
          title: 'Location',
          subtitle: 'Where is your event?',
          child: Column(children: [
            _purpleField(
              controller: _locationCtrl,
              label: 'Venue / Location *',
              hint: 'e.g. BMICH, Colombo',
              icon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 14),
            Text('Right-click Google Maps → copy coordinates',
                style: TextStyle(color: _p3, fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _purpleField(
                controller: _latCtrl, label: 'Latitude', hint: '6.9271',
                icon: Icons.my_location_rounded,
                keyboard: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
              )),
              const SizedBox(width: 12),
              Expanded(child: _purpleField(
                controller: _lngCtrl, label: 'Longitude', hint: '79.8612',
                icon: Icons.my_location_rounded,
                keyboard: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
              )),
            ]),
            const SizedBox(height: 12),

            // Quick-fill Colombo
            GestureDetector(
              onTap: () {
                _latCtrl.text = '6.9271'; _lngCtrl.text = '79.8612';
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('📍 Set to Colombo, Sri Lanka'),
                  backgroundColor: _p1,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _p4,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _p3.withOpacity(0.5)),
                ),
                child: const Row(children: [
                  Icon(Icons.tips_and_updates_rounded, size: 16, color: _p1),
                  SizedBox(width: 8),
                  Text('Use Colombo, Sri Lanka coordinates',
                      style: TextStyle(color: _p1, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 3 — Tickets
  // ══════════════════════════════════════════════════════
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(children: [

        // Free toggle
        _purpleCard(
          icon: _isFree
              ? Icons.card_giftcard_rounded
              : Icons.monetization_on_rounded,
          title: 'Ticket Type',
          subtitle: _isFree ? 'Free admission' : 'Paid event',
          child: Container(
            decoration: BoxDecoration(
              color: _isFree ? _p4 : Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isFree ? _p1.withOpacity(0.4) : _p3.withOpacity(0.4)),
            ),
            child: SwitchListTile(
              title: Text(
                _isFree ? '🎁 Free Event' : '🎫 Paid Event',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _isFree ? 'Attendees can join for free' : 'Set ticket price below',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isFree,
              activeColor: _p1,
              onChanged: (v) => setState(() {
                _isFree = v;
                if (v) _priceCtrl.text = '0';
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (!_isFree) ...[
          _purpleCard(
            icon: Icons.payments_rounded,
            title: 'Ticket Price',
            subtitle: 'Rs. per seat',
            child: _purpleField(
              controller: _priceCtrl,
              label: 'Price per Ticket (Rs.) *',
              hint: 'e.g. 1500',
              icon: Icons.attach_money_rounded,
              keyboard: TextInputType.number,
            ),
          ),
          const SizedBox(height: 12),
        ],

        _purpleCard(
          icon: Icons.event_seat_rounded,
          title: 'Capacity',
          subtitle: 'Total seats available',
          child: _purpleField(
            controller: _seatsCtrl,
            label: 'Total Seats *',
            hint: 'e.g. 200',
            icon: Icons.people_rounded,
            keyboard: TextInputType.number,
          ),
        ),
        const SizedBox(height: 12),

        // Summary
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: _p1.withOpacity(0.12),
                blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: _pGrad),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Row(children: [
                Icon(Icons.summarize_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Event Summary',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _summaryRow(Icons.image_rounded, 'Image',
                    _imageFile != null ? '✅ Image ready' : 'No image'),
                _summaryRow(Icons.title_rounded, 'Title',
                    _titleCtrl.text.isEmpty ? '—' : _titleCtrl.text),
                _summaryRow(
                    _categoryIcons[_selectedCategory] ?? Icons.category_rounded,
                    'Category', _selectedCategory),
                _summaryRow(Icons.calendar_today_rounded, 'Date',
                    _selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                        : 'Not set'),
                _summaryRow(Icons.access_time_rounded, 'Time',
                    _selectedTime != null ? _formatTime(_selectedTime!) : 'Not set'),
                _summaryRow(Icons.location_on_rounded, 'Location',
                    _locationCtrl.text.isEmpty ? '—' : _locationCtrl.text),
                _summaryRow(Icons.payments_rounded, 'Price',
                    _isFree ? 'Free' : 'Rs. ${_priceCtrl.text}'),
                _summaryRow(Icons.event_seat_rounded, 'Seats',
                    _seatsCtrl.text.isEmpty ? '—' : _seatsCtrl.text),
              ]),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _p4,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _p3.withOpacity(0.5)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(Icons.admin_panel_settings_rounded, size: 16, color: _p1),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin must approve before this event is visible on the events page.',
                    style: TextStyle(color: _p2, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  Widget _purpleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    List<Color>? iconColors,
  }) {
    final colors = iconColors ?? _pGrad;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: _p1.withOpacity(0.1),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Purple header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 6),
            Text('· $subtitle',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 11)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ]),
    );
  }

  Widget _purpleField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: _p5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _p2, fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: _p3.withOpacity(0.7), fontSize: 13),
          prefixIcon: Icon(icon, color: _p1, size: 18),
          filled: true,
          fillColor: _p4,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _p3.withOpacity(0.4))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _p1, width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
      );

  Widget _purplePickerBox({
    required IconData icon,
    required String label,
    required String value,
    required bool hasValue,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasValue ? _p4 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? _p1.withOpacity(0.5) : _p3.withOpacity(0.4),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: hasValue
                  ? const LinearGradient(colors: _pGrad)
                  : null,
              color: hasValue ? null : _p4,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15,
                color: hasValue ? Colors.white : _p3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(
                  color: hasValue ? _p1 : _p3,
                  fontSize: 10, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(
                  color: hasValue ? _p5 : _p3,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12)),
            ]),
          ),
        ]),
      );

  Widget _summaryRow(IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: _p4, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: _p1),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text('$label:', style: const TextStyle(
                color: _p3, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12,
                color: value == '—' ? _p3 : _p5,
              ),
            ),
          ),
        ]),
      );
}