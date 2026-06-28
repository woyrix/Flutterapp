import 'image_download_helper_io.dart'
    if (dart.library.html) 'image_download_helper_web.dart';

Future<String> downloadAssetImage({
  required String assetPath,
  required String title,
}) {
  return downloadAssetImageImpl(assetPath: assetPath, title: title);
}
