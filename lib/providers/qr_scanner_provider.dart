import 'package:asset_management_system/core/uhf_service.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/pages/uhf_scanner_screen.dart';
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
      if (call.method == 'onScanReceived') {
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

final rfidScannerLauncherProvider = Provider<Future<String?> Function(BuildContext context)>((ref) {
  return (context) async {
    ref.read(scannerServiceProvider);
    try {
      final available = await UhfService.instance().isAvailable();
      if (available && context.mounted) {
        final tag = await Navigator.of(context).push<String?>(MaterialPageRoute(builder: (_) => const UhfScannerScreen()));
        if (tag != null) {
          return tag;
        }
      }
    } catch (_) {
      // Fall through to hardware scanner dialog.
    }

    ref.read(scannerResultProvider.notifier).update(null);
    if (!context.mounted) {
      return null;
    }
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _HardwareScanDialog(
        title: l10n.hardwareRfidScannerActive,
        instructions: l10n.hardwareRfidScannerInstructions,
        icon: Icons.contactless,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(scannerResultProvider);
      if (pending != null && mounted) {
        Navigator.of(context).pop(pending);
        return;
      }
      _scannerService.wakeUpScanner();
    });
  }

  @override
  void dispose() {
    _scannerService.stopScanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<String?>(scannerResultProvider, (previous, next) {
      if (next != null) {
        Navigator.of(context).pop(next);
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
