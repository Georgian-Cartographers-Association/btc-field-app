import 'package:flutter/material.dart';
import '../../../models/btk_record.dart';

class VerticalStructureSection extends StatelessWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const VerticalStructureSection({super.key, required this.record, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final r = record;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'ბტკ-ის ვერტიკალური სტრუქტურა'),
          const SizedBox(height: 16),
          _tf('ვ.ს. ტიპის სახელწოდება', r.vertStructTypeName,
              (v) => _upd(r..vertStructTypeName = v)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _tf('ინდექსი', r.vertStructIndex,
                    (v) => _upd(r..vertStructIndex = v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tf('სიმაღლე', r.vertStructHeight,
                    (v) => _upd(r..vertStructHeight = v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tf(
            'ვ.პ. მიწისზედა ნ. დამოკიდ. მიწისქვედა ნ.თ.',
            r.vertStructDesc,
            (v) => _upd(r..vertStructDesc = v),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  void _upd(BtkRecord r) => onChanged(r);
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
