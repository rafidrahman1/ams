import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Scanner result state manager
class ScannerResultNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? value) => state = value;
}

final scannerResultProvider = NotifierProvider<ScannerResultNotifier, String?>(ScannerResultNotifier.new);

// Scanner service that bridges Flutter and native
final scannerServiceProvider = Provider((ref) {
  return ScannerService(ref);
});

class ScannerService {
  final Ref _ref;
  static const _channel = MethodChannel('com.catchbangladesh.ams/scanner');

  // Debounce protection for scanner wake-up calls
  var _lastWakeUpTime = 0;
  static const _WAKE_UP_DEBOUNCE = Duration(milliseconds: 500);
  bool _isScanActive = false;

  ScannerService(this._ref) {
    _init();
  }

  void _init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "onScanReceived") {
        final String barcode = call.arguments;
        _isScanActive = false; // Reset scan state when result received
        _ref.read(scannerResultProvider.notifier).update(barcode);
      }
    });
  }

  Future<void> wakeUpScanner() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Prevent concurrent scan attempts
    if (_isScanActive) {
      return;
    }

    // Apply debounce delay
    if (now - _lastWakeUpTime < _WAKE_UP_DEBOUNCE.inMilliseconds) {
      return;
    }

    try {
      _lastWakeUpTime = now;
      _isScanActive = true;
      await _channel.invokeMethod('startHardwareScan');
    } on PlatformException {
      _isScanActive = false;
      // Scanner wake-up failed silently
    }
  }

  Future<void> stopScanner() async {
    try {
      _isScanActive = false;
      _lastWakeUpTime = 0; // Reset debounce timer
      await _channel.invokeMethod('stopHardwareScan');
    } on PlatformException {
      // Scanner stop failed silently
    }
  }
}

// QR scanner dialog launcher
final qrScannerLauncherProvider = Provider<Future<String?> Function(BuildContext context)>((ref) {
  return (context) async {
    ref.read(scannerServiceProvider);
    ref.read(scannerResultProvider.notifier).update(null);
    return showDialog<String>(context: context, barrierDismissible: true, builder: (context) => const _HardwareScannerDialog());
  };
});

class _HardwareScannerDialog extends ConsumerStatefulWidget {
  const _HardwareScannerDialog({super.key});

  @override
  ConsumerState<_HardwareScannerDialog> createState() => _HardwareScannerDialogState();
}

class _HardwareScannerDialogState extends ConsumerState<_HardwareScannerDialog> {
  late ScannerService _scannerService;

  @override
  void initState() {
    super.initState();
    _scannerService = ref.read(scannerServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      title: Text(l10n.hardwareScannerActive),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(l10n.hardwareScannerInstructions),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))],
    );
  }
}
