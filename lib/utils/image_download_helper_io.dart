import 'dart:io';

import 'package:flutter/services.dart';

const _galleryChannel = MethodChannel('priyatam_kavya/gallery_saver');

Future<String> downloadAssetImageImpl({
  required String assetPath,
  required String title,
}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  final fileName = _fileNameFor(assetPath, title);

  if (Platform.isAndroid) {
    final saved = await _galleryChannel.invokeMethod<String>('saveImage', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': _mimeTypeFor(assetPath),
    });
    return saved ?? 'Gallery';
  }

  final directory = await _downloadsDirectory();
  final file = await _uniqueFile(directory, fileName);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Directory> _downloadsDirectory() async {
  final env = Platform.environment;
  final candidates = <String?>[
    env['USERPROFILE'] == null ? null : '${env['USERPROFILE']}\\Downloads',
    env['HOME'] == null ? null : '${env['HOME']}/Downloads',
    Platform.isAndroid ? '/storage/emulated/0/Download' : null,
  ];

  for (final path in candidates) {
    if (path == null) continue;
    final directory = Directory(path);
    if (await directory.exists()) return directory;
  }

  return Directory.systemTemp;
}

Future<File> _uniqueFile(Directory directory, String fileName) async {
  final dot = fileName.lastIndexOf('.');
  final base = dot == -1 ? fileName : fileName.substring(0, dot);
  final extension = dot == -1 ? '' : fileName.substring(dot);
  var file = File('${directory.path}${Platform.pathSeparator}$fileName');
  var index = 1;

  while (await file.exists()) {
    file = File(
      '${directory.path}${Platform.pathSeparator}$base-$index$extension',
    );
    index += 1;
  }

  return file;
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
