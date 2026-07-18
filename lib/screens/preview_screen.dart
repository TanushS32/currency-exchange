import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../calculator.dart';
import '../models.dart';
import '../theme.dart';
import '../web_download_stub.dart' if (dart.library.html) '../web_download_web.dart';
import '../widgets/receipt_widget.dart';

class PreviewScreen extends StatefulWidget {
  final String dealType;
  final List<ExchangeItem> items;
  final QuoteTotals totals;
  final DateTime timestamp;

  const PreviewScreen({
    super.key,
    required this.dealType,
    required this.items,
    required this.totals,
    required this.timestamp,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  ReceiptStyle _style = ReceiptStyle.ledger;
  bool _busy = false;

  Future<Uint8List> _captureBytes() async {
    // pixelRatio 2 mirrors the desktop app's html2canvas capture (scale: 2)
    // so exported images come out at the same resolution/crispness.
    final bytes = await _screenshotController.capture(pixelRatio: 2);
    return bytes!;
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final bytes = await _captureBytes();
      if (kIsWeb) {
        // Browsers have no gallery API — this triggers a normal file download.
        downloadBytesOnWeb(bytes, 'exchange-summary-${DateTime.now().millisecondsSinceEpoch}.png');
      } else {
        await Gal.putImageBytes(bytes, album: 'Currency Exchange', name: 'exchange-summary');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kIsWeb ? 'Downloaded' : 'Saved to Photos')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _captureBytes();
      final file = XFile.fromData(bytes, name: 'exchange-summary.png', mimeType: 'image/png');
      await Share.shareXFiles([file]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: SegmentedButton<ReceiptStyle>(
                segments: const [
                  ButtonSegment(value: ReceiptStyle.modern, label: Text('Receipt')),
                  ButtonSegment(value: ReceiptStyle.ledger, label: Text('Ledger')),
                ],
                selected: {_style},
                onSelectionChanged: (s) => setState(() => _style = s.first),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _style == ReceiptStyle.ledger
              // The ledger view is a fixed-width card matching the desktop
              // app's layout exactly; FittedBox shrinks it to fit narrow
              // phone screens on-screen without affecting the actual
              // captured image, which stays at full (natural) resolution.
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Screenshot(
                    controller: _screenshotController,
                    child: ReceiptView(
                      style: _style,
                      dealType: widget.dealType,
                      items: widget.items,
                      totals: widget.totals,
                      timestamp: widget.timestamp,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: ReceiptView(
                      style: _style,
                      dealType: widget.dealType,
                      items: widget.items,
                      totals: widget.totals,
                      timestamp: widget.timestamp,
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _saveToGallery,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(kIsWeb ? 'Download' : 'Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.bg,
    );
  }
}
