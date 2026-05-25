import 'package:flutter/material.dart';
import '../../../models/btk_record.dart';

class SoilSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const SoilSection({super.key, required this.record, required this.onChanged});

  @override
  State<SoilSection> createState() => _SoilSectionState();
}

class _SoilSectionState extends State<SoilSection> {
  void _addHorizon() {
    setState(() => widget.record.soilHorizons.add(SoilHorizonRow()));
    widget.onChanged(widget.record);
  }

  void _removeHorizon(int i) {
    if (widget.record.soilHorizons.length <= 1) return;
    setState(() => widget.record.soilHorizons.removeAt(i));
    widget.onChanged(widget.record);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'ნიადაგი'),
          const SizedBox(height: 12),
          _tf('ნიადაგის ტიპის სახელწოდება', r.soilTypeName,
              (v) => _upd(r..soilTypeName = v)),
          const SizedBox(height: 12),
          _tf('ნიადაგის პროფილის მორფ. დახასიათება', r.soilProfileDesc,
              (v) => _upd(r..soilProfileDesc = v), maxLines: 3),
          const SizedBox(height: 16),
          Text('გენეტიკური ჰორიზონტები',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'ფ.=ფერი  მ.შ.=მექ.შედგ.  სტ.=სტრ.  ფ.=ფ-ნ.  სმ.=სიმკვ.  '
            'ახ.=ახ-ნ.  ხ.=ხ-ნ.  ტ.=ტ-ბა  ჰ.=ჰ-ს.  ქ.=ქ.საზ.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...List.generate(r.soilHorizons.length, (i) {
            final h = r.soilHorizons[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: TextEditingController(text: h.horizon),
                      onChanged: (v) => setState(() => h.horizon = v),
                      decoration: const InputDecoration(
                        labelText: 'ჰ-ტი',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: h.description),
                      onChanged: (v) => setState(() => h.description = v),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'დახასიათება',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                    onPressed: () => _removeHorizon(i),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addHorizon,
            icon: const Icon(Icons.add),
            label: const Text('ჰორიზონტის დამატება'),
          ),
          const SizedBox(height: 16),
          _tf('გეოჰორიზონტის ინდექსი', r.geohorizonIndex,
              (v) => _upd(r..geohorizonIndex = v)),
          const SizedBox(height: 12),
          _tf('ნიადაგ ზედაპ. ფორმაციის ტიპი', r.soilSurfaceFormation,
              (v) => _upd(r..soilSurfaceFormation = v)),
        ],
      ),
    );
  }

  void _upd(BtkRecord r) {
    setState(() {});
    widget.onChanged(r);
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

Widget _tf(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) =>
    TextField(
      controller: TextEditingController(text: value),
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
