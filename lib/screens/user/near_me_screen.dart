
import 'dart:async';
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
  final MapController  _mapController       = MapController();
  final Distance       _distance            = const Distance();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  Position? _currentPosition;
  bool      _isLocating = true;
  String    _errorMsg   = '';
  double    _radiusKm   = 10.0;
  String    _selectedCat = 'All';
  Event?    _selectedEvent; // highlighted pin

  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  final List<String> _categories = [
    'All', 'Technology', 'Music', 'Sports', 'Arts',
    'Food & Drink', 'Business', 'Health', 'Education', 'Entertainment',
  ];

  // Category → color
  static const Map<String, Color> _catColors = {
    'Music':         Color(0xFF42A5F5),
    'Sports':        Color(0xFF66BB6A),
    'Arts':          Color(0xFFEC407A),
    'Technology':    Color(0xFF26A69A),
    'Food & Drink':  Color(0xFFFFA726),
    'Business':      Color(0xFF5C6BC0),
    'Health':        Color(0xFFEF5350),
    'Education':     Color(0xFF00BCD4),
    'Entertainment': Color(0xFFAB47BC),
    'Other':         Color(0xFF7E57C2),
  };

  Color _color(String cat) => _catColors[cat] ?? Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final p = Provider.of<EventProvider>(context, listen: false);
    if (p.events.isEmpty) await p.fetchEvents();
    await _locate();
  }

  Future<void> _locate() async {
    if (!mounted) return;
    setState(() { _isLocating = true; _errorMsg = ''; });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _errorMsg = 'Location permission denied.'; _isLocating = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 12));
      if (!mounted) return;
      setState(() { _currentPosition = pos; _isLocating = false; });
      _mapController.move(LatLng(pos.latitude, pos.longitude), _zoom(_radiusKm));
    } catch (_) {
      if (mounted) setState(() { _errorMsg = 'Could not get location.'; _isLocating = false; });
    }
  }

  double _dist(Event e) {
    if (_currentPosition == null || (e.latitude == 0 && e.longitude == 0)) return 0;
    return _distance.as(
      LengthUnit.Kilometer,
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(e.latitude, e.longitude),
    );
  }

  List<Event> get _nearby {
    final all = Provider.of<EventProvider>(context, listen: false).events;
    return all.where((e) {
      if (e.latitude == 0 && e.longitude == 0) return false;
      if (_selectedCat != 'All' && e.category != _selectedCat) return false;
      if (_currentPosition != null && _dist(e) > _radiusKm) return false;
      return true;
    }).toList()..sort((a, b) => _dist(a).compareTo(_dist(b)));
  }

  double _zoom(double r) {
    if (r <= 2)  return 14.5;
    if (r <= 5)  return 13.0;
    if (r <= 10) return 12.0;
    if (r <= 25) return 11.0;
    if (r <= 50) return 10.0;
    return 9.0;
  }

  void _goToEvent(Event e) {
    setState(() => _selectedEvent = e);
    _mapController.move(LatLng(e.latitude, e.longitude), 14.0);
    // collapse sheet so user sees the map
    _sheetController.animateTo(0.12,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(children: [

        // ── Full screen map ─────────────────────────────────
        _buildMap(),

        // ── Top bar ─────────────────────────────────────────
        _buildTopBar(),

        // ── Category + radius filter row ────────────────────
        _buildFilterBar(),

        // ── Draggable bottom sheet ───────────────────────────
        _buildBottomSheet(),

        // ── Locating overlay ─────────────────────────────────
        if (_isLocating) _buildLoadingOverlay(),
      ]),
    );
  }

  // ── Top bar ───────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          // Back button
          _circlBtn(Icons.arrow_back_ios_new_rounded, Colors.white, () => Navigator.pop(context)),
          const SizedBox(width: 8),
          // Title card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
              ),
              child: Consumer<EventProvider>(
                builder: (_, p, __) {
                  final count = _nearby.length;
                  return Row(children: [
                    Icon(Icons.location_on_rounded, color: Colors.deepPurple.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text('Near Me',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15, color: Colors.deepPurple.shade800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count events',
                          style: TextStyle(color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ]);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // My location button
          _circlBtn(Icons.my_location_rounded, Colors.deepPurple.shade700, _locate,
              bg: Colors.white),
        ]),
      ),
    );
  }

  Widget _circlBtn(IconData icon, Color iconColor, VoidCallback onTap, {Color? bg}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: bg ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      );

  // ── Filter bar: categories + radius ──────────────────
  Widget _buildFilterBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 68),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = _selectedCat == cat;
                return GestureDetector(
                  onTap: () => setState(() { _selectedCat = cat; _selectedEvent = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? Colors.deepPurple.shade700 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6)],
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.grey.shade700,
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Radius slider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6)],
            ),
            child: Row(children: [
              Icon(Icons.radar_rounded, size: 16, color: Colors.deepPurple.shade700),
              const SizedBox(width: 6),
              Text('${_radiusKm.toStringAsFixed(0)} km',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                      color: Colors.deepPurple.shade700)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.deepPurple.shade400,
                    inactiveTrackColor: Colors.deepPurple.shade100,
                    thumbColor: Colors.deepPurple.shade700,
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _radiusKm, min: 1, max: 100, divisions: 99,
                    onChanged: (v) {
                      setState(() { _radiusKm = v; _selectedEvent = null; });
                      if (_currentPosition != null) {
                        _mapController.move(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          _zoom(v),
                        );
                      }
                    },
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Map ───────────────────────────────────────────────
  Widget _buildMap() {
    final pos = _currentPosition;
    final center = pos != null ? LatLng(pos.latitude, pos.longitude) : _defaultCenter;
    final events = _nearby;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _zoom(_radiusKm),
        onTap: (_, __) => setState(() => _selectedEvent = null),
      ),
      children: [

        // OSM tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.eventfinder.app',
        ),

        // Radius circle
        if (pos != null)
          CircleLayer(circles: [
            CircleMarker(
              point: LatLng(pos.latitude, pos.longitude),
              radius: _radiusKm * 1000,
              useRadiusInMeter: true,
              color: Colors.deepPurple.withOpacity(0.07),
              borderColor: Colors.deepPurple.withOpacity(0.5),
              borderStrokeWidth: 2,
            ),
          ]),

        // Markers
        MarkerLayer(markers: [

          // User dot
          if (pos != null)
            Marker(
              point: LatLng(pos.latitude, pos.longitude),
              width: 50, height: 50,
              child: Stack(alignment: Alignment.center, children: [
                Container(width: 50, height: 50,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.blue.withOpacity(0.2))),
                Container(width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 13)),
              ]),
            ),

          // Event pins
          ...events.map((e) {
            final color  = _color(e.category);
            final isSelected = _selectedEvent?.id == e.id;
            return Marker(
              point: LatLng(e.latitude, e.longitude),
              width: isSelected ? 52 : 42,
              height: isSelected ? 62 : 52,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedEvent = e);
                  // expand sheet slightly so event card is visible
                  _sheetController.animateTo(0.45,
                      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Column(children: [
                    Container(
                      width: isSelected ? 44 : 34, height: isSelected ? 44 : 34,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : Colors.white,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [BoxShadow(
                            color: color.withOpacity(isSelected ? 0.6 : 0.4),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3))],
                      ),
                      child: Icon(Icons.event_rounded,
                          color: isSelected ? color : Colors.white,
                          size: isSelected ? 22 : 17),
                    ),
                    // Pin tail
                    CustomPaint(
                      size: Size(isSelected ? 14 : 10, isSelected ? 9 : 7),
                      painter: _TailPainter(isSelected ? color.withOpacity(0.8) : color),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ]),

        // OSM attribution (required)
        const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
      ],
    );
  }

  // ── Draggable bottom sheet ─────────────────────────────
  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.28,
      minChildSize: 0.12,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.12, 0.28, 0.55, 0.75],
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20)],
          ),
          child: Consumer<EventProvider>(
            builder: (_, provider, __) {
              final events = _nearby;
              return CustomScrollView(
                controller: scrollCtrl,
                slivers: [

                  // Handle + header
                  SliverToBoxAdapter(child: Column(children: [
                    const SizedBox(height: 10),
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Text('Events Nearby',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                                color: Colors.grey.shade800)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${events.length} found',
                              style: TextStyle(color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.grey.shade100),
                  ])),

                  // Error message
                  if (_errorMsg.isNotEmpty)
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMsg,
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 13))),
                          GestureDetector(onTap: _locate,
                            child: Text('Retry', style: TextStyle(
                                color: Colors.orange.shade700, fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline, fontSize: 13))),
                        ]),
                      ),
                    )),

                  // Empty state
                  if (events.isEmpty && !_isLocating)
                    SliverFillRemaining(child: Center(child: Column(
                      mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No events within ${_radiusKm.toStringAsFixed(0)} km',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        const SizedBox(height: 6),
                        Text('Try increasing the radius',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ))),

                  // Event cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _EventCard(
                          event: events[i],
                          distKm: _dist(events[i]),
                          color: _color(events[i].category),
                          isSelected: _selectedEvent?.id == events[i].id,
                          onTap: () => _goToEvent(events[i]),
                          onDetailTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  EventDetailScreen(event: events[i]))),
                        ),
                        childCount: events.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ── Loading overlay ───────────────────────────────────
  Widget _buildLoadingOverlay() => Container(
    color: Colors.black.withOpacity(0.35),
    child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      SizedBox(height: 14),
      Text('Getting your location…',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
    ])),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.distKm,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.onDetailTap,
  });

  final Event    event;
  final double   distKm;
  final Color    color;
  final bool     isSelected;
  final VoidCallback onTap;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: [BoxShadow(
            color: isSelected
                ? color.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 2),
          )],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [

            // Category icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_rounded, color: color, size: 26),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category + distance
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(event.category,
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Icon(Icons.navigation_rounded, size: 11, color: Colors.blue.shade600),
                const SizedBox(width: 2),
                Text('${distKm.toStringAsFixed(1)} km',
                    style: TextStyle(color: Colors.blue.shade700,
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 5),

              // Title
              Text(event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),

              // Location
              Row(children: [
                Icon(Icons.place_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Expanded(child: Text(event.location,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            const SizedBox(width: 10),

            // Right side: price + arrow
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                event.isFree ? 'FREE' : 'Rs.${event.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 13,
                  color: event.isFree ? Colors.green.shade600 : Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('View',
                      style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}