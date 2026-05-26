import 'dart:typed_data';

/// Raster overlay layer — either from app assets (catalog.json) or device storage.
class RasterLayer {
  final String id;
  final String name;

  /// For asset-based rasters: path like 'assets/rasters/my_map.png'
  final String? assetPath;

  /// For device rasters (Android/desktop): absolute file system path.
  /// Null on web — use [fileBytes] instead.
  final String? filePath;

  /// For web or in-memory rasters: raw image bytes.
  /// Not serialized — only present while the app is running.
  final Uint8List? fileBytes;

  final double northLat;
  final double southLat;
  final double eastLon;
  final double westLon;
  double opacity;
  bool visible;

  /// True for device/file rasters (not from catalog.json assets).
  bool get isDeviceLayer => assetPath == null;

  RasterLayer({
    required this.id,
    required this.name,
    this.assetPath,
    this.filePath,
    this.fileBytes,
    required this.northLat,
    required this.southLat,
    required this.eastLon,
    required this.westLon,
    this.opacity = 0.7,
    this.visible = true,
  }) : assert(assetPath != null || filePath != null || fileBytes != null,
            'At least one image source must be provided');

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

  /// Serialize for SharedPreferences (device rasters only).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'north': northLat,
        'south': southLat,
        'east': eastLon,
        'west': westLon,
        'opacity': opacity,
        'visible': visible,
      };

  factory RasterLayer.fromJson(Map<String, dynamic> j,
      {Uint8List? fileBytes}) =>
      RasterLayer(
        id: j['id'] as String,
        name: j['name'] as String,
        filePath: j['filePath'] as String?,
        fileBytes: fileBytes,
        northLat: (j['north'] as num).toDouble(),
        southLat: (j['south'] as num).toDouble(),
        eastLon: (j['east'] as num).toDouble(),
        westLon: (j['west'] as num).toDouble(),
        opacity: (j['opacity'] as num?)?.toDouble() ?? 0.7,
        visible: j['visible'] as bool? ?? true,
      );
}
