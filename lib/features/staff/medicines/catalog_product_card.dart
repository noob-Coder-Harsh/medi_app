import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/listing.dart';

enum CatalogProductAction { edit, addBatch, toggleActive }

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  final ListingCard item;
  final VoidCallback onTap;
  final ValueChanged<CatalogProductAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = item.sellingPrice;
    final badge = _stockBadge(item);
    final meta = _metaLabel(item);
    final manufacturer = item.manufacturer?.trim() ?? '';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Thumb(name: item.name, url: item.imageUrl ?? item.thumb),
                  const SizedBox(height: 6),
                  _StockBadge(badge: badge),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                        PopupMenuButton<CatalogProductAction>(
                          tooltip: t('STORE_FORM.CATALOG_EDIT_META'),
                          padding: EdgeInsets.zero,
                          onSelected: onAction,
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<CatalogProductAction>>[
                              PopupMenuItem<CatalogProductAction>(
                                value: CatalogProductAction.edit,
                                child: Text(t('STORE_FORM.CATALOG_EDIT_META')),
                              ),
                              PopupMenuItem<CatalogProductAction>(
                                value: CatalogProductAction.addBatch,
                                child: Text(t('STORE_FORM.ADD_BATCH')),
                              ),
                              PopupMenuItem<CatalogProductAction>(
                                value: CatalogProductAction.toggleActive,
                                child: Text(
                                  item.isActive
                                      ? t('STORE_FORM.BULK_SET_INACTIVE')
                                      : t('STORE_FORM.CATALOG_SET_ACTIVE'),
                                ),
                              ),
                            ];
                          },
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                            child: Icon(Icons.more_vert, size: 20),
                          ),
                        ),
                      ],
                    ),
                    if (manufacturer.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        manufacturer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: meta.isEmpty
                              ? const SizedBox.shrink()
                              : Text(
                                  meta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          price == null ? '—' : Format.rupee(price),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    if (!item.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          t('STORE_FORM.SUPPLIER_STATUS_INACTIVE'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _metaLabel(ListingCard item) {
    final parts = <String>[
      if (item.dosageForm != null && item.dosageForm!.trim().isNotEmpty)
        item.dosageForm!.trim(),
      if (item.strength != null && item.strength!.trim().isNotEmpty)
        item.strength!.trim(),
      if (item.packLabel.trim().isNotEmpty) item.packLabel.trim(),
    ];
    return parts.join(' • ');
  }

  static _StockBadgeData _stockBadge(ListingCard item) {
    final qty = item.availableQuantity;
    if (qty <= 0) {
      return _StockBadgeData(
        label: t('STOREFRONT.OUT_OF_STOCK'),
        background: const Color(0xFFFEE2E2),
        foreground: AppTheme.error,
      );
    }
    if (item.reorderLevel > 0 && qty <= item.reorderLevel) {
      return _StockBadgeData(
        label: '${t('TODAY.LOW_STOCK')} (${Format.stock(qty)})',
        background: const Color(0xFFFEF3C7),
        foreground: AppTheme.amber,
      );
    }
    return _StockBadgeData(
      label: '${t('STOREFRONT.IN_STOCK')} (${Format.stock(qty)})',
      background: const Color(0xFFD1FAE5),
      foreground: Brand.themeColor,
    );
  }
}

class _StockBadgeData {
  const _StockBadgeData({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.badge});

  final _StockBadgeData badge;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 72),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: badge.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          badge.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: badge.foreground,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.15,
              ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: Brand.themeBackground,
        child: SizedBox(
          width: 64,
          height: 64,
          child: url != null && url!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.contain,
                  errorWidget:
                      (BuildContext context, String url, Object error) {
                    return _initials();
                  },
                )
              : _initials(),
        ),
      ),
    );
  }

  Widget _initials() {
    final trimmed = name.trim();
    final letters = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
    return Center(
      child: Text(
        letters.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
