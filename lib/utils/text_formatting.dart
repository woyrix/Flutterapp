class TextFormatting {
  TextFormatting._();

  static String displayPlainText(String value) {
    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ');

    final lines = normalized.split('\n').map((line) {
      var out = line.trimRight();
      out = out.replaceFirst(RegExp(r'^\s*##\s*'), '');
      out = out.replaceFirst(RegExp(r'^\s*\[C\]\s*'), '');
      out = out.replaceAll('**', '');
      return out.trimRight();
    }).toList();

    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
