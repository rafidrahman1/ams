import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      _finishWithResult(null);
      return;
    }

    _sessionActive = true;
    await NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        final scannedValue = await _extractTagValue(tag);

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

  Future<String?> _extractTagValue(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      return null;
    }

    final message = ndef.cachedMessage ?? await ndef.read();

    for (final record in message.records) {
      final value = _parseRecordPayload(record);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String? _parseRecordPayload(NdefRecord record) {
    if (record.payload.isEmpty) {
      return null;
    }

    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
        utf8.decode(record.type, allowMalformed: true) == 'T') {
      final statusByte = record.payload.first;
      final languageCodeLength = statusByte & 0x3F;
      if (record.payload.length <= languageCodeLength + 1) {
        return null;
      }
      return utf8
          .decode(
            record.payload.sublist(languageCodeLength + 1),
            allowMalformed: true,
          )
          .trim();
    }

    return utf8.decode(record.payload, allowMalformed: true).trim();
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
    await _stopSession();
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
              OutlinedButton(
                onPressed: () => _finishWithResult(null),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
