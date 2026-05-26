class TileService {
  final String id;
  String name;
  String urlTemplate;
  List<String> subdomains;
  double opacity;
  bool visible;

  TileService({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.subdomains = const [],
    this.opacity = 1.0,
    this.visible = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'urlTemplate': urlTemplate,
        'subdomains': subdomains,
        'opacity': opacity,
        'visible': visible,
      };

  factory TileService.fromJson(Map<String, dynamic> j) => TileService(
        id: j['id'] as String,
        name: j['name'] as String,
        urlTemplate: j['urlTemplate'] as String,
        subdomains: List<String>.from(j['subdomains'] as List? ?? []),
        opacity: (j['opacity'] as num?)?.toDouble() ?? 1.0,
        visible: j['visible'] as bool? ?? true,
      );

  // ── Built-in templates ──────────────────────────────────────────────
  static const List<Map<String, dynamic>> kTemplates = [
    {
      'name': 'Esri Satellite',
      'urlTemplate':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
    },
    {
      'name': 'Esri Topo',
      'urlTemplate':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
    },
    {
      'name': 'Google Satellite',
      'urlTemplate':
          'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
      'subdomains': <String>[],
    },
    {
      'name': 'Stamen Terrain',
      'urlTemplate':
          'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg',
      'subdomains': <String>['a', 'b', 'c', 'd'],
    },
    {
      'name': 'CARTO Light',
      'urlTemplate':
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      'subdomains': <String>['a', 'b', 'c', 'd'],
    },
    {
      'name': 'Custom XYZ / WMTS',
      'urlTemplate': 'https://example.com/tiles/{z}/{x}/{y}.png',
      'subdomains': <String>[],
    },
  ];
}
