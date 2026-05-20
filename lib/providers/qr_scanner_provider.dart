import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerResultNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? value) => state = value;
}

final scannerResultProvider = NotifierProvider<ScannerResultNotifier, String?>(ScannerResultNotifier.new);

final scannerServiceProvider = Provider((ref) {
  return ScannerService(ref);
});

class ScannerService {
  final Ref _ref;
  static const _channel = MethodChannel('com.catchbangladesh.ams/scanner');

  var _lastWakeUpTime = 0;
  static const _wakeUpDebounce = Duration(milliseconds: 500);
  bool _isScanActive = false;

  ScannerService(this._ref) {
    _init();
  }

  void _init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onScanReceived':
          final barcode = call.arguments?.toString().trim();
          if (barcode == null || barcode.isEmpty) {
            return;
          }
          _isScanActive = false;
          _ref.read(scannerResultProvider.notifier).update(barcode);
      }
    });
  }

  Future<void> wakeUpScanner() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_isScanActive) {
      return;
    }

    if (now - _lastWakeUpTime < _wakeUpDebounce.inMilliseconds) {
      return;
    }

    try {
      _lastWakeUpTime = now;
      _isScanActive = true;
      final started = await _channel.invokeMethod<bool>('startHardwareScan');
      if (started != true) {
        _isScanActive = false;
      }
    } on PlatformException {
      _isScanActive = false;
    }
  }

  Future<void> stopScanner() async {
    try {
      _isScanActive = false;
      _lastWakeUpTime = 0;
      await _channel.invokeMethod('stopHardwareScan');
    } on PlatformException {
      // Scanner stop failed silently
    }
  }
}

final qrScannerLauncherProvider = Provider<Future<String?> Function(BuildContext context)>((ref) {
  return (context) async {
    ref.read(scannerServiceProvider);
    await ref.read(scannerServiceProvider).stopScanner();
    ref.read(scannerResultProvider.notifier).update(null);
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _HardwareScanDialog(
        title: l10n.hardwareScannerActive,
        instructions: l10n.hardwareScannerInstructions,
        icon: Icons.qr_code_scanner,
      ),
    );
  };
});

class _HardwareScanDialog extends ConsumerStatefulWidget {
  const _HardwareScanDialog({required this.title, required this.instructions, required this.icon});

  final String title;
  final String instructions;
  final IconData icon;

  @override
  ConsumerState<_HardwareScanDialog> createState() => _HardwareScanDialogState();
}

class _HardwareScanDialogState extends ConsumerState<_HardwareScanDialog> {
  late ScannerService _scannerService;

  @override
  void initState() {
    super.initState();
    _scannerService = ref.read(scannerServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _scannerService.stopScanner();
      if (!mounted) return;
      await _scannerService.wakeUpScanner();
    });
  }

  @override
  void dispose() {
    ref.read(scannerResultProvider.notifier).update(null);
    _scannerService.stopScanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<String?>(scannerResultProvider, (previous, next) {
      if (next != null && mounted) {
        final scanned = next;
        ref.read(scannerResultProvider.notifier).update(null);
        Navigator.of(context).pop(scanned);
      }
    });

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(widget.instructions),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))],
    );
  }
}
