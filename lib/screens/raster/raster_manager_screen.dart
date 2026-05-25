import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/raster_layer.dart';
import '../../providers/raster_provider.dart';

class RasterManagerScreen extends ConsumerWidget {
  const RasterManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(rasterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ლოკალური რასტრული რუკები')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('რუკის დამატება'),
      ),
      body: layers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('ლოკალური რუკები არ არის',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  const Text(
                    'დაამატეთ ნიადაგის, ლანდშაფტის\nან რელიეფის რასტრული გამოსახულება',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: layers.length,
              itemBuilder: (ctx, i) {
                final layer = layers[i];
                return _RasterTile(
                  layer: layer,
                  onToggle: () => ref.read(rasterProvider.notifier).toggleVisible(layer.id),
                  onEdit: () => _showEditDialog(context, ref, layer),
                  onDelete: () => _confirmDelete(context, ref, layer.id),
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddRasterDialog(
        fileName: file.name,
        imageBytes: file.bytes!,
      ),
    ).then((data) async {
      if (data == null) return;
      await ref.read(rasterProvider.notifier).add(
            name: data['name'],
            imageBytes: file.bytes!,
            northLat: data['northLat'],
            southLat: data['southLat'],
            eastLon: data['eastLon'],
            westLon: data['westLon'],
            opacity: data['opacity'],
          );
    });
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, RasterLayer layer) async {
    await showDialog(
      context: context,
      builder: (ctx) => _EditRasterDialog(layer: layer),
    ).then((data) async {
      if (data == null) return;
      layer
        ..name = data['name']
        ..northLat = data['northLat']
        ..southLat = data['southLat']
        ..eastLon = data['eastLon']
        ..westLon = data['westLon']
        ..opacity = data['opacity'];
      await ref.read(rasterProvider.notifier).update(layer);
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('წაშლა'),
        content: const Text('ამ ლოკალური რუკის წაშლა გსურთ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('არა')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(rasterProvider.notifier).remove(id);
              Navigator.pop(ctx);
            },
            child: const Text('წაშლა', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _RasterTile extends StatelessWidget {
  final RasterLayer layer;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RasterTile({
    required this.layer,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: layer.visible
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade200,
          child: Icon(
            Icons.layers_outlined,
            color: layer.visible
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        title: Text(layer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'N:${layer.northLat.toStringAsFixed(4)} S:${layer.southLat.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              'E:${layer.eastLon.toStringAsFixed(4)} W:${layer.westLon.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11),
            ),
            Text('გამჭვირვალობა: ${(layer.opacity * 100).round()}%',
                style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: layer.visible, onChanged: (_) => onToggle()),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: onDelete),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ─── Add Dialog ───────────────────────────────────────────────────────────────

class _AddRasterDialog extends StatefulWidget {
  final String fileName;
  final List<int> imageBytes;

  const _AddRasterDialog({required this.fileName, required this.imageBytes});

  @override
  State<_AddRasterDialog> createState() => _AddRasterDialogState();
}

class _AddRasterDialogState extends State<_AddRasterDialog> {
  late TextEditingController _nameCtrl;
  final _northCtrl = TextEditingController();
  final _southCtrl = TextEditingController();
  final _eastCtrl = TextEditingController();
  final _westCtrl = TextEditingController();
  double _opacity = 0.7;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.fileName.replaceAll(RegExp(r'\.[^.]+$'), ''));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ლოკალური რუკის დამატება'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tf(_nameCtrl, 'სახელი'),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ბაუნდინგ ბოქსი (კოორდინატები)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: _tf(_northCtrl, 'ჩრდ. (N lat)')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_southCtrl, 'სამხ. (S lat)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(_eastCtrl, 'აღმ. (E lon)')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_westCtrl, 'დას. (W lon)')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('გამჭვირვ.: ${(_opacity * 100).round()}%'),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  onChanged: (v) => setState(() => _opacity = v),
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('გაუქმება')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('დამატება'),
        ),
      ],
    );
  }

  void _submit() {
    final north = double.tryParse(_northCtrl.text);
    final south = double.tryParse(_southCtrl.text);
    final east = double.tryParse(_eastCtrl.text);
    final west = double.tryParse(_westCtrl.text);

    if (north == null || south == null || east == null || west == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('კოორდინატები სწორად შეიყვანეთ')));
      return;
    }
    if (north <= south) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('N lat > S lat უნდა იყოს')));
      return;
    }

    Navigator.pop(context, {
      'name': _nameCtrl.text.isEmpty ? widget.fileName : _nameCtrl.text,
      'northLat': north,
      'southLat': south,
      'eastLon': east,
      'westLon': west,
      'opacity': _opacity,
    });
  }
}

// ─── Edit Dialog ──────────────────────────────────────────────────────────────

class _EditRasterDialog extends StatefulWidget {
  final RasterLayer layer;
  const _EditRasterDialog({required this.layer});

  @override
  State<_EditRasterDialog> createState() => _EditRasterDialogState();
}

class _EditRasterDialogState extends State<_EditRasterDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _northCtrl;
  late TextEditingController _southCtrl;
  late TextEditingController _eastCtrl;
  late TextEditingController _westCtrl;
  late double _opacity;

  @override
  void initState() {
    super.initState();
    final l = widget.layer;
    _nameCtrl = TextEditingController(text: l.name);
    _northCtrl = TextEditingController(text: l.northLat.toString());
    _southCtrl = TextEditingController(text: l.southLat.toString());
    _eastCtrl = TextEditingController(text: l.eastLon.toString());
    _westCtrl = TextEditingController(text: l.westLon.toString());
    _opacity = l.opacity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('რასტრული შრის რედ.'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tf(_nameCtrl, 'სახელი'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(_northCtrl, 'N lat')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_southCtrl, 'S lat')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(_eastCtrl, 'E lon')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_westCtrl, 'W lon')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('გამჭვირვ.: ${(_opacity * 100).round()}%'),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  onChanged: (v) => setState(() => _opacity = v),
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('გაუქმება')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'name': _nameCtrl.text,
            'northLat': double.tryParse(_northCtrl.text) ?? widget.layer.northLat,
            'southLat': double.tryParse(_southCtrl.text) ?? widget.layer.southLat,
            'eastLon': double.tryParse(_eastCtrl.text) ?? widget.layer.eastLon,
            'westLon': double.tryParse(_westCtrl.text) ?? widget.layer.westLon,
            'opacity': _opacity,
          }),
          child: const Text('შენახვა'),
        ),
      ],
    );
  }
}

Widget _tf(TextEditingController ctrl, String label) => TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
