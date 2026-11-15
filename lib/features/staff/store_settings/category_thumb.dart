import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/category_icons.dart';
import '../../../core/theme.dart';

class CategoryThumb extends StatelessWidget {
  const CategoryThumb({
    super.key,
    required this.slug,
    this.iconUrl,
    this.size = 48,
  });

  final String slug;
  final String? iconUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final src = resolveCategoryImageSrc(iconUrl, slug);
    final style = categoryIconStyle(slug);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: src == null
          ? Icon(style.icon, color: style.foreground, size: size * 0.42)
          : isNetworkCategoryImage(src)
              ? CachedNetworkImage(
                  imageUrl: src,
                  fit: BoxFit.contain,
                  width: size,
                  height: size,
                  errorWidget: (_, __, ___) => Icon(
                    style.icon,
                    color: style.foreground,
                    size: size * 0.42,
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(size * 0.08),
                  child: Image.asset(
                    src,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      style.icon,
                      color: style.foreground,
                      size: size * 0.42,
                    ),
                  ),
                ),
    );
  }
}
