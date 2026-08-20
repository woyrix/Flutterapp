import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/reader_provider.dart';
import 'providers/favourites_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PriyatamKavyaApp());
}

class PriyatamKavyaApp extends StatelessWidget {
  const PriyatamKavyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ReaderProvider()),
        ChangeNotifierProvider(create: (_) => FavouritesProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (_, app, __) => MaterialApp(
          title: 'प्रियतम काव्य',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(app.accent.light),
          darkTheme: AppTheme.dark(app.accent.dark),
          themeMode: app.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 180),
          themeAnimationCurve: Curves.easeOutCubic,
          builder: (context, child) => DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
