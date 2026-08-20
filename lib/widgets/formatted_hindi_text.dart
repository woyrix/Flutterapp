import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormattedHindiText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color primaryColor;
  final TextAlign textAlign;

  const FormattedHindiText({
    super.key,
    required this.text,
    required this.style,
    required this.primaryColor,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.trim().split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          _FormattedLine(
            line: line,
            style: style,
            primaryColor: primaryColor,
            textAlign: textAlign,
          ),
      ],
    );
  }
}

class _FormattedLine extends StatelessWidget {
  final String line;
  final TextStyle style;
  final Color primaryColor;
  final TextAlign textAlign;

  const _FormattedLine({
    required this.line,
    required this.style,
    required this.primaryColor,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    if (line.trim().isEmpty) {
      return SizedBox(height: (style.fontSize ?? 16) * 0.65);
    }

    final trimmedLeft = line.trimLeft();
    final leadingSpaces = line.length - trimmedLeft.length;
    final isHeading = trimmedLeft.startsWith('##');
    final markerParsed = _parseAlignmentMarker(
      isHeading ? trimmedLeft.replaceFirst('##', '').trimLeft() : line,
    );
    final displayLine = isHeading
        ? markerParsed.text.trim()
        : markerParsed.text.replaceAll('\t', '    ');
    final spans = _spansFor(displayLine, style);

    if (isHeading) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: RichText(
          textAlign: TextAlign.center,
          locale: const Locale('hi', 'IN'),
          text: TextSpan(
            style: style.copyWith(
              color: primaryColor,
              fontSize: (style.fontSize ?? 16) + 2,
              fontWeight: FontWeight.w900,
            ),
            children: spans,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        textAlign: markerParsed.textAlign ?? textAlign,
        locale: const Locale('hi', 'IN'),
        text: TextSpan(
          style: style,
          children: [
            if (leadingSpaces > 0)
              WidgetSpan(
                child: SizedBox(
                    width: leadingSpaces * (style.fontSize ?? 16) * 0.35),
              ),
            ...spans,
          ],
        ),
      ),
    );
  }

  List<TextSpan> _spansFor(String source, TextStyle baseStyle) {
    final parts = source.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? baseStyle.copyWith(fontWeight: FontWeight.w900)
              : baseStyle,
        ),
    ];
  }
}

class _ParsedAlignmentMarker {
  const _ParsedAlignmentMarker(this.text, this.textAlign);

  final String text;
  final TextAlign? textAlign;
}

_ParsedAlignmentMarker _parseAlignmentMarker(String source) {
  final trimmedLeft = source.trimLeft();
  final markerMatch = RegExp(r'^\[(L|R|C)\]\s*', caseSensitive: false)
      .firstMatch(trimmedLeft);
  if (markerMatch == null) {
    return _ParsedAlignmentMarker(source, null);
  }

  final marker = markerMatch.group(1)?.toUpperCase();
  final text = trimmedLeft.substring(markerMatch.end);
  final textAlign = switch (marker) {
    'L' => TextAlign.left,
    'R' => TextAlign.right,
    _ => TextAlign.center,
  };
  return _ParsedAlignmentMarker(text, textAlign);
}

TextStyle formattedHindiBodyStyle(
  BuildContext context, {
  required double fontSize,
  double height = 1.85,
}) {
  final cs = Theme.of(context).colorScheme;
  return GoogleFonts.notoSerifDevanagari(
    color: cs.onBackground,
    fontSize: fontSize,
    height: height,
    letterSpacing: 0,
    wordSpacing: 0,
  );
}
