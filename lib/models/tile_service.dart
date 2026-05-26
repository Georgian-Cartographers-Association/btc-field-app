/// XYZ/WMTS tile service vs proper WMS service type
enum ServiceType { xyz, wms }

class TileService {
  final String id;
  String name;
  ServiceType serviceType;
  String urlTemplate; // XYZ/WMTS url OR WMS base URL (https://host/wms?)
  List<String> subdomains;
  String wmsLayers;   // WMS only — comma-separated layer names
  double opacity;
  bool visible;

  TileService({
    required this.id,
    required this.name,
    this.serviceType = ServiceType.xyz,
    required this.urlTemplate,
    this.subdomains = const [],
    this.wmsLayers = '',
    this.opacity = 1.0,
    this.visible = true,
  });

  TileService copyWith({
    String? name,
    ServiceType? serviceType,
    String? urlTemplate,
    List<String>? subdomains,
    String? wmsLayers,
    double? opacity,
    bool? visible,
  }) =>
      TileService(
        id: id,
        name: name ?? this.name,
        serviceType: serviceType ?? this.serviceType,
        urlTemplate: urlTemplate ?? this.urlTemplate,
        subdomains: subdomains ?? this.subdomains,
        wmsLayers: wmsLayers ?? this.wmsLayers,
        opacity: opacity ?? this.opacity,
        visible: visible ?? this.visible,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serviceType': serviceType.name,
        'urlTemplate': urlTemplate,
        'subdomains': subdomains,
        'wmsLayers': wmsLayers,
        'opacity': opacity,
        'visible': visible,
      };

  factory TileService.fromJson(Map<String, dynamic> j) => TileService(
        id: j['id'] as String,
        name: j['name'] as String,
        serviceType: ServiceType.values.firstWhere(
          (e) => e.name == (j['serviceType'] as String? ?? 'xyz'),
          orElse: () => ServiceType.xyz,
        ),
        urlTemplate: j['urlTemplate'] as String,
        subdomains: List<String>.from(j['subdomains'] as List? ?? []),
        wmsLayers: j['wmsLayers'] as String? ?? '',
        opacity: (j['opacity'] as num?)?.toDouble() ?? 1.0,
        visible: j['visible'] as bool? ?? true,
      );

  // ── Built-in templates (XYZ/WMTS only) ─────────────────────────────────────
  static const List<Map<String, dynamic>> kBuiltinTemplates = [
    {
      'name': 'Esri Satellite',
      'urlTemplate':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
      'serviceType': 'xyz',
    },
    {
      'name': 'Esri World Topo',
      'urlTemplate':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
      'serviceType': 'xyz',
    },
    {
      'name': 'Esri World Street',
      'urlTemplate':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
      'serviceType': 'xyz',
    },
    {
      'name': 'Esri NatGeo World',
      'urlTemplate':
          'https://server.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}',
      'subdomains': <String>[],
      'serviceType': 'xyz',
    },
    {
      'name': 'CARTO Voyager',
      'urlTemplate':
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      'subdomains': <String>['a', 'b', 'c', 'd'],
      'serviceType': 'xyz',
    },
    {
      'name': 'CARTO Light',
      'urlTemplate':
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      'subdomains': <String>['a', 'b', 'c', 'd'],
      'serviceType': 'xyz',
    },
    {
      'name': 'CARTO Dark',
      'urlTemplate':
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      'subdomains': <String>['a', 'b', 'c', 'd'],
      'serviceType': 'xyz',
    },
  ];
}
