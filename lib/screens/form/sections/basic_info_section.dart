import 'package:flutter/material.dart';
import '../../../models/btk_record.dart';

class BasicInfoSection extends StatelessWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;
  final VoidCallback onDetectGps;

  const BasicInfoSection({
    super.key,
    required this.record,
    required this.onChanged,
    required this.onDetectGps,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'ბუნებრივ-ტერიტორიული კომპლექსის (ბტკ) აღწერა'),
          const SizedBox(height: 4),
          Text('ID: ${record.id}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          _field(
            label: 'თარიღი',
            value: record.date.toString().split(' ')[0],
            readOnly: true,
            suffix: IconButton(
              icon: const Icon(Icons.calendar_today, size: 18),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: record.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) onChanged(record..date = d);
              },
            ),
          ),
          const SizedBox(height: 12),
          _field(
            label: 'ადგილმდებარეობა',
            value: record.location,
            onChanged: (v) => onChanged(record..location = v),
            hint: 'მდებარეობის სახელი / აღწერა',
          ),
          const SizedBox(height: 16),
          Text('კოორდინატები', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'განედი (lat)',
                  value: record.latitude?.toStringAsFixed(6) ?? '',
                  onChanged: (v) => onChanged(record..latitude = double.tryParse(v)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  label: 'გრძედი (lon)',
                  value: record.longitude?.toStringAsFixed(6) ?? '',
                  onChanged: (v) => onChanged(record..longitude = double.tryParse(v)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Altitude + Aspect row
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'სიმაღლე (მ)',
                  value: record.altitude != null
                      ? record.altitude!.toStringAsFixed(0)
                      : '',
                  onChanged: (v) =>
                      onChanged(record..altitude = double.tryParse(v)),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  label: 'ასპექტი (°)',
                  value: record.aspect != null
                      ? record.aspect!.toStringAsFixed(0)
                      : '',
                  onChanged: (v) =>
                      onChanged(record..aspect = double.tryParse(v)),
                  hint: '0–360',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onDetectGps,
            icon: const Icon(Icons.gps_fixed, size: 18),
            label: const Text('GPS-ით დადგენა'),
          ),
        ],
      ),
    );
  }
}

Widget _sectionHeader(BuildContext context, String title) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        )),
  );
}

Widget _field({
  required String label,
  String value = '',
  ValueChanged<String>? onChanged,
  bool readOnly = false,
  String? hint,
  Widget? suffix,
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  final ctrl = TextEditingController(text: value);
  return TextField(
    controller: ctrl,
    readOnly: readOnly,
    maxLines: maxLines,
    keyboardType: keyboardType,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    ),
  );
}
