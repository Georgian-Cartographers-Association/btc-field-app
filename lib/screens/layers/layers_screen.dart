import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/tile_service.dart';
import '../../providers/raster_provider.dart';
import '../../providers/tile_service_provider.dart';

class LayersScreen extends ConsumerStatefulWidget {
  const LayersScreen({super.key});

  @override
  ConsumerState<LayersScreen> createState() => _LayersScreenState();
}

class _LayersScreenState extends ConsumerState<LayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('მონაცემთა შრეები'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.image_outlined), text: 'რასტრები'),
            Tab(icon: Icon(Icons.public), text: 'ვებ სერვისები'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RasterTab(),
          _TileServiceTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 1: Asset Rasters (from catalog.json)
// ══════════════════════════════════════════════════════════════════════════════

class _RasterTab extends ConsumerWidget {
  const _RasterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(rasterProvider);
    final notifier = ref.read(rasterProvider.notifier);

    if (layers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_search, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('რასტრული შრეები არ არის',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'PNG ფაილები ჩადეთ assets/rasters/ საქაღალდეში\n'
                'და catalog.json-ში ჩაამატეთ ჩანაწერი:\n\n'
                '{\n'
                '  "id": "my_map",\n'
                '  "name": "ჩემი რუკა",\n'
                '  "file": "assets/rasters/my_map.png",\n'
                '  "north": 43.5, "south": 41.0,\n'
                '  "east": 46.8, "west": 40.0\n'
                '}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace', color: Colors.grey.shade600),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: layers.length,
      itemBuilder: (ctx, i) {
        final layer = layers[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: layer.visible
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.image_outlined,
                    color: layer.visible
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                title: Text(layer.name),
                subtitle: Text(
                  'N:${layer.northLat.toStringAsFixed(3)}  '
                  'S:${layer.southLat.toStringAsFixed(3)}  '
                  'E:${layer.eastLon.toStringAsFixed(3)}  '
                  'W:${layer.westLon.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Switch(
                  value: layer.visible,
                  onChanged: (_) => notifier.toggleVisible(layer.id),
                ),
              ),
              if (layer.visible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.opacity, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: layer.opacity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          label: '${(layer.opacity * 100).round()}%',
                          onChanged: (v) => notifier.setOpacity(layer.id, v),
                        ),
                      ),
                      Text('${(layer.opacity * 100).round()}%',
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 2: WMS / WMTS / XYZ Tile Services
// ══════════════════════════════════════════════════════════════════════════════

class _TileServiceTab extends ConsumerWidget {
  const _TileServiceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(tileServiceProvider);
    final notifier = ref.read(tileServiceProvider.notifier);

    return Column(
      children: [
        // ─ Add button ─
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('შაბლონიდან დამატება'),
                  onPressed: () => _showTemplateDialog(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: const Text('Custom URL'),
                  onPressed: () => _showAddDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ─ List ─
        Expanded(
          child: services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('ვებ სერვისები არ არის',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('XYZ ტაილ სერვერი, WMTS ან WMS',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: services.length,
                  itemBuilder: (ctx, i) {
                    final svc = services[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: svc.visible
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Colors.grey.shade200,
                              child: Icon(Icons.public,
                                  color: svc.visible
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey),
                            ),
                            title: Text(svc.name),
                            subtitle: Text(
                              svc.urlTemplate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: svc.visible,
                                  onChanged: (_) =>
                                      notifier.toggleVisible(svc.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 20),
                                  onPressed: () =>
                                      _showEditDialog(context, ref, svc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, ref, svc.id),
                                ),
                              ],
                            ),
                          ),
                          if (svc.visible)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.opacity,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: svc.opacity,
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 18,
                                      label:
                                          '${(svc.opacity * 100).round()}%',
                                      onChanged: (v) =>
                                          notifier.setOpacity(svc.id, v),
                                    ),
                                  ),
                                  Text('${(svc.opacity * 100).round()}%',
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _TemplateSheet(
        onSelected: (tpl, name) {
          ref.read(tileServiceProvider.notifier).addFromTemplate(tpl, name);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _TileServiceDialog(
        onSave: (svc) {
          ref.read(tileServiceProvider.notifier).add(svc);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, TileService svc) {
    showDialog(
      context: context,
      builder: (ctx) => _TileServiceDialog(
        initial: svc,
        onSave: (updated) {
          ref.read(tileServiceProvider.notifier).update(updated);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('წაშლა'),
        content: const Text('ამ სერვისის წაშლა გსურთ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('არა')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(tileServiceProvider.notifier).remove(id);
              Navigator.pop(ctx);
            },
            child:
                const Text('წაშლა', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _TemplateSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> tpl, String name) onSelected;
  const _TemplateSheet({required this.onSelected});

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  int? _selected;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Text('შაბლონის არჩევა',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...TileService.kTemplates.asMap().entries.map((e) => RadioListTile<int>(
                value: e.key,
                groupValue: _selected,
                title: Text(e.value['name'] as String),
                subtitle: Text(
                  e.value['urlTemplate'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                dense: true,
                onChanged: (v) => setState(() {
                  _selected = v;
                  if (_nameCtrl.text.isEmpty) {
                    _nameCtrl.text = e.value['name'] as String;
                  }
                }),
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'სახელი (სურვილისამებრ)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => widget.onSelected(
                        TileService.kTemplates[_selected!],
                        _nameCtrl.text.trim(),
                      ),
              child: const Text('დამატება'),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _TileServiceDialog extends StatefulWidget {
  final TileService? initial;
  final void Function(TileService) onSave;
  const _TileServiceDialog({this.initial, required this.onSave});

  @override
  State<_TileServiceDialog> createState() => _TileServiceDialogState();
}

class _TileServiceDialogState extends State<_TileServiceDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _subCtrl; // comma-separated subdomains

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _urlCtrl = TextEditingController(text: s?.urlTemplate ?? '');
    _subCtrl = TextEditingController(
        text: s?.subdomains.join(',') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Custom URL სერვისი' : 'სერვისის რედ.'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameCtrl, 'სახელი'),
            const SizedBox(height: 10),
            _field(_urlCtrl, 'URL შაბლონი',
                hint: 'https://example.com/{z}/{x}/{y}.png'),
            const SizedBox(height: 10),
            _field(_subCtrl, 'Subdomains (მძიმით)',
                hint: 'a,b,c  — სურვილისამებრ'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('გაუქმება')),
        ElevatedButton(
          onPressed: _save,
          child: const Text('შენახვა'),
        ),
      ],
    );
  }

  void _save() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final subs = _subCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final svc = TileService(
      id: widget.initial?.id ?? const Uuid().v4().substring(0, 8),
      name: _nameCtrl.text.trim().isEmpty ? url : _nameCtrl.text.trim(),
      urlTemplate: url,
      subdomains: subs,
      opacity: widget.initial?.opacity ?? 1.0,
      visible: widget.initial?.visible ?? true,
    );
    widget.onSave(svc);
  }

  Widget _field(TextEditingController c, String label, {String? hint}) =>
      TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
      );
}
