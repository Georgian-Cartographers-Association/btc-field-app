import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/btk_record.dart';
import '../../providers/btk_provider.dart';
import '../../providers/settings_provider.dart';
import '../pdf/pdf_viewer_screen.dart';
import 'sections/basic_info_section.dart';
import 'sections/physical_geo_section.dart';
import 'sections/vegetation_section.dart';
import 'sections/soil_section.dart';
import 'sections/geomass_section.dart';
import 'sections/vertical_structure_section.dart';

class BtkFormScreen extends ConsumerStatefulWidget {
  final BtkRecord record;
  const BtkFormScreen({super.key, required this.record});

  @override
  ConsumerState<BtkFormScreen> createState() => _BtkFormScreenState();
}

class _BtkFormScreenState extends ConsumerState<BtkFormScreen>
    with SingleTickerProviderStateMixin {
  late BtkRecord _record;
  late TabController _tabController;
  bool _pdfOpen = false;
  bool _dirty = false; // unsaved changes indicator

  // Auto-save debounce — 800 ms after last change
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    // Flush any pending auto-save immediately on screen close
    if (_autoSaveTimer?.isActive == true) {
      _autoSaveTimer!.cancel();
      // fire-and-forget — we're leaving the widget tree
      ref.read(btkProvider.notifier).update(_record);
    }
    _tabController.dispose();
    super.dispose();
  }

  // Called by every section widget on any field change
  void _update(BtkRecord updated) {
    setState(() {
      _record = updated;
      _dirty = true;
    });
    // Debounce auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  // Silent background save (no snackbar)
  Future<void> _autoSave() async {
    await ref.read(btkProvider.notifier).update(_record);
    if (mounted) setState(() => _dirty = false);
  }

  // Explicit save (with snackbar)
  Future<void> _save() async {
    _autoSaveTimer?.cancel();
    await ref.read(btkProvider.notifier).update(_record);
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('შენახულია ✓'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _detectGps() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('კოორდინატების დადგენა...'),
            duration: Duration(seconds: 2)));
    final pos = await Geolocator.getCurrentPosition();
    _update(_record
      ..latitude = pos.latitude
      ..longitude = pos.longitude);
  }

  // ─── Email sending ──────────────────────────────────────────────────────────

  Future<void> _sendEmail() async {
    final emails = ref.read(settingsProvider).emails;

    List<String> targets;
    if (emails.isEmpty) {
      final entered = await _askEmailManually();
      if (entered == null || entered.isEmpty) return;
      targets = [entered];
    } else if (emails.length == 1) {
      targets = emails;
    } else {
      // Let user pick which emails to send to
      targets = await _pickEmails(emails) ?? [];
      if (targets.isEmpty) return;
    }

    final to = targets.join(',');
    final subject = Uri.encodeComponent(
        'ბტკ ჩანაწერი ${_record.id} — ${_record.date.toString().split(' ')[0]}');
    final body = Uri.encodeComponent(_record.toEmailText());
    final uri = Uri.parse('mailto:$to?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<List<String>?> _pickEmails(List<String> all) {
    final selected = <String>{...all}; // all selected by default
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('გაგზავნა'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: all
                .map((e) => CheckboxListTile(
                      value: selected.contains(e),
                      title: Text(e),
                      dense: true,
                      onChanged: (v) => setS(() {
                        if (v == true) {
                          selected.add(e);
                        } else {
                          selected.remove(e);
                        }
                      }),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('გაუქმება')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected.toList()),
              child: const Text('გაგზავნა'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askEmailManually() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ელ-ფოსტის მისამართი'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'example@email.com'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.paste),
              tooltip: 'ჩასმა',
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) controller.text = data!.text!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('გაუქმება')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('გაგზავნა'),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Auto-save on back navigation
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _dirty) {
          _autoSaveTimer?.cancel();
          ref.read(btkProvider.notifier).update(_record);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text('ბტკ #${_record.id}'),
              if (_dirty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_book_outlined),
              tooltip: 'მეთოდური მითითება',
              onPressed: () => setState(() => _pdfOpen = !_pdfOpen),
            ),
            IconButton(
              icon: const Icon(Icons.email_outlined),
              tooltip: 'გაგზავნა',
              onPressed: _sendEmail,
            ),
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'შენახვა',
              onPressed: _save,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'ძირითადი'),
              Tab(text: 'ფიზ.გეოგ.'),
              Tab(text: 'მცენარ.'),
              Tab(text: 'ნიადაგი'),
              Tab(text: 'გეომასა'),
              Tab(text: 'ვ.სტრ.'),
            ],
          ),
        ),
        body: _pdfOpen
            ? _SplitView(
                form: _buildTabView(),
                pdfButton: () => setState(() => _pdfOpen = false),
              )
            : _buildTabView(),
        floatingActionButton: _pdfOpen
            ? null
            : FloatingActionButton.extended(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('შენახვა'),
              ),
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        BasicInfoSection(record: _record, onChanged: _update, onDetectGps: _detectGps),
        PhysicalGeoSection(record: _record, onChanged: _update),
        VegetationSection(record: _record, onChanged: _update),
        SoilSection(record: _record, onChanged: _update),
        GeomassSection(record: _record, onChanged: _update),
        VerticalStructureSection(record: _record, onChanged: _update),
      ],
    );
  }
}

// ─── Split view ──────────────────────────────────────────────────────────────

class _SplitView extends StatelessWidget {
  final Widget form;
  final VoidCallback pdfButton;

  const _SplitView({required this.form, required this.pdfButton});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 1, child: form),
          const VerticalDivider(width: 1),
          const Expanded(flex: 1, child: PdfViewerScreen(embedded: true)),
        ],
      );
    }
    return Stack(
      children: [
        form,
        Positioned(
          bottom: 80,
          right: 16,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text('მეთოდური მითითება',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                          onPressed: pdfButton,
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                      child: PdfViewerScreen(embedded: true)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
