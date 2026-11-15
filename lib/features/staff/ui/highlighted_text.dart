import 'package:flutter/material.dart';

/// Google-style yellow highlight for case-insensitive query matches.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    this.query,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.highlightColor,
  });

  final String text;
  final String? query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final q = query?.trim() ?? '';
    if (q.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = q.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    final hl = highlightColor ?? const Color(0xFFFFF59D);

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: TextStyle(
            backgroundColor: hl,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = index + q.length;
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
