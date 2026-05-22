import 'dart:async';

import 'package:flutter/services.dart';

/// UHF RFID reader bridge over the shared scanner MethodChannel.
class UhfService {
  static const MethodChannel _channel = MethodChannel('com.catchbangladesh.ams/scanner');
  static final UhfService _instance = UhfService._();

  final StreamController<String> _tagController = StreamController<String>.broadcast();

  UhfService._();

  factory UhfService.instance() => _instance;

  /// Dispatched from [ScannerService] — do not register a second channel handler here.
  void handleNativeTag(String? tag) {
    if (tag != null && tag.isNotEmpty) {
      _tagController.add(tag);
    }
  }

  Stream<String> get tagStream => _tagController.stream;

  Future<bool> isAvailable() async {
    try {
      final res = await _channel.invokeMethod('isUhfAvailable');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startInventory() async {
    try {
      final res = await _channel.invokeMethod('startUhfInventory');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopInventory() async {
    try {
      final res = await _channel.invokeMethod('stopUhfInventory');
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
