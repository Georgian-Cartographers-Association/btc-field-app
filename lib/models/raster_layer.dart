class RasterLayer {
  final String id;
  String name;
  double northLat;
  double southLat;
  double eastLon;
  double westLon;
  double opacity;
  bool visible;
  // storagePath: absolute file path on mobile/desktop, 'web:<id>' on web
  final String storagePath;

  RasterLayer({
    required this.id,
    required this.name,
    required this.northLat,
    required this.southLat,
    required this.eastLon,
    required this.westLon,
    this.opacity = 0.7,
    this.visible = true,
    required this.storagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'northLat': northLat,
        'southLat': southLat,
        'eastLon': eastLon,
        'westLon': westLon,
        'opacity': opacity,
        'visible': visible,
        'storagePath': storagePath,
      };

  factory RasterLayer.fromJson(Map<String, dynamic> j) => RasterLayer(
        id: j['id'],
        name: j['name'],
        northLat: (j['northLat'] as num).toDouble(),
        southLat: (j['southLat'] as num).toDouble(),
        eastLon: (j['eastLon'] as num).toDouble(),
        westLon: (j['westLon'] as num).toDouble(),
        opacity: (j['opacity'] as num?)?.toDouble() ?? 0.7,
        visible: j['visible'] as bool? ?? true,
        storagePath: j['storagePath'],
      );
}
