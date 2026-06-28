import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccentOption {
  final String name; // Hindi name
  final Color light; // accent in light mode
  final Color dark; // accent in dark mode
  const AccentOption(this.name, this.light, this.dark);
}

class AppProvider extends ChangeNotifier {
  static const double minFont = 7.0;
  static const double maxFont = 34.0;
  static const double defaultFont = 9.0;

  // 18 accent options
  static const List<AccentOption> accents = [
    AccentOption('केसरी', Color(0xFFE8B84B), Color(0xFFE8B84B)),
    AccentOption('स्वर्ण', Color(0xFFB8860B), Color(0xFFFFD54F)),
    AccentOption('लाल', Color(0xFFC62828), Color(0xFFEF5350)),
    AccentOption('सिंदूरी', Color(0xFFD84315), Color(0xFFFF7043)),
    AccentOption('गुलाबी', Color(0xFFC2185B), Color(0xFFF06292)),
    AccentOption('बैंगनी', Color(0xFF6A1B9A), Color(0xFFBA68C8)),
    AccentOption('नीलम', Color(0xFF4527A0), Color(0xFF9575CD)),
    AccentOption('नीला', Color(0xFF1565C0), Color(0xFF42A5F5)),
    AccentOption('आसमानी', Color(0xFF0277BD), Color(0xFF4FC3F7)),
    AccentOption('फ़िरोज़ा', Color(0xFF00838F), Color(0xFF4DD0E1)),
    AccentOption('हरित', Color(0xFF2E7D32), Color(0xFF66BB6A)),
    AccentOption('पन्ना', Color(0xFF00695C), Color(0xFF4DB6AC)),
    AccentOption('मेहंदी', Color(0xFF558B2F), Color(0xFF9CCC65)),
    AccentOption('भूरा', Color(0xFF6D4C41), Color(0xFFA1887F)),
    AccentOption('ताम्र', Color(0xFFA1432B), Color(0xFFD98F73)),
    AccentOption('धूसर', Color(0xFF455A64), Color(0xFF90A4AE)),
    AccentOption('चंदन', Color(0xFF8D6E63), Color(0xFFD7CCC8)),
    AccentOption('कुंकुम', Color(0xFFAD1457), Color(0xFFEC407A)),
    AccentOption('प्रभा', Color(0xFF00A6FF), Color(0xFF36D7FF)),
    AccentOption('दीप्ति', Color(0xFF7C4DFF), Color(0xFFB388FF)),
    AccentOption('किरण', Color(0xFFFFB300), Color(0xFFFFD166)),
    AccentOption('आरुणि', Color(0xFFFF4D6D), Color(0xFFFF7A90)),
    AccentOption('मयूर', Color(0xFF00BFA5), Color(0xFF64FFDA)),
    AccentOption('चन्द्रिका', Color(0xFF5C6BC0), Color(0xFF9FA8DA)),
    AccentOption('माणिक्य', Color(0xFF9C174D), Color(0xFFFF5C93)),
  ];

  // 1. यहाँ डिफ़ॉल्ट मोड को हमेशा के लिए लाइट (उजाला) कर दिया है
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSize = defaultFont;
  int _accentIndex = 0;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  int get accentIndex => _accentIndex;
  bool get loaded => _loaded;
  AccentOption get accent => accents[_accentIndex];

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  AppProvider() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    final mode = p.getString('themeMode') ?? 'light';
    _themeMode = switch (mode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    _fontSize = (p.getDouble('fontSize') ?? defaultFont)
        .clamp(minFont, maxFont)
        .toDouble();
    _accentIndex = (p.getInt('accentIndex') ?? 0)
        .clamp(0, accents.length - 1)
        .toInt();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'themeMode',
        switch (_themeMode) {
          ThemeMode.light => 'light',
          ThemeMode.system => 'system',
          _ => 'dark',
        });
    await p.setDouble('fontSize', _fontSize);
    await p.setInt('accentIndex', _accentIndex);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _save();
    notifyListeners();
  }

  void setAccent(int index) {
    _accentIndex = index.clamp(0, accents.length - 1).toInt();
    _save();
    notifyListeners();
  }

  void setFontSize(double v) {
    _fontSize = v.clamp(minFont, maxFont).toDouble();
    _save();
    notifyListeners();
  }
}
