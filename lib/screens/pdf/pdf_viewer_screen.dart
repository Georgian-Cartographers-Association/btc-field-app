import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/constants.dart';
import '../../providers/settings_provider.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const PdfViewerScreen({super.key, this.embedded = false});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Restore saved page after first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedPage = ref.read(settingsProvider).pdfPage;
      if (savedPage > 0 && _loaded) {
        _controller.jumpToPage(savedPage);
      }
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    ref.read(settingsProvider.notifier).savePdfPage(details.newPageNumber);
  }

  @override
  Widget build(BuildContext context) {
    final savedPage = ref.read(settingsProvider).pdfPage;

    final viewer = SfPdfViewer.asset(
      AppConstants.pdfAssetPath,
      controller: _controller,
      initialPageNumber: savedPage > 0 ? savedPage : 1,
      onPageChanged: _onPageChanged,
      onDocumentLoaded: (_) => setState(() => _loaded = true),
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableTextSelection: true,
    );

    if (widget.embedded) {
      return viewer;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('მეთოდური მითითება'),
        actions: [
          if (_loaded)
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'დასაწყისი',
              onPressed: () => _controller.jumpToPage(1),
            ),
          if (_loaded)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'გვ. ${_controller.pageNumber} / ${_controller.pageCount}',
              onPressed: () => _showPageJump(),
            ),
        ],
      ),
      body: viewer,
    );
  }

  void _showPageJump() {
    final ctrl = TextEditingController(text: _controller.pageNumber.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('გვერდზე გადასვლა'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'გვ. (1–${_controller.pageCount})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('გაუქმება')),
          ElevatedButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= _controller.pageCount) {
                _controller.jumpToPage(p);
              }
              Navigator.pop(ctx);
            },
            child: const Text('გადასვლა'),
          ),
        ],
      ),
    );
  }
}
