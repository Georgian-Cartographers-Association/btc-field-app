import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/settings_provider.dart';

const _githubUrl =
    'https://github.com/Georgian-Cartographers-Association/GCA-btc-field-app';

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
          // ── გარეგნობა ──────────────────────────────────────────────
          const _SectionHeader('გარეგნობა'),

          // Dark mode: 3-segment (ნათელი / სისტემა / მუქი)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('თემა',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('ნათელი'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('სისტემა'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('მუქი'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => notifier.setTheme(s.first),
                ),
              ],
            ),
          ),
          const Divider(),

          // ── ენა ───────────────────────────────────────────────────
          const _SectionHeader('ენა'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<Locale>(
              segments: const [
                ButtonSegment(
                    value: Locale('ka'),
                    label: Text('ქართული'),
                    icon: Icon(Icons.language)),
                ButtonSegment(
                    value: Locale('en'),
                    label: Text('English'),
                    icon: Icon(Icons.language)),
              ],
              selected: {settings.locale},
              onSelectionChanged: (s) => notifier.setLocale(s.first),
            ),
          ),
          const Divider(),

          // ── ეკრანი ────────────────────────────────────────────────
          if (!kIsWeb) ...[
            const _SectionHeader('ეკრანი'),
            SwitchListTile(
              secondary: const Icon(Icons.screen_lock_portrait_outlined),
              title: const Text('ეკრანი ნუ ჩაქრება'),
              subtitle: const Text('რუკაზე მუშაობისას'),
              value: settings.screenAwake,
              onChanged: (v) async {
                await notifier.setScreenAwake(v);
                await WakelockPlus.toggle(enable: v);
              },
            ),
            const Divider(),
          ],

          // ── ელ-ფოსტების სია ───────────────────────────────────────
          const _SectionHeader('ელ-ფოსტის მისამართები'),
          if (settings.emails.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'ელ-ფოსტა არ არის დამატებული',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...settings.emails.map((email) => ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(email),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'წაშლა',
                  onPressed: () => notifier.removeEmail(email),
                ),
                dense: true,
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _AddEmailField(onAdd: notifier.addEmail),
          ),
          const Divider(),

          // ── შესახებ ────────────────────────────────────────────────
          const _SectionHeader('შესახებ'),

          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final ver = snapshot.data?.version ?? '—';
              final build = snapshot.data?.buildNumber ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('ვერსია'),
                subtitle: Text('$ver+$build'),
              );
            },
          ),

          const ListTile(
            leading: Icon(Icons.business_outlined),
            title: Text('ორგანიზაცია'),
            subtitle: Text(
                'ალ. ასლანიკაშვილის სახ.\nსაქართველოს კარტოგრაფთა ასოციაცია'),
          ),

          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('უნივერსიტეტი'),
            subtitle: Text('ი. ჯავახიშვილის სახ. თბილისის სახ. უნ-ტი'),
          ),

          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            subtitle: const Text(
              'Georgian-Cartographers-Association/\nGCA-btc-field-app',
              style: TextStyle(fontSize: 11),
            ),
            trailing:
                const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => launchUrl(
              Uri.parse(_githubUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── helper widgets ─────────────────────────────────────────────────────────────

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

class _AddEmailField extends StatefulWidget {
  final Future<void> Function(String) onAdd;
  const _AddEmailField({required this.onAdd});

  @override
  State<_AddEmailField> createState() => _AddEmailFieldState();
}

class _AddEmailFieldState extends State<_AddEmailField> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    await widget.onAdd(email);
    _ctrl.clear();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: const InputDecoration(
              labelText: 'ახალი ელ-ფოსტა',
              hintText: 'example@email.com',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _add,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('დამატება'),
        ),
      ],
    );
  }
}
