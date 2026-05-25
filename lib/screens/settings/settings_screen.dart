import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('პარამეტრები')),
      body: ListView(
        children: [
          const _SectionHeader('გარეგნობა'),
          SwitchListTile(
            secondary: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            title: const Text('მუქი ფონი'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (v) =>
                notifier.setTheme(v ? ThemeMode.dark : ThemeMode.light),
          ),
          const Divider(),
          const _SectionHeader('ენა'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<Locale>(
              segments: const [
                ButtonSegment(value: Locale('ka'), label: Text('ქართული'), icon: Icon(Icons.language)),
                ButtonSegment(value: Locale('en'), label: Text('English'), icon: Icon(Icons.language)),
              ],
              selected: {settings.locale},
              onSelectionChanged: (s) => notifier.setLocale(s.first),
            ),
          ),
          const Divider(),
          const _SectionHeader('ელ-ფოსტა'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _EmailField(
              initialValue: settings.defaultEmail,
              onSave: notifier.setDefaultEmail,
            ),
          ),
          const Divider(),
          const _SectionHeader('შესახებ'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('ვერსია'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('ორგანიზაცია'),
            subtitle: const Text(
                'ალ. ასლანიკაშვილის სახ.\nსაქართველოს კარტოგრაფთა ასოციაცია'),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('უნივერსიტეტი'),
            subtitle: const Text('ი. ჯავახიშვილის სახ. თბილისის სახ. უნ-ტი'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _EmailField extends StatefulWidget {
  final String initialValue;
  final Future<void> Function(String) onSave;

  const _EmailField({required this.initialValue, required this.onSave});

  @override
  State<_EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<_EmailField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'ნაგულისხმევი ელ-ფოსტა',
              hintText: 'example@email.com',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            await widget.onSave(_ctrl.text.trim());
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('შენახულია'), duration: Duration(seconds: 2)));
            }
          },
          child: const Text('შენახვა'),
        ),
      ],
    );
  }
}
