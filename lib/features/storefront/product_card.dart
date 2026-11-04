import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models/listing.dart';
import '../cart/qty_stepper.dart';

/// Customer read-model tile. Does not show warehouse qty, GST, HSN, or batches.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.card,
    required this.storeId,
    this.onTap,
    this.compact = false,
  });

  final ListingCard card;
  final String storeId;
  final VoidCallback? onTap;
  final bool compact;

  bool get _out {
    return !card.inStock || card.availableQuantity <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bits = <String>[
      if (card.strength != null && card.strength!.isNotEmpty) card.strength!,
      if (card.dosageForm != null && card.dosageForm!.isNotEmpty)
        card.dosageForm!,
    ];
    final price = card.sellingPrice ?? 0;
    final mrp = card.mrp;
    final strike = mrp != null && mrp > price;

    final body = compact
        ? _compactBody(text, price)
        : _rowBody(text, bits, price, strike, mrp);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadius,
        child: body,
      ),
    );
  }

  Widget _rowBody(
    TextTheme text,
    List<String> bits,
    num price,
    bool strike,
    double? mrp,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _thumb(72),
          const SizedBox(width: 12),
          Expanded(child: _copy(text, bits, price, strike, mrp)),
          const SizedBox(width: 8),
          CartAddControl(card: card, storeId: storeId),
        ],
      ),
    );
  }

  Widget _compactBody(TextTheme text, num price) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(child: _thumb(48)),
          const SizedBox(height: 6),
          Text(
            card.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
          if (card.genericName != null && card.genericName!.isNotEmpty)
            Text(
              card.genericName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          Text(
            card.packLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
          if (card.requiresPrescription)
            Text(
              t('STOREFRONT.REQUIRES_RX'),
              maxLines: 1,
              style: text.labelSmall,
            ),
          if (_out) Text(Format.stock(0), style: text.labelSmall),
          const Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  Format.rupee(price),
                  style: AppTheme.rupee(text.titleSmall!),
                ),
              ),
              CartAddControl(card: card, storeId: storeId, compact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _copy(
    TextTheme text,
    List<String> bits,
    num price,
    bool strike,
    double? mrp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          card.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall,
        ),
        if (bits.isNotEmpty)
          Text(
            bits.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
        if (card.genericName != null && card.genericName!.isNotEmpty)
          Text(
            card.genericName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
        Text(card.packLabel, style: text.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: <Widget>[
            Text(
              Format.rupee(price),
              style: AppTheme.rupee(text.titleSmall!),
            ),
            if (strike)
              Text(
                Format.rupee(mrp!),
                style: AppTheme.rupee(text.bodySmall!).copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (card.requiresPrescription)
          Text(t('STOREFRONT.REQUIRES_RX'), style: text.labelSmall),
        if (_out) Text(Format.stock(0), style: text.labelSmall),
      ],
    );
  }

  Widget _thumb(double size) {
    final url = card.thumb ?? card.imageUrl;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadius,
          border: Border.all(
            color: AppTheme.hairlineColor,
            width: AppTheme.hairline,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppTheme.borderRadius,
          child: url == null || url.isEmpty
              ? const Icon(Icons.medication_outlined)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (BuildContext context, String _) {
                    return const SizedBox.expand();
                  },
                  errorWidget: (BuildContext context, String _, Object __) {
                    return const Icon(Icons.medication_outlined);
                  },
                ),
        ),
      ),
    );
  }
}
