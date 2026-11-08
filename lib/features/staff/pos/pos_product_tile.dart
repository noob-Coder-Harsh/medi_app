import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/packaging.dart';
import '../../../core/theme.dart';
import 'pos_product.dart';

class PosProductTile extends StatelessWidget {
  const PosProductTile({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.onAdd,
  });

  final PosProduct product;
  final int quantityInCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packaging = product.packaging;
    final listedPrice = hasRetailPack(packaging)
        ? calculatePackPrice(product.unitPrice, packaging)
        : product.unitPrice;
    final enabled = product.hasStock;
    final inCart = quantityInCart > 0;
    final nameStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final nameLineHeight = (nameStyle?.fontSize ?? 12) * (nameStyle?.height ?? 1.2);

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: inCart && enabled ? Brand.themeColor : AppTheme.hairlineColor,
          width: inCart && enabled ? 2 : AppTheme.hairline,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onAdd : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ColoredBox(
                          color: Brand.themeBackground,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              _image(),
                              if (product.requiresPrescription)
                                Positioned(
                                  left: 3,
                                  top: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.amber,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Rx',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: nameLineHeight * 2,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            formatPosPackMeta(packaging),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          Format.rupee(listedPrice),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (inCart)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Brand.themeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      quantityInCart > 99 ? '99+' : '$quantityInCart',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
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

  Widget _image() {
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        errorWidget: (BuildContext context, String url, Object error) {
          return _initials();
        },
      );
    }
    return _initials();
  }

  Widget _initials() {
    final letters = product.name.trim().isEmpty
        ? '?'
        : product.name.trim().substring(
            0,
            product.name.trim().length >= 2 ? 2 : 1,
          );
    return Center(
      child: Text(
        letters.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
