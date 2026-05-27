import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../models/btk_record.dart';
import '../../models/raster_layer.dart';
import '../../models/tile_service.dart';
import '../../providers/btk_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/raster_provider.dart';
import '../../providers/tile_service_provider.dart';
import '../../utils/measurement_service.dart';
import '../form/btk_form_screen.dart';
import '../layers/layers_screen.dart';
import '../pdf/pdf_viewer_screen.dart';
import '../records/records_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/layer_control_panel.dart';
import 'widgets/measurement_layers.dart';
import 'widgets/measurement_panel.dart';
import 'widgets/weather_panel.dart';
import '../../services/analytics_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _addingPoint = false;

  // GeoJSON boundaries
  List<List<LatLng>> _boundaryPolygons = [];
  List<List<LatLng>> _regionPolygons = [];
  List<List<LatLng>> _municipalityPolygons = [];

  // Measurement
  MeasureMode _measureMode = MeasureMode.none;
  List<LatLng> _measurePoints = [];

  @override
  void initState() {
    super.initState();
    _loadGeojson(AppConstants.geojsonAssetPath, (p) => _boundaryPolygons = p);
    _loadGeojson(AppConstants.regionsGeojsonPath, (p) => _regionPolygons = p);
    _loadGeojson(AppConstants.municipalitiesGeojsonPath,
        (p) => _municipalityPolygons = p);
  }

  Future<void> _loadGeojson(
      String assetPath, void Function(List<List<LatLng>>) setter) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
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
      if (mounted) setState(() => setter(polys));
    } catch (_) {}
  }

  List<LatLng> _parseRing(List<dynamic> ring) =>
      ring.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

  // ── Raster / Tile layers ──────────────────────────────────────────────────

  ImageProvider _imageProviderFor(RasterLayer r) {
    if (r.assetPath != null) return AssetImage(r.assetPath!);
    if (!kIsWeb && r.filePath != null) return FileImage(File(r.filePath!));
    if (r.fileBytes != null) return MemoryImage(r.fileBytes!);
    return MemoryImage(Uint8List(0));
  }

  List<Widget> _buildAssetRasterLayers() {
    return ref
        .watch(rasterProvider)
        .where((r) => r.visible)
        .map((r) {
          final layer = OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: LatLngBounds(
                  LatLng(r.southLat, r.westLon),
                  LatLng(r.northLat, r.eastLon),
                ),
                imageProvider: _imageProviderFor(r),
              ),
            ],
          );
          return r.opacity < 0.999
              ? Opacity(opacity: r.opacity, child: layer)
              : layer;
        })
        .toList();
  }

  List<Widget> _buildTileServiceLayers() {
    return ref
        .watch(tileServiceProvider)
        .where((s) => s.visible)
        .map((s) {
          final Widget layer;
          if (s.serviceType == ServiceType.wms) {
            // Proper WMS GetMap request via WMSTileLayerOptions
            final baseUrl = s.urlTemplate.contains('?')
                ? s.urlTemplate
                : '${s.urlTemplate}?';
            final layerList = s.wmsLayers
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            layer = TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: baseUrl,
                layers: layerList,
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
              userAgentPackageName: 'ge.cartographers.btk',
            );
          } else {
            // XYZ / WMTS
            layer = TileLayer(
              urlTemplate: s.urlTemplate,
              subdomains: s.subdomains,
              userAgentPackageName: 'ge.cartographers.btk',
            );
          }
          return s.opacity < 0.999
              ? Opacity(opacity: s.opacity, child: layer)
              : layer;
        })
        .toList();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
    AnalyticsService.logGpsDetect();
  }

  // ── Map tap ──────────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng latlng) {
    // Measurement has priority
    if (_measureMode != MeasureMode.none) {
      setState(() {
        if (_measureMode == MeasureMode.coordinate) {
          _measurePoints = [latlng];
        } else {
          _measurePoints = [..._measurePoints, latlng];
        }
      });
      return;
    }
    if (!_addingPoint) return;
    setState(() => _addingPoint = false);
    ref
        .read(btkProvider.notifier)
        .add(lat: latlng.latitude, lon: latlng.longitude)
        .then((record) {
      AnalyticsService.logRecordCreated();
      if (!mounted) return;
      _openForm(record);
    });
  }

  void _openForm(BtkRecord record) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => BtkFormScreen(record: record)));
  }

  // ── Measurement ───────────────────────────────────────────────────────────

  void _toggleMeasure() {
    setState(() {
      if (_measureMode == MeasureMode.none) {
        _measureMode = MeasureMode.coordinate;
        _measurePoints = [];
        _addingPoint = false;
        AnalyticsService.logMeasurement('coordinate');
      } else {
        _measureMode = MeasureMode.none;
        _measurePoints = [];
      }
    });
  }

  // ── Weather ───────────────────────────────────────────────────────────────

  void _openWeather() {
    AnalyticsService.logWeatherViewed();
    final center = _mapController.camera.center;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => WeatherPanel(
        lat: center.latitude,
        lon: center.longitude,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layers = ref.watch(mapLayersProvider);
    final records = ref.watch(btkProvider);
    final measuring = _measureMode != MeasureMode.none;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
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
              // Base tile layers
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
              // WMS/WMTS tile services
              ..._buildTileServiceLayers(),
              // Admin boundaries (render bottom-up)
              if (layers.showMunicipalities && _municipalityPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _municipalityPolygons
                      .map((pts) => Polygon(
                            points: pts,
                            borderColor: Colors.green.shade700,
                            borderStrokeWidth: 0.8,
                            color: Colors.green.withValues(alpha: 0.04),
                          ))
                      .toList(),
                ),
              if (layers.showRegions && _regionPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _regionPolygons
                      .map((pts) => Polygon(
                            points: pts,
                            borderColor: Colors.orange.shade700,
                            borderStrokeWidth: 1.5,
                            color: Colors.orange.withValues(alpha: 0.05),
                          ))
                      .toList(),
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
              // Asset raster overlays
              ..._buildAssetRasterLayers(),
              // BTC markers
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
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, color: Colors.black26)
                            ],
                          ),
                          child: const Icon(Icons.location_pin,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              // Measurement overlay
              ...buildMeasurementLayers(
                mode: _measureMode,
                points: _measurePoints,
                scheme: Theme.of(context).colorScheme,
              ),
            ],
          ),

          // ── Adding point hint ───────────────────────────────────────────
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'რუკაზე დააჭირეთ წერტილის დასამატებლად',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                    ),
                  ),
                ),
              ),
            ),

          // ── Right-side buttons ──────────────────────────────────────────
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1),
                ),
                const SizedBox(height: 16),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
                const SizedBox(height: 8),
                // Weather forecast
                _MapButton(
                  icon: Icons.wb_cloudy_outlined,
                  onTap: _openWeather,
                ),
                const SizedBox(height: 8),
                // Raster + WMS services (above vector controls)
                _MapButton(
                  icon: Icons.travel_explore,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LayersScreen())),
                ),
                const SizedBox(height: 4),
                // Vector / admin layer toggles
                _MapButton(
                  icon: Icons.layers_outlined,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => const LayerControlPanel(),
                  ),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.menu_book_outlined,
                  onTap: () {
                    AnalyticsService.logPdfOpened();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PdfViewerScreen()));
                  },
                ),
                const SizedBox(height: 8),
                // Measurement button
                _MapButton(
                  icon: Icons.straighten,
                  active: measuring,
                  onTap: _toggleMeasure,
                ),
              ],
            ),
          ),

          // ── Measurement panel ───────────────────────────────────────────
          if (measuring)
            Positioned(
              bottom: 90,
              left: 12,
              right: 12,
              child: MeasurementPanel(
                mode: _measureMode,
                points: _measurePoints,
                onModeChanged: (m) =>
                    setState(() {
                      _measureMode = m;
                      _measurePoints = [];
                    }),
                onUndo: () => setState(() {
                  if (_measurePoints.isNotEmpty) _measurePoints.removeLast();
                }),
                onClear: () => setState(() => _measurePoints = []),
                onClose: _toggleMeasure,
              ),
            ),

          // ── Bottom navigation ───────────────────────────────────────────
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
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black12)
                  ],
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
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RecordsScreen())),
                    ),
                    // Central add FAB
                    GestureDetector(
                      onTap: () =>
                          setState(() => _addingPoint = !_addingPoint),
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _addingPoint
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26)
                          ],
                        ),
                        child: Icon(
                          _addingPoint
                              ? Icons.close
                              : Icons.add_location_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    _BottomBarButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'მეთოდიკა',
                      onTap: () {
                        AnalyticsService.logPdfOpened();
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PdfViewerScreen()));
                      },
                    ),
                    _BottomBarButton(
                      icon: Icons.settings_outlined,
                      label: 'პარამ.',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen())),
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

// ──────────────────────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _MapButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      color: active
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: active ? Theme.of(context).colorScheme.primary : null,
          ),
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
