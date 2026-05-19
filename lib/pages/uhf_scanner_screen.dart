import 'dart:async';

import 'package:asset_management_system/core/uhf_service.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class UhfScannerScreen extends StatefulWidget {
  const UhfScannerScreen({super.key});

  @override
  State<UhfScannerScreen> createState() => _UhfScannerScreenState();
}

class _UhfScannerScreenState extends State<UhfScannerScreen> {
  final _uhf = UhfService.instance();
  StreamSubscription<String>? _sub;
  String _lastEpc = '';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final available = await _uhf.isAvailable();
    if (!available) {
      if (!mounted) return;
      Navigator.of(context).pop(null);
      return;
    }

    _sub = _uhf.tagStream.listen((tag) {
      if (!_started || !mounted) return;
      setState(() => _lastEpc = tag);
      _uhf.stopInventory();
      Navigator.of(context).pop(tag);
    });

    _started = true;
    final success = await _uhf.startInventory();
    if (!success && mounted) {
      Navigator.of(context).pop(null);
    }
  }

  @override
  void dispose() {
    _uhf.stopInventory();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rfidScannerTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contactless, size: 80),
              const SizedBox(height: 16),
              Text(l10n.holdRfidTagClose, textAlign: TextAlign.center),
              if (_lastEpc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_lastEpc, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(null), child: Text(l10n.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}
