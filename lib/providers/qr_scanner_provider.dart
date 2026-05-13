import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The Notifier that the UI will "watch"
class ScannerResultNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? value) => state = value;
}

final scannerResultProvider = NotifierProvider<ScannerResultNotifier, String?>(ScannerResultNotifier.new);

// 2. The Service that listens to the Native Bridge
final scannerServiceProvider = Provider((ref) {
  return ScannerService(ref);
});

class ScannerService {
  final Ref _ref;
  static const _channel = MethodChannel('com.catchbangladesh.ams/scanner');

  ScannerService(this._ref) {
    _init();
  }

  void _init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "onScanReceived") {
        final String barcode = call.arguments;
        // Update the state so the UI reacts
        _ref.read(scannerResultProvider.notifier).update(barcode);
      }
    });
  }

  Future<void> triggerHardwareScan() async {
    try {
      await _channel.invokeMethod('triggerHardwareScan');
    } catch (e) {
      debugPrint('Error triggering hardware scan: $e');
    }
  }
}

// Updated launcher to use the hardware scanner
final qrScannerLauncherProvider = Provider<Future<String?> Function(BuildContext context)>((ref) {
  return (context) async {
    // Ensure the service is initialized
    ref.read(scannerServiceProvider);

    // Reset any previous result
    ref.read(scannerResultProvider.notifier).update(null);

    // Show a dialog that waits for a scan
    return showDialog<String>(context: context, barrierDismissible: true, builder: (context) => const _HardwareScannerDialog());
  };
});

class _HardwareScannerDialog extends ConsumerStatefulWidget {
  const _HardwareScannerDialog({super.key});

  @override
  ConsumerState<_HardwareScannerDialog> createState() => _HardwareScannerDialogState();
}

class _HardwareScannerDialogState extends ConsumerState<_HardwareScannerDialog> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger the laser when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerServiceProvider).triggerHardwareScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for scan results and pop the dialog when a barcode is received
    ref.listen<String?>(scannerResultProvider, (previous, next) {
      if (next != null) {
        Navigator.of(context).pop(next);
      }
    });

    return AlertDialog(
      title: const Text('Hardware Scanner Active'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text('Please use the hardware scanner to scan the QR code.'),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
    );
  }
}
