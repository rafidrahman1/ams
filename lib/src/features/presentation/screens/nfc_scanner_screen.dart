import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../utils/nfc_parser.dart';

class NfcScannerScreen extends StatefulWidget {
  const NfcScannerScreen({super.key, this.testScanValue});

  final String? testScanValue;

  @override
  State<NfcScannerScreen> createState() => _NfcScannerScreenState();
}

class _NfcScannerScreenState extends State<NfcScannerScreen> {
  bool _completed = false;
  bool _sessionActive = false;
  String _status = 'Hold the NFC tag close to the device';

  @override
  void initState() {
    super.initState();

    if (widget.testScanValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishWithResult(widget.testScanValue);
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  @override
  void dispose() {
    _stopSession();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (_completed || !mounted) {
      return;
    }

    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC is not available on this device')));
      _finishWithResult(null);
      return;
    }

    _sessionActive = true;
    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (tag) async {
        final scannedValue = await NfcParser.extractTagValue(tag);

        if (scannedValue == null || scannedValue.isEmpty) {
          if (mounted) {
            setState(() {
              _status = 'Tag detected, but no readable asset id was found';
            });
          }
          return;
        }

        _finishWithResult(scannedValue);
      },
      onError: (error) async {
        if (mounted) {
          setState(() {
            _status = error.message;
          });
        }
        await _stopSession();
      },
    );
  }

  Future<void> _stopSession() async {
    if (!_sessionActive) {
      return;
    }
    _sessionActive = false;

    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Session may already be closed.
    }
  }

  Future<void> _finishWithResult(String? value) async {
    if (_completed || !mounted) return;
    _completed = true;

    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan NFC Tag')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nfc, size: 80),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: () => _finishWithResult(null), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}
