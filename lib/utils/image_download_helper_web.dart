import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/services.dart';

Future<String> downloadAssetImageImpl({
  required String assetPath,
  required String title,
}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  final fileName = _fileNameFor(assetPath, title);
  final mimeType = _mimeTypeFor(assetPath);
  final base64Data = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:$mimeType;base64,$base64Data',
  )
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return fileName;
}

String _fileNameFor(String assetPath, String title) {
  final extension = assetPath.contains('.') ? assetPath.split('.').last : 'jpg';
  final safeTitle = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final base = safeTitle.isEmpty ? 'priyatam-kavya-image' : safeTitle;
  return '${base.length > 48 ? base.substring(0, 48).trim() : base}.$extension';
}

String _mimeTypeFor(String assetPath) {
  final extension = assetPath.split('.').last.toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}
