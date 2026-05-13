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

  ScannerService(this._ref) {
    _init();
  }

  void _init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "onScanReceived") {
        final String barcode = call.arguments;
        _ref.read(scannerResultProvider.notifier).update(barcode);
      }
    });
  }

  Future<void> wakeUpScanner() async {
    try {
      await _channel.invokeMethod('startHardwareScan');
    } on PlatformException {
      // Scanner wake-up failed silently
    }
  }

  Future<void> stopScanner() async {
    try {
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
