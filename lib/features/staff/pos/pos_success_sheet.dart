import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/pos_checkout.dart';
import 'pos_receipt.dart';
import 'pos_receipt_document.dart';

/// Success popup after POS charge: preview + download + New Sale.
Future<void> showPosSuccessSheet(
  BuildContext context, {
  required PosCheckoutResult result,
  required PosReceiptSnapshot receipt,
  required VoidCallback onNewSale,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialog) {
      return PosSuccessSheet(
        result: result,
        receipt: receipt,
        onNewSale: onNewSale,
      );
    },
  );
}

class PosSuccessSheet extends ConsumerStatefulWidget {
  const PosSuccessSheet({
    super.key,
    required this.result,
    required this.receipt,
    required this.onNewSale,
  });

  final PosCheckoutResult result;
  final PosReceiptSnapshot receipt;
  final VoidCallback onNewSale;

  @override
  ConsumerState<PosSuccessSheet> createState() => _PosSuccessSheetState();
}

class _PosSuccessSheetState extends ConsumerState<PosSuccessSheet> {
  static const Color _mint = Color(0xFFE6F4F1);

  Uint8List? _previewPng;
  Object? _previewError;
  var _busy = false;
  var _loadingPreview = true;

  PosReceiptSnapshot get receipt => widget.receipt;
  PosCheckoutResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final bytes = await PosReceiptDocument.buildPng(receipt);
      if (!mounted) return;
      setState(() {
        _previewPng = bytes;
        _loadingPreview = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _previewError = error;
        _loadingPreview = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<File> _writeDocuments(String name, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _downloadPdf() async {
    final bytes = await PosReceiptDocument.buildPdf(receipt);
    final file = await _writeDocuments(
      '${PosReceiptDocument.fileStem(receipt)}.pdf',
      bytes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t('STORE_FORM.POS_SAVED_TO')}: ${file.path}'),
      ),
    );
  }

  Future<void> _downloadImage() async {
    final bytes = _previewPng ?? await PosReceiptDocument.buildPng(receipt);
    final file = await _writeDocuments(
      '${PosReceiptDocument.fileStem(receipt)}.png',
      bytes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t('STORE_FORM.POS_SAVED_TO')}: ${file.path}'),
      ),
    );
  }

  void _newSale() {
    Navigator.of(context).pop();
    widget.onNewSale();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final media = MediaQuery.sizeOf(context);
    final maxHeight = media.height * 0.88;
    final maxWidth = media.width.clamp(0, 420).toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Brand.themeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t('STORE_FORM.POS_ORDER_CREATED'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${result.orderNumber} · ${Format.rupee(receipt.totalPayable)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Brand.themeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                t('STORE_FORM.POS_PREVIEW_RECEIPT'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.hairlineColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _previewBody(theme),
                  ),
                ),
              ),
              if (_busy) ...<Widget>[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(_downloadImage),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(t('STORE_FORM.POS_DOWNLOAD_IMAGE')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(_downloadPdf),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(t('STORE_FORM.POS_DOWNLOAD_PDF')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: AppTheme.chargeHeight,
                child: FilledButton(
                  onPressed: _busy ? null : _newSale,
                  style: AppTheme.charge,
                  child: Text(
                    t('STORE_FORM.POS_NEW_SALE'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewBody(ThemeData theme) {
    if (_loadingPreview) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_previewError != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '$_previewError',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
        ),
      );
    }
    final bytes = _previewPng;
    if (bytes == null) {
      return const SizedBox(height: 120, child: Center(child: Text('—')));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
