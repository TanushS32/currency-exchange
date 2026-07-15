import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../calculator.dart';
import '../models.dart';
import '../theme.dart';
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

  Future<File> _captureFile() async {
    // pixelRatio 2 mirrors the desktop app's html2canvas capture (scale: 2)
    // so exported images come out at the same resolution/crispness.
    final bytes = await _screenshotController.capture(pixelRatio: 2);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/exchange-summary-${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!);
    return file;
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final file = await _captureFile();
      await Gal.putImage(file.path, album: 'Currency Exchange');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Photos')),
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
      final file = await _captureFile();
      await Share.shareXFiles([XFile(file.path)]);
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
                  label: const Text('Save'),
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
