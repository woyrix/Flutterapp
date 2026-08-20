import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps platform screenshot and screen-recording protection scoped to gallery UI.
class GalleryProtection {
  GalleryProtection._();

  static const _channel = MethodChannel('priyatam_kavya/gallery_protection');
  static bool _isListening = false;
  static final captured = ValueNotifier<bool>(false);

  static Future<void> enable() async {
    if (!_isListening) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'captureChanged' && call.arguments is bool) {
          captured.value = call.arguments as bool;
        }
      });
      _isListening = true;
    }
    final isCaptured = await _channel.invokeMethod<bool>('setProtected', true);
    captured.value = isCaptured ?? false;
  }

  static Future<void> disable() async {
    await _channel.invokeMethod<void>('setProtected', false);
    _channel.setMethodCallHandler(null);
    _isListening = false;
    captured.value = false;
  }
}
