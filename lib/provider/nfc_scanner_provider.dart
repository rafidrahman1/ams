import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/nfc_scanner_screen.dart';

final nfcScannerLauncherProvider = Provider<Future<String?> Function(BuildContext context)>((ref) {
  return (context) async {
    return Navigator.of(context).push<String?>(MaterialPageRoute(builder: (_) => const NfcScannerScreen()));
  };
});
