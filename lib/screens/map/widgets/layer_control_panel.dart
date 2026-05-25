import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/map_provider.dart';

class LayerControlPanel extends ConsumerWidget {
  const LayerControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(mapLayersProvider);
    final notifier = ref.read(mapLayersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('შრეების კონტროლი',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _LayerTile(
            icon: Icons.map_outlined,
            label: 'OpenStreetMap (საბაზისო)',
            value: layers.showOsm,
            onChanged: (_) => notifier.toggleOsm(),
          ),
          _LayerTile(
            icon: Icons.terrain,
            label: 'OpenTopoMap (ტოპო)',
            value: layers.showTopo,
            onChanged: (_) => notifier.toggleTopo(),
          ),
          const Divider(),
          _LayerTile(
            icon: Icons.pentagon_outlined,
            label: 'საქართველოს საზღვარი',
            value: layers.showBoundary,
            onChanged: (_) => notifier.toggleBoundary(),
          ),
          _LayerTile(
            icon: Icons.location_pin,
            label: 'ბტკ წერტილები',
            value: layers.showPoints,
            onChanged: (_) => notifier.togglePoints(),
          ),
        ],
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
