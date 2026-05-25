import 'package:flutter/material.dart';
import '../../../models/btk_record.dart';

class PhysicalGeoSection extends StatelessWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const PhysicalGeoSection({super.key, required this.record, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'ფიზიკურ-გეოგრაფიული დახასიათება'),
          const SizedBox(height: 16),
          _tf('გეოლოგიური ფორმაცია', record.geologicalFormation,
              (v) => onChanged(record..geologicalFormation = v)),
          _gap,
          _tf('რელიეფის ტიპი', record.reliefType,
              (v) => onChanged(record..reliefType = v)),
          _gap,
          _tf('მორფოლოგიური დახასიათება', record.morphologicalDesc,
              (v) => onChanged(record..morphologicalDesc = v), maxLines: 3),
          _gap,
          _tf('თანამედროვე გეომორფოლოგიური პროცესები', record.geomorphProcesses,
              (v) => onChanged(record..geomorphProcesses = v), maxLines: 2),
          _gap,
          _tf('მიგრაციის რეჟიმი', record.migrationRegime,
              (v) => onChanged(record..migrationRegime = v)),
          _gap,
          _tf('დატენიანების ხარისხი', record.moistureDegree,
              (v) => onChanged(record..moistureDegree = v)),
        ],
      ),
    );
  }
}

const _gap = SizedBox(height: 12);

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

Widget _tf(String label, String value, ValueChanged<String> onChanged,
    {int maxLines = 1}) {
  return TextField(
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
}
