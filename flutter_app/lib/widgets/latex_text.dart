import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../core/theme.dart';

class LatexText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LatexText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final parts = text.split('\$');
    if (parts.length == 1) {
      return Text(text, style: style);
    }

    List<InlineSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;

      if (i % 2 == 1) {
        // Math mode
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              part,
              textStyle: style,
              onErrorFallback: (err) => Text(
                '\$$part\$',
                style: style?.copyWith(color: Colors.red) ?? const TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
      } else {
        // Text mode
        spans.add(TextSpan(text: part, style: style));
      }
    }

    return RichText(
      text: TextSpan(
        style: style ?? const TextStyle(color: AppTheme.black),
        children: spans,
      ),
    );
  }
}
