import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/btk_provider.dart';
import '../../services/export_service.dart';
import '../form/btk_form_screen.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(btkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('შენახული ჩანაწერები'),
        actions: [
          if (records.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'ექსპორტი',
              onSelected: (val) async {
                try {
                  if (val == 'csv') {
                    await ExportService.shareCsv(records);
                  } else if (val == 'pdf') {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF მზადდება...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    await ExportService.sharePdf(records);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('შეცდომა: $e')),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'csv',
                  child: ListTile(
                    leading: Icon(Icons.table_chart_outlined),
                    title: Text('CSV (Excel/Sheets)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('PDF დოკუმენტი'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: records.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('ჩანაწერები არ მოიძებნა', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, i) {
                final r = records[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(r.id.substring(0, 2),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    title: Text('ბტკ #${r.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.date.toString().split(' ')[0]),
                        if (r.location.isNotEmpty) Text(r.location),
                        if (r.latitude != null)
                          Text(
                            '${r.latitude!.toStringAsFixed(4)}, ${r.longitude!.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Single-record export
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 20),
                          tooltip: 'ექსპ.',
                          onPressed: () async {
                            try {
                              await ExportService.sharePdf([r]);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('შეცდომა: $e')));
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, r.id),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BtkFormScreen(record: r)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('წაშლა'),
        content: const Text('დარწმუნებული ხართ ამ ჩანაწერის წაშლაში?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('არა')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(btkProvider.notifier).remove(id);
              Navigator.pop(ctx);
            },
            child: const Text('წაშლა', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
