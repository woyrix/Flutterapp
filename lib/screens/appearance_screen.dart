import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/app_provider.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  int _tab = 0;

  void _closeToDrawer() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _closeToDrawer,
          ),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Theme Colour & Appearance',
              maxLines: 1,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            Text(
              'अपनी reading preference चुनें',
              locale: const Locale('hi', 'IN'),
              style: GoogleFonts.notoSerifDevanagari(
                color: cs.onBackground.withOpacity(0.56),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            _TabSwitch(
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
              cs: cs,
            ),
            const SizedBox(height: 26),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: _tab == 0
                  ? _ModeSection(
                      key: const ValueKey('mode'),
                      app: app,
                      cs: cs,
                    )
                  : _ColourSection(
                      key: const ValueKey('colour'),
                      app: app,
                      cs: cs,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSwitch extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final ColorScheme cs;

  const _TabSwitch({
    required this.selected,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Appearance',
            selected: selected == 0,
            onTap: () => onChanged(0),
            cs: cs,
          ),
          _TabItem(
            label: 'Theme Colour',
            selected: selected == 1,
            onTap: () => onChanged(1),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cs.background : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(color: cs.primary.withOpacity(0.22))
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? cs.primary : cs.onSurface.withOpacity(0.58),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSection extends StatelessWidget {
  final AppProvider app;
  final ColorScheme cs;

  const _ModeSection({
    super.key,
    required this.app,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Mode', cs: cs),
        const SizedBox(height: 10),
        _ModeRow(
          title: 'Light',
          subtitle: 'Bright and clean',
          icon: Icons.light_mode_rounded,
          selected: app.themeMode == ThemeMode.light,
          onTap: () =>
              context.read<AppProvider>().setThemeMode(ThemeMode.light),
          cs: cs,
        ),
        _Divider(cs: cs),
        _ModeRow(
          title: 'Dark',
          subtitle: 'Comfortable in low light',
          icon: Icons.dark_mode_rounded,
          selected: app.themeMode == ThemeMode.dark,
          onTap: () => context.read<AppProvider>().setThemeMode(ThemeMode.dark),
          cs: cs,
        ),
      ],
    );
  }
}

class _ModeRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _ModeRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? cs.primary : cs.onSurface.withOpacity(0.28),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColourSection extends StatelessWidget {
  final AppProvider app;
  final ColorScheme cs;

  const _ColourSection({
    super.key,
    required this.app,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Accent Colour', cs: cs),
        const SizedBox(height: 6),
        Text(
          app.accent.name,
          locale: const Locale('hi', 'IN'),
          style: GoogleFonts.notoSerifDevanagari(
            color: cs.primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 16,
          children: List.generate(AppProvider.accents.length, (index) {
            final accent = AppProvider.accents[index];
            final color = isDark ? accent.dark : accent.light;
            final selected = app.accentIndex == index;

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.read<AppProvider>().setAccent(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? cs.onSurface : Colors.transparent,
                    width: selected ? 2.4 : 0,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _SectionLabel(this.text, {required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: cs.onBackground.withOpacity(0.64),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme cs;

  const _Divider({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: cs.outline.withOpacity(0.18),
      thickness: 0.8,
    );
  }
}
