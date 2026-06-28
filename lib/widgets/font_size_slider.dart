import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class FontSizeSlider extends StatelessWidget {
  const FontSizeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF160D04) : const Color(0xFFFAF6EE),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cs.primary.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.text_decrease_rounded, size: 18, color: cs.primary),
              Expanded(
                child: Slider(
                  value: app.fontSize,
                  min: AppProvider.minFont,
                  max: AppProvider.maxFont,
                  activeColor: cs.primary,
                  inactiveColor: cs.primary.withOpacity(0.2),
                  onChanged: (v) => app.setFontSize(v),
                ),
              ),
              Icon(Icons.text_increase_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Container(
                width: 28,
                alignment: Alignment.center,
                child: Text(
                  '${app.fontSize.round()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}