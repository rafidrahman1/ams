import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeScannerScreen extends StatefulWidget {
  const QrCodeScannerScreen({super.key});

  @override
  State<QrCodeScannerScreen> createState() => _QrCodeScannerScreenState();
}

class _QrCodeScannerScreenState extends State<QrCodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _returnedResult = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finishWithResult(String? value) {
    if (_returnedResult || !mounted) return;
    _returnedResult = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final barcode = capture.barcodes.first;
              final value = barcode.rawValue?.trim();
              if (value != null && value.isNotEmpty) {
                _finishWithResult(value);
              }
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Point the camera at the QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
