import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../pos/pos_receipt.dart';
import '../pos/pos_receipt_document.dart';

Future<void> showOrderReceiptPreview(
  BuildContext context, {
  required PosReceiptSnapshot receipt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheet) {
      return OrderReceiptSheet(receipt: receipt);
    },
  );
}

class OrderReceiptSheet extends ConsumerStatefulWidget {
  const OrderReceiptSheet({super.key, required this.receipt});

  final PosReceiptSnapshot receipt;

  @override
  ConsumerState<OrderReceiptSheet> createState() => _OrderReceiptSheetState();
}

class _OrderReceiptSheetState extends ConsumerState<OrderReceiptSheet> {
  Uint8List? _previewPng;
  Object? _previewError;
  var _busy = false;
  var _loadingPreview = true;

  PosReceiptSnapshot get receipt => widget.receipt;

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

  Future<File> _writeTemp(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _writeDocuments(String name, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _savePdf() async {
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

  Future<void> _saveImage() async {
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

  Future<void> _sharePdf() async {
    final bytes = await PosReceiptDocument.buildPdf(receipt);
    final file = await _writeTemp(
      '${PosReceiptDocument.fileStem(receipt)}.pdf',
      bytes,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'application/pdf')],
        subject: t('STORE_FORM.POS_RECEIPT_INVOICE'),
      ),
    );
  }

  Future<void> _shareImage() async {
    final bytes = _previewPng ?? await PosReceiptDocument.buildPng(receipt);
    final file = await _writeTemp(
      '${PosReceiptDocument.fileStem(receipt)}.png',
      bytes,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'image/png')],
        subject: t('STORE_FORM.POS_RECEIPT_INVOICE'),
      ),
    );
  }

  Future<void> _print() async {
    final bytes = await PosReceiptDocument.buildPdf(receipt);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: PosReceiptDocument.fileStem(receipt),
    );
  }

  void _showSaveOverlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheet) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.hairlineColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t('STORE_FORM.POS_SHARE_RECEIPT'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.image_outlined, color: Brand.themeColor),
                  title: Text(t('STORE_FORM.POS_SAVE_IMAGE')),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _run(_saveImage);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Brand.themeColor,
                  ),
                  title: Text(t('STORE_FORM.POS_SAVE_PDF')),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _run(_savePdf);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined),
                  title: Text(t('STORE_FORM.POS_SHARE_IMAGE')),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _run(_shareImage);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(t('STORE_FORM.POS_SHARE_PDF')),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _run(_sharePdf);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: const Color(0xFFF4F7F6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: maxHeight,
          width: double.infinity,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(
                      child: Text(
                        t('STORE_FORM.POS_PREVIEW_RECEIPT'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.hairlineColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _previewBody(theme),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: <Widget>[
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LinearProgressIndicator(),
                        ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _showSaveOverlay,
                              icon: const Icon(Icons.save_alt_outlined, size: 18),
                              label: Text(t('STORE_FORM.POS_SHARE_RECEIPT')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy ? null : () => _run(_print),
                              style: FilledButton.styleFrom(
                                backgroundColor: Brand.themeColor,
                              ),
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: Text(t('STORE_FORM.POS_PRINT_RECEIPT')),
                            ),
                          ),
                        ],
                      ),
                    ],
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_previewError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$_previewError',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.error),
          ),
        ),
      );
    }
    final bytes = _previewPng;
    if (bytes == null) {
      return const Center(child: Text('—'));
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
