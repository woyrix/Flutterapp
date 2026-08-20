import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class FontSizeSlider extends StatefulWidget {
  const FontSizeSlider({super.key});

  @override
  State<FontSizeSlider> createState() => _FontSizeSliderState();
}

class _FontSizeSliderState extends State<FontSizeSlider> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
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
                child: ValueListenableBuilder<double>(
                  valueListenable: app.fontSizePreview,
                  builder: (context, previewValue, _) {
                    final value = _dragValue ?? previewValue;

                    return Slider(
                      value: value,
                      min: AppProvider.minFont,
                      max: AppProvider.maxFont,
                      activeColor: cs.primary,
                      inactiveColor: cs.primary.withOpacity(0.2),
                      onChanged: (v) {
                        _dragValue = v;
                        app.previewFontSize(v);
                      },
                      onChangeEnd: (v) {
                        _dragValue = null;
                        app.commitFontSize(v);
                      },
                    );
                  },
                ),
              ),
              Icon(Icons.text_increase_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              ValueListenableBuilder<double>(
                valueListenable: app.fontSizePreview,
                builder: (context, previewValue, _) {
                  final value = _dragValue ?? previewValue;

                  return Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text(
                      '${value.round()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
