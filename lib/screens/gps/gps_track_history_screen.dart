import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../database/btk_database.dart';
import '../../models/gps_track.dart';
import '../../services/export_service.dart';

class GpsTrackHistoryScreen extends StatefulWidget {
  const GpsTrackHistoryScreen({super.key});

  @override
  State<GpsTrackHistoryScreen> createState() => _GpsTrackHistoryScreenState();
}

class _GpsTrackHistoryScreenState extends State<GpsTrackHistoryScreen> {
  List<GpsTrack> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tracks = await BtkDatabase.getAllTracks();
    if (mounted) setState(() { _tracks = tracks; _loading = false; });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h სთ $m წთ';
    if (m > 0) return '$m წთ $s წმ';
    return '$s წმ';
  }

  String _formatDistance(GpsTrack t) {
    if (t.points.length < 2) return '0 მ';
    const calc = Distance();
    double total = 0;
    for (int i = 1; i < t.points.length; i++) {
      total += calc(
        LatLng(t.points[i - 1].lat, t.points[i - 1].lon),
        LatLng(t.points[i].lat, t.points[i].lon),
      );
    }
    return total >= 1000
        ? '${(total / 1000).toStringAsFixed(2)} კმ'
        : '${total.toStringAsFixed(0)} მ';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'იანვ', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete(GpsTrack track) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ტრეკის წაშლა'),
        content: const Text('გსურთ ამ ტრეკის წაშლა?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('გაუქმება'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('წაშლა', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await BtkDatabase.deleteTrack(track.id);
    setState(() => _tracks.removeWhere((t) => t.id == track.id));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS ტრეკების ისტორია'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'განახლება',
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tracks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TrackCard(
                    track: _tracks[i],
                    distance: _formatDistance(_tracks[i]),
                    duration: _tracks[i].endedAt != null
                        ? _formatDuration(
                            _tracks[i].endedAt!.difference(_tracks[i].startedAt))
                        : '—',
                    dateStr: _formatDate(_tracks[i].startedAt),
                    onExport: () => ExportService.shareGpx(_tracks[i]),
                    onDelete: () => _delete(_tracks[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'ჩაწერილი ტრეკი არ არის',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 6),
            Text(
              'რუკაზე  ➤  ▶ ღილაკი',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3)),
            ),
          ],
        ),
      );
}

// ── Track card ───────────────────────────────────────────────────────────────

class _TrackCard extends StatelessWidget {
  final GpsTrack track;
  final String distance;
  final String duration;
  final String dateStr;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _TrackCard({
    required this.track,
    required this.distance,
    required this.duration,
    required this.dateStr,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = track.endedAt == null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            // ── Icon ───────────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.red.withValues(alpha: 0.12)
                    : Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.radio_button_on : Icons.route,
                size: 22,
                color: isActive
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Chip(Icons.straighten, distance),
                    const SizedBox(width: 8),
                    _Chip(Icons.timer_outlined, duration),
                    const SizedBox(width: 8),
                    _Chip(Icons.location_on_outlined,
                        '${track.points.length}'),
                  ]),
                  if (isActive) ...[
                    const SizedBox(height: 4),
                    const Text('● ჩაწერა მიმდინარეობს',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),

            // ── Actions ────────────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isActive)
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'GPX გადმოტვირთვა',
                    onPressed: onExport,
                    iconSize: 20,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'წაშლა',
                  onPressed: onDelete,
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65))),
        ],
      );
}
