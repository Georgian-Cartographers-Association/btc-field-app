import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

/// Screen for creating a new expedition or joining an existing one.
///
/// Create → generates a 6-char code, writes the expedition document to Firestore,
///          switches to expedition mode.
/// Join   → user enters a 6-char code; app validates it exists, then joins.
class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen({super.key});

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _busy = false;
  String? _createdCode;

  // Join tab
  final _joinCtrl = TextEditingController();
  String? _joinError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _joinCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  CollectionReference<Map<String, dynamic>> get _expeditions =>
      FirebaseFirestore.instance.collection('expeditions');

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<void> _create() async {
    setState(() { _busy = true; _createdCode = null; });
    try {
      final code = _generateCode();
      await _expeditions.doc(code).set({
        'created_at': FieldValue.serverTimestamp(),
      });
      setState(() => _createdCode = code);
    } catch (e) {
      _showError('შეცდომა: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCreate() async {
    if (_createdCode == null) return;
    await ref.read(settingsProvider.notifier).joinExpedition(_createdCode!);
    if (mounted) Navigator.pop(context, _createdCode);
  }

  // ── Join ───────────────────────────────────────────────────────────────────

  Future<void> _join() async {
    final code = _joinCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _joinError = 'კოდი უნდა შედგებოდეს 6 სიმბოლოსგან');
      return;
    }
    setState(() { _busy = true; _joinError = null; });
    try {
      final doc = await _expeditions.doc(code).get();
      if (!doc.exists) {
        setState(() => _joinError = 'ასეთი ექსპედიცია არ მოიძებნა');
        return;
      }
      await ref.read(settingsProvider.notifier).joinExpedition(code);
      if (mounted) Navigator.pop(context, code);
    } catch (e) {
      setState(() => _joinError = 'შეცდომა: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ექსპედიციის რეჟიმი'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'შექმნა'),
            Tab(icon: Icon(Icons.login_outlined), text: 'შეერთება'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCreateTab(),
          _buildJoinTab(),
        ],
      ),
    );
  }

  // ── Create tab ─────────────────────────────────────────────────────────────

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text('ახალი ექსპედიცია',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'შეიქმნება 6-სიმბოლოიანი კოდი. '
                    'გაუზიარეთ კოლეგებს — მათ შეუძლიათ '
                    '"შეერთება" ჩანართით შეუერთდნენ '
                    'და ერთად ამუშაონ ჩანაწერები.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Generated code display
          if (_createdCode != null) ...[
            Center(
              child: Column(
                children: [
                  Text('ექსპედიციის კოდი',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _createdCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('კოდი კოპირდა ✓')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _createdCode!,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.copy_outlined,
                              color:
                                  Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('დაჭირეთ კოდზე კოპირებისთვის',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _busy ? null : _confirmCreate,
              icon: const Icon(Icons.check),
              label: const Text('ექსპედიციაში შესვლა'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _create,
              icon: const Icon(Icons.refresh),
              label: const Text('ახალი კოდის გენერაცია'),
            ),
          ] else ...[
            const Spacer(),
            FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_circle_outline),
              label: const Text('ექსპედიციის შექმნა'),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  // ── Join tab ───────────────────────────────────────────────────────────────

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.group_outlined,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text('არსებულ ექსპედიციაში შეერთება',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'შეიყვანეთ კოლეგისგან მიღებული '
                    '6-სიმბოლოიანი კოდი.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Code input
          TextField(
            controller: _joinCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'ექსპედიციის კოდი',
              hintText: 'XXXXXX',
              errorText: _joinError,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (_) {
              if (_joinError != null) setState(() => _joinError = null);
            },
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _busy ? null : _join,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login_outlined),
            label: const Text('შეერთება'),
          ),
        ],
      ),
    );
  }
}
