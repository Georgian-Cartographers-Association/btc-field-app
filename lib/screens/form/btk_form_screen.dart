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

class _BtkFormScreenState extends ConsumerState<BtkFormScreen> with SingleTickerProviderStateMixin {
  late BtkRecord _record;
  late TabController _tabController;
  bool _pdfOpen = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _update(BtkRecord updated) {
    setState(() => _record = updated);
  }

  Future<void> _save() async {
    await ref.read(btkProvider.notifier).update(_record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('შენახულია ✓'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _detectGps() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('კოორდინატების დადგენა...'), duration: Duration(seconds: 2)));
    final pos = await Geolocator.getCurrentPosition();
    _update(_record
      ..latitude = pos.latitude
      ..longitude = pos.longitude);
  }

  Future<void> _sendEmail() async {
    final settings = ref.read(settingsProvider);
    String email = settings.defaultEmail;
    if (email.isEmpty) {
      email = await _askEmail() ?? '';
      if (email.isEmpty) return;
    }
    final subject = Uri.encodeComponent('ბტკ ჩანაწერი ${_record.id} — ${_record.date.toString().split(' ')[0]}');
    final body = Uri.encodeComponent(_record.toEmailText());
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<String?> _askEmail() async {
    final controller = TextEditingController(
        text: ref.read(settingsProvider).defaultEmail);
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
                decoration: const InputDecoration(hintText: 'example@email.com'),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('გაუქმება')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('გაგზავნა'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ბტკ #${_record.id}'),
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
          Expanded(flex: 1, child: const PdfViewerScreen(embedded: true)),
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
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text('მეთოდური მითითება',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: pdfButton,
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: PdfViewerScreen(embedded: true)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
