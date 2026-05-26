/// Asset raster overlay loaded from assets/rasters/.
/// Metadata from catalog.json; visibility/opacity in SharedPreferences.
class RasterLayer {
  final String id;
  final String name;
  final String assetPath;   // assets/rasters/filename.png
  final double northLat;
  final double southLat;
  final double eastLon;
  final double westLon;
  double opacity;
  bool visible;

  RasterLayer({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.northLat,
    required this.southLat,
    required this.eastLon,
    required this.westLon,
    this.opacity = 0.7,
    this.visible = true,
  });

  factory RasterLayer.fromCatalog(Map<String, dynamic> j) => RasterLayer(
        id: j['id'] as String,
        name: j['name'] as String,
        assetPath: j['file'] as String,
        northLat: (j['north'] as num).toDouble(),
        southLat: (j['south'] as num).toDouble(),
        eastLon: (j['east'] as num).toDouble(),
        westLon: (j['west'] as num).toDouble(),
        opacity: (j['opacity'] as num?)?.toDouble() ?? 0.7,
        visible: j['visible'] as bool? ?? true,
      );
}
