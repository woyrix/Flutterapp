import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/app_provider.dart';
import '../providers/favourites_provider.dart';
import '../providers/reader_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/font_size_slider.dart';
import 'browse_search_screen.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().resetFontSize(AppProvider.defaultFont);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final favs = context.watch<FavouritesProvider>();
    final cs = Theme.of(context).colorScheme;
    final isFav = favs.isSaved(reader.bookIndex, reader.pageIndex);

    return Scaffold(
      key: homeScaffoldKey,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(context, reader, favs, isFav, cs),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification &&
              scrollInfo.scrollDelta != null &&
              scrollInfo.scrollDelta!.abs() > 1.5) {
            context.read<ReaderProvider>().hideSlider();
          }
          return false;
        },
        child: Stack(
          children: [
            Column(
              children: [
                const Expanded(child: ReaderScreen()),
              ],
            ),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.8),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: reader.sliderActive
                    ? const FontSizeSlider(key: ValueKey('slider'))
                    : const SizedBox.shrink(key: ValueKey('no_slider')),
              ),
            ),
            const Positioned.fill(child: _FontSizeApplyingOverlay()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ReaderProvider reader,
    FavouritesProvider favs,
    bool isFav,
    ColorScheme cs,
  ) {
    return AppBar(
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 48,
      leading: Builder(
        builder: (ctx) => IconButton(
          tooltip: 'मेन्यू',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const SizedBox.shrink(),
      flexibleSpace: SafeArea(
        child: IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 65,
                right: 146,
                top: 08,
                bottom: 01,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, 0.34),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ));

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: _HomeAppBarTitle(
                    key: const ValueKey('home-title'),
                    title: 'प्रियतम काव्य',
                    compact: false,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        _AnimatedIconButton(
          tooltip: 'खोजें',
          icon: Icons.search_rounded,
          color: cs.primary.withOpacity(0.45),
          onTap: () {
            context.read<ReaderProvider>().hideSlider();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withOpacity(0.28),
              builder: (_) => const BrowseSearchScreen(),
            );
          },
        ),
        _AnimatedIconButton(
          tooltip: isFav ? 'बुकमार्क हटाएँ' : 'पृष्ठ सहेजें',
          icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isFav ? cs.primary : cs.primary.withOpacity(0.45),
          onTap: () {
            favs.toggle(reader.bookIndex, reader.pageIndex);
            _showSnack(
              context,
              isFav
                  ? 'बुकमार्क हटा दिया गया'
                  : 'पृष्ठ बुकमार्क में सहेज लिया गया',
            );
          },
        ),
        _AnimatedIconButton(
          tooltip:
              reader.sliderActive ? 'टेक्स्ट साइज बंद करें' : 'टेक्स्ट साइज',
          icon: Icons.text_fields_rounded,
          color:
              reader.sliderActive ? cs.primary : cs.primary.withOpacity(0.45),
          onTap: () => context.read<ReaderProvider>().toggleSlider(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 0.5,
          color: cs.primary.withOpacity(0.2),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
  }
}

class _FontSizeApplyingOverlay extends StatelessWidget {
  const _FontSizeApplyingOverlay();

  @override
  Widget build(BuildContext context) {
    final visible = context.select<AppProvider, bool>(
      (app) => app.fontSizeApplying,
    );
    final cs = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          color: Colors.black.withOpacity(0.16),
          alignment: Alignment.center,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAppBarTitle extends StatelessWidget {
  final String title;
  final bool compact;
  final Color color;

  const _HomeAppBarTitle({
    super.key,
    required this.title,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          locale: const Locale('hi', 'IN'),
          style: GoogleFonts.notoSerifDevanagari(
            fontSize: compact ? 12.5 : 17,
            height: compact ? 1.25 : 1.1,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _AnimatedIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.78).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Tooltip(
          message: widget.tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                widget.icon,
                key: ValueKey(widget.icon),
                color: color,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
