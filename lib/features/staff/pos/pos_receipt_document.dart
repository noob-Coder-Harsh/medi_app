import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/i18n.dart';
import 'pos_receipt.dart';

/// Builds an 80mm thermal Tax Invoice as PDF and PNG.
abstract final class PosReceiptDocument {
  static const double thermalWidthMm = 80;
  static const double thermalDpi = 203;

  static PdfPageFormat get pageFormat => PdfPageFormat(
        thermalWidthMm * PdfPageFormat.mm,
        double.infinity,
        marginAll: 3 * PdfPageFormat.mm,
      );

  static Future<Uint8List> buildPdf(PosReceiptSnapshot receipt) async {
    final doc = pw.Document();
    final labels = _Labels.current();
    final when = DateFormat('dd/MM/yyyy HH:mm').format(receipt.placedAt.toLocal());
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: base, bold: bold);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: <pw.Widget>[
              pw.Center(
                child: pw.Text(
                  receipt.storeName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              for (final line in receipt.storeAddressLines)
                pw.Center(
                  child: pw.Text(
                    line,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
              if (receipt.gstin != null)
                pw.Center(
                  child: pw.Text(
                    'GSTIN: ${receipt.gstin}',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
              if (receipt.drugLicense != null)
                pw.Center(
                  child: pw.Text(
                    'DL No: ${receipt.drugLicense}',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
              _dash(),
              pw.Center(
                child: pw.Text(
                  labels.invoice,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              _dash(),
              _metaRow('Bill No', '${receipt.billNumber}'),
              _metaRow('Date', when),
              if ((receipt.customerPhone ?? '').isNotEmpty)
                _metaRow(labels.phone, receipt.customerPhone!),
              if ((receipt.customerName ?? '').trim().isNotEmpty)
                _metaRow(labels.customer, receipt.customerName!.trim()),
              _dash(),
              _headerRow(labels),
              _dash(),
              for (final line in receipt.lines) _itemRow(line),
              _dash(),
              if (receipt.mrpSavings > 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    labels.savedOnMrp.replaceAll(
                      '{amount}',
                      _money(receipt.mrpSavings),
                    ),
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
              _totalRow('Subtotal', _money(receipt.subtotal)),
              if (receipt.discount > 0)
                _totalRow(labels.discount, '- ${_money(receipt.discount)}'),
              _totalRow(
                'TOTAL',
                _money(receipt.totalPayable),
                bold: true,
              ),
              _metaRow(labels.payment, receipt.paymentMethod),
              _dash(),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  labels.thankYou,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildPng(PosReceiptSnapshot receipt) async {
    final pdfBytes = await buildPdf(receipt);
    await for (final page in Printing.raster(
      pdfBytes,
      dpi: thermalDpi,
      pages: const <int>[0],
    )) {
      return page.toPng();
    }
    throw StateError('Receipt raster produced no pages');
  }

  static String fileStem(PosReceiptSnapshot receipt) =>
      'tax-invoice-${receipt.billNumber}';

  static String _money(num amount) {
    final digits = amount % 1 == 0 ? 0 : 2;
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs.',
      decimalDigits: digits,
    ).format(amount);
  }

  static String _qty(double qty) {
    if (qty == qty.roundToDouble()) return '${qty.round()}';
    return qty.toStringAsFixed(2);
  }

  static pw.Widget _dash() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(
        '-' * 42,
        style: const pw.TextStyle(fontSize: 6.5),
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text('$label:', style: const pw.TextStyle(fontSize: 7.5)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 7.5)),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 9 : 7.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static pw.Widget _headerRow(_Labels labels) {
    return pw.Row(
      children: <pw.Widget>[
        pw.Expanded(
          flex: 34,
          child: pw.Text(labels.item, style: _colHead),
        ),
        pw.Expanded(
          flex: 16,
          child: pw.Text(labels.mrp, style: _colHead, textAlign: pw.TextAlign.right),
        ),
        pw.Expanded(
          flex: 16,
          child: pw.Text(labels.price, style: _colHead, textAlign: pw.TextAlign.right),
        ),
        pw.Expanded(
          flex: 12,
          child: pw.Text(labels.qty, style: _colHead, textAlign: pw.TextAlign.right),
        ),
        pw.Expanded(
          flex: 18,
          child: pw.Text(labels.amount, style: _colHead, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static pw.Widget _itemRow(PosReceiptLine line) {
    final mrpText = line.mrp == null || line.mrp! <= 0
        ? '-'
        : _money(line.mrp!);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Text(line.name, style: const pw.TextStyle(fontSize: 7.5)),
          pw.Row(
            children: <pw.Widget>[
              pw.Expanded(flex: 34, child: pw.SizedBox()),
              pw.Expanded(
                flex: 16,
                child: pw.Text(
                  mrpText,
                  style: _colBody,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 16,
                child: pw.Text(
                  _money(line.unitPrice),
                  style: _colBody,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 12,
                child: pw.Text(
                  _qty(line.quantity),
                  style: _colBody,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 18,
                child: pw.Text(
                  _money(line.lineTotal),
                  style: _colBody,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final _colHead = pw.TextStyle(
    fontSize: 7,
    fontWeight: pw.FontWeight.bold,
  );
  static const _colBody = pw.TextStyle(fontSize: 7);
}

class _Labels {
  const _Labels({
    required this.invoice,
    required this.item,
    required this.mrp,
    required this.price,
    required this.qty,
    required this.amount,
    required this.savedOnMrp,
    required this.thankYou,
    required this.customer,
    required this.phone,
    required this.discount,
    required this.payment,
  });

  final String invoice;
  final String item;
  final String mrp;
  final String price;
  final String qty;
  final String amount;
  final String savedOnMrp;
  final String thankYou;
  final String customer;
  final String phone;
  final String discount;
  final String payment;

  factory _Labels.current() {
    return _Labels(
      invoice: t('STORE_FORM.POS_RECEIPT_INVOICE'),
      item: t('STORE_FORM.POS_RECEIPT_ITEM'),
      mrp: t('STORE_FORM.POS_RECEIPT_MRP'),
      price: t('STORE_FORM.POS_RECEIPT_PRICE'),
      qty: t('STORE_FORM.POS_RECEIPT_QTY'),
      amount: t('STORE_FORM.POS_RECEIPT_AMOUNT'),
      savedOnMrp: t('STORE_FORM.POS_RECEIPT_SAVED_ON_MRP'),
      thankYou: t('STORE_FORM.POS_RECEIPT_THANK_YOU'),
      customer: t('STORE_FORM.POS_RECEIPT_CUSTOMER'),
      phone: t('STORE_FORM.POS_RECEIPT_PHONE'),
      discount: t('STORE_FORM.POS_DISCOUNT'),
      payment: t('STORE_FORM.POS_PAYMENT_METHOD'),
    );
  }
}
