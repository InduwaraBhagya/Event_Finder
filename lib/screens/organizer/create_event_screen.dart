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
  final _formKey      = GlobalKey<FormState>();
  final _apiClient    = ApiClient();

  // Controllers
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _latCtrl         = TextEditingController();
  final _lngCtrl         = TextEditingController();
  final _priceCtrl       = TextEditingController(text: '0');
  final _seatsCtrl       = TextEditingController();

  // State
  String   _selectedCategory = 'Technology';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool     _isFree      = false;
  bool     _isLoading   = false;
  int      _currentStep = 0;  // stepper index

  // ── Categories matching backend enum ─────────────────
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
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _priceCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  // ── Date Picker ───────────────────────────────────────
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  // ── Time Picker ───────────────────────────────────────
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  // ── Format time to "HH:MM AM/PM" ─────────────────────
  String _formatTime(TimeOfDay t) {
    final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ── Submit to backend ─────────────────────────────────
  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select an event date');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select an event time');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = {
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category':    _selectedCategory,
        'date':        _selectedDate!.toIso8601String(),
        'time':        _formatTime(_selectedTime!),
        'location':    _locationCtrl.text.trim(),
        'latitude':    double.tryParse(_latCtrl.text.trim()) ?? 0.0,
        'longitude':   double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
        'price':       _isFree ? 0 : (double.tryParse(_priceCtrl.text.trim()) ?? 0),
        'totalSeats':  int.tryParse(_seatsCtrl.text.trim()) ?? 0,
      };

      print('📡 CreateEvent: Sending → $body');

      final response = await _apiClient.post(
        AppConfig.organizerEventsEndpoint,
        body,
        requiresAuth: true,   // ✅ organizer must be logged in
      );

      print('✅ CreateEvent: Response → $response');

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog(response['event']?['title'] ?? _titleCtrl.text);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final msg = e.toString().replaceAll('Exception: ', '');
      print('❌ CreateEvent: $msg');
      _showError(msg);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Text('Event Created!',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '"$title" has been saved to the database successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);   // close dialog
                Navigator.pop(context); // go back to organizer dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View My Events',
                  style: TextStyle(fontSize: 16)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[200],
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submitEvent();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (ctx, details) =>
              _buildStepControls(details),
          steps: [
            _step1BasicInfo(),
            _step2DateLocation(),
            _step3TicketReview(),
          ],
        ),
      ),
    );
  }

  // ── Step Controls ─────────────────────────────────────
  Widget _buildStepControls(ControlsDetails details) {
    final isLast = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // Continue / Submit
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading && isLast
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isLast ? '🚀 Create Event' : 'Continue',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // STEP 1 — Basic Info
  // ══════════════════════════════════════════════════════
  Step _step1BasicInfo() {
    return Step(
      title: const Text('Basic Info'),
      subtitle: const Text('Title, category & description'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _label('Event Title *'),
          TextFormField(
            controller: _titleCtrl,
            decoration: _inputDec(
                hint: 'e.g. Tech Conference 2026',
                icon: Icons.title),
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Title is required';
              if (v.trim().length < 5) return 'At least 5 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Category
          _label('Category *'),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: _inputDec(hint: 'Select category', icon: Icons.category),
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Row(children: [
                  Icon(_categoryIcons[cat], size: 18,
                      color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Text(cat),
                ]),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 20),

          // Description
          _label('Description *'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: _inputDec(
                hint: 'Describe your event in detail...',
                icon: Icons.description),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Description is required';
              if (v.trim().length < 20) return 'At least 20 characters';
              return null;
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // STEP 2 — Date, Time & Location
  // ══════════════════════════════════════════════════════
  Step _step2DateLocation() {
    return Step(
      title: const Text('Date & Location'),
      subtitle: const Text('When and where'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time row
          Row(
            children: [
              // Date picker
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date *',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('MMM dd, yyyy')
                                      .format(_selectedDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                color: _selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Time picker
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(Icons.access_time,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time *',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTime != null
                                  ? _formatTime(_selectedTime!)
                                  : 'Select Time',
                              style: TextStyle(
                                color: _selectedTime != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location
          _label('Venue / Location *'),
          TextFormField(
            controller: _locationCtrl,
            decoration: _inputDec(
                hint: 'e.g. BMICH, Colombo',
                icon: Icons.location_on),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Location is required' : null,
          ),
          const SizedBox(height: 20),

          // Lat / Lng
          _label('GPS Coordinates *'),
          const Text(
            'Find coordinates at maps.google.com → right-click location',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: _inputDec(hint: 'Latitude', icon: Icons.my_location),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = double.tryParse(v.trim());
                    if (val == null || val < -90 || val > 90) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: _inputDec(hint: 'Longitude', icon: Icons.my_location),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = double.tryParse(v.trim());
                    if (val == null || val < -180 || val > 180) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),

          // Sri Lanka quick-fill tip
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                _latCtrl.text = '6.9271';
                _lngCtrl.text = '79.8612';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📍 Set to Colombo, Sri Lanka'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to use Colombo, Sri Lanka coordinates',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // STEP 3 — Tickets & Review
  // ══════════════════════════════════════════════════════
  Step _step3TicketReview() {
    return Step(
      title: const Text('Tickets & Review'),
      subtitle: const Text('Pricing and final check'),
      isActive: _currentStep >= 2,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isFree
                  ? Colors.green.withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _isFree ? Colors.green : Colors.grey[300]!),
            ),
            child: SwitchListTile(
              title: const Text('Free Event',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _isFree
                    ? 'Attendees can book for free'
                    : 'Set a ticket price below',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isFree,
              activeColor: Colors.green,
              onChanged: (v) {
                setState(() {
                  _isFree = v;
                  if (v) _priceCtrl.text = '0';
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Price field (hidden when free)
          if (!_isFree) ...[
            _label('Ticket Price (Rs.) *'),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDec(
                  hint: 'e.g. 1500', icon: Icons.monetization_on),
              validator: (v) {
                if (_isFree) return null;
                if (v == null || v.trim().isEmpty) return 'Price is required';
                final val = double.tryParse(v.trim());
                if (val == null || val < 0) return 'Enter valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Total seats
          _label('Total Seats *'),
          TextFormField(
            controller: _seatsCtrl,
            keyboardType: TextInputType.number,
            decoration:
                _inputDec(hint: 'e.g. 200', icon: Icons.event_seat),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Seats are required';
              final val = int.tryParse(v.trim());
              if (val == null || val < 1) return 'At least 1 seat';
              if (val > 100000) return 'Maximum 100,000 seats';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // ── Review Summary ──────────────────────
          if (_titleCtrl.text.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('📋 Event Summary',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            _reviewRow(Icons.title,       'Title',    _titleCtrl.text),
            _reviewRow(Icons.category,    'Category', _selectedCategory),
            _reviewRow(Icons.calendar_today, 'Date',
                _selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                    : 'Not set'),
            _reviewRow(Icons.access_time, 'Time',
                _selectedTime != null
                    ? _formatTime(_selectedTime!)
                    : 'Not set'),
            _reviewRow(Icons.location_on, 'Location', _locationCtrl.text),
            _reviewRow(
              Icons.payments,
              'Price',
              _isFree
                  ? 'Free'
                  : 'Rs. ${_priceCtrl.text.isEmpty ? '0' : _priceCtrl.text}',
            ),
            _reviewRow(Icons.event_seat,  'Seats',    _seatsCtrl.text),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
      );

  InputDecoration _inputDec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[350]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _reviewRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text('$label:',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13)),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
}