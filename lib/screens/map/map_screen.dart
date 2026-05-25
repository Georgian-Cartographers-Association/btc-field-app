import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../models/btk_record.dart';
import '../../providers/btk_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/raster_provider.dart';
import '../form/btk_form_screen.dart';
import '../pdf/pdf_viewer_screen.dart';
import '../raster/raster_manager_screen.dart';
import '../records/records_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/layer_control_panel.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _addingPoint = false;
  List<List<LatLng>> _boundaryPolygons = [];
  // Cache: raster id → loaded image bytes
  final Map<String, Uint8List> _rasterCache = {};

  @override
  void initState() {
    super.initState();
    _loadBoundary();
  }

  Future<void> _loadBoundary() async {
    try {
      final raw = await rootBundle.loadString(AppConstants.geojsonAssetPath);
      final geo = jsonDecode(raw) as Map<String, dynamic>;
      final features = geo['features'] as List<dynamic>;
      final polys = <List<LatLng>>[];
      for (final f in features) {
        final geom = f['geometry'] as Map<String, dynamic>;
        final type = geom['type'] as String;
        final coords = geom['coordinates'] as List<dynamic>;
        if (type == 'Polygon') {
          polys.add(_parseRing(coords[0] as List<dynamic>));
        } else if (type == 'MultiPolygon') {
          for (final poly in coords) {
            polys.add(_parseRing((poly as List<dynamic>)[0] as List<dynamic>));
          }
        }
      }
      if (mounted) setState(() => _boundaryPolygons = polys);
    } catch (_) {}
  }

  List<LatLng> _parseRing(List<dynamic> ring) =>
      ring.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

  List<Widget> _buildRasterLayers() {
    final rasters = ref.watch(rasterProvider);
    final widgets = <Widget>[];
    for (final r in rasters) {
      if (!r.visible) continue;
      final bytes = _rasterCache[r.id];
      if (bytes == null) {
        // Trigger async load; once done, setState rebuilds the layer
        ref.read(rasterProvider.notifier).loadImageBytes(r).then((b) {
          if (b != null && mounted) {
            setState(() => _rasterCache[r.id] = b);
          }
        });
        continue;
      }
      widgets.add(
        Opacity(
          opacity: r.opacity,
          child: OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: LatLngBounds(
                  LatLng(r.southLat, r.westLon),
                  LatLng(r.northLat, r.eastLon),
                ),
                imageProvider: MemoryImage(bytes),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _goToMyLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
  }

  void _onMapTap(TapPosition _, LatLng latlng) async {
    if (!_addingPoint) return;
    setState(() => _addingPoint = false);
    final record = await ref.read(btkProvider.notifier).add(lat: latlng.latitude, lon: latlng.longitude);
    if (!mounted) return;
    _openForm(record);
  }

  void _openForm(BtkRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BtkFormScreen(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layers = ref.watch(mapLayersProvider);
    final records = ref.watch(btkProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: AppConstants.georgiaCenter,
              initialZoom: AppConstants.defaultZoom,
              minZoom: AppConstants.minZoom,
              maxZoom: AppConstants.maxZoom,
              onTap: _onMapTap,
            ),
            children: [
              if (layers.showOsm)
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: 'ge.cartographers.btk',
                ),
              if (layers.showTopo)
                Opacity(
                  opacity: 0.85,
                  child: TileLayer(
                    urlTemplate: AppConstants.topoTileUrl,
                    subdomains: AppConstants.topoSubdomains,
                    userAgentPackageName: 'ge.cartographers.btk',
                  ),
                ),
              if (layers.showBoundary && _boundaryPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _boundaryPolygons
                      .map((pts) => Polygon(
                            points: pts,
                            borderColor: Colors.blue.shade700,
                            borderStrokeWidth: 2.0,
                            color: Colors.blue.withValues(alpha: 0.04),
                          ))
                      .toList(),
                ),
              // Local raster overlays
              ..._buildRasterLayers(),
              if (layers.showPoints)
                MarkerLayer(
                  markers: records.map((r) {
                    if (r.latitude == null) return null;
                    return Marker(
                      point: LatLng(r.latitude!, r.longitude!),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _openForm(r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                          ),
                          child: const Icon(Icons.location_pin, color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
            ],
          ),

          // Adding point hint
          if (_addingPoint)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'რუკაზე დააჭირეთ წერტილის დასამატებლად',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
            ),

          // Right-side action buttons (matching screenshot layout)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                      _mapController.camera.center, _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                      _mapController.camera.center, _mapController.camera.zoom - 1),
                ),
                const SizedBox(height: 16),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.layers_outlined,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => const LayerControlPanel(),
                  ),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.menu_book_outlined,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PdfViewerScreen())),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.satellite_alt_outlined,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const RasterManagerScreen())),
                ),
              ],
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BottomBarButton(
                      icon: Icons.map_outlined,
                      label: 'რუკა',
                      selected: true,
                      onTap: () {},
                    ),
                    _BottomBarButton(
                      icon: Icons.list_alt_outlined,
                      label: 'ჩანაწერები',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const RecordsScreen())),
                    ),
                    // Central add button
                    GestureDetector(
                      onTap: () => setState(() => _addingPoint = !_addingPoint),
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _addingPoint
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                        ),
                        child: Icon(
                          _addingPoint ? Icons.close : Icons.add_location_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    _BottomBarButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'მეთოდიკა',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const PdfViewerScreen())),
                    ),
                    _BottomBarButton(
                      icon: Icons.settings_outlined,
                      label: 'პარამ.',
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}
