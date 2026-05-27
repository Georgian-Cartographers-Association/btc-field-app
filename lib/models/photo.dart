class Photo {
  final String id;
  final String recordId;
  final String filePath;
  final String caption;
  final int sortOrder;
  final DateTime createdAt;
  final String? cloudUrl; // null = not yet uploaded to Firebase Storage

  const Photo({
    required this.id,
    required this.recordId,
    required this.filePath,
    this.caption = '',
    this.sortOrder = 0,
    required this.createdAt,
    this.cloudUrl,
  });

  Photo copyWith({String? cloudUrl}) => Photo(
        id: id,
        recordId: recordId,
        filePath: filePath,
        caption: caption,
        sortOrder: sortOrder,
        createdAt: createdAt,
        cloudUrl: cloudUrl ?? this.cloudUrl,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'record_id': recordId,
        'file_path': filePath,
        'caption': caption,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'cloud_url': cloudUrl,
      };

  factory Photo.fromMap(Map<String, dynamic> m) => Photo(
        id: m['id'] as String,
        recordId: m['record_id'] as String,
        filePath: m['file_path'] as String,
        caption: m['caption'] as String? ?? '',
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
        cloudUrl: m['cloud_url'] as String?,
      );
}
