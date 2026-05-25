import 'package:flutter/material.dart';
import '../../../models/btk_record.dart';

class VegetationSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const VegetationSection({super.key, required this.record, required this.onChanged});

  @override
  State<VegetationSection> createState() => _VegetationSectionState();
}

class _VegetationSectionState extends State<VegetationSection> {
  void _addRow() {
    setState(() => widget.record.vegetation.add(VegetationRow()));
    widget.onChanged(widget.record);
  }

  void _removeRow(int i) {
    if (widget.record.vegetation.length <= 1) return;
    setState(() => widget.record.vegetation.removeAt(i));
    widget.onChanged(widget.record);
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.record.vegetation;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'მცენარეულობა'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)),
              columnSpacing: 12,
              columns: const [
                DataColumn(label: Text('იარ.', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('სიმ. (მ)', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('სიმძლ.', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('ფენოფ.', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('სახეობა', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
              ],
              rows: List.generate(rows.length, (i) {
                final r = rows[i];
                return DataRow(cells: [
                  DataCell(_cell(r.tier, (v) => setState(() => r.tier = v))),
                  DataCell(_cell(r.height, (v) => setState(() => r.height = v))),
                  DataCell(_cell(r.density, (v) => setState(() => r.density = v))),
                  DataCell(_cell(r.phenophase, (v) => setState(() => r.phenophase = v))),
                  DataCell(_cell(r.species, (v) => setState(() => r.species = v), wide: true)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                    onPressed: () => _removeRow(i),
                  )),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text('სტრიქონის დამატება'),
          ),
        ],
      ),
    );
  }
}

Widget _header(BuildContext context, String title) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
    );

Widget _cell(String value, ValueChanged<String> onChanged, {bool wide = false}) {
  return SizedBox(
    width: wide ? 120 : 70,
    child: TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        border: UnderlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
    ),
  );
}
