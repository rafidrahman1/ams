import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/asset_card_builder.dart';
import '../core/utils/ast_id_parser.dart';
import '../pages/asset_checklist_screen.dart';
import '../providers/qr_scanner_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  var _scanStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openScanner());
  }

  Future<void> _openScanner() async {
    if (_scanStarted || !mounted) {
      return;
    }
    _scanStarted = true;

    final l10n = AppLocalizations.of(context)!;
    final scannedValue = await ref.read(qrScannerLauncherProvider)(context);
    final scannedAstId = normalizeAstId(scannedValue);
    final expectedAstId = normalizeAstId(widget.asset.astId);

    if (!mounted) {
      return;
    }

    if (scannedAstId == null) {
      Navigator.of(context).maybePop();
      return;
    }

    if (scannedAstId == expectedAstId) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: widget.asset)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.qrScanMismatch)));
    _scanStarted = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrScannerTitle)),
      body: const Center(
        child: CircularProgressIndicator(color: ThemeColor.primary),
      ),
    );
  }
}
