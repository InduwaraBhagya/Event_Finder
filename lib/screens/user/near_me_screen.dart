import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/event_provider.dart';
import 'package:event_finder/models/event_model.dart';
import 'package:event_finder/screens/user/event_detail_screen.dart';

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({super.key});

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  final MapController _mapController = MapController();

  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isLoadingEvents   = false;
  String _errorMessage    = '';

  double _radiusKm         = 10.0; // ✅ Start at 10km — visible on map
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Technology', 'Music', 'Sports', 'Arts',
    'Food & Drink', 'Business', 'Health', 'Education',
    'Entertainment', 'Other',
  ];

  // Colombo default
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadEventsFromProvider();
      await _getUserLocation();
    });
  }

  Future<void> _loadEventsFromProvider() async {
    if (!mounted) return;
    setState(() => _isLoadingEvents = true);
    try {
      final provider = Provider.of<EventProvider>(context, listen: false);
      if (provider.events.isEmpty) await provider.fetchEvents();
    } catch (e) {
      debugPrint('Event load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _getUserLocation() async {
    if (!mounted) return;
    setState(() { _isLoadingLocation = true; _errorMessage = ''; });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() {
          _errorMessage = 'GPS is off. Please turn on Location Services.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorMessage = permission == LocationPermission.deniedForever
                ? 'Location permanently denied. Enable in App Settings.'
                : 'Location permission denied.';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // ✅ Zoom level 12 shows ~10km radius nicely
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        12.0,
      );
    } on TimeoutException {
      if (mounted) setState(() {
        _errorMessage = 'Location timed out. Showing default map.';
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _errorMessage = 'Could not get location. Showing default map.';
        _isLoadingLocation = false;
      });
    }
  }

  // ── Haversine ─────────────────────────────────────────
  double _getDistance(Event event) {
    if (event.distance != null && event.distance! > 0) return event.distance!;
    if (_currentPosition == null) return 0;
    if (event.latitude == 0.0 && event.longitude == 0.0) return 0;
    const R = 6371.0;
    final lat1 = _currentPosition!.latitude * pi / 180;
    final lat2 = event.latitude * pi / 180;
    final dLat = (event.latitude - _currentPosition!.latitude) * pi / 180;
    final dLon = (event.longitude - _currentPosition!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  List<Event> get _filteredEvents {
    final provider = Provider.of<EventProvider>(context, listen: false);
    return provider.events.where((event) {
      if (event.latitude == 0.0 && event.longitude == 0.0) return false;
      if (_selectedCategory != 'All' && event.category != _selectedCategory) return false;
      if (_currentPosition != null && _getDistance(event) > _radiusKm) return false;
      return true;
    }).toList()
      ..sort((a, b) => _getDistance(a).compareTo(_getDistance(b)));
  }

  // ✅ Zoom level that fits radius on screen properly
  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 1)  return 15.0;
    if (radiusKm <= 2)  return 14.0;
    if (radiusKm <= 5)  return 13.0;
    if (radiusKm <= 10) return 12.0;
    if (radiusKm <= 20) return 11.0;
    if (radiusKm <= 40) return 10.0;
    if (radiusKm <= 80) return 9.0;
    return 8.0;
  }

  Color _categoryColor(String category) {
    const map = {
      'Music':         Color(0xFF42A5F5),
      'Sports':        Color(0xFF66BB6A),
      'Arts':          Color(0xFFEC407A),
      'Technology':    Color(0xFF26A69A),
      'Food & Drink':  Color(0xFFFFA726),
      'Business':      Color(0xFF5C6BC0),
      'Health':        Color(0xFFEF5350),
      'Education':     Color(0xFF00BCD4),
      'Entertainment': Color(0xFFAB47BC),
    };
    return map[category] ?? Colors.deepPurple;
  }

  void _showEventBottomSheet(Event event) {
    final dist = _getDistance(event);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor(event.category).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(event.category,
                    style: TextStyle(
                        color: _categoryColor(event.category),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.location_on, size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 3),
                  Text('${dist.toStringAsFixed(1)} km away',
                      style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Text(event.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.place, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(event.location,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.event_seat, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                event.isAvailable
                    ? '${event.availableSeats} seats available'
                    : 'Sold out',
                style: TextStyle(
                    color: event.isAvailable ? Colors.green.shade600 : Colors.red,
                    fontSize: 13),
              ),
            ]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event.isFree ? '🎉 FREE' : 'Rs. ${event.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: Colors.deepPurple),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EventDetailScreen(event: event)));
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Near Me',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () async {
              await _loadEventsFromProvider();
              await _getUserLocation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'Center on me',
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  _zoomForRadius(_radiusKm),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(flex: 3, child: _buildMapSection()),
          Expanded(flex: 2, child: _buildEventsList()),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  selectedColor: Colors.deepPurple.shade100,
                  visualDensity: VisualDensity.compact,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.deepPurple.shade800
                        : Colors.grey.shade700,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 2),

          // ✅ Radius slider — with auto zoom when changed
          Row(children: [
            const Icon(Icons.radar, size: 16, color: Colors.deepPurple),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              child: Text(
                'Radius: ${_radiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Expanded(
              child: Slider(
                value: _radiusKm,
                min: 1, max: 100, divisions: 99,
                activeColor: Colors.deepPurple,
                inactiveColor: Colors.deepPurple.shade100,
                onChanged: (val) {
                  setState(() => _radiusKm = val);
                  // ✅ Auto-zoom map to show the new radius
                  if (_currentPosition != null) {
                    _mapController.move(
                      LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      _zoomForRadius(val),
                    );
                  }
                },
              ),
            ),
            // ✅ Show event count badge
            Consumer<EventProvider>(
              builder: (_, provider, __) {
                final count = _filteredEvents.length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultCenter;

    return Stack(
      children: [
        // ✅ OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _zoomForRadius(_radiusKm),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [

            // OSM tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.eventfinder.app',
              maxZoom: 19,
            ),

            // ✅ Radius circle — shows search area
            if (_currentPosition != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    radius: _radiusKm * 1000, // in meters
                    useRadiusInMeter: true,
                    color: Colors.deepPurple.withOpacity(0.07),
                    borderColor: Colors.deepPurple.withOpacity(0.6),
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

            // ✅ Markers
            MarkerLayer(
              markers: [

                // User dot
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing ring
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        // Inner dot
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 8)
                            ],
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),

                // Event markers
                ..._filteredEvents.map((event) {
                  final color = _categoryColor(event.category);
                  return Marker(
                    point: LatLng(event.latitude, event.longitude),
                    width: 46,
                    height: 56, // taller to show pin shape
                    child: GestureDetector(
                      onTap: () {
                        // ✅ Animate to event then show sheet
                        _mapController.move(
                          LatLng(event.latitude, event.longitude),
                          14.0,
                        );
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _showEventBottomSheet(event);
                        });
                      },
                      child: Column(
                        children: [
                          // Pin bubble
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: const Icon(Icons.event,
                                color: Colors.white, size: 20),
                          ),
                          // Pin tail
                          CustomPaint(
                            size: const Size(12, 8),
                            painter: _PinTailPainter(color: color),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Loading overlay
        if (_isLoadingLocation)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 14),
                  Text('Getting your location...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),

        // Error banner
        if (_errorMessage.isNotEmpty && !_isLoadingLocation)
          Positioned(
            top: 8, left: 8, right: 8,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: _getUserLocation,
                    child: const Text('Retry',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            decoration: TextDecoration.underline)),
                  ),
                ]),
              ),
            ),
          ),

        // OSM attribution (required)
        Positioned(
          bottom: 4, right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Colors.black54)),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        if (_isLoadingEvents || provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple));
        }

        final filtered = _filteredEvents;
        final noCoords = provider.events
            .where((e) => e.latitude == 0.0 && e.longitude == 0.0)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${filtered.length}',
                          style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontSize: 16),
                        ),
                        const TextSpan(text: ' events within '),
                        TextSpan(
                          text: '${_radiusKm.toStringAsFixed(0)} km',
                          style: TextStyle(
                              color: Colors.deepPurple.shade700),
                        ),
                      ],
                    ),
                  ),
                  if (noCoords > 0)
                    Row(children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 3),
                      Text('$noCoords no GPS',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 11)),
                    ]),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 52, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text('No events within ${_radiusKm.toStringAsFixed(0)} km',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Try increasing the radius above',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final event = filtered[i];
                        return _EventCard(
                          event: event,
                          distanceKm: _getDistance(event),
                          categoryColor: _categoryColor(event.category),
                          onTap: () {
                            // ✅ Tap card → zoom map to event → show sheet
                            _mapController.move(
                              LatLng(event.latitude, event.longitude),
                              14.0,
                            );
                            Future.delayed(
                                const Duration(milliseconds: 300), () {
                              _showEventBottomSheet(event);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Pin tail painter ─────────────────────────────────────────────────────────
// ✅ Use ui.Path to avoid conflict with flutter_map's Path<LatLng> class
class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ── Event Card ────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.distanceKm,
    required this.categoryColor,
    required this.onTap,
  });

  final Event event;
  final double distanceKm;
  final Color categoryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          // Icon box
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.event, color: categoryColor, size: 26),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(event.category,
                    style: TextStyle(
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.place, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(event.location,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Distance badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.navigation,
                      size: 10, color: Colors.blue.shade700),
                  const SizedBox(width: 2),
                  Text('${distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                event.isFree ? 'FREE' : 'Rs.${event.price.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: event.isFree
                        ? Colors.green.shade700
                        : Colors.deepPurple.shade700),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: event.isAvailable
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.isAvailable
                      ? '${event.availableSeats} left'
                      : 'Full',
                  style: TextStyle(
                      fontSize: 10,
                      color: event.isAvailable
                          ? Colors.green.shade700
                          : Colors.red,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}