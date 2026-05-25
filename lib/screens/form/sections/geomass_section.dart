import 'package:flutter/material.dart';
import '../../../models/btk_record.dart';

class GeomassSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const GeomassSection({super.key, required this.record, required this.onChanged});

  @override
  State<GeomassSection> createState() => _GeomassSectionState();
}

class _GeomassSectionState extends State<GeomassSection> {
  void _addRow() {
    setState(() => widget.record.geomasses.add(GeomassRow()));
    widget.onChanged(widget.record);
  }

  void _removeRow(int i) {
    if (widget.record.geomasses.length <= 1) return;
    setState(() => widget.record.geomasses.removeAt(i));
    widget.onChanged(widget.record);
  }

  void _addTree() {
    setState(() => widget.record.treePhytomass.add(TreePhytomassRow()));
    widget.onChanged(widget.record);
  }

  void _removeTree(int i) {
    if (widget.record.treePhytomass.length <= 1) return;
    setState(() => widget.record.treePhytomass.removeAt(i));
    widget.onChanged(widget.record);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'გეომასების კვლევა — ბტკ-ის ვ.პ. მიწისზედა ნაწ.'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)),
              columnSpacing: 8,
              columns: const [
                DataColumn(label: Text('სექ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სიღ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('პედ.მოც.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('პედ.რ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ლით.რ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ლით.სმ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ჰიდ.რ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ჰიდ.სვ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ჰიდ.მშ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ფიტ.სვ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ფიტ.მშ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('', style: TextStyle(fontSize: 11))),
              ],
              rows: List.generate(widget.record.geomasses.length, (i) {
                final g = widget.record.geomasses[i];
                return DataRow(cells: [
                  DataCell(_c(g.section, (v) => setState(() => g.section = v))),
                  DataCell(_c(g.depth, (v) => setState(() => g.depth = v))),
                  DataCell(_c(g.pedomassBulk, (v) => setState(() => g.pedomassBulk = v))),
                  DataCell(_c(g.pedomassQty, (v) => setState(() => g.pedomassQty = v))),
                  DataCell(_c(g.lithomassQty, (v) => setState(() => g.lithomassQty = v))),
                  DataCell(_c(g.lithomassDensity, (v) => setState(() => g.lithomassDensity = v))),
                  DataCell(_c(g.hydromassQty, (v) => setState(() => g.hydromassQty = v))),
                  DataCell(_c(g.hydromassWet, (v) => setState(() => g.hydromassWet = v))),
                  DataCell(_c(g.hydromassDry, (v) => setState(() => g.hydromassDry = v))),
                  DataCell(_c(g.phytomassWet, (v) => setState(() => g.phytomassWet = v))),
                  DataCell(_c(g.phytomassDry, (v) => setState(() => g.phytomassDry = v))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                    onPressed: () => _removeRow(i),
                  )),
                ]);
              }),
            ),
          ),
          TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('სტრიქ.')),
          const SizedBox(height: 20),
          _header(context, 'ხე-მცენარეების ფიტომასა (ტ/ჰა)'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: widget.record.experimentPlotSize),
            onChanged: (v) {
              widget.record.experimentPlotSize = v;
              widget.onChanged(widget.record);
            },
            decoration: const InputDecoration(
              labelText: 'ექსპ. ნაკვ. ზომა',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)),
              columnSpacing: 8,
              columns: const [
                DataColumn(label: Text('სახ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მ.წ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.მ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ფ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ტ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ფეს.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ჯ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.მ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ფ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ტ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ფეს.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ჯ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('', style: TextStyle(fontSize: 11))),
              ],
              rows: List.generate(widget.record.treePhytomass.length, (i) {
                final t = widget.record.treePhytomass[i];
                return DataRow(cells: [
                  DataCell(_c(t.species, (v) => setState(() => t.species = v), wide: true)),
                  DataCell(_c(t.bulkDensity, (v) => setState(() => t.bulkDensity = v))),
                  DataCell(_c(t.wetWood, (v) => setState(() => t.wetWood = v))),
                  DataCell(_c(t.wetLeaves, (v) => setState(() => t.wetLeaves = v))),
                  DataCell(_c(t.wetBranches, (v) => setState(() => t.wetBranches = v))),
                  DataCell(_c(t.wetRoots, (v) => setState(() => t.wetRoots = v))),
                  DataCell(_c(t.wetTotal, (v) => setState(() => t.wetTotal = v))),
                  DataCell(_c(t.dryWood, (v) => setState(() => t.dryWood = v))),
                  DataCell(_c(t.dryLeaves, (v) => setState(() => t.dryLeaves = v))),
                  DataCell(_c(t.dryBranches, (v) => setState(() => t.dryBranches = v))),
                  DataCell(_c(t.dryRoots, (v) => setState(() => t.dryRoots = v))),
                  DataCell(_c(t.dryTotal, (v) => setState(() => t.dryTotal = v))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                    onPressed: () => _removeTree(i),
                  )),
                ]);
              }),
            ),
          ),
          TextButton.icon(onPressed: _addTree, icon: const Icon(Icons.add), label: const Text('ხე-მც. სტრიქ.')),
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

Widget _c(String value, ValueChanged<String> onChanged, {bool wide = false}) => SizedBox(
      width: wide ? 90 : 55,
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 11),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        ),
      ),
    );
