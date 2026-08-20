import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/app_provider.dart';
import '../providers/favourites_provider.dart';
import '../providers/reader_provider.dart';
import '../widgets/font_size_slider.dart';

class TopicSectionScreen extends StatefulWidget {
  final List<String> topics;
  final int initialIndex;
  final String? sectionId;
  final String? sectionTitle;

  const TopicSectionScreen({
    super.key,
    required this.topics,
    required this.initialIndex,
    this.sectionId,
    this.sectionTitle,
  });

  @override
  State<TopicSectionScreen> createState() => _TopicSectionScreenState();
}

class _TopicSectionScreenState extends State<TopicSectionScreen> {
  late final PageController _controller;
  late int _index;
  bool _isReading = false;
  bool _sliderActive = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.topics.length - 1).toInt();
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeToDrawer() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  void _goToTopic(int newIndex) {
    if (newIndex < 0 ||
        newIndex >= widget.topics.length ||
        newIndex == _index) {
      return;
    }

    if (_controller.hasClients) {
      _controller.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
      );
    } else {
      setState(() => _index = newIndex);
    }
  }

  void _setReadingHeader(bool value) {
    if (_isReading == value) return;
    setState(() => _isReading = value);
  }

  void _toggleSlider() {
    setState(() => _sliderActive = !_sliderActive);
  }

  void _hideSlider() {
    if (_sliderActive) {
      setState(() => _sliderActive = false);
    }
  }

  void _showMessage(String message, {int seconds = 2}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: Duration(seconds: seconds),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
  }

  void _returnHome() {
    HapticFeedback.mediumImpact();
    context.read<ReaderProvider>().goHome();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<AppProvider>().fontSize;
    final favs = context.watch<FavouritesProvider>();
    final sectionTitle = widget.sectionTitle ?? _sectionTitle(widget.sectionId);
    final topicTitle = widget.topics[_index];
    final isSaved = favs.isTopicSaved(widget.sectionId, topicTitle);

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          toolbarHeight: 64,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _closeToDrawer,
          ),
          titleSpacing: 0,
          title: AnimatedSwitcher(
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
            child: _TopicAppBarTitle(
              key: ValueKey(_isReading),
              title: _isReading ? widget.topics[_index] : sectionTitle,
              compact: _isReading,
            ),
          ),
          actions: [
            _TopicActionButton(
              tooltip: isSaved ? 'Bookmark à¤¹à¤Ÿà¤¾à¤à¤' : 'Bookmark à¤•à¤°à¥‡à¤‚',
              icon: isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isSaved ? Theme.of(context).colorScheme.primary : null,
              onTap: () {
                favs.toggleTopic(
                  sectionId: widget.sectionId,
                  sectionTitle: sectionTitle,
                  topicTitle: topicTitle,
                  topics: widget.topics,
                  topicIndex: _index,
                );
                _showMessage(
                  isSaved
                      ? 'Bookmark à¤¹à¤Ÿà¤¾ à¤¦à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾'
                      : 'Page bookmark à¤®à¥‡à¤‚ à¤¸à¤¹à¥‡à¤œ à¤²à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾',
                );
              },
            ),
            _TopicActionButton(
              tooltip: _sliderActive ? 'Text size à¤¬à¤‚à¤¦ à¤•à¤°à¥‡à¤‚' : 'Text size',
              icon: Icons.text_fields_rounded,
              color:
                  _sliderActive ? Theme.of(context).colorScheme.primary : null,
              onTap: _toggleSlider,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0, -0.18),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: _isReading
                        ? const SizedBox(
                            key: ValueKey('reading-header-hidden'),
                            width: double.infinity,
                          )
                        : _TopicHeaderStrip(
                            key: ValueKey(
                                'reading-header-${widget.topics[_index]}'),
                            sectionTitle: sectionTitle,
                            subtopicTitle: widget.topics[_index],
                          ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.topics.length,
                    onPageChanged: (value) => setState(() {
                      _index = value;
                      _isReading = false;
                    }),
                    itemBuilder: (context, index) => _TopicPage(
                      title: widget.topics[index],
                      content: _TopicPageContent.forTopic(
                        widget.sectionId,
                        widget.topics[index],
                      ),
                      index: index,
                      total: widget.topics.length,
                      fontSize: fontSize,
                      onTap: _hideSlider,
                      onReadingHeaderChanged:
                          index == _index ? _setReadingHeader : null,
                    ),
                  ),
                ),
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
                child: _sliderActive
                    ? const FontSizeSlider(key: ValueKey('slider'))
                    : const SizedBox.shrink(key: ValueKey('no_slider')),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _TopicSectionNavBar(
          canPrev: _index > 0,
          canNext: _index < widget.topics.length - 1,
          onPrev: () => _goToTopic(_index - 1),
          onNext: () => _goToTopic(_index + 1),
          onHomeTap: () => _showMessage(
            'à¤®à¥à¤–à¤ªà¥ƒà¤·à¥à¤  à¤ªà¤° à¤²à¥Œà¤Ÿà¤¨à¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤¥à¥‹à¤¡à¤¼à¥€ à¤¦à¥‡à¤° à¤¦à¤¬à¤¾à¤•à¤° à¤°à¤–à¥‡à¤‚',
          ),
          onHomeLongPress: _returnHome,
        ),
      ),
    );
  }

  String _sectionTitle(String? sectionId) {
    if (sectionId == 'topic1') {
      return 'à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤¸à¤‚à¤•à¥à¤·à¤¿à¤ªà¥à¤¤ à¤œà¥€à¤µà¤¨ à¤ªà¤°à¤¿à¤šà¤¯';
    }
    if (sectionId == 'topic2') return 'à¤¨à¤¿à¤µà¥‡à¤¦à¤¨';
    if (sectionId == 'topic3') return 'à¤…à¤¨à¥à¤•à¥à¤°à¤®à¤£à¤¿à¤•à¤¾ (à¤¸à¤¾à¤° à¤¸à¤‚à¤•à¥à¤·à¥‡à¤ª)';
    if (sectionId == 'topic4') return 'à¤¸à¤°à¤²à¤¾à¤°à¥à¤¥ (à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤•à¤¾à¤µà¥à¤¯)';
    if (sectionId == 'topic5') return 'à¤·à¥‹à¤¡à¤¶ à¤—à¥€à¤¤';

    return switch (sectionId) {
      'topic1' =>
        'Ã Â¤ÂªÃ Â¥â€šÃ Â¤Å“Ã Â¥ÂÃ Â¤Â¯ Ã Â¤Â¶Ã Â¥ÂÃ Â¤Â°Ã Â¥â‚¬Ã Â¤Â°Ã Â¤Â¾Ã Â¤Â§Ã Â¤Â¾Ã Â¤Â¬Ã Â¤Â¾Ã Â¤Â¬Ã Â¤Â¾ Ã Â¤Â¸Ã Â¤â€šÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¤Â¿Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â¤ Ã Â¤Å“Ã Â¥â‚¬Ã Â¤ÂµÃ Â¤Â¨ Ã Â¤ÂªÃ Â¤Â°Ã Â¤Â¿Ã Â¤Å¡Ã Â¤Â¯',
      'topic2' => 'Ã Â¤Â¨Ã Â¤Â¿Ã Â¤ÂµÃ Â¥â€¡Ã Â¤Â¦Ã Â¤Â¨',
      'topic3' =>
        'Ã Â¤â€¦Ã Â¤Â¨Ã Â¥ÂÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â°Ã Â¤Â®Ã Â¤Â£Ã Â¤Â¿Ã Â¤â€¢Ã Â¤Â¾ (Ã Â¤Â¸Ã Â¤Â¾Ã Â¤Â° Ã Â¤Â¸Ã Â¤â€šÃ Â¤â€¢Ã Â¥ÂÃ Â¤Â·Ã Â¥â€¡Ã Â¤Âª)',
      'topic4' =>
        'Ã Â¤Â¸Ã Â¤Â°Ã Â¤Â²Ã Â¤Â¾Ã Â¤Â°Ã Â¥ÂÃ Â¤Â¥ (Ã Â¤ÂªÃ Â¥ÂÃ Â¤Â°Ã Â¤Â¿Ã Â¤Â¯Ã Â¤Â¤Ã Â¤Â® Ã Â¤â€¢Ã Â¤Â¾Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¯)',
      'topic5' => 'Ã Â¤â€¢Ã Â¤Â¾Ã Â¤ÂµÃ Â¥ÂÃ Â¤Â¯-Ã Â¤Â®Ã Â¤Â¯ Ã Â¤Â¸Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¦Ã Â¥â€¡Ã Â¤Â¶',
      _ => 'Topic',
    };
  }
}

class _TopicAppBarTitle extends StatelessWidget {
  final String title;
  final bool compact;

  const _TopicAppBarTitle({
    super.key,
    required this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            locale: const Locale('hi', 'IN'),
            strutStyle: StrutStyle(
              fontSize: compact ? 12.5 : 13,
              height: 1.32,
              forceStrutHeight: true,
            ),
            style: GoogleFonts.notoSerifDevanagari(
              color: cs.primary,
              fontSize: compact ? 12.5 : 13,
              fontWeight: FontWeight.w800,
              height: 1.32,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicHeaderStrip extends StatelessWidget {
  final String sectionTitle;
  final String subtopicTitle;

  const _TopicHeaderStrip({
    super.key,
    required this.sectionTitle,
    required this.subtopicTitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isDark ? cs.surface.withOpacity(0.5) : cs.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: cs.primary.withOpacity(0.12), width: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtopicTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              locale: const Locale('hi', 'IN'),
              strutStyle: const StrutStyle(
                fontSize: 12,
                height: 1.45,
                forceStrutHeight: true,
              ),
              style: GoogleFonts.notoSerifDevanagari(
                color: cs.onBackground.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _TopicActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_TopicActionButton> createState() => _TopicActionButtonState();
}

class _TopicActionButtonState extends State<_TopicActionButton>
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
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? cs.primary.withOpacity(0.45);

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

class _TopicSectionNavBar extends StatelessWidget {
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onHomeTap;
  final VoidCallback onHomeLongPress;

  const _TopicSectionNavBar({
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onHomeTap,
    required this.onHomeLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: 56,
      child: Row(children: [
        Expanded(
          child: _TopicNavBtn(
            icon: Icons.chevron_left_rounded,
            label: 'Previous',
            iconFirst: true,
            enabled: canPrev,
            onTap: onPrev,
          ),
        ),
        Container(width: 0.5, height: 28, color: cs.outline),
        Expanded(
          child: _TopicNavBtn(
            icon: Icons.home_rounded,
            label: 'à¤®à¥à¤–à¤ªà¥ƒà¤·à¥à¤ ',
            enabled: true,
            isCenter: true,
            onTap: onHomeTap,
            onLongPress: onHomeLongPress,
          ),
        ),
        Container(width: 0.5, height: 28, color: cs.outline),
        Expanded(
          child: _TopicNavBtn(
            icon: Icons.chevron_right_rounded,
            label: 'Next',
            iconFirst: false,
            enabled: canNext,
            onTap: onNext,
          ),
        ),
      ]),
    );
  }
}

class _TopicNavBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isCenter;
  final bool iconFirst;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TopicNavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isCenter = false,
    this.iconFirst = true,
    this.onLongPress,
  });

  @override
  State<_TopicNavBtn> createState() => _TopicNavBtnState();
}

class _TopicNavBtnState extends State<_TopicNavBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.8).animate(
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
    final cs = Theme.of(context).colorScheme;
    final color = widget.enabled ? cs.primary : cs.primary.withOpacity(0.22);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
      onTapUp: widget.enabled
          ? (_) async {
              await _ctrl.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _ctrl.reverse();
              widget.onLongPress!.call();
            },
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox.expand(
          child: Center(
            child: widget.isCenter
                ? Icon(widget.icon, color: color, size: 24)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.iconFirst
                        ? [
                            Icon(widget.icon, color: color, size: 22),
                            const SizedBox(width: 2),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ]
                        : [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(widget.icon, color: color, size: 22),
                          ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TopicPage extends StatelessWidget {
  final String title;
  final _TopicPageContent content;
  final int index;
  final int total;
  final double fontSize;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onReadingHeaderChanged;

  const _TopicPage({
    required this.title,
    required this.content,
    required this.index,
    required this.total,
    required this.fontSize,
    this.onTap,
    this.onReadingHeaderChanged,
  });

  Future<void> _copy(BuildContext context) async {
    final footer = content.boldFooter?.trim();
    final text = [
      title,
      content.body.trim(),
      if (footer != null && footer.isNotEmpty) footer,
    ].join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Page à¤•à¤¾ à¤ªà¤¾à¤  à¤•à¥‰à¤ªà¥€ à¤¹à¥‹ à¤—à¤¯à¤¾'),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
    }
  }

  // ... (aapke existing variables and _copy method)

  // à¤¯à¤¹ à¤œà¤¾à¤¦à¥à¤ˆ à¤«à¤‚à¤•à¥à¤¶à¤¨ ** à¤”à¤° ## à¤•à¥‹ à¤ªà¤¹à¤šà¤¾à¤¨ à¤•à¤° Bold à¤”à¤° Center à¤•à¤° à¤¦à¥‡à¤—à¤¾
  Widget _buildFormattedText(
      String text, TextStyle defaultStyle, Color primaryColor) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return const SizedBox(height: 12);
        }
        // à¤…à¤—à¤° à¤²à¤¾à¤‡à¤¨ '##' à¤¸à¥‡ à¤¶à¥à¤°à¥‚ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆ, à¤¤à¥‹ à¤‰à¤¸à¥‡ à¤¸à¥‡à¤‚à¤Ÿà¤° à¤”à¤° à¤¬à¥‹à¤²à¥à¤¡ à¤•à¤°à¥‡à¤‚
        if (line.trim().startsWith('##')) {
          return Padding(
            padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
            child: Text(
              line.replaceFirst('##', '').trim(),
              textAlign: TextAlign.center,
              style: defaultStyle.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: defaultStyle.fontSize! + 2,
                color: primaryColor,
              ),
            ),
          );
        }

        // à¤¬à¥€à¤š à¤®à¥‡à¤‚ à¤œà¤¹à¤¾à¤ ** à¤²à¤—à¥‡ à¤¹à¥ˆà¤‚ à¤‰à¤¸à¥‡ à¤¬à¥‹à¤²à¥à¤¡ à¤•à¤°à¥‡à¤‚
        final spans = <TextSpan>[];
        final parts = line.split('**');
        for (int i = 0; i < parts.length; i++) {
          if (i % 2 == 1) {
            spans.add(TextSpan(
              text: parts[i],
              style: defaultStyle.copyWith(
                  fontWeight: FontWeight.w900), // Bold Text
            ));
          } else {
            spans.add(TextSpan(text: parts[i])); // Normal Text
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
              style: defaultStyle,
              children: spans,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final defaultTextStyle = GoogleFonts.notoSerifDevanagari(
      color: cs.onBackground,
      fontSize: fontSize.clamp(13, 24).toDouble(),
      height: 1.75,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: () => _copy(context),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical) {
            onReadingHeaderChanged?.call(notification.metrics.pixels > 8);
          }
          return false;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (content.imagePaths.isNotEmpty) ...[
                _TopicImageCarousel(imagePaths: content.imagePaths),
                const SizedBox(height: 14),
              ],

              // à¤¯à¤¹à¤¾à¤ à¤¹à¤®à¤¨à¥‡ à¤¸à¤¾à¤§à¤¾à¤°à¤£ Text à¤µà¤¿à¤œà¥‡à¤Ÿ à¤•à¥‹ à¤¹à¤Ÿà¤¾à¤•à¤° à¤…à¤ªà¤¨à¤¾ à¤¸à¥à¤®à¤¾à¤°à¥à¤Ÿ à¤µà¤¿à¤œà¥‡à¤Ÿ à¤²à¤—à¤¾ à¤¦à¤¿à¤¯à¤¾ à¤¹à¥ˆ
              _buildFormattedText(content.body, defaultTextStyle, cs.primary),

              // à¤¬à¥‹à¤²à¥à¤¡ à¤«à¥à¤Ÿà¤° (à¤¯à¤¦à¤¿ à¤¹à¥‹ à¤¤à¥‹)
              if (content.boldFooter != null) ...[
                const SizedBox(height: 16),
                Text(
                  content.boldFooter!.trim(),
                  textAlign: TextAlign.center,
                  locale: const Locale('hi', 'IN'),
                  style: GoogleFonts.notoSerifDevanagari(
                    color: cs.onBackground,
                    fontSize: (fontSize - 8).clamp(9, 18).toDouble(),
                    height: 1.75,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicImageCarousel extends StatefulWidget {
  final List<String> imagePaths;

  const _TopicImageCarousel({required this.imagePaths});

  @override
  State<_TopicImageCarousel> createState() => _TopicImageCarouselState();
}

class _TopicImageCarouselState extends State<_TopicImageCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;
  bool _userIsDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.imagePaths.length * 1000;
    _controller = PageController(initialPage: _currentPage);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.imagePaths.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 1660), (_) {
      if (!mounted || _userIsDragging || !_controller.hasClients) return;
      final nextPage = _currentPage + 1;
      _currentPage = nextPage;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 0.74,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _userIsDragging = true;
                } else if (notification is ScrollEndNotification) {
                  _userIsDragging = false;
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemBuilder: (context, index) => Image.asset(
                  widget.imagePaths[index % widget.imagePaths.length],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                    ),
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: cs.primary.withOpacity(0.5),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.imagePaths.length,
            (index) {
              final active = index == _currentPage % widget.imagePaths.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopicPageContent {
  final List<String> imagePaths;
  final String body;
  final String? boldFooter;

  const _TopicPageContent({
    this.imagePaths = const [],
    required this.body,
    this.boldFooter,
  });

  static _TopicPageContent forTopic(String? sectionId, String title) {
    if (sectionId == 'topic1' && title == 'à¤¸à¤‚à¤•à¥à¤·à¤¿à¤ªà¥à¤¤ à¤œà¥€à¤µà¤¨ à¤ªà¤°à¤¿à¤šà¤¯') {
      return const _TopicPageContent(
        imagePaths: [
          'assets/images/sidebar/radha_baba_jivan_01.png',
          'assets/images/sidebar/radha_baba_jivan_02.jpg',
        ],
        body:
            '''à¤ªà¥‚à¤œà¥à¤¯à¤¶à¥à¤°à¥€à¤šà¤•à¥à¤°à¤§à¤° à¤®à¤¿à¤¶à¥à¤°, à¤œà¤¿à¤¨à¥à¤¹à¥‡à¤‚ à¤¬à¤¾à¤¦ à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥‡ à¤¨à¤¾à¤® à¤¸à¥‡ à¤œà¤¾à¤¨à¤¾ à¤—à¤¯à¤¾, à¤‰à¤¨à¤•à¤¾ à¤œà¤¨à¥à¤® à¥§à¥¬ à¤œà¤¨à¤µà¤°à¥€ à¥§à¥¯à¥§à¥© à¤•à¥‹ à¤¬à¤¿à¤¹à¤¾à¤° à¤•à¥‡ à¤«à¤–à¤°à¤ªà¥à¤° à¤—à¤¾à¤à¤µ à¤®à¥‡à¤‚ à¤¹à¥à¤† à¤¥à¤¾à¥¤ à¤‰à¤¨à¤•à¥‡ à¤ªà¤¿à¤¤à¤¾ à¤®à¤¹à¤¿à¤ªà¤¾à¤² à¤®à¤¿à¤¶à¥à¤° à¤à¤• à¤µà¤¿à¤¦à¥à¤µà¤¾à¤¨ à¤”à¤° à¤§à¤°à¥à¤®à¤¨à¤¿à¤·à¥à¤  à¤¬à¥à¤°à¤¾à¤¹à¥à¤®à¤£ à¤¥à¥‡, à¤”à¤° à¤šà¤•à¥à¤°à¤§à¤° à¤®à¤¿à¤¶à¥à¤° (à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾) à¤…à¤ªà¤¨à¥‡ à¤®à¤¾à¤¤à¤¾-à¤ªà¤¿à¤¤à¤¾ à¤•à¥‡ à¤šà¥Œà¤¥à¥‡ à¤ªà¥à¤¤à¥à¤° à¤¥à¥‡à¥¤ à¤‰à¤¨à¤•à¥€ à¤®à¤¾à¤¤à¤¾, à¤…à¤§à¤¿à¤•à¤¾à¤°à¤¿à¤£à¥€ à¤¦à¥‡à¤µà¥€ à¤­à¥€ à¤à¤• à¤…à¤¤à¥à¤¯à¤‚à¤¤ à¤ªà¥à¤£à¥à¤¯à¤¾à¤¤à¥à¤®à¤¾ à¤¥à¥€à¤‚à¥¤
à¤¬à¤šà¤ªà¤¨ à¤®à¥‡à¤‚ à¤¹à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤¨à¥‡ à¤›à¤¹ à¤¸à¥‡ à¤¸à¤¾à¤¤ à¤­à¤¾à¤·à¤¾à¤“à¤‚ à¤ªà¤° à¤¯à¥‹à¤—à¥à¤¯à¤¤à¤¾ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤•à¤° à¤²à¥€ à¤¥à¥€, à¤œà¤¿à¤¸à¤¸à¥‡ à¤‰à¤¨à¤•à¥€ à¤µà¤¿à¤¦à¥à¤µà¤¤à¤¾ à¤•à¤¾ à¤ªà¤°à¤¿à¤šà¤¯ à¤®à¤¿à¤²à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤¯à¤¦à¥à¤¯à¤ªà¤¿, à¤‰à¤šà¥à¤š à¤œà¥à¤žà¤¾à¤¨ à¤•à¥€ à¤‰à¤¨à¤•à¥€ à¤œà¤¿à¤œà¥à¤žà¤¾à¤¸à¤¾ à¤¨à¥‡ à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤¶à¤¿à¤•à¥à¤·à¤¾ à¤•à¥‡ à¤ªà¤¾à¤° à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤•à¤¤à¤¾ à¤•à¥€ à¤“à¤° à¤…à¤—à¥à¤°à¤¸à¤° à¤•à¤¿à¤¯à¤¾à¥¤
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤•à¤¾ à¤ªà¥à¤°à¤¾à¤°à¤‚à¤­à¤¿à¤• à¤œà¥€à¤µà¤¨ à¤à¤• à¤œà¤¿à¤œà¥à¤žà¤¾à¤¸à¥ à¤•à¥‡ à¤°à¥‚à¤ª à¤®à¥‡à¤‚ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤•à¤¤à¤¾ à¤•à¥‡ à¤µà¤¿à¤·à¤¯à¥‹à¤‚ à¤ªà¤° à¤­à¤¿à¤¨à¥à¤¨-à¤­à¤¿à¤¨à¥à¤¨ à¤¤à¤°à¥€à¤•à¥‹à¤‚ à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤‚à¤§à¤¾à¤¨ à¤¸à¥‡ à¤­à¤°à¤¾ à¤¹à¥à¤† à¤¥à¤¾à¥¤ à¤ªà¥à¤°à¤¾à¤°à¤‚à¤­ à¤®à¥‡à¤‚ à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¤¾ à¤¨à¥‡ à¤µà¥‡à¤¦à¤¾à¤‚à¤¤ à¤•à¥‡ à¤®à¤¾à¤°à¥à¤— à¤•à¤¾ à¤…à¤¨à¥à¤¸à¤°à¤£ à¤•à¤¿à¤¯à¤¾, à¤œà¥‹ à¤­à¤¾à¤°à¤¤à¥€à¤¯ à¤¦à¤°à¥à¤¶à¤¨ à¤•à¤¾ à¤®à¤¹à¤¤à¥à¤µà¤ªà¥‚à¤°à¥à¤£ à¤…à¤‚à¤— à¤¹à¥ˆ à¤œà¥‹ à¤†à¤¤à¥à¤®-à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥à¤•à¤¾à¤° à¤”à¤° à¤†à¤¤à¥à¤®à¤¾ à¤¤à¤¥à¤¾ à¤¬à¥à¤°à¤¹à¥à¤®à¤¾à¤‚à¤¡à¥€à¤¯ à¤šà¥‡à¤¤à¤¨à¤¾ à¤•à¥€ à¤à¤•à¤¤à¤¾ à¤ªà¤° à¤¬à¤² à¤¦à¥‡à¤¤à¤¾ à¤¹à¥ˆ, à¤”à¤° à¤†à¤—à¥‡ à¤šà¤²à¤•à¤° à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¤¾ à¤à¤• à¤¦à¥ƒà¤¢à¤¼ à¤µà¥‡à¤¦à¤¾à¤‚à¤¤à¥€ à¤¬à¤¨à¥‡, à¤œà¥‹ à¤¸à¤¤à¥à¤¯ à¤•à¥€ à¤–à¥‹à¤œ à¤•à¥‡ à¤²à¤¿à¤ à¤¬à¥Œà¤¦à¥à¤§à¤¿à¤• à¤°à¥‚à¤ª à¤¸à¥‡ à¤¸à¤‚à¤•à¤²à¥à¤ªà¤¿à¤¤ à¤¥à¥‡à¥¤
à¤¯à¤¦à¥à¤¯à¤ªà¤¿, à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥‡ à¤œà¥€à¤µà¤¨ à¤®à¥‡à¤‚ à¤à¤• à¤®à¤¹à¤¤à¥à¤µà¤ªà¥‚à¤°à¥à¤£ à¤®à¥‹à¤¡à¤¼ à¤¤à¤¬ à¤†à¤¯à¤¾ à¤œà¤¬ à¤‰à¤¨à¤•à¥€ à¤­à¥‡à¤‚à¤Ÿ à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆà¤œà¥€ (à¤¶à¥à¤°à¥€à¤¹à¤¨à¥à¤®à¤¾à¤¨ à¤ªà¥à¤°à¤¸à¤¾à¤¦ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤°) à¤¸à¥‡ à¤¹à¥à¤ˆà¥¤ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆà¤œà¥€ à¤à¤• à¤®à¤¹à¤¾à¤¨ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤¤à¥à¤µ à¤¥à¥‡, à¤œà¥‹ à¤—à¥€à¤¤à¤¾ à¤ªà¥à¤°à¥‡à¤¸ à¤—à¥‹à¤°à¤–à¤ªà¥à¤° à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤® à¤¸à¥‡ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤¸à¤¾à¤¹à¤¿à¤¤à¥à¤¯ à¤•à¥‹ à¤¸à¤‚à¤ªà¤¾à¤¦à¤¿à¤¤ à¤”à¤° à¤ªà¥à¤°à¤•à¤¾à¤¶à¤¿à¤¤ à¤•à¤° à¤§à¤°à¥à¤® à¤—à¥à¤°à¤‚à¤¥à¥‹à¤‚ à¤•à¤¾ à¤ªà¥à¤°à¤šà¤¾à¤° à¤•à¤°à¤¤à¥‡ à¤¥à¥‡ à¥¥ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¤¾ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆà¤œà¥€ à¤¸à¥‡ à¤¸à¤‚à¤ªà¤°à¥à¤• à¤œà¤¯à¤¦à¤¯à¤¾à¤² à¤œà¥€ à¤—à¥‹à¤¯à¤¨à¤•à¤¾ à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤® à¤¸à¥‡ à¤¹à¥à¤†, à¤œà¥‹ à¤—à¥€à¤¤à¤¾ à¤ªà¥à¤°à¥‡à¤¸ à¤•à¥‡ à¤¸à¤‚à¤¸à¥à¤¥à¤¾à¤ªà¤• à¤¥à¥‡à¥¤ à¤¯à¤¹à¥€ à¤µà¤¹ à¤¸à¤®à¤¯ à¤¥à¤¾ à¤œà¤¬ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤œà¥€ à¤•à¥‡ à¤¸à¤‚à¤— à¤•à¥‡ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤¸à¥‡ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ â€˜à¤µà¥‡à¤¦à¤¾à¤¨à¥à¤¤ à¤®à¤¾à¤°à¥à¤—â€™ à¤¸à¥‡ â€˜à¤­à¤•à¥à¤¤à¤¿ à¤®à¤¾à¤°à¥à¤—â€™ à¤•à¥‡ à¤ªà¤¥à¤¿à¤• à¤¬à¤¨ à¤—à¤à¥¥
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤•à¤¾ â€˜à¤µà¥‡à¤¦à¤¾à¤‚à¤¤ à¤®à¤¾à¤°à¥à¤—â€™ à¤¸à¥‡ â€˜à¤­à¤•à¥à¤¤à¤¿ à¤®à¤¾à¤°à¥à¤—â€™ à¤•à¥€ à¤“à¤° à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨ à¤à¤•à¤¦à¤® à¤¸à¥‡ à¤¨à¤¹à¥€à¤‚ à¤¹à¥à¤†à¥¤ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆ à¤œà¥€ à¤•à¥‡ à¤¸à¤‚à¤— à¤•à¥‡ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤¸à¥‡ à¤”à¤° à¤­à¤¾à¤ˆà¤œà¥€ à¤•à¥‡ à¤®à¤¾à¤°à¥à¤—à¤¦à¤°à¥à¤¶à¤¨ à¤¸à¥‡ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥€ à¤•à¤ à¥‹à¤° à¤µà¥‡à¤¦à¤¾à¤¨à¥à¤¤à¤¿à¤• à¤ªà¥à¤°à¤µà¥ƒà¤¤à¥à¤¤à¤¿ à¤à¤• à¤•à¥‹à¤®à¤² à¤”à¤° à¤­à¤¾à¤µà¤¨à¤¾à¤¤à¥à¤®à¤• à¤­à¤•à¥à¤¤à¤¿ à¤®à¤¾à¤°à¥à¤— à¤•à¥€ à¤“à¤° à¤®à¥à¤¡à¤¼ à¤—à¤ˆ, à¤µà¤¿à¤¶à¥‡à¤· à¤°à¥‚à¤ª à¤¸à¥‡ à¤­à¤—à¤µà¤¾à¤¨ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤¬à¥à¤°à¤œ à¤¸à¤¾à¤§à¤¨à¤¾ à¤•à¥‹ à¤…à¤ªà¤¨à¤¾à¤¯à¤¾, à¤œà¥‹ à¤­à¤—à¤µà¤¾à¤¨ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤•à¥‡ à¤ªà¥à¤°à¥‡à¤® à¤”à¤° à¤­à¤•à¥à¤¤à¤¿ à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬à¤¨à¥‡ à¤•à¥€ à¤¸à¤¾à¤§à¤¨à¤¾ à¤¹à¥ˆ, à¤µà¤¿à¤¶à¥‡à¤·à¤•à¤° à¤—à¥‹à¤ªà¥€ à¤”à¤° à¤°à¤¾à¤§à¤¾à¤­à¤¾à¤µ à¤®à¥‡à¤‚à¥¤ à¤¯à¤¹ à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥‡ à¤œà¥€à¤µà¤¨ à¤®à¥‡à¤‚ à¤à¤• à¤¨à¤ à¤šà¤°à¤£ à¤•à¥€ à¤¶à¥à¤°à¥à¤†à¤¤ à¤¥à¥€à¥¤ à¤à¤• à¤•à¤Ÿà¥à¤Ÿà¤° à¤¬à¥Œà¤¦à¥à¤§à¤¿à¤• à¤¸à¥‡, à¤µà¥‡ à¤à¤• à¤•à¥‹à¤®à¤² à¤¹à¥ƒà¤¦à¤¯ à¤µà¤¾à¤²à¥‡, à¤­à¤•à¥à¤¤à¤¿ à¤¸à¥‡ à¤ªà¥‚à¤°à¤¿à¤¤ à¤­à¤•à¥à¤¤ à¤¬à¤¨ à¤—à¤, à¤œà¥‹ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤•à¥‡ à¤ªà¥à¤°à¥‡à¤® à¤®à¥‡à¤‚ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤¡à¥‚à¤¬ à¤—à¤ à¤¥à¥‡ à¤”à¤° à¤†à¤—à¥‡ à¤šà¤² à¤•à¤° à¤°à¤¾à¤§à¤¾ à¤­à¤¾à¤µ à¤¸à¥‡ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤•à¥€ à¤‰à¤ªà¤¾à¤¸à¤¨à¤¾ à¤•à¤°à¤¨à¥‡ à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥‡ à¤¨à¤¾à¤® à¤¸à¥‡ à¤œà¤¾à¤¨à¤¾ à¤—à¤¯à¤¾à¥¤ 
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤¨à¥‡ à¤¸à¤‚à¤¤ à¤¶à¥à¤°à¥€ à¤šà¥ˆà¤¤à¤¨à¥à¤¯ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤•à¥€ à¤ªà¤°à¤‚à¤ªà¤°à¤¾ à¤•à¤¾ à¤…à¤¨à¥à¤¸à¤°à¤£ à¤•à¤¿à¤¯à¤¾, à¤œà¥‹ à¥§à¥¬ à¤µà¥€à¤‚ à¤¶à¤¤à¤¾à¤¬à¥à¤¦à¥€ à¤•à¥‡ à¤¸à¤‚à¤¤ à¤¥à¥‡ à¤”à¤° à¤œà¤¿à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤­à¤•à¥à¤¤à¤¿ à¤†à¤‚à¤¦à¥‹à¤²à¤¨ à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿ à¤…à¤ªà¤¨à¥‡ à¤—à¤¹à¤¨ à¤ªà¥à¤°à¥‡à¤® à¤”à¤° à¤­à¤•à¥à¤¤à¤¿ à¤•à¤¾ à¤ªà¤°à¤¿à¤šà¤¯ à¤¦à¤¿à¤¯à¤¾à¥¤ à¤šà¥ˆà¤¤à¤¨à¥à¤¯ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤•à¥€ à¤¤à¤°à¤¹, à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥€ â€˜à¤­à¤•à¥à¤¤à¤¿ à¤¨à¤¾à¤® à¤¸à¤¾à¤§à¤¨à¤¾â€™ à¤”à¤° â€˜à¤­à¤¾à¤µ à¤¸à¤®à¤¾à¤§à¤¿â€™ (à¤¦à¤¿à¤µà¥à¤¯ à¤ªà¥à¤°à¥‡à¤® à¤®à¥‡à¤‚ à¤—à¤¹à¤¨ à¤­à¤¾à¤µà¤¨à¤¾à¤¤à¥à¤®à¤• à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿) à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤•à¤Ÿ à¤¹à¥à¤ˆà¥¤ à¤‡à¤¨ à¤¸à¤¾à¤§à¤¨à¤¾à¤“à¤‚ à¤¨à¥‡ à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤—à¤¹à¤¨ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤†à¤¨à¤‚à¤¦ à¤•à¥€ à¤…à¤µà¤¸à¥à¤¥à¤¾à¤“à¤‚ à¤®à¥‡à¤‚ à¤ªà¤¹à¥à¤‚à¤šà¤¾ à¤¦à¤¿à¤¯à¤¾, à¤œà¤¹à¤¾à¤‚ à¤µà¥‡ à¤•à¤ˆ à¤¦à¤¿à¤¨à¥‹à¤‚ à¤¤à¤• à¤¬à¤¾à¤¹à¤°à¥€ à¤¦à¥à¤¨à¤¿à¤¯à¤¾ à¤¸à¥‡ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤…à¤¨à¤­à¤¿à¤œà¥à¤ž à¤°à¤¹à¤¤à¥‡ à¤¥à¥‡à¥¤
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¤¾ à¤œà¥€à¤µà¤¨ à¤•à¤ à¥‹à¤° à¤¤à¤ª à¤”à¤° à¤¸à¤¾à¤¦à¤—à¥€ à¤¸à¥‡ à¤­à¤°à¤¾ à¤¥à¤¾, à¤œà¥‹ à¤‰à¤¸ à¤¸à¤®à¤¯ à¤•à¥‡ à¤¸à¤‚à¤¤à¥‹à¤‚ à¤®à¥‡à¤‚ à¤­à¥€ à¤¦à¥à¤°à¥à¤²à¤­ à¤¥à¤¾à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤ªà¥‚à¤°à¥‡ à¤œà¥€à¤µà¤¨ à¤¸à¤–à¥à¤¤ à¤…à¤¨à¥à¤¶à¤¾à¤¸à¤¨ à¤•à¤¾ à¤ªà¤¾à¤²à¤¨ à¤•à¤¿à¤¯à¤¾, à¤œà¤¿à¤¸à¤®à¥‡à¤‚ à¤µà¥‡ à¤¦à¤¿à¤¨ à¤®à¥‡à¤‚ à¤•à¥‡à¤µà¤² à¤à¤• à¤¬à¤¾à¤° à¤­à¥‹à¤œà¤¨ à¤”à¤° à¤œà¤² à¤—à¥à¤°à¤¹à¤£ à¤•à¤°à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤‰à¤¨à¤•à¤¾ à¤¯à¤¹ à¤¸à¤°à¤² à¤”à¤° à¤…à¤¨à¥à¤¶à¤¾à¤¸à¤¿à¤¤ à¤œà¥€à¤µà¤¨ à¤•à¤¿à¤¸à¥€ à¤¦à¤¿à¤–à¤¾à¤µà¥‡ à¤•à¥‡ à¤²à¤¿à¤ à¤¨à¤¹à¥€à¤‚ à¤¥à¤¾, à¤¬à¤²à¥à¤•à¤¿ à¤‰à¤¨à¤•à¥‡ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸ à¤•à¥€ à¤à¤• à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ à¤¥à¤¾à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤•à¤­à¥€ à¤§à¤¨ à¤•à¥‹ à¤¹à¤¾à¤¥ à¤¨à¤¹à¥€à¤‚ à¤²à¤—à¤¾à¤¯à¤¾ à¤”à¤° à¤¨ à¤¹à¥€ à¤•à¤¿à¤¸à¥€ à¤µà¤¿à¤²à¤¾à¤¸à¤¿à¤¤à¤¾ à¤•à¤¾ à¤•à¤­à¥€ à¤†à¤¨à¤‚à¤¦ à¤²à¤¿à¤¯à¤¾à¥¤ à¤­à¥Œà¤¤à¤¿à¤• à¤¸à¥à¤–-à¤¸à¥à¤µà¤¿à¤§à¤¾à¤“à¤‚ à¤¸à¥‡ à¤‰à¤¨à¤•à¤¾ à¤ªà¥‚à¤°à¥à¤£ à¤¤à¥à¤¯à¤¾à¤— à¤‰à¤¨à¤•à¥‡ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤†à¤¦à¤°à¥à¤¶à¥‹à¤‚ à¤•à¤¾ à¤ªà¥à¤°à¤¤à¥€à¤• à¤¥à¤¾à¥¤
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤•à¤¾ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆà¤œà¥€ à¤•à¥‡ à¤¸à¤¾à¤¥ à¤—à¤¹à¤°à¤¾ à¤¸à¤‚à¤¬à¤‚à¤§ à¤¥à¤¾, à¤”à¤° à¤‰à¤¨à¤•à¤¾ à¤à¤• à¤…à¤¨à¥‹à¤–à¤¾ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤¸à¤‚à¤¬à¤‚à¤§ à¤¥à¤¾à¥¤ à¤µà¥‡ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤—à¥‹à¤°à¤–à¤ªà¥à¤° à¤•à¥‡ à¤¶à¤¾à¤‚à¤¤à¤¿à¤ªà¥‚à¤°à¥à¤£ à¤”à¤° à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤°à¥‚à¤ª à¤¸à¥‡ à¤ªà¥à¤°à¤¬à¥à¤¦à¥à¤§ à¤¸à¥à¤¥à¤¾à¤¨ à¤—à¥€à¤¤à¤¾ à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾ à¤®à¥‡à¤‚ à¤¸à¤¾à¤¥ à¤°à¤¹à¤¤à¥‡ à¤¥à¥‡, à¤œà¥‹ à¤­à¤•à¥à¤¤à¥‹à¤‚ à¤•à¥‹ à¤†à¤•à¤°à¥à¤·à¤¿à¤¤ à¤•à¤°à¤¤à¤¾ à¤¥à¤¾à¥¤ à¤œà¥‹ à¤²à¥‹à¤— à¤­à¤¾à¤ˆà¤œà¥€ à¤•à¤¾ à¤…à¤¨à¥à¤¸à¤°à¤£ à¤•à¤°à¤¤à¥‡ à¤¥à¥‡, à¤µà¥‡ à¤¸à¥à¤µà¤¾à¤­à¤¾à¤µà¤¿à¤• à¤°à¥‚à¤ª à¤¸à¥‡ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤¸à¥‡ à¤ªà¤°à¤¿à¤šà¤¿à¤¤ à¤¹à¥‹ à¤¹à¥€ à¤œà¤¾à¤¤à¥‡ à¤¥à¥‡, à¤²à¥‡à¤•à¤¿à¤¨ à¤¬à¤¾à¤¬à¤¾ à¤¨à¥‡ à¤•à¤­à¥€ à¤­à¥€ à¤…à¤ªà¤¨à¥‡ à¤²à¤¿à¤ à¤…à¤¨à¥à¤¯à¤¾à¤¯à¤¿à¤¯à¥‹à¤‚ à¤¯à¤¾ à¤ªà¥à¤°à¤¸à¤¿à¤¦à¥à¤§à¤¿ à¤•à¥€ à¤šà¤¾à¤¹ à¤¨à¤¹à¥€à¤‚ à¤°à¤–à¥€à¥¤ à¤‰à¤¨à¤•à¥€ à¤µà¤¿à¤¨à¤®à¥à¤°à¤¤à¤¾ à¤‡à¤¤à¤¨à¥€ à¤¥à¥€ à¤•à¤¿ à¤µà¥‡ à¤à¤• à¤‰à¤¤à¥à¤•à¥ƒà¤·à¥à¤Ÿ à¤²à¥‡à¤–à¤• à¤”à¤° à¤•à¤µà¤¿ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥à¤ à¤­à¥€ à¤…à¤ªà¤¨à¥‡ à¤•à¤¾à¤°à¥à¤¯à¥‹à¤‚ à¤•à¥‹ à¤…à¤ªà¤¨à¥‡ à¤¨à¤¾à¤® à¤¸à¥‡ à¤ªà¥à¤°à¤•à¤¾à¤¶à¤¿à¤¤ à¤¨à¤¹à¥€à¤‚ à¤•à¤°à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤‰à¤¨à¤•à¥€ à¤ªà¥à¤¸à¥à¤¤à¤•à¥‹à¤‚ à¤”à¤° à¤²à¥‡à¤–à¥‹à¤‚ à¤•à¥‹ à¤—à¥à¤®à¤¨à¤¾à¤® à¤°à¥‚à¤ª à¤¸à¥‡ â€œà¤à¤• à¤¸à¤¾à¤§à¥â€ à¤•à¥‡ à¤°à¥‚à¤ª à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¸à¥à¤¤à¥à¤¤ à¤•à¤¿à¤¯à¤¾ à¤œà¤¾à¤¤à¤¾ à¤¥à¤¾à¥¤ à¤‰à¤¨à¤•à¥€ à¤­à¤•à¥à¤¤à¤¿ à¤¸à¥‡ à¤“à¤¤ à¤ªà¥à¤°à¥‹à¤¤ à¤•à¤µà¤¿à¤¤à¤¾à¤à¤ à¤‰à¤¨à¤•à¥‡ à¤—à¤¹à¤°à¥‡ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤…à¤¨à¥à¤­à¤µà¥‹à¤‚ à¤•à¥€ à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ à¤¥à¥€à¤‚, à¤²à¥‡à¤•à¤¿à¤¨ à¤µà¥‡ à¤­à¥€ à¤¬à¤¿à¤¨à¤¾ à¤¹à¤¸à¥à¤¤à¤¾à¤•à¥à¤·à¤° à¤•à¥‡ à¤°à¤¹à¥€à¤‚à¥¤
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥€ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤¸à¤¾à¤§à¤¨à¤¾ à¤­à¤—à¤µà¤¾à¤¨à¥à¤¨à¤¾à¤® à¤œà¤ª à¤ªà¤° à¤•à¥‡à¤‚à¤¦à¥à¤°à¤¿à¤¤ à¤¥à¥€à¥¤ à¤‰à¤¨à¤•à¤¾ à¤®à¤¾à¤¨à¤¨à¤¾ à¤¥à¤¾ à¤•à¤¿ à¤­à¤—à¤µà¤¾à¤¨ à¤•à¥‡ à¤¨à¤¾à¤® à¤•à¤¾ à¤œà¤ª à¤¸à¤¬à¤¸à¥‡ à¤‰à¤šà¥à¤šà¤¤à¤® à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤¸à¤¾à¤§à¤¨à¤¾ à¤¹à¥ˆ à¤”à¤° à¤¸à¤šà¥à¤šà¥‡ à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸ à¤•à¥‡ à¤¸à¤¾à¤¥ à¤•à¥€ à¤—à¤ˆ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤†à¤¤à¥à¤®-à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥à¤•à¤¾à¤° à¤•à¥‡ à¤²à¤¿à¤ à¤¸à¤¬à¤¸à¥‡ à¤¶à¤•à¥à¤¤à¤¿à¤¶à¤¾à¤²à¥€ à¤¸à¤¾à¤§à¤¨ à¤¹à¥ˆà¥¤ à¤‰à¤¨à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤°, à¤¯à¤¦à¤¿ à¤ªà¥‚à¤°à¥€ à¤­à¤•à¥à¤¤à¤¿ à¤”à¤° à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸ à¤•à¥‡ à¤¸à¤¾à¤¥ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤”à¤° à¤­à¤—à¤µà¤¾à¤¨ à¤•à¤¾ à¤¨à¤¾à¤® à¤œà¤ª à¤•à¤¿à¤¯à¤¾ à¤œà¤¾à¤ à¤¤à¥‹ à¤µà¤¹ à¤•à¤­à¥€ à¤…à¤¸à¤«à¤² à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹ à¤¸à¤•à¤¤à¤¾à¥¤
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤¨à¥‡ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤® à¤•à¥‡ à¤‰à¤šà¥à¤š à¤¸à¥à¤¤à¤° à¤•à¥‹ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤•à¤¿à¤¯à¤¾, à¤²à¥‡à¤•à¤¿à¤¨ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤•à¤­à¥€ à¤­à¥€ à¤…à¤ªà¤¨à¥‡ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤‰à¤ªà¤²à¤¬à¥à¤§à¤¿à¤¯à¥‹à¤‚ à¤•à¥‹ à¤‰à¤œà¤¾à¤—à¤° à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¯à¤¾ à¤”à¤° à¤¨ à¤¹à¥€ à¤•à¥‹à¤ˆ à¤¶à¤¿à¤·à¥à¤¯ à¤¬à¤¨à¤¾à¤¯à¤¾à¥¤ à¤‰à¤¨à¤•à¥€ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤•à¤¤à¤¾ à¤”à¤° à¤…à¤¨à¥à¤­à¤µ à¤¬à¤¹à¥à¤¤ à¤¹à¥€ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤—à¤¤ à¤¥à¥‡, à¤”à¤° à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤‡à¤¸à¤•à¥‡ à¤²à¤¿à¤ à¤•à¤­à¥€ à¤ªà¥à¤°à¤¸à¤¿à¤¦à¥à¤§à¤¿ à¤•à¥€ à¤•à¤¾à¤®à¤¨à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¥€à¥¤ à¤¬à¤¾à¤¬à¤¾ à¤•à¥€ à¤—à¤¹à¤°à¥€ à¤¸à¤®à¤¾à¤§à¤¿ à¤…à¤µà¤¸à¥à¤¥à¤¾à¤“à¤‚ à¤•à¤¾ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥à¤•à¤¾à¤° à¤‰à¤¨à¤•à¥‡ à¤¨à¤¿à¤•à¤Ÿ à¤°à¤¹à¤¨à¥‡ à¤µà¤¾à¤²à¥‡ à¤²à¥‹à¤—à¥‹à¤‚ à¤¨à¥‡ à¤•à¤¿à¤¯à¤¾, à¤•à¥à¤¯à¥‹à¤‚à¤•à¤¿ à¤µà¥‡ à¤‡à¤¨ à¤…à¤µà¤¸à¥à¤¥à¤¾à¤“à¤‚ à¤®à¥‡à¤‚ à¤•à¤ˆ à¤¦à¤¿à¤¨à¥‹à¤‚ à¤¤à¤• à¤¦à¥à¤¨à¤¿à¤¯à¤¾ à¤¸à¥‡ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤¸à¥‡ à¤µà¤¿à¤šà¥à¤›à¤¿à¤¨à¥à¤¨ à¤°à¤¹à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤¯à¤¹à¤¾à¤ à¤¤à¤• à¤•à¤¿ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤²à¤—à¤¾à¤¤à¤¾à¤° à¤ªà¤‚à¤¦à¥à¤°à¤¹ à¤µà¤°à¥à¤·à¥‹à¤‚ à¤¤à¤• â€œà¤•à¤¾à¤·à¥à¤  à¤®à¥Œà¤¨â€ (à¤ªà¥‚à¤°à¥à¤£ à¤®à¥Œà¤¨ à¤œà¤¿à¤¸à¤®à¥‡à¤‚ à¤•à¥‹à¤ˆ à¤¸à¤‚à¤•à¥‡à¤¤ à¤­à¥€ à¤¨ à¤•à¤°à¤¨à¤¾) à¤®à¥‡à¤‚ à¤¬à¤¿à¤¤à¤¾à¤¯à¤¾ à¤œà¥‹ à¤…à¤ªà¤¨à¥‡ à¤†à¤ª à¤®à¥‡à¤‚ à¤à¤• à¤…à¤¤à¥à¤¯à¤‚à¤¤ à¤•à¤ à¥‹à¤° à¤¸à¤¾à¤§à¤¨à¤¾ à¤¹à¥ˆà¥¤
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¤¾ à¤œà¥€à¤µà¤¨ à¤µà¤¿à¤¨à¤®à¥à¤°à¤¤à¤¾, à¤­à¤•à¥à¤¤à¤¿ à¤”à¤° à¤¤à¥à¤¯à¤¾à¤— à¤•à¤¾ à¤‰à¤¦à¤¾à¤¹à¤°à¤£ à¤¥à¤¾à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤šà¥à¤ªà¤šà¤¾à¤ª à¤…à¤ªà¤¨à¥‡ à¤—à¥à¤°à¥ à¤¶à¥à¤°à¥€à¤¹à¤¨à¥à¤®à¤¾à¤¨ à¤ªà¥à¤°à¤¸à¤¾à¤¦ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤•à¥€ à¤›à¤¾à¤¯à¤¾ à¤®à¥‡à¤‚ à¤œà¥€à¤µà¤¨ à¤¬à¤¿à¤¤à¤¾à¤¯à¤¾ à¤”à¤° à¤•à¤­à¥€ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤—à¤¤ à¤®à¤¾à¤¨à¥à¤¯à¤¤à¤¾ à¤•à¥€ à¤‡à¤šà¥à¤›à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¥€à¥¤ à¤‰à¤¨à¤•à¥€ à¤®à¤¹à¤¾à¤¨à¤¤à¤¾ à¤¨ à¤•à¥‡à¤µà¤² à¤‰à¤¨à¤•à¥€ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤• à¤‰à¤ªà¤²à¤¬à¥à¤§à¤¿à¤¯à¥‹à¤‚ à¤®à¥‡à¤‚ à¤¥à¥€, à¤¬à¤²à¥à¤•à¤¿ à¤‡à¤¸à¤®à¥‡à¤‚ à¤­à¥€ à¤¥à¥€ à¤•à¤¿ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤‡à¤¨à¥à¤¹à¥‡à¤‚ à¤ªà¥à¤°à¤šà¤¾à¤°à¤¿à¤¤ à¤•à¤°à¤¨à¥‡ à¤¸à¥‡ à¤®à¤¨à¤¾ à¤•à¤¿à¤¯à¤¾à¥¤ à¤‰à¤¨à¤•à¥€ à¤•à¥ƒà¤·à¥à¤£ à¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿ à¤­à¤•à¥à¤¤à¤¿, à¤¸à¤®à¤°à¥à¤ªà¤£ à¤”à¤° à¤¦à¤¿à¤µà¥à¤¯ à¤ªà¥à¤°à¥‡à¤® à¤•à¥€ à¤•à¤¾à¤µà¥à¤¯à¤¾à¤¤à¥à¤®à¤• à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ â€˜à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤•à¤¾à¤µà¥à¤¯â€™ à¤‰à¤¨ à¤¸à¤¾à¤§à¤•à¥‹à¤‚ à¤•à¥‹ à¤ªà¥à¤°à¥‡à¤°à¤¿à¤¤ à¤•à¤°à¤¤à¥€ à¤°à¤¹à¤¤à¥€ à¤¹à¥ˆ à¤œà¥‹ à¤ªà¥à¤°à¥‡à¤® à¤®à¤¾à¤°à¥à¤— à¤•à¤¾ à¤…à¤¨à¥à¤¸à¤°à¤£ à¤•à¤°à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤
à¤¹à¤¾à¤²à¤¾à¤à¤•à¤¿ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤•à¥‹à¤ˆ à¤”à¤ªà¤šà¤¾à¤°à¤¿à¤• à¤¶à¤¿à¤·à¥à¤¯ à¤¨à¤¹à¥€à¤‚ à¤¬à¤¨à¤¾à¤, à¤ªà¤°à¤¨à¥à¤¤à¥ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤•à¥€ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤•à¥€ à¤¶à¤•à¥à¤¤à¤¿, à¤­à¤—à¤µà¤¾à¤¨ à¤•à¥‡ à¤¨à¤¾à¤® à¤•à¥‡ à¤œà¤ª à¤•à¤¾ à¤®à¤¹à¤¤à¥à¤µ, à¤”à¤° à¤à¤• à¤œà¥€à¤µà¤¨ à¤œà¥‹ à¤ªà¥‚à¤°à¥€ à¤¤à¤°à¤¹ à¤¸à¥‡ à¤­à¤—à¤µà¤¾à¤¨ à¤•à¥‹ à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤ à¤¹à¥‹, à¤‰à¤¨à¤•à¥€ à¤¶à¤¿à¤•à¥à¤·à¤¾à¤à¤ à¤†à¤œ à¤­à¥€ à¤‰à¤¨à¤•à¥‡ à¤­à¤•à¥à¤¤à¥‹à¤‚ à¤•à¥‡ à¤¬à¥€à¤š à¤ªà¥à¤°à¤¤à¤¿à¤§à¥à¤µà¤¨à¤¿à¤¤ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤‰à¤¨à¤•à¤¾ à¤œà¥€à¤µà¤¨ à¤à¤• à¤¶à¤•à¥à¤¤à¤¿à¤¶à¤¾à¤²à¥€ à¤…à¤¨à¥à¤¸à¥à¤®à¤¾à¤°à¤• à¤¹à¥ˆ à¤•à¤¿ à¤¸à¤šà¥à¤šà¥€ à¤†à¤§à¥à¤¯à¤¾à¤¤à¥à¤®à¤¿à¤•à¤¤à¤¾ à¤¬à¤¾à¤¹à¤°à¥€ à¤®à¤¾à¤¨à¥à¤¯à¤¤à¤¾ à¤®à¥‡à¤‚ à¤¨à¤¹à¥€à¤‚, à¤¬à¤²à¥à¤•à¤¿ à¤¦à¤¿à¤µà¥à¤¯ à¤ªà¥à¤°à¥‡à¤® à¤•à¥€ à¤¨à¤¿à¤°à¤‚à¤¤à¤° à¤”à¤° à¤…à¤¡à¤¿à¤— à¤–à¥‹à¤œ à¤®à¥‡à¤‚ à¤¨à¤¿à¤¹à¤¿à¤¤ à¤¹à¥ˆà¥¤ à¤‰à¤¨à¤•à¥€ à¤…à¤‚à¤¤à¤¿à¤® à¤‡à¤šà¥à¤›à¤¾ à¤¥à¥€ à¤•à¤¿ à¤µà¥‡ à¤¶à¥à¤°à¥€ à¤¹à¤¨à¥à¤®à¤¾à¤¨ à¤ªà¥à¤°à¤¸à¤¾à¤¦ à¤œà¥€ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤•à¥€ à¤¸à¤®à¤¾à¤§à¤¿ à¤•à¥‡ à¤ªà¤¾à¤¸ à¤…à¤ªà¤¨à¥‡ à¤¶à¤°à¥€à¤° à¤•à¥‹ à¤¤à¥à¤¯à¤¾à¤—à¥‡à¤‚ à¤”à¤° à¤¯à¤¹ à¤‡à¤šà¥à¤›à¤¾ à¤ªà¥‚à¤°à¥€ à¤¹à¥à¤ˆà¥¤ à¤µà¥‡ à¤¸à¤‚à¤•à¤²à¥à¤ª à¤¸à¤¿à¤¦à¥à¤§ à¤¸à¤‚à¤¤ à¤¥à¥‡ à¤œà¤¿à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥€ à¤‡à¤šà¥à¤›à¤¾ à¤¸à¥‡ à¤¶à¤°à¥€à¤° à¤•à¤¾ à¤¤à¥à¤¯à¤¾à¤— à¤•à¤¿à¤¯à¤¾à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤—à¥à¤°à¥ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆà¤œà¥€ à¤•à¥‹ à¤¯à¤¹ à¤µà¤šà¤¨ à¤¦à¤¿à¤¯à¤¾ à¤¥à¤¾ à¤•à¤¿ à¤µà¥‡ à¤‰à¤¨à¤•à¥€ (à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆ à¤œà¥€) à¤§à¤°à¥à¤® à¤ªà¤¤à¥à¤¨à¥€ â€˜à¤œà¤¿à¤¨à¥à¤¹à¥‡à¤‚ à¤¸à¤¬ à¤®à¤¾à¤à¤œà¥€ à¤•à¤¹à¤¤à¥‡ à¤¥à¥‡â€™ à¤•à¥€ à¤¦à¥‡à¤–à¤­à¤¾à¤² à¤‰à¤¨à¤•à¥‡ à¤œà¤¾à¤¨à¥‡ à¤•à¥‡ à¤¬à¤¾à¤¦ à¤•à¤°à¥‡à¤‚à¤—à¥‡, à¤¤à¤¬ à¤¤à¤• à¤œà¤¬ à¤¤à¤• à¤µà¥‡ à¤¶à¤°à¥€à¤° à¤®à¥‡à¤‚ à¤°à¤¹à¥‡à¤‚à¤—à¥€à¥¤ à¤ªà¥‚à¤œà¥à¤¯ à¤®à¤¾à¤à¤œà¥€ à¤•à¥‡ à¤¶à¤°à¥€à¤° à¤¤à¥à¤¯à¤¾à¤—à¤¤à¥‡ à¤¹à¥€, à¤•à¥à¤› à¤¦à¤¿à¤¨à¥‹à¤‚ à¤¬à¤¾à¤¦ à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾ à¤¨à¥‡ â€˜à¤œà¤¾à¤¨à¥‡â€™ à¤•à¤¾ à¤¸à¤‚à¤•à¤²à¥à¤ª à¤•à¤° à¤²à¤¿à¤¯à¤¾ à¤”à¤° à¤…à¤°à¥à¤¥à¤¾à¤¤ à¥§à¥© à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤° à¥§à¥¯à¥¯à¥¨ à¤•à¥‹ à¤¹à¤® à¤¸à¤­à¥€ à¤²à¥‹à¤—à¥‹à¤‚ à¤•à¥‡ à¤®à¤§à¥à¤¯ à¤¸à¥‡ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤¸à¤¦à¤¾ à¤•à¥‡ à¤²à¤¿à¤ à¤µà¤¿à¤¦à¤¾à¤ˆ à¤²à¥€à¥¥ 
à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¨à¤¿à¤®à¤—à¥à¤¨ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¬à¤¾à¤¬à¤¾, à¤œà¤¿à¤¨à¤•à¤¾ â€˜à¤…à¤‚à¤¤à¤ƒà¤•à¤°à¤£â€™ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¹à¥ˆà¤‚, à¤œà¤¿à¤¨à¤•à¤¾ â€˜à¤­à¤¾à¤µ à¤¦à¥‡à¤¹â€™ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¹à¥ˆà¤‚, à¤œà¤¿à¤¨à¤•à¥€ â€˜à¤‡à¤‚à¤¦à¥à¤°à¤¿à¤¯à¤¾à¤â€™ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¹à¥ˆà¤‚, à¤œà¤¿à¤¨à¤•à¥€ â€˜à¤¬à¥à¤¦à¥à¤§à¤¿â€™ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¹à¥ˆà¤‚, à¤‰à¤¨à¤•à¤¾ à¤¸à¤‚à¤•à¥à¤·à¤¿à¤ªà¥à¤¤ à¤œà¥€à¤µà¤¨ à¤ªà¤°à¤¿à¤šà¤¯ à¤•à¥ˆà¤¸à¥‡ à¤²à¤¿à¤–à¤¾ à¤œà¤¾ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆ ? à¤«à¤¿à¤° à¤­à¥€ à¤‰à¤¨à¤•à¥€ à¤•à¥ƒà¤ªà¤¾ à¤¸à¥‡ à¤¹à¥€ à¤•à¥à¤› à¤…à¤‚à¤¶ à¤¯à¤¹à¤¾à¤ à¤¦à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾ à¤¹à¥ˆ à¤ªà¤° à¤¸à¤¤à¥à¤¯ à¤¤à¥‹ à¤¯à¥‡ à¤¹à¥ˆ-''',
        boldFooter: '''      à¤•à¥‹à¤ˆ  à¤¨ à¤šà¤¿à¤¤à¥‡à¤°à¤¾ à¤¹à¥à¤† à¤¯à¤¹à¤¾à¤, à¤†à¤—à¥‡ à¤¨ à¤•à¤­à¥€ à¤¹à¥‹à¤—à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! 
  à¤œà¥‹ à¤šà¤¿à¤¤à¥à¤° à¤¸à¤²à¥‹à¤¨à¥€ à¤¨à¥ƒà¤ªà¤•à¥€ à¤‰à¤¸ à¤¬à¥‡à¤Ÿà¥€à¤•à¤¾ à¤¸à¤¹à¥€ à¤²à¤¿à¤–à¥‡, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !''',
      );
    }
    // 2. Dusri Subheading add karein (Exact wahi title use karein jo drawer mein hai)
    else if (sectionId == 'topic1' &&
        title ==
            'à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤•à¥‡ à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤ªà¤° à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤­à¤¾à¤ˆ à¤œà¥€ à¤•à¥‡ à¤‰à¤¦à¥à¤—à¤¾à¤° à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤²à¤¿à¤') {
      return const _TopicPageContent(
        // Agar isme bhi images chahiye toh unka path yahan dein, warna list khali chhod dein
        imagePaths: [],
        body:
            '''à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¤¾ à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤ à¤†à¤œà¤¸à¥‡ à¤†à¤°à¤®à¥à¤­ à¤¹à¥‹ à¤—à¤¯à¤¾à¥¤ à¤‡à¤¨ à¤¦à¤¿à¤¨à¥‹à¤‚ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¥‡ à¤ªà¤¾à¤¸ à¤œà¥‹ à¤²à¥‹à¤— à¤¬à¤¹à¥à¤¤ à¤†à¤¯à¥‡ à¤—à¤¯à¥‡, à¤œà¤¿à¤¨ à¤²à¥‹à¤—à¥‹à¤‚à¤¸à¥‡ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤¨à¥‡ à¤¬à¤¡à¤¼à¥€ à¤¸à¥à¤µà¤šà¥à¤›à¤¨à¥à¤¦à¤¤à¤¾à¤¸à¥‡ à¤¬à¤¾à¤¤-à¤šà¥€à¤¤ à¤•à¥€, à¤¬à¤¹à¥à¤¤ à¤ªà¥à¤°à¥‡à¤®à¤•à¤¾ à¤¸à¥à¤¨à¥‡à¤¹à¤¸à¤¨à¤¾ à¤µà¥à¤¯à¤µà¤¹à¤¾à¤° à¤•à¤¿à¤¯à¤¾, à¤¬à¤¡à¤¼à¤¾ à¤…à¤®à¥ƒà¤¤ à¤‰à¤¡à¥‡à¤²à¤¾, à¤…à¤¬ à¤‰à¤¨ à¤²à¥‹à¤—à¥‹à¤‚à¤•à¥‡ à¤®à¤¨à¤®à¥‡à¤‚ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¥‡ à¤¨ à¤¬à¥‹à¤²à¤¨à¥‡à¤•à¥€ à¤¸à¥à¤¥à¤¿à¤¤à¤¿ à¤‰à¤¤à¥à¤ªà¤¨à¥à¤¨ à¤¹à¥‹ à¤œà¤¾à¤¨à¥‡à¤¸à¥‡ à¤•à¥à¤·à¥‹à¤­ à¤¹à¥‹à¤¨à¤¾ à¤¸à¥à¤µà¤¾à¤­à¤¾à¤µà¤¿à¤• à¤¹à¥ˆà¥¤ à¤…à¤­à¥€à¤•à¥€ à¤¬à¤¾à¤¤ à¤¹à¥ˆ à¤•à¤¿ à¤®à¥‡à¤°à¥‡ à¤˜à¤°à¤•à¥‡ à¤²à¥‹à¤—, à¤‡à¤¤à¤¨à¤¾ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚, à¤¬à¤šà¥à¤šà¥‡ à¤”à¤° à¤¬à¥‚à¤¢à¤¼à¥‡-à¤¬à¥‚à¤¢à¤¼à¥‡ à¤²à¥‹à¤— à¤­à¥€ à¤®à¥‡à¤°à¥‡ à¤ªà¤¾à¤¸ à¤†à¤¯à¥‡ à¤”à¤° à¤°à¥‹à¤¨à¥‡ à¤²à¤—à¥‡à¥¤ à¤¯à¤¹ à¤¸à¥à¤µà¤¾à¤­à¤¾à¤µà¤¿à¤• à¤¹à¥€ à¤¹à¥ˆà¥¤ à¤œà¤¿à¤¨à¤¸à¥‡ à¤²à¤¾à¤­ à¤®à¤¿à¤²à¤¾, à¤œà¤¿à¤¨à¤¸à¥‡ à¤ªà¥à¤¯à¤¾à¤° à¤®à¤¿à¤²à¤¾, à¤œà¤¿à¤¨à¤¸à¥‡ à¤¸à¥à¤¨à¥‡à¤¹ à¤®à¤¿à¤²à¤¾, à¤œà¤¿à¤¨à¤¸à¥‡ à¤…à¤®à¥ƒà¤¤ à¤®à¤¿à¤²à¤¾, à¤‰à¤¸à¤•à¤¾ à¤¸à¥à¤°à¥‹à¤¤ à¤¯à¤¦à¤¿ à¤•à¤¹à¥€à¤‚ à¤¬à¤¨à¥à¤¦ à¤¹à¥‹à¤¤à¤¾-à¤¸à¤¾ à¤¦à¤¿à¤–à¤²à¤¾à¤¯à¥€ à¤¦à¥‡ à¤¤à¥‹ à¤¸à¥à¤µà¤¾à¤­à¤¾à¤µà¤¿à¤• à¤¹à¥€ à¤®à¤¨à¤®à¥‡à¤‚ à¤•à¥à¤·à¥‹à¤­ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤ªà¤° à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¤¾ à¤¯à¤¹ à¤®à¥Œà¤¨ à¤…à¤¸à¤²à¤®à¥‡à¤‚ à¤¨à¤¯à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤ à¤œà¥‹ à¤²à¥‹à¤— à¤¬à¤¿à¤²à¤•à¥à¤² à¤¨à¤¯à¥‡ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¤‚, à¤µà¥‡ à¤œà¤¾à¤¨à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤•à¤¿ à¤²à¤—à¤­à¤— à¤¦à¤¸ à¤µà¤°à¥à¤· à¤ªà¤¹à¤²à¥‡ à¤‡à¤¸à¥€ à¤ªà¤‚à¤¡à¤¾à¤²à¤®à¥‡à¤‚ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤•à¥€ à¤˜à¥‹à¤·à¤£à¤¾ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤¨à¥‡ à¤•à¥€ à¤¥à¥€à¥¤
à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤•à¤¾ à¤…à¤°à¥à¤¥ à¤•à¥‡à¤µà¤² à¤µà¤¾à¤£à¥€à¤•à¤¾ à¤®à¥Œà¤¨ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾, à¤…à¤ªà¤¿à¤¤à¥ 'à¤œà¤—à¤¤à¤•à¥€ à¤”à¤° à¤¶à¤°à¥€à¤°à¤•à¥€ à¤¸à¤¾à¤°à¥€ à¤•à¥à¤°à¤¿à¤¯à¤¾à¤“à¤‚à¤¸à¥‡ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤ªà¤¨à¥‡à¤•à¥‹ à¤¹à¤Ÿà¤¾ à¤²à¥‡à¤¨à¤¾, à¤¸à¤¬à¤¸à¥‡ à¤®à¥Œà¤¨ à¤¹à¥‹ à¤œà¤¾à¤¨à¤¾' à¤¯à¤¹ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¥¤
 à¤‰à¤¸à¤•à¤¾ à¤µà¤¿à¤§à¤¾à¤¨ à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤° à¤¹à¥ˆ à¤•à¤¿ à¤œà¥‹ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤ à¤²à¥‡, à¤µà¤¹ à¤¸à¤¬ à¤•à¥à¤› à¤ªà¤°à¤¿à¤¤à¥à¤¯à¤¾à¤— à¤•à¤°à¤•à¥‡ à¤˜à¤°à¤¸à¥‡ à¤šà¤² à¤¦à¥‡, à¤•à¥à¤Ÿà¤¿à¤¯à¤¾à¤¸à¥‡ à¤šà¤² à¤¦à¥‡ à¤¹à¤¿à¤®à¤¾à¤²à¤¯à¤•à¥€ à¤“à¤°à¥¤ à¤šà¤²à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤šà¤² à¤¦à¥‡à¥¤ à¤‰à¤¸à¤•à¥‡ à¤®à¤¨à¤®à¥‡à¤‚ à¤•à¤¹à¥€à¤‚à¤ªà¤° à¤µà¤¿à¤¶à¥à¤°à¤¾à¤® à¤•à¤°à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤…à¤¥à¤µà¤¾ à¤ à¤¹à¤°à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¸à¤‚à¤•à¤²à¥à¤ª à¤¨ à¤¹à¥‹à¥¤ à¤šà¤²à¤¤à¥‡-à¤šà¤²à¤¤à¥‡ à¤¦à¥ˆà¤µà¤•à¥€ à¤ªà¥à¤°à¥‡à¤°à¤£à¤¾à¤¸à¥‡ à¤°à¤¾à¤¸à¥à¤¤à¥‡ à¤®à¥‡à¤‚ à¤•à¥‹à¤ˆ à¤•à¥à¤› à¤–à¤¿à¤²à¤¾ à¤¦à¥‡ à¤¤à¥‹ à¤–à¤¾ à¤²à¥‡, à¤•à¥‹à¤ˆ à¤•à¥à¤› à¤ªà¤¿à¤²à¤¾ à¤¦à¥‡ à¤¤à¥‹ à¤ªà¥€ à¤²à¥‡à¥¤ à¤œà¤¹à¤¾à¤ à¤¶à¤°à¥€à¤° à¤…à¤¶à¤•à¥à¤¤ à¤¹à¥‹à¤•à¤° à¤—à¤¿à¤° à¤œà¤¾à¤¯à¥‡, à¤µà¤¹à¤¾à¤ à¤¨à¥€à¤‚à¤¦ à¤²à¥‡ à¤²à¥‡à¥¤ à¤«à¤¿à¤° à¤‰à¤ à¤•à¤° à¤šà¤² à¤¦à¥‡à¥¤ à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤° à¤šà¤²à¤¤à¥‡-à¤šà¤²à¤¤à¥‡ à¤œà¤¹à¤¾à¤ à¤…à¤¨à¥à¤¤à¤¿à¤® à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤¶à¤°à¥€à¤° à¤—à¤¿à¤° à¤œà¤¾à¤¯à¥‡, à¤µà¤¹à¤¾à¤ à¤—à¤¿à¤° à¤œà¤¾à¤¯à¥‡à¥¤
à¤‰à¤¸ à¤¦à¤¿à¤¨ à¤‡à¤¸à¥€ à¤ªà¤‚à¤¡à¤¾à¤²à¤®à¥‡à¤‚ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤•à¤¾ à¤¯à¤¹à¥€ à¤…à¤°à¥à¤¥ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤¨à¥‡ à¤¸à¤®à¤à¤¾à¤¯à¤¾ à¤¥à¤¾à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤•à¤¹à¤¾ à¤¥à¤¾ à¤•à¤¿ à¤‡à¤¸à¥€à¤•à¥‹ à¤²à¤•à¥à¤·à¥à¤¯ à¤•à¤°à¤•à¥‡ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨à¤•à¤¾ à¤®à¤¨à¤®à¥‡à¤‚ à¤µà¤¿à¤šà¤¾à¤° à¤•à¤¿à¤¯à¤¾ à¤¥à¤¾ à¤”à¤° à¤¯à¤¹à¥€ à¤µà¤¿à¤šà¤¾à¤° à¤¹à¥ˆ, à¤ªà¤°à¤‚à¤¤à¥ à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤‡à¤¤à¤¨à¤¾ à¤•à¤¡à¤¼à¤¾ à¤µà¥à¤°à¤¤ à¤•à¥à¤› à¤ à¥€à¤• à¤¨à¤¹à¥€à¤‚ à¤°à¤¹à¤¤à¤¾à¥¤ à¤‡à¤¸à¤²à¤¿à¤¯à¥‡ à¤•à¤¿à¤¸à¥€à¤•à¥€ à¤“à¤° à¤¨ à¤¦à¥‡à¤–à¤¨à¤¾, à¤•à¤¿à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¤¾ à¤¸à¤‚à¤•à¤²à¥à¤ª à¤¨ à¤•à¤°à¤¨à¤¾, à¤‡à¤¶à¤¾à¤°à¥‡à¤¸à¥‡ à¤­à¥€ à¤•à¤¿à¤¸à¥€ à¤¬à¤¾à¤¤à¤•à¤¾ à¤•à¤¿à¤¸à¥€ à¤¤à¤°à¤¹ à¤‰à¤¤à¥à¤¤à¤° à¤¨ à¤¦à¥‡à¤¨à¤¾, à¤à¤¸à¤¾ à¤µà¥à¤°à¤¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤²à¤¿à¤¯à¤¾ à¤”à¤° à¤•à¤ˆ à¤µà¤°à¥à¤·à¥‹à¤‚à¤¤à¤• à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤•à¤¿à¤¸à¥€à¤•à¥€ à¤“à¤° à¤¦à¥‡à¤–à¤¾à¤¤à¤• à¤¨à¤¹à¥€à¤‚à¥¤ à¤†à¤—à¥‡ à¤šà¤²à¤•à¤° à¤•à¥à¤› à¤à¤¸à¥€ à¤•à¤ à¤¿à¤¨ à¤¸à¤®à¤¸à¥à¤¯à¤¾à¤à¤ à¤¸à¤¾à¤®à¤¨à¥‡ à¤†à¤¯à¥€à¤‚ à¤•à¤¿ à¤‰à¤¨à¤•à¥‡ à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤à¤®à¥‡à¤‚ à¤•à¥à¤› à¤¶à¤¿à¤¥à¤¿à¤²à¤¤à¤¾ à¤†à¤¯à¥€à¥¤ à¤µà¤¹ à¤¶à¤¿à¤¥à¤¿à¤²à¤¤à¤¾ à¤­à¥€, à¤‰à¤¨à¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤¶à¤¿à¤¥à¤¿à¤²à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚, à¤…à¤ªà¤¿à¤¤à¥ à¤ªà¤¦à¥à¤§à¤¤à¤¿à¤®à¥‡à¤‚ à¤¶à¤¿à¤¥à¤¿à¤²à¤¤à¤¾ à¤†à¤¯à¥€à¥¤ à¤•à¥à¤°à¤®à¤¶à¤ƒ à¤¶à¤¿à¤¥à¤¿à¤²à¤¤à¤¾ à¤¬à¤¢à¤¼à¤¤à¥€ à¤—à¤¯à¥€à¥¤ à¤«à¤¿à¤° à¤‰à¤¸ à¤¶à¤¿à¤¥à¤¿à¤²à¤¤à¤¾à¤•à¥‹ à¤µà¤¿à¤°à¤¾à¤® à¤¦à¥‡à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤ªà¥à¤¨à¤ƒ à¤¯à¤¹ à¤•à¤²à¤µà¤¾à¤²à¤¾ à¤°à¥‚à¤ª à¤¸à¤¾à¤®à¤¨à¥‡ à¤† à¤—à¤¯à¤¾à¥¤
à¤•à¥à¤› à¤­à¥€à¤¤à¤°à¥€ à¤¬à¤¾à¤¤à¥‡à¤‚ à¤à¤¸à¥€ à¤¹à¥ˆà¤‚, à¤œà¤¿à¤¨à¤•à¥‹ à¤®à¥ˆà¤‚ à¤¸à¤‚à¤•à¥‡à¤¤ à¤°à¥‚à¤ªà¤¸à¥‡ à¤¹à¥€ à¤•à¤¹ à¤¸à¤•à¤¤à¤¾ à¤¹à¥‚à¤à¥¤ à¤¸à¤¬ à¤¬à¤¾à¤¤ à¤¤à¥‹ à¤•à¤¹à¤¨à¤¾ à¤‰à¤šà¤¿à¤¤ à¤¨à¤¹à¥€à¤‚à¥¤ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤®à¥‡à¤‚ à¤”à¤° à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¥‡ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤®à¥‡à¤‚ à¤¥à¥‹à¤¡à¤¼à¤¾-à¤¸à¤¾ à¤…à¤¨à¥à¤¤à¤° à¤¹à¥ˆà¥¤ à¤¯à¥‡ à¤¸à¤¬ à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¥‡ à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤¸à¤¿à¤¦à¥à¤§à¤¾à¤‚à¤¤à¤•à¥€ à¤¬à¤¾à¤¤à¥‡à¤‚ à¤¹à¥ˆà¤‚à¥¤ à¤à¤• à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤°à¤¸-à¤®à¤¾à¤°à¥à¤— à¤”à¤° à¤¦à¥‚à¤¸à¤°à¤¾ à¤œà¥à¤žà¤¾à¤¨-à¤®à¤¾à¤°à¥à¤—à¥¤ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤®à¤¾à¤°à¥à¤—à¥‹à¤‚à¤®à¥‡à¤‚ à¤¹à¥€ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨ à¤…à¤ªà¥‡à¤•à¥à¤·à¤¿à¤¤ à¤¹à¥ˆà¥¤ à¤°à¤¸-à¤®à¤¾à¤°à¥à¤—à¤•à¤¾ à¤¸à¤¿à¤¦à¥à¤§ à¤ªà¥à¤°à¥à¤· à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¤¸à¥‡ à¤°à¤¹à¤¿à¤¤ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾ à¤”à¤° à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¥€à¤®à¥‡à¤‚ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨ à¤°à¤¹à¤¤à¤¾ à¤¹à¥€ à¤¹à¥ˆ, à¤°à¤¸ à¤šà¤¾à¤¹à¥‡ à¤¨ à¤¹à¥‹à¥¤ à¤¦à¥‹à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤‡à¤¤à¤¨à¤¾-à¤¸à¤¾ à¤…à¤¨à¥à¤¤à¤° à¤¹à¥ˆà¥¤ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¥€à¤®à¥‡à¤‚ à¤°à¤¸ à¤šà¤¾à¤¹à¥‡ à¤¨ à¤¹à¥‹, à¤ªà¤° à¤µà¤¹ à¤¤à¤¤à¥à¤¤à¥à¤µà¤®à¥‡à¤‚ à¤¸à¥à¤¥à¤¿à¤¤ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤¬à¥à¤°à¤¹à¥à¤®à¤¨à¤¿à¤·à¥à¤  à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤®à¥à¤•à¥à¤¤ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤‡à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤° à¤°à¤¸-à¤¸à¤¿à¤¦à¥à¤§ à¤ªà¥à¤°à¥à¤· à¤­à¥€ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¥€ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤‰à¤¨à¤•à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤®à¥‡à¤‚ à¤œà¤—à¤¤ à¤µà¥ˆà¤¸à¤¾ à¤¨à¤¹à¥€à¤‚ à¤°à¤¹à¤¤à¤¾, à¤œà¥ˆà¤¸à¤¾ à¤¹à¤® à¤¸à¤¾à¤‚à¤¸à¤¾à¤°à¤¿à¤• à¤²à¥‹à¤—à¥‹à¤‚à¤•à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤®à¥‡à¤‚ à¤¹à¥ˆà¥¤ à¤µà¥‡ à¤œà¤—à¤¤à¤¸à¥‡ à¤®à¥à¤•à¥à¤¤ à¤¹à¥‹ à¤œà¤¾à¤¤à¥‡ à¤¹à¥ˆà¤‚, à¤ªà¤°à¤‚à¤¤à¥ à¤‰à¤¨à¤®à¥‡à¤‚ à¤à¤• à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥‡ à¤°à¤¸à¤•à¤¾ à¤†à¤µà¤¿à¤°à¥à¤­à¤¾à¤µ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤œà¥‹ à¤†à¤—à¥‡ à¤œà¤¾à¤•à¤° à¤¸à¤®à¥à¤¦à¥à¤° à¤¬à¤¨ à¤œà¤¾à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤‰à¤¸ à¤®à¤¹à¤¾à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚ à¤…à¤¨à¤¨à¥à¤¤ à¤¤à¤°à¤‚à¤—à¥‡à¤‚ à¤‰à¤ à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤”à¤° à¤‰à¤¨ à¤¤à¤°à¤‚à¤—à¥‹à¤‚à¤®à¥‡à¤‚ à¤µà¤¹ à¤²à¤¹à¤°à¤¾à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤•à¤­à¥€-à¤•à¤­à¥€ à¤µà¤¹ à¤‰à¤¸ à¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥‡ à¤¤à¤Ÿà¤ªà¤° à¤†à¤¤à¤¾ à¤¹à¥ˆ à¤¤à¥‹ à¤¬à¤¾à¤¹à¤° à¤¦à¤¿à¤–à¤²à¤¾à¤¯à¥€ à¤¦à¥‡à¤¤à¤¾ à¤¹à¥ˆ, à¤…à¤¨à¥à¤¯à¤¥à¤¾ à¤µà¤¹ à¤‰à¤¨à¥à¤¹à¥€à¤‚ à¤¤à¤°à¤‚à¤—à¥‹à¤‚à¤®à¥‡à¤‚ à¤°à¤¹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬à¥‡ à¤¹à¥à¤ à¤²à¥‹à¤—à¥‹à¤‚à¤•à¥‡ à¤‰à¤¦à¤¾à¤¹à¤°à¤£à¤¸à¥à¤µà¤°à¥‚à¤ª à¤µà¤°à¥à¤¤à¤®à¤¾à¤¨à¤®à¥‡à¤‚ à¤¹à¤®à¤¾à¤°à¥‡ à¤¸à¤¾à¤®à¤¨à¥‡ à¤¥à¥‡ à¤¶à¥à¤°à¥€à¤šà¥ˆà¤¤à¤¨à¥à¤¯ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥à¥¤ à¤…à¤¨à¥à¤¤à¤¿à¤® à¤—à¤®à¥à¤­à¥€à¤°à¤¾ à¤²à¥€à¤²à¤¾à¤•à¥‡ à¤¸à¤®à¤¯ à¤µà¥‡ à¤‡à¤¸ à¤°à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥‡ à¤¤à¤Ÿà¤ªà¤° à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤†à¤¯à¥‡, à¤‰à¤¸à¥€à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬à¥‡ à¤°à¤¹à¥‡à¥¤ à¤‰à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¤¾ à¤œà¥‹ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤¥à¤¾, à¤µà¤¹ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤•à¥‡à¤µà¤² à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¤®à¥‡à¤‚ à¤¸à¥à¤¥à¤¿à¤¤à¤¿à¤œà¤¨à¤¿à¤¤ à¤ªà¤‚à¤šà¤® à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤¤à¤• à¤µà¤¾à¤²à¤¾ à¤¨à¤¹à¥€à¤‚, à¤•à¥à¤°à¤¿à¤¯à¤¾à¤•à¥‡ à¤…à¤­à¤¾à¤µà¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤µà¤¾à¤²à¤¾ à¤¨à¤¹à¥€à¤‚, à¤…à¤ªà¤¿à¤¤à¥ à¤°à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥‡ à¤²à¤¹à¤°à¤¾à¤¨à¥‡à¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤µà¤¾à¤²à¤¾ à¤¹à¥ˆà¥¤ à¤¬à¤¸, à¤‡à¤¤à¤¨à¤¾ à¤‡à¤¸à¤®à¥‡à¤‚ à¤”à¤° à¤‰à¤¸à¤®à¥‡à¤‚ à¤…à¤¨à¥à¤¤à¤° à¤¹à¥ˆà¥¤ à¤¯à¤¹ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤°à¤¸à¤•à¤¾ à¤¹à¥ˆ à¤”à¤° à¤µà¤¹ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¤•à¤¾ à¤¹à¥ˆà¥¤
à¤ªà¤¹à¤²à¥‡ à¤¯à¥‡ à¤¶à¥à¤°à¥€à¤°à¤¾à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¬à¤¾à¤¬à¥‚à¤œà¥€ ( à¤ªà¥à¤°à¤¥à¤® à¤°à¤¾à¤·à¥à¤Ÿà¥à¤°à¤ªà¤¤à¤¿ à¤¶à¥à¤°à¥€à¤°à¤¾à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤ªà¥à¤°à¤¸à¤¾à¤¦ à¤œà¥€ ) à¤•à¥‡ à¤¸à¤¾à¤¥ à¤°à¤¾à¤œà¤¨à¥ˆà¤¤à¤¿à¤• à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤•à¤¾à¤® à¤•à¤°à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤µà¥‡ à¤‰à¤®à¥à¤°à¤®à¥‡à¤‚ à¤•à¥à¤› à¤¬à¤¡à¤¼à¥‡ à¤¥à¥‡ à¤”à¤° à¤¯à¥‡ à¤›à¥‹à¤Ÿà¥‡ à¤¥à¥‡, à¤ªà¤° à¤‰à¤¨à¤•à¥‡ à¤¸à¤¾à¤¥ à¤¬à¤¿à¤¹à¤¾à¤°à¤®à¥‡à¤‚ à¤•à¤¾à¤® à¤•à¤°à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤¯à¥‡ à¤¸à¥à¤•à¥‚à¤²à¤¸à¥‡ à¤¨à¤¿à¤•à¤²à¤•à¤° à¤œà¥‡à¤² à¤—à¤¯à¥‡ à¤”à¤° à¤œà¥‡à¤²à¤®à¥‡à¤‚ à¤•à¤ˆ à¤¦à¤¿à¤¨à¥‹à¤‚à¤¤à¤• à¤°à¤¹à¥‡à¥¤ à¤­à¤—à¤µà¤¾à¤¨à¤•à¥€ à¤²à¥€à¤²à¤¾ à¤µà¤¿à¤šà¤¿à¤¤à¥à¤° à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤®à¤¨à¥à¤·à¥à¤¯à¤•à¥‹ à¤ªà¤¤à¤¾à¤¤à¤• à¤¨à¤¹à¥€à¤‚ à¤²à¤—à¤¤à¤¾ à¤•à¤¿ à¤­à¤—à¤µà¤¾à¤¨ à¤•à¤¿à¤¸à¤•à¥‹ à¤•à¥ˆà¤¸à¥‡ à¤•à¤¿à¤¸ à¤®à¤¾à¤°à¥à¤—à¤®à¥‡à¤‚ à¤²à¥‡ à¤œà¤¾à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚, à¤ªà¤° à¤µà¥‡ à¤²à¥‡ à¤œà¤¾à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤°à¤¾à¤œà¤¨à¥ˆà¤¤à¤¿à¤• à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤•à¤¾à¤°à¥à¤¯ à¤•à¤°à¤¤à¥‡-à¤•à¤°à¤¤à¥‡ à¤‰à¤¸à¥€ à¤œà¥‡à¤²à¤®à¥‡à¤‚ à¤‡à¤¨à¤•à¥‡ à¤®à¤¨à¤®à¥‡à¤‚ à¤•à¥à¤› à¤¦à¥‚à¤¸à¤°à¥‡ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥‡ à¤­à¤¾à¤µ à¤†à¤¯à¥‡à¥¤ à¤œà¥‡à¤²à¤®à¥‡à¤‚ à¤¹à¥€ à¤”à¤° à¤œà¥‡à¤²à¤¸à¥‡ à¤¨à¤¿à¤•à¤²à¤¨à¥‡à¤•à¥‡ à¤¬à¤¾à¤¦ à¤‡à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤§à¥à¤¯à¤¯à¤¨ à¤•à¤¿à¤¯à¤¾à¥¤ à¤¶à¥à¤°à¥‚à¤¸à¥‡ à¤¹à¥€ à¤¯à¥‡ à¤¬à¤¡à¤¼à¥‡ à¤ªà¥à¤°à¤¤à¤¿à¤­à¤¾à¤¶à¤¾à¤²à¥€ à¤¥à¥‡à¥¤ à¤•à¤¾à¤²à¥‡à¤œà¤¸à¥‡ à¤ªà¤¹à¤²à¥‡ à¤¹à¥€ à¤¸à¥à¤•à¥‚à¤²à¤®à¥‡à¤‚ à¤¹à¥€ à¤‡à¤¨à¤•à¥€ à¤ªà¥à¤°à¤¤à¤¿à¤­à¤¾à¤•à¤¾ à¤œà¥à¤žà¤¾à¤¨ à¤…à¤§à¥à¤¯à¤¾à¤ªà¤•à¥‹à¤‚à¤•à¥‹ à¤”à¤° à¤…à¤§à¤¿à¤•à¤¾à¤°à¤¿à¤¯à¥‹à¤‚à¤•à¥‹ à¤¹à¥‹ à¤šà¥à¤•à¤¾ à¤¥à¤¾à¥¤ à¤‡à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤¦à¥à¤µà¥ˆà¤¤ à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¤¾ à¤…à¤¨à¥à¤µà¥‡à¤·à¤£, à¤…à¤§à¥à¤¯à¤¯à¤¨ à¤”à¤° à¤¸à¤¾à¤§à¤¨ à¤•à¤¿à¤¯à¤¾ à¤”à¤° à¤¯à¥‡ à¤‰à¤¸à¤®à¥‡à¤‚ à¤¬à¤¹à¥à¤¤ à¤†à¤—à¥‡ à¤¬à¤¢à¤¼ à¤—à¤¯à¥‡à¥¤ à¤•à¤²à¤•à¤¤à¥à¤¤à¥‡à¤®à¥‡à¤‚ à¤¯à¥‡ à¤¬à¤¡à¤¼à¥‡ à¤µà¤¿à¤°à¤•à¥à¤¤ à¤­à¤¾à¤µà¤¸à¥‡ à¤°à¤¹à¤¤à¥‡, à¤•à¤­à¥€ à¤«à¥à¤Ÿà¤ªà¤¾à¤¥à¤ªà¤° à¤ªà¤¡à¤¼à¥‡ à¤°à¤¹à¤¤à¥‡à¥¤ à¤•à¤¹à¥€à¤‚ à¤–à¤¾à¤¨à¥‡à¤•à¥‹ à¤®à¤¿à¤² à¤—à¤¯à¤¾, à¤–à¤¾ à¤²à¥‡à¤¤à¥‡ à¤”à¤° à¤œà¥‹ à¤®à¤¿à¤² à¤—à¤¯à¤¾, à¤²à¥‡ à¤²à¥‡à¤¤à¥‡à¥¤
à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€ (à¤¶à¥à¤°à¥€à¤œà¤¯à¤¦à¤¯à¤¾à¤²à¤œà¥€ à¤—à¥‹à¤¯à¤¨à¥à¤¦à¤•à¤¾) à¤•à¤¾ à¤—à¥€à¤¤à¤¾à¤ªà¤° à¤µà¤¿à¤µà¥‡à¤šà¤¨ à¤¬à¤¡à¤¼à¤¾ à¤¸à¥à¤¨à¥à¤¦à¤° à¤¹à¥à¤† à¤•à¤°à¤¤à¤¾ à¤¥à¤¾à¥¤ à¤‡à¤¨à¤•à¥‡ à¤®à¤¨à¤®à¥‡à¤‚ à¤‰à¤¨à¤•à¥‡ à¤ªà¤¾à¤¸ à¤œà¤¾à¤¨à¥‡à¤•à¥€ à¤‡à¤šà¥à¤›à¤¾ à¤œà¤¾à¤—à¥à¤°à¤¤à¥ à¤¹à¥à¤ˆà¥¤ à¤¯à¥‡ à¤šà¤²à¥‡ à¤—à¤¯à¥‡ à¤¬à¤¾à¤à¤•à¥à¤¡à¤¼à¤¾à¥¤ à¤¬à¤¾à¤à¤•à¥à¤¡à¤¼à¤¾ à¤œà¤¾à¤•à¤° à¤¯à¥‡ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤•à¥‡ à¤ªà¤¾à¤¸ à¤°à¤¹à¥‡à¥¤ à¤¯à¤¹ à¤œà¥‹ à¤—à¥€à¤¤à¤¾-à¤¤à¤¤à¥à¤¤à¥à¤µ-à¤µà¤¿à¤µà¥‡à¤šà¤¨à¥€ à¤Ÿà¥€à¤•à¤¾ à¤¹à¥ˆ, à¤‡à¤¸à¤®à¥‡à¤‚ à¤­à¤¾à¤µ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤•à¥‡ à¤¹à¥ˆà¤‚, à¤ªà¤° à¤‡à¤¸ à¤¸à¤¾à¤°à¥€ à¤Ÿà¥€à¤•à¤¾à¤•à¥‹ à¤®à¥‚à¤²à¤¤à¤ƒ à¤‡à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤¹à¤¾à¤¥à¤¸à¥‡ à¤²à¤¿à¤–à¥€ à¤¹à¥ˆ à¤”à¤° à¤‡à¤¸à¤®à¥‡à¤‚ à¤Ÿà¤¿à¤ªà¥à¤ªà¤£à¥€ à¤”à¤° à¤¸à¤¾à¤°à¤¾ à¤¸à¤‚à¤¶à¥‹à¤§à¤¨ à¤®à¥‡à¤°à¤¾ à¤•à¤¿à¤¯à¤¾ à¤¹à¥à¤† à¤¹à¥ˆà¥¤ à¤µà¤¹à¤¾à¤ à¤¯à¥‡ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤•à¥‡ à¤ªà¤¾à¤¸ à¤°à¤¹à¤¨à¥‡ à¤²à¤—à¥‡à¥¤ à¤¯à¥‡ à¤¬à¤¡à¤¼à¥‡ à¤•à¤Ÿà¥à¤Ÿà¤° à¤¨à¤¿à¤°à¥à¤—à¥à¤£à¤µà¤¾à¤¦à¥€ à¤¥à¥‡à¥¤ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€ à¤¯à¤¦à¥à¤¯à¤ªà¤¿ à¤…à¤¦à¥à¤µà¥ˆà¤¤ à¤¨à¤¿à¤°à¥à¤—à¥à¤£ à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¥‡ à¤¹à¥€ à¤ªà¤°à¤¿à¤ªà¥‹à¤·à¤• à¤¥à¥‡, à¤‡à¤¸à¤ªà¤° à¤­à¥€ à¤µà¥‡ à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¥‡ à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤¸à¤—à¥à¤£ à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¤¾ à¤­à¥€ à¤¨à¤¿à¤°à¥‚à¤ªà¤£ à¤•à¤¿à¤¯à¤¾ à¤•à¤°à¤¤à¥‡ à¤¥à¥‡ à¤”à¤° à¤¯à¥‡ à¤‰à¤¸à¥‡ à¤®à¤¾à¤¯à¤¾ à¤•à¤¹à¤•à¤° à¤–à¤£à¥à¤¡à¤¨ à¤•à¤° à¤¦à¥‡à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤‡à¤¨à¤•à¤¾ à¤†à¤ªà¤¸à¤®à¥‡à¤‚ à¤¤à¤°à¥à¤•-à¤µà¤¿à¤¤à¤°à¥à¤• à¤šà¤²à¤¤à¤¾à¥¤ à¤¤à¤°à¥à¤•-à¤µà¤¿à¤¤à¤°à¥à¤•à¤®à¥‡à¤‚ à¤•à¤¹à¥€à¤‚ à¤•à¤Ÿà¥à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚ à¤†à¤¤à¥€à¥¤ à¤¯à¤¹ à¤¹à¥‹à¤¤à¤¾ à¤¬à¤¡à¤¼à¤¾ à¤¸à¥à¤¨à¥à¤¦à¤° à¤”à¤° à¤†à¤¨à¤¨à¥à¤¦à¤ªà¥‚à¤°à¥à¤£, à¤ªà¤° à¤¤à¤°à¥à¤•-à¤µà¤¿à¤¤à¤°à¥à¤•à¤®à¥‡à¤‚ à¤à¤•-à¤¦à¥‚à¤¸à¤°à¥‡à¤•à¥‹ à¤¸à¤®à¤à¤¾ à¤¸à¤•à¥‡à¤‚, à¤à¤¸à¥€ à¤¸à¥à¤¥à¤¿à¤¤à¤¿ à¤¨à¤¹à¥€à¤‚ à¤†à¤¯à¥€à¥¤ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤•à¥‡ à¤ªà¤¾à¤¸ à¤…à¤¨à¥à¤­à¤µ à¤¥à¤¾, à¤ªà¤° à¤—à¥€à¤¤à¤¾à¤•à¥‡ à¤…à¤¤à¤¿à¤°à¤¿à¤•à¥à¤¤ à¤…à¤¨à¥à¤¯ à¤¶à¤¾à¤¸à¥à¤¤à¥à¤° à¤¨à¤¹à¥€à¤‚ à¤¥à¤¾ à¤”à¤° à¤‡à¤¨à¤•à¥‡ à¤ªà¤¾à¤¸ à¤¬à¤¡à¤¼à¤¾ à¤­à¤¾à¤°à¥€ à¤…à¤§à¥à¤¯à¤¯à¤¨ à¤¥à¤¾à¥¤ à¤œà¤¬ à¤¬à¥à¤°à¤¹à¥à¤®à¤¸à¥‚à¤¤à¥à¤°à¤•à¥‡ à¤¸à¥‚à¤¤à¥à¤°à¥‹à¤‚à¤•à¥‹ à¤²à¥‡à¤•à¤° à¤”à¤° à¤‰à¤ªà¤¨à¤¿à¤·à¤¦à¥‹à¤‚à¤•à¥‡ à¤®à¤¨à¥à¤¤à¥à¤°à¥‹à¤‚à¤•à¥‹ à¤²à¥‡à¤•à¤° à¤¯à¥‡ à¤…à¤ªà¤¨à¥‡ à¤®à¤¤à¤•à¥‹ à¤ªà¥à¤·à¥à¤Ÿ à¤•à¤°à¤¨à¥‡ à¤²à¤—à¤¤à¥‡, à¤¤à¤¬ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€ à¤¸à¤¿à¤¦à¥à¤§à¤¾à¤¨à¥à¤¤à¤•à¥€ à¤¬à¤¾à¤¤ à¤¤à¥‹ à¤•à¤¹ à¤¦à¥‡à¤¤à¥‡, à¤ªà¤° à¤µà¥‡ à¤‰à¤¤à¥à¤¤à¤°à¤•à¤¾ à¤ªà¥à¤°à¤¤à¥à¤¯à¥à¤¤à¥à¤¤à¤° à¤¨à¤¹à¥€à¤‚ à¤¦à¥‡ à¤ªà¤¾à¤¤à¥‡à¥¤ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€ à¤‰à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥€ à¤¶à¤¾à¤¸à¥à¤¤à¥à¤°à¥€à¤¯ à¤­à¤¾à¤·à¤¾à¤®à¥‡à¤‚ à¤…à¤ªà¤¨à¥‡ à¤®à¤¤à¤•à¤¾ à¤ªà¥à¤°à¤¤à¤¿à¤ªà¤¾à¤¦à¤¨ à¤¨à¤¹à¥€à¤‚ à¤•à¤° à¤ªà¤¾à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤à¤• à¤¦à¤¿à¤¨ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤¨à¥‡ à¤•à¤¹à¤¾- à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€ ! à¤†à¤ª à¤­à¤¾à¤ˆ à¤¹à¤¨à¥à¤®à¤¾à¤¨à¤•à¥‡ à¤ªà¤¾à¤¸ à¤šà¤²à¥‡ à¤œà¤¾à¤‡à¤¯à¥‡à¥¤
à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€ à¤®à¥‡à¤°à¥‡ à¤¬à¤¡à¤¼à¥‡ à¤®à¥Œà¤¸à¥‡à¤°à¥‡ à¤­à¤¾à¤ˆ à¤²à¤—à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤®à¥ˆà¤‚ à¤‰à¤¨à¤¸à¥‡ à¤›à¥‹à¤Ÿà¤¾ à¤¥à¤¾, à¤…à¤¤à¤ƒ à¤µà¥‡ à¤®à¥à¤à¥‡ à¤¹à¤¨à¥à¤®à¤¾à¤¨ à¤¹à¥€ à¤•à¤¹à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤•à¥‡ à¤à¤¸à¤¾ à¤•à¤¹à¤¨à¥‡à¤ªà¤° à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤¨à¥‡ à¤•à¤¹à¤¾ à¤µà¤¹à¤¾à¤ à¤œà¤¾à¤•à¤° à¤•à¥à¤¯à¤¾ à¤•à¤°à¤¨à¤¾ à¤¹à¥ˆ ?
à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤¨à¥‡ à¤•à¤¹à¤¾- à¤†à¤ª à¤à¤• à¤¬à¤¾à¤° à¤¹à¥‹ à¤¤à¥‹ à¤†à¤‡à¤¯à¥‡à¥¤
à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤Ÿà¤¿à¤•à¤Ÿ à¤•à¤Ÿà¤µà¤¾ à¤¦à¥€ à¤”à¤° à¤¯à¥‡ à¤¯à¤¹à¤¾à¤ à¤† à¤—à¤¯à¥‡à¥¤ à¤‰à¤¸ à¤¸à¤®à¤¯ à¤¯à¤¹à¤¾à¤ à¤¸à¤¾à¤² à¤­à¤°à¤•à¤¾ à¤…à¤–à¤£à¥à¤¡ à¤¹à¤°à¤¿à¤¨à¤¾à¤® à¤¸à¤‚à¤•à¥€à¤°à¥à¤¤à¤¨ à¤šà¤² à¤°à¤¹à¤¾ à¤¥à¤¾à¥¤ à¤…à¤–à¤£à¥à¤¡ à¤•à¥€à¤°à¥à¤¤à¤¨à¤•à¥‡ à¤¸à¤¾à¤§à¤•à¥‹à¤‚à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤˜à¤¾à¤¸à¤•à¥€ à¤¬à¤¹à¥à¤¤-à¤¸à¥€ à¤•à¥à¤Ÿà¤¿à¤¯à¤¾à¤à¤ à¤¯à¤¹à¤¾à¤ à¤¬à¤¨à¥€ à¤¹à¥à¤ˆ à¤¥à¥€à¤‚, à¤‡à¤¨à¤•à¥‹ à¤à¤• à¤›à¥‹à¤Ÿà¥€-à¤¸à¥€ à¤•à¥à¤Ÿà¤¿à¤¯à¤¾ à¤°à¤¹à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¦à¥‡ à¤¦à¥€ à¤—à¤¯à¥€à¥¤ à¤‡à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤®à¥à¤à¤¸à¥‡ à¤¬à¤¤à¤²à¤¾à¤¯à¤¾ à¤•à¤¿ à¤®à¥ˆà¤‚ à¤•à¤¿à¤¸à¤²à¤¿à¤¯à¥‡ à¤†à¤¯à¤¾ à¤¹à¥‚à¤à¥¤ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤•à¤¹à¤¾ à¤•à¤¿ à¤®à¥ˆà¤‚ à¤¤à¥‹ à¤•à¥à¤› à¤œà¤¾à¤¨à¤¤à¤¾ à¤¹à¥‚à¤ à¤¨à¤¹à¥€à¤‚, à¤ªà¤° à¤†à¤ª à¤°à¤¹à¤¿à¤¯à¥‡à¥¤
à¤¯à¤¹à¤¾à¤ à¤†à¤¨à¥‡à¤•à¥‡ à¤ªà¤¶à¥à¤šà¤¾à¤¤à¥ à¤¯à¥‡ à¤¬à¤¿à¤²à¤•à¥à¤² à¤¬à¤¦à¤² à¤—à¤¯à¥‡à¥¤ à¤¬à¤¦à¤²à¤¤à¥‡-à¤¬à¤¦à¤²à¤¤à¥‡ à¤¯à¥‡ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¥‡à¤¶ à¤•à¤°à¤•à¥‡ à¤µà¥à¤°à¤œ-à¤°à¤¸à¤•à¥‡ à¤‰à¤ªà¤¾à¤¸à¤• à¤¬à¤¨ à¤—à¤¯à¥‡à¥¤ à¤¦à¥‹ à¤šà¥€à¤œ à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µà¤µà¤¾à¤²à¥‡ à¤…à¤¦à¥à¤µà¥ˆà¤¤à¤•à¥‡ à¤µà¤¿à¤°à¥‹à¤§à¥€ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤”à¤° à¤…à¤¦à¥à¤µà¥ˆà¤¤ à¤¤à¤¤à¥à¤¤à¥à¤µà¤µà¤¾à¤²à¥‡ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¥‹ à¤…à¤œà¥à¤žà¤¾à¤¨à¤•à¥€ à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤®à¤¾à¤¨à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤…à¤¦à¥à¤µà¥ˆà¤¤ à¤®à¤¤à¤¾à¤µà¤²à¤®à¥à¤¬à¥€ à¤¸à¤®à¥à¤ªà¥à¤°à¤¦à¤¾à¤¯à¤®à¥‡à¤‚ à¤•à¥à¤› à¤à¤¸à¥‡ à¤­à¥€ à¤¹à¥ˆà¤‚, à¤œà¥‹ à¤­à¤—à¤µà¤¾à¤¨à¤•à¥‹ à¤­à¥€ à¤®à¤¾à¤¯à¤¾à¤•à¥€ à¤µà¤¸à¥à¤¤à¥ à¤®à¤¾à¤¨à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤”à¤° à¤•à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤•à¤¿ à¤ˆà¤¶à¥à¤µà¤° à¤®à¤¾à¤¯à¥‹à¤ªà¤¾à¤§à¤¿à¤• à¤¹à¥ˆà¤‚ à¤¤à¤¥à¤¾ à¤œà¥€à¤µ à¤…à¤µà¤¿à¤¦à¥à¤¯à¥‹à¤ªà¤¾à¤§à¤¿à¤• à¤¹à¥ˆà¥¤ à¤…à¤µà¤¿à¤¦à¥à¤¯à¤¾ à¤”à¤° à¤®à¤¾à¤¯à¤¾à¤•à¤¾ à¤¨à¤¿à¤°à¤¸à¤¨ à¤¹à¥à¤† à¤•à¤¿ à¤¨ à¤œà¥€à¤µ à¤¹à¥ˆ à¤”à¤° à¤¨ à¤ˆà¤¶à¥à¤µà¤° à¤¹à¥ˆà¥¤ à¤µà¥‡ à¤ˆà¤¶à¥à¤µà¤°à¤•à¥€ à¤¸à¤¤à¥à¤¤à¤¾ à¤­à¥€ à¤¤à¤¤à¥à¤¤à¥à¤µà¤¤à¤ƒ à¤¸à¥à¤µà¥€à¤•à¤¾à¤° à¤¨à¤¹à¥€à¤‚ à¤•à¤°à¤¤à¥‡à¥¤ à¤¬à¤¸, à¤¸à¤¾à¤§à¤¨à¤•à¤¾à¤²à¤®à¥‡à¤‚ à¤ˆà¤¶à¥à¤µà¤°à¤•à¤¾ à¤‰à¤ªà¤¯à¥‹à¤— à¤•à¤°à¤¨à¤¾ à¤®à¤¾à¤¨à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤µà¥‡ à¤…à¤¨à¥à¤¤à¤ƒà¤•à¤°à¤£à¤•à¥€ à¤¶à¥à¤¦à¥à¤§à¤¿à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤ˆà¤¶à¥à¤µà¤°à¤•à¤¾ à¤¸à¥à¤¤à¤µà¤¨ à¤•à¤°à¤¨à¤¾, à¤ªà¥‚à¤œà¤¨ à¤•à¤°à¤¨à¤¾ à¤†à¤µà¤¶à¥à¤¯à¤• à¤®à¤¾à¤¨à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¸à¤²à¤¿à¤¯à¥‡ à¤µà¥‡ à¤•à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤•à¤¿ à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¤¾à¤²à¤®à¥‡à¤‚ à¤‰à¤ªà¤¾à¤¸à¤¨à¤¾ à¤­à¥€ à¤¬à¤¡à¤¼à¥€ à¤²à¤¾à¤­à¤¦à¤¾à¤¯à¤• à¤¹à¥‹à¤¤à¥€ à¤¹à¥ˆ, à¤ªà¤° à¤‰à¤ªà¤¾à¤¸à¥à¤¯ à¤ˆà¤¶à¥à¤µà¤° à¤•à¥‹à¤ˆ à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¥€ à¤µà¤¸à¥à¤¤à¥ à¤¨à¤¹à¥€à¤‚, à¤…à¤ªà¤¿à¤¤à¥ à¤µà¤¹ à¤¤à¥‹ à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¥€ à¤šà¥€à¤œ à¤¹à¥ˆà¥¤ à¤‡à¤¸à¥€ à¤¤à¤°à¤¹à¤¸à¥‡ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¥‡ à¤²à¥‹à¤— à¤­à¥€ à¤…à¤¦à¥à¤µà¥ˆà¤¤-à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¤¾ à¤¬à¤¡à¤¼à¤¾ à¤®à¤–à¥Œà¤² à¤‰à¤¡à¤¼à¤¾à¤¯à¤¾ à¤•à¤°à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤”à¤° à¤‡à¤¸à¥‡ à¤œà¤¡à¤¼ à¤¤à¤¥à¤¾ à¤†à¤•à¤¾à¤¶à¤•à¥€ à¤­à¤¾à¤à¤¤à¤¿ à¤¶à¥‚à¤¨à¥à¤¯ à¤•à¤¹à¤•à¤° à¤‰à¤ªà¤¹à¤¾à¤¸ à¤•à¤¿à¤¯à¤¾ à¤•à¤°à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤µà¤¹ à¤‰à¤ªà¤¹à¤¾à¤¸ à¤•à¥à¤› à¤¤à¥‹ à¤‰à¤¨à¤•à¤¾ à¤µà¤¿à¤¨à¥‹à¤¦ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ (à¤”à¤° à¤µà¤¿à¤¨à¥‹à¤¦à¤®à¥‡à¤‚ à¤¤à¥‹ à¤•à¥‹à¤ˆ à¤†à¤ªà¤¤à¥à¤¤à¤¿ à¤¨à¤¹à¥€à¤‚), à¤•à¥à¤› à¤µà¤¹ à¤¶à¤¾à¤¸à¥à¤¤à¥à¤°à¤¾à¤°à¥à¤¥à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¹à¤  à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤•à¥à¤› à¤µà¤¹ à¤¦à¥à¤°à¤¾à¤—à¥à¤°à¤¹ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, (à¤œà¥‹ à¤…à¤šà¥à¤›à¤¾ à¤¨à¤¹à¥€à¤‚) à¤”à¤° à¤•à¥à¤› à¤¤à¥‹ à¤µà¤¹ à¤…à¤œà¥à¤žà¤¾à¤¨ à¤¹à¥€ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤œà¤¿à¤¸à¤•à¤¾ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤“à¤°à¤¸à¥‡ à¤¨à¤¿à¤°à¤¸à¤¨ à¤¹à¥€ à¤¹à¥‹à¤¨à¤¾ à¤šà¤¾à¤¹à¤¿à¤¯à¥‡à¥¤ à¤¯à¥‡ à¤•à¥à¤› à¤¸à¤¿à¤¦à¥à¤§à¤¾à¤¨à¥à¤¤à¤•à¥€ à¤¬à¤¾à¤¤à¥‡à¤‚ à¤¹à¥ˆà¤‚à¥¤ à¤…à¤¦à¥à¤µà¥ˆà¤¤-à¤¤à¤¤à¥à¤¤à¥à¤µà¤®à¥‡à¤‚ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¥€ à¤¨à¤¿à¤·à¥à¤ à¤¾ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥à¤ à¤­à¥€ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µà¤®à¥‡à¤‚ à¤‡à¤¨à¤•à¤¾ à¤ªà¥à¤°à¤µà¥‡à¤¶ à¤¹à¥à¤† à¤”à¤° à¤µà¤¹ à¤ªà¥à¤°à¤µà¥‡à¤¶ à¤‰à¤¤à¥à¤¤à¤°à¥‹à¤¤à¥à¤¤à¤° à¤µà¤°à¥à¤§à¤¿à¤¤ à¤¹à¥‹à¤¤à¤¾ à¤šà¤²à¤¾ à¤—à¤¯à¤¾à¥¤ à¤œà¥‹ à¤‡à¤¨à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤°à¤‚à¤— à¤œà¥€à¤µà¤¨à¤•à¥‡ à¤¸à¤®à¥à¤ªà¤°à¥à¤•à¤®à¥‡à¤‚ à¤†à¤¯à¥‡ à¤¹à¥ˆà¤‚, à¤‰à¤¨à¤•à¥‹ à¤®à¤¾à¤²à¥‚à¤® à¤¹à¥ˆ à¤•à¤¿ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤•à¥€ à¤œà¥‹ à¤…à¤—à¤²à¥‡ à¤¸à¥à¤¤à¤°à¤•à¥€ à¤šà¥€à¤œ à¤¹à¥ˆ, à¤œà¤¿à¤¸à¤•à¥€ à¤°à¥‚à¤ª-à¤°à¥‡à¤–à¤¾ à¤¶à¤¾à¤¯à¤¦ à¤œà¥€à¤µ à¤—à¥‹à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€ à¤¤à¤•à¤¨à¥‡ à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤–à¥€à¤‚à¤šà¥€, à¤µà¥ˆà¤¸à¥€ à¤šà¥€à¤œ à¤‡à¤¨à¤®à¥‡à¤‚ à¤µà¥à¤¯à¤•à¥à¤¤ à¤¹à¥à¤ˆ, à¤‡à¤¨à¤•à¥‡ à¤…à¤¨à¥à¤­à¤µà¤®à¥‡à¤‚ à¤†à¤¯à¥€à¥¤ à¤µà¥‡ à¤µà¥à¤°à¤œ-à¤°à¤¸à¤•à¥‡ à¤‰à¤ªà¤¾à¤¸à¤• à¤¬à¤¨ à¤—à¤¯à¥‡ à¤”à¤° à¤‰à¤¸à¤•à¥€ à¤‰à¤¤à¥à¤¤à¤°à¥‹à¤¤à¥à¤¤à¤° à¤ªà¥à¤·à¥à¤Ÿà¤¿ à¤¹à¥‹à¤¤à¥€ à¤—à¤¯à¥€ à¤”à¤° à¤‰à¤¸à¥€à¤•à¤¾ à¤ªà¤°à¤¿à¤£à¤¾à¤® à¤¥à¤¾ à¤‡à¤¨à¤•à¤¾ à¤ªà¥‚à¤°à¥à¤µà¤•à¤¾ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¥¤ à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤‡à¤¨à¤•à¤¾ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤…à¤¸à¤²à¤®à¥‡à¤‚ à¤‡à¤¨à¤•à¤¾ à¤°à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚ à¤¨à¤¿à¤®à¤œà¥à¤œà¤¨ à¤¹à¥ˆ à¤”à¤° à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤®à¥‡à¤‚ à¤œà¥‹ à¤­à¤¾à¤µà¤¤à¤°à¤‚à¤—à¥‡à¤‚ à¤‰à¤ à¤¾ à¤•à¤°à¤¤à¥€ à¤¹à¥ˆà¤‚, à¤¸à¤®à¥à¤­à¤µ à¤¹à¥ˆ, à¤µà¥‡ à¤‡à¤¨à¤•à¥‡ à¤œà¥€à¤µà¤¨à¤®à¥‡à¤‚ à¤‰à¤ à¥‡à¤‚à¥¤ à¤•à¥ˆà¤¸à¥‡ à¤‰à¤ à¥‡à¤‚, à¤•à¥à¤¯à¤¾ à¤‰à¤ à¥‡à¤‚, à¤¤à¤°à¤‚à¤—à¥‹à¤‚à¤•à¤¾ à¤•à¥à¤› à¤ªà¤¤à¤¾ à¤¨à¤¹à¥€à¤‚ à¤šà¤²à¤¤à¤¾à¥¤ à¤‡à¤¸à¤²à¤¿à¤¯à¥‡ à¤‡à¤¨à¤•à¥€ à¤¯à¤¹ à¤µà¤¸à¥à¤¤à¥ à¤†à¤œà¤•à¥€ à¤•à¥‹à¤ˆ à¤¨à¤¯à¥€ à¤¨à¤¹à¥€à¤‚, à¤ªà¥à¤°à¤¾à¤¨à¥€ à¤šà¥€à¤œ à¤¹à¥ˆ à¤”à¤° à¤…à¤µà¤¶à¥à¤¯ à¤¹à¥€ à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¥‡ à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤¯à¤¹ à¤à¤• à¤¬à¤¡à¤¼à¥€ à¤µà¤¿à¤²à¤•à¥à¤·à¤£ à¤µà¤¸à¥à¤¤à¥ à¤¹à¥ˆ à¤•à¤¿ à¤œà¤¹à¤¾à¤ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µ à¤”à¤° à¤¬à¥à¤°à¤¹à¥à¤®-à¤¤à¤¤à¥à¤¤à¥à¤µ à¤à¤•-à¤¦à¥‚à¤¸à¤°à¥‡à¤•à¥‡ à¤…-à¤ªà¥à¤°à¤¤à¤¿à¤¦à¥à¤µà¤¨à¥à¤¦à¥à¤µà¥€ à¤¹à¥‹à¤•à¤° à¤à¤• à¤¸à¤¾à¤¥ à¤à¤• à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤°à¤¹à¤¤à¥‡ à¤¹à¥‹à¤‚à¥¤ à¤¯à¥‡ à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚ à¤ªà¤¹à¤²à¥‡à¥¤ à¤à¤¸à¤¾ à¤¨à¤¾à¤°à¤¦à¤¾à¤¦à¤¿à¤®à¥‡à¤‚ à¤¥à¤¾à¥¤ à¤­à¤—à¤µà¤¾à¤¨ à¤¶à¤‚à¤•à¤°à¤¾à¤šà¤¾à¤°à¥à¤¯à¤®à¥‡à¤‚ à¤­à¥€ à¤à¤¸à¤¾ à¤®à¤¾à¤¨à¤¾ à¤œà¤¾à¤¤à¤¾ à¤¹à¥ˆ, à¤²à¥‡à¤•à¤¿à¤¨ à¤¯à¥‡ à¤‰à¤¦à¤¾à¤¹à¤°à¤£ à¤µà¤¿à¤°à¤² à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚, à¤¬à¤¹à¥à¤¤ à¤•à¤® à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¸à¤¸à¥‡ à¤²à¥‹à¤—à¥‹à¤‚à¤•à¥‹ à¤¶à¤¿à¤•à¥à¤·à¤¾ à¤²à¥‡à¤¨à¥€ à¤šà¤¾à¤¹à¤¿à¤¯à¥‡à¥¤
à¤œà¥‹ à¤²à¥‹à¤— à¤à¤¸à¤¾ à¤¸à¤®à¤à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤•à¤¿ à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€à¤•à¥‡ à¤®à¥Œà¤¨ à¤¹à¥‹ à¤œà¤¾à¤¨à¥‡à¤¸à¥‡ à¤…à¤¬ à¤¹à¤® à¤²à¤¾à¤­à¤¸à¥‡ à¤µà¤‚à¤šà¤¿à¤¤ à¤¹à¥‹ à¤—à¤¯à¥‡, à¤¯à¤¹ à¤‰à¤¨à¤•à¥€ à¤­à¥‚à¤² à¤¹à¥ˆà¥¤ à¤…à¤¸à¤²à¥€ à¤¬à¤¾à¤¤ à¤¤à¥‹ à¤¯à¤¹ à¤¹à¥ˆ à¤•à¤¿ à¤²à¤¾à¤­à¤¸à¥‡ à¤µà¤‚à¤šà¤¿à¤¤ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤­à¤¾à¤µà¤¸à¥‡ à¤°à¤¹à¤¿à¤¤ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¥¤ à¤¶à¤¾à¤¸à¥à¤¤à¥à¤°à¥‹à¤‚à¤®à¥‡à¤‚ à¤¸à¤‚à¤¤à¤•à¥€ à¤®à¤¹à¤¿à¤®à¤¾ à¤¤à¥‹ à¤¯à¤¹à¤¾à¤à¤¤à¤• à¤•à¤¹à¥€ à¤—à¤¯à¥€ à¤¹à¥ˆ à¤•à¤¿ à¤¯à¤¦à¤¿ à¤•à¤¿à¤¸à¥€ à¤¦à¥‡à¤¶à¤®à¥‡à¤‚ à¤¸à¤‚à¤¤à¤•à¤¾ à¤…à¤¸à¥à¤¤à¤¿à¤¤à¥à¤µ à¤¹à¥ˆ, à¤­à¤²à¥‡ à¤µà¤¹ à¤•à¤¿à¤¸à¥€à¤¸à¥‡ à¤¬à¥‹à¤²à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚, à¤®à¤¿à¤²à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚, à¤µà¤¹ à¤¬à¤¾à¤¤à¤šà¥€à¤¤ à¤¤à¥‹ à¤•à¤°à¤¤à¤¾ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚, à¤•à¥‹à¤ˆ à¤‰à¤¸à¥‡ à¤œà¤¾à¤¨à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚, à¤•à¤¿à¤‚à¤¤à¥ à¤¯à¤¦à¤¿ à¤‰à¤¸à¤•à¤¾ à¤…à¤¸à¥à¤¤à¤¿à¤¤à¥à¤µ à¤¹à¥ˆ à¤¤à¥‹ à¤‰à¤¸ à¤…à¤¸à¥à¤¤à¤¿à¤¤à¥à¤µà¤¸à¥‡ à¤¹à¥€ à¤œà¤¿à¤¤à¤¨à¥‡ à¤…à¤‚à¤¶à¤¤à¤• à¤‰à¤¸ à¤¸à¤‚à¤¤à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¾à¤—à¤²à¥à¤­à¥à¤¯ à¤¹à¥ˆ, à¤œà¤¿à¤¤à¤¨à¤¾ à¤‰à¤¸à¤•à¤¾ à¤¤à¥‡à¤œ à¤¹à¥ˆ, à¤‰à¤¸à¤•à¥‡ à¤…à¤¨à¥à¤ªà¤¾à¤¤à¤¸à¥‡ à¤œà¤—à¤¤à¤•à¥‹ à¤²à¤¾à¤­ à¤…à¤ªà¤¨à¥‡ à¤†à¤ª à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤œà¥ˆà¤¸à¥‡ à¤•à¤¹à¥€à¤‚ à¤¬à¤°à¥à¤« à¤¢à¤•à¥€ à¤¹à¥à¤ˆ à¤°à¤–à¥€ à¤¹à¥‹ à¤”à¤° à¤¹à¤®à¤•à¥‹ à¤¦à¤¿à¤–à¤²à¤¾à¤¯à¥€ à¤¨à¤¹à¥€à¤‚ à¤¦à¥‡, à¤­à¤²à¥‡ à¤¨ à¤¦à¥€à¤–à¥‡, à¤ªà¤° à¤‰à¤¸à¤•à¥€ à¤ à¤£à¥à¤¡ à¤¹à¤®à¥‡à¤‚ à¤®à¤¿à¤²à¥‡à¤—à¥€ à¤¹à¥€à¥¤ à¤‡à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤¸à¤‚à¤¤à¤•à¤¾ à¤°à¤¹à¤¨à¤¾ à¤œà¤—à¤¤à¤®à¥‡à¤‚ à¤²à¤¾à¤­à¤¦à¤¾à¤¯à¤• à¤¹à¥ˆà¥¤
à¤¦à¥‚à¤¸à¤°à¥€ à¤¬à¤¾à¤¤ à¤¯à¤¹ à¤¹à¥ˆ à¤•à¤¿ à¤¯à¤¦à¤¿ à¤•à¤¿à¤¸à¥€ à¤¸à¤‚à¤¤à¤®à¥‡à¤‚ à¤•à¤¿à¤¸à¥€ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤•à¥€ à¤µà¤¾à¤¸à¥à¤¤à¤µà¤¿à¤• à¤¶à¥à¤°à¤¦à¥à¤§à¤¾, à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸ à¤¯à¤¾ à¤ªà¥à¤°à¥‡à¤®-à¤ªà¥à¤°à¥€à¤¤à¤¿ à¤¹à¥ˆ, à¤¤à¥‹ à¤¸à¤‚à¤¤à¤•à¥‡ à¤…à¤‚à¤¦à¤° à¤œà¥‹ à¤­à¤¾à¤µ à¤¹à¥ˆà¤‚, à¤‰à¤¨ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤¸à¤‚à¤•à¥à¤°à¤®à¤£ à¤‰à¤¸ à¤ªà¥à¤°à¥‡à¤®à¥€à¤®à¥‡à¤‚ à¤…à¤ªà¤¨à¥‡ à¤†à¤ª à¤¹à¥‹à¤¤à¤¾ à¤°à¤¹à¥‡à¤—à¤¾à¥¤ à¤µà¤¹ à¤¸à¤‚à¤¤ à¤¨ à¤®à¤¿à¤²à¥‡, à¤¨ à¤¬à¤¾à¤¤à¤šà¥€à¤¤ à¤•à¤°à¥‡ à¤¤à¥‹ à¤•à¥‹à¤ˆ à¤¬à¤¾à¤¤ à¤¨à¤¹à¥€à¤‚, à¤ªà¤° à¤‰à¤¨ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤¸à¤‚à¤•à¥à¤°à¤®à¤£ à¤…à¤ªà¤¨à¥‡ à¤†à¤ª à¤¹à¥‹à¤¤à¤¾ à¤°à¤¹à¥‡à¤—à¤¾à¥¤
à¤¤à¥€à¤¸à¤°à¥€ à¤¬à¤¾à¤¤ à¤‡à¤¸à¤¸à¥‡ à¤­à¥€ à¤”à¤° à¤…à¤§à¤¿à¤• à¤†à¤µà¤¶à¥à¤¯à¤• à¤¹à¥ˆ à¤¸à¤‚à¤¤à¤•à¥€ à¤¸à¥‡à¤µà¤¾à¤•à¥‡ à¤µà¤¿à¤·à¤¯à¤®à¥‡à¤‚à¥¤ à¤¯à¤¹ à¤¬à¤¡à¤¼à¤¾ à¤¸à¥à¤¨à¥à¤¦à¤° à¤¹à¥ˆ à¤”à¤° à¤¸à¤°à¤¾à¤¹à¤¨à¥€à¤¯ à¤¹à¥ˆ à¤•à¤¿ à¤‰à¤¨à¤•à¥‡ à¤¨ à¤¬à¥‹à¤²à¤¨à¥‡à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤¹à¤®à¥‡à¤‚ à¤¬à¥‹à¤²à¥€à¤•à¥‡ à¤µà¤¿à¤¯à¥‹à¤—à¤®à¥‡à¤‚ à¤¦à¥à¤ƒà¤– à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤ªà¤° à¤œà¥‹ à¤‰à¤¨à¤•à¥€ à¤¸à¥‡à¤µà¤¾ à¤•à¤°à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚, à¤‰à¤¨à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤‰à¤šà¤¿à¤¤ à¤¯à¤¹ à¤¹à¥ˆ à¤•à¤¿ à¤¹à¤®à¤¨à¥‡ à¤‰à¤¨à¤¸à¥‡ à¤œà¥‹ à¤¸à¥€à¤–à¤¾ à¤¹à¥ˆ, à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤µà¤¿à¤­à¤¿à¤¨à¥à¤¨ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤œà¥‹ à¤¶à¤¿à¤•à¥à¤·à¤¾ à¤¦à¥€ à¤¹à¥ˆ à¤”à¤° à¤‡à¤¨ à¤¦à¤¿à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤†à¤¨à¥‡-à¤œà¤¾à¤¨à¥‡à¤µà¤¾à¤²à¥‡ à¤²à¥‹à¤—à¥‹à¤‚à¤¸à¥‡ à¤œà¤¿à¤¸à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤œà¥‹ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤•à¤¹à¤¾ à¤¹à¥ˆ, à¤œà¥ˆà¤¸à¥‡ à¤¤à¥à¤® à¤¸à¤¤à¥à¤¯ à¤¬à¥‹à¤²à¤¾ à¤•à¤°à¥‹, à¤¤à¥à¤® à¤—à¤°à¥€à¤¬à¤•à¥€ à¤¸à¥‡à¤µà¤¾ à¤•à¤¿à¤¯à¤¾ à¤•à¤°à¥‹, à¤¤à¥à¤® à¤…à¤®à¥à¤• à¤¨à¤¾à¤®à¤•à¤¾ à¤‡à¤¤à¤¨à¤¾ à¤œà¤ª à¤•à¤¿à¤¯à¤¾ à¤•à¤°à¥‹, à¤¤à¥à¤® à¤‡à¤¤à¤¨à¤¾ à¤ªà¤¾à¤  à¤•à¤¿à¤¯à¤¾ à¤•à¤°à¥‹, à¤‰à¤¸à¥‡ à¤…à¤ªà¤¨à¥‡ à¤œà¥€à¤µà¤¨à¤•à¤¾ à¤µà¥à¤°à¤¤ à¤®à¤¾à¤¨à¤•à¤° à¤…à¤ªà¤¨à¥‡ à¤œà¥€à¤µà¤¨à¤®à¥‡à¤‚ à¤‰à¤¤à¤¾à¤° à¤²à¥‡à¤‚à¥¤ à¤‰à¤¨à¤•à¥€ à¤°à¥à¤šà¤¿à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤° à¤œà¥€à¤µà¤¨ à¤¬à¤¨à¤¾à¤¨à¥‡à¤¸à¥‡ à¤¸à¤šà¥à¤šà¥€ à¤¸à¥‡à¤µà¤¾ à¤¹à¥‹à¤—à¥€ à¤”à¤° à¤‰à¤¨à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤²à¤¾à¤­ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤•à¤°à¤¨à¥‡à¤•à¤¾ à¤¯à¤¹ à¤¬à¤¡à¤¼à¤¾ à¤®à¤¾à¤§à¥à¤¯à¤® à¤¸à¤¿à¤¦à¥à¤§ à¤¹à¥‹à¤—à¤¾à¥¤	
à¤¸à¥à¤µà¤¾à¤®à¥€à¤œà¥€ à¤†à¤œ à¤®à¥Œà¤¨ à¤¹à¥‹ à¤—à¤¯à¥‡à¥¤ à¤‰à¤¨à¤•à¤¾ à¤®à¥Œà¤¨ à¤¹à¥‹à¤¨à¤¾ à¤¬à¤¡à¤¼à¤¾ à¤®à¤‚à¤—à¤²à¤®à¤¯ ! à¤µà¥‡ à¤¯à¤¦à¤¿ à¤°à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬à¥‡à¤‚ à¤”à¤° à¤¡à¥‚à¤¬ à¤œà¤¾à¤¯à¥‡à¤‚ à¤¹à¤®à¥‡à¤¶à¤¾à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¤à¥‹ à¤¸à¥à¤µà¤¾à¤­à¤¾à¤µà¤¿à¤• à¤¹à¥€ à¤‰à¤¸à¤•à¥‡ à¤•à¥à¤› à¤•à¤£ à¤¹à¤®à¤²à¥‹à¤—à¥‹à¤‚à¤•à¥‹ à¤®à¤¿à¤²à¥‡à¤‚à¤—à¥‡ à¤¹à¥€à¥¤ à¤‰à¤¨à¤•à¤¾ à¤¡à¥‚à¤¬à¤¨à¤¾ à¤¬à¤¡à¤¼à¤¾ à¤…à¤šà¥à¤›à¤¾ !''',
      );
    }

    // 3. Teesri Subheading add karein
    else if (sectionId == 'topic1' && title == 'à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ â€“ à¤œà¥€à¤µà¤¨à¤¯à¤¾à¤¤à¥à¤°à¤¾') {
      return const _TopicPageContent(
        imagePaths: [],
        body: '''à¥§. à¥§à¥¬ à¤œà¤¨à¤µà¤°à¥€, à¥§à¥¯à¥§à¥©-		à¤†à¤µà¤¿à¤°à¥à¤­à¤¾à¤µ
à¥¨. à¤¸à¤¨à¥ à¥§à¥¯à¥¨à¥® à¤¸à¥‡ à¤¸à¤¨à¥ à¥§à¥¯à¥©à¥§ à¤¤à¤•-	à¤°à¤¾à¤œà¤¨à¥ˆà¤¤à¤¿à¤• à¤œà¥€à¤µà¤¨ à¤à¤µà¤‚ à¤œà¥‡à¤² à¤¯à¤¾à¤¤à¥à¤°à¤¾
à¥©. à¤¸à¤¨à¥ à¥§à¥¯à¥©à¥¨-			à¤•à¤²à¤•à¤¤à¥à¤¤à¥‡à¤®à¥‡à¤‚ à¤µà¤¿à¤¦à¥à¤¯à¤¾à¤²à¤¯à¥€ à¤¶à¤¿à¤•à¥à¤·à¤¾à¤•à¤¾ à¤ªà¥à¤¨à¤ƒ à¤¶à¥à¤­à¤¾à¤°à¤®à¥à¤­
à¥ª. à¥§-à¥§-à¥§à¥¯à¥©à¥ª à¤¸à¥‡ à¥§à¥ª-à¥§à¥¦-à¥§à¥¯à¥©à¥«-	à¤­à¤—à¤µà¤¾à¤¨à¥â€Œà¤•à¥‡ à¤¨à¤¾à¤® à¤ªà¤¤à¥à¤° à¤²à¤¿à¤–à¤¨à¤¾	
à¥«. à¥§à¥¨ à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥©à¥«-		à¤¸à¤‚à¤¨à¥à¤¯à¤¾à¤¸-à¤—à¥à¤°à¤¹à¤£	
à¥¬. à¤…à¤ªà¥à¤°à¥ˆà¤², à¥§à¥¯à¥©à¥¬-		à¤¸à¤‚à¤¨à¥à¤¯à¤¾à¤¸à¥€ à¤µà¥‡à¤·à¤®à¥‡à¤‚ à¤‡à¤£à¥à¤Ÿà¤°à¤®à¥€à¤¡à¤¿à¤à¤Ÿà¤•à¥€ à¤ªà¤°à¥€à¤•à¥à¤·à¤¾ 
à¤¦à¥‡à¤•à¤° à¤µà¤¿à¤¦à¥à¤¯à¤¾à¤²à¤¯à¥€ à¤¶à¤¿à¤•à¥à¤·à¤¾à¤¸à¥‡ à¤µà¤¿à¤®à¥à¤–à¤¤à¤¾
à¥­. à¤…à¤ªà¥à¤°à¥ˆà¤² à¤¸à¥‡ à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°,à¥§à¥¯à¥©à¥¬ à¤¤à¤•-	à¤…à¤œà¥à¤žà¤¾à¤¤ à¤µà¤¾à¤¸, à¤˜à¥‹à¤° à¤à¤•à¤¾à¤¨à¥à¤¤ à¤¸à¤¾à¤§à¤¨à¤¾ à¤à¤µà¤‚ à¤…à¤¦à¥à¤µà¥ˆà¤¤ à¤¤à¤¤à¥à¤¤à¥à¤µà¤•à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤¸à¥‡ à¤ªà¤°à¤® à¤¸à¤¿à¤¦à¥à¤§à¤¿, à¤•à¥‹à¤¢à¤¼à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤®à¤§à¥à¤¯ à¤¬à¥ˆà¤ à¤¨à¤¾, à¤¸à¥à¤µà¤¾à¤®à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤®à¤¸à¥à¤–à¤¦à¤¾à¤¸à¤œà¥€à¤¸à¥‡ à¤®à¤¿à¤²à¤¨ à¤à¤µà¤‚ à¤¸à¤¤à¥à¤¸à¤‚à¤—
à¥®. à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥©à¥¬- 	à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤¸à¥‡ à¤®à¤¿à¤²à¤¨ à¤¤à¤¥à¤¾ à¤‰à¤¨à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¸à¥‡ à¤®à¤¿à¤²à¤¨à¥‡à¤•à¥€ à¤ªà¥à¤°à¥‡à¤°à¤£à¤¾
à¥¯. à¥¨à¥­ à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥©à¥¬-	à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤¸à¤°à¥à¤µà¤ªà¥à¤°à¤¥à¤® à¤†à¤—à¤®à¤¨ à¤¤à¤¥à¤¾ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¸à¥‡ à¤ªà¥à¤°à¤¥à¤® à¤®à¤¿à¤²à¤¨, à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤šà¤°à¤£ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤à¤µà¤‚ à¤šà¤°à¤£-à¤¸à¥à¤ªà¤°à¥à¤¶à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤®à¤¸à¥‡ à¤¸à¤¾à¤•à¤¾à¤°à¥‹à¤ªà¤¾à¤¸à¤¨à¤¾à¤•à¤¾ à¤¬à¥€à¤œà¤¾à¤°à¥‹à¤ªà¤£
à¥§à¥¦. à¥©à¥¦ à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥©à¥¬-		à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤‡à¤®à¤²à¥€ à¤µà¥ƒà¤•à¥à¤·à¤•à¥‡ à¤¨à¥€à¤šà¥‡ à¤¦à¤¿à¤µà¥à¤¯à¤¾à¤¨à¥à¤­à¥‚à¤¤à¤¿
à¥§à¥§. à¤¨à¤µà¤®à¥à¤¬à¤°, à¥§à¥¯à¥©à¥¬-	à¤—à¥‹à¤°à¤–à¤ªà¥à¤°à¤®à¥‡à¤‚ à¤°à¤¾à¤ªà¥à¤¤à¥€ à¤¨à¤¦à¥€à¤•à¥‡ à¤•à¤¿à¤¨à¤¾à¤°à¥‡ à¤¶à¥à¤°à¥€à¤¹à¤¨à¥à¤®à¤¾à¤¨à¤—à¤¢à¤¼à¥€à¤®à¥‡à¤‚ à¤µà¤¾à¤¸ à¤•à¤°à¤¤à¥‡ à¤¹à¥à¤ à¤­à¤—à¤µà¤¾à¤¨à¥ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨
à¥§à¥¨. à¤¨à¤µà¤®à¥à¤¬à¤° à¤¯à¤¾ à¤¦à¤¿à¤¸à¤®à¥à¤¬à¤°,à¥§à¥¯à¥©à¥¬- 	à¤¶à¥à¤°à¥€à¤¸à¥‡à¤ à¤œà¥€à¤•à¥‡ à¤¸à¤¾à¤¥ à¤°à¤¹à¤¨à¤¾ à¤¤à¤¥à¤¾ à¤²à¤—à¤­à¤— à¤…à¤¢à¤¼à¤¾à¤ˆ à¤µà¤°à¥à¤·à¥‹à¤‚à¤¤à¤• à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤¸à¤¾à¤¥ à¤°à¤¹à¤•à¤° à¤¶à¥à¤°à¥€à¤®à¤¦à¥à¤­à¤—à¤µà¤¦à¥à¤—à¥€à¤¤à¤¾à¤•à¥€ à¤Ÿà¥€à¤•à¤¾à¤•à¥‡ à¤²à¥‡à¤–à¤¨ à¤•à¤¾à¤°à¥à¤¯à¤®à¥‡à¤‚ à¤¸à¤¹à¤¯à¥‹à¤— à¤¦à¥‡à¤¨à¤¾à¥¤ 
à¥§à¥©. à¤¸à¤¨à¥ à¥§à¥¯à¥©à¥­- 	à¤—à¥€à¤¤à¤¾à¤ªà¥à¤°à¥‡à¤¸à¤•à¥‡ à¤à¤• à¤•à¤®à¤°à¥‡à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¶à¤°à¥€à¤°à¤®à¥‡à¤‚ à¤—à¥‹à¤ªà¥€-à¤µà¤ªà¥à¤•à¤¾ à¤…à¤µà¤¤à¤°à¤£ à¤à¤µà¤‚ à¤¤à¤¿à¤°à¥‹à¤­à¤¾à¤µ
à¥§à¥ª. à¥¨à¥¬ à¤¯à¤¾ à¥¨à¥­ à¤¯à¤¾ à¥¨à¥® à¤…à¤ªà¥à¤°à¥ˆà¤²,à¥§à¥¯à¥©à¥¯-	à¤¬à¤¾à¤à¤•à¥à¤¡à¤¼à¤¾à¤®à¥‡à¤‚ à¤•à¥à¤·à¥‡à¤¤à¥à¤° à¤¸à¤‚à¤¨à¥à¤¯à¤¾à¤¸à¤•à¤¾ à¤¸à¤‚à¤•à¤²à¥à¤ª à¤à¤µà¤‚ à¤­à¤—à¤µà¤¾à¤¨à¥ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤•à¥à¤·à¥‡à¤¤à¥à¤°-à¤¸à¤‚à¤¨à¥à¤¯à¤¾à¤¸à¤•à¤¾ à¤¨à¤µà¥€à¤¨ à¤…à¤°à¥à¤¥ à¤¬à¤¤à¤²à¤¾à¤¯à¤¾ à¤œà¤¾à¤¨à¤¾ à¤à¤µà¤‚ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤µà¤ªà¥à¤•à¥‹ 'à¤¸à¤šà¤² à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨' à¤¬à¤¤à¤²à¤¾à¤¨à¤¾à¥¤ 
à¥§à¥«. à¤®à¤ˆ, à¥§à¥¯à¥©à¥¯- 			à¤«à¤–à¤°à¤ªà¥à¤° à¤—à¥à¤°à¤¾à¤®à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤®à¤¾à¤¤à¥ƒ-à¤šà¤°à¤£à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤¿à¤® à¤¦à¤°à¥à¤¶à¤¨
à¥§à¥¬. à¥§à¥§ à¤®à¤ˆ, à¥§à¥¯à¥©à¥¯- 		à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¸à¤¾à¤¥ à¤¨à¤¿à¤¤à¥à¤¯ à¤°à¤¹à¤¨à¥‡à¤•à¤¾ à¤¸à¤‚à¤•à¤²à¥à¤ª
à¥§à¥­. à¤œà¥‚à¤¨ à¤¯à¤¾ à¤œà¥à¤²à¤¾à¤ˆ à¤¯à¤¾ à¤…à¤—à¤¸à¥à¤¤,à¥§à¥¯à¥©à¥¯- 	à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¤¾ à¤¸à¥‚à¤•à¥à¤·à¥à¤® à¤¦à¥‡à¤¹à¤¸à¥‡ à¤ªà¤§à¤¾à¤°à¤•à¤° à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ 'à¤¦à¥€à¤•à¥à¤·à¤¾' à¤¦à¥‡à¤¨à¤¾
à¥§à¥®. à¤¸à¤¨à¥ à¥§à¥¯à¥©à¥¯ à¤¯à¤¾ à¥§à¥¯à¥ªà¥¦ à¤®à¥‡à¤‚- 	à¤¶à¥à¤°à¥€à¤®à¤žà¥à¤œà¥à¤²à¥€à¤²à¤¾-à¤­à¤¾à¤µà¤•à¥€ 'à¤­à¤¾à¤µ-à¤¦à¥€à¤•à¥à¤·à¤¾' (à¤¯à¤¹ à¤ªà¥à¤°à¤¥à¤® à¤­à¤¾à¤µ à¤¦à¥€à¤•à¥à¤·à¤¾)
à¥§à¥¯. à¥¨à¥© à¤…à¤—à¤¸à¥à¤¤, à¥§à¥¯à¥ªà¥§- 	à¤¦à¤¿à¤²à¥à¤²à¥€à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¥à¤® à¤¬à¤¾à¤° 'à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤·à¥à¤Ÿà¤®à¥€' à¤…à¤¤à¤¿ à¤¸à¥‚à¤•à¥à¤·à¥à¤®  à¤°à¥‚à¤ªà¤¸à¥‡ à¤®à¤¨à¤¾à¤¨à¤¾
à¥¨à¥¦. à¤¸à¤®à¥à¤­à¤µà¤¤à¤ƒ à¤¸à¤¨à¥ à¥§à¥¯à¥ªà¥§-à¥ªà¥¨ à¤®à¥‡à¤‚-	à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¸à¤‚à¤•à¥‡à¤¤à¤ªà¤° à¤ªà¥à¤°à¤µà¤šà¤¨à¤•à¤¾ à¤ªà¤°à¤¿à¤¤à¥à¤¯à¤¾à¤— à¤à¤µà¤‚ à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤
à¥¨à¥§. à¤¸à¤¨à¥ à¥§à¥¯à¥ªà¥¨-à¥ªà¥© à¤®à¥‡à¤‚- 	'à¤•à¥‡à¤²à¤¿à¤•à¥à¤žà¥à¤œ' à¤•à¥€ à¤²à¥€à¤²à¤¾à¤“à¤‚à¤•à¤¾ à¤¤à¤¥à¤¾ 'à¤ªà¥à¤°à¥‡à¤®-à¤¸à¤¤à¥à¤¸à¤‚à¤— à¤¸à¥à¤§à¤¾ à¤®à¤¾à¤²à¤¾' à¤•à¤¾ à¤²à¥‡à¤–à¤¨
à¥¨à¥¨. à¤¸à¤¨à¥ à¥§à¥¯à¥ªà¥©-à¥ªà¥ª à¤®à¥‡à¤‚- 	à¤¶à¥à¤°à¥€à¤®à¤žà¥à¤œà¥à¤¶à¥à¤¯à¤¾à¤®à¤¾ à¤­à¤¾à¤µà¤•à¥€ 'à¤­à¤¾à¤µ à¤¦à¥€à¤•à¥à¤·à¤¾' (à¤¯à¤¹ à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤­à¤¾à¤µ à¤¦à¥€à¤•à¥à¤·à¤¾)
à¥¨à¥©. à¤¸à¤¨à¥ à¥§à¥¯à¥ªà¥ª-à¥ªà¥« à¤®à¥‡à¤‚- 		'à¤°à¤¾à¤§à¤¾' à¤¨à¤¾à¤®à¤•à¥‡ à¤œà¤ªà¤¸à¥‡ à¤²à¤—à¤¾à¤µ
à¥¨à¥ª. à¥§à¥¯ à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°, à¥§à¥¯à¥ªà¥«- 	à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¥à¤® à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤·à¥à¤Ÿà¤®à¥€ à¤‰à¤¤à¥à¤¸à¤µ; à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤·à¥à¤Ÿà¤®à¥€à¤•à¥‡ à¤¦à¤¿à¤¨ 'à¤¶à¥à¤°à¥€à¤•à¤¾à¤®-à¤—à¤¾à¤¯à¤¤à¥à¤°à¥€ à¤®à¤‚à¤¤à¥à¤°' à¤¸à¥‡ à¤…à¤°à¥à¤šà¤¨à¤¾
à¥¨à¥«. à¤¸à¤¨à¥ à¥§à¥¯à¥ªà¥¬ à¤¸à¥‡ à¤•à¤ˆ à¤µà¤°à¥à¤·à¥‹à¤‚à¤¤à¤•-	'à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤²à¥€à¤²à¤¾-à¤šà¤¿à¤¨à¥à¤¤à¤¨' 'à¤œà¤—à¤œà¥à¤œà¤¨à¤¨à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾' à¤†à¤¦à¤¿-à¤†à¤¦à¤¿ à¤…à¤¨à¥‡à¤• à¤­à¤¾à¤µà¤ªà¥‚à¤°à¥à¤£ à¤•à¥ƒà¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤ªà¥à¤°à¤£à¤¯à¤¨
à¥¨à¥¬. à¤¸à¤¨à¥ à¥§à¥¯à¥ªà¥¯-à¥«à¥¦ -  		à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥€ à¤†à¤¯à¥-à¤µà¥ƒà¤¦à¥à¤§à¤¿à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¦à¥‡à¤µà¤¾à¤°à¤¾à¤§à¤¨
à¥¨à¥­. à¥¨à¥¬ à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°, à¥§à¥¯à¥«à¥¦- 	'à¤¦à¥‡à¤µà¤°à¥à¤·à¤¿à¤ªà¤° à¤¶à¥à¤°à¥€à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤¨à¤¨à¥à¤¦à¤¿à¤¨à¥€à¤•à¥€ à¤•à¥ƒà¤ªà¤¾' à¤¨à¤¾à¤®à¤• à¤¨à¤¾à¤Ÿà¤¿à¤•à¤¾à¤ªà¤° à¤…à¤­à¤¿à¤¨à¤¯
à¥¨à¥®. à¤¸à¤®à¥à¤­à¤µà¤¤à¤ƒ à¤¸à¤¨à¥ à¥§à¥¯à¥«à¥¦ à¤®à¥‡à¤‚- 	à¤­à¤—à¤µà¤¾à¤¨à¥ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤­à¤—à¤µà¤¤à¥€ à¤¶à¥à¤°à¥€à¤¤à¥à¤°à¤¿à¤ªà¥à¤°-à¤¸à¥à¤¨à¥à¤¦à¤°à¥€à¤•à¥€ à¤…à¤°à¥à¤šà¤¨à¤¾ à¤•à¤°à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¨à¤¿à¤°à¥à¤¦à¥‡à¤¶
à¥¨à¥¯. à¥¨à¥¦ à¤œà¤¨à¤µà¤°à¥€, à¥§à¥¯à¥«à¥§- 	à¤—à¤²à¥‡à¤•à¥€ à¤¹à¤¡à¥à¤¡à¥€ à¤Ÿà¥‚à¤Ÿà¤¨à¥‡à¤¸à¥‡ à¤­à¤—à¤µà¤¤à¥€ à¤¤à¥à¤°à¤¿à¤ªà¥à¤°à¤¸à¥à¤¨à¥à¤¦à¤°à¥€à¤•à¥€ à¤…à¤°à¥à¤šà¤¨à¤¾à¤®à¥‡à¤‚ à¤µà¤¿à¤˜à¥à¤¨
à¥©à¥¦. à¥¯ à¤®à¤ˆ, à¥§à¥¯à¥«à¥§- 	à¤­à¤—à¤µà¤¤à¥€ à¤¤à¥à¤°à¤¿à¤ªà¥à¤°à¤¸à¥à¤¨à¥à¤¦à¤°à¥€ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¨à¤¿à¤œ à¤®à¤‚à¤¤à¥à¤°à¤•à¤¾ à¤¦à¤¾à¤¨ (à¤¯à¤¹ à¤¤à¥€à¤¸à¤°à¥€ à¤­à¤¾à¤µ à¤¦à¥€à¤•à¥à¤·à¤¾)
à¥©à¥§. à¤¸à¤¨à¥ à¥§à¥¯à¥«à¥§ à¤¸à¥‡ à¥§à¥¯à¥«à¥ª à¤¤à¤•- 	à¤…à¤ à¤¾à¤°à¤¹ à¤ªà¥à¤°à¤¾à¤£à¥‹à¤‚à¤•à¤¾ à¤¶à¥à¤°à¤µà¤£
à¥©à¥¨. à¥¨à¥­ à¤œà¤¨à¤µà¤°à¥€,à¥§à¥¯à¥«à¥¬ à¤¸à¥‡ à¥¨à¥¬ à¤…à¤ªà¥à¤°à¥ˆà¤²,à¥§à¥¯à¥«à¥¬ à¤¤à¤•- 	à¤¤à¥€à¤°à¥à¤¥à¤¯à¤¾à¤¤à¥à¤°à¤¾ à¤Ÿà¥à¤°à¥‡à¤¨ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¤à¥€à¤¨ à¤§à¤¾à¤®à¥‹à¤‚à¤•à¥€ à¤ªà¤¾à¤µà¤¨ à¤¯à¤¾à¤¤à¥à¤°à¤¾
à¥©à¥©. à¥§à¥¯ à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥«à¥¬- 		à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¥à¤® à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤
à¥©à¥ª. à¥®-à¥¯ à¤…à¤ªà¥à¤°à¥ˆà¤², à¥§à¥¯à¥«à¥­-		'à¤°à¤¾à¤§à¤¾ à¤­à¤¾à¤µ' à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾, (à¤¯à¤¹ à¤šà¥Œà¤¥à¥€ à¤­à¤¾à¤µà¤¦à¥€à¤•à¥à¤·à¤¾)
à¥©à¥«. à¥§ à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°, à¥§à¥¯à¥«à¥­- 	à¤°à¤¤à¤¨à¤—à¤¢à¤¼à¤®à¥‡à¤‚ à¤µà¤¿à¤¶à¤¿à¤·à¥à¤Ÿ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤·à¥à¤Ÿà¤®à¥€, 'à¤°à¤¸à¥‹à¤ªà¤¾à¤¸à¤¨à¤¾' à¤•à¥‡ à¤¦à¤¿à¤µà¥à¤¯ à¤®à¤‚à¤¤à¥à¤°à¥‹à¤‚à¤•à¤¾ à¤…à¤²à¥Œà¤•à¤¿à¤• à¤°à¥€à¤¤à¤¿à¤¸à¥‡ à¤…à¤µà¤¤à¤°à¤£
à¥©à¥¬. à¤œà¤¨à¤µà¤°à¥€, à¥§à¥¯à¥«à¥®- 	à¤®à¤¥à¥à¤°à¤¾ à¤¸à¥à¤¥à¤¿à¤¤ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾ à¤§à¤°à¥à¤®à¤¶à¤¾à¤²à¤¾à¤®à¥‡à¤‚ â€˜à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤•à¤¾à¤µà¥à¤¯â€™ à¤•à¥‡ à¤²à¥‡à¤–à¤¨à¤•à¥€ à¤ªà¥à¤°à¥‡à¤°à¤£à¤¾ à¤¤à¤¥à¤¾ à¤•à¤¾à¤·à¥à¤  à¤®à¥Œà¤¨à¤¾à¤µà¤§à¤¿à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤£à¤¯à¤¨
à¥©à¥­. à¤¸à¤¨à¥ à¥§à¥¯à¥¬à¥©-à¥¬à¥ª à¤®à¥‡à¤‚- 		à¤°à¤¾à¤¸à¤²à¥€à¤²à¤¾ à¤¦à¥à¤µà¤¾à¤°à¤¾ 'à¤·à¥‹à¤¡à¤¶ à¤—à¥€à¤¤' à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¾à¤£ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾
à¥©à¥®. à¥§à¥¯ à¤œà¤¨à¤µà¤°à¥€, à¥§à¥¯à¥¬à¥ª- 		à¤­à¤—à¤µà¤¤à¥€ à¤¶à¥à¤°à¥€à¤µà¤¿à¤·à¥à¤£à¥à¤ªà¥à¤°à¤¿à¤¯à¤¾à¤œà¥€à¤•à¤¾ à¤œà¤¨à¥à¤®à¥‹à¤¤à¥à¤¸à¤µ à¤®à¤¨à¤¾à¤¨à¤¾
à¥©à¥¯. à¥¨à¥¨ à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°, à¥§à¥¯à¥¬à¥«- 	à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤¸à¥à¤¥à¤¾à¤ªà¤¿à¤¤ à¤¶à¥à¤°à¥€à¤—à¤¿à¤°à¤¿à¤°à¤¾à¤œà¤œà¥€à¤•à¥€ à¤ªà¤°à¤¿à¤•à¥à¤°à¤®à¤¾à¤•à¤¾ à¤¶à¥à¤­à¤¾à¤°à¤®à¥à¤­
à¥ªà¥¦. à¥­ à¤…à¤ªà¥à¤°à¥ˆà¤², à¥§à¥¯à¥¬à¥­- 		à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤
à¥ªà¥§. à¥¨à¥¨ à¤®à¤¾à¤°à¥à¤š, à¥§à¥¯à¥­à¥§- 		à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¤¾ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤¯à¤¾à¤£ à¤¤à¤¥à¤¾ à¤•à¥à¤Ÿà¤¿à¤¯à¤¾à¤•à¤¾ à¤ªà¤°à¤¿à¤¤à¥à¤¯à¤¾à¤—
à¥ªà¥¨. à¥§à¥¬ à¤«à¤°à¤µà¤°à¥€, à¥§à¥¯à¥­à¥«- 	à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤ªà¥à¤°à¥‡à¤°à¤£à¤¾à¤¸à¥‡ à¤•à¥ˆà¤‚à¤¸à¤° à¤…à¤¸à¥à¤ªà¤¤à¤¾à¤²à¤•à¥€ à¤¸à¥à¤¥à¤¾à¤ªà¤¨à¤¾à¤•à¤¾ à¤¸à¤‚à¤•à¤²à¥à¤ª
à¥ªà¥©. à¥¨à¥¬ à¤…à¤—à¤¸à¥à¤¤, à¥§à¥¯à¥­à¥¬- 	à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥€ à¤¸à¤®à¤¾à¤§à¤¿à¤ªà¤° à¤¬à¤¨ à¤°à¤¹à¥‡ à¤¸à¥à¤®à¤¾à¤°à¤•à¤•à¥‡ à¤¨à¤¿à¤°à¥à¤®à¤¾à¤£ à¤•à¤¾à¤°à¥à¤¯à¤•à¥€ à¤ªà¥‚à¤°à¥à¤£à¤¤à¤¾à¤ªà¤° à¤¹à¤°à¥à¤·à¥‹à¤²à¥à¤²à¤¾à¤¸
à¥ªà¥ª. à¥¨à¥¦ à¤…à¤—à¤¸à¥à¤¤, à¥§à¥¯à¥­à¥­- 		à¤²à¤•à¤µà¤¾à¤•à¤¾ à¤à¤Ÿà¤•à¤¾
à¥ªà¥«. à¥­ à¤¦à¤¿à¤¸à¤®à¥à¤¬à¤°, à¥§à¥¯à¥­à¥®- 		à¤¤à¥ƒà¤¤à¥€à¤¯ à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤
à¥ªà¥¬. à¤¸à¤¨à¥ à¥§à¥¯à¥®à¥¨ à¤à¤µà¤‚ à¤¸à¤¨à¥ à¥§à¥¯à¥®à¥ª à¤®à¥‡à¤‚- à¤¦à¥‹ à¤…à¤·à¥à¤Ÿà¤¯à¤¾à¤® à¤²à¥€à¤²à¤¾à¤“à¤‚à¤•à¤¾ à¤†à¤¯à¥‹à¤œà¤¨
à¥ªà¥­.à¥® à¤«à¤°à¤µà¤°à¥€,à¥§à¥¯à¥®à¥« à¤¸à¥‡ à¥§à¥­à¤«à¤°à¤µà¤°à¥€,à¥§à¥¯à¥®à¥« à¤¤à¤•-	à¤¬à¤¾à¤¬à¤¾ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¶à¥à¤°à¥€à¤¡à¥‹à¤‚à¤—à¤°à¥‡à¤œà¥€ à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¥€ à¤¶à¥à¤°à¥€à¤®à¤¦à¥à¤­à¤¾à¤—à¤µà¤¤ à¤•à¤¥à¤¾à¤•à¤¾ à¤¶à¥à¤°à¤µà¤£
à¥ªà¥®. à¥¨à¥§ à¤œà¥‚à¤¨, à¥§à¥¯à¥®à¥«- 	à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¥ƒà¤·à¥à¤£ à¤¸à¤¾à¤§à¤¨à¤¾ à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¾à¤£-à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾à¤•à¤¾ à¤µà¤¿à¤¶à¤¦ à¤†à¤¯à¥‹à¤œà¤¨
à¥ªà¥¯. à¥« à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥¯à¥§ à¤¸à¥‡ à¥¨à¥© à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°, à¥§à¥¯à¥¯à¥¨ à¤¤à¤•- 	à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¤¾ à¤œà¤¨à¥à¤®-à¤¶à¤¤à¤¾à¤¬à¥à¤¦à¥€ à¤‰à¤¤à¥à¤¸à¤µ à¤¸à¤¾à¤°à¥‡ à¤¦à¥‡à¤¶à¤®à¥‡à¤‚ à¤µà¤°à¥à¤·à¤­à¤° à¤¯à¤¤à¥à¤°-à¤¤à¤¤à¥à¤° à¤®à¤¨à¤¾à¤¯à¤¾ à¤—à¤¯à¤¾
à¥«à¥¦. à¥¨à¥¬ à¤¸à¤¿à¤¤à¤®à¥à¤¬à¤°, à¥§à¥¯à¥¯à¥¨- 	à¤ªà¥‚à¤œà¥à¤¯à¤¾ à¤®à¥ˆà¤¯à¤¾à¤•à¤¾ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤¯à¤¾à¤£
à¥«à¥§. à¥§à¥© à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤°, à¥§à¥¯à¥¯à¥¨- 	à¤ªà¥‚à¤œà¥à¤¯à¤¾ à¤®à¥ˆà¤¯à¤¾à¤•à¥‡ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤¯à¤¾à¤£à¤•à¥‡ à¤‰à¤ªà¤°à¤¾à¤¨à¥à¤¤ à¤¶à¥à¤°à¤¾à¤¦à¥à¤§-à¤•à¤°à¥à¤®à¤•à¤¾à¤£à¥à¤¡à¤•à¥€ à¤ªà¥à¤°à¤•à¥à¤°à¤¿à¤¯à¤¾à¤•à¥‡ à¤¸à¤®à¥à¤ªà¤¨à¥à¤¨ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥€ à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤¯à¤¾à¤£ à¤²à¥€à¤²à¤¾ à¥¥ 

    à¤°à¤¾à¤§à¤¾ à¤°à¤¾à¤§à¤¾ à¤°à¤¾à¤§à¤¾ à¤°à¤¾à¤§à¤¾''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œ') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''à¤à¤• à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤°à¤¸-à¤®à¤¾à¤°à¥à¤— à¤”à¤° à¤¦à¥‚à¤¸à¤°à¤¾ à¤œà¥à¤žà¤¾à¤¨-à¤®à¤¾à¤°à¥à¤—à¥¤ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤®à¤¾à¤°à¥à¤—à¥‹à¤‚à¤®à¥‡à¤‚ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨ à¤…à¤ªà¥‡à¤•à¥à¤·à¤¿à¤¤ à¤¹à¥ˆà¥¤ à¤°à¤¸-à¤®à¤¾à¤°à¥à¤—à¤•à¤¾ à¤¸à¤¿à¤¦à¥à¤§ à¤ªà¥à¤°à¥à¤· à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¤¸à¥‡ à¤°à¤¹à¤¿à¤¤ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾ à¤”à¤° à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¥€à¤®à¥‡à¤‚ à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨ à¤°à¤¹à¤¤à¤¾ à¤¹à¥€ à¤¹à¥ˆ, à¤°à¤¸ à¤šà¤¾à¤¹à¥‡ à¤¨ à¤¹à¥‹à¥¤...... (à¤¬à¤¾à¤¬à¤¾) à¤•à¤¾ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤•à¥‡à¤µà¤² à¤¤à¤¤à¥à¤¤à¥à¤µà¤œà¥à¤žà¤¾à¤¨à¤®à¥‡à¤‚ à¤¸à¥à¤¥à¤¿à¤¤à¤¿à¤œà¤¨à¤¿à¤¤ à¤ªà¤‚à¤šà¤® à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤µà¤¾à¤²à¤¾ à¤¨à¤¹à¥€à¤‚, à¤•à¥à¤°à¤¿à¤¯à¤¾à¤•à¥‡ à¤…à¤­à¤¾à¤µà¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤µà¤¾à¤²à¤¾ à¤¨à¤¹à¥€à¤‚, à¤…à¤ªà¤¿à¤¤à¥ à¤°à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥‡ à¤²à¤¹à¤°à¤¾à¤¨à¥‡à¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤µà¤¾à¤²à¤¾ à¤¹à¥ˆà¥¤ 
(à¤¬à¤¾à¤¬à¤¾) à¤•à¥‡ à¤œà¥‹ à¤…à¤¨à¥à¤¤à¤°à¤‚à¤— à¤œà¥€à¤µà¤¨à¤•à¥‡ à¤¸à¤®à¥à¤ªà¤°à¥à¤•à¤®à¥‡à¤‚ à¤†à¤¯à¥‡ à¤¹à¥ˆà¤‚, à¤‰à¤¨à¤•à¥‹ à¤®à¤¾à¤²à¥‚à¤® à¤¹à¥ˆ à¤•à¤¿ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤•à¥€ à¤œà¥‹ à¤…à¤—à¤²à¥‡ à¤¸à¥à¤¤à¤°à¤•à¥€ à¤šà¥€à¤œ à¤¹à¥ˆ, à¤œà¤¿à¤¸à¤•à¥€ à¤°à¥‚à¤ª-à¤°à¥‡à¤–à¤¾ à¤¶à¤¾à¤¯à¤¦ à¤—à¥‹à¤¸à¥à¤µà¤¾à¤®à¥€ à¤ªà¥à¤°à¤­à¥ƒà¤¤ à¤°à¤¸-à¤®à¤°à¥à¤®à¤œà¥à¤žà¥‹à¤‚ à¤¤à¤•à¤¨à¥‡ à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤–à¥€à¤‚à¤šà¥€, à¤µà¥ˆà¤¸à¥€ à¤šà¥€à¤œ à¤‡à¤¨à¤®à¥‡à¤‚ à¤µà¥à¤¯à¤•à¥à¤¤ à¤¹à¥à¤ˆ, à¤‡à¤¨à¤•à¥‡ à¤…à¤¨à¥à¤­à¤µà¤®à¥‡à¤‚ à¤†à¤¯à¥€à¥¤...... à¤‡à¤¸  à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡  à¤‡à¤¨à¤•à¤¾  à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨  à¤…à¤¸à¤²à¤®à¥‡à¤‚  à¤‡à¤¨à¤•à¤¾ à¤°à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚  à¤¨à¤¿à¤®à¤œà¥à¤œà¤¨ à¤¹à¥ˆà¥¤ ...... à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¥‡ à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤¯à¤¹ à¤à¤• à¤¬à¤¡à¤¼à¥€ à¤µà¤¿à¤²à¤•à¥à¤·à¤£ à¤µà¤¸à¥à¤¤à¥ à¤¹à¥ˆ à¤•à¤¿ à¤œà¤¹à¤¾à¤ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µ à¤”à¤° à¤¬à¥à¤°à¤¹à¥à¤®-à¤¤à¤¤à¥à¤¤à¥à¤µ à¤à¤•-à¤¦à¥‚à¤¸à¤°à¥‡à¤•à¥‡ à¤…-à¤ªà¥à¤°à¤¤à¤¿à¤¦à¥à¤µà¤¨à¥à¤¦à¥à¤µà¥€ à¤¹à¥‹à¤•à¤° à¤à¤• à¤¸à¤¾à¤¥ à¤à¤• à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤°à¤¹à¤¤à¥‡ à¤¹à¥‹à¤‚à¥¤ à¤¯à¥‡ à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚ à¤ªà¤¹à¤²à¥‡à¥¤ à¤à¤¸à¤¾ à¤¨à¤¾à¤°à¤¦à¤¾à¤¦à¤¿à¤®à¥‡à¤‚ à¤¥à¤¾à¥¤ à¤­à¤—à¤µà¤¾à¤¨ à¤¶à¤‚à¤•à¤°à¤¾à¤šà¤¾à¤°à¥à¤¯à¤®à¥‡à¤‚ à¤­à¥€ à¤à¤¸à¤¾ à¤®à¤¾à¤¨à¤¾ à¤œà¤¾à¤¤à¤¾ à¤¹à¥ˆ, à¤²à¥‡à¤•à¤¿à¤¨ à¤¯à¥‡ à¤‰à¤¦à¤¾à¤¹à¤°à¤£ à¤µà¤¿à¤°à¤² à¤¹à¥‹à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'à¤ªà¤°à¤® à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤¬à¤¾à¤²à¤•à¥ƒà¤·à¥à¤£à¤¦à¤¾à¤¸à¤œà¥€ à¤®à¤¹à¤¾à¤°à¤¾à¤œ') {
      return const _TopicPageContent(
        imagePaths: [],
        body: '''à¤¹à¤°à¥‡  à¤°à¤¾à¤®  à¤¹à¤°à¥‡  à¤°à¤¾à¤®  à¤°à¤¾à¤®  à¤°à¤¾à¤®  à¤¹à¤°à¥‡  à¤¹à¤°à¥‡à¥¤
à¤¹à¤°à¥‡ à¤•à¥ƒà¤·à¥à¤£ à¤¹à¤°à¥‡ à¤•à¥ƒà¤·à¥à¤£ à¤•à¥ƒà¤·à¥à¤£ à¤•à¥ƒà¤·à¥à¤£ à¤¹à¤°à¥‡ à¤¹à¤°à¥‡ à¥¥

à¤¸à¥à¤¨à¤¿  à¤®à¥‡à¤°à¥‹  à¤µà¤šà¤¨  à¤›à¤¬à¥€à¤²à¥€  à¤°à¤¾à¤§à¤¾, à¤¤à¥ˆà¤‚  à¤ªà¤¾à¤¯à¥Œ  à¤°à¤¸ à¤¸à¤¿à¤‚à¤§à¥ à¤…à¤—à¤¾à¤§à¤¾à¥¥ 
à¤¤à¥‚  à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥  à¤—à¥‹à¤ª  à¤•à¥€  à¤¬à¥‡à¤Ÿà¥€,  à¤®à¥‹à¤¹à¤¨ à¤²à¤¾à¤² à¤°à¤¸à¤¿à¤•  à¤¹à¤à¤¸à¤¿  à¤­à¥‡à¤‚à¤Ÿà¥€à¥¤ 
à¤œà¤¾à¤¹à¤¿  à¤¬à¤¿à¤°à¤‚à¤šà¤¿  à¤‰à¤®à¤¾à¤ªà¤¤à¤¿  à¤¨à¤¾à¤¯à¥‡, à¤¤à¤¾à¤ªà¥ˆà¤‚    à¤¤à¥‡à¤‚   à¤¬à¤¨  à¤«à¥‚à¤²  à¤¬à¤¿à¤¨à¤¾à¤¯à¥‡à¥¥
à¤œà¥‹ à¤°à¤¸ à¤¨à¥‡à¤¤à¤¿-à¤¨à¥‡à¤¤à¤¿ à¤¶à¥à¤°à¥à¤¤à¤¿ à¤­à¤¾à¤–à¥à¤¯à¥Œ, à¤¤à¤¾à¤•à¥‹  à¤…à¤§à¤°  à¤¸à¥à¤§à¤¾ à¤°à¤¸ à¤šà¤¾à¤–à¥à¤¯à¥Œà¥¤ 
à¤¤à¥‡à¤°à¥Œ à¤°à¥‚à¤ª à¤•à¤¹à¤¤ à¤¨à¤¹à¥€à¤‚ à¤†à¤µà¥ˆ,   à¤¹à¤¿à¤¤  à¤¹à¤°à¤¿à¤µà¤‚à¤¶  à¤•à¤›à¥à¤•  à¤œà¤¸  à¤—à¤¾à¤µà¥ˆà¥¥ 

à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤°à¤¸à¤¸à¥à¤§à¤¾à¤¸à¤¿à¤¨à¥à¤§à¥à¤¸à¥‡ à¤†à¤¨à¥à¤¦à¥‹à¤²à¤¿à¤¤-à¤†à¤¹à¥à¤²à¤¾à¤¦à¤¿à¤¤ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤šà¤°à¤£à¤¨à¤–à¤®à¤£à¤¿-à¤šà¤¨à¥à¤¦à¥à¤°à¤šà¥à¤›à¤Ÿà¤¾à¤¸à¥‡ à¤†à¤²à¥‹à¤•à¤¿à¤¤ à¤…à¤²à¤‚à¤•à¥ƒà¤¤ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¨à¤¿à¤®à¤—à¥à¤¨ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤•à¥à¤¯à¤¾ à¤¹à¥ˆà¤‚, à¤¹à¤®à¤¨à¥‡ à¤‡à¤¸ à¤•à¥à¤·à¤£à¤¤à¤• à¤ªà¤¹à¤šà¤¾à¤¨à¤¾ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤†à¤ª à¤µà¤¹à¥€à¤‚ à¤¹à¥ˆà¤‚, à¤¯à¤¹à¤¾à¤ à¤¨à¤¹à¥€à¤‚, à¤•à¤¿à¤žà¥à¤šà¤¤à¥ à¤­à¥€ à¤¨à¤¹à¥€à¤‚, à¤•à¤¦à¤¾à¤ªà¤¿ à¤¨à¤¹à¥€à¤‚à¥¤ à¤†à¤ªà¤•à¥€ à¤µà¤šà¤¨à¤¾à¤°à¤¸à¤¾à¤®à¥ƒà¤¤à¤§à¤¾à¤°à¤¾à¤®à¥‡à¤‚ à¤¹à¥‹à¤¨à¥‡à¤ªà¤° à¤ªà¥à¤°à¤¤à¤¿à¤ªà¤— à¤ªà¥à¤°à¤¤à¤¿à¤•à¥à¤·à¤£ à¤®à¥‚à¤°à¥à¤¤à¤¿à¤®à¤¾à¤¨ à¤®à¤¾à¤§à¥à¤°à¥à¤¯à¤°à¤¸à¤¸à¤¿à¤¨à¥à¤§à¥à¤•à¤¾ à¤®à¤¿à¤²à¤¨-à¤¹à¥€-à¤®à¤¿à¤²à¤¨ à¤¹à¥ˆ, à¤¨à¤µ-à¤¨à¤µ à¤²à¥€à¤²à¤¾à¤°à¤¸à¤¾à¤¨à¥à¤­à¤µ à¤¹à¥ˆà¥¤ à¤•à¥‹à¤ˆ à¤²à¤¾à¤²à¤¸à¤¾à¤ªà¥‚à¤°à¥à¤£ à¤¸à¥Œà¤­à¤¾à¤—à¥à¤¯à¤µà¤¾à¤¨ à¤ªà¥à¤®à¤¾à¤¨à¥ à¤¹à¥€ à¤†à¤ªà¤•à¥‡ à¤µà¤šà¤¨à¤¸à¥à¤§à¤¾à¤°à¤¸à¤ªà¥à¤°à¤µà¤¾à¤¹à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¤¾à¤¹à¤¿à¤¤ à¤¹à¥‹à¤•à¤° à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾-à¤®à¤¾à¤§à¤µ-à¤®à¤¿à¤²à¤¨-à¤®à¤¹à¥‹à¤¤à¥à¤¸à¤µà¤®à¥‡à¤‚ à¤¸à¤®à¥à¤®à¤¿à¤²à¤¿à¤¤ à¤¹à¥‹ à¤¸à¤•à¥‡à¤—à¤¾à¥¤ à¤¶à¥à¤°à¥€à¤¯à¤®à¥à¤¨à¤¾à¤²à¤¹à¤°-à¤¸à¤®à¤²à¤‚à¤•à¥ƒà¤¤ à¤¨à¤¿à¤•à¥à¤žà¥à¤œ-à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚ à¤µà¤¿à¤•à¥à¤°à¥€à¤¡à¤¼à¤¿à¤¤-à¤µà¤¿à¤²à¤¸à¤¿à¤¤ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤°à¤¸à¤¸à¥à¤§à¥‹à¤¨à¥à¤®à¤¤à¥à¤¤à¤•à¥‡ à¤šà¤°à¤£-à¤•à¤®à¤²à¥‹à¤‚à¤¸à¥‡ à¤šà¤¿à¤¹à¥à¤¨à¤¿à¤¤ à¤°à¤®à¥à¤¯ à¤ªà¤¥à¤®à¥‡à¤‚ à¤ªà¥‚à¤°à¥à¤£à¤¾à¤¨à¥à¤—à¤¤ à¤¹à¥‹à¤•à¤° à¤¨à¤¿à¤œ-à¤®à¤§à¥à¤ª-à¤¸à¥à¤µà¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤ªà¥à¤¨à¤ƒ à¤†à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤®à¤§à¥à¤° à¤¸à¤‚à¤•à¥‡à¤¤ à¤¹à¥ˆ, à¤‰à¤¨à¤•à¥€ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥-à¤¸à¤®à¥€à¤ªà¤¤à¤¾à¤•à¤¾ à¤…à¤²à¤­à¥à¤¯ à¤²à¤¾à¤­ à¤¹à¥ˆ, à¤šà¤¿à¤°à¤•à¤¾à¤²à¤¤à¤• à¤®à¤§à¥à¤°à¤¸à¥à¤§à¤¾à¤°à¤¸à¤¾à¤µà¤—à¤¾à¤¹à¤¨ à¤•à¤°à¤¨à¥‡à¤®à¥‡à¤‚ à¤®à¤§à¥à¤° à¤¸à¤®à¤¾à¤—à¤® à¤¹à¥ˆà¥¤
'à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤®à¤§à¥à¤° à¤¨à¤¾à¤®, à¤¬à¤¿à¤¨à¤¾ à¤¶à¥à¤°à¥€à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¾ à¤°à¤¾à¤§à¤¾à¤¸à¥‡ à¤®à¤¿à¤²à¥‡, à¤à¤•à¤¾à¤•à¥€ à¤°à¤¹à¤•à¤° à¤¶à¥à¤°à¤µà¤£ à¤•à¥ˆà¤¸à¥‡ à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¥à¥‡ ? à¤…à¤ªà¤¨à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤¸à¥à¤µà¤°à¥‚à¤ªà¤¾à¤¨à¥à¤­à¤µ à¤•à¥ˆà¤¸à¥‡ à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¥à¥‡ ? à¤…à¤¸à¤®à¥à¤­à¤µ, à¤…à¤¸à¤®à¥à¤­à¤µ à¥¤ (à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¾) à¤•à¥‹à¤ˆ à¤®à¤§à¥à¤° à¤¨à¤¾à¤® à¤²à¥‡à¤‚, à¤¯à¤¹à¥€ à¤¤à¥‹ à¤°à¤¹à¤¸à¥à¤¯ à¤¸à¤‚à¤¯à¥à¤•à¥à¤¤à¤¤à¤¾à¤¸à¥‡ à¤“à¤¤-à¤ªà¥à¤°à¥‹à¤¤ à¤†à¤ªà¥à¤²à¤¾à¤µà¤¿à¤¤ à¤¹à¥ˆà¥¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤ªà¥à¤°à¤¸à¤‚à¤—à¥‹à¤‚à¤®à¥‡à¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¾-à¤ªà¥à¤°à¤¸à¤‚à¤—à¥‹à¤‚à¤®à¥‡à¤‚, à¤¦à¥‹à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤à¤•à¤•à¥‹ à¤­à¥€ à¤¦à¥‡à¤–à¥‡à¤‚ à¤¤à¥‹ à¤²à¥€à¤²à¤¾ à¤¹à¥€ à¤¦à¥€à¤–à¥‡à¤—à¥€à¥¤ à¤…à¤¨à¥à¤°à¤‚à¤œà¤¿à¤¤à¤®à¥‡à¤‚ à¤…à¤¨à¥à¤°à¤‚à¤œà¤¿à¤¤à¤¾, à¤…à¤¨à¥à¤°à¤‚à¤œà¤¿à¤¤à¤¾à¤®à¥‡à¤‚ à¤…à¤¨à¥à¤°à¤‚à¤œà¤¿à¤¤ à¥¤ à¤ªà¥à¤°à¥‡à¤®à¤•à¤¾ à¤…à¤ªà¤¾à¤° à¤…à¤¨à¥à¤ªà¤®à¥‡à¤¯ à¤…à¤µà¤°à¥à¤£à¤¨à¥€à¤¯ à¤¸à¤¾à¤®à¥à¤°à¤¾à¤œà¥à¤¯ à¤¹à¥ˆ à¤¯à¤¹à¥¤ à¤¸à¤‚à¤¯à¥à¤•à¥à¤¤à¤¤à¤¾à¤•à¤¾ à¤¹à¥€ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤…à¤¨à¥à¤­à¤µ à¤¶à¥à¤°à¥€à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¥€ à¤šà¤°à¥à¤šà¤¾à¤®à¥‡à¤‚à¥¤ à¤¸à¤®à¥à¤¯à¤•à¥ à¤¸à¤‚à¤¯à¥à¤•à¥à¤¤à¤¤à¤¾à¤¨à¥à¤­à¤µ à¤•à¤°à¤¾à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤ 'à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤¯à¤¹ à¤®à¤§à¥à¤° à¤¨à¤¾à¤® à¤®à¥‚à¤°à¥à¤¤à¤¿à¤®à¤¾à¤¨ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¾-à¤ªà¤°à¤¿à¤®à¤£à¥à¤¡à¤¿à¤¤ à¤ªà¤°à¤¸à¥à¤ªà¤°-à¤®à¤¿à¤²à¤¿à¤¤-à¤°à¤¸à¤¾à¤¨à¥à¤­à¤µ à¤¹à¥ˆà¥¤ à¤¦à¥‚à¤°à¥€ à¤µ à¤¦à¥‡à¤°à¥€à¤•à¥€ à¤•à¤²à¥à¤ªà¤¨à¤¾à¤¸à¥‡ à¤¬à¥‡à¤¸à¥à¤§ à¤•à¤°à¤¾à¤¨à¥‡à¤µà¤¾à¤²à¥€, à¤…à¤µà¤¿à¤²à¤®à¥à¤¬ à¤¸à¤®à¥€à¤ª à¤®à¤¿à¤²à¤¨à¥‡à¤µà¤¾à¤²à¥€ à¤¹à¥ˆ à¤°à¥‚à¤ªà¤®à¤¾à¤§à¥à¤°à¥€à¤šà¤°à¥à¤šà¤¾ à¤²à¥€à¤²à¤¾à¤®à¤¾à¤§à¥à¤°à¥€à¤šà¤°à¥à¤šà¤¾à¥¤
à¤¯à¥à¤—à¤¾à¤¨à¥à¤¤à¤°à¥‹à¤‚-à¤œà¤¨à¥à¤®à¤¾à¤¨à¥à¤¤à¤°à¥‹à¤‚à¤•à¥‡ à¤¸à¥à¤¦à¥€à¤°à¥à¤˜à¤•à¤¾à¤²à¥€à¤¨ à¤…à¤¨à¥à¤¤à¤°à¤•à¥‹ à¤­à¥à¤²à¤¾à¤•à¤° à¤šà¤¿à¤° à¤°à¥à¤šà¤¿à¤° à¤šà¤¾à¤°à¥à¤¨à¤¿à¤§à¤¿ à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¸à¥‡ à¤¹à¤®à¥‡à¤‚ à¤®à¤¿à¤²à¤¨à¥‡ à¤²à¤¾à¤²à¤¾à¤¸à¤¾à¤¨à¥à¤µà¤¿à¤¤ à¤•à¤°à¤¤à¥€ à¤¹à¥‹, à¤à¤¸à¥€ à¤¹à¥ˆ à¤¯à¤¹ à¤…à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤°à¤¸à¤¸à¥à¤§à¤¾à¤µà¤°à¥à¤·à¤¿à¤£à¥€-à¤µà¤šà¤¨à¤ªà¥à¤·à¥à¤ªà¤®à¤¾à¤²à¤¾ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®'à¥¤ à¤¹à¤®à¥‡à¤‚ à¤­à¥€ à¤®à¤¹à¤¾à¤ªà¥à¤°à¥à¤·à¥‹à¤‚à¤•à¥€ à¤µà¤¾à¤£à¥€à¤®à¥‡à¤‚, à¤šà¤°à¤£à¤šà¤¿à¤¹à¥à¤¨à¤®à¥‡à¤‚ à¤—à¤®à¤¨ à¤•à¤°à¤¨à¤¾ à¤¹à¥ˆ à¤µà¤¹à¥€à¤‚, à¤œà¤¹à¤¾à¤ à¤µà¥‡ à¤ªà¤¹à¥à¤à¤šà¤¨à¥‡à¤•à¤¾ à¤¸à¤‚à¤•à¥‡à¤¤ à¤•à¤°à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤µà¤¹à¥€ à¤‰à¤¨à¥à¤®à¥à¤– à¤—à¤®à¤¨ à¤•à¤°à¤¨à¤¾ à¤¹à¥ˆà¥¤ à¤¹à¤®à¥‡à¤‚ à¤­à¥€ à¤µà¤¾à¤£à¥€à¤•à¥‹ à¤²à¥‡à¤•à¤° à¤µà¤¹à¥€à¤‚ à¤°à¤¹à¤¨à¤¾ à¤¹à¥ˆà¥¤
''',
      );
    } else if (sectionId == 'topic2' && title == 'à¤¶à¥à¤°à¥€à¤®à¤¤à¥€ à¤¸à¤¾à¤µà¤¿à¤¤à¥à¤°à¥€à¤¦à¥‡à¤µà¥€ à¤«à¥‹à¤—à¤²à¤¾') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''à¤¬à¤¾à¤¬à¤¾ à¤œà¥ˆà¤¸à¥‡ à¤¶à¤¾à¤°à¤¦à¤¾à¤•à¥‡ à¤µà¤°à¤¦ à¤ªà¥à¤¤à¥à¤°à¤•à¥‡ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿ à¤—à¥à¤°à¤¨à¥à¤¥ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤•à¤¾à¤µà¥à¤¯à¤•à¥‹ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤¹à¥€ à¤²à¤¿à¤ªà¤¿à¤¬à¤¦à¥à¤§ à¤•à¤¿à¤¯à¤¾ à¤¥à¤¾à¥¤ à¤­à¤¾à¤µà¥‹à¤¨à¥à¤®à¤¾à¤¦à¤•à¥€ à¤¦à¤¶à¤¾à¤®à¥‡à¤‚ à¤µà¥‡ à¤¬à¥‹à¤²à¤¤à¥‡ à¤œà¤¾à¤¤à¥‡ à¤”à¤° à¤®à¥ˆà¤‚ à¤²à¤¿à¤–à¤¤à¥€ à¤°à¤¹à¤¤à¥€à¥¤ à¤…à¤¨à¥à¤¯à¤¾à¤¨à¥à¤¯ à¤­à¤¾à¤µà¤®à¤¯à¥€ à¤²à¥€à¤²à¤¾à¤à¤ à¤¤à¤¥à¤¾ à¤ªà¤¦à¥‹à¤‚à¤•à¥€ à¤¸à¤‚à¤°à¤šà¤¨à¤¾ à¤­à¥€ à¤ªà¤°à¥à¤¯à¤¾à¤ªà¥à¤¤ à¤¹à¥ˆ, à¤œà¤¿à¤¸à¥‡ à¤¸à¤®à¤à¤¨à¤¾ à¤®à¤¾à¤¨à¤µà¥€à¤¯ à¤µà¤¿à¤¦à¥à¤¯à¤¾-à¤•à¥Œà¤¶à¤²à¤•à¥‡ à¤¬à¥‚à¤¤à¥‡à¤•à¥€ à¤¬à¤¾à¤¤ à¤¨à¤¹à¥€à¤‚à¥¤
à¤¬à¤¾à¤¬à¤¾à¤•à¤¾ à¤¯à¤¹ à¤¸à¤¾à¤°à¤¾ à¤°à¤šà¤¨à¤¾-à¤¸à¤‚à¤¸à¤¾à¤° à¤‰à¤¨à¤•à¥‡ à¤®à¥Œà¤¨à¤¾à¤µà¤§à¤¿à¤•à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¤•à¤¾ à¤œà¤—à¤¤ à¤¹à¥ˆ, à¤‰à¤¨à¥à¤¹à¥€à¤‚ à¤¦à¥ƒà¤¶à¥à¤¯à¥‹à¤‚à¤•à¥‹ à¤¯à¤¥à¤¾à¤µà¤¤ à¤šà¤¿à¤¤à¥à¤°à¤¿à¤¤ à¤•à¤¿à¤¯à¤¾ à¤¹à¥ˆ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡à¥¤ à¤ªà¤°à¤¨à¥à¤¤à¥ à¤‡à¤¸ à¤…à¤ªà¤¨à¥€ à¤œà¥€à¤µà¤¨-à¤§à¤¾à¤°à¤¾à¤•à¥‹ à¤†à¤¤à¥à¤¯à¤¨à¥à¤¤à¤¿à¤• à¤¸à¥à¤—à¥à¤ªà¥à¤¤ à¤°à¤–à¤¨à¤¾ à¤…à¤­à¤¿à¤ªà¥à¤°à¥‡à¤¤ à¤¥à¤¾ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹, à¤”à¤° à¤¤à¤¦à¤¨à¥à¤°à¥‚à¤ª à¤¹à¥€ à¤†à¤¦à¥‡à¤¶ à¤¥à¤¾ à¤®à¥à¤à¥‡à¥¤ à¤ªà¤¾à¤¨à¥€ à¤ªà¤¿à¤²à¤¾à¤¨à¥‡ à¤œà¤¬ à¤®à¥ˆà¤‚ à¤œà¤¾à¤¤à¥€ à¤¥à¥€, à¤‰à¤¸ à¤¸à¤®à¤¯ à¤µà¤¸à¥à¤¤à¥à¤°à¥‹à¤‚à¤®à¥‡à¤‚ à¤›à¤¿à¤ªà¤¾à¤•à¤° à¤›à¥‹à¤Ÿà¥€ à¤ªà¤¤à¤²à¥€ à¤¸à¥€ à¤•à¥‰à¤ªà¥€ à¤¸à¤¾à¤¥ à¤²à¥‡ à¤œà¤¾à¤¤à¥€, à¤”à¤° à¤µà¤¾à¤ªà¤¸ à¤µà¥ˆà¤¸à¥‡ à¤¹à¥€ à¤›à¤¿à¤ªà¤¾à¤ à¤²à¥‡ à¤†à¤¤à¥€à¥¤ à¤µà¤°à¥à¤·à¥‹à¤‚ à¤¤à¤• à¤®à¥‡à¤°à¥‡ à¤ªà¤°à¤¿à¤µà¤¾à¤°à¤®à¥‡à¤‚ à¤­à¥€ à¤•à¤¿à¤¸à¥€à¤•à¥‹ à¤¯à¤¹ à¤­à¤¨à¤• à¤¤à¤• à¤¨ à¤²à¤—à¥€ à¤•à¤¿ à¤ªà¤¾à¤¨à¥€ à¤ªà¥€à¤¤à¥‡-à¤ªà¤¿à¤²à¤¾à¤¤à¥‡ à¤¸à¤®à¤¯ à¤•à¥ˆà¤¸à¥€ à¤…à¤¨à¤¿à¤°à¥à¤µà¤šà¤¨à¥€à¤¯ à¤°à¤¸-à¤šà¤°à¥à¤šà¤¾ à¤šà¤² à¤°à¤¹à¥€ à¤¹à¥ˆ, à¤”à¤° à¤‰à¤¸à¥‡ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¬à¤¦à¥à¤§ à¤•à¤°à¤µà¤¾à¤•à¤° à¤µà¤¿à¤¶à¥à¤µ-à¤®à¤¨à¥€à¤·à¤¾ à¤à¤µà¤‚ à¤…à¤§à¥à¤¯à¤¾à¤¤à¥à¤® à¤œà¤—à¤¤à¤•à¥‹ à¤•à¥ˆà¤¸à¤¾ à¤…à¤ªà¥à¤°à¤¤à¤¿à¤® à¤‰à¤ªà¤¹à¤¾à¤° à¤¦à¥‡ à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚ à¤¬à¤¾à¤¬à¤¾à¥¤ à¤ªà¥à¤°à¤¤à¤¿à¤­à¤¾à¤•à¥‡ à¤§à¤¨à¥€ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤­à¤¾à¤·à¤¾-à¤¶à¥ˆà¤²à¥€, à¤‰à¤¸à¤•à¥€ à¤°à¤¸à¤®à¤¯à¤¤à¤¾, à¤ªà¥à¤°à¤­à¤¾à¤µà¥‹à¤¤à¥à¤ªà¤¾à¤¦à¤•à¤¤à¤¾ à¤¸à¤¬ à¤…à¤¨à¥‚à¤ à¥€ à¤¥à¥€à¥¤ à¤à¤•à¤¬à¤¾à¤° à¤‰à¤¸ à¤¦à¤¿à¤¶à¤¾à¤®à¥‡à¤‚ à¤‰à¤¨à¥à¤®à¥à¤– à¤¹à¥‹ à¤†à¤°à¤®à¥à¤­ à¤•à¤°à¤¤à¥‡ à¤¹à¥€, à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤…à¤ªà¥à¤°à¤¤à¤¿à¤® à¤ªà¥à¤°à¤µà¤¾à¤¹ à¤šà¤² à¤ªà¤¡à¤¼à¤¤à¤¾ à¤”à¤° à¤¶à¤¬à¥à¤¦à¥‹à¤‚à¤•à¥‡ à¤šà¤¿à¤¤à¥à¤° à¤¸à¤¾à¤®à¤¨à¥‡ à¤†à¤•à¤° à¤–à¤¡à¤¼à¥‡ à¤¹à¥‹ à¤œà¤¾à¤¤à¥‡à¥¤ à¤®à¤¨à¥à¤¤à¥à¤°à¤®à¥à¤—à¥à¤§à¤¸à¤¾ à¤ªà¤¾à¤ à¤• à¤…à¤¨à¤¾à¤¯à¤¾à¤¸ à¤¡à¥‚à¤¬à¤¤à¤¾ à¤šà¤²à¤¾ à¤œà¤¾à¤¤à¤¾ à¤‰à¤¸à¤®à¥‡à¤‚à¥¤ à¤®à¥ˆà¤‚ à¤¤à¥‹ à¤¸à¥à¤µà¤¯à¤‚ à¤¯à¤¨à¥à¤¤à¥à¤°à¤µà¤¤ à¤²à¤¿à¤–à¤¤à¥€ à¤šà¤²à¥€ à¤œà¤¾à¤¤à¥€à¥¤ à¤•à¥ˆà¤¸à¥‡, à¤•à¥à¤¯à¤¾, à¤•à¥Œà¤¨ à¤²à¤¿à¤–à¤µà¤¾à¤¤à¤¾ à¤¥à¤¾- à¤®à¥à¤à¥‡ à¤•à¥à¤› à¤œà¥à¤žà¤¾à¤¨ à¤¨à¤¹à¥€à¤‚à¥¤ à¤…à¤¨à¥‡à¤• à¤¬à¤¾à¤° à¤¤à¥‹ à¤à¤¸à¤¾ à¤­à¥€ à¤¹à¥à¤† à¤œà¤¬ à¤®à¥‡à¤°à¥€ à¤”à¤° à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤¹à¤¸à¥à¤¤à¤²à¤¿à¤ªà¤¿-à¤›à¤µà¤¿à¤²à¤¿à¤ªà¤¿-à¤¸à¥€ à¤ªà¥à¤°à¤¤à¥€à¤¤ à¤¹à¥‹à¤¨à¥‡ à¤²à¤—à¥€à¥¤ à¤¬à¤¾à¤¬à¤¾ à¤”à¤° à¤®à¥ˆà¤‚-à¤¹à¤® à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¹à¥€ à¤­à¥à¤°à¤®à¤¿à¤¤ à¤¹à¥‹ à¤œà¤¾à¤¤à¥‡ à¤¥à¥‡ à¤•à¤¿ à¤¯à¤¹ à¤²à¤¿à¤–à¤¾à¤µà¤Ÿ à¤•à¤¿à¤¸à¤•à¥€ à¤¹à¥ˆ ? à¤†à¤¨à¤¨à¥à¤¦ à¤”à¤° à¤°à¤¸à¤•à¥‡ à¤†à¤µà¤°à¥à¤¤à¥‹à¤‚à¤•à¥‡ à¤®à¤§à¥à¤¯ à¤¸à¥ƒà¤œà¤¨ à¤¹à¥‹à¤¤à¤¾ à¤°à¤¹à¤¤à¤¾, à¤‡à¤¸ à¤°à¤¸-à¤¸à¥ƒà¤·à¥à¤Ÿà¤¿à¤•à¤¾à¥¤
à¤‰à¤°à¥à¤¦à¥‚, à¤¹à¤¿à¤¨à¥à¤¦à¥€, à¤µà¥à¤°à¤œà¤­à¤¾à¤·à¤¾ - à¤¤à¥€à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤°à¤šà¤¨à¤¾à¤•à¥€, à¤”à¤° à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤†à¤²à¥‡à¤– à¤¸à¥à¤µà¤¯à¤‚à¤®à¥‡à¤‚ à¤ªà¥‚à¤°à¥à¤£à¤¤à¤¾à¤•à¥‹ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤¥à¤¾â€¦ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤•à¥‹à¤¶ à¤¥à¤¾à¥¤ à¤—à¤¦à¥à¤¯à¤®à¥‡à¤‚ à¤­à¥€ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤ªà¤°à¥à¤¯à¤¾à¤ªà¥à¤¤ à¤²à¥€à¤²à¤¾à¤à¤ à¤²à¤¿à¤–à¤µà¤¾à¤ˆà¤‚â€¦. à¤ªà¤°à¤¨à¥à¤¤à¥ à¤‰à¤¨à¥à¤¹à¥‡ à¤ªà¥à¤°à¤•à¤¾à¤¶à¤®à¥‡à¤‚ à¤²à¤¾à¤¨à¤¾ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤µà¤¾à¤‚à¤›à¤¨à¥€à¤¯ à¤¨à¤¹à¥€à¤‚ à¤¥à¤¾à¥¤ à¤…à¤¤à¤ƒ à¤¸à¤¾à¤°à¥€ à¤šà¥€à¤œà¥‡à¤‚ à¤à¤• à¤¸à¤¾à¤¥ à¤ªà¥à¤°à¤•à¤¾à¤¶à¤®à¥‡à¤‚ à¤¨à¤¹à¥€à¤‚ à¤†à¤ˆà¤‚à¥¤ à¤…à¤¨à¥à¤¯ à¤ªà¤°à¤¿à¤ªà¤¤à¥à¤°à¥‹à¤‚à¤•à¥‡ à¤¸à¤¾à¤¥, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤šà¤¾à¤° à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥‡ à¤†à¤§à¤¾à¤°à¤ªà¤° à¤­à¥€ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤°à¤¾à¤§à¤¾à¤¸à¥‡ à¤ªà¤°à¤¿à¤ªà¤¤à¥à¤° à¤²à¤¿à¤–à¤µà¤¾à¤à¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤­à¤¾à¤·à¤¾à¤•à¤¾ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤²à¥‡à¤–à¤¨à¥€à¤®à¥‡à¤‚ à¤¸à¥à¤ªà¤·à¥à¤Ÿ à¤¹à¥ˆà¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¥‹ à¤—à¥à¤°à¤¹à¤£ à¤•à¤°à¤¨à¥‡à¤•à¥€ à¤•à¥à¤·à¤®à¤¤à¤¾ à¤‰à¤¸à¥‡ à¤ªà¥à¤°à¤­à¥à¤¨à¥‡ à¤ªà¥à¤°à¤¦à¤¾à¤¨ à¤•à¥€ à¤¥à¥€ à¤”à¤° à¤…à¤¨à¥‡à¤• à¤¬à¤¾à¤° à¤¬à¤¾à¤¬à¤¾ à¤‰à¤¸à¥‡ à¤•à¤¹à¤¾ à¤•à¤°à¤¤à¥‡ à¤¥à¥‡- â€œà¤¬à¤¿à¤Ÿà¤¿à¤¯à¤¾, à¤œà¤¬ à¤¬à¤›à¤¡à¤¼à¤¾ à¤—à¤¾à¤¯à¤•à¥‡ à¤¥à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤®à¥à¤à¤¹ à¤²à¤—à¤¾à¤¤à¤¾ à¤¹à¥ˆ, à¤¤à¤¬ à¤ªà¤¿à¤¨à¥à¤¹à¤¾à¤•à¤° à¤—à¤¾à¤¯ à¤¦à¥‚à¤§ à¤¦à¥‡à¤¨à¥‡ à¤²à¤—à¤¤à¥€ à¤¹à¥ˆ - à¤…à¤¨à¤¾à¤¯à¤¾à¤¸ à¤‰à¤¸à¤•à¥‡ à¤¥à¤¨à¥‹à¤‚à¤¸à¥‡ à¤¦à¥‚à¤§à¤•à¥€ à¤§à¤¾à¤°à¤¾ à¤¬à¤¹ à¤šà¤²à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤ à¥€à¤• à¤µà¥ˆà¤¸à¥€ à¤¹à¥€ à¤¦à¤¶à¤¾ à¤®à¥‡à¤°à¥€ à¤¹à¥ˆ, à¤¤à¥‡à¤°à¥€ à¤—à¥à¤°à¤¾à¤¹à¤•à¤¤à¤¾à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤®à¥ˆà¤‚ à¤¸à¥à¤µà¤¯à¤‚ à¤‰à¤¸à¥€ à¤­à¤¾à¤µà¤®à¥‡à¤‚ à¤¬à¤¹à¤¨à¥‡ à¤²à¤—à¤¤à¤¾ à¤¹à¥‚à¤ à¤”à¤° à¤šà¤² à¤ªà¤¡à¤¼à¤¤à¤¾ à¤¹à¥ˆ à¤°à¤¸à¤•à¤¾ à¤ªà¥à¤°à¤µà¤¾à¤¹ à¥¤â€
''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'à¤ªà¤°à¤® à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤¸à¤¾à¤§à¥à¤•à¥ƒà¤·à¥à¤£ à¤ªà¥à¤°à¥‡à¤® à¤œà¥€') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤°à¥‚à¤ªà¤¾ à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤‰à¤¦à¥à¤—à¤¾à¤¤à¤¾ à¤‹à¤·à¤¿ à¤¥à¥‡ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾, à¤”à¤° à¤¶à¥à¤°à¥‹à¤¤à¤¾ à¤¥à¥‡ à¤‰à¤¨à¤•à¥‡ à¤­à¥€ à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤¹à¤¨à¥à¤®à¤¾à¤¨à¤ªà¥à¤°à¤¸à¤¾à¤¦à¤œà¥€ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¥¤ à¤¯à¤¹ à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¸à¥Œ à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤›à¤¨à¥à¤¦à¥‹à¤‚à¤•à¤¾ à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤•à¥‹à¤‚à¤®à¥‡ à¤µà¤¿à¤­à¤¾à¤œà¤¿à¤¤ à¤•à¤¾à¤µà¥à¤¯ à¤²à¥‡à¤–à¤¨à¥€à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤®à¤¸à¥‡ à¤¤à¥‹ à¤²à¤¿à¤–à¤¾ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤—à¤¯à¤¾à¥¤ à¤¯à¤¹ à¤¤à¥‹ à¤®à¤¾à¤¤à¥à¤° à¤…à¤µà¤¤à¤°à¤¿à¤¤ à¤¹à¥à¤† à¤¥à¤¾ - à¤›à¤¨à¥à¤¦à¥‹à¤‚à¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤ƒà¤•à¤°à¤£à¤®à¥‡à¤‚ à¤”à¤° à¤‰à¤¨à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¹à¥€ à¤‡à¤¸à¥‡ à¤¸à¥à¤¨à¤¾à¤¯à¤¾ à¤—à¤¯à¤¾ à¤¥à¤¾ à¤¶à¥à¤°à¥€à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¥‹à¥¤ à¤¹à¤¾à¤, à¤œà¤¬ à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨ à¤¨à¥€à¤²à¤®à¤£à¤¿à¤•à¥€ à¤‡à¤šà¥à¤›à¤¾à¤¸à¥‡ à¤¹à¥€ -

à¤à¤• à¤¦à¥à¤µà¤¾à¤° à¤°à¤–à¤¿  à¤•à¥à¤à¤…à¤°à¤¿  à¤¨à¥‡  à¤²à¥€à¤¨à¥€  à¤ªà¥ˆà¤   à¤‰à¤ à¤¾à¤¯à¥¤
à¤°à¥à¤šà¥ˆ à¤œà¥‹ à¤°à¤‚à¤šà¤• à¤•à¥€à¤¨à¥ à¤ªà¤¿à¤¯, à¤¬à¤¹à¤¿à¤¨à¥€, à¤­à¥ˆà¤¯à¤¾, à¤®à¤¾à¤¯à¥¤à¥¤

à¤•à¥à¤à¤…à¤°à¤¿ à¤°à¤¾à¤§à¤¾à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤ªà¥à¤°à¥€à¤¤à¤¿-à¤µà¤¿à¤¤à¤°à¤£à¤•à¥€ à¤ªà¥ˆà¤  à¤‰à¤ à¤¾ à¤¹à¥€ à¤²à¥€, à¤®à¤¾à¤¤à¥à¤° à¤à¤• à¤¦à¥à¤µà¤¾à¤°- à¤…. à¤¸à¥Œ. à¤¸à¤¾à¤µà¤¿à¤¤à¥à¤°à¥€à¤¬à¤¾à¤ˆ à¤«à¥‹à¤—à¤²à¤¾ (à¤¸à¥à¤ªà¥à¤¤à¥à¤°à¥€ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œ) à¤•à¥‹ à¤¹à¥€ à¤¨à¤¿à¤°à¥à¤§à¤¾à¤°à¤¿à¤¤ à¤•à¤° à¤¦à¤¿à¤¯à¤¾à¥¤ à¤‰à¤¸ à¤¸à¤®à¤¯ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤¹à¥€ à¤…à¤ªà¤¨à¥‡ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨à¤•à¥‡ à¤‡à¤¸ à¤•à¤¾à¤µà¥à¤¯à¤•à¥‹ à¤¬à¥‹à¤²-à¤¬à¥‹à¤²à¤•à¤° à¤ªà¥‚à¤œà¥à¤¯à¤¾ à¤….à¤¸à¥Œ. à¤¬à¤¾à¤ˆ à¤¸à¤¾à¤µà¤¿à¤¤à¥à¤°à¥€à¤•à¥‹ à¤¯à¤¹ 'à¤°à¤¸à¤¶à¥à¤°à¥à¤¤à¤¿' à¤ªà¥à¤°à¤¦à¤¾à¤¨ à¤•à¤° à¤¦à¥€à¥¤ à¤•à¥à¤› à¤•à¥ƒà¤ªà¤¾à¤ªà¤¾à¤¤à¥à¤°à¥‹à¤‚à¤•à¥‹, à¤œà¤¿à¤¨à¤®à¥‡à¤‚ à¤à¤• à¤²à¥‡à¤–à¤• à¤­à¥€ à¤°à¤¹à¤¾, à¤ªà¥‚.à¤….à¤¸à¥Œ. à¤¸à¤¾à¤µà¤¿à¤¤à¥à¤°à¥€à¤¬à¤¾à¤ˆà¤¨à¥‡ à¤¹à¥€ à¤¯à¤¹ à¤¶à¥à¤°à¥à¤¤à¤¿à¤—à¥à¤°à¤¨à¥à¤¥ à¤•à¥ƒà¤ªà¤¾à¤ªà¤°à¤µà¤¶ à¤ªà¥à¤°à¤¦à¤¾à¤¨ à¤•à¤° à¤¦à¤¿à¤¯à¤¾à¥¤ 
à¤‡à¤¸à¤®à¥‡à¤‚ à¤•à¤¹à¥€à¤‚ à¤•à¥‹à¤ˆ à¤¸à¤‚à¤¶à¤¯ à¤¨à¤¹à¥€à¤‚ à¤•à¤¿ à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤¨à¤¾à¤¯à¤• à¤¨à¤¾à¤¯à¤¿à¤•à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨ à¤¨à¥€à¤²à¤¸à¥à¤¨à¥à¤¦à¤° à¤à¤µà¤‚ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤¨à¤¨à¥à¤¦à¤¿à¤¨à¥€ à¤¬à¤¾à¤²à¤¾ à¤°à¤¾à¤§à¤¾ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¨ à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¥‡ à¤®à¤¾à¤¤à¤¾-à¤ªà¤¿à¤¤à¤¾, à¤ªà¤¿à¤¤à¤¾à¤®à¤¹, à¤¤à¤¾à¤Š-à¤šà¤¾à¤šà¤¾, à¤­à¤¾à¤ˆ-à¤¬à¤¹à¤¿à¤¨, à¤¸à¤–à¤¾ à¤à¤µà¤‚ à¤¸à¤–à¥€à¤—à¤£, à¤‡à¤¨à¤•à¥‡ à¤ªà¤¿à¤¤à¥ƒà¤•à¥à¤², à¤®à¤¾à¤¤à¥ƒà¤•à¥à¤² à¤à¤µà¤‚ à¤¶à¥à¤µà¤¸à¥à¤°à¤¾à¤²à¤¯à¤•à¥‡ à¤­à¥€ à¤¸à¤­à¥€ à¤ªà¤¾à¤¤à¥à¤°, à¤‰à¤¨à¤•à¥‡ à¤¦à¥‡à¤¹à¤¾à¤¦à¤¿ à¤®à¤¾à¤¯à¤¾à¤•à¥‡ à¤•à¤¾à¤°à¥à¤¯, à¤ªà¤žà¥à¤šà¤®à¤¹à¤¾à¤­à¥‚à¤¤à¥‹à¤‚à¤®à¥‡à¤‚ à¤¨à¤¿à¤°à¥à¤®à¤¿à¤¤ à¤®à¤¾à¤¯à¤¾-à¤†à¤µà¤°à¤£à¤°à¥‚à¤ª à¤•à¤¦à¤¾à¤ªà¤¿ à¤•à¤¦à¤¾à¤ªà¤¿ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¸ à¤°à¤¸à¤¶à¥à¤°à¥à¤¤à¤¿à¤®à¥‡à¤‚ à¤µà¤°à¥à¤£à¤¿à¤¤ à¤²à¥€à¤²à¤¾à¤à¤ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤¹à¥ˆà¤‚ à¤œà¥‹ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤•à¥à¤·à¥‡à¤¤à¥à¤°, à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤•à¤¾à¤¨à¤¨, à¤¶à¥à¤°à¥€à¤¸à¥à¤¨à¥à¤¦à¤°à¥€à¤µà¤¨à¤•à¥‡ à¤¨à¤¿à¤•à¥à¤žà¥à¤œà¤“à¤‚, à¤à¤µà¤‚ à¤¬à¥à¤°à¤œà¤•à¥‡ à¤—à¥à¤°à¤¾à¤®à¥‹à¤‚à¤®à¥‡à¤‚ à¤˜à¤Ÿà¤¿à¤¤ à¤¹à¥à¤ˆ à¤¹à¥ˆà¤‚ à¤à¤µà¤‚ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤®à¤¨-à¤¬à¥à¤¦à¥à¤§à¤¿ à¤à¤µà¤‚ à¤¶à¤°à¥€à¤°à¤§à¤¾à¤°à¥€ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤ªà¤¾à¤¤à¥à¤°à¥‹à¤‚à¤•à¥€ à¤²à¥€à¤²à¤¾à¤à¤ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¸à¥€à¤²à¤¿à¤¯à¥‡ à¤‡à¤¸ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤•à¤¾à¤µà¥à¤¯à¤•à¤¾ à¤¶à¤¬à¥à¤¦-à¤¶à¤¬à¥à¤¦ à¤®à¤‚à¤¤à¥à¤° à¤¹à¥ˆ à¤à¤µà¤‚ à¤‡à¤¨ à¤®à¤‚à¤¤à¥à¤°à¥‹à¤‚à¤•à¥‡ à¤œà¤¾à¤ªà¤¸à¥‡ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤®à¤¨-à¤¬à¥à¤¦à¥à¤§à¤¿à¤•à¤¾ à¤¨à¤¿à¤°à¥à¤®à¤¾à¤£ à¤¸à¤‚à¤­à¤µ à¤¹à¥ˆà¥¤ à¤¯à¤¹à¥€ à¤‡à¤¸ à¤—à¥à¤°à¤¨à¥à¤¥à¤•à¤¾ à¤…à¤ªà¥‚à¤°à¥à¤µ à¤®à¤¾à¤¹à¤¾à¤¤à¥à¤®à¥à¤¯ à¤¹à¥ˆà¥¤
à¤¸à¤°à¥à¤µà¤ªà¥à¤°à¤¥à¤® à¤œà¤¬ à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤°à¤šà¤¨à¤¾à¤•à¤¾ à¤ªà¥à¤°à¤¥à¤® à¤›à¤¨à¥à¤¦ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤ƒà¤•à¤°à¤£à¤®à¥‡à¤‚ à¤…à¤µà¤¤à¤°à¤¿à¤¤ à¤¹à¥à¤† à¤à¤µà¤‚ à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤¯à¤¹ à¤­à¤¾à¤¸à¤¿à¤¤ à¤¹à¥‹à¤¨à¥‡ à¤²à¤—à¤¾ à¤®à¤¾à¤¨à¥‹ à¤‰à¤¨à¤•à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤‰à¤¨à¤¸à¥‡ à¤‰à¤¨à¤•à¥‡ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨à¤•à¥‹ à¤•à¤¾à¤µà¥à¤¯à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤•à¤Ÿ à¤•à¤°à¤¾à¤¨à¤¾ à¤šà¤¾à¤¹ à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚, à¤à¤µà¤‚ à¤¯à¤¹ à¤°à¤šà¤¨à¤¾ à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤•à¥‹à¤‚à¤®à¥‡à¤‚ à¤•à¥à¤°à¤®à¤¶à¤ƒ à¤ªà¥à¤°à¤¸à¥‚à¤¤ à¤¹à¥‹ à¤°à¤¹à¥€ à¤¹à¥ˆ, à¤‰à¤¸ à¤¸à¤®à¤¯ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨à¤¸à¥‡ à¤¯à¤¹à¥€ à¤µà¤¿à¤¨à¤¯ à¤•à¥€ à¤¥à¥€ à¤•à¤¿ 'à¤œà¤¬ à¤­à¥‚à¤¤à¤•à¤¾à¤²à¤•à¥‡ à¤…à¤¨à¥‡à¤•à¥‹à¤‚ à¤®à¤¹à¤¾à¤¸à¤¿à¤¦à¥à¤§ à¤°à¤¸à¤¿à¤•à¤¾à¤šà¤¾à¤°à¥à¤¯à¥‹à¤‚à¤•à¥€ à¤…à¤¨à¥‡à¤•à¥‹à¤‚ à¤µà¤¾à¤£à¤¿à¤¯à¤¾à¤ à¤µà¤°à¥à¤¤à¥à¤¤à¤®à¤¾à¤¨à¤®à¥‡à¤‚ à¤‰à¤ªà¤²à¤¬à¥à¤§ à¤¹à¥ˆà¤‚ à¤à¤µà¤‚ à¤¸à¤¾à¤¹à¤¿à¤¤à¥à¤¯à¤•à¥‡ à¤‰à¤¤à¥à¤•à¥ƒà¤·à¥à¤Ÿà¤¤à¤® à¤ªà¥à¤°à¤¯à¥‹à¤—à¥‹à¤‚ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤°à¤¾à¤§à¤¾à¤•à¥ƒà¤·à¥à¤£à¤•à¤¥à¤¾à¤•à¥‡ à¤¸à¤­à¥€ à¤ªà¤•à¥à¤· à¤…à¤·à¥à¤Ÿà¤›à¤¾à¤ªà¤•à¥‡ à¤¸à¥‚à¤°à¤¦à¤¾à¤¸, à¤¨à¤¨à¥à¤¦à¤¦à¤¾à¤¸à¤¾à¤¦à¤¿ à¤¤à¤¥à¤¾ à¤‡à¤¤à¤° à¤•à¤µà¤¿à¤¯à¥‹à¤‚ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤­à¥€ à¤ªà¥à¤°à¤šà¥à¤°à¤¤à¤¾à¤¸à¥‡, à¤µà¤°à¥à¤£à¤¿à¤¤ à¤•à¤¿à¤¯à¥‡ à¤œà¤¾ à¤šà¥à¤•à¥‡ à¤¹à¥ˆà¤‚, à¤«à¤¿à¤° à¤®à¥‡à¤°à¥‡-à¤œà¥ˆà¤¸à¥‡ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤¸à¥‡ à¤¯à¤¹ à¤ªà¤¿à¤·à¥à¤Ÿ-à¤ªà¥‡à¤·à¤£ à¤•à¤°à¤¾à¤¨à¥‡à¤•à¥€ à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾ à¤¹à¥€ à¤•à¥à¤¯à¤¾ à¤¹à¥ˆ ? à¤¯à¤¦à¤¿ à¤ªà¥‚à¤°à¥à¤µà¤•à¥‡ à¤‡à¤¨ à¤¸à¤­à¥€ à¤°à¤¸à¤¿à¤•à¤¾à¤šà¤¾à¤°à¥à¤¯à¥‹à¤‚ à¤à¤µà¤‚ à¤•à¤µà¤¿à¤¯à¥‹à¤‚à¤¸à¥‡ à¤®à¥‡à¤°à¥€ à¤¯à¤¹ à¤°à¤šà¤¨à¤¾ à¤•à¥à¤› à¤…à¤ªà¥‚à¤°à¥à¤µ à¤¸à¤¿à¤¦à¥à¤§ à¤¹à¥‹, à¤¤à¤¬ à¤¤à¥‹ à¤‡à¤¸à¤•à¥€ à¤¸à¤¾à¤°à¥à¤¥à¤•à¤¤à¤¾ à¤¹à¥ˆ, à¤…à¤¨à¥à¤¯à¤¥à¤¾ à¤¯à¤¹ à¤•à¥à¤°à¤¿à¤¯à¤¾ à¤šà¤°à¥à¤µà¤¿à¤¤à¤•à¤¾ à¤šà¤°à¥à¤µà¤£ à¤®à¤¾à¤¤à¥à¤° à¤¹à¥€ à¤¤à¥‹ à¤¹à¥‹à¤—à¥€ ?'
à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‡ à¤‡à¤¸ à¤¨à¤¿à¤µà¥‡à¤¦à¤¨à¤•à¥‡ à¤‰à¤¤à¥à¤¤à¤°à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤®à¥à¤¸à¤•à¤¾à¤•à¤° à¤‰à¤¨à¤¸à¥‡ à¤‡à¤¤à¤¨à¤¾ à¤¹à¥€ à¤•à¤¹à¤¾ 'à¤¤à¥‚ à¤‡à¤¸à¥‡ à¤ªà¥à¤°à¤•à¤Ÿ à¤¤à¥‹ à¤•à¤° ! à¤¤à¥‡à¤°à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤ªà¥à¤°à¤•à¤Ÿ à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤•à¤¾ à¤®à¤¾à¤¹à¤¾à¤¤à¥à¤®à¥à¤¯ à¤‰à¤¨ à¤¸à¤­à¥€ à¤•à¥ƒà¤¤à¤¿à¤¯à¥‹à¤‚à¤¸à¥‡ à¤…à¤ªà¥‚à¤°à¥à¤µ à¤¹à¥€ à¤¹à¥‹à¤—à¤¾à¥¤ à¤‡à¤¸ à¤˜à¥‹à¤° à¤•à¤²à¤¿à¤•à¤¾à¤²à¤®à¥‡à¤‚ à¤µà¤¿à¤¶à¥à¤¦à¥à¤§ à¤­à¤¾à¤—à¤µà¤¤à¥€ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¥€ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¯à¥‡ à¤¤à¥‡à¤°à¥‡ à¤¶à¥à¤°à¥à¤¤à¤¿à¤›à¤¨à¥à¤¦ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤¨à¥‡à¤¤à¥à¤°, à¤•à¤°à¥à¤£, à¤µà¤¾à¤£à¥€, à¤®à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤¤à¤ƒà¤•à¤°à¤£à¤•à¥‡ à¤¨à¤¿à¤°à¥à¤®à¤¾à¤£à¤®à¥‡à¤‚ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤¹à¥‡à¤¤à¥ à¤¹à¥‹à¤‚à¤—à¥‡à¥¤ à¤¯à¤¹ à¤¶à¥à¤°à¥à¤¤à¤¿ à¤•à¤¾à¤²à¤œà¤¯à¥€ à¤¸à¤¿à¤¦à¥à¤§ à¤¹à¥‹à¤—à¥€ à¤à¤µà¤‚ à¤­à¤µà¤¿à¤·à¥à¤¯à¤®à¥‡à¤‚ à¤ªà¤šà¥à¤šà¥€à¤¸ à¤¸à¥Œ à¤µà¤°à¥à¤·à¥‹à¤‚ à¤¤à¤• à¤‡à¤¸à¤•à¤¾ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤¸à¥à¤¥à¤¾à¤¯à¥€ à¤°à¤¹à¥‡à¤—à¤¾à¥¤'
à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤‡à¤¸ à¤²à¥‡à¤–à¤• à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤µà¥à¤¯à¤•à¥à¤¤ à¤¯à¤¹ à¤ªà¥à¤°à¤¸à¤™à¥à¤— à¤•à¤¿à¤¨à¥à¤¹à¥€à¤‚ à¤®à¤¹à¤¾à¤¸à¤¿à¤¦à¥à¤§ à¤°à¤¸à¤¿à¤•à¤¾à¤šà¤¾à¤°à¥à¤¯à¥‹à¤‚à¤•à¥€ à¤•à¥ƒà¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥€ à¤¹à¥‡à¤ à¥€ à¤¸à¤¿à¤¦à¥à¤§ à¤•à¤°à¤¨à¥‡à¤•à¥‡ à¤¹à¥‡à¤¤à¥à¤¸à¥‡ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤‰à¤²à¥à¤²à¥‡à¤– à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾ à¤¹à¥ˆ, à¤¨ à¤¹à¥€ à¤¯à¤¹ à¤•à¤¿à¤¸à¥€ à¤®à¤¤à¤µà¤¿à¤¶à¥‡à¤·à¤ªà¤° à¤†à¤•à¥à¤·à¥‡à¤ª à¤¹à¥€ à¤¹à¥ˆà¥¤ à¤²à¥‡à¤–à¤•à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤—à¥à¤°à¥à¤®à¥à¤–à¤¸à¥‡ à¤œà¥‹ à¤­à¥€ à¤µà¤¾à¤£à¥€ à¤¸à¥à¤¨à¥€ à¤¹à¥ˆ, à¤¹à¥ƒà¤¦à¤¯à¤™à¥à¤—à¤® à¤•à¥€ à¤¹à¥ˆ, à¤‰à¤ªà¤°à¥‹à¤•à¥à¤¤ à¤¶à¤¬à¥à¤¦ à¤²à¥‡à¤–à¤•à¤•à¥€ à¤…à¤ªà¤¨à¥€ à¤¹à¥€ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤¶à¤ƒ à¤¨à¤¿à¤·à¥à¤ à¤¾ à¤à¤µà¤‚ à¤¶à¥à¤°à¤¦à¥à¤§à¤¾à¤•à¥‹ à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤ à¤•à¤° à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤²à¥‡à¤–à¤•à¤•à¤¾ à¤¯à¤¹ à¤†à¤—à¥à¤°à¤¹ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆ à¤•à¤¿ à¤‰à¤¸à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤²à¤¿à¤–à¥€ à¤¬à¤¾à¤¤à¥‹à¤‚à¤•à¥‹ à¤ªà¤¾à¤ à¤• à¤®à¤¾à¤¨ à¤¹à¥€ à¤²à¥‡à¤‚à¥¤ à¤¯à¤¹ à¤¤à¥‹ à¤®à¤¾à¤¤à¥à¤° à¤²à¥‡à¤–à¤•à¤•à¥‡ à¤¸à¥à¤µà¤¯à¤‚à¤•à¥‡ à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸à¤•à¥€ à¤¬à¤¾à¤¤ à¤¹à¥ˆ à¤”à¤° à¤²à¥‡à¤–à¤•à¤•à¤¾ à¤¤à¥‹ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤‡à¤¸ à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸à¤®à¥‡à¤‚ à¤¹à¥€ à¤•à¤²à¥à¤¯à¤¾à¤£ à¤¹à¥ˆà¥¤ à¤²à¥‡à¤–à¤• à¤†à¤—à¥à¤°à¤¹à¤ªà¥‚à¤°à¥à¤µà¤• à¤…à¤ªà¤¨à¤¾ à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸ à¤¦à¥‚à¤¸à¤°à¥‹à¤‚à¤ªà¤° à¤²à¤¾à¤¦à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤‰à¤ªà¤°à¥‹à¤•à¥à¤¤ à¤²à¥‡à¤–à¤¨ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¤° à¤°à¤¹à¤¾à¥¤
à¤²à¥‡à¤–à¤•à¤•à¥€ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤ªà¤¾à¤ à¤•à¤—à¤£ à¤‡à¤¸ à¤µà¤¿à¤·à¤¯à¤®à¥‡à¤‚ à¤¤à¤°à¥à¤•à¤¬à¥à¤¦à¥à¤§à¤¿à¤•à¤¾ à¤†à¤¶à¥à¤°à¤¯ à¤•à¤°à¤•à¥‡ à¤‰à¤¸à¤¸à¥‡ à¤ªà¥à¤°à¤¶à¥à¤¨à¥‹à¤¤à¥à¤¤à¤°à¤•à¥€ à¤†à¤¶à¤¾ à¤•à¥ƒà¤ªà¤¯à¤¾ à¤¨à¤¹à¥€à¤‚ à¤°à¤•à¥à¤–à¥‡à¤‚à¥¤ à¤µà¤¿à¤µà¤¾à¤¦à¤®à¥‡à¤‚ à¤¤à¥‹ à¤…à¤ªà¤¨à¥€ à¤¹à¤¾à¤° à¤µà¤¹ à¤ªà¤¹à¤²à¥‡ à¤¹à¥€ à¤¸à¥à¤µà¥€à¤•à¤¾à¤° à¤•à¤° à¤²à¥‡à¤¤à¤¾ à¤¹à¥ˆ à¤à¤µà¤‚ à¤¤à¤°à¥à¤• à¤•à¤°à¤¨à¤¾ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤šà¤¾à¤¹à¤¤à¤¾à¥¤ à¤…à¤µà¤¶à¥à¤¯ à¤¹à¥€ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤à¤µà¤‚ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤ªà¤° à¤‰à¤¸à¤•à¥€ à¤¸à¤°à¥à¤µà¥‹à¤ªà¤°à¤¿ à¤¨à¤¿à¤·à¥à¤ à¤¾, à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸, à¤¶à¥à¤°à¤¦à¥à¤§à¤¾ à¤•à¥à¤·à¤£-à¤•à¥à¤·à¤£ à¤¬à¤¢à¤¼à¤¤à¥€ à¤°à¤¹à¥‡ à¤”à¤° à¤‰à¤¨à¤•à¥‡à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤•à¤¥à¤¿à¤¤ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤¶à¤¬à¥à¤¦ à¤‰à¤¸à¥‡ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥ à¤ªà¤°à¤®à¤¾à¤¤à¥à¤®à¤¾à¤•à¥€ à¤µà¤¾à¤£à¥€ à¤¹à¥€ à¤…à¤¨à¥à¤­à¤µ à¤¹à¥‹, à¤…à¤¨à¥à¤¤à¤°à¥à¤¯à¤¾à¤®à¥€ à¤ªà¥à¤°à¤­à¥à¤¸à¥‡ à¤‰à¤¸à¤•à¥€ à¤°à¥‹à¤®-à¤°à¥‹à¤®à¤¸à¥‡ à¤¯à¤¹à¥€ à¤µà¤¿à¤¨à¥€à¤¤ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤¹à¥ˆà¥¤
à¤¸à¥à¤•à¤¨à¥à¤¦à¤ªà¥à¤°à¤¾à¤£à¤®à¥‡à¤‚ à¤‰à¤²à¥à¤²à¥‡à¤– à¤¹à¥ˆ 'à¤­à¤—à¤µà¤¾à¤¨à¥ à¤¶à¤¿à¤µ à¤ªà¤¾à¤°à¥à¤µà¤¤à¥€à¤œà¥€à¤¸à¥‡ à¤—à¥à¤°à¥à¤®à¤¹à¤¿à¤®à¤¾à¤•à¥‡ à¤µà¤¿à¤·à¤¯à¤®à¥‡à¤‚ à¤•à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚ 'à¤—à¥à¤°à¥à¤µà¤•à¥à¤¤à¥à¤°à¤¸à¥à¤¥à¤¿à¤¤à¤‚ à¤¬à¥à¤°à¤¹à¥à¤® à¤ªà¥à¤°à¤¾à¤ªà¥à¤¯à¤¤à¥‡ à¤¯à¤¤à¥à¤ªà¥à¤°à¤¸à¤¾à¤¦à¤¤à¤ƒ' à¤…à¤°à¥à¤¥à¤¾à¤¤à¥ 'à¤¹à¥‡ à¤ªà¤¾à¤°à¥à¤µà¤¤à¤¿ ! à¤—à¥à¤°à¥à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¨à¤¿à¤ƒà¤¸à¥ƒà¤¤ à¤µà¤¾à¤£à¥€ à¤¹à¥€ à¤ªà¤°à¤¾à¤¤à¥à¤ªà¤° à¤ªà¤°à¤¬à¥à¤°à¤¹à¥à¤® à¤ªà¤°à¤®à¤¾à¤¤à¥à¤®à¤¾ à¤¹à¥ˆ, à¤”à¤° à¤—à¥à¤°à¥à¤ªà¥à¤°à¤¸à¤¾à¤¦, à¤—à¥à¤°à¥à¤•à¥ƒà¤ªà¤¾ à¤¹à¥€ à¤‰à¤¸à¤•à¥€ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤à¤¿à¤•à¤¾ à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤•à¤¾à¤°à¤£ à¤¹à¥ˆà¥¤ à¤‡à¤¸ à¤¨à¤¿à¤·à¥à¤ à¤¾à¤•à¥‡ à¤ªà¥à¤°à¤¦à¥à¤¯à¥‹à¤¤à¤• à¤¹à¥€ à¤®à¥‡à¤°à¥‡ à¤‰à¤ªà¤°à¥‹à¤•à¥à¤¤ à¤¶à¤¬à¥à¤¦ à¤¹à¥ˆà¤‚à¥¤
à¤¯à¤¦à¤¿ à¤¯à¤¹ à¤®à¥‡à¤°à¥€ à¤¨à¤¿à¤·à¥à¤ à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¥€ à¤¤à¥‹ à¤°à¤¸à¤¿à¤•à¥‡à¤¨à¥à¤¦à¥à¤°à¤¶à¥‡à¤–à¤° à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨ à¤°à¤¸à¤°à¤¾à¤œ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤®à¥à¤ à¤œà¥ˆà¤¸à¥‡ à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤®à¤¨-à¤¬à¥à¤¦à¥à¤§à¤¿ à¤µà¤¾à¤²à¥‡ à¤ªà¤¾à¤®à¤° à¤ªà¥à¤°à¤¾à¤£à¥€à¤¸à¥‡ à¤œà¤¿à¤¸à¤¨à¥‡ à¤†à¤µà¤°à¤£à¤°à¥‚à¤ªà¤¾ à¤®à¤¾à¤¯à¤¾à¤®à¥‡à¤‚ à¤¹à¥€ à¤œà¤¨à¥à¤®à¤—à¥à¤°à¤¹à¤£ à¤•à¤¿à¤¯à¤¾ à¤¹à¥ˆ, à¤•à¤¦à¤¾à¤ªà¤¿ à¤‡à¤¸ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤­à¤¾à¤—à¤µà¤¤à¥€ à¤¶à¥à¤°à¥à¤¤à¤¿à¤—à¥à¤°à¤¨à¥à¤¥à¤•à¥€ à¤Ÿà¥€à¤•à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¤°à¤¾à¤¤à¥‡à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤®à¥à¤ à¤ªà¤¶à¥à¤•à¥‹ à¤‡à¤¸ à¤ªà¤¾à¤µà¤¨à¤¤à¤® à¤•à¤¾à¤°à¥à¤¯à¤®à¥‡à¤‚ à¤¹à¥‡à¤¤à¥ à¤¬à¤¨à¤¾à¤¯à¤¾, à¤‡à¤¸à¤•à¤¾ à¤¯à¤¦à¤¿ à¤•à¥‹à¤ˆ à¤ªà¥à¤°à¤•à¤Ÿ à¤•à¤¾à¤°à¤£ à¤¹à¥‹ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆ, à¤¤à¥‹ à¤¯à¤¹à¥€ à¤¹à¥ˆ à¤•à¤¿ à¤¨ à¤œà¤¾à¤¨à¥‡ à¤•à¤¿à¤¸ à¤ªà¥à¤£à¥à¤¯à¤¬à¤²à¤¸à¥‡ à¤®à¥‡à¤°à¥€ à¤¬à¥à¤¦à¥à¤§à¤¿ à¤¦à¤¿à¤µà¤¸-à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤µà¤¸, à¤•à¥à¤·à¤£-à¤ªà¥à¤°à¤¤à¤¿à¤•à¥à¤·à¤£ à¤‡à¤¸à¥€ à¤¨à¤¿à¤·à¥à¤ à¤¾à¤•à¥‹ à¤—à¥à¤°à¤¹à¤£ à¤•à¤° à¤°à¤¹à¥€ à¤¹à¥ˆ à¤•à¤¿ 'à¤œà¥‹ à¤°à¤¾à¤§à¤¾ à¤¹à¥ˆà¤‚, à¤µà¤¹à¥€, à¤µà¤¹à¥€, à¤µà¤¹à¥€ à¤®à¥‡à¤°à¥‡ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤¹à¥ˆà¤‚à¥¤ à¤œà¥ˆà¤¸à¥‡ à¤¦à¥‚à¤§à¤®à¥‡à¤‚ à¤¸à¤«à¥‡à¤¦à¥€, à¤…à¤—à¥à¤¨à¤¿à¤®à¥‡à¤‚ à¤¦à¤¾à¤¹à¤¿à¤•à¤¾ à¤¶à¤•à¥à¤¤à¤¿, à¤”à¤° à¤ªà¥ƒà¤¥à¥à¤µà¥€à¤®à¥‡à¤‚ à¤—à¤¨à¥à¤§ à¤°à¤¹à¤¤à¥€ à¤¹à¥ˆ, à¤‰à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤° à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤®à¥‡à¤‚ à¤ªà¤°à¤¾à¤¤à¥à¤ªà¤° à¤°à¤¸à¤¿à¤•à¥‡à¤¨à¥à¤¦à¥à¤°à¤¶à¥‡à¤–à¤° à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤à¤µà¤‚ à¤®à¥‡à¤°à¥‡ à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤°à¤¾à¤¨à¥€ à¤°à¤¹à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤«à¤¿à¤° à¤¯à¥‡ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¸à¤¦à¤¾ à¤…à¤­à¤¿à¤¨à¥à¤¨ à¤à¤•à¤°à¤¸ à¤à¤µà¤‚ à¤à¤•à¤¾à¤¤à¥à¤® à¤¹à¥ˆà¤‚à¥¤ à¤ªà¥à¤°à¥‡à¤®à¤°à¤¸à¤¸à¤¾à¤° à¤®à¥‡à¤°à¥‡ à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¤¾ à¤…à¤¸à¥à¤¤à¤¿à¤¤à¥à¤µ à¤¹à¥€ à¤†à¤¨à¤¨à¥à¤¦à¤°à¤¸à¤¸à¤¾à¤° à¤ªà¤°à¤® à¤ªà¥‚à¤œà¥à¤¯ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤®à¥‡à¤‚ à¤¸à¤‚à¤—à¥à¤ªà¥à¤¤ à¤°à¤¸à¤¿à¤•à¤¶à¥‡à¤–à¤°-à¤°à¤¸à¤°à¤¾à¤œà¤¤à¤¤à¥à¤µà¤•à¥‹ à¤‰à¤œà¤¾à¤—à¤° à¤•à¤°à¤¾à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¹à¥€ à¤¥à¤¾, à¤¹à¥ˆ à¤à¤µà¤‚ à¤°à¤¹à¥‡à¤—à¤¾à¥¤
à¤®à¥ˆà¤‚ à¤¯à¤¹ à¤¸à¤¤à¥à¤¯, à¤¸à¤¤à¥à¤¯, à¤¸à¤¤à¥à¤¯ à¤•à¤¹ à¤°à¤¹à¤¾ à¤¹à¥‚à¤ à¤•à¤¿ à¤®à¥ˆà¤‚ à¤°à¤¸à¤¶à¤¾à¤¸à¥à¤¤à¥à¤°à¤¸à¥‡ à¤à¤µà¤‚ à¤°à¤¸à¤¤à¤¤à¥à¤µà¤¸à¥‡ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤¨à¤­à¤¿à¤œà¥à¤ž, à¤¨à¤¿à¤¤à¤¾à¤¨à¥à¤¤ à¤…à¤œà¥à¤ž à¤¹à¥‚à¤, à¤˜à¥‹à¤° à¤µà¤¿à¤·à¤¯à¥€, à¤ªà¤¾à¤®à¤° à¤•à¥‹à¤Ÿà¤¿à¤•à¤¾ à¤ªà¥à¤°à¤¾à¤£à¥€ à¤¹à¥‚à¤à¥¤ à¤‡à¤¸ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤¸à¥‡ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥€ à¤‡à¤¸ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨à¥€à¤•à¥€ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾ à¤•à¤°à¤¨à¥‡à¤®à¥‡à¤‚ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤à¤µà¤‚ à¤¸à¤°à¥à¤µà¤¦à¤¾ à¤…à¤ªà¤¾à¤¤à¥à¤° à¤¹à¥‚à¤à¥¤ à¤‡à¤¸à¥‡ à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶ à¤•à¤°à¤¨à¥‡à¤•à¤¾ à¤­à¥€ à¤®à¥à¤ à¤œà¥ˆà¤¸à¥‡ à¤…à¤˜à¥€ à¤ªà¥à¤°à¤¾à¤£à¥€à¤•à¤¾ à¤…à¤§à¤¿à¤•à¤¾à¤° à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤ à¤®à¥‡à¤°à¥‡ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥€ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨à¥€à¤•à¥€ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾ à¤¤à¥‹ à¤°à¤¾à¤§à¤¾à¤­à¤¾à¤µà¤¦à¥à¤¯à¥à¤¤à¤¿-à¤µà¤²à¤¿à¤¤-à¤¤à¤¨à¥ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤šà¤¨à¥à¤¦à¥à¤° à¤¹à¥€ à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤µà¥‡ à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤”à¤° à¤¸à¤¾à¤¥-à¤¹à¥€-à¤¸à¤¾à¤¥ à¤µà¥‡ à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤•à¤° à¤¸à¤•à¤¤à¥‡, à¤•à¥à¤¯à¥‹à¤‚à¤•à¤¿ à¤šà¤¿à¤¨à¥à¤®à¤¯, à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤, à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤°à¥‚à¤ª à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤šà¤°à¤¿à¤¤à¥à¤°à¤•à¥€ à¤à¤¸à¥€ à¤¹à¥€ à¤…à¤ªà¥‚à¤°à¥à¤µ à¤¶à¥‹à¤­à¤¾ à¤¹à¥ˆà¥¤ à¤‡à¤¸à¤•à¥€ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾ à¤¸à¥à¤µà¤¯à¤‚ à¤°à¤¸à¤°à¤¾à¤œ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤•à¤° à¤¸à¤•à¤¤à¥‡à¥¤ à¤µà¥‡ à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¹à¥‹à¤¤à¥‡ à¤¤à¥‹ à¤®à¥à¤ à¤œà¥ˆà¤¸à¥‡ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤¨à¤§à¤¿à¤•à¤¾à¤°à¥€à¤•à¤¾ à¤‡à¤¸ à¤•à¤¾à¤°à¥à¤¯à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤µà¥‡ à¤šà¤¯à¤¨ à¤•à¤°à¤¤à¥‡ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤•à¤¾à¤°à¤£ à¤¸à¥à¤¸à¥à¤ªà¤·à¥à¤Ÿ à¤¹à¥ˆà¥¤ à¤°à¤¾à¤§à¤¾ à¤ªà¥à¤°à¥€à¤¤à¤¿-à¤—à¥à¤£-à¤¸à¥à¤µà¤­à¤¾à¤µ-à¤¸à¥à¤®à¥ƒà¤¤à¤¿ à¤®à¤¾à¤¤à¥à¤°à¤¸à¥‡ à¤¹à¥€ à¤µà¥‡ à¤°à¤¸à¤¿à¤•à¥‡à¤¨à¥à¤¦à¥à¤°à¤¶à¥‡à¤–à¤° à¤‡à¤¤à¤¨à¥‡ à¤µà¤¿à¤¹à¤², à¤®à¥à¤—à¥à¤§ à¤¤à¤¥à¤¾ à¤—à¤¦à¥à¤—à¤¦à¤•à¤£à¥à¤  à¤¹à¥‹ à¤œà¤¾à¤¤à¥‡ à¤•à¤¿ à¤‰à¤¨à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤‰à¤¨à¤•à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤šà¤°à¤¿à¤¤à¥à¤°à¤•à¤¾ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾-à¤²à¥‡à¤–à¤¨ à¤¸à¤‚à¤­à¤µ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾à¥¤ à¤¤à¤­à¥€ à¤¨, à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤®à¥à¤-à¤œà¥ˆà¤¸à¥‡ à¤¸à¥ƒà¤·à¥à¤Ÿà¤¿à¤•à¥‡ à¤¸à¤°à¥à¤µà¤¾à¤§à¤¿à¤• à¤µà¤œà¥à¤°-à¤•à¤ à¥‹à¤° à¤¨à¥€à¤°à¤¸ à¤ªà¥à¤°à¤¾à¤£à¥€à¤•à¤¾ à¤šà¤¯à¤¨ à¤•à¤¿à¤¯à¤¾à¥¤ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤®à¥à¤à¤®à¥‡à¤‚ à¤à¤• à¤¹à¥€ à¤ªà¤¾à¤¤à¥à¤°à¤¤à¤¾ à¤ªà¤¾à¤ˆà¥¤ à¤µà¤¹ à¤ªà¤¾à¤¤à¥à¤°à¤¤à¤¾ à¤¯à¤¹à¥€ à¤¥à¥€ à¤•à¤¿ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œ à¤à¤µà¤‚ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¦à¤¿à¤µà¥à¤¯à¤¾à¤¤à¤¿à¤¦à¤¿à¤µà¥à¤¯ à¤ªà¤¦-à¤°à¤œà¤•à¤£ à¤¹à¥€ à¤®à¥‡à¤°à¥‡ à¤ªà¤°à¤® à¤†à¤¶à¥à¤°à¤¯ à¤¥à¥‡à¥¤ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤®à¤¸à¥à¤¤à¤•à¤•à¥‹ à¤¶à¤¤à¤¾à¤§à¤¿à¤• à¤¬à¤¾à¤° à¤‡à¤¸ à¤ªà¤¦-à¤°à¤œà¤•à¤£à¤¸à¥‡ à¤ªà¤°à¤¿à¤¸à¥à¤¨à¤¾à¤¤ à¤•à¤¿à¤¯à¤¾ à¤¥à¤¾à¥¤ à¤®à¥à¤ à¤¨à¤¿à¤°à¤¾à¤²à¤®à¥à¤¬à¤•à¥‡ à¤®à¤¾à¤¤à¥à¤° à¤µà¥‡ à¤¹à¥€ à¤…à¤µà¤²à¤®à¥à¤¬ à¤¥à¥‡, à¤à¤µà¤‚ à¤¹à¥ˆà¤‚à¥¤ à¤®à¥à¤ à¤ªà¤¤à¤¿à¤¤à¤•à¥‹ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¤¾ à¤µà¤¾à¤šà¤¿à¤• à¤µà¤°à¤¦à¤¾à¤¨ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤ à¤¥à¤¾ à¤•à¤¿ 'à¤•à¤­à¥€-à¤•à¤­à¥€ à¤®à¤¹à¤œà¥à¤œà¤¨-à¤šà¤°à¤£à¤¾à¤¶à¥à¤°à¤¯à¤¸à¥‡ à¤¸à¤°à¥à¤µà¤¾à¤§à¤¿à¤• à¤¨à¤¿à¤•à¥ƒà¤·à¥à¤Ÿ à¤œà¥€à¤µ à¤­à¥€ à¤¸à¤°à¥à¤µà¥‹à¤¤à¥à¤•à¥ƒà¤·à¥à¤Ÿ à¤•à¥ƒà¤ªà¤¾à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤®à¥‡à¤‚ à¤¹à¥‡à¤¤à¥ à¤¹à¥‹ à¤œà¤¾à¤¤à¤¾ à¤¹à¥ˆ'à¥¤ à¤‰à¤¨ à¤¹à¥‡à¤¤à¥à¤°à¤¹à¤¿à¤¤ à¤•à¥ƒà¤ªà¤¾à¤˜à¤¨à¤•à¥€ à¤®à¤¹à¤¾à¤¨à¥ à¤…à¤¨à¥à¤—à¥à¤°à¤¹à¤µà¤°à¥à¤·à¤¾ à¤¹à¥€ à¤®à¥à¤ à¤ªà¤¤à¤¿à¤¤ à¤ªà¤¾à¤®à¤° à¤ªà¥à¤°à¤¾à¤£à¥€à¤¸à¥‡ à¤¯à¤¹ à¤•à¤¾à¤°à¥à¤¯ à¤¨à¤¿à¤·à¥à¤ªà¤¾à¤¦à¤¨ à¤•à¤°à¤¾ à¤—à¤¯à¥€ à¤¹à¥ˆà¥¤
à¤®à¥ˆà¤‚ à¤¸à¤¤à¥à¤¯ à¤•à¤¹ à¤°à¤¹à¤¾ à¤¹à¥‚à¤ à¤•à¤¿ à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤®à¤°à¥à¤®à¤•à¤¾ à¤ªà¤°à¤¿à¤šà¤¯ à¤®à¥à¤à¥‡ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¥€ à¤•à¥ƒà¤ªà¤¾à¤¸à¥‡ à¤¹à¥€ à¤®à¤¿à¤²à¤¾à¥¤ à¤à¤¸à¥‡ à¤…à¤¨à¥‡à¤•à¥‹à¤‚ à¤ªà¥à¤°à¤¸à¤™à¥à¤— à¤†à¤¯à¥‡ à¤œà¤¹à¤¾à¤ à¤®à¥ˆà¤‚ à¤•à¥à¤› à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤¸à¤®à¤ à¤ªà¤¾à¤¯à¤¾, à¤®à¥‡à¤°à¥‡ à¤¸à¤®à¥à¤®à¥à¤– à¤µà¥‡ à¤²à¥€à¤²à¤¾à¤à¤ à¤ªà¥à¤°à¤•à¤Ÿ à¤¹à¥à¤ˆ à¤œà¤¿à¤¨à¤•à¤¾ à¤¸à¥‚à¤¤à¥à¤°à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤®à¤¾à¤¤à¥à¤° à¤¸à¤™à¥à¤•à¥‡à¤¤ à¤¹à¥€ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤•à¤° à¤—à¤¯à¥‡ à¤¥à¥‡à¥¤ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤‡à¤¸ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾à¤®à¥‡à¤‚ à¤à¤•-à¤à¤• à¤¶à¤¬à¥à¤¦ à¤ªà¥‚à¤°à¥à¤£ à¤ªà¥à¤°à¤¾à¤®à¤¾à¤£à¤¿à¤•à¤¤à¤¾à¤¸à¥‡ à¤²à¤¿à¤–à¤¨à¥‡à¤•à¥€ à¤šà¥‡à¤·à¥à¤Ÿà¤¾ à¤•à¥€ à¤¹à¥ˆ, à¤•à¥à¤¯à¥‹à¤‚à¤•à¤¿ à¤¯à¤¹ à¤®à¥‡à¤°à¥‡ à¤¸à¤°à¥à¤µà¤¾à¤§à¤¿à¤• à¤ªà¥à¤°à¤¿à¤¯, à¤ªà¥‚à¤œà¥à¤¯, à¤œà¥€à¤µà¤¨à¤¸à¤°à¥à¤µà¤¸à¥à¤µ, à¤œà¥€à¤µà¤¨à¤¨à¤¿à¤§à¤¿ à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¤¾ à¤­à¤¾à¤µà¤šà¤°à¤¿à¤¤à¥à¤° à¤¥à¤¾à¥¤ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤‡à¤¸ à¤—à¥à¤°à¤¨à¥à¤¥à¤•à¥€ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾à¤®à¥‡à¤‚ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤…à¤ªà¤¨à¥€ à¤®à¤¨à¥‹à¤ªà¥à¤°à¤¸à¥‚à¤¤ à¤•à¤²à¥à¤ªà¤¨à¤¾à¤•à¤¾ à¤¸à¤¹à¤¾à¤°à¤¾ à¤¨à¤¹à¥€à¤‚ à¤²à¤¿à¤¯à¤¾ à¤¹à¥ˆà¥¤ à¤¯à¤¦à¤¿ à¤®à¥ˆà¤‚ à¤®à¤¨à¥‹à¤ªà¥à¤°à¤¸à¥‚à¤¤ à¤•à¤²à¥à¤ªà¤¨à¤¾à¤•à¥€ à¤›à¤¾à¤¯à¤¾à¤•à¤¾ à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶ à¤­à¥€ à¤‡à¤¸ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾à¤®à¥‡à¤‚ à¤•à¤°à¤¤à¤¾ à¤¤à¥‹ à¤¯à¤¹ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¤¾ à¤¨à¤¿à¤°à¥à¤®à¤²à¤¤à¤® à¤¸à¥‚à¤°à¥à¤¯ à¤®à¥‡à¤°à¥‡ à¤…à¤¨à¥à¤§à¤¤à¤® 'à¤•à¤¾à¤®' à¤¸à¥‡ à¤—à¥à¤°à¤¸à¥à¤¤ à¤¹à¥‹ à¤œà¤¾à¤¤à¤¾à¥¤ à¤®à¥ˆ à¤‡à¤¸ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾à¤•à¤¾ à¤¶à¤¬à¥à¤¦-à¤¶à¤¬à¥à¤¦ à¤²à¤¿à¤–à¤¤à¥‡ à¤¸à¤®à¤¯ à¤‡à¤¸ à¤­à¤¯à¤¸à¥‡ à¤¸à¤¦à¥ˆà¤µ à¤†à¤¶à¤™à¥à¤•à¤¿à¤¤ à¤°à¤¹à¤¾ à¤¹à¥‚à¤ à¤•à¤¿ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤®à¥‡à¤°à¥€ à¤•à¤²à¥à¤ªà¤¨à¤¾à¤•à¥€ à¤•à¥‹à¤ˆ à¤•à¤¾à¤šà¤®à¤£à¤¿ à¤‡à¤¸ à¤¹à¥€à¤°à¤•-à¤¹à¤¾à¤°à¤¾à¤µà¤²à¤¿à¤®à¥‡à¤‚ à¤¨à¤¹à¥€à¤‚ à¤µà¤¿à¤œà¤¡à¤¼à¤¿à¤¤ à¤¹à¥‹ à¤œà¤¾à¤¯, à¤…à¤¨à¥à¤¯à¤¥à¤¾ à¤¯à¤¹ à¤°à¤šà¤¨à¤¾ à¤¸à¤šà¥à¤šà¥‡ à¤°à¤¸à¤®à¤°à¥à¤®à¤œà¥à¤ž à¤œà¥Œà¤¹à¤°à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¸à¤®à¤¾à¤¦à¤°à¤£à¥€à¤¯ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤—à¥€à¥¤ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤¯à¤¹ à¤—à¥à¤°à¤¨à¥à¤¥ à¤²à¥€à¤²à¤¾à¤œà¤—à¤¤à¥à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¥à¤¥à¤¿à¤¤ à¤°à¤¸à¤¿à¤•à¤¾à¤šà¤¾à¤°à¥à¤¯ à¤šà¥ˆà¤¤à¤¨à¥à¤¯ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥, à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤µà¤²à¥à¤²à¤­à¤¾à¤šà¤¾à¤°à¥à¤¯, à¤ªà¤°à¤® à¤µà¤¨à¥à¤¦à¤¨à¥€à¤¯ à¤¸à¥à¤µà¤¾à¤®à¥€ à¤¹à¤°à¤¿à¤¦à¤¾à¤¸à¤¾à¤šà¤¾à¤°à¥à¤¯, à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¹à¤¿à¤¤à¤¹à¤°à¤¿à¤µà¤‚à¤¶, à¤­à¤•à¥à¤¤à¤ªà¥à¤°à¤µà¤° à¤µà¤¨à¥à¤¦à¤¨à¥€à¤¯ à¤°à¥‚à¤ª-à¤¸à¤¨à¤¾à¤¤à¤¨à¤¾à¤¦à¤¿ à¤—à¥Œà¤¡à¥€à¤¯ à¤†à¤šà¤¾à¤°à¥à¤¯à¥‹à¤‚à¤•à¥‡ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤ªà¤¥à¤®à¥‡à¤‚ à¤­à¥€ à¤†à¤µà¥‡à¤—à¤¾à¥¤ à¤µà¥‡ à¤‡à¤¸ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾à¤ªà¤° à¤­à¥€ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤ªà¤¾à¤¤ à¤­à¥€ à¤•à¤°à¥‡à¤‚à¤—à¥‡à¥¤ à¤µà¥‡ à¤°à¤¸à¤¿à¤•à¤¶à¤¿à¤°à¥‹à¤®à¤£à¤¿ à¤®à¤¹à¤¾à¤¸à¤¿à¤¦à¥à¤§ à¤†à¤šà¤¾à¤°à¥à¤¯à¤µà¤°à¥à¤¯ à¤•à¤¹à¥€à¤‚ à¤®à¥‡à¤°à¥€ à¤µà¥à¤¯à¤¾à¤–à¥à¤¯à¤¾à¤®à¥‡à¤‚ à¤•à¤¿à¤žà¥à¤šà¤¿à¤¤à¥ à¤­à¥€ à¤²à¥Œà¤•à¤¿à¤•à¤¾à¤µà¥‡à¤¶à¤•à¥€ à¤—à¤¨à¥à¤§ à¤ªà¤¾ à¤œà¤¾à¤µà¥‡à¤‚à¤—à¥‡ à¤¤à¥‹ à¤®à¥‡à¤°à¥‡ à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¨à¤¾à¤®à¤•à¥€ à¤•à¤¿à¤°à¤•à¤¿à¤°à¥€ à¤¹à¥‹ à¤œà¤¾à¤µà¥‡à¤—à¥€, à¤•à¥à¤¯à¥‹à¤‚à¤•à¤¿ à¤…à¤¨à¥à¤¤à¤¤à¤ƒ à¤¶à¤¿à¤·à¥à¤¯ à¤¤à¥‹ à¤®à¥ˆà¤‚ à¤‰à¤¨à¤•à¤¾ à¤¹à¥€ à¤¹à¥‚à¤à¥¤
à¤…à¤¸à¥à¤¤à¥, à¤‡à¤¸ à¤†à¤¶à¤™à¥à¤•à¤¾à¤•à¥‹ à¤§à¥à¤¯à¤¾à¤¨à¤®à¥‡à¤‚ à¤°à¤–à¤¤à¥‡ à¤¹à¥à¤ à¤‡à¤¸ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¶à¥à¤°à¥à¤¤à¤¿à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤•à¤¿à¤¸à¥€ à¤­à¥€ à¤›à¤¨à¥à¤¦à¤•à¥‡ à¤…à¤°à¥à¤¥à¤ªà¥à¤°à¤•à¤¾à¤¶à¤ªà¤° à¤œà¤¹à¤¾à¤ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤®à¥‡à¤°à¥€ à¤¬à¥à¤¦à¥à¤§à¤¿ à¤•à¥à¤£à¥à¤ à¤¿à¤¤ à¤¹à¥à¤ˆ à¤¹à¥ˆ à¤¤à¥‹ à¤®à¥ˆà¤‚à¤¨à¥‡ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥à¤•à¥€ à¤šà¤°à¤£à¤°à¥‡à¤£à¥à¤•à¤¾ à¤¹à¥€ à¤†à¤¶à¥à¤°à¤¯ à¤²à¤¿à¤¯à¤¾ à¤¹à¥ˆà¥¤ à¤‰à¤¨ à¤¹à¥‡à¤¤à¥à¤°à¤¹à¤¿à¤¤ à¤•à¥ƒà¤ªà¤¾-à¤µà¤°à¤¦à¤¾à¤¨à¥€à¤•à¥€ à¤šà¤°à¤£à¤°à¥‡à¤£à¥à¤¨à¥‡ à¤®à¥à¤à¥‡ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤¨à¤¿à¤°à¤¾à¤¶ à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¯à¤¾ à¤¹à¥ˆà¥¤ à¤‡à¤¸ à¤—à¥à¤°à¤¨à¥à¤¥à¤•à¥‡ à¤•à¥‚à¤Ÿ-à¤¸à¥‡-à¤•à¥‚à¤Ÿ à¤¸à¥à¤¥à¤²à¥‹à¤‚à¤•à¥‡ à¤®à¤°à¥à¤®à¤•à¤¾ à¤ªà¥à¤°à¤•à¤¾à¤¶ à¤¤à¤¤à¥à¤•à¥à¤·à¤£ à¤¹à¥€ à¤®à¥‡à¤°à¥‡ à¤¸à¤®à¥à¤®à¥à¤– à¤‡à¤¸ à¤¸à¤°à¤²à¤¤à¤¾à¤¸à¥‡ à¤¹à¥à¤† à¤¹à¥ˆ à¤•à¤¿ à¤®à¥ˆà¤‚ à¤§à¤¨à¥à¤¯-à¤§à¤¨à¥à¤¯ à¤•à¤° à¤‰à¤ à¤¾ à¤¹à¥‚à¤à¥¤
à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œ à¤¤à¥‹ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ à¤¥à¥‡ à¤¹à¥€ à¤•à¤¹à¤¾à¤ ?

à¤¤à¥à¤°à¤¿à¤—à¥à¤£à¤°à¤šà¤¿à¤¤ à¤¯à¤¹ à¤¦à¥‡à¤¹, à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤®à¤¯ à¤•à¤°à¤¿ à¤°à¤¹à¥à¤¯à¥Œà¥¤
à¤à¤¸à¥‹  à¤•à¤¿à¤°à¤ªà¤¾-à¤®à¥‡à¤¹   à¤¬à¤°à¤¸à¤¾à¤¯à¥Œ  à¤ªà¤¿à¤¯  à¤¸à¤¾à¤à¤µà¤°à¥Œ à¥¤à¥¤
        (à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤°à¤šà¤¿à¤¤ à¤¸à¥‹à¤°à¤ à¤¾)

à¤‰à¤¨à¤•à¤¾ à¤¤à¥à¤°à¤¿à¤—à¥à¤£à¤°à¤šà¤¿à¤¤ à¤¦à¥‡à¤¹ à¤°à¤¹à¤¾ à¤¹à¥€ à¤•à¤¹à¤¾à¤ à¤¥à¤¾? à¤µà¤¹ à¤¤à¥‹ à¤•à¤¬à¤•à¤¾ à¤¹à¥€ à¤²à¤¹à¤°à¤¾à¤¤à¥‡, à¤¨à¤¿à¤¤à¥à¤¯à¥‹à¤šà¥à¤›à¤²à¤¿à¤¤, à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¸à¤¿à¤¨à¥à¤§à¥à¤•à¥€ à¤Šà¤°à¥à¤®à¤¿ à¤¬à¤¨ à¤—à¤¯à¤¾ à¤¥à¤¾ ! à¤¤à¤­à¥€ à¤¨,	

à¤›à¤¾à¤à¤¡à¥à¤¯à¥Œ à¤…à¤ªà¤¨à¥Œ à¤¨à¥‡à¤®,  à¤¸à¤­à¥€ à¤®à¥‹à¤°  à¤¸à¤¾à¤à¤šà¥Œ à¤•à¤¯à¥Œà¤‚à¥¤
à¤•à¤°à¥ˆ à¤œà¥‹à¤— à¤…à¤°à¥ à¤›à¥‡à¤®, à¤ªà¤¿à¤¯ à¤¸à¥Œ à¤­à¤¯à¥Œ à¤¨ à¤¹à¥‹à¤¹à¤¿à¤¹à¥ˆà¥¤à¥¤
        (à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤°à¤šà¤¿à¤¤ à¤¸à¥‹à¤°à¤ à¤¾)

à¤®à¥‡à¤°à¥‡ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¥‡à¤¶à¥à¤µà¤°, à¤ªà¥à¤°à¤¾à¤£à¤¾à¤°à¤¾à¤®, à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤•, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨à¤•à¤¾ à¤¸à¥à¤µà¤­à¤¾à¤µ à¤à¤¸à¤¾ à¤¹à¥€ à¤¹à¥ˆà¥¤ à¤µà¥‡ à¤…à¤ªà¤¨à¤¾ à¤¨à¥à¤¯à¤¾à¤¯-à¤¨à¤¿à¤¯à¤® à¤¤à¥à¤¯à¤¾à¤— à¤¦à¥‡à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤”à¤° à¤…à¤ªà¤¨à¥‡ à¤†à¤¶à¥à¤°à¤¿à¤¤ à¤œà¤¨à¥‹à¤‚à¤•à¥‡ à¤®à¤¨à¥‹à¤°à¤¥à¤•à¥‹ à¤¸à¤šà¥à¤šà¤¾ à¤¬à¤¨à¤¾à¤•à¤° à¤ªà¥‚à¤°à¥à¤£ à¤•à¤° à¤¦à¥‡à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤‰à¤¨ à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤œà¥ˆà¤¸à¤¾ à¤¯à¥‹à¤—-à¤•à¥à¤·à¥‡à¤®à¤•à¤¾ à¤¨à¤¿à¤°à¥à¤µà¤¾à¤¹ à¤•à¤°à¤¨à¥‡à¤µà¤¾à¤²à¤¾ à¤…à¤¨à¥à¤¯ à¤•à¥‹à¤ˆ à¤¹à¥à¤† à¤¹à¥ˆ, à¤¨ à¤¹à¥‹à¤—à¤¾ à¤¹à¥€à¥¤
à¤‰à¤¨ à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥€ à¤®à¥‡à¤°à¥‡ à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤ªà¤° à¤…à¤¨à¤¨à¥à¤¤ à¤…à¤¸à¥€à¤® à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¥‹ à¤ªà¤°à¤–à¤¤à¥‡ à¤¹à¥à¤ à¤¹à¥€ à¤®à¥‡à¤°à¤¾ à¤ªà¥‚à¤°à¥à¤£ à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸ à¤¹à¥ˆ à¤•à¤¿ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‡ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨à¤•à¥‡ à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤—à¥à¤°à¤¨à¥à¤¥à¤•à¤¾ à¤œà¥‹ à¤­à¥€ à¤ªà¤¾à¤ à¤• à¤­à¤¾à¤µ à¤à¤µà¤‚ à¤¶à¥à¤°à¤¦à¥à¤§à¤¾à¤¸à¤¹à¤¿à¤¤ à¤…à¤µà¤—à¤¾à¤¹à¤¨ à¤•à¤°à¥‡à¤‚à¤—à¥‡, à¤µà¥‡ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¸à¥à¤µà¤°à¥‚à¤ª à¤ªà¥à¤°à¥‡à¤®à¤œà¤—à¤¤à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¥‡à¤¶ à¤ªà¤¾à¤µà¥‡à¤‚à¤—à¥‡à¥¤
à¤¯à¤¹ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥ˆ à¤•à¤¿ à¤®à¥ˆà¤‚ à¤à¤• à¤ªà¥à¤°à¥‡à¤®à¤¶à¥‚à¤¨à¥à¤¯ à¤œà¤¨à¥à¤¤à¥ à¤¹à¥‚à¤à¥¤ à¤à¤¸à¥‡ à¤•à¥ƒà¤ªà¤¾à¤µà¤¾à¤•à¥à¤¯ à¤•à¤¹à¤¨à¥‡-à¤²à¤¿à¤–à¤¨à¥‡à¤•à¥€ à¤®à¥‡à¤°à¥€ à¤¸à¤¾à¤®à¤°à¥à¤¥à¥à¤¯ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤ à¤•à¤¿à¤¨à¥à¤¤à¥ à¤®à¥‡à¤°à¥‡ à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤ªà¤° à¤‰à¤¨à¤•à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤ªà¥à¤°à¤¾à¤£à¤¨à¤¾à¤¥à¤•à¥€ à¤ªà¥à¤°à¥€à¤¤à¤¿ à¤¦à¥‡à¤–à¤•à¤° à¤¹à¥€ à¤®à¥ˆà¤‚ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¥€ à¤šà¤°à¤£à¤°à¤œà¤•à¥‹ à¤¸à¤¾à¤•à¥à¤·à¥€ à¤¬à¤¨à¤¾à¤•à¤° à¤•à¤¹à¤¤à¤¾ à¤¹à¥‚à¤ à¤•à¤¿ à¤®à¥‡à¤°à¥€ à¤µà¤¾à¤£à¥€ à¤…à¤•à¥à¤·à¤°à¤¶à¤ƒ à¤…à¤–à¤£à¥à¤¡ à¤¸à¤¤à¥à¤¯ à¤¸à¤¿à¤¦à¥à¤§ à¤¹à¥‹à¤—à¥€à¥¤
à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤¸à¥à¤µà¤¯à¤‚ à¤”à¤° à¤‰à¤¨à¤•à¤¾ à¤¯à¤¹ à¤²à¥€à¤²à¤¾à¤šà¤°à¤¿à¤¤à¥à¤° à¤¦à¥‹ à¤µà¤¸à¥à¤¤à¥à¤à¤ à¤¤à¥‹ à¤¹à¥ˆà¤‚ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤œà¤¹à¤¾à¤ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¤¾ à¤¨à¤¾à¤®, à¤°à¥‚à¤ª, à¤²à¥€à¤²à¤¾, à¤à¤µà¤‚ à¤§à¤¾à¤® à¤šà¤¾à¤°à¥‹à¤‚ à¤µà¤¸à¥à¤¤à¥à¤à¤ à¤ªà¥‚à¤°à¥à¤£ à¤ªà¤°à¤¾à¤¤à¥à¤ªà¤° à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¸à¥à¤µà¤°à¥‚à¤ª à¤¹à¥€ à¤¹à¥ˆà¤‚ à¤¤à¥‹ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¤¾ à¤šà¤°à¤¿à¤¤à¥à¤° à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¸à¥‡ à¤­à¤¿à¤¨à¥à¤¨ à¤•à¥ˆà¤¸à¥‡ à¤¸à¤‚à¤­à¤µ à¤¹à¥ˆ? à¤…à¤¤à¤ƒ à¤®à¥ˆà¤‚ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾ à¤°à¤šà¤¿à¤¤ à¤¨à¤¿à¤®à¥à¤¨ à¤›à¤¨à¥à¤¦à¥‹à¤‚à¤•à¤¾ à¤†à¤¶à¥à¤°à¤¯ à¤²à¥‡à¤•à¤° à¤¹à¥€ à¤à¤¸à¥€ à¤®à¤™à¥à¤—à¤²à¤®à¤¯à¥€ à¤µà¤¾à¤£à¥€à¤•à¤¾ à¤‰à¤šà¥à¤šà¤¾à¤°à¤£ à¤•à¤° à¤°à¤¹à¤¾ à¤¹à¥‚à¤-

(à¤¦à¥‹à¤¹à¤¾) 
   à¤®à¥‹ à¤‡à¤šà¥à¤›à¤¿à¤¤  à¤•à¥ˆ  à¤•à¥ƒà¤¸à¥à¤¨ à¤ªà¤¿à¤¯,  à¤°à¥à¤šà¥ˆ  à¤¬à¤¨à¤¿à¤‰,  à¤¬à¤¨à¤°à¤¾à¤‰à¥¤
   à¤¹à¥‹à¤‡  à¤¨à¤¿à¤°à¤¾à¤µà¤¿à¤²  à¤¸à¤°à¥à¤µà¤¥à¤¾   à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿  à¤¬à¥à¤¡à¤¼à¤¿ à¤œà¤¾à¤‰ à¥¤à¥¤à¥§à¥¤à¥¤
   à¤¬à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ª à¤œà¤¸à¥à¤®à¤¤à¤¿-à¤¸à¥à¤…à¤¨ ! à¤…à¤¬ à¤µà¤¿à¤²à¤®à¥à¤¬ à¤œà¤¨à¤¿ à¤²à¤¾à¤‰à¥¤
   à¤¹à¥‹à¤‡ à¤¨à¤¿à¤°à¤¾à¤µà¤¿à¤² à¤à¤¹à¤¿ à¤›à¤¿à¤¨ à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿  à¤¬à¥à¤¡à¤¼à¤¿  à¤œà¤¾à¤‰ à¥¤à¥¤à¥¨à¥¤à¥¤
   à¤¬à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ª  à¤¬à¤¿à¤¨à¤¤à¥€   à¤§à¤°à¤¤   à¤…à¤­à¤¿à¤¨à¥Œ  à¤¸à¥à¤–  à¤¬à¤¿à¤¸à¤°à¤¾à¤‰à¥¤
   à¤•à¤°à¥Œ  à¤…à¤¨à¥à¤—à¥à¤°à¤¹  à¤…à¤¬  à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿  à¤¬à¥à¤¡à¤¼à¤¿  à¤œà¤¾à¤‰ à¥¤à¥¤à¥©à¥¤à¥¤
   à¤¬à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ª   à¤ªà¤¿à¤¯   à¤¬à¥‡à¤¨à¥à¤§à¤°,   à¤¸à¤¾à¤à¤µà¤°   à¤¬à¤¿à¤°à¤¦  à¤¬à¤¢à¤¼à¤¾à¤‰ à¥¤
   à¤•à¤°à¥Œ  à¤¤à¥à¤°à¤¨à¥à¤¤  à¤•à¥ƒà¤ªà¤¾  à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿  à¤¬à¥à¤¡à¤¼à¤¿   à¤œà¤¾à¤‰ à¥¤à¥¤à¥ªà¥¤à¥¤


(à¤¸à¥‹à¤°à¤ à¤¾)
    à¤®à¥‹ à¤¸à¥à¤– à¤²à¤—à¤¿ à¤¤à¥à¤® à¤ªà¥€à¤‰, à¤…à¤¬ à¤²à¥Œà¤‚ à¤•à¤¹à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¤¸à¥à¤¯à¥Œà¥¤
    à¤¤à¥à¤®à¥à¤¹à¤°à¥Œ  à¤ªà¥à¤¯à¤¾à¤°  à¤…à¤¸à¥€à¤‰à¤,   à¤¨à¤¿à¤¤à¥à¤¯   à¤…à¤¤à¥à¤²  à¤à¤¸à¥‹à¤‡  à¤¹à¥ˆà¥¤à¥¤à¥«à¥¤à¥¤
    à¤¦à¥‡à¤–à¥à¤¯à¥Œ   à¤…à¤¦à¥à¤­à¥à¤¤    à¤–à¥‡à¤²,   à¤‡à¤¨   à¤®à¤¾à¤Ÿà¥€-à¤ªà¥à¤¤à¤°à¥€à¤¨  à¤•à¥Œà¥¤
    à¤…à¤¬  à¤¤à¥à¤°à¤¨à¥à¤¤  à¤¦à¥‹  à¤ à¥‡à¤²,  à¤¸à¤¬à¤¨à¤¨à¤¿  à¤¬à¥à¤°à¤œ-à¤°à¤¸-à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚ à¥¤à¥¤ à¥¬ à¥¤à¥¤

(à¤›à¤¨à¥à¤¦)
à¤¹à¥‡ à¤®à¤¹à¤¾à¤®à¤¹à¤¿à¤® !  à¤¹à¥‡ à¤¬à¥à¤°à¤œà¤¨à¤¨à¥à¤¦à¤¨ !  à¤•à¤°à¥à¤£à¤¾à¤µà¤°à¥à¤£à¤¾à¤²à¤¯ !  à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥‡ à¤•à¥ƒà¤·à¥à¤£ ! à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­ ! à¤¸à¤¾à¤à¤µà¤° ! à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤°à¤¸à¤¿à¤¯à¤¾ ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥‡ à¤µà¤‚à¤¶à¥€à¤§à¤° ! à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥‡  à¤¸à¥à¤–à¤®à¥‡à¤‚ à¤¹à¥€  à¤¬à¤¸,  à¤¸à¥à¤–à¤¿à¤¯à¤¾ ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥‡    à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤°   !  à¤®à¥à¤  à¤°à¤¾à¤§à¤¾à¤•à¥€  à¤¨à¥ˆà¤¯à¤¾à¤•à¥‡   à¤–à¥‡à¤µà¥ˆà¤¯à¤¾ !   à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !

à¤…à¤¬  à¤¢à¤°à¥Œ  à¤¤à¥à¤°à¤¨à¥à¤¤  à¤ªà¥à¤°à¤¥à¤®  à¤…à¤ªà¤¨à¥‡  à¤‡à¤¨  à¤¦à¤¸ à¤°à¥‚à¤ªà¥‹à¤‚à¤ªà¤°,  à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤«à¤¿à¤°  à¤¢à¤°à¥Œ  à¤¤à¥à¤°à¤¨à¥à¤¤  à¤µà¤¿à¤¶à¥à¤µà¤®à¤¯  à¤¨à¤¿à¤œ à¤®à¤¦à¥à¤¦à¥ƒà¤¶à¥à¤¯  à¤°à¥‚à¤ªà¤ªà¤°,   à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¸à¥à¤–à¥€ à¤¤à¥à¤® à¤¹à¥‹ à¤œà¤¾à¤“,  à¤–à¤¿à¤²  à¤‰à¤ à¥‹  à¤«à¥‚à¤²-à¤¸à¥‡,  à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤ªà¤²-à¤ªà¤²  à¤¬à¤¢à¤¼à¤¤à¥‡  à¤¹à¥€  à¤šà¤²à¥‹  à¤­à¤¾à¤µà¤¸à¤¾à¤—à¤°à¤•à¥€  à¤“à¤°  à¤¤à¤¥à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !

à¤œà¥‹ à¤¦à¥‹à¤·  à¤¨  à¤¦à¥‡à¤–à¥‡  à¤•à¤¹à¥€à¤‚,  à¤•à¤­à¥€,  à¤à¤¸à¥‡  à¤¹à¥‹  à¤à¤• à¤¤à¥à¤®à¥à¤¹à¥€à¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤…à¤¤à¤à¤µ   à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€   à¤ªà¥à¤¯à¤¾à¤°à¥€   à¤®à¥à¤   à¤°à¤¾à¤§à¤¾à¤•à¥€  à¤¬à¤¿à¤¨à¤¤à¥€  à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¯à¤¦à¥à¤¯à¤ªà¤¿  à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾  à¤¤à¥à¤®à¤¸à¥‡  à¤•à¤¹à¤¨à¥‡à¤•à¥€  à¤¥à¥€  à¤¨  à¤•à¤¿à¤¨à¥à¤¤à¥,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤•à¤¹ à¤—à¤¯à¥€  à¤”à¤° à¤•à¤°  à¤—à¤¯à¥€,  à¤¹à¥à¤ˆ  à¤ªà¥à¤°à¥‡à¤°à¤¿à¤¤  à¤¤à¥à¤®à¤¸à¥‡  à¤¬à¤¿à¤¨à¤¤à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !


à¤•à¤¹à¤¨à¥‡à¤µà¤¾à¤²à¥€,   à¤¸à¥à¤¨à¤¨à¥‡à¤µà¤¾à¤²à¥‡    à¤¦à¥‹à¤¨à¥‹à¤‚   à¤¤à¥à¤®   à¤¹à¥€  à¤¤à¥‹  à¤¹à¥‹,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¯à¤¹  à¤–à¥‡à¤²   à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾   à¤¨à¤¿à¤¤à¥à¤¯  à¤¸à¤°à¤¸   à¤à¤µà¤‚  à¤°à¤¹à¤¸à¥à¤¯à¤®à¤¯ à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥ˆ  à¤²à¤¹à¤°à¤¾à¤¤à¤¾  à¤¹à¥€   à¤°à¤¹à¤¤à¤¾  à¤µà¤¹,  à¤¸à¤‚à¤µà¤¿à¤¦-à¤¸à¥à¤µà¤°à¥‚à¤ª  à¤¸à¤¾à¤—à¤°,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤‰à¤¨ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¤¾ à¤¹à¥€ à¤¨à¤¾à¤®  à¤¯à¤¹à¤¾à¤  à¤¸à¤‚à¤¸à¥à¤¥à¤¾à¤¨,  à¤¸à¥ƒà¤œà¤¨,  à¤²à¤¯ à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !

à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¤¾ à¤‰à¤¤à¥à¤¤à¤°â€”
à¤¹à¥ˆ  à¤¸à¤¦à¤¾ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤¹à¥€ à¤¸à¥à¤– à¤¬à¤¸,  à¤®à¥‡à¤°à¤¾  à¤¤à¥‹ à¤¸à¥à¤– à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ ! à¤…à¤¹à¥‹ !
à¤®à¥ˆà¤‚   à¤•à¤°   à¤¦à¥‚à¤à¤—à¤¾  à¤…à¤µà¤¶à¥à¤¯  à¤ªà¥‚à¤°à¥€  à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤•   à¤šà¤¾à¤¹,  à¤¨à¤¿à¤¶à¥à¤šà¤¿à¤¨à¥à¤¤  à¤°à¤¹à¥‹ !
à¤¹à¤® à¤¸à¤­à¥€ à¤…à¤­à¤¿à¤¨à¥à¤¨ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤¹à¥ˆà¤‚, à¤«à¤¿à¤° à¤­à¥€ à¤œà¥‹ à¤°à¥à¤šà¤¿ à¤¹à¥‹, à¤¤à¥à¤°à¤¤ à¤•à¤¹à¥‹à¥¤
à¤¹à¥‡  à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤®à¤¯à¤¿  !  à¤¹à¤®à¥‡à¤‚ à¤²à¤¿à¤¯à¥‡, à¤°à¤¸-à¤¸à¥à¤§à¤¾-à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚  à¤¨à¤¿à¤¤à¥à¤¯ à¤¬à¤¹à¥‹à¥¤à¥¤ 

(à¤­à¤¾à¤µà¤¾à¤°à¥à¤¥)

à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ ! à¤¯à¤¦à¤¿ à¤†à¤ªà¤•à¥‹ à¤°à¥à¤šà¤¿à¤•à¤° à¤²à¤—à¤¤à¤¾ à¤¹à¥‹ à¤¤à¥‹ à¤®à¥‡à¤°à¥€ à¤‡à¤šà¥à¤›à¤¾à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤° à¤°à¥‚à¤ª à¤§à¤¾à¤°à¤£ à¤•à¤° à¤²à¥€à¤œà¤¿à¤¯à¥‡à¥¤ à¤¹à¥‡ à¤¬à¤¨à¤°à¤¾à¤‡ (à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨à¤•à¥‡ à¤°à¤¾à¤œà¤¾), à¤†à¤ª à¤¸à¤‚à¤¸à¤¾à¤°à¤—à¤¤ à¤®à¤¾à¤¯à¤¾à¤µà¥‡à¤¶ à¤¤à¥à¤¯à¤¾à¤—à¤•à¤° à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¨à¤¿à¤°à¤¾à¤µà¤¿à¤² (à¤¨à¤¿à¤·à¥à¤•à¤²à¥à¤®à¤·) à¤¹à¥‹à¤•à¤° à¤­à¤¾à¤µà¤¸à¤®à¥à¤¦à¥à¤° à¤ªà¥à¤°à¥‡à¤®à¥‹à¤¦à¤§à¤¿à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬ à¤œà¤¾à¤‡à¤¯à¥‡ à¥¤à¥¤à¥¤à¥§à¥¤à¥¤
à¤¹à¥‡ à¤µà¤¿à¤¶à¥à¤µà¤°à¥‚à¤ª à¤¯à¤¶à¥à¤®à¤¤à¤¿à¤¨à¤¨à¥à¤¦à¤¨ ! à¤…à¤¬ à¤µà¤¿à¤²à¤®à¥à¤¬ à¤®à¤¤ à¤•à¤°à¤¿à¤¯à¥‡à¥¤ à¤‡à¤¸à¥€ à¤•à¥à¤·à¤£ à¤¸à¤®à¤—à¥à¤° à¤•à¤²à¥à¤®à¤·à¤°à¤¹à¤¿à¤¤ à¤¹à¥‹à¤•à¤° à¤­à¤¾à¤µà¤¸à¤®à¥à¤¦à¥à¤° à¤ªà¥à¤°à¥€à¤¤à¤¿à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬ à¤œà¤¾à¤‡à¤¯à¥‡ à¥¤à¥¤ à¥¨ à¥¤à¥¤
à¤¹à¥‡ à¤µà¤¿à¤¶à¥à¤µà¤°à¥‚à¤ª à¤§à¤¾à¤°à¤£ à¤•à¤¿à¤¯à¥‡ à¤®à¥‡à¤°à¥‡ à¤¸à¥à¤µà¤¾à¤®à¥€! à¤®à¥‡à¤°à¥€ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾à¤•à¥‹ à¤…à¤ªà¤¨à¥‡ à¤šà¤¿à¤¤à¥à¤¤à¤®à¥‡à¤‚ à¤§à¤¾à¤°à¤£ à¤•à¤° à¤²à¥€à¤œà¤¿à¤¯à¥‡à¥¤ à¤…à¤¬ à¤‡à¤¨à¥à¤¦à¥à¤°à¤¿à¤¯à¤œà¤¨à¥à¤¯ à¤¨à¤¯à¥‡-à¤¨à¤¯à¥‡ à¤µà¤¿à¤·à¤¯à¥‹à¤‚à¤®à¥‡à¤‚ à¤¸à¥à¤–à¤¾à¤¶à¤¾ à¤›à¥‹à¤¡à¤¼ à¤¦à¥€à¤œà¤¿à¤¯à¥‡à¥¤ à¤…à¤¬ à¤…à¤ªà¤¨à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤®à¥à¤ à¤†à¤ªà¤•à¥€ à¤†à¤¤à¥à¤®à¤¾à¤ªà¤° à¤…à¤¨à¥à¤—à¥à¤°à¤¹ à¤•à¤°à¤¿à¤¯à¥‡ à¤à¤µà¤‚ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¥‡ à¤¸à¤°à¥à¤µà¥‹à¤šà¥à¤š à¤¸à¤°à¥à¤µà¤¶à¥à¤¦à¥à¤§ à¤®à¤¹à¤¾à¤­à¤¾à¤µ à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬ à¤œà¤¾à¤‡à¤¯à¥‡à¥¤à¥¤à¥©à¥¤à¥¤
à¤¹à¥‡ à¤µà¤¿à¤¶à¥à¤µà¤°à¥‚à¤ª à¤§à¤¾à¤°à¤£à¤•à¤¿à¤¯à¥‡ à¤µà¥‡à¤£à¥à¤§à¤° à¤¶à¥à¤¯à¤¾à¤®à¤¸à¥à¤¨à¥à¤¦à¤° ! à¤…à¤ªà¤¨à¥‡ à¤¯à¤¶à¤•à¥€ à¤…à¤­à¤¿à¤µà¥ƒà¤¦à¥à¤§à¤¿ à¤•à¤°à¤¿à¤¯à¥‡ à¤à¤µà¤‚ à¤®à¥à¤ à¤…à¤ªà¤¨à¥€ à¤†à¤¤à¥à¤®à¤¾à¤ªà¤° à¤¤à¥à¤°à¤¨à¥à¤¤ à¤•à¥ƒà¤ªà¤¾ à¤•à¤°à¤•à¥‡ à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤¸à¤®à¥à¤¦à¥à¤°à¤®à¥‡à¤‚ à¤¡à¥‚à¤¬ à¤œà¤¾à¤‡à¤¯à¥‡à¥¤à¥¤à¥ªà¥¤à¥¤
à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¤¨à¤¾à¤¥ ! à¤†à¤ªà¤¨à¥‡ à¤®à¥‡à¤°à¥‡ à¤¸à¥à¤–à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤…à¤¬à¤¤à¤• à¤•à¥à¤¯à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¯à¤¾ ? à¤†à¤ªà¤•à¤¾ à¤ªà¥à¤°à¥‡à¤® à¤…à¤¸à¥€à¤® à¤…à¤¨à¤¨à¥à¤¤ à¤¹à¥ˆà¥¤ à¤µà¤¹ à¤à¤¸à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤‰à¤¸à¤•à¥€ à¤¤à¥à¤²à¤¨à¤¾ à¤•à¤¹à¥€à¤‚ à¤•à¤¿à¤¸à¥€à¤¸à¥‡ à¤¹à¥‹ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤¸à¤•à¤¤à¥€à¥¤à¥¤ à¥« à¥¤à¥¤
à¤®à¥ˆà¤‚à¤¨à¥‡ à¤‡à¤¨ à¤ªà¤žà¥à¤šà¤­à¥‚à¤¤à¤°à¤šà¤¿à¤¤ à¤¦à¥‡à¤¹à¥‹à¤‚à¤•à¥‹ à¤§à¤¾à¤°à¤£ à¤•à¤°à¤¨à¥‡à¤µà¤¾à¤²à¥€ à¤®à¥ƒà¤¤à¥à¤¤à¤¿à¤•à¤¾à¤®à¤¯à¥€ à¤ªà¥à¤¤à¤²à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤…à¤¦à¥à¤­à¥à¤¤ à¤–à¥‡à¤² à¤–à¥‚à¤¬ à¤¦à¥‡à¤– à¤²à¤¿à¤¯à¤¾à¥¤ à¤…à¤¬. à¤¤à¥‹ à¤‡à¤¨ à¤¸à¤­à¥€ à¤ªà¥à¤¤à¤²à¤¿à¤¯à¥‹à¤‚à¤•à¥‹ à¤†à¤ª à¤¬à¥à¤°à¤œ-à¤°à¤¸-à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚ à¤ à¥‡à¤² à¤¦à¥€à¤œà¤¿à¤¯à¥‡ à¥¤à¥¤à¥¬à¥¤à¥¤
à¤¹à¥‡ à¤®à¤¹à¤¾à¤®à¤¹à¤¿à¤® à¤¬à¥à¤°à¤œà¤¨à¤¨à¥à¤¦à¤¨ ! à¤¹à¥‡ à¤•à¤°à¥à¤£à¤¾à¤µà¤°à¥à¤£à¤¾à¤²à¤¯ ! à¤¹à¥‡ à¤•à¥ƒà¤·à¥à¤£ ! à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­ à¤¸à¤¾à¤à¤µà¤°à¥‡ ! à¤¹à¥‡ à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤°à¤¸à¤¿à¤¯à¤¾ ! à¤¹à¥‡ à¤µà¤‚à¤¶à¥€à¤§à¤° ! à¤¹à¥‡ à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤¸à¥à¤–à¤®à¥‡à¤‚ à¤¹à¥€ à¤¸à¥à¤–à¤¿à¤¯à¤¾ ! à¤¹à¥‡ à¤œà¥€à¤µà¤¨à¤§à¤¨ ! à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤•! à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤° ! à¤¹à¥‡ à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤¨à¥ˆà¤¯à¤¾à¤•à¥‡ à¤–à¥‡à¤µà¥ˆà¤¯à¤¾ ! à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¸à¤°à¥à¤µà¤ªà¥à¤°à¤¥à¤® à¤†à¤ª à¤¤à¥à¤°à¤¨à¥à¤¤ à¤¹à¥€ à¤†à¤ªà¤•à¥‡ à¤‡à¤¸ à¤¦à¤¸ à¤¨à¤¾à¤®à¤°à¥‚à¤ª à¤§à¤¾à¤°à¤£ à¤•à¤¿à¤¯à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¥‹à¤‚à¤ªà¤° (à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‡ à¤¦à¤¸ à¤ªà¥à¤°à¤®à¥à¤– à¤•à¥ƒà¤ªà¤¾à¤ªà¤¾à¤¤à¥à¤°à¥‹à¤‚à¤ªà¤°) à¤…à¤¨à¥à¤—à¥à¤°à¤¹à¥€à¤¤ à¤¹à¥‹à¤“ à¤à¤µà¤‚ à¤¤à¤¬ à¤…à¤µà¤¿à¤²à¤®à¥à¤¬ à¤…à¤ªà¤¨à¥‡ à¤µà¤¿à¤¶à¥à¤µà¤®à¤¯ à¤®à¥‡à¤°à¥‡ à¤¦à¥ƒà¤¶à¥à¤¯ à¤¬à¤¨à¥‡ à¤°à¥‚à¤ªà¥‹à¤‚à¤ªà¤° à¤•à¥ƒà¤ªà¤¾à¤²à¥ à¤¹à¥‹ à¤œà¤¾à¤“à¥¤ à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¤à¥à¤® à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¸à¥à¤–à¥€ à¤¹à¥‹ à¤œà¤¾à¤“ à¤à¤µà¤‚ à¤«à¥‚à¤²à¤•à¥€ à¤¤à¤°à¤¹ à¤ªà¥à¤°à¤«à¥à¤²à¥à¤²à¤¿à¤¤ à¤¹à¥‹à¤•à¤° à¤–à¤¿à¤² à¤‰à¤ à¥‹ à¥¤à¥¤ à¥­ à¥¤à¥¤
à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¤à¥à¤® à¤ªà¥à¤°à¤¤à¤¿à¤ªà¤² à¤ªà¥à¤°à¥‡à¤®à¤•à¥‡ à¤¸à¤°à¥à¤µà¥‹à¤šà¥à¤š à¤­à¤¾à¤µà¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥€ à¤“à¤° à¤¬à¤¢à¤¼à¤¤à¥‡ à¤¹à¥€ à¤œà¤¾à¤“à¥¤ à¤œà¥‹ à¤•à¤¿à¤¸à¥€à¤•à¤¾ à¤•à¤­à¥€ à¤¦à¥‹à¤· à¤¨à¤¹à¥€à¤‚ à¤¦à¥‡à¤–à¥‡ à¤à¤¸à¥‡ à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤¹à¥‹à¥¤ à¤‡à¤¸à¥€à¤²à¤¿à¤¯à¥‡ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤¤à¥à¤®à¤¸à¥‡ à¤µà¤¿à¤¨à¤¯ à¤¹à¥ˆà¥¤ à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¸à¤°à¥à¤µà¤¾à¤¨à¥à¤¤à¤°à¥à¤¯à¤¾à¤®à¥€ à¤¹à¥‹à¤¨à¥‡à¤•à¥‡ à¤¨à¤¾à¤¤à¥‡ à¤¤à¥à¤®à¤¸à¥‡ à¤…à¤ªà¤¨à¥€ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤®à¥Œà¤–à¤¿à¤• à¤•à¤¹à¤¨à¥‡à¤•à¥€ à¤¯à¤¦à¥à¤¯à¤ªà¤¿ à¤•à¥‹à¤ˆ à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¥à¥€, à¤•à¤¿à¤¨à¥à¤¤à¥ à¤«à¤¿à¤° à¤­à¥€ à¤®à¥ˆà¤‚ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¹à¥€ à¤ªà¥à¤°à¥‡à¤°à¤¿à¤¤ à¤¹à¥à¤ˆ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤¸à¤¬à¤•à¥à¤› à¤®à¥Œà¤–à¤¿à¤• à¤•à¤¹ à¤—à¤¯à¥€ à¤à¤µà¤‚ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤­à¥€ à¤•à¤° à¤¹à¥€ à¤—à¤¯à¥€à¥¤ à¤®à¥ˆà¤‚ à¤¯à¤¹ à¤¬à¤¾à¤¤ à¤­à¤²à¥€ à¤ªà¥à¤°à¤•à¤¾à¤° à¤œà¤¾à¤¨à¤¤à¥€ à¤¥à¥€ à¤•à¤¿ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤•à¤°à¤¨à¥‡à¤µà¤¾à¤²à¥€ à¤­à¥€ à¤¤à¥à¤® à¤¹à¥€ à¤¬à¤¨à¥‡ à¤¹à¥‹, à¤”à¤° à¤¸à¥à¤¨à¤¨à¥‡à¤µà¤¾à¤²à¥‡ à¤¤à¥‹ à¤¤à¥à¤® à¤¹à¥‹ à¤¹à¥€à¥¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®! à¤…à¤ªà¤¨à¥‡ à¤†à¤ªà¤¸à¥‡, à¤…à¤ªà¤¨à¥‡ à¤†à¤ªà¤®à¥‡à¤‚ à¤¹à¥€ à¤¯à¤¹ à¤–à¥‡à¤² à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¤°à¤¸ à¤à¤µà¤‚ à¤°à¤¹à¤¸à¥à¤¯à¤®à¤¯ à¤¹à¥ˆà¥¤ à¤°à¤¹à¤¸à¥à¤¯à¤®à¤¯ à¤‡à¤¸ à¤…à¤‚à¤¶à¤®à¥‡à¤‚ à¤•à¤¿ à¤‡à¤¸à¤•à¥‡ à¤­à¥€à¤¤à¤°à¤•à¤¾ à¤®à¤¾à¤°à¥à¤®à¤¿à¤• à¤¸à¤¤à¥à¤¯ à¤•à¥‹à¤ˆ à¤œà¤¾à¤¨ à¤¨à¤¹à¥€à¤‚ à¤ªà¤¾à¤¤à¤¾, à¤µà¤¹ à¤¸à¤¦à¥ˆà¤µ à¤…à¤œà¥à¤žà¤¾à¤¤ à¤¹à¥€ à¤°à¤¹à¤¤à¤¾ à¤¹à¥ˆ; à¤à¤µà¤‚ à¤¸à¤°à¤¸ à¤‡à¤¸ à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤•à¤¿ à¤¦à¥à¤–à¤°à¥‚à¤ª à¤•à¥à¤·à¤£à¤­à¤‚à¤—à¥à¤° à¤°à¤¹à¤¤à¥‡ à¤¹à¥à¤ à¤­à¥€ à¤‡à¤¸à¤®à¥‡à¤‚ à¤¸à¥à¤–à¤¾à¤¶à¤¾ à¤¬à¤¨à¥€ à¤¹à¥€ à¤°à¤¹à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤¯à¤¹ à¤¸à¤‚à¤µà¤¿à¤¦à¥ à¤°à¥‚à¤ª à¤¸à¤®à¥à¤¦à¥à¤° (à¤šà¥‡à¤¤à¤¨-à¤œà¥€à¤µà¤®à¤¯ à¤¸à¤‚à¤¸à¤¾à¤°) à¤²à¤¹à¤°à¤¾à¤¤à¤¾ à¤¹à¥€ à¤°à¤¹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤‡à¤¸ à¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥€ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¤¾ à¤¹à¥€ à¤¨à¤¾à¤® à¤¸à¥ƒà¤œà¤¨, à¤¸à¥à¤¥à¤¿à¤¤à¤¿, à¤à¤µà¤‚ à¤ªà¥à¤°à¤²à¤¯ à¤¹à¥ˆà¥¤

à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¤¾ à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‹ à¤‰à¤¤à¥à¤¤à¤°-
à¤…à¤¹à¥‹ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ à¤°à¤¾à¤§à¥‡ ! à¤¸à¤¦à¥ˆà¤µ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤¹à¥€ à¤¸à¥à¤– à¤¬à¤¸, à¤®à¥‡à¤°à¤¾ à¤¸à¥à¤– à¤¹à¥ˆà¥¤ à¤®à¥ˆà¤‚ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤‡à¤šà¥à¤›à¤¾ à¤…à¤µà¤¶à¥à¤¯ à¤ªà¥‚à¤°à¥€ à¤•à¤° à¤¦à¥‚à¤à¤—à¤¾, à¤¤à¥à¤® à¤¨à¤¿à¤¶à¥à¤šà¤¿à¤¨à¥à¤¤ à¤°à¤¹à¥‹à¥¤ à¤¤à¥à¤®, à¤®à¥ˆà¤‚, à¤à¤µà¤‚ à¤¯à¤¹ à¤¸à¥ƒà¤œà¤¨, à¤¸à¥à¤¥à¤¿à¤¤à¤¿ à¤à¤µà¤‚ à¤ªà¥à¤°à¤²à¤¯à¤°à¥‚à¤ª à¤œà¥€à¤µ-à¤¸à¤®à¥à¤¦à¤¾à¤¯ à¤¸à¤­à¥€ à¤ªà¤°à¤¸à¥à¤ªà¤° à¤…à¤­à¤¿à¤¨à¥à¤¨ à¤¹à¥ˆà¤‚à¥¤ à¤«à¤¿à¤° à¤­à¥€ à¤œà¥‹ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤°à¥à¤šà¤¿ à¤¹à¥‹, à¤¤à¥à¤® à¤¤à¥à¤°à¤¨à¥à¤¤ à¤•à¤¹à¥‹à¥¤ à¤¹à¥‡ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤®à¤¯à¤¿ ! à¤¤à¥à¤® à¤®à¥à¤à¥‡ à¤à¤µà¤‚ à¤®à¥‡à¤°à¥‡ à¤…à¤­à¤¿à¤¨à¥à¤¨ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤¸à¥ƒà¤·à¥à¤Ÿà¤¿, à¤¸à¥à¤¥à¤¿à¤¤à¤¿, à¤ªà¥à¤°à¤²à¤¯à¤°à¥‚à¤ª à¤‡à¤¸ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥‡ à¤¦à¥ƒà¤¶à¥à¤¯à¤°à¥‚à¤ª à¤µà¤¿à¤¶à¥à¤µà¤•à¥‹ à¤¸à¤¾à¤¥ à¤²à¤¿à¤¯à¥‡ à¤°à¤¸-à¤¸à¥à¤§à¤¾ à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¬à¤¹à¤¤à¥€ à¤°à¤¹à¥‹à¥¤
-------
à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤…à¤ªà¤¨à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤ªà¥à¤°à¤¾à¤£à¤¨à¤¾à¤¥ à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¸à¥‡ à¤•à¥€ à¤¹à¥à¤ˆ à¤‰à¤ªà¤°à¥‹à¤•à¥à¤¤ à¤ªà¥à¤°à¤¾à¤°à¥à¤¥à¤¨à¤¾ à¤à¤µà¤‚ à¤‰à¤¨à¤•à¥‡ à¤¸à¤°à¥à¤µà¤­à¤µà¤¨à¤¸à¤®à¤°à¥à¤¥, à¤•à¤°à¥à¤¤à¥à¤®à¤•à¤°à¥à¤¤à¥à¤®à¤¨à¥à¤¯à¤¥à¤¾à¤•à¤°à¥à¤¤à¥à¤®à¥ à¤¸à¤®à¤°à¥à¤¥ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤‰à¤¨à¥à¤¹à¥‡à¤‚ à¤¦à¤¿à¤¯à¥‡à¤—à¤¯à¥‡ à¤‰à¤¤à¥à¤¤à¤°à¤•à¥‡ à¤†à¤§à¤¾à¤°à¤•à¥‹ à¤²à¥‡à¤•à¤° à¤¹à¥€ à¤ªà¥‚. à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‡ à¤¸à¥à¤µà¤°à¤®à¥‡à¤‚ à¤…à¤ªà¤¨à¤¾ à¤¨à¤¿à¤°à¥à¤¬à¤² à¤¨à¤¿à¤°à¥€à¤¹ à¤¸à¥à¤µà¤° à¤®à¤¿à¤²à¤¾à¤¤à¥‡ à¤¹à¥à¤ à¤®à¥ˆà¤‚ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤ªà¤¾à¤¤à¥à¤° à¤¨à¤¿à¤®à¥à¤¨ à¤®à¤™à¥à¤—à¤²à¤µà¤šà¤¨ à¤•à¤¹ à¤°à¤¹à¤¾ à¤¹à¥‚à¤-
'à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨à¤•à¥‡ à¤‡à¤¸ à¤¶à¥à¤°à¥à¤¤à¤¿à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤œà¥‹ à¤­à¥€ à¤ªà¤¾à¤ à¤• à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤…à¤µà¤—à¤¾à¤¹à¤¨, à¤¨à¤¿à¤®à¤œà¥à¤œà¤¨ à¤•à¤°à¥‡à¤‚à¤—à¥‡, à¤µà¥‡ à¤à¤• à¤à¤¸à¥‡ à¤…à¤¨à¤¿à¤°à¥à¤µà¤šà¤¨à¥€à¤¯ à¤ªà¤°à¤® à¤¦à¥à¤°à¥à¤²à¤­ à¤µà¤¿à¤²à¤•à¥à¤·à¤£ à¤šà¤¿à¤¦à¤¾à¤¨à¤¨à¥à¤¦à¤®à¤¯ à¤®à¤¹à¤¾à¤°à¤¸à¤•à¥€ à¤‰à¤ªà¤²à¤¬à¥à¤§à¤¿ à¤•à¤°à¥‡à¤‚à¤—à¥‡, à¤œà¥‹ à¤‰à¤¨à¤•à¥‡ à¤¸à¤®à¤—à¥à¤° à¤µà¤¿à¤·à¤¯-à¤µà¥à¤¯à¤¾à¤®à¥‹à¤¹à¤•à¥‹ à¤¸à¤¦à¤¾à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤®à¤¿à¤Ÿà¤¾ à¤¦à¥‡à¤—à¤¾à¥¤ à¤®à¥‡à¤°à¥‡ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤­à¤¾à¤µà¤œà¥€à¤µà¤¨ à¤‡à¤¸ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤ªà¤ à¤¨à¤•à¤¾ à¤¯à¤¹à¥€ à¤®à¤¾à¤¹à¤¾à¤¤à¥à¤®à¥à¤¯ à¤¹à¥ˆà¥¤ à¤‡à¤¸à¤•à¤¾ à¤…à¤•à¥à¤·à¤°-à¤…à¤•à¥à¤·à¤°, à¤‡à¤¸à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤£ à¤µà¤¿à¤°à¤¾à¤®, à¤…à¤°à¥à¤§ à¤µà¤¿à¤°à¤¾à¤®, à¤…à¤¨à¥à¤¸à¥à¤µà¤¾à¤°, à¤šà¤¨à¥à¤¦à¥à¤°à¤µà¤¿à¤¨à¥à¤¦à¥à¤¤à¤• à¤ªà¥‚à¤°à¥à¤£ à¤°à¤¸à¤®à¤¯ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¸à¤®à¥‡à¤‚ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤¡à¥‚à¤¬à¤¨à¥‡à¤µà¤¾à¤²à¥‡à¤•à¥‹ à¤¦à¥à¤°à¥à¤²à¤­-à¤¸à¥‡-à¤¦à¥à¤°à¥à¤²à¤­ à¤¦à¤¿à¤µà¥à¤¯ à¤¦à¥‡à¤µà¤­à¥‹à¤—à¥‹à¤‚à¤•à¥‡ à¤†à¤¨à¤¨à¥à¤¦à¤¸à¥‡ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚, à¤ªà¤°à¤® à¤¤à¤¥à¤¾ à¤šà¤°à¤® à¤µà¤¾à¤žà¥à¤›à¤¨à¥€à¤¯ à¤¬à¥à¤°à¤¹à¥à¤®à¤¾à¤¨à¤¨à¥à¤¦à¤¸à¥‡ à¤­à¥€ à¤…à¤°à¥à¤šà¤¿ à¤¹à¥‹ à¤œà¤¾à¤¯à¤—à¥€à¥¤ à¤¶à¥à¤°à¥€à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¹à¥€ à¤‰à¤¸à¤•à¥‡ à¤¸à¤°à¥à¤µà¤¸à¥à¤µ à¤¹à¥‹à¤•à¤° à¤‰à¤¸à¤®à¥‡à¤‚ à¤¬à¤¸ à¤œà¤¾à¤µà¥‡à¤‚à¤—à¥‡ à¤”à¤° à¤‰à¤¸à¤•à¥‹ à¤…à¤ªà¤¨à¤¾ à¤¸à¥à¤µà¥‡à¤šà¥à¤›à¤¾à¤šà¤¾à¤²à¤¿à¤¤ à¤²à¥€à¤²à¤¾à¤¯à¤‚à¤¤à¥à¤° à¤¬à¤¨à¤¾à¤•à¤° à¤§à¤¨à¥à¤¯ à¤•à¤° à¤¦à¥‡à¤‚à¤—à¥‡à¥¤'
'à¤¨à¤¾à¤¥ ! à¤¹à¥ƒà¤¦à¤¯à¥‡à¤¶à¥à¤µà¤° ! à¤ªà¥à¤°à¤¾à¤£à¤¾à¤°à¤¾à¤® ! à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤•! à¤œà¥€à¤µà¤¨à¤¸à¤°à¥à¤µà¤¸à¥à¤µ ! à¤¨à¤¯à¤¨à¤¾à¤¨à¤¨à¥à¤¦ ! à¤°à¤¸à¤®à¤¯ ! à¤•à¤°à¥à¤£à¤¾à¤®à¤¯! à¤­à¤¾à¤µà¤®à¤¯ ! à¤²à¥€à¤²à¤¾à¤®à¤¯ ! à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¾à¤° ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®! à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ ! à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤¦à¥‹à¤·à¤¦à¤°à¥à¤¶à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤…à¤¨à¤¨à¥à¤¤ à¤•à¤²à¥à¤¯à¤¾à¤£à¤®à¤¯, à¤¸à¥à¤µà¤°à¥‚à¤ªà¤­à¥‚à¤¤ à¤—à¥à¤£à¤—à¤£à¤¶à¤¾à¤²à¥€ ! à¤µà¤¿à¤¶à¥à¤µà¤°à¥‚à¤ª à¤µà¤¿à¤¶à¥à¤µà¥‡à¤¶à¥à¤µà¤° ! à¤…à¤–à¤¿à¤²à¤¾à¤¤à¥à¤®à¤¨à¥ ! à¤¸à¤°à¥à¤µà¤œà¥à¤ž-à¤¸à¤°à¥à¤µà¤µà¤¿à¤¦à¥ ! à¤¸à¤°à¥à¤µà¤­à¤µà¤¨à¤¸à¤®à¤°à¥à¤¥ ! à¤…à¤¨à¤¨à¥à¤¤à¥ˆà¤¶à¥à¤µà¤°à¥à¤¯à¤¨à¤¿à¤•à¥‡à¤¤à¤¨ ! à¤¸à¤°à¥à¤µà¤²à¥‹à¤•à¤®à¤¹à¥‡à¤¶à¥à¤µà¤° ! à¤•à¤°à¥à¤£à¤¾à¤µà¤°à¥à¤£à¤¾à¤²à¤¯ ! à¤®à¥‡à¤°à¥‡ à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥€ à¤°à¥à¤šà¤¿à¤•à¤¾ à¤¹à¥€ à¤…à¤¨à¥à¤¸à¤°à¤£ à¤•à¤°à¤¨à¥‡à¤µà¤¾à¤²à¥‡ ! à¤®à¥‡à¤°à¥‡ à¤¦à¥‡à¤µà¤¤à¤¾! à¤®à¥‡à¤°à¥‡ à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥€ à¤°à¥à¤šà¤¿à¤•à¥‹ à¤¹à¥€ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¸à¤°à¥à¤µà¤¾à¤‚à¤¶à¤®à¥‡à¤‚ à¤¹à¥€ à¤ªà¤µà¤¿à¤¤à¥à¤°à¤¤à¤® à¤¢à¤‚à¤—à¤¸à¥‡, à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¸à¤°à¥à¤µà¤¾à¤‚à¤¶à¤®à¥‡à¤‚ à¤¹à¥€ à¤ªà¤µà¤¿à¤¤à¥à¤°à¤¤à¤® à¤¢à¤‚à¤—à¤¸à¥‡, à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¸à¤°à¥à¤µà¤¾à¤‚à¤¶à¤®à¥‡à¤‚ à¤¹à¥€ à¤ªà¤µà¤¿à¤¤à¥à¤°à¤¤à¤® à¤¢à¤‚à¤—à¤¸à¥‡, à¤¶à¥€à¤˜à¥à¤°-à¤¸à¥‡-à¤¶à¥€à¤˜à¥à¤°, à¤¶à¥€à¤˜à¥à¤°-à¤¸à¥‡-à¤¶à¥€à¤˜à¥à¤°, à¤¶à¥€à¤˜à¥à¤°-à¤¸à¥‡-à¤¶à¥€à¤˜à¥à¤° à¤ªà¥‚à¤°à¥à¤£à¤•à¤°à¤•à¥‡ à¤‰à¤¸à¥‡ à¤¤à¤¤à¥à¤•à¥à¤·à¤£ à¤…à¤¨à¤¨à¥à¤¤ à¤…à¤ªà¤°à¤¿à¤¸à¥€à¤® à¤ªà¤°à¤® à¤®à¤™à¥à¤—à¤²à¤®à¥‡à¤‚, à¤¶à¥à¤°à¥€à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¥‡ à¤”à¤° à¤®à¥‡à¤°à¥‡ à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µà¤•à¥‡ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ª-à¤µà¤¿à¤²à¤¾à¤¸-à¤¸à¤®à¥à¤¦à¥à¤°à¤•à¥€ à¤ªà¤°à¤® à¤°à¤®à¤£à¥€à¤¯ à¤Šà¤°à¥à¤®à¤¿à¤®à¥‡à¤‚ à¤ªà¤°à¥à¤¯à¤µà¤¸à¤¿à¤¤ à¤•à¤°à¤¦à¥‡à¤¨à¥‡à¤µà¤¾à¤²à¥‡ à¤®à¥‡à¤°à¥‡ à¤¨à¥€à¤²à¤ªà¤¦à¥à¤®, à¤ªà¥à¤°à¤¾à¤£à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ ! à¤ªà¥à¤°à¤¾à¤£à¤§à¤¨ ! à¤ªà¥à¤°à¤¾à¤£à¤°à¤®à¤£ ! à¤¸à¤°à¥à¤µà¤¸à¥à¤µ! à¤ªà¥à¤°à¤¾à¤£à¤®à¥‚à¤² à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£! à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‹à¤‚à¤•à¥‡ à¤ªà¤°à¤®à¤¾à¤°à¤¾à¤§à¥à¤¯ à¤¦à¥‡à¤µ ! à¤…à¤–à¤¿à¤² à¤°à¤¸à¤¾à¤®à¥ƒà¤¤à¤®à¥‚à¤°à¥à¤¤à¤¿ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ ! à¤…à¤ªà¤¨à¤¾ à¤¸à¥à¤µà¥‡à¤šà¥à¤›à¤¾à¤šà¤¾à¤²à¤¿à¤¤ à¤²à¥€à¤²à¤¾à¤¯à¤‚à¤¤à¥à¤° à¤¬à¤¨à¤¾à¤•à¤°, à¤…à¤ªà¤¨à¥€ à¤šà¤°à¤£à¤§à¥‚à¤²à¤¿à¤•à¥€ à¤•à¥ƒà¤ªà¤¾à¤•à¤¾ à¤µà¤°à¤¦à¤¾à¤¨ à¤¦à¥‡à¤•à¤° à¤†à¤ªà¤¨à¥‡ à¤‡à¤¸ à¤ªà¤¤à¤¿à¤¤à¤¸à¥‡ à¤œà¥‹ à¤²à¤¿à¤–à¤¾à¤¯à¤¾, à¤¸à¤¬ à¤†à¤ªà¤•à¥‹ à¤¹à¥€ à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤ à¤¹à¥ˆà¥¤'
'à¤†à¤¤à¥à¤®à¤¸à¥à¤µà¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤°à¥‚à¤ªà¤¿à¤£à¤¿ à¥¤ à¤œà¤—à¤œà¥à¤œà¤¨à¤¨à¥€à¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤¯à¥‹à¤—à¤®à¤¾à¤¯à¤¾à¤°à¥‚à¤ªà¤¿à¤£à¤¿ à¥¤ à¤œà¤¾à¤—à¥à¤°à¤¤à¥-à¤¸à¥à¤µà¤ªà¥à¤¨-à¤¸à¥à¤·à¥à¤ªà¥à¤¤à¤¿-à¤­à¤¾à¤µà¤¾à¤ªà¤¨à¥à¤¨à¥‡ ! à¤¤à¥‚à¤°à¥à¤¯à¤¤à¤¾à¤¤à¥à¤®à¤¿à¤•à¥‡ ! à¤¯à¤®à¥à¤¨à¤¾-à¤—à¤™à¥à¤—à¤¾-à¤¸à¤°à¤¸à¥à¤µà¤¤à¥€à¤°à¥‚à¤ªà¤¿à¤£à¤¿ à¥¤ à¤‹à¤¦à¥à¤§à¤¿-à¤¸à¤¿à¤¦à¥à¤§à¤¿-à¤®à¤¹à¤¾à¤¸à¤°à¤¸à¥à¤µà¤¤à¥€-à¤®à¤¹à¤¾à¤²à¤•à¥à¤·à¥à¤®à¥€à¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤†à¤µà¤¯à¥‹à¤ƒ à¤¶à¤¿à¤µ-à¤ªà¤¾à¤°à¥à¤µà¤¤à¥€-à¤²à¥€à¤²à¤¾à¤¯à¤¾à¤‚ à¤¶à¤¿à¤µà¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤ªà¥à¤¨à¤¶à¥à¤š à¤‰à¤®à¤¾à¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤¨à¤µà¤¦à¥à¤°à¥à¤—à¤¾à¤°à¥‚à¤ªà¤¿à¤£à¤¿ à¥¤ à¤¦à¤¶à¤µà¤¿à¤¦à¥à¤¯à¤¾à¤°à¥‚à¤ªà¥‡ ! à¤­à¤—à¤µà¤¤à¤¿ à¥¤ à¤¶à¥à¤°à¥€à¤®à¤¨à¥à¤®à¤¹à¤¾à¤¤à¥à¤°à¤¿à¤ªà¥à¤°à¤¸à¥à¤¨à¥à¤¦à¤°à¥€à¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤• à¤‡à¤¤à¤¿ à¤®à¤‚à¤¤à¥à¤°à¤¸à¥à¤²à¤­à¥‡ ! à¤¶à¥à¤°à¥€à¤®à¤¾à¤¤à¥ƒà¤°à¥‚à¤ªà¥‡ ! à¤²à¤²à¤¿à¤¤à¤¾à¤¦à¤¿-à¤ªà¤°à¤¿à¤•à¤°-à¤°à¥‚à¤ªà¤¿à¤£à¤¿! à¤®à¤žà¥à¤œà¤¶à¥à¤¯à¤¾à¤®à¤¾à¤°à¥‚à¤ªà¤‚ à¤ªà¥à¤°à¤¤à¥à¤¯à¤ªà¤¿ à¤…à¤ªà¤°à¤¿à¤¸à¥€à¤®à¤¾à¤¨à¥à¤°à¤¾à¤— à¤­à¤¾à¤µà¤¯à¤¤à¤¿ ! à¤®à¤žà¥à¤œà¤¶à¥à¤¯à¤¾à¤®à¤¾à¤¯à¤¾à¤‚ à¤›à¤¾à¤¯à¤¾à¤¯à¤¾à¤‚ à¤ªà¥à¤°à¤¤à¥à¤¯à¤ªà¤¿ à¤®à¤šà¥à¤›à¤¾à¤¯à¤¾à¤¯à¤¾à¤‚ à¤ªà¥à¤°à¤¤à¤¿ à¤š à¤®à¤šà¥à¤›à¤¾à¤¯à¤¾à¤¯à¤¾à¤‚ à¤›à¤¾à¤¯à¤¾à¤¯à¤¾à¤‚ à¤ªà¥à¤°à¤¤à¤¿ à¤š à¤…à¤ªà¤°à¤¿à¤¸à¥€à¤®à¤¾à¤¨à¥à¤°à¤¾à¤—-à¤­à¤¾à¤µ-à¤µà¤¿à¤§à¤¾à¤¯à¤¿à¤¨à¤¿ ! à¤…à¤¨à¤¨à¥à¤¤à¤¾à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤-à¤¨à¤¾à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤ à¤¶à¤•à¥à¤¤à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ªà¤¿à¤£à¤¿ ! à¤¸à¤°à¥à¤µà¤¸à¥à¤µà¤°à¥‚à¤ªà¥‡ ! à¤¸à¤°à¥à¤µ à¤°à¥‚à¤ªà¥‡ ! à¤¸à¤°à¥à¤µà¤¾à¤¤à¥€à¤¤à¥‡ ! à¤¨à¤¿à¤¤à¥à¤¯à¤¾à¤¨à¤¿à¤°à¥à¤µà¤šà¤¨à¥€à¤¯à¤¾à¤šà¤¿à¤¨à¥à¤¤à¥à¤¯-à¤µà¤¿à¤°à¥à¤¦à¥à¤§à¤§à¤°à¥à¤®à¤¾à¤¶à¥à¤°à¤¯à¤¤à¥à¤µà¤‚ à¤µà¤¿à¤­à¥‚à¤·à¤¿à¤¤à¥‡ ! à¤°à¤¾à¤§à¥‡ ! à¤¤à¤µ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤ƒ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤•à¤ƒ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤°à¤ƒ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­à¤ƒ, à¤¨à¤¿à¤¤à¥à¤¯à¤¨à¤µà¤¨à¤¿à¤•à¥à¤žà¥à¤œà¥‡à¤¶à¥à¤µà¤°à¤ƒ à¤¨à¤¿à¤¤à¥à¤¯à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨à¥‡à¤¶à¥à¤µà¤°à¤ƒ à¤¨à¤¿à¤¤à¥à¤¯à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨à¤ƒ à¤…à¤¹à¤‚ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤à¤µ à¤¤à¤µà¤¾à¤¤à¥à¤®à¤¾à¤¨à¤‚ à¤®à¤¨à¥à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¾ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤•à¤¾ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤°à¥€ à¤¨à¤¿à¤¤à¥à¤¯à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­à¤¾ à¤¨à¤¿à¤¤à¥à¤¯à¤¨à¤µà¤¨à¤¿à¤•à¥à¤žà¥à¤œà¥‡à¤¶à¥à¤µà¤°à¥€ à¤¨à¤¿à¤¤à¥à¤¯à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨à¥‡à¤¶à¥à¤µà¤°à¥€ à¤¨à¤¿à¤¤à¥à¤¯à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤ªà¥à¤¤à¥à¤°à¥€ à¤¤à¥à¤µà¤‚ à¤°à¤¾à¤§à¥ˆà¤µ à¤®à¤®à¤¾à¤¤à¥à¤®à¤¾ à¤¨à¤¿à¤¤à¥à¤¯à¤²à¥€à¤²à¤¾à¤°à¥à¤¥ à¤­à¤¿à¤¨à¥à¤¨à¤¤à¤¯à¤¾ à¤¸à¥à¤¥à¤¿à¤¤à¤ƒ à¤¸à¤¨à¥ à¤¤à¤µà¤¾à¤™à¥à¤—à¤¸à¥à¤¯ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤•à¥‡ à¤•à¤£à¥‡ à¤¹à¤¿ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¾à¤¤à¥à¤®à¤•à¤¾à¤¹à¥à¤²à¤¾à¤¦à¤°à¥‚à¤ªà¥‡à¤£ à¤¨à¤¿à¤¤à¥à¤¯à¤‚ à¤µà¤°à¥à¤¤à¥à¤¤à¤®à¤¾à¤¨à¤ƒ à¤¤à¤µ à¤¹à¥ƒà¤¦à¤¯à¤¾à¤•à¤¾à¤¶à¥‡ à¤¤à¥ à¤¬à¤¹à¤¿à¤¶à¥à¤š à¤¨à¤¿à¤–à¤¿à¤²à¥‡ à¤°à¥‹à¤®à¤•à¥‚à¤ªà¥‡ à¤š à¤¯à¤¥à¤¾à¤¨à¥à¤­à¥‚à¤¤à¤°à¥€à¤¤à¥à¤¯à¤¾ à¤¤à¥à¤µà¤¦à¤­à¤¿à¤²à¤·à¤¿à¤¤à¤¾à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤ à¤¨à¤µà¤¨à¥€à¤°à¤¦à¤µà¤°à¥à¤£ à¤¦à¥à¤µà¤¿à¤­à¥à¤œà¤¾à¤¨à¤¨à¥à¤¤à¥ˆà¤¶à¥à¤µà¤°à¥à¤¯à¤¨à¤¿à¤•à¥‡à¤¤à¤¨ à¤¸à¤°à¥à¤µà¤²à¥‹à¤•à¤®à¤¹à¥‡à¤¶à¥à¤µà¤° à¤¸à¥à¤µà¤¯à¤‚à¤­à¤—à¤µà¤¤à¥à¤ªà¥à¤°à¤•à¤¾à¤¶ à¤ªà¥à¤°à¥à¤·à¥‹à¤¤à¥à¤¤à¤® à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤• à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤° à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­ à¤¨à¤¿à¤¤à¥à¤¯à¤¨à¤µà¤¨à¤¿à¤•à¥à¤žà¥à¤œà¥‡à¤¶à¥à¤µà¤° à¤¨à¤¿à¤¤à¥à¤¯à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨à¥‡à¤¶à¥à¤µà¤° à¤¨à¤¿à¤¤à¥à¤¯à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨à¤°à¥‚à¤ªà¥‡à¤£ à¤®à¤® à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¯à¥à¤—à¤² ! à¤®à¥‡à¤°à¥‡ à¤¸à¤®à¥à¤®à¥à¤– à¤¯à¤¹à¤¾à¤ à¤®à¥‡à¤°à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤¸à¤¤à¤¤ à¤¸à¤®à¥à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¿à¤¤ à¤¹à¥‹à¤‚ à¤à¤µà¤‚ à¤®à¥‡à¤°à¥€ à¤‡à¤¸ à¤Ÿà¥€à¤•à¤¾à¤ªà¤° à¤…à¤ªà¤¨à¤¾ à¤µà¤°à¤¦ à¤…à¤¨à¥à¤—à¥à¤°à¤¹-à¤¹à¤¸à¥à¤¤ à¤°à¤–à¤•à¤° à¤‡à¤¸à¥‡ à¤…à¤¨à¤¨à¥à¤¤à¤•à¤¾à¤²à¤¤à¤•, à¤¸à¥à¤µà¤‡à¤šà¥à¤›à¤¿à¤¤ à¤•à¤¾à¤²à¤¤à¤• à¤…à¤ªà¤¨à¥‡ à¤à¤µà¤‚ à¤…à¤ªà¤¨à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¾à¤•à¥‡ à¤µà¤¿à¤¶à¥à¤¦à¥à¤§ à¤ªà¥à¤°à¥‡à¤®-à¤µà¤¿à¤¤à¤°à¤£à¤•à¥‡ à¤¯à¥‹à¤—à¥à¤¯ à¤¸à¤¿à¤¦à¥à¤§ à¤•à¤°à¥‡à¤‚à¥¤ à¤à¤µà¤®à¤¸à¥à¤¤à¥, à¤‡à¤¤à¥à¤¯à¤²à¤®à¥ à¥¤ 
''',
      );
    } else if (sectionId == 'topic2' && title == 'à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¥‡à¤¶à¥à¤¯à¤¾à¤® à¤¬à¤‚à¤•à¤¾') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            ''''à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤•à¥€ à¤¸à¥à¤«à¥à¤°à¤£à¤¾ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¨à¤¿à¤®à¤—à¥à¤¨ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤°à¤¸à¤¾à¤µà¤¤à¤¾à¤° à¤ªà¤°à¤®à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤¸à¤°à¥à¤µ à¤ªà¥à¤°à¤¥à¤® à¤µà¥à¤°à¤œ-à¤­à¥‚à¤®à¤¿à¤®à¥‡à¤‚ à¤¹à¥à¤ˆà¥¤ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤ à¥§à¥¯à¥«à¥¬ à¤•à¥‡ à¤…à¤•à¥à¤Ÿà¥‚à¤¬à¤° à¤®à¤¾à¤¸à¤®à¥‡à¤‚ à¤²à¤¿à¤¯à¤¾ à¤¥à¤¾à¥¤ à¤‡à¤¸à¤•à¥‡ à¤à¤• à¤®à¤¾à¤¸ à¤¬à¤¾à¤¦ à¤¨à¤µà¤®à¥à¤¬à¤°à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾ à¤”à¤° à¤¬à¤¾à¤¬à¥‚à¤œà¥€ (à¤¶à¥à¤°à¤¦à¥à¤§à¥‡à¤¯ à¤¶à¥à¤°à¥€à¤¹à¤¨à¥à¤®à¤¾à¤¨à¤ªà¥à¤°à¤¸à¤¾à¤¦à¤œà¥€ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤°) à¤°à¤¤à¤¨à¤—à¤¢à¤¼ (à¤°à¤¾à¤œà¤¸à¥à¤¥à¤¾à¤¨) à¤šà¤²à¥‡ à¤†à¤¯à¥‡ à¤¥à¥‡à¥¤ à¤¨à¤µà¤®à¥à¤¬à¤° à¥§à¥¯à¥«à¥¬ à¤¸à¥‡ à¤…à¤ªà¥à¤°à¥ˆà¤² à¥§à¥¯à¥«à¥® à¤¤à¤• à¤¬à¤¾à¤¬à¤¾ à¤”à¤° à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤°à¤¤à¤¨à¤—à¤¢à¤¼à¤®à¥‡à¤‚ à¤°à¤¹à¥‡à¥¤ à¤‡à¤¸à¥€ à¥§à¥¯à¥«à¥® à¤•à¥‡ à¤œà¤¨à¤µà¤°à¥€ à¤®à¤¾à¤¸à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾ à¤”à¤° à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤°à¤¤à¤¨à¤—à¤¢à¤¼à¤¸à¥‡ à¤µà¥à¤°à¤œà¤­à¥‚à¤®à¤¿ à¤—à¤¯à¥‡ à¤¥à¥‡ à¤¶à¥à¤°à¥€à¤—à¤¿à¤°à¤¿à¤°à¤¾à¤œ à¤­à¤—à¤µà¤¾à¤¨à¤•à¥€ à¤ªà¤°à¤¿à¤•à¥à¤°à¤®à¤¾ à¤²à¤—à¤¾à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡à¥¤ à¤¸à¤¾à¤¥à¤®à¥‡à¤‚ à¤­à¤•à¥à¤¤à¥‹à¤‚à¤•à¤¾ à¤­à¥€ à¤¸à¤®à¥à¤¦à¤¾à¤¯ à¤¥à¤¾, à¤œà¥‹ à¤­à¤¿à¤¨à¥à¤¨-à¤­à¤¿à¤¨à¥à¤¨ à¤¸à¥à¤¥à¤¾à¤¨à¥‹à¤‚à¤¸à¥‡ à¤ªà¤°à¤¿à¤•à¥à¤°à¤®à¤¾ à¤¹à¥‡à¤¤à¥ à¤µà¤¹à¤¾à¤ à¤† à¤—à¤¯à¤¾ à¤¥à¤¾à¥¤ à¤¸à¤­à¥€à¤•à¥‡ à¤ à¤¹à¤°à¤¨à¥‡à¤•à¤¾ à¤ªà¥à¤°à¤¬à¤¨à¥à¤§ à¤•à¤¿à¤¯à¤¾ à¤—à¤¯à¤¾ à¤¥à¤¾ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾-à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚, à¤œà¥‹ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨ à¤”à¤° à¤®à¤¥à¥à¤°à¤¾à¤•à¥‡ à¤®à¤§à¥à¤¯à¤®à¥‡à¤‚ à¤¸à¥à¤¥à¤¿à¤¤ à¤¹à¥ˆà¥¤ à¤‡à¤¨ à¤¦à¤¿à¤¨à¥‹à¤‚ à¤¬à¤¾à¤¬à¤¾à¤•à¤¾ à¤…à¤¤à¤¿ à¤•à¤ à¥‹à¤° à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨-à¤µà¥à¤°à¤¤ à¤šà¤² à¤°à¤¹à¤¾ à¤¥à¤¾, à¤…à¤¤à¤ƒ à¤‡à¤¸à¥€ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾ à¤®à¤¨à¥à¤¦à¤¿à¤°à¤•à¥‡ à¤à¤• à¤•à¤®à¤°à¥‡à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¨à¤¿à¤¤à¤¾à¤¨à¥à¤¤ à¤à¤•à¤¾à¤¨à¥à¤¤ à¤†à¤µà¤¾à¤¸à¤•à¥€ à¤µà¥à¤¯à¤µà¤¸à¥à¤¥à¤¾ à¤•à¥€ à¤—à¤¯à¥€ à¤¥à¥€à¥¤
à¤à¤• à¤¬à¤¾à¤° à¤¬à¤¾à¤¬à¤¾ à¤‡à¤¸ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾ à¤®à¤¨à¥à¤¦à¤¿à¤°à¤•à¥‡ à¤à¤• à¤–à¥à¤²à¥‡ à¤¸à¥à¤¥à¤¾à¤¨à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤§à¤¾à¤® à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨à¤•à¥€ à¤“à¤° à¤®à¥à¤– à¤•à¤° à¤¬à¥ˆà¤ à¥‡ à¤¹à¥à¤ à¤¥à¥‡à¥¤ à¤¤à¤­à¥€ à¤…à¤šà¤¾à¤¨à¤• à¤¨à¥‡à¤¤à¥à¤°à¥‹à¤‚à¤¸à¥‡ à¤…à¤¶à¥à¤°à¥à¤•à¤¾ à¤ªà¥à¤°à¤µà¤¾à¤¹ à¤¬à¤¹ à¤šà¤²à¤¾, à¤¸à¤¾à¤§à¤¾à¤°à¤£ à¤¨à¤¹à¥€à¤‚, à¤…à¤¨à¤°à¥à¤—à¤² à¤ªà¥à¤°à¤µà¤¾à¤¹à¥¤ à¤•à¥‹à¤ˆ à¤¹à¥‡à¤¤à¥ à¤¨à¤¹à¥€à¤‚, à¤«à¤¿à¤° à¤­à¥€ à¤…à¤¨à¤°à¥à¤—à¤² à¤…à¤¶à¥à¤°à¥-à¤ªà¥à¤°à¤µà¤¾à¤¹ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤•à¤ªà¥‹à¤‚à¤²à¥‹à¤‚à¤•à¥‹ à¤°à¤¹-à¤°à¤¹ à¤•à¤°à¤•à¥‡ à¤¸à¤‚à¤¸à¤¿à¤•à¥à¤¤ à¤•à¤° à¤°à¤¹à¤¾ à¤¥à¤¾à¥¤ à¤‰à¤¸à¥€ à¤¸à¤®à¤¯ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤à¤• à¤®à¤¯à¥‚à¤°à¤•à¥‹ à¤¨à¥ƒà¤¤à¥à¤¯ à¤•à¤°à¤¤à¥‡ à¤¹à¥à¤ à¤¦à¥‡à¤–à¤¾à¥¤ à¤‡à¤¸à¤¸à¥‡ à¤”à¤° à¤…à¤§à¤¿à¤• à¤­à¤¾à¤µà¥‹à¤¦à¥à¤¦à¥€à¤ªà¤¨ à¤¹à¥à¤†à¥¤ à¤«à¤¿à¤° à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤µà¥‡à¤— à¤‡à¤¤à¤¨à¤¾ à¤…à¤§à¤¿à¤• à¤¬à¤¢à¤¼ à¤šà¤²à¤¾ à¤•à¤¿ à¤¸à¤®à¤•à¥à¤· à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨ à¤”à¤° à¤µà¥à¤°à¤œà¤­à¥‚à¤®à¤¿à¤•à¤¾ à¤¦à¤¿à¤–à¤²à¤¾à¤¯à¥€ à¤¦à¥‡à¤¨à¤¾ à¤¬à¤¨à¥à¤¦ à¤¹à¥‹ à¤—à¤¯à¤¾à¥¤ à¤¸à¥à¤¥à¥‚à¤² à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨ à¤¤à¤¿à¤°à¥‹à¤¹à¤¿à¤¤ à¤¹à¥‹ à¤—à¤¯à¤¾ à¤”à¤° à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿-à¤ªà¤¥à¤ªà¤° à¤…à¤µà¤¤à¤°à¤¿à¤¤ à¤¹à¥‹ à¤‰à¤ à¤¾ à¤¦à¤¿à¤µà¥à¤¯ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨, à¤•à¥‡à¤µà¤² à¤¦à¤¿à¤µà¥à¤¯ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚, à¤…à¤ªà¤¿à¤¤à¥ à¤µà¤¹à¤¾à¤à¤•à¥€ à¤¦à¤¿à¤µà¥à¤¯ à¤°à¤¸à¥€à¤²à¥€ à¤²à¥€à¤²à¤¾à¤•à¥€ à¤…à¤¦à¥à¤­à¥à¤¤-à¤…à¤­à¤¿à¤¨à¤µ à¤…à¤µà¤²à¥€à¥¤ à¤¤à¤­à¥€ à¤²à¥€à¤²à¤¾à¤•à¥‡ à¤ªà¥à¤°à¤¸à¤‚à¤— à¤”à¤° à¤­à¤¾à¤µ, à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤›à¤¨à¥à¤¦à¥‹à¤‚à¤®à¥‡à¤‚ à¤¢à¤²à¤¨à¥‡ à¤²à¤— à¤—à¤¯à¥‡à¥¤
à¤‡à¤¨ à¤›à¤¨à¥à¤¦à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤®à¥‡à¤‚ à¤•à¥‹à¤ˆ à¤•à¥à¤°à¤® à¤¨à¤¹à¥€à¤‚ à¤¥à¥€, à¤ªà¤° à¤‰à¤¸ à¤•à¥à¤°à¤®à¤¬à¤¦à¥à¤§à¤¤à¤¾à¤•à¥‡ à¤…à¤­à¤¾à¤µà¥‹à¤‚à¤®à¥‡à¤‚  à¤¸à¥‡ à¤à¤• à¤…à¤¦à¥à¤­à¥à¤¤ à¤­à¤µà¤¿à¤¤à¤µà¥à¤¯à¤•à¥€ à¤¸à¤®à¥à¤­à¤¾à¤µà¤¨à¤¾ à¤‰à¤­à¤°à¤•à¤° à¤¸à¤¾à¤®à¤¨à¥‡ à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤ à¤¹à¥‹ à¤—à¤¯à¥€à¥¤ à¤à¤¸à¤¾ à¤²à¤—à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤‡à¤¸ à¤…à¤¦à¥à¤­à¥à¤¤ à¤­à¤µà¤¿à¤¤à¤µà¥à¤¯à¤•à¥‹ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¸à¤®à¤•à¥à¤· à¤ªà¥à¤°à¤¸à¥à¤¤à¥à¤¤ à¤•à¤°à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤•à¤¿à¤¸à¥€ à¤…à¤šà¤¿à¤¨à¥à¤¤à¥à¤¯ à¤µà¤¿à¤§à¤¾à¤¨à¤¸à¥‡ à¤›à¤¨à¥à¤¦à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤®à¥‡à¤‚ à¤•à¥à¤°à¤®à¤¬à¤¦à¥à¤§à¤¤à¤¾à¤•à¤¾ à¤¸à¤®à¤¾à¤µà¥‡à¤¶ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹ à¤ªà¤¾à¤¯à¤¾à¥¤ à¤‡à¤¸ à¤¸à¤®à¤¯ à¤œà¤¿à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥à¤ˆ, à¤‰à¤¸à¤¸à¥‡ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤…à¤¨à¥à¤®à¤¾à¤¨ à¤¹à¥‹ à¤—à¤¯à¤¾ à¤•à¤¿ à¤œà¤¿à¤¸ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤­à¤µà¤¿à¤·à¥à¤¯à¤®à¥‡à¤‚ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¤¨à¥‡à¤µà¤¾à¤²à¥€ à¤¹à¥ˆ, à¤‰à¤¸à¤•à¥‡ à¤•à¥à¤² à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤• à¤¹à¥‹à¤‚à¤—à¥‡à¥¤ à¤ªà¥à¤°à¤¥à¤® à¤¶à¤¤à¤•à¤•à¥€ à¤†à¤  à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¤¾à¤, à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤¶à¤¤à¤•à¤•à¥€ à¤šà¤¾à¤° à¤…à¤¥à¤µà¤¾ à¤†à¤  à¤…à¤¥à¤µà¤¾ à¤¸à¥‹à¤²à¤¹ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¤¾à¤, à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤° à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤¶à¤¤à¤•à¤•à¥€ à¤šà¤¾à¤° à¤…à¤¥à¤µà¤¾ à¤†à¤  à¤…à¤¥à¤µà¤¾ à¤¸à¥‹à¤²à¤¹ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹ à¤—à¤¯à¥€à¥¤ à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥€ à¤†à¤°à¤®à¥à¤­à¤¿à¤• à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤‰à¤¸à¥€ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾ à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚ à¤¤à¤¤à¥à¤•à¤¾à¤² à¤¹à¥‹ à¤—à¤¯à¥€à¥¤ à¤•à¥à¤°à¤®à¤•à¥€ à¤µà¤¿à¤¶à¥à¤°à¥ƒà¤‚à¤–à¤²à¤¤à¤¾à¤¨à¥‡ à¤¹à¥€ à¤¸à¤‚à¤•à¥‡à¤¤ à¤¦à¥‡ à¤¦à¤¿à¤¯à¤¾ à¤•à¤¿ à¤•à¥à¤² à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¤—à¥€à¥¤
à¤œà¥à¤¯à¥‹à¤‚ à¤¹à¥€ à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤­à¤¾à¤µà¤¿à¤¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤¯à¤¹ à¤†à¤­à¤¾à¤¸ à¤¹à¥à¤† à¤•à¤¿ à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤•à¥‹à¤‚à¤µà¤¾à¤²à¥‡ à¤•à¤¿à¤¸à¥€ à¤­à¤¾à¤µà¥€ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤•à¥‡ à¤¯à¥‡ à¤ªà¥‚à¤°à¥à¤µ-à¤¸à¤‚à¤•à¥‡à¤¤ à¤¹à¥ˆà¤‚, à¤¤à¥à¤¯à¥‹à¤‚ à¤¹à¥€ à¤‰à¤¨à¥à¤¹à¥‹à¤‚à¤¨à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¸à¥‡ à¤•à¤¿à¤‚à¤šà¤¿à¤¤à¥ à¤‰à¤ªà¤¾à¤²à¤®à¥à¤­-à¤®à¤¿à¤¶à¥à¤°à¤¿à¤¤ à¤¸à¥à¤µà¤°à¤®à¥‡à¤‚ à¤•à¤¹à¤¾- à¤œà¥‹ à¤…à¤¬à¤¤à¤• à¤…à¤¨à¥‡à¤• à¤­à¤•à¥à¤¤ à¤•à¤µà¤¿à¤¯à¥‹à¤‚ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤²à¤¿à¤–à¤¾ à¤œà¤¾ à¤šà¥à¤•à¤¾ à¤¹à¥ˆ, à¤µà¤¹à¥€ à¤¸à¤¬ à¤®à¥‡à¤°à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤ªà¥à¤¨à¤ƒ à¤²à¤¿à¤–à¤µà¤¾à¤¨à¥‡à¤¸à¥‡ à¤•à¥à¤¯à¤¾ à¤²à¤¾à¤­ ?
à¤¬à¤¾à¤¬à¤¾ à¤¤à¥‹ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾-à¤­à¤¾à¤µà¤®à¥‡à¤‚ à¤¥à¥‡à¥¤ à¤¬à¤¡à¤¼à¥‡ à¤ªà¥à¤¯à¤¾à¤° à¤­à¤°à¥‡ à¤¶à¤¬à¥à¤¦à¥‹à¤‚à¤®à¥‡à¤‚ à¤ªà¤°à¤® à¤à¤•à¤¾à¤¨à¥à¤¤à¤¿à¤• à¤¸à¤®à¥à¤¬à¥‹à¤§à¤¨ à¤•à¤°à¤¤à¥‡ à¤¹à¥à¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤•à¤¹à¤¾- à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤°à¤¿ ! à¤¤à¥à¤® à¤°à¤šà¤¨à¤¾ à¤•à¤°à¥‹ à¤¤à¥‹ à¤¸à¤¹à¥€à¥¤
à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤ªà¥à¤¨à¤ƒ à¤‰à¤¸à¥€ à¤¸à¥à¤µà¤°à¤®à¥‡à¤‚ à¤•à¤¹à¤¾- à¤µà¤¹ à¤°à¤šà¤¨à¤¾ à¤ªà¤¿à¤·à¥à¤Ÿà¤ªà¥‡à¤·à¤£ à¤®à¤¾à¤¤à¥à¤° à¤¹à¥€ à¤¤à¥‹ à¤¹à¥‹à¤—à¥€à¥¤ à¤®à¥à¤à¤¸à¥‡ à¤µà¥à¤¯à¤°à¥à¤¥à¤®à¥‡à¤‚ à¤¶à¥à¤°à¤® à¤•à¥à¤¯à¥‹à¤‚ à¤•à¤°à¤µà¤¾ à¤°à¤¹à¥‡ à¤¹à¥‹? à¤¯à¤¦à¤¿ à¤°à¤šà¤¨à¤¾ à¤•à¤°à¤µà¤¾à¤¨à¥€ à¤¹à¥€ à¤¹à¥‹ à¤¤à¥‹ à¤•à¥à¤› à¤à¤¸à¥€ à¤•à¤°à¤µà¤¾à¤“, à¤œà¥‹ à¤†à¤œà¤¤à¤• à¤¹à¥à¤ˆ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¥¤ à¤µà¤¹ à¤à¤• à¤¨à¤µà¥€à¤¨ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¥¤
à¤…à¤ªà¤¨à¥‡ à¤…à¤¨à¥à¤°à¥‹à¤§à¤®à¥‡à¤‚ à¤”à¤° à¤…à¤§à¤¿à¤• à¤®à¤¾à¤§à¥à¤°à¥à¤¯ à¤˜à¥‹à¤²à¤¤à¥‡ à¤¹à¥à¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤•à¤¹à¤¾-à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤•à¥‡ ! à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤­à¤¾à¤µà¤¨à¤¾à¤•à¥‡ à¤…à¤¨à¥à¤°à¥‚à¤ª à¤¹à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¤—à¥€à¥¤
à¤ªà¥à¤°à¤¾à¤£à¤¾à¤§à¤¿à¤• à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤œà¤¬ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤­à¤¾à¤µà¤¨à¤¾à¤•à¤¾ à¤…à¤¨à¥à¤®à¥‹à¤¦à¤¨ à¤•à¤° à¤¦à¤¿à¤¯à¤¾, à¤¤à¤¬ à¤”à¤° à¤•à¥à¤› à¤•à¤¹à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤°à¤¹ à¤¹à¥€ à¤•à¥à¤¯à¤¾ à¤—à¤¯à¤¾ à¤¥à¤¾à¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤‰à¤¸ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤•à¥€ à¤…à¤µà¤§à¤¿à¤®à¥‡à¤‚ à¤•à¤¾à¤µà¥à¤¯à¤•à¤¾ à¤¸à¥ƒà¤œà¤¨ à¤†à¤°à¤®à¥à¤­ à¤¹à¥‹ à¤—à¤¯à¤¾à¥¤ à¤®à¥Œà¤¨à¤µà¥à¤°à¤¤à¤•à¥€ à¤•à¤ à¥‹à¤°à¤¤à¤¾à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤•à¤¾à¤—à¤œ-à¤•à¤²à¤® à¤®à¤¾à¤à¤—à¤¾ à¤œà¤¾à¤¨à¤¾ à¤¸à¤®à¥à¤­à¤µ à¤¨à¤¹à¥€à¤‚ à¤¥à¤¾ à¤”à¤° à¤œà¥‹-à¤œà¥‹ à¤¦à¤¿à¤µà¥à¤¯ à¤²à¥€à¤²à¤¾à¤à¤ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿-à¤ªà¤¥à¤ªà¤° à¤†à¤¤à¥€à¤‚, à¤‰à¤¨à¤•à¥€ à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤•à¥‡ à¤•à¥à¤°à¤®à¤•à¤¾ à¤¶à¥à¤­à¤¾à¤°à¤®à¥à¤­ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾-à¤®à¤¨à¥à¤¦à¤¿à¤°à¤¸à¥‡ à¤¹à¥€ à¤¹à¥‹ à¤šà¥à¤•à¤¾ à¤¥à¤¾ à¤…à¤¤à¤ƒ à¤•à¤ˆ à¤µà¤°à¥à¤·à¥‹à¤‚à¤¤à¤• à¤¯à¤¹ à¤•à¤¾à¤µà¥à¤¯ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤¸à¥à¤®à¥ƒà¤¤à¤¿à¤®à¥‡à¤‚ à¤¸à¥à¤°à¤•à¥à¤·à¤¿à¤¤ à¤°à¤¹à¤¾à¥¤ à¤œà¤¬ à¤¯à¤¹ à¤µà¥à¤°à¤¤ à¤¶à¤¿à¤¥à¤¿à¤² à¤¹à¥à¤†, à¤¤à¤¬ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤‡à¤¸à¥‡ à¤†à¤¦à¤°à¤£à¥€à¤¯à¤¾ à¤¬à¤¾à¤ˆ (à¤¶à¥à¤°à¥€à¤¸à¤¾à¤µà¤¿à¤¤à¥à¤°à¥€ à¤¬à¤¾à¤ˆ à¤«à¥‹à¤—à¤²à¤¾) à¤•à¥‹ à¤²à¤¿à¤–à¤µà¤¾à¤¯à¤¾à¥¤ à¤¬à¤¾à¤¬à¤¾ à¤¬à¥‹à¤²à¤¤à¥‡ à¤œà¤¾à¤¤à¥‡ à¤¥à¥‡ à¤¤à¤¥à¤¾ à¤¬à¤¾à¤ˆ à¤²à¤¿à¤–à¤¤à¥€ à¤œà¤¾à¤¤à¥€ à¤¥à¥€à¥¤ à¤‡à¤¸ à¤²à¥‡à¤–à¤¨ à¤•à¤¾à¤°à¥à¤¯à¤®à¥‡à¤‚ à¤¬à¤¾à¤ˆà¤•à¥‡ à¤…à¤¤à¤¿à¤°à¤¿à¤•à¥à¤¤ à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¨à¥‡ à¤­à¥€ à¤¸à¤¹à¤¯à¥‹à¤— à¤¦à¤¿à¤¯à¤¾à¥¤ à¤®à¥Œà¤¨à¤µà¥à¤°à¤¤à¤•à¥‡ à¤¶à¤¿à¤¥à¤¿à¤² à¤¹à¥‹à¤¨à¥‡à¤ªà¤° à¤­à¥€ à¤•à¤¾à¤µà¥à¤¯-à¤¸à¥ƒà¤œà¤¨à¤®à¥‡à¤‚ à¤µà¤¿à¤°à¤¾à¤® à¤¤à¥‹ à¤†à¤¯à¤¾ à¤¨à¤¹à¥€à¤‚à¥¤ à¤…à¤¨à¥à¤¯ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥‡ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤•à¤¾ à¤•à¥à¤°à¤® à¤šà¤²à¤¤à¤¾ à¤°à¤¹à¤¾à¥¤ à¤¯à¤¹ à¤†à¤µà¤¶à¥à¤¯à¤• à¤¨à¤¹à¥€à¤‚ à¤•à¤¿ à¤œà¤¿à¤¸ à¤¸à¤®à¤¯ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾ à¤¹à¥‹ à¤°à¤¹à¥€ à¤¹à¥‹, à¤‰à¤¸ à¤¸à¤®à¤¯ à¤¬à¤¾à¤ˆ à¤…à¤¥à¤µà¤¾ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤ à¤°à¤¹à¥‡à¤‚à¥¤ à¤…à¤¨à¥‡à¤•à¥‹à¤‚ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹ à¤œà¤¾à¤¤à¥€ à¤”à¤° à¤œà¤¬ à¤¬à¤¾à¤ˆ à¤†à¤¤à¥€, à¤¤à¤¬ à¤«à¤¿à¤° à¤¬à¤¾à¤¬à¤¾ à¤¬à¤¾à¤ˆà¤•à¥‹ à¤²à¤¿à¤–à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤•à¤¹à¤¤à¥‡à¥¤ à¤‡à¤¸à¤¸à¥‡ à¤…à¤¨à¥‡à¤• à¤¬à¤¾à¤° à¤à¤¸à¤¾ à¤­à¥€ à¤¹à¥à¤† à¤¹à¥ˆ à¤•à¤¿ à¤‰à¤¨ à¤µà¤¿à¤µà¤¿à¤§ à¤•à¤¾à¤µà¥à¤¯à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¿à¤¤ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¤¾à¤ à¤µà¤¿à¤¸à¥à¤®à¥ƒà¤¤ à¤¹à¥‹ à¤œà¤¾à¤¤à¥€ à¤”à¤° à¤œà¥‹ à¤µà¤¿à¤¸à¥à¤®à¥ƒà¤¤ à¤¹à¥‹ à¤—à¤¯à¥€à¤‚, à¤µà¥‡ à¤¸à¤¦à¤¾à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤µà¤¿à¤²à¥à¤ªà¥à¤¤ à¤¹à¥‹ à¤—à¤¯à¥€à¤‚à¥¤
à¤—à¥à¤¯à¤¾à¤°à¤¹ à¤¶à¤¤à¤•à¥‹à¤‚ à¤µà¤¾à¤²à¤¾ à¤¯à¤¹ à¤•à¤¾à¤µà¥à¤¯ à¤•à¤¹à¤²à¤¾à¤¯à¤¾ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®'à¥¤ à¤‡à¤¸ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤®à¥‡à¤‚ 'à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤¶à¤¬à¥à¤¦ à¤¸à¤®à¥à¤¬à¥‹à¤§à¤¨à¤¾à¤¤à¥à¤®à¤• à¤¶à¤¬à¥à¤¦ à¤¹à¥ˆà¥¤ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤®à¥‡à¤‚ à¤¯à¤¹ à¤¸à¤®à¥à¤¬à¥‹à¤§à¤¨ à¤‡à¤¸à¤²à¤¿à¤¯à¥‡ à¤¹à¥ˆ à¤•à¤¿ à¤…à¤ªà¤¨à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¥‹ à¤¸à¥à¤¨à¤¾à¤¤à¥‡ à¤¹à¥à¤ à¤¹à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤ªà¥à¤°à¤¾à¤£à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¹à¥‹ à¤°à¤¹à¥€ à¤¹à¥ˆà¥¤ à¤¯à¤¹ à¤•à¤¾à¤µà¥à¤¯ à¤†à¤¦à¥à¤¯à¤¨à¥à¤¤ à¤¤à¥à¤•à¤¾à¤¨à¥à¤¤ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤ à¤°à¤šà¤¨à¤¾à¤•à¥‡ à¤ªà¥à¤°à¤µà¤¾à¤¹à¤®à¥‡à¤‚ à¤¤à¥à¤• à¤¬à¥ˆà¤  à¤—à¤¯à¥€ à¤¤à¥‹ à¤‰à¤¤à¥à¤¤à¤®, à¤…à¤¨à¥à¤¯à¤¥à¤¾ à¤¤à¥à¤• à¤¬à¥ˆà¤ à¤¾à¤¨à¥‡à¤•à¤¾ à¤†à¤—à¥à¤°à¤¹ à¤®à¤¨à¤®à¥‡à¤‚ à¤¨à¤¹à¥€à¤‚ à¤¥à¤¾à¥¤ à¤°à¤šà¤¿à¤¤ à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤¨ à¤¤à¥‹ à¤¸à¤‚à¤¶à¥‹à¤§à¤¨ à¤•à¤°à¤¨à¤¾ à¤¥à¤¾ à¤”à¤° à¤¨ à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨à¥¤ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤®à¥‡à¤‚ à¤œà¥‹ à¤­à¤¾à¤µ à¤¢à¤² à¤—à¤¯à¥‡ à¤”à¤° à¤œà¤¿à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤¢à¤² à¤—à¤¯à¥‡, à¤µà¤¹à¥€ à¤¸à¥à¤µà¥€à¤•à¤¾à¤°à¥à¤¯ à¤¥à¤¾à¥¤ à¤¹à¤¾à¤, à¤à¤• à¤¸à¥à¤¥à¤¾à¤¨à¤ªà¤° à¤à¤• à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¯à¤¾, à¤…à¤ªà¤¿à¤¤à¥ à¤¬à¤¾à¤¬à¤¾à¤¸à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤•à¤°à¤µà¤¾à¤¯à¤¾à¥¤ à¤œà¤¬ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¤¤à¥€ à¤¥à¥€ à¤¤à¥‹ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¸à¤¾à¤®à¤¨à¥‡ à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤ à¤°à¤¹à¤¤à¥‡ à¤¥à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¥¤ à¤ªà¥à¤°à¤¥à¤® à¤¶à¤¤à¤•à¤•à¥‡ à¤†à¤°à¤®à¥à¤­à¤®à¥‡à¤‚ à¤à¤• à¤¸à¥à¤¥à¤¾à¤¨à¤ªà¤° à¤à¤• à¤ªà¤‚à¤•à¥à¤¤à¤¿ à¤†à¤¯à¥€ à¤¹à¥ˆ 'à¤—à¥‹à¤¬à¤° à¤®à¤¿à¤Ÿà¥à¤Ÿà¥€à¤¸à¥‡ à¤¯à¤¦à¥à¤¯à¤ªà¤¿ à¤¥à¥€ à¤…à¤µà¤¨à¥€ à¤²à¥€à¤ªà¥€ à¤ªà¥‹à¤¤à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®'à¥¤ à¤ªà¤¹à¤²à¥‡ 'à¤—à¥‹à¤¬à¤°' à¤¶à¤¬à¥à¤¦ à¤¨à¤¹à¥€à¤‚ à¤¥à¤¾à¥¤ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤°à¤šà¤¨à¤¾ à¤•à¤°à¤¤à¥‡ à¤¸à¤®à¤¯ à¤ªà¥à¤°à¤¯à¥‹à¤— à¤•à¤¿à¤¯à¤¾ à¤¥à¤¾ 'à¤—à¥ˆà¤°à¤¿à¤•' à¤¶à¤¬à¥à¤¦à¥¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤•à¤¹à¤¾- 'à¤—à¥ˆà¤°à¤¿à¤•' à¤¶à¤¬à¥à¤¦à¤•à¤¾ à¤ªà¥à¤°à¤¯à¥‹à¤— à¤®à¤¤ à¤•à¤°à¥‹à¥¤
à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¤¾ à¤à¤¸à¤¾ à¤¸à¤‚à¤•à¥‡à¤¤ à¤®à¤¿à¤²à¤¤à¥‡ à¤¹à¥€ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤¶à¤¬à¥à¤¦à¤•à¤¾ à¤ªà¤°à¤¿à¤µà¤°à¥à¤¤à¤¨ à¤•à¤° à¤¦à¤¿à¤¯à¤¾ à¤”à¤° 'à¤—à¥ˆà¤°à¤¿à¤•' à¤¶à¤¬à¥à¤¦à¤•à¥‡ à¤¸à¥à¤¥à¤¾à¤¨à¤ªà¤° 'à¤—à¥‹à¤¬à¤°' à¤¶à¤¬à¥à¤¦à¤•à¤¾ à¤ªà¥à¤°à¤¯à¥‹à¤— à¤•à¤¿à¤¯à¤¾à¥¤
à¤‡à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤° à¤à¤• à¤¬à¤¾à¤° à¤à¤• à¤šà¤°à¤£à¤•à¥€ à¤ªà¥‚à¤°à¥à¤¤à¤¿ à¤¸à¥à¤µà¤¯à¤‚ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤•à¥€à¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤›à¤¨à¥à¤¦à¤•à¥‡ à¤¤à¥€à¤¨ à¤šà¤°à¤£à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹ à¤—à¤¯à¥€, à¤ªà¤° à¤šà¥Œà¤¥à¤¾ à¤šà¤°à¤£ à¤‰à¤­à¤°à¤•à¤° à¤¸à¤¾à¤®à¤¨à¥‡ à¤¨à¤¹à¥€à¤‚ à¤†à¤¯à¤¾. à¤œà¤¬ à¤ªà¤°à¥à¤¯à¤¾à¤ªà¥à¤¤ à¤µà¤¿à¤²à¤®à¥à¤¬ à¤¹à¥‹à¤¨à¥‡ à¤²à¤—à¤¾ à¤¤à¥‹ à¤šà¥Œà¤¥à¥‡ à¤šà¤°à¤£à¤•à¥‹ à¤ªà¥‚à¤°à¥à¤£ à¤•à¤°à¤¤à¥‡ à¤¹à¥à¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤¨à¥‡ à¤•à¤¹à¤¾- "à¤ªà¥à¤°à¤¾à¤£à¥‹à¤‚à¤•à¤¾ à¤¸à¥Œà¤¦à¤¾ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤•à¥à¤·à¤£à¤®à¥‡à¤‚ à¤•à¥à¤› à¤à¤¸à¥‡ à¤¹à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®"à¥¤
à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤šà¥Œà¤¥à¥‡ à¤¶à¤¤à¤•à¤®à¥‡à¤‚ à¤¯à¤¹ à¤šà¤°à¤£-à¤ªà¥‚à¤°à¥à¤¤à¤¿ à¤¹à¥ˆà¥¤ à¤à¤• à¤¬à¤¾à¤¬à¤¾ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤¬à¤¤à¤²à¤¾à¤¯à¤¾ à¤¥à¤¾-à¤¯à¤¹ à¤ªà¤‚à¤•à¥à¤¤à¤¿ à¤•à¥‹à¤ˆ à¤¸à¤¾à¤§à¤¾à¤°à¤£ à¤µà¤¾à¤•à¥à¤¯ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆ, à¤…à¤ªà¤¿à¤¤à¥ à¤®à¤¨à¥à¤¤à¥à¤° à¤¹à¥ˆà¥¤
'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤•à¥‡ à¤•à¥à¤°à¤®à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥ƒà¤‚à¤–à¤²à¤¾-à¤¬à¤¦à¥à¤§à¤¤à¤¾à¤•à¤¾ à¤…à¤­à¤¾à¤µ à¤°à¤¹à¤¾à¥¤ à¤•à¤­à¥€ à¤•à¤¿à¤¸à¥€ à¤¶à¤¤à¤•à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥à¤ˆ à¤”à¤° à¤•à¤­à¥€ à¤•à¤¿à¤¸à¥€ à¤¶à¤¤à¤•à¤•à¥€à¥¤ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤µà¤°à¥à¤£à¥à¤¯-à¤µà¤¸à¥à¤¤à¥à¤•à¥€ à¤¸à¤®à¤—à¥à¤°à¤¤à¤¾ à¤¤à¥‹ à¤§à¥à¤¯à¤¾à¤¨à¤®à¥‡à¤‚ à¤† à¤šà¥à¤•à¥€ à¤¥à¥€ à¤”à¤° à¤ªà¥‚à¤°à¥à¤µà¤¾à¤ªà¤°à¤•à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤¸à¥‡ à¤—à¥à¤¯à¤¾à¤°à¤¹à¥‹à¤‚ à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥‡ à¤•à¥à¤°à¤®à¤•à¤¾ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤­à¥€ à¤¤à¤­à¥€ à¤¹à¥‹ à¤—à¤¯à¤¾ à¤¥à¤¾, à¤œà¤¬ à¤¬à¤¿à¤¡à¤¼à¤²à¤¾ à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤¸à¤°à¥à¤µ à¤ªà¥à¤°à¤¥à¤® à¤¸à¥à¤«à¥à¤°à¤£ à¤¹à¥à¤† à¤¥à¤¾, à¤ªà¤°à¤‚à¤¤à¥ à¤à¤¸à¤¾ à¤¨à¤¹à¥€à¤‚ à¤°à¤¹à¤¾ à¤•à¤¿ à¤†à¤°à¤®à¥à¤­à¤¸à¥‡ à¤…à¤¨à¥à¤¤à¤¤à¤• à¤—à¥à¤¯à¤¾à¤°à¤¹à¥‹à¤‚ à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾, à¤à¤•à¤•à¥‡ à¤¬à¤¾à¤¦ à¤¦à¥‚à¤¸à¤°à¥‡ à¤”à¤° à¤¦à¥‚à¤¸à¤°à¥‡à¤•à¥‡ à¤¬à¤¾à¤¦ à¤¤à¥€à¤¸à¤°à¥‡ à¤¶à¤¤à¤•à¤•à¥€, à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤° à¤¸à¤­à¥€ à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤•à¥à¤°à¤®à¤¶à¤ƒ à¤¹à¥‹à¤¤à¥€ à¤šà¤²à¥€ à¤—à¤¯à¥€ à¤¹à¥‹à¥¤ à¤•à¤­à¥€ à¤ªà¤¹à¤²à¥‡ à¤¶à¤¤à¤•à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹ à¤°à¤¹à¥€ à¤¹à¥ˆ à¤¤à¥‹ à¤•à¤­à¥€ à¤¸à¤¾à¤¤à¤µà¥‡à¤‚ à¤¶à¤¤à¤•à¤•à¥€à¥¤ à¤‡à¤¸à¤•à¤¾ à¤¹à¥‡à¤¤à¥ à¤¯à¤¹à¥€ à¤¥à¤¾ à¤•à¤¿ à¤œà¤¬ à¤œà¤¿à¤¸ à¤¦à¤¿à¤µà¥à¤¯ à¤²à¥€à¤²à¤¾à¤®à¥‡à¤‚ à¤®à¤¨ à¤¨à¤¿à¤®à¤—à¥à¤¨ à¤¹à¥‹à¤¤à¤¾, à¤‰à¤¸à¥€à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤•à¤¾ à¤ªà¥à¤°à¤µà¤¾à¤¹ à¤¬à¤¹ à¤šà¤²à¤¤à¤¾à¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¨à¤¿à¤œà¥€ à¤ªà¤°à¤¿à¤•à¤° à¤¶à¥à¤°à¥€à¤­à¤—à¤¤à¤œà¥€à¤¨à¥‡ à¤¬à¤¤à¤²à¤¾à¤¯à¤¾-à¤¬à¤¾à¤¬à¤¾ à¤•à¤²à¤®-à¤¦à¤µà¤¾à¤¤-à¤•à¤¾à¤—à¤œ à¤²à¥‡à¤•à¤° à¤¥à¥‹à¤¡à¤¼à¥‡ à¤¹à¥€ à¤¬à¥ˆà¤ à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤…à¤ªà¤¨à¥€ à¤•à¥à¤Ÿà¤¿à¤¯à¤¾à¤•à¥‡ à¤à¤•à¤¾à¤¨à¥à¤¤à¤®à¥‡à¤‚ à¤¬à¥ˆà¤ à¥‡ à¤¹à¥à¤ à¤—à¥à¤¨à¤—à¥à¤¨à¤¾à¤¤à¥‡ à¤°à¤¹à¤¤à¥‡à¥¤ à¤à¤¸à¤¾ à¤²à¤—à¤¤à¤¾ à¤¥à¤¾ à¤®à¤¾à¤¨à¥‹ à¤•à¥‹à¤ˆ à¤ªà¥à¤°à¥‡à¤°à¤¿à¤¤ à¤•à¤°à¤¤à¤¾ à¤šà¤²à¤¾ à¤œà¤¾ à¤°à¤¹à¤¾ à¤¹à¥ˆ à¤”à¤° à¤µà¥‡ à¤­à¤¾à¤µ à¤¶à¤¬à¥à¤¦à¥‹à¤‚à¤®à¥‡à¤‚ à¤¢à¤²à¤¤à¥‡ à¤šà¤²à¥‡ à¤œà¤¾ à¤°à¤¹à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤œà¤¬ à¤¬à¤¾à¤ˆ à¤…à¤¥à¤µà¤¾ à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤†à¤¤à¥‡ à¤¤à¥‹ à¤¬à¤¾à¤¬à¤¾ à¤¬à¥‹à¤²à¤¤à¥‡ à¤œà¤¾à¤¤à¥‡ à¤”à¤° à¤µà¥‡ à¤²à¤¿à¤–à¤¤à¥‡ à¤œà¤¾à¤¤à¥‡à¥¤ à¤•à¤ˆ à¤¬à¤¾à¤° à¤à¤¸à¤¾ à¤­à¥€ à¤¹à¥à¤† à¤¹à¥ˆ à¤•à¤¿ à¤¬à¤¾à¤ˆ à¤²à¤¿à¤–à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤•à¤²à¤®-à¤•à¤¾à¤ªà¥€ à¤²à¥‡à¤•à¤° à¤¬à¥ˆà¤ à¥€ à¤¹à¥ˆ, à¤ªà¤° à¤¬à¤¾à¤¬à¤¾ à¤­à¤¾à¤µà¤ªà¥‚à¤°à¥à¤£ à¤²à¥€à¤²à¤¾à¤•à¥‹ à¤¦à¥‡à¤–à¤•à¤° 'à¤­à¤ à¤ªà¥à¤°à¥‡à¤® à¤¬à¤¸ à¤¬à¤¿à¤•à¤² à¤¬à¤¿à¤¸à¥‡à¤·à¥€' à¤”à¤° à¤µà¤¿à¤¹à¥à¤µà¤²à¤¾à¤§à¤¿à¤•à¥à¤¯à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤µà¥‡ à¤²à¤¿à¤–à¤µà¤¾à¤¨à¥‡à¤•à¥€ à¤¸à¥à¤¥à¤¿à¤¤à¤¿à¤®à¥‡à¤‚ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆà¥¤ à¤‡à¤§à¤° à¤¬à¤¾à¤¬à¤¾ à¤…à¤¤à¥à¤¯à¤§à¤¿à¤• à¤²à¥€à¤²à¤¾-à¤¨à¤¿à¤®à¤—à¥à¤¨ à¤¹à¥ˆà¤‚ à¤”à¤° à¤‰à¤§à¤° à¤¬à¤¾à¤ˆ à¤…à¤¤à¥à¤¯à¤§à¤¿à¤• à¤ªà¥à¤°à¤¤à¥€à¤•à¥à¤·à¤¾-à¤¨à¤¿à¤®à¤—à¥à¤¨ à¤ªà¥à¤°à¤¤à¥€à¤•à¥à¤·à¤¾ à¤•à¤°à¤¤à¥‡-à¤•à¤°à¤¤à¥‡ à¤¬à¤¾à¤ˆà¤•à¥‹ à¤•à¤­à¥€-à¤•à¤­à¥€ à¤à¤•-à¤¡à¥‡à¤¢à¤¼ à¤˜à¤‚à¤Ÿà¥‡à¤¤à¤• à¤¬à¥ˆà¤ à¥‡ à¤°à¤¹à¤¨à¤¾ à¤ªà¤¡à¤¼à¤¾ à¤”à¤° à¤•à¤­à¥€-à¤•à¤­à¥€ à¤ªà¤°à¤¿à¤¸à¥à¤¥à¤¿à¤¤à¤¿ à¤¯à¤¹à¤¾à¤à¤¤à¤• à¤†à¤¤à¥€ à¤•à¤¿ à¤‡à¤¸à¤¸à¥‡ à¤­à¥€ à¤²à¤®à¥à¤¬à¥€ à¤¬à¥ˆà¤ à¤•à¤•à¥‡ à¤¬à¤¾à¤¦ à¤²à¤¿à¤–à¤¨à¥‡-à¤²à¤¿à¤–à¤µà¤¾à¤¨à¥‡à¤•à¥‡ à¤•à¥à¤°à¤®à¤•à¤¾ à¤‰à¤ªà¤•à¥à¤°à¤® à¤¬à¤¨ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤ªà¤¾à¤¤à¤¾ à¤¥à¤¾à¥¤ à¤²à¥€à¤²à¤¾-à¤¨à¤¿à¤®à¤—à¥à¤¨à¤¤à¤¾à¤•à¥€ à¤—à¤¹à¤°à¤¾à¤ˆà¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤¦à¥‡à¤–à¤•à¤° à¤¬à¤¾à¤ˆ à¤²à¥‡à¤–à¤¨-à¤•à¤¾à¤°à¥à¤¯ à¤…à¤—à¤²à¥‡ à¤¦à¤¿à¤¨à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤¸à¥à¤¥à¤—à¤¿à¤¤ à¤•à¤° à¤¦à¥‡à¤¤à¥€à¥¤
à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤¨à¤¨à¤¿à¤¨à¥à¤¦à¤¨à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¤¾ à¤œà¥‹ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤‰à¤­à¤°à¤•à¤° à¤¸à¤¾à¤®à¤¨à¥‡ à¤†à¤¯à¤¾ à¤¹à¥ˆ, à¤µà¤¹ à¤µà¤¸à¥à¤¤à¥à¤¤à¤ƒ à¤…à¤­à¥‚à¤¤à¤ªà¥‚à¤°à¥à¤µ à¤”à¤° à¤…à¤¨à¥‚à¤ à¤¾ à¤¹à¥ˆà¥¤ à¤°à¤¸à¤•à¤¾ à¤¸à¤¾à¤—à¤° à¤¤à¥‹ à¤…à¤¨à¤¨à¥à¤¤ à¤”à¤° à¤…à¤—à¤¾à¤§ à¤¹à¥ˆ à¤”à¤° à¤‰à¤¸à¤®à¥‡à¤‚ à¤…à¤¨à¥‡à¤• à¤²à¤¹à¤°à¥‡à¤‚ à¤‰à¤ à¤¤à¥€ à¤°à¤¹à¤¤à¥€ à¤¹à¥ˆà¤‚à¥¤ à¤‡à¤¨ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¥€ à¤¸à¤‚à¤–à¥à¤¯à¤¾ à¤…à¤—à¤£à¥à¤¯ à¤¹à¥ˆ à¤”à¤° à¤‡à¤¨à¤•à¥€ à¤Šà¤à¤šà¤¾à¤ˆ à¤­à¥€ à¤­à¤¿à¤¨à¥à¤¨-à¤­à¤¿à¤¨à¥à¤¨à¥¤ à¤µà¤¿à¤­à¤¿à¤¨à¥à¤¨ à¤•à¤¾à¤²à¤•à¥‡ à¤µà¤¿à¤­à¤¿à¤¨à¥à¤¨ à¤­à¤•à¥à¤¤ à¤•à¤µà¤¿à¤¯à¥‹à¤‚à¤¨à¥‡ à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤•à¥€ à¤¸à¤°à¤¸ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¤¾ à¤¦à¤°à¥à¤¶à¤¨ à¤•à¤¿à¤¯à¤¾ à¤”à¤° à¤¦à¤°à¥à¤¶à¤¨à¤•à¥‡ à¤…à¤¨à¥à¤°à¥‚à¤ª à¤¹à¥€ à¤‰à¤¨ à¤­à¤•à¥à¤¤ à¤•à¤µà¤¿à¤¯à¥‹à¤‚ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤‰à¤¨ à¤¸à¤°à¤² à¤²à¤¹à¤°à¥‹à¤‚à¤•à¤¾ à¤µà¤°à¥à¤£à¤¨ à¤¹à¥à¤†à¥¤ à¤¯à¥‡ à¤¸à¤¾à¤°à¥‡ à¤µà¤°à¥à¤£à¤¨ à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤•à¥€ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¥‡ à¤¹à¥€ à¤¹à¥ˆ à¤”à¤° à¤¨à¤¿à¤¤à¤¾à¤¨à¥à¤¤ à¤¸à¤¤à¥à¤¯ à¤¹à¥ˆà¥¤ à¤‡à¤¸à¥€à¤¸à¥‡ à¤à¤• à¤¤à¤¥à¥à¤¯ à¤”à¤° à¤œà¥à¤¡à¤¼à¤¾ à¤¹à¥à¤† à¤¹à¥ˆà¥¤ à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤®à¥‡à¤‚ à¤à¤•-à¤¸à¥‡-à¤à¤• à¤Šà¤à¤šà¥€ à¤²à¤¹à¤°à¥‡à¤‚ à¤‰à¤ à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤”à¤° à¤‡à¤¨à¤•à¤¾ à¤µà¤°à¥à¤£à¤¨ à¤²à¥€à¤²à¤¾-à¤•à¤¾à¤µà¥à¤¯à¥‹à¤‚à¤®à¥‡à¤‚ à¤¹à¥à¤† à¤¹à¥ˆà¥¤ à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤•à¥€ à¤œà¤¿à¤¨ à¤Šà¤à¤šà¥€-à¤Šà¤à¤šà¥€ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¤¾ à¤µà¤°à¥à¤£à¤¨ à¤† à¤šà¥à¤•à¤¾ à¤¹à¥ˆ, à¤…à¤¬ à¤¯à¤¹ à¤¤à¥‹ à¤¨à¤¹à¥€à¤‚ à¤•à¤¹à¤¾ à¤œà¤¾ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤‰à¤¨ à¤Šà¤à¤šà¥€ à¤²à¤¹à¤°à¥‹à¤‚à¤¸à¥‡ à¤”à¤° à¤…à¤§à¤¿à¤• à¤Šà¤à¤šà¥€ à¤²à¤¹à¤° à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤®à¥‡à¤‚ à¤‰à¤ à¥‡à¤—à¥€ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤°à¤¸-à¤¸à¤¾à¤—à¤°à¤•à¥‡ à¤‰à¤¦à¥à¤µà¥‡à¤²à¤¨ à¤”à¤° à¤‰à¤šà¥à¤›à¤²à¤¨à¤•à¥‹ à¤¸à¥€à¤®à¤¾à¤¬à¤¦à¥à¤§ à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¯à¤¾ à¤œà¤¾ à¤¸à¤•à¤¤à¤¾à¥¤ à¤ªà¤¤à¤¾ à¤¨à¤¹à¥€à¤‚, à¤°à¤¸-à¤¸à¤¾à¤—à¤° à¤•à¤¬ à¤‡à¤¤à¤¨à¤¾ à¤…à¤§à¤¿à¤• à¤‰à¤šà¥à¤›à¤¿à¤²à¤¤ à¤¹à¥‹ à¤‰à¤ à¥‡ à¤•à¤¿ à¤¨à¤µà¥€à¤¨ à¤²à¤¹à¤°à¤•à¥€ à¤Šà¤à¤šà¥€ à¤ªà¤¿à¤›à¤²à¥€ à¤¸à¤¾à¤°à¥€ à¤Šà¤à¤šà¥€ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¥‹ à¤ªà¤¾à¤° à¤•à¤° à¤œà¤¾à¤¯à¥‡à¥¤ à¤à¤¸à¤¾ à¤²à¤—à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¿ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤¸à¤¾à¤¥ à¤¯à¤¹ à¤¤à¤¥à¥à¤¯ à¤®à¥‚à¤°à¥à¤¤ à¤¹à¥‹ à¤‰à¤ à¤¾ à¤¹à¥ˆà¥¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥€ à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤à¤¿à¤®à¥‡à¤‚ à¤œà¤¿à¤¸ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¤‚, à¤‰à¤¸ à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤¯à¤¹ à¤¸à¤¤à¥à¤¯ à¤¸à¤®à¤¨à¥à¤µà¤¿à¤¤ à¤¹à¥‹ à¤‰à¤ à¥‡ à¤¤à¥‹ à¤•à¥à¤¯à¤¾ à¤†à¤¶à¥à¤šà¤°à¥à¤¯ à¤•à¤¿à¤¯à¤¾ à¤œà¤¾à¤¯? à¤²à¥€à¤²à¤¾à¤•à¥‡ à¤ªà¥à¤°à¤µà¤¾à¤¹à¤•à¤¾ à¤²à¤¾à¤²à¤¿à¤¤à¥à¤¯, à¤¸à¤‚à¤µà¤¾à¤¦à¤®à¥‡à¤‚ à¤¦à¥ˆà¤¨à¥à¤¯à¤•à¤¾ à¤®à¤¾à¤§à¥à¤°à¥à¤¯, à¤­à¤¾à¤µà¥‹à¤‚à¤•à¥‡ à¤¦à¥à¤µà¤¨à¥à¤¦à¥à¤µà¤•à¥€ à¤ªà¤°à¤¾à¤•à¤¾à¤·à¥à¤ à¤¾, à¤…à¤¨à¥à¤¤à¤°à¤•à¥€ à¤µà¥à¤¯à¤¥à¤¾à¤•à¥€ à¤ªà¥à¤°à¤–à¤°à¤¤à¤¾, à¤¹à¥ƒà¤¦à¤¯à¤•à¥‡ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¥€ à¤•à¥‹à¤®à¤²à¤¤à¤¾, à¤¸à¥à¤µà¤¸à¥à¤–à¤•à¥€ à¤µà¤¾à¤žà¥à¤›à¤¾à¤•à¤¾ à¤…à¤­à¤¾à¤µ, à¤¸à¥à¤µà¤¾à¤°à¥à¤¥-à¤¶à¥‚à¤¨à¥à¤¯ à¤¸à¤®à¤°à¥à¤ªà¤£à¤•à¥€ à¤…à¤¸à¥€à¤®à¤¤à¤¾, à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¾à¤¨-à¤¨à¤¿à¤°à¤ªà¥‡à¤•à¥à¤· à¤ªà¥à¤¯à¤¾à¤°à¤•à¥€ à¤ªà¥à¤°à¤¬à¤²à¤¤à¤¾, à¤†à¤¤à¥à¤®à¤¾à¤°à¥à¤ªà¤£ à¤œà¤¨à¤¿à¤¤ à¤µà¤¿à¤¨à¤¯à¤•à¥€ à¤…à¤—à¤¾à¤§à¤¤à¤¾, à¤­à¤¾à¤µà¤¾à¤µà¥‡à¤—à¤•à¥€ à¤…à¤¤à¤¿à¤¶à¤¯à¤¤à¤¾à¤®à¥‡à¤‚ à¤†à¤¤à¥à¤®-à¤µà¤¿à¤¸à¥à¤®à¥ƒà¤¤à¤¿, à¤ªà¥à¤°à¥€à¤¤à¤¿à¤®à¥‡à¤‚ à¤¸à¥à¤µà¤¯à¤‚à¤•à¥€ à¤†à¤¹à¥à¤¤à¤¿, à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥€ à¤•à¥à¤› à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤¯à¥‹à¤‚à¤®à¥‡à¤‚ à¤¦à¥‡à¤–à¤¨à¥‡à¤ªà¤° à¤¯à¤¹à¥€ à¤²à¤—à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤¯à¤¹ à¤•à¤¾à¤µà¥à¤¯ à¤µà¤¸à¥à¤¤à¥à¤¤à¤ƒ à¤²à¥‹à¤•à¥‹à¤¤à¥à¤¤à¤° à¤¹à¥ˆà¥¤

à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤•à¤¾à¤µà¥à¤¯à¤•à¥‡ à¤à¤• à¤ªà¥à¤°à¤¸à¤‚à¤—à¤•à¤¾ à¤­à¤¾à¤µ-à¤—à¤¾à¤®à¥à¤­à¥€à¤°à¥à¤¯ à¤µà¤¸à¥à¤¤à¥à¤¤à¤ƒ à¤†à¤¸à¥à¤µà¤¾à¤¦à¤¨à¥€à¤¯ à¤¹à¥ˆà¥¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥‡ à¤¦à¥‚à¤¤ à¤¶à¥à¤°à¥€à¤‰à¤¦à¥à¤§à¤µ à¤®à¤¥à¥à¤°à¤¾à¤¸à¥‡ à¤µà¥à¤°à¤œà¤®à¥‡à¤‚ à¤†à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤”à¤° à¤†à¤•à¤° à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤¨à¤¨à¥à¤¦à¤¿à¤¨à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤­à¤¾à¤µà¤®à¤¯à¥€ à¤¸à¥à¤¥à¤¿à¤¤à¤¿à¤•à¥‹ à¤¦à¥‡à¤–à¤•à¤° à¤‰à¤¨à¤•à¥‡ à¤¶à¥à¤°à¥€à¤šà¤°à¤£à¥‹à¤‚à¤•à¥‹ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤•à¤°à¤•à¥‡ à¤ªà¥à¤°à¤£à¤¾à¤® à¤•à¤°à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤¶à¥à¤°à¥€à¤‰à¤¦à¥à¤§à¤µà¤œà¥€à¤•à¥‡ à¤œà¥à¤žà¤¾à¤¨à¤•à¥€ à¤—à¤°à¤¿à¤®à¤¾à¤•à¥‹ à¤¤à¥‹ à¤—à¥‹à¤ªà¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤­à¤¾à¤µ-à¤¸à¤¾à¤—à¤°à¤•à¥€
à¤²à¤¹à¤°à¥‡à¤‚ à¤¬à¤¹à¥à¤¤ à¤ªà¤¹à¤²à¥‡ à¤¹à¥€ à¤¬à¤¹à¤¾ à¤²à¥‡ à¤—à¤¯à¥€ à¤¥à¥€à¤‚à¥¤ à¤œà¥à¤¯à¥‹à¤‚ à¤¹à¥€ à¤¶à¥à¤°à¥€à¤‰à¤¦à¥à¤§à¤µà¤œà¥€ à¤ªà¥à¤°à¤£à¤¾à¤® à¤•à¤°à¤¨à¥‡à¤•à¥€ à¤‡à¤šà¥à¤›à¤¾à¤¸à¥‡ à¤‰à¤ à¥‡, à¤ªà¥à¤°à¥€à¤¤à¤¿-à¤ªà¥à¤°à¤¤à¤¿à¤®à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡ à¤¶à¥à¤°à¥€à¤šà¤°à¤£à¥‹à¤‚à¤•à¥‹ à¤¸à¤‚à¤•à¥à¤šà¤¿à¤¤ à¤•à¤° à¤²à¤¿à¤¯à¤¾à¥¤ à¤¶à¥à¤¯à¤¾à¤®-à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤‰à¤¦à¥à¤§à¤µà¤œà¥€à¤•à¥‹ à¤šà¤°à¤£ à¤¸à¥à¤ªà¤°à¥à¤¶à¤¸à¥‡ à¤µà¤¿à¤°à¤¤ à¤•à¤°à¤¨à¤¾ à¤šà¤¾à¤¹à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤”à¤° à¤¶à¥à¤°à¥€à¤®à¤¦à¥à¤­à¤¾à¤—à¤µà¤¤à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤œà¥€ à¤•à¤¹à¤¤à¥€ à¤¹à¥ˆà¤‚- 'à¤®à¤§à¥à¤ª à¤®à¤¾ à¤¸à¥à¤ªà¥ƒà¤¶à¤¾à¤™à¥à¤˜à¥à¤°à¤¿'à¥¤ à¤®à¥‡à¤°à¥‡ à¤šà¤°à¤£à¥‹à¤‚à¤•à¤¾ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤®à¤¤ à¤•à¤°à¥‹à¥¤

à¤‡à¤¸à¥€ à¤ªà¥à¤°à¤¸à¤‚à¤—à¤•à¤¾ à¤µà¤°à¥à¤£à¤¨ à¤•à¤°à¤¤à¥‡ à¤¹à¥à¤ à¤­à¤¿à¤¨à¥à¤¨-à¤­à¤¿à¤¨à¥à¤¨ à¤­à¤•à¥à¤¤ à¤•à¤¿à¤µà¤¯à¥‹à¤‚à¤¨à¥‡ à¤…à¤ªà¤¨à¥‡-à¤…à¤ªà¤¨à¥‡ à¤¢à¤‚à¤—à¤¸à¥‡ à¤­à¤¾à¤µ-à¤ªà¤²à¥à¤²à¤µà¤¨ à¤•à¤¿à¤¯à¤¾ à¤¹à¥ˆà¥¤ à¤­à¤•à¥à¤¤ à¤¹à¥ƒà¤¦à¤¯ à¤¶à¥à¤°à¥€à¤¸à¥‚à¤°à¤¦à¤¾à¤¸à¤œà¥€à¤•à¥€ à¤…à¤¨à¥à¤ªà¤® à¤•à¥ƒà¤¤à¤¿ à¤¸à¥‚à¤°à¤¸à¤¾à¤—à¤°à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤‰à¤¦à¥à¤§à¤µà¤œà¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿ à¤•à¤Ÿà¥‚à¤•à¥à¤¤à¤¿ à¤¹à¥ˆ-
à¤®à¤§à¥à¤•à¤° à¤¸à¥à¤¯à¤¾à¤® à¤•à¤¹à¤¾ à¤¹à¤¿à¤¤ à¤œà¤¾à¤¨à¥ˆà¥¤
à¤•à¥‹à¤Š  à¤ªà¥à¤°à¥€à¤¤à¤¿  à¤•à¤°à¥‡à¤‚  à¤•à¥ˆà¤¸à¥‡à¤¹à¥‚   à¤µà¤¹  à¤…à¤ªà¤¨à¥‹  à¤—à¥à¤¨  à¤ à¤¾à¤¨à¥ˆ à¥¥
à¤­à¤à¤µà¤° à¤­à¥à¤œà¤‚à¤— à¤•à¤¾à¤• à¤•à¥‹à¤•à¤¿à¤² à¤•à¥‹ à¤•à¤¬à¤¿à¤—à¤¨ à¤•à¤ªà¤Ÿ à¤¬à¤–à¤¾à¤¨à¥ˆà¥¤
'à¤¸à¥‚à¤°à¤¦à¤¾à¤¸'  à¤¸à¤°à¤¬à¤¸  à¤œà¥Œ  à¤¦à¥€à¤œà¥ˆ,  à¤•à¤¾à¤°à¥Œ à¤•à¥ƒà¤¤à¤¹à¤¿à¤‚ à¤¨ à¤®à¤¾à¤¨à¥ˆ à¥¥
*****
à¤®à¥€à¤ à¥‡  à¤¬à¤šà¤¨   à¤¸à¥à¤¹à¤¾à¤   à¤¬à¥‹à¤²à¤¤,    à¤…à¤‚à¤¤à¤°    à¤œà¤¾à¤°à¤¨à¤¹à¤¾à¤°à¥¤
à¤­à¤à¤µà¤° à¤•à¥à¤°à¤‚à¤— à¤•à¤¾à¤• à¤…à¤°à¥ à¤•à¥‹à¤•à¤¿à¤², à¤•à¤ªà¤Ÿà¤¿à¤¨ à¤•à¥€ à¤šà¤Ÿà¤¸à¤¾à¤° à¥¥
*****
à¤®à¤§à¥à¤ª     à¤¤à¥à¤®     à¤¦à¥‡à¤–à¤¿à¤¯à¤¤      à¤¹à¥‹  à¤…à¤¤à¤¿    à¤•à¤¾à¤°à¥‡à¥¤
à¤•à¤ªà¤Ÿà¥€ à¤•à¥à¤Ÿà¤¿à¤² à¤¨à¤¿à¤ à¥à¤° à¤¨à¤¿à¤°à¤®à¥‹à¤¹à¥€, à¤¦à¥à¤– à¤¦à¥ˆ à¤¦à¥‚à¤°à¤¿ à¤¸à¤¿à¤§à¤¾à¤°à¥‡ à¥¥
*****
à¤à¤¸à¥€ à¤¹à¥€ à¤•à¤¾à¤°à¥ˆà¤¨ à¤•à¥€ à¤°à¥€à¤¤à¤¿à¥¤
à¤®à¤¨ à¤¦à¥‡ à¤¸à¤°à¤¬à¤¸ à¤¹à¤°à¤¤ à¤ªà¤°à¤¾à¤¯à¥Œ, à¤•à¤°à¤¤ à¤•à¤ªà¤Ÿ à¤•à¥€ à¤ªà¥à¤°à¥€à¤¤à¤¿ à¥¥
*****
à¤•à¤¾à¤¹à¥‡à¤‚  à¤šà¤°à¤¨  à¤›à¥à¤µà¤¤  à¤°à¤¸ à¤²à¤‚à¤ªà¤Ÿ, à¤¹à¤® à¤†à¤—à¥‡ à¤¯à¤¹ à¤—à¥€à¤¤à¥¤
'à¤¸à¥‚à¤°' à¤‡à¤¤à¥ˆ  à¤¸à¥Œ  à¤¬à¤¾à¤°  à¤•à¤¹à¤¾ à¤¹à¥ˆ, à¤œà¥‹ à¤ªà¥ˆ à¤¤à¥à¤°à¤¿à¤—à¥à¤¨ à¤…à¤¤à¥€à¤¤ à¥¥

'à¤¸à¥‚à¤° à¤¸à¤¾à¤—à¤°' à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤‰à¤¦à¥à¤§à¤µà¤œà¥€à¤¸à¥‡ à¤­à¥à¤°à¤®à¤°à¤•à¥‡ à¤®à¤¿à¤¸à¤¸à¥‡ à¤¯à¤¹à¥€ à¤•à¤¹à¤¾ à¤—à¤¯à¤¾ à¤¹à¥ˆ- à¤¹à¥‡ à¤¦à¥‚à¤¤ ! à¤¤à¥à¤® à¤®à¥‡à¤°à¥‡ à¤šà¤°à¤£à¥‹à¤‚à¤•à¤¾ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤®à¤¤ à¤•à¤°à¥‹, à¤‡à¤¸à¥€à¤²à¤¿à¤¯à¥‡ à¤•à¤¿ à¤¹à¤® à¤¸à¤°à¤²à¤¾à¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤ªà¥à¤°à¥€à¤¤à¤¿ à¤•à¤ªà¤Ÿà¤ªà¥‚à¤°à¥à¤£ à¤¹à¥ˆà¥¤ à¤¤à¥à¤® à¤•à¤ªà¤Ÿà¥€ à¤¹à¥‹, à¤•à¥à¤Ÿà¤¿à¤² à¤¹à¥‹, à¤…à¤•à¥ƒà¤¤à¤œà¥à¤ž à¤¹à¥‹, à¤µà¤‚à¤šà¤• à¤¹à¥‹, à¤²à¥‹à¤²à¥à¤ª à¤¹à¥‹, à¤²à¤‚à¤ªà¤Ÿ à¤¹à¥‹, à¤…à¤¤à¤ƒ à¤¦à¥‚à¤° à¤¹à¥€ à¤°à¤¹à¥‹à¥¤ à¤¤à¥à¤® à¤®à¥‡à¤°à¥‡ à¤šà¤°à¤£à¥‹à¤‚à¤•à¤¾ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤®à¤¤ à¤•à¤°à¥‹à¥¤
'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤­à¤¿à¤¨à¥à¤¨ à¤¹à¥ˆà¥¤ à¤®à¤¹à¤¾à¤¸à¤¦à¤¾à¤¶à¤¯à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤­à¥à¤°à¤®à¤°à¤•à¥‹ à¤‰à¤ªà¤¾à¤²à¤®à¥à¤­ à¤¨à¤¹à¥€à¤‚ à¤¸à¥à¤¨à¤¾à¤¤à¥€, à¤…à¤ªà¤¿à¤¤à¥ à¤…à¤ªà¤¨à¥€ à¤‰à¤²à¤à¤¨à¤•à¤¾ à¤¨à¤¿à¤µà¥‡à¤¦à¤¨ à¤•à¤°à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤šà¤°à¤£-à¤¸à¥à¤ªà¤°à¥à¤¶à¤•à¥€ à¤…à¤­à¤¿à¤²à¤¾à¤·à¤¾à¤•à¥€ à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥€ à¤•à¥ƒà¤·à¥à¤£à¤ªà¥à¤°à¥‡à¤®à¤®à¤¯à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤¦à¥à¤µà¤¨à¥à¤¦à¥à¤µ à¤‰à¤  à¤–à¤¡à¤¼à¤¾ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ à¤”à¤° à¤µà¤¹ à¤¦à¥à¤µà¤¨à¥à¤¦à¥à¤µ à¤¸à¥€à¤®à¤¾à¤•à¤¾ à¤…à¤¤à¤¿à¤•à¥à¤°à¤®à¤£ à¤•à¤°à¤¨à¥‡ à¤²à¤—à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤­à¤¾à¤µ à¤¦à¥à¤µà¤¨à¥à¤¦à¥à¤µà¤•à¥‡ à¤†à¤§à¤¿à¤•à¥à¤¯à¤®à¥‡à¤‚ à¤¯à¥à¤—à¤² à¤šà¤°à¤£ à¤¸à¤‚à¤•à¥à¤šà¤¿à¤¤ à¤¹à¥‹ à¤œà¤¾à¤¤à¥‡ à¤¹à¥ˆà¤‚à¥¤ à¤šà¤°à¤£-à¤¸à¥à¤ªà¤°à¥à¤¶-à¤¹à¥‡à¤¤à¥-à¤‰à¤¤à¥à¤¸à¥à¤• à¤¦à¥‚à¤¤à¤¸à¥‡ à¤ªà¥à¤°à¥€à¤¤à¤¿-à¤µà¤¿à¤—à¤²à¤¿à¤¤à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤•à¤¹à¤¤à¥€ à¤¹à¥ˆ-à¤¤à¥à¤® à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤£à¤§à¤¨ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¥‡ à¤ªà¥à¤°à¤¿à¤¯ à¤¦à¥‚à¤¤ à¤¹à¥‹, à¤…à¤¤à¤ƒ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤”à¤° à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤…à¤­à¤¿à¤²à¤¾à¤·à¤¾à¤•à¤¾ à¤¸à¤®à¥à¤®à¤¾à¤¨ à¤•à¤°à¤¨à¤¾ à¤¹à¥€ à¤®à¥‡à¤°à¤¾ à¤ªà¤°à¤® à¤•à¤°à¥à¤¤à¤µà¥à¤¯ à¤¹à¥ˆ, à¤ªà¤°à¤¨à¥à¤¤à¥ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤‡à¤¸ à¤…à¤­à¤¿à¤²à¤¾à¤·à¤¾à¤¨à¥‡ à¤®à¥à¤à¥‡ à¤¬à¤¹à¥à¤¤ à¤¬à¤¡à¤¼à¥€ à¤‰à¤²à¤à¤¨à¤®à¥‡à¤‚ à¤¡à¤¾à¤² à¤¦à¤¿à¤¯à¤¾ à¤¹à¥ˆà¥¤ à¤à¤• à¤à¤¸à¥€ à¤…à¤¸à¤®à¤žà¥à¤œà¤¸à¤•à¥€ à¤¸à¥à¤¥à¤¿à¤¤à¤¿ à¤‰à¤¤à¥à¤ªà¤¨à¥à¤¨ à¤¹à¥‹ à¤—à¤¯à¥€ à¤¹à¥ˆ, à¤œà¤¿à¤¸à¤•à¤¾ à¤¸à¤®à¤¾à¤§à¤¾à¤¨ à¤¨à¤¹à¥€à¤‚à¥¤ à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤£à¤§à¤¨ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¨à¥‡ à¤®à¥à¤à¤¸à¥‡ à¤µà¤šà¤¨ à¤²à¥‡ à¤²à¤¿à¤¯à¤¾ à¤¹à¥ˆ à¤•à¤¿ à¤‡à¤¨ à¤šà¤°à¤£à¥‹à¤‚à¤ªà¤° à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤®à¥‡à¤°à¤¾ à¤¹à¥€ à¤¸à¥à¤µà¤¤à¥à¤µ à¤°à¤¹à¥‡ à¤…à¤¥à¤µà¤¾ à¤‡à¤¨ à¤šà¤°à¤£à¥‹à¤‚à¤•à¤¾ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤µà¥‡ à¤¹à¥€ à¤•à¤° à¤ªà¤¾à¤¯à¥‡à¤‚, à¤œà¤¿à¤¨à¤•à¤¾ à¤®à¤¨-à¤®à¤¤à¤¿-à¤šà¤¿à¤¤à¥à¤¤-à¤…à¤¹à¤‚ à¤¸à¤¬ à¤•à¥à¤› à¤®à¥à¤à¤¸à¥‡ à¤à¤•à¤¾à¤•à¤¾à¤° à¤¹à¥‹ à¤œà¤¾à¤¯à¥‡à¥¤ 

à¤¹à¥‹ à¤—à¤¦à¥à¤—à¤¦ à¤¬à¥‹à¤²à¥‡-à¤¦à¤¾à¤¨ à¤®à¤¹à¤¾  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ !  à¤®à¥à¤à¥‡ à¤¯à¤¹ à¤¦à¥‹,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¯à¥‡ à¤ªà¥‹à¤‚à¤› à¤šà¤°à¤£  à¤…à¤¸à¤®à¥‹à¤°à¥à¤§à¥à¤µ à¤°à¤¹à¥‚à¤ à¤¬à¤¡à¤¼à¤­à¤¾à¤—à¥€ à¤¸à¥à¤–à¥€ à¤¸à¤¦à¤¾,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤®à¥‡à¤°à¥€   à¤¹à¥€  à¤¸à¥à¤µà¤¤à¥à¤µ  à¤°à¤¹à¥‡ à¤‡à¤¨à¤ªà¤°,  à¤•à¥‡à¤µà¤²  à¤›à¥à¤à¤  à¤µà¥‡ à¤¹à¥€,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !	
à¤œà¤¿à¤¨à¤•à¤¾ à¤®à¤¨ à¤¬à¥à¤¦à¥à¤§à¤¿ à¤…à¤¹à¤‚ à¤•à¤¾à¤²à¤¾ à¤œà¤²à¤¦à¤¾à¤­ à¤¬à¤¨à¥‡ à¤®à¥à¤-à¤¸à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !

à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¥‡ à¤šà¤°à¤£à¥‹à¤‚à¤•à¥€ à¤¯à¤¹ à¤¦à¤¾à¤¸à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¸à¥‡ à¤­à¤¿à¤¨à¥à¤¨ à¤•à¥à¤› à¤¸à¥‹à¤š à¤¹à¥€ à¤¨à¤¹à¥€à¤‚ à¤¸à¤•à¤¤à¥€à¥¤ à¤‰à¤¨à¤•à¥€ à¤°à¥à¤šà¤¿ à¤¹à¥€ à¤®à¥‡à¤°à¤¾ à¤œà¥€à¤µà¤¨ à¤¹à¥ˆà¥¤ à¤‰à¤¨à¤•à¥‹ à¤à¤¸à¤¾ à¤µà¤šà¤¨ à¤¦à¥‡ à¤šà¥à¤•à¤¨à¥‡à¤•à¥‡ à¤¬à¤¾à¤¦ à¤…à¤¬ à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤¬à¤¤à¤²à¤¾à¤“à¤‚ à¤•à¤¿ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤…à¤­à¤¿à¤²à¤¾à¤·à¤¾à¤•à¤¾ à¤¸à¤®à¥à¤®à¤¾à¤¨ à¤®à¥ˆà¤‚ à¤•à¥ˆà¤¸à¥‡ à¤•à¤°à¥‚à¤?
'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¸à¥à¤µà¤°à¥‚à¤ªà¤¾, à¤®à¤¹à¤¾à¤¨à¥à¤°à¤¾à¤—à¤¿à¤£à¥€, à¤®à¤¹à¤¾à¤¸à¤®à¤°à¥à¤ªà¤£à¤®à¤¯à¥€ à¤®à¤¹à¤¾à¤¹à¥à¤²à¤¾à¤¦à¤¿à¤¨à¥€, à¤®à¤¹à¤¾à¤µà¤¿à¤¨à¥€à¤¤à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¤¾ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤¤à¤¥à¤¾ à¤ªà¥‚à¤°à¥à¤£à¤¤à¤ƒ à¤²à¥‹à¤•à¥‹à¤¤à¥à¤¤à¤° à¤¹à¥ˆà¥¤ à¤†à¤¨à¥à¤¤à¤°à¤¿à¤• à¤‰à¤²à¤à¤¨à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤®à¤¨à¤•à¥‡ à¤­à¥€à¤¤à¤° à¤œà¥‹ à¤…à¤¸à¤®à¤žà¥à¤œà¤¸ à¤­à¤°à¤¾ à¤¸à¤‚à¤•à¥‹à¤š à¤¹à¥ˆ, à¤‰à¤¸à¥€à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤¤à¥‹ à¤‰à¤¨à¤•à¥‡ à¤µà¥‡ à¤šà¤°à¤£ à¤¯à¥à¤—à¤² à¤¸à¤‚à¤•à¥à¤šà¤¿à¤¤ à¤¹à¥‹à¤•à¤° à¤¸à¤¿à¤®à¤Ÿ à¤—à¤¯à¥‡à¥¤ à¤•à¤¹à¤¾à¤ à¤µà¤¹ à¤‰à¤ªà¤¾à¤²à¤®à¥à¤­ à¤”à¤° à¤•à¤¹à¤¾à¤ à¤¯à¤¹ à¤‰à¤²à¤à¤¨ ? à¤šà¤°à¤£ à¤¸à¥à¤ªà¤°à¥à¤¶à¤•à¤¾ à¤µà¤°à¥à¤œà¤¨ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¹à¥€ à¤¸à¥à¤¥à¤¾à¤¨à¥‹à¤‚à¤ªà¤° à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆ, à¤•à¤¿à¤¨à¥à¤¤à¥ à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¥‡ à¤¹à¥‡à¤¤à¥-à¤¨à¤¿à¤µà¥‡à¤¦à¤¨à¤®à¥‡à¤‚ à¤•à¤¿à¤¤à¤¨à¤¾ à¤®à¤¹à¤¾à¤¨ à¤…à¤¨à¥à¤¤à¤° à¤¹à¥ˆà¤‚? à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¤¾ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿à¤¤à¥à¤µ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤­à¤¿à¤¨à¥à¤¨ à¤¹à¥ˆà¥¤
à¤‡à¤¸à¥€ à¤¸à¥à¤¥à¤¾à¤¨à¤ªà¤° à¤à¤• à¤”à¤° à¤¤à¤¥à¥à¤¯ à¤‰à¤²à¥à¤²à¥‡à¤–à¤¨à¥€à¤¯ à¤¹à¥ˆà¥¤ à¤‡à¤¸ à¤¤à¤¥à¥à¤¯à¤•à¥€ à¤µà¥ˆà¤šà¤¿à¤¤à¥à¤°à¥€ à¤®à¤¨à¤•à¥‹ à¤¬à¤°à¤¬à¤¸ à¤šà¤®à¤¤à¥à¤•à¥ƒà¤¤ à¤•à¤° à¤¦à¥‡à¤¤à¥€ à¤¹à¥ˆà¥¤ à¤¤à¥€à¤¨ à¤§à¤¾à¤®à¥‹à¤‚à¤•à¥€ à¤¤à¥€à¤°à¥à¤¥à¤¯à¤¾à¤¤à¥à¤°à¤¾à¤¸à¥‡ à¤µà¤¾à¤ªà¤¸ à¤†à¤¨à¥‡à¤•à¥‡ à¤¬à¤¾à¤¦ à¤¸à¤¨à¥ à¥§à¥¯à¥«à¥¬ à¤ˆà¥¦ à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤¶à¤°à¥€à¤°à¤¸à¥‡ à¤…à¤¸à¥à¤µà¤¸à¥à¤¥ à¤¹à¥‹ à¤—à¤¯à¥‡à¥¤ à¤šà¤¿à¤•à¤¿à¤¤à¥à¤¸à¤•à¥‹à¤‚à¤•à¥‡ à¤ªà¤°à¤¾à¤®à¤°à¥à¤¶à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤° à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤ªà¥à¤°à¤¾à¤¯à¤ƒ à¤à¤• à¤à¤•à¤¾à¤¨à¥à¤¤ à¤•à¤®à¤°à¥‡à¤®à¥‡à¤‚ à¤µà¤¿à¤¶à¥à¤°à¤¾à¤® à¤•à¤°à¤¤à¥‡ à¤°à¤¹à¤¤à¥‡ à¤¥à¥‡à¥¤ à¤µà¤¿à¤¶à¥à¤°à¤¾à¤®à¤•à¥‡ à¤¨à¤¿à¤®à¤¿à¤¤à¥à¤¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‹ à¤ªà¤°à¤® à¤®à¤¨-à¤­à¤¾à¤µà¤¨ à¤à¤•à¤¾à¤¨à¥à¤¤ à¤¸à¥à¤²à¤­ à¤¹à¥‹ à¤—à¤¯à¤¾à¥¤ à¤•à¤®à¤°à¥‡à¤•à¥‡ à¤‡à¤¸ à¤à¤•à¤¾à¤¨à¥à¤¤à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥€ à¤•à¤¾à¤µà¥à¤¯-à¤§à¤¾à¤°à¤¾à¤•à¥‹ à¤¬à¤¾à¤§à¤¾-à¤°à¤¹à¤¿à¤¤ à¤—à¤¤à¤¿à¤¸à¥‡ à¤ªà¥à¤°à¤µà¤¾à¤¹à¤¿à¤¤à¤• à¤¹à¥‹à¤¨à¥‡à¤•à¤¾ à¤…à¤µà¤¸à¤° à¤®à¤¿à¤²à¤¾à¥¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾ à¤¤à¥‹ à¤ªà¤¹à¤²à¥‡ à¤­à¥€ à¤¹à¥‹à¤¤à¥€ à¤¥à¥€, à¤ªà¤° à¤…à¤¬ à¤•à¤¾à¤µà¥à¤¯-à¤§à¤¾à¤°à¤¾à¤•à¥€ à¤—à¤¤à¤¿ à¤•à¥à¤› à¤”à¤° à¤¹à¥€ à¤¥à¥€à¥¤ à¤­à¤—à¤µà¤¾à¤¨ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥€ à¤…à¤¹à¥ˆà¤¤à¥à¤•à¥€ à¤•à¥ƒà¤ªà¤¾à¤¸à¥‡ à¤®à¤¨ à¤­à¤—à¤µà¤²à¥à¤²à¥€à¤²à¤¾à¤®à¥‡à¤‚ à¤¸à¤¦à¤¾ à¤¹à¥€ à¤²à¥€à¤¨ à¤°à¤¹à¤¨à¥‡ à¤²à¤—à¤¾ à¤”à¤° à¤—à¤¹à¤°à¥‡ à¤­à¤¾à¤µà¥‹à¤‚à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤¿à¤®à¤—à¥à¤¨à¤¤à¤¾à¤µà¤¾à¤²à¥€ à¤¦à¤¶à¤¾ à¤¹à¥‹à¤¨à¥‡à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤…à¤¬ à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤µà¤°à¥à¤£à¥à¤¯-à¤µà¤¸à¥à¤¤à¥ à¤¥à¤¾ à¤µà¥à¤°à¤œ-à¤µà¥à¤°à¤œà¥‡à¤¶ à¤µà¥à¤°à¤œà¤¾à¤‚à¤—à¤¨à¤¾à¤•à¤¾ à¤°à¤¸-à¤¸à¤¿à¤¨à¥à¤§à¥à¥¤ à¤‡à¤¸à¤•à¤¾ à¤¸à¥à¤ªà¤·à¥à¤Ÿ à¤¸à¤‚à¤•à¥‡à¤¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¨à¥‡ à¤…à¤ªà¤¨à¥€ à¤²à¥‡à¤–à¤¨à¥€à¤¸à¥‡ à¤•à¤¿à¤¯à¤¾ à¤¹à¥ˆ, à¤œà¥‹ à¤¸à¤¬à¤•à¥‡ à¤¸à¤¾à¤®à¤¨à¥‡ à¤† à¤šà¥à¤•à¤¾ à¤¹à¥ˆ 'à¤ªà¤¦-à¤°à¤¤à¥à¤¨à¤¾à¤•à¤°' à¤•à¥€ à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤•à¥‡ à¤°à¥‚à¤ªà¤®à¥‡à¤‚à¥¤ à¤…à¤¬ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥€ à¤•à¤µà¤¿à¤¤à¤¾à¤®à¥‡à¤‚ à¤µà¤°à¥à¤£à¤¨ à¤¥à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾-à¤®à¤¾à¤§à¤µà¤•à¤¾ à¤”à¤° à¤‰à¤¨à¤•à¥€ à¤ªà¤¾à¤°à¤¸à¥à¤ªà¤°à¤¿à¤• à¤…à¤•à¤²à¥à¤· à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¤¾à¥¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¸à¥à¤µà¤¸à¥à¤¥ à¤¹à¥‹ à¤œà¤¾à¤¨à¥‡à¤•à¥‡ à¤¬à¤¾à¤¦ à¤­à¥€ à¤‰à¤¨à¤•à¥€ à¤•à¤¾à¤µà¥à¤¯-à¤§à¤¾à¤°à¤¾à¤®à¥‡à¤‚ à¤µà¤¿à¤°à¤¾à¤® à¤¨à¤¹à¥€à¤‚ à¤†à¤¯à¤¾, à¤…à¤ªà¤¿à¤¤à¥ à¤œà¤¿à¤¤à¤¨à¥€ à¤¹à¥€ à¤—à¤¹à¤°à¥€ à¤­à¤¾à¤µ-à¤¦à¤¶à¤¾, à¤‰à¤¤à¤¨à¥€ à¤¹à¥€ à¤‰à¤¤à¥à¤•à¥ƒà¤·à¥à¤Ÿ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾ à¤¹à¥‹à¤¤à¥€ à¤¥à¥€à¥¤ à¤‡à¤¸ à¤‰à¤¤à¥à¤•à¥ƒà¤·à¥à¤Ÿ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾à¤•à¤¾ à¤•à¥à¤°à¤® à¤…à¤–à¤£à¥à¤¡ à¤”à¤° à¤…à¤¬à¤¾à¤§ à¤—à¤¤à¤¿à¤¸à¥‡ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤šà¤²à¤¤à¤¾ à¤°à¤¹à¤¾à¥¤ à¤‡à¤¸ à¤¸à¥à¤¤à¤°à¤•à¥€ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾ à¤®à¥à¤–à¥à¤¯à¤¤à¤ƒ à¤¸à¤¨à¥ à¥§à¥¯à¥«à¥¬ à¤ˆà¥¦ à¤¸à¥‡ à¤ªà¥à¤°à¤¾à¤°à¤®à¥à¤­ à¤¹à¥à¤ˆà¥¤
à¤‡à¤¸à¥€ à¤¸à¤¨à¥ à¥§à¥¯à¥«à¥¬ à¤ˆà¥¦ à¤®à¥‡à¤‚ à¤ªà¥‚à¤œà¥à¤¯ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨à¤•à¤¾ à¤•à¤ à¥‹à¤° à¤µà¥à¤°à¤¤ à¤²à¤¿à¤¯à¤¾à¥¤ à¤•à¤¾à¤·à¥à¤ à¤®à¥Œà¤¨à¤•à¥€ à¤…à¤µà¤§à¤¿à¤®à¥‡à¤‚ à¤¹à¥€ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾à¤•à¤¾ à¤¸à¥à¤«à¥à¤°à¤£ à¤¹à¥à¤† à¤”à¤° à¤‡à¤¸à¥€ à¤…à¤µà¤§à¤¿à¤®à¥‡à¤‚ à¤°à¤šà¤¨à¤¾ à¤†à¤°à¤®à¥à¤­ à¤¹à¥à¤ˆ à¤‰à¤¨à¤•à¥‡ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€à¥¤ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤•à¥€ à¤°à¤šà¤¨à¤¾à¤•à¥‡ à¤¸à¤®à¤¯ à¤•à¤ à¥‹à¤° à¤®à¥Œà¤¨ à¤µà¥à¤°à¤¤ à¤¹à¥‹à¤¨à¥‡à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤¬à¤¾à¤¬à¤¾ à¤•à¤¿à¤¸à¥€à¤¸à¥‡ à¤­à¥€ à¤¸à¤‚à¤­à¤¾à¤·à¤£ à¤¨à¤¹à¥€à¤‚ à¤•à¤°à¤¤à¥‡ à¤¥à¥‡, à¤¯à¤¹à¤¾à¤ à¤¤à¤• à¤•à¤¿ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¸à¥‡ à¤­à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤¸à¥à¤µà¥€à¤•à¥ƒà¤¤ à¤¨à¤¿à¤¯à¤®à¥‹à¤‚à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤° à¤¬à¤¾à¤¬à¤¾ à¤µà¥à¤°à¤¤à¤•à¥€ à¤…à¤µà¤§à¤¿à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¸à¥‡ à¤¬à¤¾à¤¤ à¤•à¤° à¤¸à¤•à¤¤à¥‡ à¤¥à¥‡, à¤ªà¤° à¤à¤¸à¥€ à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾ à¤†à¤¯à¥€ à¤¹à¥€ à¤¨à¤¹à¥€à¤‚à¥¤ à¤œà¤¬ à¤¬à¤¾à¤¬à¤¾ à¤•à¤¿à¤¸à¥€à¤•à¥€ à¤“à¤° à¤­à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿ à¤‰à¤ à¤¾à¤•à¤° à¤¨à¤¹à¥€à¤‚ à¤¦à¥‡à¤–à¤¤à¥‡ à¤¥à¥‡, à¤¤à¤¬ à¤•à¤¿à¤¸à¥€à¤¸à¥‡ à¤­à¥€ à¤¸à¤‚à¤­à¤¾à¤·à¤£à¤•à¥€ à¤¸à¤‚à¤­à¤¾à¤µà¤¨à¤¾ à¤¹à¥€ à¤•à¤¹à¤¾à¤ ?
à¤¸à¤¨à¥ à¥§à¥¯à¥«à¥¬ à¤ˆà¥¦ à¤•à¥‡ à¤¬à¤¾à¤¦à¤¸à¥‡ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤”à¤° à¤¬à¤¾à¤¬à¤¾, à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¥‡ à¤¹à¥€ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾à¤•à¤¾ à¤†à¤°à¤®à¥à¤­ à¤¹à¥‹à¤¤à¤¾ à¤¹à¥ˆà¥¤ à¤‡à¤¨ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤µà¤¿à¤­à¥‚à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤ªà¤°à¤¸à¥à¤ªà¤°à¤®à¥‡à¤‚ à¤µà¤¿à¤šà¤¾à¤°à¥‹à¤‚ à¤à¤µà¤‚ à¤­à¤¾à¤µà¥‹à¤‚à¤•à¤¾ à¤†à¤¦à¤¾à¤¨-à¤ªà¥à¤°à¤¦à¤¾à¤¨ à¤¤à¤¨à¤¿à¤• à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾ à¤¥à¤¾, à¤‡à¤¸à¤•à¥‡ à¤¬à¤¾à¤¦ à¤­à¥€ à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¥‡ à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤¨à¤¨à¥à¤¦à¤¿à¤¨à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤à¤µà¤‚ à¤¨à¤¨à¥à¤¦à¤¨à¤¨à¥à¤¦à¤¨ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥‡ 'à¤ªà¤°-à¤¤à¤¤à¥à¤¤à¥à¤µ' à¤•à¥‡ à¤šà¤¿à¤¤à¥à¤°à¤£à¤®à¥‡à¤‚ à¤”à¤° à¤‰à¤¨à¤•à¥€ à¤ªà¤¾à¤°à¤¸à¥à¤ªà¤°à¤¿à¤• à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¥‡ à¤¸à¥à¤¤à¤° à¤à¤µà¤‚ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤•à¥‡ à¤šà¤¿à¤¤à¥à¤°à¤£à¤®à¥‡à¤‚ à¤…à¤¦à¥à¤­à¥à¤¤ à¤¸à¤¾à¤®à¥à¤¯ à¤¹à¥ˆà¥¤ à¤‡à¤¤à¤¨à¤¾ à¤…à¤§à¤¿à¤• à¤¸à¤¾à¤®à¥à¤¯ à¤¹à¥ˆ, à¤®à¤¾à¤¨à¥‹ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤µà¤¿à¤­à¥‚à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤®à¤§à¥à¤¯ à¤¨à¤¿à¤¤à¥à¤¯ à¤¹à¥€ à¤ªà¤°à¤¸à¥à¤ªà¤°à¤¾à¤²à¤¾à¤ª à¤¹à¥‹à¤¤à¤¾ à¤°à¤¹à¤¾ à¤¹à¥ˆ à¤”à¤° à¤®à¤¾à¤¨à¥‹ à¤ªà¤°à¤¸à¥à¤ªà¤°à¤¾à¤²à¤¾à¤ªà¤•à¥‡ à¤®à¤§à¥à¤¯ à¤¶à¥à¤°à¥€à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤µà¤¿à¤·à¤¯à¤• à¤šà¤¿à¤¨à¥à¤¤à¤¨-à¤®à¤¨à¤¨ à¤¹à¥‹à¤¤à¤¾ à¤°à¤¹à¤¾ à¤¹à¥ˆà¥¤ à¤¯à¤¦à¤¿ à¤à¤¸à¤¾ à¤¨à¤¹à¥€à¤‚ à¤¹à¥‹à¤¤à¤¾ à¤¤à¥‹ à¤‡à¤¨ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤µà¤¿à¤­à¥‚à¤¤à¤¿à¤¯à¥‹à¤‚ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤°à¤šà¤¿à¤¤ à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚ à¤‡à¤¤à¤¨à¥‡ à¤…à¤§à¤¿à¤• à¤¸à¤¾à¤®à¥à¤¯à¤•à¤¾ à¤¸à¤®à¤¾à¤µà¥‡à¤¶ à¤•à¥ˆà¤¸à¥‡ à¤¹à¥‹ à¤œà¤¾à¤¤à¤¾ ? à¤¸à¤¾à¤®à¥à¤¯à¤•à¥‹ à¤¦à¥‡à¤–à¤•à¤° à¤•à¥‹à¤ˆ à¤­à¥€ à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥€ à¤¬à¤¾à¤¤à¤•à¥‹ à¤¸à¥‹à¤š à¤²à¥‡ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆ, à¤ªà¤° à¤µà¤¾à¤¸à¥à¤¤à¤µà¤¿à¤•à¤¤à¤¾ à¤¯à¤¹ à¤¹à¥ˆ à¤•à¤¿ à¤‡à¤¨ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤µà¤¿à¤­à¥‚à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¥€ à¤•à¤¾à¤µà¥à¤¯-à¤°à¤šà¤¨à¤¾à¤®à¥‡à¤‚ à¤¶à¥à¤°à¥€à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤šà¤¿à¤¤à¥à¤°à¤£à¤®à¥‡à¤‚ à¤œà¥‹ à¤¸à¤¾à¤®à¥à¤¯ à¤¹à¥ˆ, à¤µà¤¹ à¤µà¤¸à¥à¤¤à¥à¤¤à¤ƒ à¤®à¤¨à¤•à¥‹ à¤šà¤®à¤¤à¥à¤•à¥ƒà¤¤ à¤•à¤° à¤¦à¥‡à¤¤à¤¾ à¤¹à¥ˆ à¤”à¤° à¤‡à¤¸ à¤¸à¤¾à¤®à¥à¤¯à¤•à¥‡ à¤…à¤µà¤¤à¤°à¤£à¤•à¤¾ à¤¹à¥‡à¤¤à¥ à¤­à¥€ à¤…à¤¦à¥à¤­à¥à¤¤ à¤¹à¥ˆà¥¤
à¤‡à¤¸ à¤¸à¥à¤¥à¤²à¤ªà¤° à¤•à¥à¤› à¤ªà¥à¤°à¤¾à¤¤à¤¨ à¤ªà¥à¤°à¤¸à¤‚à¤—à¥‹à¤‚à¤•à¥€ à¤“à¤° à¤‡à¤‚à¤—à¤¿à¤¤ à¤•à¤°à¤¨à¤¾ à¤†à¤µà¤¶à¥à¤¯à¤• à¤¹à¥‹ à¤—à¤¯à¤¾ à¤¹à¥ˆà¥¤ à¤¸à¤¨à¥ à¥§à¥¯à¥©à¥¬ à¤ˆà¥¦ à¤®à¥‡à¤‚ à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤à¤• à¤µà¤°à¥à¤·à¥€à¤¯ à¤…à¤–à¤£à¥à¤¡ à¤¹à¤°à¤¿à¤¨à¤¾à¤® à¤¸à¤‚à¤•à¥€à¤°à¥à¤¤à¤¨ à¤¹à¥‹ à¤°à¤¹à¤¾ à¤¥à¤¾à¥¤ à¤‰à¤¸ à¤¸à¤®à¤¯ à¤¬à¤¾à¤¬à¤¾ à¤¸à¤°à¥à¤µ à¤ªà¥à¤°à¤¥à¤® à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤†à¤¯à¥‡ à¤¥à¥‡à¥¤ à¤¤à¤¬ à¤¬à¤¾à¤¬à¤¾ à¤ªà¥‚à¤°à¥à¤£à¤¤à¤ƒ à¤¶à¤¾à¤‚à¤•à¤°à¤®à¤¤à¤¾à¤¨à¥à¤¯à¤¾à¤¯à¥€ à¤¥à¥‡ à¤”à¤° à¤‰à¤¨à¤•à¥€ à¤¨à¤¿à¤·à¥à¤ à¤¾ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤¦à¥à¤µà¥ˆà¤¤à¤µà¤¾à¤¦à¥€ à¤¥à¥€à¥¤ à¤¸à¤°à¥à¤µà¤ªà¥à¤°à¤¥à¤® à¤®à¤¿à¤²à¤¨à¤•à¥‡ à¤¸à¤®à¤¯ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¨à¥‡ à¤¸à¤‚à¤¨à¥à¤¯à¤¾à¤¸à¥€ à¤µà¥‡à¤·à¤®à¥‡à¤‚ à¤ªà¤§à¤¾à¤°à¥‡ à¤¹à¥à¤ à¤…à¤ªà¤°à¤¿à¤šà¤¿à¤¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤šà¤°à¤£ à¤›à¥‚à¤•à¤° à¤ªà¥à¤°à¤£à¤¾à¤® à¤•à¤¿à¤¯à¤¾à¥¤ à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤•à¥‡ à¤…à¤—à¥à¤°à¤­à¤¾à¤—à¤®à¥‡à¤‚ à¤šà¤°à¤£ à¤¸à¥à¤ªà¤°à¥à¤¶à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤®à¤¸à¥‡ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ 'à¤¸à¥à¤¥à¥‚à¤²-à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶' à¤•à¤¾ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤à¤¸à¤¾ à¤¥à¤¾ à¤•à¤¿ à¤¬à¤¾à¤¬à¤¾ à¤¨à¤¿à¤°à¤¾à¤•à¤¾à¤°à¤µà¤¾à¤¦à¥€à¤¸à¥‡ à¤¸à¤¾à¤•à¤¾à¤°à¥‹à¤ªà¤¾à¤¸à¤• à¤¬à¤¨ à¤—à¤¯à¥‡ à¤”à¤° à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨ à¤§à¤¾à¤®à¤•à¥€ à¤ªà¤°à¤® à¤¨à¤¿à¤§à¤¿ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾-à¤®à¤¾à¤§à¤µà¤•à¥€ à¤¸à¤°à¤¸ à¤¸à¤®à¥à¤ªà¤¤à¥à¤¤à¤¿à¤•à¤¾ à¤®à¤¹à¤¾à¤¦à¤¾à¤¨ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤®à¤¿à¤² à¤—à¤¯à¤¾à¥¤
à¤¸à¤¨à¥ à¥§à¥¯à¥©à¥¯ à¤•à¥‡ à¤®à¤ˆ à¤®à¤¾à¤¸à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¤¾à¤¥ à¤°à¤¹à¤¨à¥‡ à¤²à¤— à¤—à¤¯à¥‡à¥¤ à¤‡à¤¸à¤•à¥‡ à¤¬à¤¾à¤¦ à¤¸à¤®à¥à¤­à¤µà¤¤à¤ƒ à¤œà¥‚à¤¨ à¤¯à¤¾ à¤œà¥à¤²à¤¾à¤ˆ à¥§à¥¯à¥©à¥¯ à¤•à¥€ à¤¬à¤¾à¤¤ à¤¹à¥ˆà¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¤¾ à¤¨à¤¿à¤µà¤¾à¤¸ à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤•à¥‡ à¤ªà¤¿à¤›à¤²à¥‡ à¤­à¤¾à¤—à¤®à¥‡à¤‚ à¤à¤• à¤•à¥à¤Ÿà¤¿à¤¯à¤¾à¤•à¥‡ à¤…à¤¨à¥à¤¦à¤° à¤¥à¤¾à¥¤ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤®à¤¨à¤®à¥‡à¤‚ à¤µà¥à¤°à¤œà¤­à¤¾à¤µ à¤¸à¤®à¥à¤¬à¤¨à¥à¤§à¥€ à¤•à¥à¤› à¤à¤¸à¥€ à¤—à¥à¤¤à¥à¤¥à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤‰à¤¦à¥à¤­à¤µ à¤¹à¥‹ à¤—à¤¯à¤¾, à¤œà¤¿à¤¨à¤•à¥‹ à¤•à¥‹à¤ˆ à¤¸à¤¿à¤¦à¥à¤§ à¤°à¤¸à¤¿à¤• à¤¸à¤‚à¤¤ à¤¹à¥€ à¤¸à¥à¤²à¤à¤¾ à¤¸à¤•à¤¤à¤¾ à¤¥à¤¾à¥¤ à¤¬à¤¾à¤¬à¤¾ à¤œà¤¾à¤¨à¤¤à¥‡ à¤¥à¥‡ à¤•à¤¿ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¯à¤¹ à¤•à¤¾à¤°à¥à¤¯ à¤¹à¥‹ à¤¸à¤•à¤¤à¤¾ à¤¹à¥ˆ, à¤ªà¤° à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤­à¤²à¤¾ à¤—à¥à¤°à¥-à¤ªà¤¦ à¤•à¥à¤¯à¥‹à¤‚à¤•à¤° à¤¸à¥à¤µà¥€à¤•à¤¾à¤° à¤•à¤°à¤¨à¥‡ à¤²à¤—à¥‡ ? à¤‡à¤§à¤° à¤¬à¤¾à¤¬à¤¾ à¤…à¤ªà¤¨à¥€ à¤—à¥à¤¤à¥à¤¥à¤¿à¤¯à¥‹à¤‚à¤®à¥‡à¤‚ à¤‰à¤²à¤à¥‡ à¤¹à¥à¤ à¤•à¥à¤Ÿà¤¿à¤¯à¤¾à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤ªà¤° à¤¬à¥ˆà¤ à¥‡ à¤¹à¥à¤ à¤¥à¥‡, à¤‰à¤§à¤° à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥€ à¤…à¤¨à¥à¤¤à¤°à¥à¤­à¥‡à¤¦à¥€ à¤¦à¥ƒà¤·à¥à¤Ÿà¤¿à¤¨à¥‡ à¤…à¤§à¤¿à¤•à¤¾à¤°à¥€à¤•à¥‡ à¤®à¤¨à¤•à¥€ à¤•à¥à¤£à¥à¤ à¤¾ à¤”à¤° à¤–à¤¿à¤¨à¥à¤¨à¤¤à¤¾à¤•à¥‹ à¤œà¤¾à¤¨ à¤²à¤¿à¤¯à¤¾à¥¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤¸à¥‚à¤•à¥à¤·à¥à¤® à¤¶à¤°à¥€à¤°à¤¸à¥‡ à¤µà¤¹à¤¾à¤ à¤ªà¤§à¤¾à¤°à¥‡, à¤œà¤¹à¤¾à¤ à¤¬à¤¾à¤¬à¤¾ à¤•à¥à¤£à¥à¤ à¤¿à¤¤ à¤®à¤¨à¤¸à¥‡ à¤¬à¥ˆà¤ à¥‡ à¤¹à¥à¤ à¤¥à¥‡à¥¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¨à¥‡ à¤…à¤ªà¤¨à¥€ à¤…à¤à¤—à¥à¤²à¥€à¤¸à¥‡ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤…à¤à¤—à¥à¤²à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤¦à¤¸à¥‹à¤‚ à¤¨à¤–à¥‹à¤‚à¤•à¤¾ à¤¸à¥à¤ªà¤°à¥à¤¶ à¤•à¤¿à¤¯à¤¾à¥¤ à¤à¤• à¤ªà¥à¤°à¤•à¤¾à¤°à¤¸à¥‡ à¤¯à¤¹ à¤¶à¤•à¥à¤¤à¤¿-à¤ªà¤¾à¤¤ à¤¹à¥€ à¤¥à¤¾à¥¤ à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤•à¥‡ à¤à¤•à¤¾à¤¨à¥à¤¤ à¤­à¤¾à¤—à¤®à¥‡à¤‚ à¤¨à¤–-à¤¸à¥à¤ªà¤°à¥à¤¶à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤®à¤¸à¥‡ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ 'à¤¸à¥‚à¤•à¥à¤·à¥à¤®-à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶' à¤•à¤¾ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤à¤¸à¤¾ à¤¥à¤¾ à¤•à¤¿ à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤¸à¤¾à¤°à¥€ à¤—à¥à¤¤à¥à¤¥à¤¿à¤¯à¤¾à¤ à¤–à¥à¤² à¤—à¤¯à¥€à¤‚ à¤”à¤° à¤°à¤¸à¥‹à¤ªà¤¾à¤¸à¤¨à¤¾à¤¸à¥‡ à¤¸à¤®à¥à¤¬à¤¨à¥à¤§à¤¿à¤¤ à¤¸à¤­à¥€ à¤¸à¤®à¤¸à¥à¤¯à¤¾à¤“à¤‚à¤•à¥‡ à¤¸à¥à¤¥à¤¾à¤¯à¥€ à¤¸à¤®à¤¾à¤§à¤¾à¤¨à¤•à¤¾ à¤®à¤¹à¤¾à¤¦à¤¾à¤¨ à¤¬à¤¾à¤¬à¤¾à¤•à¥‹ à¤®à¤¿à¤² à¤—à¤¯à¤¾à¥¤
à¤…à¤¬ à¤‡à¤¸ 'à¤¸à¥à¤¥à¥‚à¤²-à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶' à¤à¤µà¤‚ 'à¤¸à¥‚à¤•à¥à¤·à¥à¤®-à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶' à¤•à¥€ à¤ªà¤°à¤¿à¤§à¤¿à¤¸à¥‡ à¤¦à¥‚à¤°, à¤¬à¤¹à¥à¤¤ à¤¦à¥‚à¤°, à¤…à¤¤à¥€à¤µ à¤¦à¥‚à¤° à¤…à¤¬ à¤ªà¥‚à¤°à¥à¤£à¤¤à¤ƒ à¤‡à¤¨à¥à¤¦à¥à¤°à¤¿à¤¯à¤¾à¤¤à¥€à¤¤ à¤¸à¥à¤¤à¤°à¤ªà¤° à¤à¤• à¤à¤¸à¥€ à¤ªà¥à¤°à¤•à¥à¤°à¤¿à¤¯à¤¾ à¤¸à¤•à¥à¤°à¤¿à¤¯ à¤¹à¥‹ à¤‰à¤ à¥€, à¤œà¤¿à¤¸à¤¸à¥‡ à¤…à¤¸à¤®à¥à¤­à¤µ à¤­à¥€ à¤¸à¤®à¥à¤­à¤µ à¤¹à¥‹ à¤—à¤¯à¤¾à¥¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¸à¥‡ à¤¬à¤¾à¤¬à¤¾à¤•à¤¾ à¤®à¤¨ à¤‡à¤¤à¤¨à¤¾ à¤…à¤§à¤¿à¤• à¤œà¥à¤¡à¤¼à¤¾ à¤¹à¥à¤† à¤¥à¤¾, à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¤¾ à¤­à¤¾à¤µ à¤¸à¤®à¥à¤¬à¤¨à¥à¤§ à¤‡à¤¤à¤¨à¤¾ à¤…à¤§à¤¿à¤• à¤ªà¥à¤°à¤¬à¤² à¤¥à¤¾ à¤•à¤¿ à¤µà¤¸à¥à¤¤à¥ à¤à¤• à¤“à¤°à¤¸à¥‡ à¤¦à¥‚à¤¸à¤°à¥€ à¤“à¤° à¤¸à¥à¤µà¤¤à¤ƒ à¤¸à¤‚à¤•à¥à¤°à¤®à¤¿à¤¤ à¤¹à¥‹ à¤—à¤¯à¥€à¥¤ à¤¬à¤¾à¤¹à¤°à¤¸à¥‡ à¤¦à¥‡à¤–à¤¨à¥‡ à¤­à¤°à¤®à¥‡à¤‚ à¤¬à¤¾à¤¬à¤¾ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤¸à¥‡ à¤¨à¤¹à¥€à¤‚ à¤®à¤¿à¤²à¤¤à¥‡ à¤¥à¥‡, à¤ªà¤° à¤­à¥€à¤¤à¤°à¤¸à¥‡ à¤‰à¤¨à¤•à¤¾ à¤¨à¤¿à¤¤à¥à¤¯ à¤®à¤¿à¤²à¤¨ à¤¹à¥ˆà¥¤ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤·à¤¤à¤ƒ à¤µà¤¿à¤¯à¥à¤•à¥à¤¤ à¤¹à¥‹à¤¤à¥‡ à¤¹à¥à¤ à¤­à¥€ à¤µà¤¸à¥à¤¤à¥à¤¤à¤ƒ à¤¦à¥‹à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¤‚à¤¯à¥à¤•à¥à¤¤à¤¿ à¤¹à¥ˆà¥¤ à¤­à¤¾à¤µà¤¾à¤¤à¥à¤®à¤• à¤à¤•à¤¾à¤¤à¥à¤®à¤¤à¤¾à¤•à¥‡ à¤•à¤¾à¤°à¤£ à¤¦à¥‹à¤¨à¥‹à¤‚à¤®à¥‡à¤‚ à¤ªà¤°à¤® à¤¸à¤¾à¤‚à¤¨à¤¿à¤§à¥à¤¯ à¤¹à¥ˆ à¤”à¤° à¤‰à¤¸ à¤­à¤¾à¤µà¤¾à¤¤à¥à¤®à¤• à¤¸à¤¾à¤‚à¤¨à¤¿à¤§à¥à¤¯à¤¨à¥‡ à¤¹à¥€ à¤µà¤¸à¥à¤¤à¥-à¤¸à¤‚à¤•à¥à¤°à¤®à¤£à¤•à¥‹ à¤¸à¤®à¥à¤­à¤µ à¤¬à¤¨à¤¾ à¤¦à¤¿à¤¯à¤¾à¥¤ à¤œà¤¿à¤¸à¤•à¥€ à¤¸à¤•à¥à¤°à¤¿à¤¯à¤¤à¤¾ à¤¬à¥‹à¤§à¤•à¥€ à¤¸à¥€à¤®à¤¾à¤®à¥‡à¤‚ à¤¸à¤°à¤²à¤¤à¤¾à¤ªà¥‚à¤°à¥à¤µà¤• à¤¨à¤¹à¥€à¤‚ à¤† à¤ªà¤¾à¤¤à¥€, à¤à¤¸à¥‡ à¤¸à¤‚à¤•à¥à¤°à¤®à¤£à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤‰à¤¨ 'à¤¦à¥‹ à¤®à¤¹à¤¾à¤¦à¤¾à¤¨à¥‹à¤‚' à¤¸à¥‡ à¤­à¥€ à¤‡à¤¸ à¤®à¤¹à¤¤à¥à¤¤à¤° à¤¦à¤¾à¤¨à¤•à¥€ à¤ªà¥à¤°à¤•à¥à¤°à¤¿à¤¯à¤¾à¤ à¤¸à¤¹à¤œ à¤¹à¥€ à¤¸à¤®à¥à¤ªà¤¨à¥à¤¨ à¤¹à¥‹ à¤—à¤¯à¥€à¥¤ à¤µà¥‡ à¤¦à¥‹ à¤®à¤¹à¤¾à¤¦à¤¾à¤¨ à¤¹à¥à¤ à¤¥à¥‡ à¤‰à¤¸ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤—à¥€à¤¤à¤¾à¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚ à¤”à¤° à¤¯à¤¹ à¤®à¤¹à¤¤à¥à¤¤à¤° à¤¦à¤¾à¤¨ à¤¹à¥à¤† à¤¥à¤¾ à¤‡à¤¸ à¤ªà¤°à¥‹à¤•à¥à¤· à¤­à¤¾à¤µà¤µà¤¾à¤Ÿà¤¿à¤•à¤¾à¤®à¥‡à¤‚à¥¤ à¤‡à¤¸ 'à¤­à¤¾à¤µ-à¤¸à¤‚à¤¸à¥à¤ªà¤°à¥à¤¶' à¤•à¤¾ à¤ªà¥à¤°à¤­à¤¾à¤µ à¤à¤¸à¤¾ à¤¥à¤¾ à¤•à¤¿ à¤ªà¥‚à¤°à¥à¤£à¤¤à¤ƒ à¤ªà¤°à¥‹à¤•à¥à¤· à¤¸à¥à¤¤à¤°à¥€à¤¯ à¤¸à¤‚à¤•à¥à¤°à¤®à¤£à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤®à¤¸à¥‡ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤µà¤¹ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤ªà¥à¤°à¤¤à¤¿à¤¬à¤¿à¤®à¥à¤¬à¤¿à¤¤-à¤ªà¥à¤°à¤¤à¤¿à¤«à¤²à¤¿à¤¤ à¤¹à¥‹ à¤‰à¤ à¤¾, à¤œà¥‹ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤¥à¤¾à¥¤ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤¸à¥à¤µà¤°à¥‚à¤ªà¤¿à¤£à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤à¤µà¤‚ à¤°à¤¸à¤°à¤¾à¤œà¤¸à¥à¤µà¤°à¥‚à¤ª à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥‡ 'à¤—à¥à¤£à¤°à¤¹à¤¿à¤¤-à¤•à¤¾à¤®à¤¨à¤¾à¤°à¤¹à¤¿à¤¤-à¤ªà¥à¤°à¤¤à¤¿à¤•à¥à¤·à¤£à¤µà¤°à¥à¤§à¤®à¤¾à¤¨ à¤…à¤µà¤¿à¤šà¥à¤›à¤¿à¤¨à¥à¤¨-à¤¸à¥‚à¤•à¥à¤·à¥à¤®à¤¤à¤°-à¤…à¤¨à¥à¤­à¤µà¤°à¥‚à¤ª' à¤ªà¥à¤°à¥‡à¤®-à¤ªà¥à¤°à¤£à¤¾à¤²à¥€à¤•à¥€ à¤œà¥‹ à¤¸à¤šà¥à¤šà¤¿à¤¦à¤¾à¤¨à¤¨à¥à¤¦à¤®à¤¯à¥€ à¤›à¤µà¤¿ à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤¥à¥€, à¤µà¤¹à¥€ à¤›à¤µà¤¿ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤ƒà¤•à¤°à¤£à¤®à¥‡à¤‚ à¤‰à¤¦à¥à¤­à¤¾à¤¸à¤¿à¤¤ à¤¹à¥‹ à¤‰à¤ à¥€à¥¤ à¤¯à¤¦à¤¿ à¤à¤• à¤“à¤° à¤¸à¤‚à¤•à¥à¤°à¤®à¤¿à¤¤ à¤•à¤°à¤¨à¥‡à¤•à¥€ à¤¯à¥‹à¤—à¥à¤¯à¤¤à¤¾ à¤¥à¥€ à¤¤à¥‹ à¤¦à¥‚à¤¸à¤°à¥€ à¤“à¤° à¤¸à¤‚à¤•à¥à¤°à¤®à¤¿à¤¤à¤•à¥‹ à¤—à¥à¤°à¤¹à¤£ à¤•à¤°à¤¨à¥‡à¤•à¥€ à¤ªà¤¾à¤¤à¥à¤°à¤¤à¤¾ à¤¥à¥€à¥¤ à¤¸à¤‚à¤•à¥à¤°à¤®à¤¿à¤¤ à¤›à¤µà¤¿à¤•à¥‹ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤¸à¥‡ à¤¸à¥à¤µà¥€à¤•à¤¾à¤° à¤•à¤¿à¤¯à¤¾, à¤œà¥€à¤µà¤¨à¤®à¥‡à¤‚ à¤…à¤‚à¤—à¥€à¤•à¤¾à¤° à¤•à¤¿à¤¯à¤¾ à¤”à¤° à¤µà¥‡ à¤¹à¥‹ à¤—à¤¯à¥‡ à¤¨à¤–à¤¶à¤¿à¤– à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¤à¤¦à¤¾à¤•à¤¾à¤°à¥¤ à¤¬à¤¾à¤¬à¤¾à¤¨à¥‡ à¤¸à¥à¤µà¤¯à¤‚ à¤•à¤¹à¤¾ à¤¹à¥ˆ- à¤¶à¥à¤°à¥€à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œ à¤¯à¤¦à¤¿ à¤—à¥à¤²à¤¾à¤¬à¤•à¥‡ à¤ªà¥Œà¤§à¥‡ à¤¹à¥ˆà¤‚ à¤¤à¥‹ à¤‰à¤¸ à¤ªà¥Œà¤§à¥‡à¤•à¥€ à¤à¤• à¤¶à¤¾à¤–à¤¾à¤ªà¤° à¤–à¤¿à¤²à¤¨à¥‡à¤µà¤¾à¤²à¤¾ à¤®à¥ˆà¤‚ à¤à¤• à¤›à¥‹à¤Ÿà¤¾-à¤¸à¤¾ à¤—à¥à¤²à¤¾à¤¬à¤•à¤¾ à¤«à¥‚à¤² à¤¹à¥‚à¤à¥¤ à¤®à¥à¤à¤¸à¥‡ à¤­à¥€ à¤…à¤§à¤¿à¤• à¤¸à¥à¤¨à¥à¤¦à¤°à¤¤à¤°, à¤…à¤§à¤¿à¤• à¤¶à¥à¤°à¥‡à¤·à¥à¤ à¤¤à¤° à¤ªà¥à¤·à¥à¤ª, à¤à¤• à¤¨à¤¹à¥€à¤‚, à¤…à¤¨à¥‡à¤•à¤¾à¤¨à¥‡à¤• à¤ªà¤¾à¤Ÿà¤² à¤ªà¥à¤·à¥à¤ª à¤–à¤¿à¤²à¤¾ à¤¦à¥‡à¤¨à¥‡à¤•à¥€ à¤•à¥à¤·à¤®à¤¤à¤¾ à¤‡à¤¸ à¤ªà¥Œà¤§à¥‡à¤‚à¤®à¥‡à¤‚ à¤¹à¥ˆà¥¤
à¤¬à¤¾à¤¬à¥‚à¤œà¥€à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤¦à¤¿à¤µà¥à¤¯ à¤¯à¥à¤—à¤² à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤®à¤¾à¤§à¤µà¤•à¥‡ à¤¦à¤¿à¤µà¥à¤¯ à¤ªà¥à¤°à¥‡à¤®à¤•à¥€ à¤œà¥‹ à¤ªà¤°à¤® à¤¸à¥à¤¨à¥à¤¦à¤°à¤¤à¤®, à¤ªà¤°à¤® à¤®à¤§à¥à¤°à¤¤à¤® à¤à¤µà¤‚ à¤ªà¤°à¤® à¤ªà¤µà¤¿à¤¤à¥à¤°à¤¤à¤® à¤›à¤µà¤¿ à¤¥à¥€, à¤µà¤¹à¥€ à¤›à¤µà¤¿ à¤¸à¤‚à¤•à¥à¤°à¤®à¤¿à¤¤ à¤¹à¥‹ à¤‰à¤ à¥€ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤”à¤° à¤‰à¤¸à¥€ à¤ªà¤°à¤®à¥‹à¤œà¥à¤œà¥à¤µà¤² à¤›à¤µà¤¿à¤•à¥€ à¤…à¤­à¤¿à¤µà¥à¤¯à¤•à¥à¤¤à¤¿ à¤¹à¥à¤ˆ à¤¹à¥ˆ à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯à¤®à¥‡à¤‚à¥¤
à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤”à¤° à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤¨à¤¨à¥à¤¦à¤¿à¤¨à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾ à¤à¤µà¤‚ à¤¨à¤¨à¥à¤¦à¤¨à¤¨à¥à¤¦à¤¨ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥‡ à¤ªà¤¾à¤°à¤¸à¥à¤ªà¤°à¤¿à¤• à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¤¾ à¤œà¥ˆà¤¸à¤¾ à¤šà¤¿à¤¤à¥à¤°à¤£ à¤¹à¥à¤† à¤¹à¥ˆ, à¤µà¤¹ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤…à¤®à¤¾à¤¨à¤µà¥€à¤¯ à¤§à¤°à¤¾à¤¤à¤²à¤•à¥€ à¤µà¤¸à¥à¤¤à¥ à¤¹à¥ˆà¥¤ à¤¯à¤¹ à¤ªà¥à¤°à¥€à¤¤à¤¿ à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¶à¤°à¥€à¤°à¤¾à¤¤à¥€à¤¤, à¤†à¤¦à¥à¤¯à¤¨à¥à¤¤ à¤•à¤¾à¤®-à¤—à¤¨à¥à¤§-à¤¶à¥‚à¤¨à¥à¤¯, à¤ªà¥à¤°à¤¤à¤¿à¤•à¥à¤·à¤£ à¤µà¤°à¥à¤§à¤¨à¤¶à¥€à¤², à¤¨à¤¿à¤¤à¥à¤¯ à¤ªà¤µà¤¿à¤¤à¥à¤°à¤¤à¤®, à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¾à¤¨-à¤­à¤¾à¤µà¤¨à¤¾-à¤¨à¤¿à¤°à¤ªà¥‡à¤•à¥à¤·, à¤¸à¥à¤µ-à¤¸à¥à¤–-à¤µà¤¾à¤žà¥à¤›à¤¾-à¤µà¤¿à¤°à¤¹à¤¿à¤¤, à¤¤à¤¤à¥à¤¸à¥à¤–à¥ˆà¤•-à¤¤à¤¾à¤¤à¥à¤ªà¤°à¥à¤¯à¤®à¤¯, à¤¦à¤¿à¤µà¥à¤¯à¤¾à¤¨à¤¨à¥à¤¦-à¤µà¤¿à¤§à¤¾à¤¯à¤•, à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤…à¤¨à¥à¤­à¤µ à¤—à¤®à¥à¤¯ à¤¹à¥ˆ à¤”à¤° à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¥‡ à¤‡à¤¸ à¤²à¥‹à¤•à¥‹à¤¤à¥à¤¤à¤° à¤¸à¥à¤µà¤°à¥‚à¤ªà¤•à¥‡ à¤‰à¤¦à¥à¤˜à¤¾à¤Ÿà¤¨à¤¨à¥‡ à¤ªà¥à¤°à¥‡à¤®-à¤¸à¤¾à¤§à¤¨à¤¾à¤•à¥‡ à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤•à¥‡ à¤‰à¤¨ à¤¸à¤­à¥€ à¤ªà¥à¤°à¤•à¤¾à¤°à¤•à¥‡ à¤®à¤¾à¤²à¤¿à¤¨à¥à¤¯ à¤à¤µà¤‚ à¤•à¤¾à¤²à¥à¤·à¥à¤¯à¤•à¥‹ à¤¦à¥‚à¤° à¤•à¤° à¤¦à¤¿à¤¯à¤¾, à¤œà¥‹ à¤…à¤µà¤¸à¤° à¤ªà¤¾à¤•à¤° à¤‡à¤¸ à¤¸à¤¾à¤§à¤¨à¤¾ à¤•à¥à¤·à¥‡à¤¤à¥à¤°à¤®à¥‡à¤‚ à¤œà¤¾à¤¨à¥‡-à¤…à¤¨à¤œà¤¾à¤¨à¥‡ à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¤¿à¤·à¥à¤Ÿ à¤¹à¥‹ à¤—à¤¯à¥‡ à¤¥à¥‡à¥¤ à¤¬à¤¾à¤¬à¥‚à¤œà¥€ à¤”à¤° à¤¬à¤¾à¤¬à¤¾à¤•à¥‡ à¤®à¤¾à¤§à¥à¤¯à¤®à¤¸à¥‡ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¤¾ à¤œà¥‹ à¤®à¤¹à¥‹à¤¤à¥à¤•à¥ƒà¤·à¥à¤Ÿ à¤à¤µà¤‚ à¤®à¤¹à¥‹à¤œà¥à¤œà¥à¤µà¤² à¤¸à¥à¤µà¤°à¥‚à¤ª à¤œà¤—à¤¤à¤•à¥‡ à¤¸à¤¾à¤®à¤¨à¥‡ à¤†à¤¯à¤¾ à¤¹à¥ˆ, à¤‰à¤¸à¤•à¥€ à¤¸à¥à¤®à¥ƒà¤¤à¤¿ à¤®à¤¾à¤¤à¥à¤°à¤¸à¥‡ à¤®à¤¨ à¤†à¤¹à¥à¤²à¤¾à¤¦à¤¿à¤¤ à¤¹à¥‹ à¤‰à¤ à¤¤à¤¾ à¤¹à¥ˆà¥¤
à¤¬à¤¾à¤¬à¤¾à¤•à¤¾ à¤¯à¤¹ 'à¤œà¤¯ à¤œà¤¯ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®' à¤•à¤¾à¤µà¥à¤¯ à¤‰à¤¨à¤•à¥€ à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨ à¤…à¤µà¤§à¤¿à¤•à¤¾ à¤à¤• à¤—à¥Œà¤°à¤µà¤ªà¥‚à¤°à¥à¤£ à¤ªà¥à¤°à¤¸à¤¾à¤¦ à¤¹à¥ˆà¥¤ à¤•à¤¾à¤·à¥à¤ -à¤®à¥Œà¤¨à¤•à¥€ à¤…à¤µà¤§à¤¿à¤®à¥‡à¤‚ à¤¹à¥€ à¤ªà¥‚à¤œà¥à¤¯ à¤¶à¥à¤°à¥€à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤­à¤¾à¤µà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾ à¤¹à¥à¤ˆà¥¤ à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤­à¤¾à¤µà¤¿à¤¤ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤¬à¤¾à¤¬à¤¾à¤•à¥€ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤ªà¥à¤°à¤¦à¤¾à¤¯à¤¿à¤•à¤¾ à¤ªà¤°à¤®à¤ªà¥à¤¨à¥€à¤¤à¤¾ à¤ªà¤¦-à¤°à¤œ-à¤•à¤£à¤¿à¤•à¤¾à¤•à¥‹ à¤¸à¤¤à¤¤ à¤µà¤¨à¥à¤¦à¤¨ à¤¹à¥ˆ à¥¥ 
''',
      );
    }
    // --- à¤·à¥‹à¤¡à¤¶ à¤—à¥€à¤¤ (Topic 5) ---
    else if (sectionId == 'topic5') {
      switch (title) {
        case 'à¤µà¤‚à¤¦à¤¨à¤¾':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''à¥¥ à¤·à¥‹à¤¡à¤¶ à¤—à¥€à¤¤à¥¥

(à¤µà¤‚à¤¦à¤¨à¤¾)

à¤¦à¥‹à¤‰ à¤šà¤•à¥‹à¤°, à¤¦à¥‹à¤‰ à¤šà¤‚à¤¦à¥à¤°à¤®à¤¾, à¤¦à¥‹à¤‰ à¤…à¤²à¤¿, à¤ªà¤‚à¤•à¤œ à¤¦à¥‹à¤‰à¥¤
à¤¦à¥‹à¤‰ à¤šà¤¾à¤¤à¤•, à¤¦à¥‹à¤‰ à¤®à¥‡à¤˜ à¤ªà¥à¤°à¤¿à¤¯, à¤¦à¥‹à¤‰ à¤®à¤›à¤°à¥€, à¤œà¤² à¤¦à¥‹à¤‰à¥¥
à¤†à¤¸à¥à¤°à¤¯-à¤†à¤²à¤‚à¤¬à¤¨ à¤¦à¥‹à¤‰, à¤¬à¤¿à¤·à¤¯à¤¾à¤²à¤‚à¤¬à¤¨ à¤¦à¥‹à¤‰à¥¤
à¤ªà¥à¤°à¥‡à¤®à¥€-à¤ªà¥à¤°à¥‡à¤®à¤¾à¤¸à¥à¤ªà¤¦ à¤¦à¥‹à¤‰, à¤¤à¤¤à¥à¤¸à¥à¤–-à¤¸à¥à¤–à¤¿à¤¯à¤¾ à¤¦à¥‹à¤‰à¥¥
à¤²à¥€à¤²à¤¾-à¤†à¤¸à¥à¤µà¤¾à¤¦à¤¨-à¤¨à¤¿à¤°à¤¤, à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤°à¤¸à¤°à¤¾à¤œà¥¤
à¤¬à¤¿à¤¤à¤°à¤¤ à¤°à¤¸ à¤¦à¥‹à¤‰ à¤¦à¥à¤¹à¥à¤¨ à¤•à¥Œà¤‚, à¤°à¤šà¤¿ à¤¬à¤¿à¤šà¤¿à¤¤à¥à¤° à¤¸à¥à¤ à¤¿ à¤¸à¤¾à¤œà¥¥
à¤¸à¤¹à¤¿à¤¤ à¤¬à¤¿à¤°à¥‹à¤§à¥€ à¤§à¤°à¥à¤®-à¤—à¥à¤¨ à¤œà¥à¤—à¤ªà¤¤ à¤¨à¤¿à¤¤à¥à¤¯ à¤…à¤¨à¤‚à¤¤à¥¤
à¤¬à¤šà¤¨à¤¾à¤¤à¥€à¤¤ à¤…à¤šà¤¿à¤¨à¥à¤¤à¥à¤¯ à¤…à¤¤à¤¿, à¤¸à¥à¤·à¤®à¤¾à¤®à¤¯ à¤¶à¥à¤°à¥€à¤®à¤‚à¤¤à¥¥
à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾-à¤®à¤¾à¤§à¤µ-à¤šà¤°à¤¨ à¤¬à¤‚à¤¦à¥Œà¤‚ à¤¬à¤¾à¤°à¤‚à¤¬à¤¾à¤°à¥¤
à¤à¤• à¤¤à¤¤à¥à¤¤à¥à¤µ à¤¦à¥‹ à¤¤à¤¨à¥ à¤§à¤°à¥‡à¤‚, à¤¨à¤¿à¤¤-à¤°à¤¸-à¤ªà¤¾à¤°à¤¾à¤¬à¤¾à¤°à¥¥''',
          );

        case '1.à¤°à¤¾à¤§à¤¿à¤•à¥‡ ! à¤¤à¥à¤® à¤®à¤® à¤œà¥€à¤µà¤¨-à¤®à¥‚à¤²à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(1)

à¤°à¤¾à¤§à¤¿à¤•à¥‡ ! à¤¤à¥à¤® à¤®à¤® à¤œà¥€à¤µà¤¨-à¤®à¥‚à¤²à¥¤ 
à¤…à¤¨à¥à¤ªà¤® à¤…à¤®à¤° à¤ªà¥à¤°à¤¾à¤¨-à¤¸à¤‚à¤œà¥€à¤µà¤¨à¤¿, à¤¨à¤¹à¤¿à¤‚ à¤•à¤¹à¥à¤ à¤•à¥‹à¤‰ à¤¸à¤®à¤¤à¥‚à¤²à¥¥
à¤œà¤¸ à¤¸à¤°à¥€à¤° à¤®à¥‡à¤‚ à¤¨à¤¿à¤œ-à¤¨à¤¿à¤œ à¤¥à¤¾à¤¨à¤¹à¤¿à¤‚ à¤¸à¤¬à¤¹à¥€ à¤¸à¥‹à¤­à¤¿à¤¤ à¤…à¤‚à¤—à¥¤
à¤•à¤¿à¤‚à¤¤à¥ à¤ªà¥à¤°à¤¾à¤¨ à¤¬à¤¿à¤¨à¥ à¤¸à¤¬à¤¹à¤¿ à¤¬à¥à¤¯à¤°à¥à¤¥, à¤¨à¤¹à¤¿à¤‚ à¤°à¤¹à¤¤ à¤•à¤¤à¤¹à¥à¤ à¤•à¥‹à¤‰ à¤°à¤‚à¤—à¥¥
à¤¤à¤¸ à¤¤à¥à¤® à¤ªà¥à¤°à¤¿à¤¯à¥‡ ! à¤¸à¤¬à¤¨à¤¿ à¤•à¥‡ à¤¸à¥à¤– à¤•à¥€ à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤†à¤§à¤¾à¤°à¥¤
à¤¤à¥à¤®à¥à¤¹à¤°à¥‡ à¤¬à¤¿à¤¨à¤¾ à¤¨à¤¹à¥€à¤‚ à¤œà¥€à¤µà¤¨-à¤°à¤¸, à¤œà¤¾à¤¸à¥Œà¤‚ à¤¸à¤¬ à¤•à¥Œ à¤ªà¥à¤¯à¤¾à¤°à¥¥
à¤¤à¥à¤®à¥à¤¹à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤¨à¤¨à¤¿ à¤¸à¥Œà¤‚ à¤…à¤¨à¥à¤ªà¥à¤°à¤¾à¤¨à¤¿à¤¤, à¤¤à¥à¤®à¥à¤¹à¤°à¥‡ à¤®à¤¨ à¤®à¤¨à¤µà¤¾à¤¨à¥¤
à¤¤à¥à¤®à¥à¤¹à¤°à¥Œ à¤ªà¥à¤°à¥‡à¤®-à¤¸à¤¿à¤‚à¤§à¥-à¤¸à¥€à¤•à¤° à¤²à¥ˆ à¤•à¤°à¥Œà¤‚ à¤¸à¤¬à¤¹à¤¿ à¤°à¤¸à¤¦à¤¾à¤¨à¥¥
à¤¤à¥à¤®à¥à¤¹à¤°à¥‡ à¤°à¤¸-à¤­à¤‚à¤¡à¤¾à¤° à¤ªà¥à¤¨à¥à¤¯ à¤¤à¥ˆà¤‚ à¤ªà¤¾à¤µà¤¤ à¤­à¤¿à¤šà¥à¤›à¥à¤• à¤šà¥‚à¤¨à¥¤
à¤¤à¥à¤® à¤¸à¤® à¤•à¥‡à¤µà¤² à¤¤à¥à¤®à¤¹à¤¿ à¤à¤• à¤¹à¥Œ, à¤¤à¤¨à¤¿à¤• à¤¨ à¤®à¤¾à¤¨à¥Œ à¤Šà¤¨à¥¥
à¤¸à¥‹à¤Š à¤…à¤¤à¤¿ à¤®à¤°à¤œà¤¾à¤¦à¤¾, à¤…à¤¤à¤¿ à¤¸à¤‚à¤­à¥à¤°à¤®-à¤­à¤¯-à¤¦à¥ˆà¤¨à¥à¤¯-à¤¸à¤à¤•à¥‹à¤šà¥¤
à¤¨à¤¹à¤¿à¤‚ à¤•à¥‹à¤‰ à¤•à¤¤à¤¹à¥à¤ à¤•à¤¬à¤¹à¥à¤ à¤¤à¥à¤®-à¤¸à¥€ à¤°à¤¸à¤¸à¥à¤µà¤¾à¤®à¤¿à¤¨à¤¿ à¤¨à¤¿à¤¸à¥à¤¸à¤‚à¤•à¥‹à¤šà¥¤
à¤¤à¥à¤®à¥à¤¹à¤°à¥Œ à¤¸à¥à¤µà¤¤à¥à¤µ à¤…à¤¨à¤‚à¤¤ à¤¨à¤¿à¤¤à¥à¤¯, à¤¸à¤¬ à¤­à¤¾à¤à¤¤à¤¿ à¤ªà¥‚à¤°à¥à¤¨ à¤…à¤§à¤¿à¤•à¤¾à¤°à¥¤
à¤•à¤¾à¤¯à¤¬à¥à¤¯à¥‚à¤¹ à¤¨à¤¿à¤œ à¤°à¤¸-à¤¬à¤¿à¤¤à¤°à¤¨ à¤•à¤°à¤µà¤¾à¤µà¤¤à¤¿ à¤ªà¤°à¤® à¤‰à¤¦à¤¾à¤°à¥¥
à¤¤à¥à¤®à¥à¤¹à¤°à¥€ à¤®à¤§à¥à¤° à¤°à¤¹à¤¸à¥à¤¯à¤®à¤ˆ à¤®à¥‹à¤¹à¤¨à¤¿ à¤®à¤¾à¤¯à¤¾ à¤¸à¥Œà¤‚ à¤¨à¤¿à¤¤à¥à¤¯à¥¤
à¤¦à¤šà¥à¤›à¤¿à¤¨ à¤¬à¤¾à¤® à¤°à¤¸à¤¾à¤¸à¥à¤µà¤¾à¤¦à¤¨ à¤¹à¤¿à¤¤ à¤¬à¤¨à¤¤à¥Œ à¤°à¤¹à¥‚à¤ à¤¨à¤¿à¤®à¤¿à¤¤à¥à¤¤à¥¥''',
          );

        case '2.à¤¹à¥Œà¤‚ à¤¤à¥‹ à¤¦à¤¾à¤¸à¥€ à¤¨à¤¿à¤¤à¥à¤¯ à¤¤à¤¿à¤¹à¤¾à¤°à¥€à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(2)

à¤¹à¥Œà¤‚ à¤¤à¥‹ à¤¦à¤¾à¤¸à¥€ à¤¨à¤¿à¤¤à¥à¤¯ à¤¤à¤¿à¤¹à¤¾à¤°à¥€à¥¤
à¤ªà¥à¤°à¤¾à¤¨à¤¨à¤¾à¤¥ à¤œà¥€à¤µà¤¨à¤§à¤¨ à¤®à¥‡à¤°à¥‡, à¤¹à¥Œà¤‚ à¤¤à¥à¤® à¤ªà¥ˆ à¤¬à¤²à¤¿à¤¹à¤¾à¤°à¥€à¥¥
à¤šà¤¾à¤¹à¥ˆà¤‚ à¤¤à¥à¤® à¤…à¤¤à¤¿ à¤ªà¥à¤°à¥‡à¤® à¤•à¤°à¥Œ, à¤¤à¤¨-à¤®à¤¨ à¤¸à¥Œà¤‚ à¤®à¥‹à¤¹à¤¿ à¤…à¤ªà¤¨à¤¾à¤”à¥¤
à¤šà¤¾à¤¹à¥ˆà¤‚ à¤¦à¥à¤°à¥‹à¤¹ à¤•à¤°à¥Œ, à¤¤à¥à¤°à¤¾à¤¸à¥Œ, à¤¦à¥à¤– à¤¦à¥‡à¤‡ à¤®à¥‹à¤¹à¤¿ à¤›à¤¿à¤Ÿà¤•à¤¾à¤”à¥¥
à¤¤à¥à¤®à¥à¤¹à¤°à¥Œ à¤¸à¥à¤– à¤¹à¥€ à¤¹à¥ˆ à¤®à¥‡à¤°à¥Œ à¤¸à¥à¤–, à¤†à¤¨ à¤¨ à¤•à¤›à¥ à¤¸à¥à¤– à¤œà¤¾à¤¨à¥Œà¤‚à¥¤
à¤œà¥‹ à¤¤à¥à¤® à¤¸à¥à¤–à¥€ à¤¹à¥‹à¤‰ à¤®à¥‹ à¤¦à¥à¤– à¤®à¥‡à¤‚, à¤…à¤¨à¥à¤ªà¤® à¤¸à¥à¤– à¤¹à¥Œà¤‚ à¤®à¤¾à¤¨à¥Œà¤‚à¥¥
à¤¸à¥à¤– à¤­à¥‹à¤—à¥Œà¤‚ à¤¤à¥à¤®à¥à¤¹à¤°à¥‡ à¤¸à¥à¤– à¤•à¤¾à¤°à¤¨, à¤”à¤° à¤¨ à¤•à¤›à¥ à¤®à¤¨ à¤®à¥‡à¤°à¥‡à¥¤
à¤¤à¥à¤®à¤¹à¤¿ à¤¸à¥à¤–à¥€ à¤¨à¤¿à¤¤ à¤¦à¥‡à¤–à¤¨ à¤šà¤¾à¤¹à¥Œà¤‚ à¤¨à¤¿à¤¸-à¤¦à¤¿à¤¨ à¤¸à¤¾à¤à¤-à¤¸à¤¬à¥‡à¤°à¥‡à¥¥
à¤¤à¥à¤®à¤¹à¤¿ à¤¸à¥à¤–à¥€ à¤¦à¥‡à¤–à¤¨ à¤¹à¤¿à¤¤ à¤¹à¥Œà¤‚ à¤¨à¤¿à¤œ à¤¤à¤¨-à¤®à¤¨ à¤•à¥Œà¤‚ à¤¸à¥à¤– à¤¦à¥‡à¤Šà¤à¥¤
à¤¤à¥à¤®à¤¹à¤¿ à¤¸à¤®à¤°à¤ªà¤¨ à¤•à¤°à¤¿ à¤…à¤ªà¤¨à¥‡ à¤•à¥Œà¤‚ à¤¨à¤¿à¤¤ à¤¤à¤µ à¤°à¥à¤šà¤¿ à¤•à¥Œà¤‚ à¤¸à¥‡à¤Šà¤à¥¥
à¤¤à¥à¤® à¤®à¥‹à¤¹à¤¿ â€˜à¤ªà¥à¤°à¤¾à¤¨à¥‡à¤¸à¥à¤µà¤°à¤¿â€™, â€˜à¤¹à¥ƒà¤¦à¤¯à¥‡à¤¸à¥à¤µà¤°à¤¿â€™, â€˜à¤•à¤¾à¤‚à¤¤à¤¾â€™ à¤•à¤¹à¤¿ à¤¸à¤šà¥ à¤ªà¤¾à¤µà¥Œà¥¤
à¤¯à¤¾à¤¤à¥ˆà¤‚ à¤¹à¥Œà¤‚ à¤¸à¥à¤µà¥€à¤•à¤¾à¤° à¤•à¤°à¥Œà¤‚ à¤¸à¤¬, à¤œà¤¦à¥à¤¯à¤ªà¤¿ à¤®à¤¨ à¤¸à¤•à¥à¤šà¤¾à¤µà¥Œà¤‚à¥¥''',
          );

        case '3.à¤¹à¥‡ à¤†à¤°à¤¾à¤§à¥à¤¯à¤¾ à¤°à¤¾à¤§à¤¾ ! à¤®à¥‡à¤°à¥‡ à¤®à¤¨à¤•à¤¾ à¤¤à¥à¤à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤¿à¤µà¤¾à¤¸à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(3)

à¤¹à¥‡ à¤†à¤°à¤¾à¤§à¥à¤¯à¤¾ à¤°à¤¾à¤§à¤¾ ! à¤®à¥‡à¤°à¥‡ à¤®à¤¨à¤•à¤¾ à¤¤à¥à¤à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤¿à¤µà¤¾à¤¸à¥¤
à¤¤à¥‡à¤°à¥‡ à¤¹à¥€ à¤¦à¤°à¥à¤¶à¤¨ à¤•à¤¾à¤°à¤£ à¤®à¥ˆà¤‚ à¤•à¤°à¤¤à¤¾ à¤¹à¥‚à¤ à¤—à¥‹à¤•à¥à¤²à¤®à¥‡à¤‚ à¤µà¤¾à¤¸à¥¥
à¤¤à¥‡à¤°à¤¾ à¤¹à¥€ à¤°à¤¸-à¤¤à¤¤à¥à¤¤à¥à¤µ à¤œà¤¾à¤¨à¤¨à¤¾, à¤•à¤°à¤¨à¤¾ à¤‰à¤¸à¤•à¤¾ à¤†à¤¸à¥à¤µà¤¾à¤¦à¤¨à¥¤
à¤‡à¤¸à¥€ à¤¹à¥‡à¤¤à¥ à¤¦à¤¿à¤¨-à¤°à¤¾à¤¤ à¤˜à¥‚à¤®à¤¤à¤¾ à¤®à¥ˆà¤‚ à¤•à¤°à¤¤à¤¾ à¤µà¤‚à¤¶à¥€à¤µà¤¾à¤¦à¤¨à¥¥
à¤‡à¤¸à¥€ à¤¹à¥‡à¤¤à¥ à¤¸à¥à¤¨à¤¾à¤¨à¤•à¥‹ à¤œà¤¾à¤¤à¤¾, à¤¬à¥ˆà¤ à¤¾ à¤°à¤¹à¤¤à¤¾ à¤¯à¤®à¥à¤¨à¤¾-à¤¤à¥€à¤°à¥¤
à¤¤à¥‡à¤°à¥€ à¤°à¥‚à¤ªà¤®à¤¾à¤§à¥à¤°à¥€à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨à¤¹à¤¿à¤¤ à¤°à¤¹à¤¤à¤¾ à¤šà¤¿à¤¤à¥à¤¤ à¤…à¤§à¥€à¤°à¥¥
à¤‡à¤¸à¥€ à¤¹à¥‡à¤¤à¥ à¤°à¤¹à¤¤à¤¾ à¤•à¤¦à¤®à¥à¤¬à¤¤à¤², à¤•à¤°à¤¤à¤¾ à¤¤à¥‡à¤°à¤¾ à¤¹à¥€ à¤¨à¤¿à¤¤ à¤§à¥à¤¯à¤¾à¤¨à¥¤
à¤¸à¤¦à¤¾ à¤¤à¤°à¤¸à¤¤à¤¾ à¤šà¤¾à¤¤à¤•à¤•à¥€ à¤œà¥à¤¯à¥‹à¤‚, à¤°à¥‚à¤ª-à¤¸à¥à¤µà¤¾à¤¤à¤¿à¤•à¤¾ à¤•à¤°à¤¨à¥‡ à¤ªà¤¾à¤¨à¥¥
à¤¤à¥‡à¤°à¥€ à¤°à¥‚à¤ª-à¤¶à¥€à¤²-à¤—à¥à¤£-à¤®à¤¾à¤§à¥à¤°à¤¿ à¤®à¤§à¥à¤° à¤¨à¤¿à¤¤à¥à¤¯ à¤²à¥‡à¤¤à¥€ à¤šà¤¿à¤¤ à¤šà¥‹à¤°à¥¤
à¤ªà¥à¤°à¥‡à¤®à¤—à¤¾à¤¨ à¤•à¤°à¤¤à¤¾ à¤¨à¤¿à¤¤ à¤¤à¥‡à¤°à¤¾, à¤°à¤¹à¤¤à¤¾ à¤‰à¤¸à¤®à¥‡à¤‚ à¤¸à¤¦à¤¾ à¤µà¤¿à¤­à¥‹à¤°à¥¥''',
          );

        case '4.à¤®à¥‡à¤°à¥€ à¤‡à¤¸ à¤µà¤¿à¤¨à¥€à¤¤ à¤µà¤¿à¤¨à¤¤à¥€à¤•à¥‹ à¤¸à¥à¤¨ à¤²à¥‹, à¤¹à¥‡ à¤µà¥à¤°à¤œà¤°à¤¾à¤œà¤•à¥à¤®à¤¾à¤° !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(4)

à¤®à¥‡à¤°à¥€ à¤‡à¤¸ à¤µà¤¿à¤¨à¥€à¤¤ à¤µà¤¿à¤¨à¤¤à¥€à¤•à¥‹ à¤¸à¥à¤¨ à¤²à¥‹, à¤¹à¥‡ à¤µà¥à¤°à¤œà¤°à¤¾à¤œà¤•à¥à¤®à¤¾à¤° !
à¤¯à¥à¤—-à¤¯à¥à¤—, à¤œà¤¨à¥à¤®-à¤œà¤¨à¥à¤®à¤®à¥‡à¤‚ à¤®à¥‡à¤°à¥‡ à¤¤à¥à¤® à¤¹à¥€ à¤¬à¤¨à¥‹ à¤œà¥€à¤µà¤¨à¤¾à¤§à¤¾à¤°à¥¥
à¤ªà¤¦-à¤ªà¤™à¥à¤•à¤œ-à¤ªà¤°à¤¾à¤—à¤•à¥€ à¤®à¥ˆà¤‚ à¤¨à¤¿à¤¤ à¤…à¤²à¤¿à¤¨à¥€ à¤¬à¤¨à¥€ à¤°à¤¹à¥‚à¤, à¤¨à¤à¤¦à¤²à¤¾à¤² !
à¤²à¤¿à¤ªà¤Ÿà¥€ à¤°à¤¹à¥‚à¤ à¤¸à¤¦à¤¾ à¤¤à¥à¤®à¤¸à¥‡ à¤®à¥ˆà¤‚ à¤•à¤¨à¤•à¤²à¤¤à¤¾ à¤œà¥à¤¯à¥‹à¤‚ à¤¤à¤°à¥à¤£ à¤¤à¤®à¤¾à¤²à¥¥
à¤¦à¤¾à¤¸à¥€ à¤®à¥ˆà¤‚ à¤¹à¥‹ à¤šà¥à¤•à¥€ à¤¸à¤¦à¤¾à¤•à¥‹ à¤…à¤°à¥à¤ªà¤£à¤•à¤° à¤šà¤°à¤£à¥‹à¤‚à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¾à¤£à¥¤
à¤ªà¥à¤°à¥‡à¤®-à¤¦à¤¾à¤®à¤¸à¥‡ à¤¬à¤à¤§ à¤šà¤°à¤£à¥‹à¤‚à¤®à¥‡à¤‚, à¤ªà¥à¤°à¤¾à¤£ à¤¹à¥‹ à¤—à¤¯à¥‡ à¤§à¤¨à¥à¤¯ à¤®à¤¹à¤¾à¤¨à¥¥
à¤¦à¥‡à¤– à¤²à¤¿à¤¯à¤¾ à¤¤à¥à¤°à¤¿à¤­à¥à¤µà¤¨à¤®à¥‡à¤‚ à¤¬à¤¿à¤¨à¤¾ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥‡ à¤”à¤° à¤•à¥Œà¤¨ à¤®à¥‡à¤°à¤¾à¥¤
à¤•à¥Œà¤¨ à¤ªà¥‚à¤›à¤¤à¤¾ à¤¹à¥ˆ â€˜à¤°à¤¾à¤§à¤¾â€™ à¤•à¤¹, à¤•à¤¿à¤¸à¤•à¥‹ à¤°à¤¾à¤§à¤¾à¤¨à¥‡ à¤¹à¥‡à¤°à¤¾à¥¥
à¤‡à¤¸ à¤•à¥à¤², à¤‰à¤¸ à¤•à¥à¤²â€”à¤¦à¥‹à¤¨à¥‹à¤‚ à¤•à¥à¤², à¤—à¥‹à¤•à¥à¤²à¤®à¥‡à¤‚ à¤®à¥‡à¤°à¤¾ à¤…à¤ªà¤¨à¤¾ à¤•à¥Œà¤¨ !
à¤…à¤°à¥à¤£ à¤®à¥ƒà¤¦à¥à¤² à¤ªà¤¦-à¤•à¤®à¤²à¥‹à¤‚à¤•à¥€ à¤²à¥‡ à¤¶à¤°à¤£ à¤…à¤¨à¤¨à¥à¤¯ à¤—à¤¯à¥€ à¤¹à¥‹ à¤®à¥Œà¤¨à¥¥
à¤¦à¥‡à¤–à¥‡ à¤¬à¤¿à¤¨à¤¾ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤ªà¤²à¤­à¤° à¤­à¥€ à¤®à¥à¤à¥‡ à¤¨à¤¹à¥€à¤‚ à¤ªà¤¡à¤¼à¤¤à¤¾ à¤¹à¥ˆ à¤šà¥ˆà¤¨à¥¤
à¤¤à¥à¤® à¤¹à¥€ à¤ªà¥à¤°à¤¾à¤£à¤¨à¤¾à¤¥ à¤¨à¤¿à¤¤ à¤®à¥‡à¤°à¥‡, à¤•à¤¿à¤¸à¥‡ à¤¸à¥à¤¨à¤¾à¤Šà¤ à¤®à¤¨à¤•à¥‡ à¤¬à¥ˆà¤¨à¥¥
à¤°à¥‚à¤ª-à¤¶à¥€à¤²-à¤—à¥à¤£-à¤¹à¥€à¤¨ à¤¸à¤®à¤à¤•à¤° à¤•à¤¿à¤¤à¤¨à¤¾ à¤¹à¥€ à¤¦à¥à¤¤à¤•à¤¾à¤°à¥‹ à¤¤à¥à¤®à¥¤
à¤šà¤°à¤£à¤§à¥‚à¤²à¤¿ à¤®à¥ˆà¤‚, à¤šà¤°à¤£à¥‹à¤‚à¤®à¥‡à¤‚ à¤¹à¥€ à¤²à¤—à¥€ à¤°à¤¹à¥‚à¤à¤—à¥€ à¤¬à¤¸, à¤¹à¤°à¤¦à¤®à¥¥''',
          );

        case '5.à¤¹à¥‡ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤°à¤¾à¤œà¤¨à¤¨à¥à¤¦à¤¿à¤¨à¤¿ ! à¤¹à¥‡ à¤…à¤¤à¥à¤² à¤ªà¥à¤°à¥‡à¤®-à¤°à¤¸-à¤¸à¥à¤§à¤¾-à¤¨à¤¿à¤§à¤¾à¤¨ !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(5)

à¤¹à¥‡ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤°à¤¾à¤œà¤¨à¤¨à¥à¤¦à¤¿à¤¨à¤¿ ! à¤¹à¥‡ à¤…à¤¤à¥à¤² à¤ªà¥à¤°à¥‡à¤®-à¤°à¤¸-à¤¸à¥à¤§à¤¾-à¤¨à¤¿à¤§à¤¾à¤¨ ! 
à¤—à¤¾à¤¯ à¤šà¤°à¤¾à¤¤à¤¾ à¤µà¤¨-à¤µà¤¨ à¤­à¤Ÿà¤•à¥‚à¤, à¤•à¥à¤¯à¤¾ à¤¸à¤®à¤à¥‚à¤ à¤®à¥ˆà¤‚ à¤ªà¥à¤°à¥‡à¤®-à¤µà¤¿à¤§à¤¾à¤¨ !       
à¤—à¥à¤µà¤¾à¤²-à¤¬à¤¾à¤²à¤•à¥‹à¤‚à¤•à¥‡ à¤¸à¤à¤— à¤¡à¥‹à¤²à¥‚à¤, à¤–à¥‡à¤²à¥‚à¤ à¤¸à¤¦à¤¾ à¤—à¤à¤µà¤¾à¤°à¥‚ à¤–à¥‡à¤²à¥¤
à¤ªà¥à¤°à¥‡à¤®-à¤¸à¥à¤§à¤¾-à¤¸à¤°à¤¿à¤¤à¤¾ à¤¤à¥à¤®à¤¸à¥‡ à¤®à¥à¤ à¤¤à¤ªà¥à¤¤ à¤§à¥‚à¤²à¤•à¤¾ à¤•à¥ˆà¤¸à¤¾ à¤®à¥‡à¤² !  
à¤¤à¥à¤® à¤¸à¥à¤µà¤¾à¤®à¤¿à¤¨à¤¿ à¤…à¤¨à¥à¤°à¤¾à¤—à¤¿à¤£à¤¿ ! à¤œà¤¬ à¤¦à¥‡à¤¤à¥€ à¤¹à¥‹ à¤ªà¥à¤°à¥‡à¤®à¤­à¤°à¥‡ à¤¦à¤°à¥à¤¶à¤¨à¥¤
à¤¤à¤¬ à¤…à¤¤à¤¿ à¤¸à¥à¤– à¤ªà¤¾à¤¤à¤¾ à¤®à¥ˆà¤‚, à¤®à¥à¤à¤ªà¤° à¤¬à¤¢à¤¼à¤¤à¤¾ à¤…à¤®à¤¿à¤¤ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤‹à¤£à¥¥
à¤•à¥ˆà¤¸à¥‡ à¤‹à¤£à¤•à¤¾ à¤¶à¥‹à¤§ à¤•à¤°à¥‚à¤ à¤®à¥ˆà¤‚, à¤¨à¤¿à¤¤à¥à¤¯ à¤ªà¥à¤°à¥‡à¤®-à¤§à¤¨à¤•à¤¾ à¤•à¤‚à¤—à¤¾à¤² ! 
à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤¦à¤¯à¤¾ à¤•à¤° à¤ªà¥à¤°à¥‡à¤®à¤¦à¤¾à¤¨ à¤¦à¥‡ à¤®à¥à¤à¤•à¥‹ à¤•à¤°à¤¤à¥€ à¤°à¤¹à¥‹ à¤¨à¤¿à¤¹à¤¾à¤²à¥¥''',
          );

        case '6.à¤¸à¥à¤¨à¥à¤¦à¤° à¤¶à¥à¤¯à¤¾à¤® à¤•à¤®à¤²-à¤¦à¤²-à¤²à¥‹à¤šà¤¨ à¤¦à¥à¤–à¤®à¥‹à¤šà¤¨ à¤µà¥à¤°à¤œà¤°à¤¾à¤œà¤•à¤¿à¤¶à¥‹à¤°à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(6)

à¤¸à¥à¤¨à¥à¤¦à¤° à¤¶à¥à¤¯à¤¾à¤® à¤•à¤®à¤²-à¤¦à¤²-à¤²à¥‹à¤šà¤¨ à¤¦à¥à¤–à¤®à¥‹à¤šà¤¨ à¤µà¥à¤°à¤œà¤°à¤¾à¤œà¤•à¤¿à¤¶à¥‹à¤°à¥¤
à¤¦à¥‡à¤–à¥‚à¤ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤¹à¤¿à¤¯-à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚, à¤¹à¥‡ à¤®à¥‡à¤°à¥‡ à¤šà¤¿à¤¤à¤šà¥‹à¤° !
à¤²à¥‹à¤•-à¤®à¤¾à¤¨-à¤•à¥à¤²-à¤®à¤°à¥à¤¯à¤¾à¤¦à¤¾à¤•à¥‡ à¤¶à¥ˆà¤² à¤¸à¤­à¥€ à¤•à¤° à¤šà¤•à¤¨à¤¾à¤šà¥‚à¤°à¥¤
à¤°à¤•à¥à¤–à¥‚à¤ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤¸à¤®à¥€à¤ª à¤¸à¤¦à¤¾ à¤®à¥ˆà¤‚, à¤•à¤°à¥‚à¤ à¤¨ à¤ªà¤²à¤• à¤¤à¤¨à¤¿à¤•à¤­à¤° à¤¦à¥‚à¤°à¥¥
à¤ªà¤° à¤®à¥ˆà¤‚ à¤…à¤¤à¤¿ à¤—à¤à¤µà¤¾à¤° à¤—à¥à¤µà¤¾à¤²à¤¿à¤¨à¤¿ à¤—à¥à¤£à¤°à¤¹à¤¿à¤¤ à¤•à¤²à¤™à¥à¤•à¥€ à¤¸à¤¦à¤¾ à¤•à¥à¤°à¥‚à¤ªà¥¤
à¤¤à¥à¤® à¤¨à¤¾à¤—à¤° à¤—à¥à¤£-à¤†à¤—à¤° à¤…à¤¤à¤¿à¤¶à¤¯ à¤•à¥à¤²à¤­à¥‚à¤·à¤£ à¤¸à¥Œà¤¨à¥à¤¦à¤°à¥à¤¯-à¤¸à¥à¤µà¤°à¥‚à¤ªà¥¥     
à¤®à¥ˆà¤‚ à¤°à¤¸-à¤œà¥à¤žà¤¾à¤¨-à¤°à¤¹à¤¿à¤¤ à¤°à¤¸à¤µà¤°à¥à¤œà¤¿à¤¤, à¤¤à¥à¤® à¤°à¤¸à¤¨à¤¿à¤ªà¥à¤£ à¤°à¤¸à¤¿à¤• à¤¸à¤¿à¤°à¤¤à¤¾à¤œà¥¥
à¤‡à¤¤à¤¨à¥‡à¤ªà¤° à¤­à¥€ à¤¦à¤¯à¤¾à¤¸à¤¿à¤¨à¥à¤§à¥ à¤¤à¥à¤® à¤®à¥‡à¤°à¥‡ à¤‰à¤°à¤®à¥‡à¤‚ à¤°à¤¹à¥‡ à¤µà¤¿à¤°à¤¾à¤œà¥¥''',
          );

        case '7.à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ à¤°à¤¾à¤§à¤¿à¤•à¥‡ ! à¤¤à¥‡à¤°à¥€ à¤®à¤¹à¤¿à¤®à¤¾ à¤…à¤¨à¥à¤ªà¤® à¤…à¤•à¤¥ à¤…à¤¨à¤¨à¥à¤¤à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(7)

à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ à¤°à¤¾à¤§à¤¿à¤•à¥‡ ! à¤¤à¥‡à¤°à¥€ à¤®à¤¹à¤¿à¤®à¤¾ à¤…à¤¨à¥à¤ªà¤® à¤…à¤•à¤¥ à¤…à¤¨à¤¨à¥à¤¤à¥¤
à¤¯à¥à¤—-à¤¯à¥à¤—à¤¸à¥‡ à¤—à¤¾à¤¤à¤¾ à¤®à¥ˆà¤‚ à¤…à¤µà¤¿à¤°à¤¤, à¤¨à¤¹à¥€à¤‚ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤ªà¤¾à¤¤à¤¾ à¤…à¤¨à¥à¤¤à¥¥
à¤¸à¥à¤§à¤¾à¤¨à¤¨à¥à¤¦ à¤¬à¤°à¤¸à¤¾à¤¤à¤¾ à¤¹à¤¿à¤¯à¤®à¥‡à¤‚ à¤¤à¥‡à¤°à¤¾ à¤®à¤§à¥à¤° à¤µà¤šà¤¨ à¤…à¤¨à¤®à¥‹à¤²à¥¤
à¤¬à¤¿à¤•à¤¾ à¤¸à¤¦à¤¾à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤®à¤§à¥à¤° à¤¦à¥ƒà¤—-à¤•à¤®à¤² à¤•à¥à¤Ÿà¤¿à¤² à¤­à¥à¤°à¥à¤•à¥à¤Ÿà¥€à¤•à¥‡ à¤®à¥‹à¤²à¥¥
à¤œà¤ªà¤¤à¤¾ à¤¤à¥‡à¤°à¤¾ à¤¨à¤¾à¤® à¤®à¤§à¥à¤° à¤…à¤¨à¥à¤ªà¤® à¤®à¥à¤°à¤²à¥€à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤²à¤²à¤¾à¤®à¥¤
à¤¨à¤¿à¤¤ à¤…à¤¤à¥ƒà¤ªà¥à¤¤ à¤¨à¤¯à¤¨à¥‹à¤‚à¤¸à¥‡ à¤¤à¥‡à¤°à¤¾ à¤°à¥‚à¤ª à¤¦à¥‡à¤–à¤¤à¤¾ à¤…à¤¤à¤¿ à¤…à¤­à¤¿à¤°à¤¾à¤®à¥¥
à¤•à¤¹à¥€à¤‚ à¤¨ à¤®à¤¿à¤²à¤¾ à¤ªà¥à¤°à¥‡à¤® à¤¶à¥à¤šà¤¿ à¤à¤¸à¤¾, à¤•à¤¹à¥€à¤‚ à¤¨ à¤ªà¥‚à¤°à¥€ à¤®à¤¨à¤•à¥€ à¤†à¤¶à¥¤
à¤à¤• à¤¤à¥à¤à¥€à¤•à¥‹ à¤ªà¤¾à¤¯à¤¾ à¤®à¥ˆà¤‚à¤¨à¥‡, à¤œà¤¿à¤¸à¤¨à¥‡ à¤•à¤¿à¤¯à¤¾ à¤ªà¥‚à¤°à¥à¤£ à¤…à¤­à¤¿à¤²à¤¾à¤·à¥¥ 
à¤¨à¤¿à¤¤à¥à¤¯ à¤¤à¥ƒà¤ªà¥à¤¤, à¤¨à¤¿à¤·à¥à¤•à¤¾à¤® à¤¨à¤¿à¤¤à¥à¤¯à¤®à¥‡à¤‚ à¤®à¤§à¥à¤° à¤…à¤¤à¥ƒà¤ªà¥à¤¤à¤¿, à¤®à¤§à¥à¤°à¤¤à¤® à¤•à¤¾à¤®à¥¤
à¤¤à¥‡à¤°à¥‡ à¤¦à¤¿à¤µà¥à¤¯ à¤ªà¥à¤°à¥‡à¤®à¤•à¤¾ à¤¹à¥ˆ à¤¯à¤¹ à¤œà¤¾à¤¦à¥‚à¤­à¤°à¤¾ à¤®à¤§à¥à¤° à¤ªà¤°à¤¿à¤£à¤¾à¤®à¥¥''',
          );

        case '8.à¤¸à¤¦à¤¾ à¤¸à¥‹à¤šà¤¤à¥€ à¤°à¤¹à¤¤à¥€ à¤¹à¥‚à¤ à¤®à¥ˆà¤‚â€”à¤•à¥à¤¯à¤¾ à¤¦à¥‚à¤ à¤¤à¥à¤®à¤•à¥‹, à¤œà¥€à¤µà¤¨à¤§à¤¨ !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(8)

à¤¸à¤¦à¤¾ à¤¸à¥‹à¤šà¤¤à¥€ à¤°à¤¹à¤¤à¥€ à¤¹à¥‚à¤ à¤®à¥ˆà¤‚â€”à¤•à¥à¤¯à¤¾ à¤¦à¥‚à¤ à¤¤à¥à¤®ko, à¤œà¥€à¤µà¤¨à¤§à¤¨ !
à¤œà¥‹ à¤§à¤¨ à¤¦à¥‡à¤¨à¤¾ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤šà¤¾à¤¹à¤¤à¥€, à¤¤à¥à¤® à¤¹à¥€ à¤¹à¥‹ à¤µà¤¹ à¤®à¥‡à¤°à¤¾ à¤§à¤¨à¥¥
à¤¤à¥à¤® à¤¹à¥€ à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤£à¤ªà¥à¤°à¤¿à¤¯ à¤¹à¥‹, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¸à¤¦à¤¾ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤®à¥ˆà¤‚à¥¤
à¤µà¤¸à¥à¤¤à¥ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤¤à¥à¤®à¤•à¥‹ à¤¦à¥‡à¤¤à¥‡ à¤ªà¤²-à¤ªà¤² à¤¹à¥‚à¤ à¤¬à¤²à¤¿à¤¹à¤¾à¤°à¥€ à¤®à¥ˆà¤‚à¥¥
à¤ªà¥à¤¯à¤¾à¤°à¥‡ ! à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤¸à¥à¤¨à¤¾à¤Šà¤ à¤•à¥ˆà¤¸à¥‡ à¤…à¤ªà¤¨à¥‡ à¤®à¤¨à¤•à¥€ à¤¸à¤¹à¤¿à¤¤ à¤µà¤¿à¤µà¥‡à¤•à¥¤
à¤…à¤¨à¥à¤¯à¥‹à¤‚à¤•à¥‡ à¤…à¤¨à¥‡à¤•, à¤ªà¤° à¤®à¥‡à¤°à¥‡ à¤¤à¥‹ à¤¤à¥à¤® à¤¹à¥€ à¤¹à¥‹, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤à¤•à¥¥
à¤®à¥‡à¤°à¥‡ à¤¸à¤­à¥€ à¤¸à¤¾à¤§à¤¨à¥‹à¤‚à¤•à¥€ à¤¬à¤¸, à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤¹à¥‹ à¤¤à¥à¤® à¤¹à¥€ à¤¸à¤¿à¤¦à¥à¤§à¤¿à¥¤
à¤¤à¥à¤®à¤¹à¥€ à¤ªà¥à¤°à¤¾à¤£à¤¨à¤¾à¤¥ à¤¹à¥‹ à¤¬à¤¸, à¤¤à¥à¤® à¤¹à¥€ à¤¹à¥‹ à¤®à¥‡à¤°à¥€ à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¤®à¥ƒà¤¦à¥à¤§à¤¿à¥¥
à¤¤à¤¨-à¤§à¤¨-à¤œà¤¨à¤•à¤¾ à¤¬à¤¨à¥à¤§à¤¨ à¤Ÿà¥‚à¤Ÿà¤¾, à¤›à¥‚à¤Ÿà¤¾, à¤­à¥‹à¤—-à¤®à¥‹à¤•à¥à¤·à¤•à¤¾ à¤°à¥‹à¤—à¥¤
à¤§à¤¨à¥à¤¯ à¤¹à¥à¤ˆ à¤®à¥ˆà¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤ªà¤¾à¤•à¤° à¤à¤• à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤ªà¥à¤°à¤¿à¤¯ à¤¸à¤‚à¤¯à¥‹à¤—à¥¥''',
          );

        case '9.à¤°à¤¾à¤§à¥‡, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡, à¤ªà¥à¤°à¤¾à¤£-à¤ªà¥à¤°à¤¤à¤¿à¤®à¥‡, à¤¹à¥‡ à¤®à¥‡à¤°à¥€ à¤œà¥€à¤µà¤¨ à¤®à¥‚à¤² !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(9)

à¤°à¤¾à¤§à¥‡, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡, à¤ªà¥à¤°à¤¾à¤£-à¤ªà¥à¤°à¤¤à¤¿à¤®à¥‡, à¤¹à¥‡ à¤®à¥‡à¤°à¥€ à¤œà¥€à¤µà¤¨ à¤®à¥‚à¤² !
à¤ªà¤²à¤­à¤° à¤­à¥€ à¤¨ à¤•à¤­à¥€ à¤°à¤¹ à¤¸à¤•à¤¤à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¥‡ à¤®à¤§à¥à¤° ! à¤®à¥ˆà¤‚ à¤¤à¥à¤®à¤•à¥‹ à¤­à¥‚à¤²à¥¥
à¤¶à¥à¤µà¤¾à¤¸-à¤¶à¥à¤µà¤¾à¤¸à¤®à¥‡à¤‚ à¤¤à¥‡à¤°à¥€ à¤¸à¥à¤®à¥ƒà¤¤à¤¿à¤•à¤¾ à¤¨à¤¿à¤¤à¥à¤¯ à¤ªà¤µà¤¿à¤¤à¥à¤° à¤¸à¥à¤°à¥‹à¤¤à¤¾ à¤¬à¤¹à¤¤à¤¾à¥¤
à¤°à¥‹à¤®-à¤°à¥‹à¤® à¤…à¤¤à¤¿ à¤ªà¥à¤²à¤•à¤¿à¤¤ à¤¤à¥‡à¤°à¤¾ à¤†à¤²à¤¿à¤™à¥à¤—à¤¨ à¤•à¤°à¤¤à¤¾ à¤°à¤¹à¤¤à¤¾à¥¥
à¤¨à¥‡à¤¤à¥à¤° à¤¦à¥‡à¤–à¤¤à¥‡ à¤¤à¥à¤à¥‡ à¤¨à¤¿à¤¤à¥à¤¯ à¤¹à¥€, à¤¸à¥à¤¨à¤¤à¥‡ à¤¶à¤¬à¥à¤¦ à¤®à¤§à¥à¤° à¤¯à¤¹ à¤•à¤¾à¤¨à¥¤
à¤¨à¤¾à¤¸à¤¾ à¤…à¤™à¥à¤—-à¤¸à¥à¤—à¤¨à¥à¤§ à¤¸à¥‚à¤à¤˜à¤¤à¥€, à¤°à¤¸à¤¨à¤¾ à¤…à¤§à¤°-à¤¸à¥à¤§à¤¾-à¤°à¤¸-à¤ªà¤¾à¤¨à¥¥
à¤…à¤™à¥à¤—-à¤…à¤™à¥à¤— à¤¶à¥à¤šà¤¿ à¤ªà¤¾à¤¤à¥‡ à¤¨à¤¿à¤¤ à¤¹à¥€ à¤¤à¥‡à¤°à¤¾ à¤ªà¥à¤¯à¤¾à¤°à¤¾ à¤…à¤™à¥à¤—-à¤¸à¥à¤ªà¤°à¥à¤¶à¥¤
à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤µà¥€à¤¨ à¤ªà¥à¤°à¥‡à¤®-à¤°à¤¸ à¤¬à¤¢à¤¼à¤¤à¤¾, à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤µà¥€à¤¨ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤¹à¤°à¥à¤·à¥¥''',
          );

        case '10.à¤®à¥‡à¤°à¥‡ à¤§à¤¨-à¤œà¤¨-à¤œà¥€à¤µà¤¨ à¤¤à¥à¤® à¤¹à¥€, à¤¤à¥à¤® à¤¹à¥€ à¤¤à¤¨-à¤®à¤¨, à¤¤à¥à¤® à¤¸à¤¬ à¤§à¤°à¥à¤®à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(10)

à¤®à¥‡à¤°à¥‡ à¤§à¤¨-à¤œà¤¨-à¤œà¥€à¤µà¤¨ à¤¤à¥à¤® à¤¹à¥€, à¤¤à¥à¤® à¤¹à¥€ à¤¤à¤¨-à¤®à¤¨, à¤¤à¥à¤® à¤¸à¤¬ à¤§à¤°à¥à¤®à¥¤
à¤¤à¥à¤® à¤¹à¥€ à¤®à¥‡à¤°à¥‡ à¤¸à¤•à¤² à¤¸à¥à¤–à¤¸à¤¦à¤¨, à¤ªà¥à¤°à¤¿à¤¯ à¤¨à¤¿à¤œ à¤œà¤¨, à¤ªà¥à¤°à¤¾à¤£à¥‹à¤‚à¤•à¥‡ à¤®à¤°à¥à¤®à¥¥
à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤à¤• à¤¬à¤¸, à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾, à¤¤à¥à¤® à¤¹à¥€ à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤¹à¥‹ à¤ªà¥‚à¤°à¥à¤¤à¤¿à¥¤
à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤à¤• à¤¸à¤¬ à¤•à¤¾à¤² à¤¸à¤­à¥€ à¤µà¤¿à¤§à¤¿ à¤¹à¥‹ à¤‰à¤ªà¤¾à¤¸à¥à¤¯ à¤¶à¥à¤šà¤¿ à¤¸à¥à¤¨à¥à¤¦à¤° à¤®à¥‚à¤°à¥à¤¤à¥€à¥¥
à¤¤à¥à¤® à¤¹à¥€ à¤•à¤¾à¤®-à¤§à¤¾à¤® à¤¸à¤¬ à¤®à¥‡à¤°à¥‡, à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤¤à¥à¤® à¤²à¤•à¥à¤·à¥à¤¯ à¤®à¤¹à¤¾à¤¨à¥¤
à¤†à¤ à¥‹à¤‚ à¤ªà¤¹à¤° à¤¬à¤¸à¥‡ à¤°à¤¹à¤¤à¥‡ à¤¤à¥à¤® à¤®à¤® à¤®à¤¨-à¤®à¤¨à¥à¤¦à¤¿à¤°à¤®à¥‡à¤‚ à¤­à¤—à¤µà¤¾à¤¨à¥¥
à¤¸à¤­à¥€ à¤‡à¤¨à¥à¤¦à¥à¤°à¤¿à¤¯à¥‹à¤‚à¤•à¥‹ à¤¤à¥à¤® à¤¶à¥à¤šà¤¿à¤¤à¤® à¤•à¤°à¤¤à¥‡ à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¥à¤ªà¤°à¥à¤¶-à¤¸à¥à¤–-à¤¦à¤¾à¤¨à¥¤
à¤¬à¤¾à¤¹à¥à¤¯à¤¾à¤­à¥à¤¯à¤¨à¥à¤¤à¤° à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤¤à¥à¤® à¤›à¥‡à¤¡à¤¼à¥‡ à¤°à¤¹à¤¤à¥‡ à¤¨à¤¿à¤œ à¤¤à¤¾à¤¨à¥¥
à¤•à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤¤à¥à¤® à¤“à¤à¤² à¤¹à¥‹à¤¤à¥‡, à¤•à¤­à¥€ à¤¨à¤¹à¥€à¤‚ à¤¤à¤œà¤¤à¥‡ à¤¸à¤‚à¤¯à¥‹à¤—à¥¤
à¤˜à¥à¤²à¥‡-à¤®à¤¿à¤²à¥‡ à¤°à¤¹à¤¤à¥‡ à¤•à¤°à¤µà¤¾à¤¤à¥‡ à¤•à¤°à¤¤à¥‡ à¤¨à¤¿à¤°à¥à¤®à¤² à¤°à¤¸-à¤¸à¤®à¥à¤­à¥‹à¤—à¥¥
à¤ªà¤° à¤‡à¤¸à¤®à¥‡à¤‚ à¤¨ à¤•à¤­à¥€ à¤®à¤¤à¤²à¤¬ à¤•à¥à¤› à¤®à¥‡à¤°à¤¾ à¤¤à¥à¤®à¤¸à¥‡ à¤°à¤¹à¤¤à¤¾ à¤­à¤¿à¤¨à¥à¤¨à¥¤
à¤¹à¥à¤ à¤¸à¤­à¥€ à¤¸à¤‚à¤•à¤²à¥à¤ª à¤­à¤™à¥à¤— à¤®à¥ˆà¤‚-à¤®à¥‡à¤°à¥‡à¤•à¥‡ à¤¸à¤®à¥‚à¤² à¤¤à¤°à¥ à¤›à¤¿à¤¨à¥à¤¨à¥¥
à¤­à¥‹à¤•à¥à¤¤à¤¾-à¤­à¥‹à¤—à¥à¤¯ à¤¸à¤­à¥€ à¤•à¥à¤› à¤¤à¥à¤® à¤¹à¥‹, à¤¤à¥à¤® à¤¹à¥€ à¤¸à¥à¤µà¤¯à¤‚ à¤¬à¤¨à¥‡ à¤¹à¥‹ à¤­à¥‹à¤—à¥¤
à¤®à¥‡à¤°à¤¾ à¤®à¤¨ à¤¬à¤¨ à¤¸à¤­à¥€ à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤¹à¥‹ à¤…à¤¨à¥à¤­à¤µ à¤•à¤°à¤¤à¥‡ à¤¯à¥‹à¤—-à¤µà¤¿à¤¯à¥‹à¤—à¥¥''',
          );

        case '11.à¤®à¥‡à¤°à¤¾ à¤¤à¤¨-à¤®à¤¨ à¤¸à¤¬ à¤¤à¥‡à¤°à¤¾ à¤¹à¥€, à¤¤à¥‚ à¤¹à¥€ à¤¸à¤¦à¤¾ à¤¸à¥à¤µà¤¾à¤®à¤¿à¤¨à¥€ à¤à¤•à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(11)

à¤®à¥‡à¤°à¤¾ à¤¤à¤¨-à¤®à¤¨ à¤¸à¤¬ à¤¤à¥‡à¤°à¤¾ à¤¹à¥€, à¤¤à¥‚ à¤¹à¥€ à¤¸à¤¦à¤¾ à¤¸à¥à¤µà¤¾à¤®à¤¿à¤¨à¥€ à¤à¤•à¥¤
à¤…à¤¨à¥à¤¯à¥‹à¤‚à¤•à¤¾ à¤‰à¤ªà¤­à¥‹à¤—à¥à¤¯ à¤¨ à¤­à¥‹à¤•à¥à¤¤à¤¾ à¤¹à¥ˆ à¤•à¤¦à¤¾à¤ªà¤¿, à¤¯à¤¹ à¤¸à¤šà¥à¤šà¥€ à¤Ÿà¥‡à¤•à¥¥
à¤¤à¤¨ à¤¸à¤®à¥€à¤ª à¤°à¤¹à¤¤à¤¾ à¤¨ à¤¸à¥à¤¥à¥‚à¤²à¤¤:, à¤ªà¤° à¤œà¥‹ à¤®à¥‡à¤°à¤¾ à¤¸à¥‚à¤•à¥à¤·à¥à¤® à¤¶à¤°à¥€à¤°à¥¤
à¤•à¥à¤·à¤£à¤­à¤° à¤­à¥€ à¤¨ à¤µà¤¿à¤²à¤— à¤°à¤¹ à¤ªà¤¾à¤¤à¤¾, à¤¹à¥‹ à¤‰à¤ à¤¤à¤¾ à¤…à¤¤à¥à¤¯à¤¨à¥à¤¤ à¤…à¤§à¥€à¤°à¥¥
à¤°à¤¹à¤¤à¤¾ à¤¸à¤¦à¤¾ à¤œà¥à¤¡à¤¼à¤¾ à¤¤à¥à¤à¤¸à¥‡ à¤¹à¥€, à¤…à¤¤: à¤¬à¤¸à¤¾ à¤¤à¥‡à¤°à¥‡ à¤ªà¤¦-à¤ªà¥à¤°à¤¾à¤¨à¥à¤¤à¥¤
à¤¤à¥‚ à¤¹à¥€ à¤‰à¤¸à¤•à¥€ à¤à¤•à¤®à¤¾à¤¤à¥à¤° à¤œà¥€à¤µà¤¨à¤•à¥€ à¤œà¥€à¤µà¤¨ à¤¹à¥ˆ à¤¨à¤¿à¤°à¥à¤­à¥à¤°à¤¾à¤¨à¥à¤¤à¥¥
à¤¹à¥à¤† à¤¨ à¤¹à¥‹à¤—à¤¾ à¤…à¤¨à¥à¤¯ à¤•à¤¿à¤¸à¥€à¤•à¤¾ à¤‰à¤¸à¤ªà¤° à¤•à¤­à¥€ à¤¤à¤¨à¤¿à¤• à¤…à¤§à¤¿à¤•à¤¾à¤°à¥¤
à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¸à¥€à¤•à¥‹ à¤¸à¥à¤– à¤¦à¥‡à¤—à¤¾, à¤²à¥‡à¤—à¤¾ à¤¨ à¤•à¤¿à¤¸à¥€à¤¸à¥‡ à¤•à¤¿à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤°à¥¥
à¤¯à¤¦à¤¿ à¤µà¤¹ à¤•à¤­à¥€ à¤•à¤¿à¤¸à¥€à¤¸à¥‡ à¤•à¤¿à¤‚à¤šà¤¿à¤¤à¥ à¤¦à¤¿à¤–à¤¤à¤¾ à¤•à¤°à¤¤à¤¾-à¤ªà¤¾à¤¤à¤¾ à¤ªà¥à¤¯à¤¾à¤°à¥¤
à¤µà¤¹ à¤¸à¤¬ à¤¤à¥‡à¤°à¥‡ à¤¹à¥€ à¤°à¤¸à¤•à¤¾ à¤¬à¤¸, à¤¹à¥ˆ à¤•à¥‡à¤µà¤² à¤ªà¤µà¤¿à¤¤à¥à¤° à¤µà¤¿à¤¸à¥à¤¤à¤¾à¤°à¥¥
à¤•à¤¹ à¤¸à¤•à¤¤à¥€ à¤¤à¥‚ à¤®à¥à¤à¥‡ à¤¸à¤­à¥€ à¤•à¥à¤›, à¤®à¥ˆà¤‚ à¤¤à¥‹ à¤¨à¤¿à¤¤ à¤¤à¥‡à¤°à¥‡ à¤†à¤§à¥€à¤¨à¥¤
à¤ªà¤° à¤¨ à¤®à¤¾à¤¨à¤¨à¤¾ à¤•à¤­à¥€ à¤…à¤¨à¥à¤¯à¤¥à¤¾, à¤•à¤­à¥€ à¤¨ à¤•à¤¹à¤¨à¤¾ à¤¨à¤¿à¤œà¤•à¥‹ à¤¦à¥€à¤¨à¥¥
à¤‡à¤¤à¤¨à¥‡ à¤ªà¤° à¤­à¥€ à¤®à¥ˆà¤‚ à¤¤à¥‡à¤°à¥‡ à¤®à¤¨à¤•à¥€ à¤¨ à¤•à¤­à¥€ à¤¹à¥‚à¤ à¤•à¤° à¤ªà¤¾à¤¤à¤¾à¥¤
à¤…à¤¤: à¤¬à¤¨à¤¾ à¤°à¤¹à¤¤à¤¾ à¤¹à¥‚à¤ à¤¸à¤‚à¤¤à¤¤ à¤¤à¥à¤à¤•à¥‹ à¤¦à¥à¤–à¤•à¤¾ à¤¹à¥€ à¤¦à¤¾à¤¤à¤¾à¥¥
à¤…à¤ªà¤¨à¥€ à¤“à¤° à¤¦à¥‡à¤– à¤¤à¥‚ à¤®à¥‡à¤°à¥‡ à¤¸à¤¬ à¤…à¤ªà¤°à¤¾à¤§à¥‹à¤‚à¤•à¥‹ à¤œà¤¾ à¤­à¥‚à¤²à¥¤
à¤•à¤°à¤¤à¥€ à¤°à¤¹ à¤•à¥ƒà¤¤à¤¾à¤°à¥à¤¥ à¤®à¥à¤à¤•à¥‹ à¤µà¥‡ à¤ªà¤¾à¤µà¤¨ à¤ªà¤¦-à¤ªà¤™à¥à¤•à¤œà¤•à¥€ à¤§à¥‚à¤²à¥¥''',
          );

        case '12.à¤¤à¥à¤®à¤¸à¥‡ à¤¸à¤¦à¤¾ à¤²à¤¿à¤¯à¤¾ à¤¹à¥€ à¤®à¥ˆà¤‚à¤¨à¥‡, à¤²à¥‡à¤¤à¥€-à¤²à¥‡à¤¤à¥€ à¤¥à¤•à¥€ à¤¨à¤¹à¥€à¤‚à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(12)

à¤¤à¥à¤®à¤¸à¥‡ à¤¸à¤¦à¤¾ à¤²à¤¿à¤¯à¤¾ à¤¹à¥€ à¤®à¥ˆà¤‚à¤¨à¥‡, à¤²à¥‡à¤¤à¥€-à¤²à¥‡à¤¤à¥€ à¤¥à¤•à¥€ à¤¨à¤¹à¥€à¤‚à¥¤
à¤…à¤®à¤¿à¤¤ à¤ªà¥à¤°à¥‡à¤®-à¤¸à¥Œà¤­à¤¾à¤—à¥à¤¯ à¤®à¤¿à¤²à¤¾, à¤ªà¤° à¤®à¥ˆà¤‚ à¤•à¥à¤› à¤­à¥€ à¤¦à¥‡ à¤¸à¤•à¥€ à¤¨à¤¹à¥€à¤‚à¥¥
à¤®à¥‡à¤°à¥€ à¤¤à¥à¤°à¥à¤Ÿà¤¿, à¤®à¥‡à¤°à¥‡ à¤¦à¥‹à¤·à¥‹à¤‚à¤•à¥‹ à¤¤à¥à¤®à¤¨à¥‡ à¤¦à¥‡à¤–à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¤­à¥€à¥¤
à¤¦à¤¿à¤¯à¤¾ à¤¸à¤¦à¤¾, à¤¦à¥‡à¤¤à¥‡ à¤¨ à¤¥à¤•à¥‡ à¤¤à¥à¤®, à¤¦à¥‡ à¤¡à¤¾à¤²à¤¾ à¤¨à¤¿à¤œ à¤ªà¥à¤¯à¤¾à¤° à¤¸à¤­à¥€à¥¥
à¤¤à¤¬ à¤­à¥€ à¤•à¤¹à¤¤à¥‡â€”â€˜à¤¦à¥‡ à¤¨ à¤¸à¤•à¤¾ à¤®à¥ˆà¤‚ à¤¤à¥à¤®à¤•à¥‹ à¤•à¥à¤› à¤­à¥€, à¤¹à¥‡ à¤ªà¥à¤¯à¤¾à¤°à¥€ !
à¤¤à¥à¤®-à¤¸à¥€ à¤¶à¥€à¤²-à¤—à¥à¤£à¤µà¤¤à¥€ à¤¤à¥à¤® à¤¹à¥€, à¤®à¥ˆà¤‚ à¤¤à¥à¤®à¤ªà¤° à¤¹à¥‚à¤ à¤¬à¤²à¤¿à¤¹à¤¾à¤°à¥€â€™à¥¥       
à¤•à¥à¤¯à¤¾ à¤®à¥ˆà¤‚ à¤•à¤¹à¥‚à¤ à¤ªà¥à¤°à¤¾à¤£à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¤¸à¥‡, à¤¦à¥‡à¤– à¤²à¤œà¤¾à¤¤à¥€ à¤…à¤ªà¤¨à¥€ à¤“à¤°à¥¤
à¤®à¥‡à¤°à¥€ à¤¹à¤° à¤•à¤°à¤¨à¥€à¤®à¥‡à¤‚ à¤¹à¥€ à¤¤à¥à¤® à¤ªà¥à¤°à¥‡à¤® à¤¦à¥‡à¤–à¤¤à¥‡ à¤¨à¤¨à¥à¤¦à¤•à¤¿à¤¶à¥‹à¤° !à¥¥''',
          );

        case '13.à¤°à¤¾à¤§à¥‡ ! à¤¤à¥‚ à¤¹à¥€ à¤šà¤¿à¤¤à¥à¤¤à¤°à¤žà¥à¤œà¤¨à¥€, à¤¤à¥‚ à¤¹à¥€ à¤šà¥‡à¤¤à¤¨à¤¤à¤¾ à¤®à¥‡à¤°à¥€à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(13)

à¤°à¤¾à¤§à¥‡ ! à¤¤à¥‚ à¤¹à¥€ à¤šà¤¿à¤¤à¥à¤¤à¤°à¤žà¥à¤œà¤¨à¥€, à¤¤à¥‚ à¤¹à¥€ à¤šà¥‡à¤¤à¤¨à¤¤à¤¾ à¤®à¥‡à¤°à¥€à¥¤
à¤¤à¥‚ à¤¹à¥€ à¤¨à¤¿à¤¤à¥à¤¯ à¤†à¤¤à¥à¤®à¤¾ à¤®à¥‡à¤°à¥€, à¤®à¥ˆà¤‚ à¤¹à¥‚à¤ à¤¬à¤¸, à¤†à¤¤à¥à¤®à¤¾ à¤¤à¥‡à¤°à¥€à¥¥
à¤¤à¥‡à¤°à¥‡ à¤œà¥€à¤µà¤¨à¤¸à¥‡ à¤œà¥€à¤µà¤¨ à¤¹à¥ˆ, à¤¤à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‹à¤‚à¤¸à¥‡ à¤¹à¥ˆà¤‚ à¤ªà¥à¤°à¤¾à¤£à¥¤
à¤¤à¥‚ à¤¹à¥€ à¤®à¤¨, à¤®à¤¤à¤¿, à¤šà¤•à¥à¤·à¥, à¤•à¤°à¥à¤£, à¤¤à¥à¤µà¤•à¥, à¤°à¤¸à¤¨à¤¾, à¤¤à¥‚ à¤¹à¥€ à¤‡à¤¨à¥à¤¦à¥à¤°à¤¿à¤¯-à¤˜à¥à¤°à¤¾à¤£à¥¥
à¤¤à¥‚ à¤¹à¥€ à¤¸à¥à¤¥à¥‚à¤²-à¤¸à¥‚à¤•à¥à¤·à¥à¤® à¤‡à¤¨à¥à¤¦à¥à¤°à¤¿à¤¯à¤•à¥‡ à¤µà¤¿à¤·à¤¯ à¤¸à¤­à¥€ à¤®à¥‡à¤°à¥‡ à¤¸à¥à¤–à¤°à¥‚à¤ªà¥¤
à¤¤à¥‚ à¤¹à¥€ à¤®à¥ˆà¤‚, à¤®à¥ˆà¤‚ à¤¹à¥€ à¤¤à¥‚ à¤¬à¤¸, à¤¤à¥‡à¤°à¤¾-à¤®à¥‡à¤°à¤¾ à¤¸à¤®à¥à¤¬à¤¨à¥à¤§ à¤…à¤¨à¥‚à¤ªà¥¥
à¤¤à¥‡à¤°à¥‡ à¤¬à¤¿à¤¨à¤¾ à¤¨ à¤®à¥ˆà¤‚ à¤¹à¥‚à¤, à¤®à¥‡à¤°à¥‡ à¤¬à¤¿à¤¨à¤¾ à¤¨ à¤¤à¥‚ à¤°à¤–à¤¤à¥€ à¤…à¤¸à¥à¤¤à¤¿à¤¤à¥à¤µà¥¤
à¤…à¤µà¤¿à¤¨à¤¾à¤­à¤¾à¤µ à¤µà¤¿à¤²à¤•à¥à¤·à¤£ à¤¯à¤¹ à¤¸à¤®à¥à¤¬à¤¨à¥à¤§, à¤¯à¤¹à¥€ à¤¬à¤¸, à¤œà¥€à¤µà¤¨-à¤¤à¤¤à¥à¤¤à¥à¤µà¥¥''',
          );

        case '14.à¤¤à¥à¤® à¤…à¤¨à¤¨à¥à¤¤ à¤¸à¥Œà¤¨à¥à¤¦à¤°à¥à¤¯-à¤¸à¥à¤§à¤¾-à¤¨à¤¿à¤§à¤¿, à¤¤à¥à¤®à¤®à¥‡à¤‚ à¤¸à¤¬ à¤®à¤¾à¤§à¥à¤°à¥à¤¯ à¤…à¤¨à¤¨à¥à¤¤à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(14)

à¤¤à¥à¤® à¤…à¤¨à¤¨à¥à¤¤ à¤¸à¥Œà¤¨à¥à¤¦à¤°à¥à¤¯-à¤¸à¥à¤§à¤¾-à¤¨à¤¿à¤§à¤¿, à¤¤à¥à¤®à¤®à¥‡à¤‚ à¤¸à¤¬ à¤®à¤¾à¤§à¥à¤°à¥à¤¯ à¤…à¤¨à¤¨à¥à¤¤à¥¤
à¤¤à¥à¤® à¤…à¤¨à¤¨à¥à¤¤ à¤à¤¶à¥à¤µà¤°à¥à¤¯-à¤®à¤¹à¥‹à¤¦à¤§à¤¿, à¤¤à¥à¤®à¤®à¥‡à¤‚ à¤¸à¤¬ à¤¶à¥à¤šà¤¿ à¤¶à¥Œà¤°à¥à¤¯ à¤…à¤¨à¤¨à¥à¤¤à¥¥
à¤¸à¤•à¤² à¤¦à¤¿à¤µà¥à¤¯ à¤¸à¤¦à¥à¤—à¥à¤£-à¤¸à¤¾à¤—à¤° à¤¤à¥à¤® à¤²à¤¹à¤°à¤¾à¤¤à¥‡ à¤¸à¤¬ à¤“à¤° à¤…à¤¨à¤¨à¥à¤¤à¥¤
à¤¸à¤•à¤² à¤¦à¤¿à¤µà¥à¤¯ à¤°à¤¸-à¤¨à¤¿à¤§à¤¿ à¤¤à¥à¤® à¤…à¤¨à¥à¤ªà¤®, à¤ªà¥‚à¤°à¥à¤£ à¤°à¤¸à¤¿à¤•, à¤°à¤¸à¤°à¥‚à¤ª à¤…à¤¨à¤¨à¥à¤¤à¥¥
à¤‡à¤¸ à¤ªà¥à¤°à¤•à¤¾à¤° à¤œà¥‹ à¤¸à¤­à¥€ à¤—à¥à¤£à¥‹à¤‚à¤®à¥‡à¤‚, à¤°à¤¸à¤®à¥‡à¤‚ à¤…à¤®à¤¿à¤¤ à¤…à¤¸à¥€à¤® à¤…à¤ªà¤¾à¤°à¥¤
à¤¨à¤¹à¥€à¤‚ à¤•à¤¿à¤¸à¥€ à¤—à¥à¤£-à¤°à¤¸à¤•à¥€ à¤‰à¤¸à¥‡ à¤…à¤ªà¥‡à¤•à¥à¤·à¤¾ à¤•à¥à¤› à¤­à¥€ à¤•à¤¿à¤¸à¥€ à¤ªà¥à¤°à¤•à¤¾à¤°à¥¥
à¤«à¤¿à¤° à¤®à¥ˆà¤‚ à¤¤à¥‹ à¤—à¥à¤£à¤°à¤¹à¤¿à¤¤ à¤¸à¤°à¥à¤µà¤¥à¤¾, à¤•à¥à¤¤à¥à¤¸à¤¿à¤¤-à¤—à¤¤à¤¿, à¤¸à¤¬ à¤­à¤¾à¤à¤¤à¤¿ à¤—à¤à¤µà¤¾à¤°à¥¤
à¤¸à¥à¤¨à¥à¤¦à¤°à¤¤à¤¾-à¤®à¤§à¥à¤°à¤¤à¤¾-à¤°à¤¹à¤¿à¤¤ à¤•à¤°à¥à¤•à¤¶ à¤•à¥à¤°à¥‚à¤ª à¤…à¤¤à¤¿ à¤¦à¥‹à¤·à¤¾à¤—à¤¾à¤°à¥¥
à¤¨à¤¹à¥€à¤‚ à¤µà¤¸à¥à¤¤à¥ à¤•à¥à¤› à¤­à¥€ à¤à¤¸à¥€, à¤œà¤¿à¤¸à¤¸à¥‡ à¤¤à¥à¤®à¤•à¥‹ à¤®à¥ˆà¤‚ à¤¦à¥‚à¤ à¤°à¤¸à¤¦à¤¾à¤¨à¥¤
à¤œà¤¿à¤¸à¤¸à¥‡ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤°à¤¿à¤à¤¾à¤Šà¤, à¤œà¤¿à¤¸à¤¸à¥‡ à¤•à¤°à¥‚à¤ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤ªà¥‚à¤œà¤¨-à¤®à¤¾à¤¨à¥¥
à¤à¤• à¤µà¤¸à¥à¤¤à¥ à¤®à¥à¤à¤®à¥‡à¤‚ à¤…à¤¨à¤¨à¥à¤¯ à¤†à¤¤à¥à¤¯à¤¨à¥à¤¤à¤¿à¤• à¤¹à¥ˆ à¤µà¤¿à¤°à¤¹à¤¿à¤¤ à¤‰à¤ªà¤®à¤¾à¤¨à¥¤
â€˜à¤®à¥à¤à¥‡ à¤¸à¤¦à¤¾ à¤ªà¥à¤°à¤¿à¤¯ à¤²à¤—à¤¤à¥‡ à¤¤à¥à¤®â€™â€”à¤¯à¤¹ à¤¤à¥à¤šà¥à¤› à¤•à¤¿à¤‚à¤¤à¥ à¤…à¤¤à¥à¤¯à¤¨à¥à¤¤ à¤®à¤¹à¤¾à¤¨à¥¥
à¤°à¥€à¤ à¤—à¤¯à¥‡ à¤¤à¥à¤® à¤‡à¤¸à¥€ à¤à¤• à¤ªà¤°, à¤•à¤¿à¤¯à¤¾ à¤®à¥à¤à¥‡ à¤¤à¥à¤®à¤¨à¥‡ à¤¸à¥à¤µà¥€à¤•à¤¾à¤°à¥¤
à¤¦à¤¿à¤¯à¤¾ à¤¸à¥à¤µà¤¯à¤‚ à¤†à¤•à¤° à¤…à¤ªà¤¨à¥‡à¤•à¥‹, à¤•à¤¿à¤¯à¤¾ à¤¨ à¤•à¥à¤› à¤­à¥€ à¤¸à¥‹à¤š-à¤µà¤¿à¤šà¤¾à¤°à¥¥
à¤­à¥‚à¤² à¤‰à¤šà¥à¤šà¤¤à¤¾ à¤­à¤—à¤µà¤¤à¥à¤¤à¤¾ à¤¸à¤¬ à¤¸à¤¤à¥à¤¤à¤¾à¤•à¤¾ à¤¸à¤¾à¤°à¤¾ à¤…à¤§à¤¿à¤•à¤¾à¤°à¥¤
à¤®à¥à¤ à¤¨à¤—à¤£à¥à¤¯à¤¸à¥‡ à¤®à¤¿à¤²à¥‡ à¤¤à¥à¤šà¥à¤› à¤¬à¤¨, à¤¸à¥à¤µà¤¯à¤‚ à¤›à¥‹à¤¡à¤¼ à¤¸à¤‚à¤•à¥‹à¤š-à¤¸à¤à¤­à¤¾à¤°à¥¥
à¤®à¤¾à¤¨à¥‹ à¤…à¤¤à¤¿ à¤†à¤¤à¥à¤° à¤®à¤¿à¤²à¤¨à¥‡à¤•à¥‹, à¤®à¤¾à¤¨à¥‹ à¤¹à¥‹ à¤…à¤¤à¥à¤¯à¤¨à¥à¤¤ à¤…à¤§à¥€à¤°à¥¤
à¤¤à¤¤à¥à¤¤à¥à¤µà¤°à¥‚à¤ªà¤¤à¤¾ à¤­à¥‚à¤² à¤¸à¤­à¥€ à¤¨à¥‡à¤¤à¥à¤°à¥‹à¤‚à¤¸à¥‡ à¤²à¤—à¥‡ à¤¬à¤¹à¤¾à¤¨à¥‡ à¤¨à¥€à¤°à¥¥
à¤¹à¥‹ à¤µà¥à¤¯à¤¾à¤•à¥à¤², à¤­à¤° à¤°à¤¸ à¤…à¤—à¤¾à¤§, à¤†à¤•à¤° à¤¶à¥à¤šà¤¿ à¤°à¤¸-à¤¸à¤°à¤¿à¤¤à¤¾à¤•à¥‡ à¤¤à¥€à¤°à¥¤
à¤•à¤°à¤¨à¥‡ à¤²à¤—à¥‡ à¤ªà¤°à¤® à¤…à¤µà¤—à¤¾à¤¹à¤¨, à¤¤à¥‹à¤¡à¤¼ à¤¸à¤­à¥€ à¤®à¤°à¥à¤¯à¤¾à¤¦à¤¾-à¤§à¥€à¤°à¥¥
à¤¬à¤¢à¤¼à¥€ à¤…à¤®à¤¿à¤¤, à¤‰à¤®à¤¡à¤¼à¥€ à¤°à¤¸-à¤¸à¤°à¤¿à¤¤à¤¾ à¤ªà¤¾à¤µà¤¨, à¤›à¤¾à¤¯à¥€ à¤šà¤¾à¤°à¥‹à¤‚ à¤“à¤°à¥¤
à¤¡à¥‚à¤¬à¥‡ à¤¸à¤­à¥€ à¤­à¥‡à¤¦ à¤‰à¤¸à¤®à¥‡à¤‚, à¤«à¤¿à¤° à¤°à¤¹à¤¾ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤“à¤° à¤¨ à¤›à¥‹à¤°à¥¥
à¤ªà¥à¤°à¥‡à¤®à¥€, à¤ªà¥à¤°à¥‡à¤®, à¤ªà¤°à¤® à¤ªà¥à¤°à¥‡à¤®à¤¾à¤¸à¥à¤ªà¤¦â€”à¤¨à¤¹à¥€à¤‚ à¤œà¥à¤žà¤¾à¤¨ à¤•à¥à¤›, à¤¹à¥à¤ à¤µà¤¿à¤­à¥‹à¤°à¥¤
à¤°à¤¾à¤§à¤¾ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤¹à¥‚à¤ à¤®à¥ˆà¤‚, à¤¯à¤¾ à¤¹à¥‹ à¤•à¥‡à¤µà¤² à¤¤à¥à¤® à¤ªà¥à¤°à¤¿à¤¯ à¤¨à¤¨à¥à¤¦à¤•à¤¿à¤¶à¥‹à¤°à¥¥''',
          );

        case '15.à¤°à¤¾à¤§à¤¾ ! à¤¤à¥à¤®-à¤¸à¥€ à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤à¤• à¤¹à¥‹, à¤¨à¤¹à¥€à¤‚ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤‰à¤ªà¤®à¤¾ à¤”à¤°à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(15)

à¤°à¤¾à¤§à¤¾ ! à¤¤à¥à¤®-à¤¸à¥€ à¤¤à¥à¤®à¥à¤¹à¥€à¤‚ à¤à¤• à¤¹à¥‹, à¤¨à¤¹à¥€à¤‚ à¤•à¤¹à¥€à¤‚ à¤­à¥€ à¤‰à¤ªà¤®à¤¾ à¤”à¤°à¥¤
à¤²à¤¹à¤°à¤¾à¤¤à¤¾ à¤…à¤¤à¥à¤¯à¤¨à¥à¤¤ à¤¸à¥à¤§à¤¾-à¤°à¤¸-à¤¸à¤¾à¤—à¤°, à¤œà¤¿à¤¸à¤•à¤¾ à¤“à¤° à¤¨ à¤›à¥‹à¤°à¥¥
à¤®à¥ˆà¤‚ à¤¨à¤¿à¤¤ à¤°à¤¹à¤¤à¤¾ à¤¡à¥‚à¤¬à¤¾ à¤‰à¤¸à¤®à¥‡à¤‚, à¤¨à¤¹à¥€à¤‚ à¤•à¤­à¥€ à¤Šà¤ªà¤° à¤†à¤¤à¤¾à¥¤
à¤•à¤­à¥€ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤¹à¥€ à¤‡à¤šà¥à¤›à¤¾à¤¸à¥‡ à¤¹à¥‚à¤ à¤²à¤¹à¤°à¥‹à¤‚à¤®à¥‡à¤‚ à¤²à¤¹à¤°à¤¾à¤¤à¤¾à¥¥        
à¤ªà¤° à¤µà¥‡ à¤²à¤¹à¤°à¥‡à¤‚ à¤­à¥€ à¤—à¤¾à¤¤à¥€ à¤¹à¥ˆà¤‚ à¤à¤• à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤°à¤®à¥à¤¯ à¤®à¤¹à¤¤à¥à¤¤à¥à¤µà¥¤
à¤‰à¤¨à¤•à¤¾ à¤¸à¤¬ à¤¸à¥Œà¤¨à¥à¤¦à¤°à¥à¤¯ à¤”à¤° à¤®à¤¾à¤§à¥à¤°à¥à¤¯ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤¹à¥€ à¤¹à¥ˆ à¤¸à¥à¤µà¤¤à¥à¤µà¥¥
à¤¤à¥‹ à¤­à¥€ à¤‰à¤¨à¤•à¥‡ à¤¬à¤¾à¤¹à¥à¤¯ à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤¹à¥€ à¤¬à¤¸, à¤®à¥ˆà¤‚ à¤¹à¥‚à¤ à¤²à¤¹à¤°à¤¾à¤¤à¤¾à¥¤
à¤•à¥‡à¤µà¤² à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤¸à¥à¤–à¥€ à¤•à¤°à¤¨à¥‡à¤•à¥‹ à¤¸à¤¹à¤œ à¤•à¤­à¥€ à¤Šà¤ªà¤° à¤†à¤¤à¤¾à¥¥
à¤à¤•à¤›à¤¤à¥à¤° à¤¸à¥à¤µà¤¾à¤®à¤¿à¤¨à¤¿ à¤¤à¥à¤® à¤®à¥‡à¤°à¥€ à¤…à¤¨à¥à¤•à¤®à¥à¤ªà¤¾ à¤…à¤¤à¤¿ à¤¬à¤°à¤¸à¤¾à¤¤à¥€à¥¤
à¤°à¤–à¤•à¤° à¤¸à¤¦à¤¾ à¤®à¥à¤à¥‡ à¤¸à¤‚à¤¨à¤¿à¤§à¤¿à¤®à¥‡à¤‚ à¤œà¥€à¤µà¤¨à¤•à¥‡ à¤•à¥à¤·à¤£ à¤¸à¤°à¤¸à¤¾à¤¤à¥€à¥¥
à¤…à¤®à¤¿à¤¤ à¤¨à¥‡à¤¤à¥à¤°à¤¸à¥‡ à¤—à¥à¤£-à¤¦à¤°à¥à¤¶à¤¨ à¤•à¤°, à¤¸à¤¦à¤¾ à¤¸à¤°à¤¾à¤¹à¤¾ à¤¹à¥€ à¤•à¤°à¤¤à¥€à¥¤
à¤¸à¤¦à¤¾ à¤¬à¤¢à¤¼à¤¾à¤¤à¥€ à¤¸à¥à¤– à¤…à¤¨à¥à¤ªà¤®, à¤‰à¤²à¥à¤²à¤¾à¤¸ à¤…à¤®à¤¿à¤¤ à¤‰à¤°à¤®à¥‡à¤‚ à¤­à¤°à¤¤à¥€à¥¥
à¤¸à¤¦à¤¾ à¤¸à¤¦à¤¾ à¤®à¥ˆà¤‚ à¤¸à¤¦à¤¾ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾, à¤¨à¤¹à¥€à¤‚ à¤•à¤¦à¤¾ à¤•à¥‹à¤ˆ à¤­à¥€ à¤…à¤¨à¥à¤¯à¥¤
à¤•à¤¹à¥€à¤‚ à¤œà¤°à¤¾ à¤­à¥€ à¤•à¤° à¤ªà¤¾à¤¤à¤¾ à¤…à¤§à¤¿à¤•à¤¾à¤° à¤¦à¤¾à¤¸à¤ªà¤° à¤¸à¤¦à¤¾ à¤…à¤¨à¤¨à¥à¤¯à¥¥
à¤œà¥ˆà¤¸à¥‡ à¤®à¥à¤à¥‡ à¤¨à¤šà¤¾à¤“à¤—à¥€ à¤¤à¥à¤®, à¤µà¥ˆà¤¸à¥‡ à¤¨à¤¿à¤¤à¥à¤¯ à¤•à¤°à¥‚à¤à¤—à¤¾ à¤¨à¥ƒà¤¤à¥à¤¯à¥¤
à¤¯à¤¹à¥€ à¤§à¤°à¥à¤® à¤¹à¥ˆ, à¤¸à¤¹à¤œ à¤ªà¥à¤°à¤•à¥ƒà¤¤à¤¿ à¤¯à¤¹, à¤¯à¤¹à¥€ à¤à¤• à¤¸à¥à¤µà¤¾à¤­à¤¾à¤µà¤¿à¤• à¤•à¥ƒà¤¤à¥à¤¯à¥¥''',
          );

        case '16.à¤¤à¥à¤® à¤¹à¥‹ à¤¯à¤¨à¥à¤¤à¥à¤°à¥€, à¤®à¥ˆà¤‚ à¤¯à¤¨à¥à¤¤à¥à¤°, à¤•à¤¾à¤ à¤•à¥€ à¤ªà¥à¤¤à¤²à¥€ à¤®à¥ˆà¤‚, à¤¤à¥à¤® à¤¸à¥‚à¤¤à¥à¤°à¤§à¤¾à¤°à¥¤':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(16)

à¤¤à¥à¤® à¤¹à¥‹ à¤¯à¤¨à¥à¤¤à¥à¤°à¥€, à¤®à¥ˆà¤‚ à¤¯à¤¨à¥à¤¤à¥à¤°, à¤•à¤¾à¤ à¤•à¥€ à¤ªà¥à¤¤à¤²à¥€ à¤®à¥ˆà¤‚, à¤¤à¥à¤® à¤¸à¥‚à¤¤à¥à¤°à¤§à¤¾à¤°à¥¤
à¤¤à¥à¤® à¤•à¤°à¤µà¤¾à¤“, à¤•à¤¹à¤²à¤¾à¤“, à¤®à¥à¤à¥‡ à¤¨à¤šà¤¾à¤“ à¤¨à¤¿à¤œ à¤‡à¤šà¥à¤›à¤¾à¤¨à¥à¤¸à¤¾à¤°à¥¥
à¤®à¥ˆà¤‚ à¤•à¤°à¥‚à¤, à¤•à¤¹à¥‚à¤, à¤¨à¤¾à¤šà¥‚à¤ à¤¨à¤¿à¤¤ à¤¹à¥€ à¤ªà¤°à¤¤à¤¨à¥à¤¤à¥à¤°, à¤¨ à¤•à¥‹à¤ˆ à¤…à¤¹à¤‚à¤•à¤¾à¤°à¥¤
à¤®à¤¨ à¤®à¥Œà¤¨ à¤¨à¤¹à¥€à¤‚, à¤®à¤¨ à¤¹à¥€ à¤¨ à¤ªà¥ƒà¤¥à¤•à¥, à¤®à¥ˆà¤‚ à¤…à¤•à¤² à¤–à¤¿à¤²à¥Œà¤¨à¤¾, à¤¤à¥à¤® à¤–à¤¿à¤²à¤¾à¤°à¥¥
à¤•à¥à¤¯à¤¾ à¤•à¤°à¥‚à¤, à¤¨à¤¹à¥€à¤‚ à¤•à¥à¤¯à¤¾ à¤•à¤°à¥‚à¤â€”à¤•à¤°à¥‚à¤ à¤‡à¤¸à¤•à¤¾ à¤®à¥ˆà¤‚ à¤•à¥ˆà¤¸à¥‡ à¤•à¥à¤› à¤µà¤¿à¤šà¤¾à¤° ?
à¤¤à¥à¤® à¤•à¤°à¥‹ à¤¸à¤¦à¤¾ à¤¸à¥à¤µà¤šà¥à¤›à¤¨à¥à¤¦, à¤¸à¥à¤–à¥€ à¤œà¥‹ à¤•à¤°à¥‡ à¤¤à¥à¤®à¥à¤¹à¥‡à¤‚ à¤¸à¥‹ à¤ªà¥à¤°à¤¿à¤¯ à¤µà¤¿à¤¹à¤¾à¤°à¥¥
à¤…à¤¨à¤¬à¥‹à¤², à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤¿à¤·à¥à¤•à¥à¤°à¤¿à¤¯, à¤¸à¥à¤ªà¤¨à¥à¤¦à¤¨à¤¸à¥‡ à¤°à¤¹à¤¿à¤¤, à¤¸à¤¦à¤¾ à¤®à¥ˆà¤‚ à¤¨à¤¿à¤°à¥à¤µà¤¿à¤•à¤¾à¤°à¥¤
à¤¤à¥à¤® à¤œà¤¬ à¤œà¥‹ à¤šà¤¾à¤¹à¥‹, à¤•à¤°à¥‹ à¤¸à¤¦à¤¾ à¤¬à¥‡à¤¶à¤°à¥à¤¤, à¤¨ à¤•à¥‹à¤ˆ à¤­à¥€ à¤•à¤°à¤¾à¤°à¥¥
à¤®à¤°à¤¨à¤¾-à¤œà¥€à¤¨à¤¾     à¤®à¥‡à¤°à¤¾      à¤•à¥ˆà¤¸à¤¾,   à¤•à¥ˆà¤¸à¤¾  à¤®à¥‡à¤°à¤¾  à¤®à¤¾à¤¨à¤¾à¤ªà¤®à¤¾à¤¨à¥¤
à¤¹à¥ˆà¤‚ à¤¸à¤­à¥€ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥‡ à¤¹à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® ! à¤¯à¥‡ à¤–à¥‡à¤² à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¥à¤–à¤®à¤¯ à¤®à¤¹à¤¾à¤¨à¥¥
à¤•à¤° à¤¦à¤¿à¤¯à¤¾ à¤•à¥à¤°à¥€à¤¡à¤¨à¤• à¤¬à¤¨à¤¾ à¤®à¥à¤à¥‡ à¤¨à¤¿à¤œ à¤•à¤°à¤•à¤¾ à¤¤à¥à¤®à¤¨à¥‡ à¤…à¤¤à¤¿ à¤¨à¤¿à¤¹à¤¾à¤²à¥¤
à¤¯à¤¹ à¤­à¥€ à¤•à¥ˆà¤¸à¥‡ à¤®à¤¾à¤¨à¥‚à¤-à¤œà¤¾à¤¨à¥‚à¤, à¤œà¤¾à¤¨à¥‹ à¤¤à¥à¤® à¤¹à¥€ à¤¨à¤¿à¤œ à¤¹à¤¾à¤²-à¤šà¤¾à¤²à¥¥
à¤‡à¤¤à¤¨à¤¾ à¤®à¥ˆà¤‚ à¤œà¥‹ à¤¯à¤¹ à¤¬à¥‹à¤² à¤—à¤¯à¥€, à¤¤à¥à¤® à¤œà¤¾à¤¨ à¤°à¤¹à¥‡â€”à¤¹à¥ˆ à¤•à¤¹à¤¾à¤ à¤•à¥Œà¤¨ ?
à¤¤à¥à¤® à¤¹à¥€ à¤¬à¥‹à¤²à¥‡ à¤­à¤° à¤¸à¥à¤° à¤®à¥à¤à¤®à¥‡à¤‚ à¤®à¥à¤–à¤°à¤¾-à¤¸à¥‡ à¤®à¥ˆà¤‚ à¤¤à¥‹ à¤¶à¥‚à¤¨à¥à¤¯ à¤®à¥Œà¤¨à¥¥''',
          );

        case 'à¤ªà¥à¤·à¥à¤ªà¤¿à¤•à¤¾':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(à¤ªà¥à¤·à¥à¤ªà¤¿à¤•à¤¾)

à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤°à¤¸à¤°à¤¾à¤œ à¤•à¥‡ à¤®à¤§à¥à¤° à¤®à¤¨à¥‹à¤¹à¤° à¤­à¤¾à¤µ à¥¤ 
à¤¦à¤¿à¤µà¥à¤¯, à¤®à¤§à¥à¤°à¤¤à¤®, à¤°à¤¾à¤—à¤®à¤¯, à¤¦à¥ˆà¤¨à¥à¤¯-à¤µà¤¿à¤­à¥‚à¤·à¤¿à¤¤ à¤šà¤¾à¤µà¥¥
à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¥‡ à¤²à¤¿à¤ à¤¸à¤¹à¤œ à¤¸à¤­à¥€ à¤•à¤° à¤¤à¥à¤¯à¤¾à¤—à¥¤
à¤¸à¥à¤–à¤¦ à¤ªà¤°à¤¸à¥à¤ªà¤° à¤¬à¤¨ à¤°à¤¹à¥‡, à¤›à¤²à¤• à¤°à¤¹à¤¾ à¤…à¤¨à¥à¤°à¤¾à¤—à¥¥
à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤•à¥‡ à¤¸à¤¦à¤¾ à¤ªà¥à¤°à¥‡à¤®à¥€-à¤ªà¥à¤°à¥‡à¤·à¥à¤  à¤®à¤¹à¤¾à¤¨à¥¤
à¤¨à¤¿à¤¤à¥à¤¯, à¤…à¤¨à¤‚à¤¤, à¤…à¤šà¤¿à¤‚à¤¤à¥à¤¯, à¤¶à¥à¤šà¤¿, à¤…à¤¨à¤¿à¤°à¥à¤µà¤¾à¤šà¥à¤¯ à¤°à¤¸à¤–à¤¾à¤¨â€Œà¥¥
à¤¸à¥à¤– à¤¦à¥à¤– à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¹à¥€ à¤¸à¥à¤–à¤¦, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®-à¤¸à¥à¤–à¤•à¥‡ à¤¹à¥‡à¤¤à¥à¥¤
à¤…à¤¨à¥à¤¯ à¤¸à¤­à¥€ à¤Ÿà¥‚à¤Ÿà¥‡ à¤¸à¤¹à¤œ à¤®à¤¿à¤¥à¥à¤¯à¤¾ à¤¨à¤¿à¤œà¤¸à¥à¤–-à¤¸à¥‡à¤¤à¥ à¥¥
à¤°à¤¾à¤§à¤¾-à¤®à¤¾à¤§à¤µ-à¤ªà¥à¤°à¥‡à¤®-à¤°à¤¸ à¤µà¤¾à¤šà¤¾-à¤šà¤¿à¤¤à¥à¤¤-à¤…à¤¤à¥€à¤¤à¥¤
à¤•à¤°à¤¤à¥‡ à¤¶à¤¾à¤–à¤¾à¤šà¤‚à¤¦à¥à¤°-à¤¸à¥‡ à¤‡à¤‚à¤—à¤¿à¤¤ à¤¸à¥‹à¤²à¤¹ à¤—à¥€à¤¤ à¥¥''',
          );

        default:
          return const _TopicPageContent(
            body: '''Topic content not found.''',
          );
      }
    }
    // --- à¤«à¤²à¤¶à¥à¤°à¥à¤¤à¤¿à¤¯à¤¾à¤ (Topic 6) ---
    else if (sectionId == 'topic6') {
      switch (title) {
        case 'à¤¶à¥à¤²à¥‹à¤• à¤à¤µà¤‚ à¤ªà¥à¤°à¤¥à¤® à¤¶à¤¤à¤•':
          return const _TopicPageContent(body: '''## à¤«à¤²à¤¶à¥à¤°à¥à¤¤à¤¿à¤¯à¤¾à¤

**à¤¶à¥à¤²à¥‹à¤•-à¤²à¤²à¤¿à¤¤à¤¾à¤®à¥à¤¬à¤¾à¤®à¤¯à¥€à¤‚-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤…à¤°à¥à¤¥-à¤…à¤µà¤§à¤¾à¤°à¤£à¤¾ à¤à¤µà¤‚ à¤…à¤¤à¤¿à¤¶à¤¯ à¤¶à¥à¤°à¤¦à¥à¤§à¤¾à¤ªà¥‚à¤°à¥à¤µà¤• à¥§à¥¦à¥® à¤¬à¤¾à¤° à¤œà¤ª--- à¤®à¥ƒà¤¤à¥à¤¯à¥à¤•à¥‡ à¤¸à¤®à¤¯ à¤­à¤—à¤µà¤¤à¥€ à¤²à¤²à¤¿à¤¤à¤¾à¤®à¥à¤¬à¤¾à¤•à¤¾ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥ à¤¦à¤°à¥à¤¶à¤¨ à¤¹à¥‹à¤—à¤¾à¥¤ à¤®à¤¹à¤¾à¤ªà¥à¤°à¤­à¥ à¤ªà¥‹à¤¦à¥à¤¦à¤¾à¤° à¤®à¤¹à¤¾à¤°à¤¾à¤œà¤•à¤¾ à¤¸à¥à¤µà¤°à¥‚à¤ª à¤ªà¥à¤°à¤•à¤Ÿ à¤¹à¥‹à¤•à¤° à¤¬à¥à¤°à¤œà¤­à¤¾à¤µà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¥‡à¤¶à¤•à¥€ à¤­à¥‚à¤®à¤¿à¤•à¤¾ à¤¬à¤¨ à¤œà¤¾à¤¯à¥‡à¤—à¥€à¥¤ à¤œà¥€à¤µà¤¨à¤®à¥‡à¤‚ à¤†à¤°à¥à¤¥à¤¿à¤• à¤¸à¤‚à¤•à¤Ÿà¥‹à¤‚à¤¸à¥‡ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤¤à¥à¤°à¤¾à¤£ à¤¹à¥‹à¤—à¤¾à¥¤

**à¤¶à¥à¤²à¥‹à¤• à¤•à¥ƒà¤·à¥à¤£à¤¸à¥à¤µà¤°à¥‚à¤ªà¤¿à¤£à¥€à¤‚-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦à¥® à¤¬à¤¾à¤° à¤œà¤ª--- à¤®à¥ƒà¤¤à¥à¤¯à¥à¤•à¥‡ à¤¸à¤®à¤¯ à¤­à¤—à¤µà¤¾à¤¨à¥ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨, à¤¬à¥à¤°à¤œà¤­à¤¾à¤µà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¥‡à¤¶à¤•à¥€ à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤•à¤¾ à¤…à¤µà¤¶à¥à¤¯à¤‚à¤­à¤¾à¤µà¥€ à¤¨à¤¿à¤°à¥à¤®à¤¾à¤£à¥¤ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤•à¥ƒà¤ªà¤¾à¤•à¤¾ à¤œà¥€à¤µà¤¨à¤•à¤¾à¤²à¤®à¥‡à¤‚ à¤¹à¥€ à¤…à¤¨à¥à¤­à¤µà¥¤

## (à¤ªà¥à¤°à¤¥à¤® à¤¶à¤¤à¤•)

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥§-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦à¥® à¤¬à¤¾à¤° à¤œà¤ª--- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¹à¥€ 'à¤¸à¤‚à¤¸à¤¾à¤° à¤¸à¤¤à¥à¤¯ à¤¨à¤¹à¥€à¤‚ à¤¹à¥ˆ, à¤¸à¥à¤µà¤ªà¥à¤¨à¤¤à¥à¤²à¥à¤¯ à¤¹à¥ˆ', à¤‡à¤¸à¤•à¤¾ à¤¸à¥à¤ªà¤·à¥à¤Ÿ à¤…à¤¨à¥à¤­à¤µ (à¤ªà¥‚.à¤—à¥à¤°à¥à¤¦à¥‡à¤µ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¸à¤¨à¥ à¥§à¥¯à¥¬à¥ª à¤ˆ. à¤®à¥‡à¤‚ à¤¬à¤¤à¤¾à¤¯à¤¾ à¤¸à¤¾à¤§à¤¨)

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥¨-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤µà¤¸ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾à¤•à¤¾ à¤œà¤ª--- à¤®à¤¾à¤¯à¤¾à¤•à¥€ à¤†à¤¤à¥à¤¯à¤¨à¥à¤¤à¤¿à¤• à¤¨à¤¿à¤µà¥ƒà¤¤à¥à¤¤à¤¿à¥¤ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤¦à¥à¤µà¤¾à¤°à¤¾ à¤¹à¤¸à¥à¤¤- à¤§à¤¾à¤°à¤£à¤•à¤° à¤¨à¤¿à¤•à¥à¤‚à¤œà¤®à¥‡à¤‚ à¤ªà¥à¤°à¤µà¥‡à¤¶à¥¤

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥ª-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾à¤•à¤¾ à¤œà¤ª--- à¤¶à¤•à¥à¤¤à¤¿à¤ªà¤¾à¤¤ à¤¹à¥‹à¤•à¤° à¤µà¥ˆà¤·à¤¯à¤¿à¤• à¤†à¤•à¤°à¥à¤·à¤£à¥‹à¤‚à¤¸à¥‡ à¤®à¥à¤•à¥à¤¤à¤¿ à¤à¤µà¤‚ à¤µà¥ˆà¤°à¤¾à¤—à¥à¤¯à¤•à¥€ à¤…à¤¦à¤®à¥à¤¯ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾ 

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥®-** à¤•à¥‡à¤µà¤² à¤šà¥Œà¤¥à¥€ à¤ªà¤‚à¤•à¥à¤¤à¤¿à¤•à¥€ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾à¤•à¤¾ à¤¨à¤¿à¤¤à¥à¤¯ à¤œà¤ª---à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¤¾ à¤…à¤¨à¤¿à¤°à¥à¤µà¤šà¤¨à¥€à¤¯ à¤…à¤¦à¥à¤­à¥à¤¤ à¤°à¥‚à¤ª-à¤¦à¤°à¥à¤¶à¤¨à¥¤

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥§à¥¨-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾à¤•à¤¾ à¤œà¤ª--- à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤µà¤¿à¤°à¤¹à¤­à¤¾à¤µ à¤•à¤¾ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤¸à¤šà¥à¤šà¤¾ à¤ªà¥à¤°à¤•à¤¾à¤¶à¥¤

**à¤›à¤¨à¥à¤¦à¤ƒ à¥§à¥© à¤¸à¥‡ à¥§à¥« à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§ à¤®à¤¾à¤²à¤¾--- à¤®à¥ƒà¤¤à¥à¤¯à¥à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤¬à¤¾à¤²-à¤šà¤°à¤¿à¤¤à¥à¤°à¤•à¤¾ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤•à¤¾à¤¶à¥¤ à¤µà¤¿à¤¶à¥à¤¦à¥à¤§ à¤µà¤¾à¤¤à¥à¤¸à¤²à¥à¤¯à¤°à¤¸à¤•à¥€ à¤¹à¥ƒà¤¦à¤¯à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥¬ à¤¸à¥‡ à¥§à¥¯ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤à¤• à¤®à¤¾à¤²à¤¾ à¤ªà¤¾à¤ --- à¤®à¥ƒà¤¤à¥à¤¯à¥à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤°à¤¾à¤§à¤¾-à¤•à¤¾à¤®à¥à¤¯à¤•à¤¾à¤¨à¤¨à¤•à¤¾ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤…à¤¨à¥à¤­à¤µà¥¤ à¤­à¤—à¤µà¤¤à¥€ à¤²à¥€à¤²à¤¾-à¤®à¤¹à¤¾à¤¶à¤•à¥à¤¤à¤¿ à¤¤à¥à¤°à¤¿à¤ªà¥à¤°à¤¸à¥à¤¨à¥à¤¦à¤°à¥€à¤•à¥‡ à¤¶à¥à¤°à¥€à¤¯à¤‚à¤¤à¥à¤°à¤•à¥‡ à¤°à¤¹à¤¸à¥à¤¯à¤•à¤¾ à¤œà¥à¤žà¤¾à¤¨à¥¤ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤¦à¥‡à¤µà¥€à¤•à¥‡ à¤¤à¤¤à¥à¤µ-à¤°à¤¹à¤¸à¥à¤¯à¤•à¥€ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤µà¤¨à¤•à¥‡ à¤ªà¤¶à¥-à¤ªà¤•à¥à¤·à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤¤à¤¤à¥à¤µ à¤°à¤¹à¤¸à¥à¤¯à¤•à¤¾ à¤œà¥à¤žà¤¾à¤¨à¥¤ 

**à¤›à¤¨à¥à¤¦ à¥¨à¥¬ à¤¸à¥‡ à¥¨à¥® à¤¤à¤•-** à¤à¤• à¤®à¤¾à¤²à¤¾à¤•à¤¾ à¤ªà¤¾à¤  à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨--- à¤œà¥€à¤µà¤¨à¤¯à¤¾à¤¤à¥à¤°à¤¾ à¤…à¤¤à¥à¤¯à¤¨à¥à¤¤ à¤¸à¥à¤•à¤°à¥¤ à¤šà¤¿à¤¤à¥à¤¤à¤µà¥ƒà¤¤à¥à¤¤à¤¿à¤®à¥‡à¤‚ à¤†à¤¤à¥à¤¯à¤¨à¥à¤¤à¤¿à¤• à¤¸à¤¾à¤¤à¥à¤µà¤¿à¤• à¤¶à¤¾à¤¨à¥à¤¤à¤¿ à¤¬à¤¨à¥€ à¤°à¤¹à¥‡à¤—à¥€à¥¤ à¤•à¥‹à¤ˆ, à¤•à¥ˆà¤¸à¤¾ à¤­à¥€ à¤¹à¥‹, à¤¶à¤¨à¥ˆà¤ƒ à¤¶à¤¨à¥ˆà¤ƒ à¤šà¤¿à¤¤à¥à¤¤à¤®à¥‡à¤‚ à¤¶à¤¾à¤¨à¥à¤¤à¤¿ à¤à¤µà¤‚ à¤à¤•à¤¾à¤—à¥à¤°à¤¤à¤¾ à¤¸à¥à¤µà¤­à¤¾à¤µà¤¤à¤ƒ à¤†à¤µà¥‡à¤—à¥€à¥¤ à¤¸à¤šà¥à¤šà¥€ à¤†à¤¸à¥à¤¤à¤¿à¤•à¤¤à¤¾à¤•à¤¾ à¤‰à¤¦à¥à¤°à¥‡à¤• à¤¹à¥‹à¤—à¤¾à¥¤ à¤‡à¤·à¥à¤Ÿà¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿ à¤¨à¤¿à¤·à¥à¤ à¤¾ à¤à¤µà¤‚ à¤¶à¥à¤°à¤¦à¥à¤§à¤¾ à¤‰à¤ªà¤²à¤¬à¥à¤§ à¤¹à¥‹à¤—à¥€à¥¤ à¤ªà¤µà¤¿à¤¤à¥à¤° à¤à¤µà¤‚ à¤¨à¤¿à¤·à¥à¤•à¤¾à¤® à¤¶à¤•à¥à¤¤à¤¿-à¤‰à¤ªà¤¾à¤¸à¤¨à¤¾à¤•à¥‡ à¤¬à¥€à¤œ à¤ªà¤¡à¤¼à¥‡à¤‚à¤—à¥‡à¥¤

**à¤›à¤¨à¥à¤¦ à¥©à¥¬à¤¸à¥‡ à¥ªà¥« à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§ à¤®à¤¾à¤²à¤¾ à¤ªà¤¾à¤ --- à¤•à¥à¤¨à¥à¤¦à¤µà¤²à¥à¤²à¥€ à¤¦à¥‡à¤µà¥€ à¤à¤µà¤‚ à¤¶à¥à¤°à¥€à¤¦à¤¾à¤® à¤­à¥ˆà¤¯à¤¾à¤•à¥‡ à¤œà¤¨à¥à¤®à¥‹à¤¤à¥à¤¸à¤µà¤•à¤¾ à¤…à¤¨à¥à¤­à¤µà¤ªà¥‚à¤°à¥à¤£ à¤¦à¤°à¥à¤¶à¤¨à¥¤ à¤¬à¥ƒà¤·à¤­à¤¾à¤¨à¥à¤ªà¥à¤°à¥€à¤•à¥‡ à¤…à¤ªà¥‚à¤°à¥à¤µ à¤µà¥ˆà¤­à¤µà¤•à¤¾ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤ªà¥à¤°à¤•à¤¾à¤¶à¥¤ à¤¶à¥à¤¦à¥à¤§ à¤¸à¤–à¥à¤¯ à¤°à¤¸à¤•à¤¾ à¤ªà¥à¤°à¤¾à¤¦à¥à¤°à¥à¤­à¤¾à¤µà¥¤ à¤¨à¤¿à¤·à¥à¤•à¤¾à¤® à¤¤à¤¤à¥à¤¸à¥à¤–à¤¿à¤¯à¤¾ à¤­à¤¾à¤µà¤¸à¥‡ à¤¹à¥ƒà¤¦à¤¯à¤•à¥‡ à¤“à¤¤à¤ªà¥à¤°à¥‹à¤¤ à¤¹à¥‹à¤¨à¥‡à¤•à¥€ à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤•à¤¾ à¤ªà¥à¤°à¤¾à¤¦à¥à¤°à¥à¤­à¤¾à¤µ à¥¤

**à¤›à¤¨à¥à¤¦ à¥ªà¥¬ à¤¸à¥‡ à¥«à¥« à¤¤à¤•-** à¥§ à¤®à¤¾à¤²à¤¾ à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤ªà¤¾à¤ --- à¤²à¤²à¤¿à¤¤à¤¾ à¤­à¤¾à¤µà¤•à¥€ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤ à¤‰à¤¨à¤•à¥‡ à¤œà¤¨à¥à¤®à¥‹à¤¤à¥à¤¸à¤µà¤•à¥€ à¤à¤¾à¤à¤•à¥€à¥¤ à¤¸à¤–à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤®à¤§à¥à¤¯à¤•à¥€ à¤¤à¤¤à¥à¤¸à¥à¤–à¥€ à¤ªà¥à¤°à¥€à¤¤à¤¿à¤•à¤¾ à¤…à¤¨à¥à¤¤à¤ƒà¤•à¤°à¤£à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¾à¤¦à¥à¤°à¥à¤­à¤¾à¤µà¥¤ à¤•à¥€à¤°à¥à¤¤à¥à¤¤à¤¿à¤¦à¤¾ à¤®à¥ˆà¤¯à¤¾ à¤à¤µà¤‚ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤ªà¥à¤°à¤•à¥‡ à¤…à¤¨à¥à¤¯ à¤®à¤¾à¤¤à¥ƒà¤µà¤°à¥à¤—à¤•à¥€ à¤¸à¤–à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤µà¤¿à¤¶à¥à¤¦à¥à¤§ à¤µà¤¾à¤¤à¥à¤¸à¤²à¥à¤¯à¤•à¤¾ à¤¬à¥€à¤œ-à¤µà¤ªà¤¨à¥¤

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥¬à¥¦-** â€˜à¤œà¤¯ à¤¦à¥‡à¤µà¤¿ à¤¦à¤¯à¤¾à¤®à¤¯à¤¿ à¤œà¤¯ à¤œà¤—à¤¦à¤®à¥à¤¬à¥‡ à¤œà¤¯ à¤²à¤²à¤¿à¤¤à¥‡â€™---  à¤‡à¤¸ à¤…à¤®à¥‹à¤˜ à¤œà¤¾à¤—à¥à¤°à¤¤ à¤®à¤‚à¤¤à¥à¤°à¤•à¤¾ à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤µà¤¸ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾ à¤œà¤ªà¤¸à¥‡ à¤¸à¤®à¤—à¥à¤° à¤†à¤¸à¥à¤°à¥€ à¤¶à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤ªà¤° à¤¶à¤¤-à¤ªà¥à¤°à¤¤à¤¿à¤¶à¤¤ à¤µà¤¿à¤œà¤¯à¥¤

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚.à¥¬à¥© à¤¸à¥‡ à¥­à¥¨ à¤¤à¤•-** à¤¦à¤¸ à¤®à¤¾à¤²à¤¾ à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤œà¤ª--- à¤¯à¤¹à¤¾à¤ à¤µà¤°à¥à¤£à¤¿à¤¤ à¤¸à¤®à¥à¤ªà¥‚à¤°à¥à¤£ à¤²à¥€à¤²à¤¾à¤•à¤¾ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤œà¥€à¤µà¤¨à¤•à¥‡ à¤…à¤µà¤¸à¤¾à¤¨à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¦à¤°à¥à¤¶à¤¨à¥¤

**à¤›à¤¨à¥à¤¦ à¥­à¥© à¤¸à¥‡ à¥®à¥­ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤œà¤¾à¤ª--- à¤°à¤¾à¤§à¤¾-à¤œà¤¨à¥à¤®à¥‹à¤¤à¥à¤¸à¤µà¤•à¥€ à¤²à¥€à¤²à¤¾à¤•à¤¾ à¤œà¥€à¤µà¤¨à¤•à¥‡ à¤…à¤µà¤¸à¤¾à¤¨à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¦à¤°à¥à¤¶à¤¨à¥¤''');

        case 'à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤¶à¤¤à¤•':
          return const _TopicPageContent(body: '''## (à¤¦à¥à¤µà¤¿à¤¤à¥€à¤¯ à¤¶à¤¤à¤•)

**à¤›à¤¨à¥à¤¦ à¥§à¥¦à¥¨ à¤¸à¥‡ à¥§à¥§à¥¦ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤¨à¥à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤…à¤µà¤¶à¥à¤¯-à¤…à¤µà¤¶à¥à¤¯ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤—à¤¿à¤°à¤¿à¤ªà¤°à¤¿à¤¸à¤° à¤à¤µà¤‚ à¤—à¤¿à¤°à¤¿à¤°à¤¾à¤œà¤•à¤¾ à¤¦à¤°à¥à¤¶à¤¨à¥¤

## (à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤°)
à¤‰à¤¸ à¤“à¤° à¤¶à¥ˆà¤²à¤•à¥‡ à¤•à¤£-à¤•à¤£à¤®à¥‡à¤‚ à¤®à¤¾à¤¨à¥‹ à¤šà¥‡à¤¤à¤¨à¤¤à¤¾ à¤¥à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤µà¤¹ à¤–à¤¡à¤¼à¤¾ à¤¸à¤¤à¤¤ à¤¦à¥‡à¤–à¤¾ à¤•à¤°à¤¤à¤¾ à¤Šà¤à¤šà¤¾ à¤¸à¤¿à¤° à¤•à¤¿à¤¯à¥‡ à¤¹à¥à¤, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
**-à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ ---** à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤—à¤¿à¤°à¤¿à¤ªà¤°à¤¿à¤¸à¤° à¤à¤µà¤‚ à¤—à¤¿à¤°à¤¿à¤°à¤¾à¤œà¤•à¤¾ à¤¦à¤°à¥à¤¶à¤¨à¥¤

## (à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤°)
à¤œà¥€à¤µà¤¨à¤•à¥€ à¤§à¤¾à¤°à¤¾ à¤•à¤¿à¤§à¤° à¤®à¥à¤¡à¤¼à¥‡, à¤­à¤¾à¤µà¥€ à¤•à¥à¤¯à¤¾ à¤¹à¥ˆ à¤•à¤¿à¤¸à¤•à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¸à¤šà¥à¤šà¤¾ à¤ªà¥à¤°à¤¤à¥€à¤• à¤‡à¤¸à¤•à¤¾ à¤µà¤¹ à¤¥à¤¾, à¤†à¤¦à¤° à¤µà¥‡ à¤¸à¤¬ à¤•à¤°à¤¤à¥€à¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
**-à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ ---** à¤ªà¤°à¤®à¤¾à¤°à¥à¤¥à¤•à¥€ à¤“à¤° à¤œà¥€à¤µà¤¨à¤§à¤¾à¤°à¤¾ à¤®à¥‹à¤¡à¤¼à¤¨à¥‡à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤°

**à¤›à¤¨à¥à¤¦ à¥§à¥§à¥§ à¤¸à¥‡ à¥§à¥¨à¥¨ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤²à¤²à¤¿à¤¤à¤¾à¤•à¥à¤‚à¤œà¤•à¥‡, à¤­à¤—à¤µà¤¤à¥€ à¤²à¤²à¤¿à¤¤à¤¾ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥¨à¥© à¤¸à¥‡ à¥§à¥©à¥¦ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤µà¤¿à¤¶à¤¾à¤–à¤¾à¤•à¥à¤‚à¤œà¤•à¥‡, à¤­à¤—à¤µà¤¤à¥€ à¤µà¤¿à¤¶à¤¾à¤–à¤¾ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥©à¥§ à¤¸à¥‡ à¥§à¥©à¥® à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤šà¤¿à¤¤à¥à¤°à¤¾à¤•à¥à¤‚à¤œà¤•à¥‡, à¤­à¤—à¤µà¤¤à¥€ à¤šà¤¿à¤¤à¥à¤°à¤¾ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥©à¥¯ à¤¸à¥‡ à¥§à¥ªà¥¬ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤‡à¤¨à¥à¤¦à¥à¤²à¥‡à¤–à¤¾à¤•à¥à¤‚à¤œà¤•à¥‡, à¤­à¤—à¤µà¤¤à¥€ à¤‡à¤¨à¥à¤¦à¥à¤²à¥‡à¤–à¤¾ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥ªà¥­ à¤¸à¥‡ à¥§à¥«à¥ª à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤šà¤‚à¤ªà¤•à¤²à¤¤à¤¾à¤•à¥à¤‚à¤œà¤•à¥‡,à¤­à¤—à¤µà¤¤à¥€ à¤šà¤‚à¤ªà¤•à¤²à¤¤à¤¾ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥«à¥« à¤¸à¥‡ à¥§à¥¬à¥¨ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤°à¤‚à¤—à¤¦à¥‡à¤µà¥€à¤•à¥à¤‚à¤œà¤•à¥‡, à¤­à¤—à¤µà¤¤à¥€ à¤°à¤‚à¤—à¤¦à¥‡à¤µà¥€ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦à¤ƒ à¥§à¥¬à¥© à¤¸à¥‡ à¥§à¥­à¥¦ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¤à¥à¤‚à¤—à¤µà¤¿à¤¦à¥à¤¯à¤¾à¤•à¥à¤‚à¤œà¤•à¥‡,à¤­à¤—à¤µà¤¤à¥€ à¤¤à¥à¤‚à¤—à¤µà¤¿à¤¦à¥à¤¯à¤¾ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥­à¥§ à¤¸à¥‡ à¥§à¥­à¥® à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¸à¥à¤¦à¥‡à¤µà¥€à¤•à¥à¤‚à¤œà¤•à¥‡,à¤­à¤—à¤µà¤¤à¥€ à¤¸à¥à¤¦à¥‡à¤µà¥€ à¤¸à¤–à¥€à¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥­à¥¯ à¤¸à¥‡ à¥§à¥¯à¥ª à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¨à¤¿à¤•à¥à¤‚à¤œà¥‡à¤¶à¥à¤µà¤° à¤à¤µà¤‚ à¤¨à¤¿à¤•à¥à¤‚à¤œà¥‡à¤¶à¥à¤µà¤°à¥€à¤•à¥‡ à¤•à¥à¤£à¥à¤¡à¥‹à¤‚à¤•à¤¾ à¤¤à¤¤à¥à¤µà¤¸à¤¹à¤¿à¤¤ à¤°à¤¹à¤¸à¥à¤¯à¤•à¤¾ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥¯à¥« à¤¸à¥‡ à¥§à¥¯à¥® à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤µà¥ƒà¤·à¤­à¤¾à¤¨à¥à¤ªà¥à¤°à¤§à¤¾à¤®à¤•à¥‡ à¤…à¤§à¤¿à¤·à¥à¤ à¤¾à¤¤à¥à¤°à¥€ à¤¦à¥‡à¤µà¤¤à¤¾ à¤¸à¥‚à¤°à¥à¤¯à¤¦à¥‡à¤µà¤•à¥‡ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤‰à¤¨à¤•à¥€ à¤µà¤¿à¤¶à¥‡à¤· à¤•à¥ƒà¤ªà¤¾à¤•à¥€ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥§à¥¯à¥¯ à¤¸à¥‡ à¥¨à¥¦à¥¨ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤ªà¤°à¤•à¥€à¤¯à¤¾ à¤­à¤¾à¤µà¤•à¥‡ à¤¤à¤¤à¥à¤µ-à¤°à¤¹à¤¸à¥à¤¯à¤•à¤¾ à¤ªà¥à¤°à¤•à¤¾à¤¶ à¤à¤µà¤‚ à¤¯à¤¾à¤µà¤Ÿ à¤—à¥à¤°à¤¾à¤® à¤à¤µà¤‚ à¤‰à¤¸à¤•à¥€ à¤®à¤¹à¤¿à¤®à¤¾à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨à¥¤''');

        case 'à¤¤à¥ƒà¤¤à¥€à¤¯ à¤¶à¤¤à¤•':
          return const _TopicPageContent(body: '''## (à¤¤à¥ƒà¤¤à¥€à¤¯ à¤¶à¤¤à¤•)

**à¤›à¤¨à¥à¤¦ à¥¨à¥¦à¥¬-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤œà¤ª--- à¤ªà¥‚à¤°à¥à¤£ à¤œà¥€à¤µà¤¨ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤®à¤‚à¤—à¤²à¤®à¤¯ à¤¬à¤¨ à¤œà¤¾à¤¯à¥‡à¤—à¤¾à¥¤

## (à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤°)
'à¤…à¤ªà¥à¤°à¤¤à¤¿à¤® à¤¯à¤¹à¤¾à¤ à¤•à¥‹à¤ˆ à¤®à¤‚à¤—à¤² à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥‹à¤—à¤¾, à¤¸à¤–à¤¿ à¤°à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !'
**---à¤•à¤¿à¤¸à¥€ à¤­à¥€ à¤•à¤¾à¤°à¥à¤¯à¤•à¥€ à¤®à¤™à¥à¤—à¤²à¤®à¤¯ à¤¸à¤‚à¤ªà¤¨à¥à¤¨à¤¤à¤¾à¤•à¥‡ à¤²à¤¿à¤¯à¥‡ à¤‡à¤¸ à¤®à¤‚à¤¤à¥à¤°à¤•à¥€ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾ à¤œà¤ª à¤•à¤°à¥‡à¤‚à¥¤**

**à¤›à¤¨à¥à¤¦ à¥¨à¥¦à¥­à¤¸à¥‡ à¥¨à¥§à¥¬à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾-à¤•à¤¾à¤®à¥à¤¯à¤•à¤¾à¤¨à¤¨à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤°à¥à¤—à¤¤ à¤²à¥€à¤²à¤¾à¤œà¤—à¤¤à¥à¤•à¥‡ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤ªà¤•à¥à¤·à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤°à¥‚à¤ª, à¤°à¤¹à¤¸à¥à¤¯, à¤¤à¤¤à¥à¤µ à¤à¤µà¤‚ à¤‰à¤¨à¤•à¥€ à¤¤à¤¤à¥à¤¸à¥à¤–à¤­à¤¾à¤µ-à¤­à¤¾à¤µà¤¿à¤¤ à¤µà¥ƒà¤¤à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥à¤•à¤¾à¤°à¥¤ à¤¬à¥à¤°à¤œà¤®à¥‡à¤‚ à¤ªà¤•à¥à¤·à¥€à¤­à¤¾à¤µà¤•à¥€ à¤ªà¥à¤°à¤¾à¤ªà¥à¤¤à¤¿à¤•à¥€ à¤­à¥‚à¤®à¤¿à¤•à¤¾à¤•à¤¾ à¤¨à¤¿à¤°à¥à¤®à¤¾à¤£à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥§à¥­à¤¸à¥‡ à¥¨à¥§à¥¯ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤°à¤¾à¤§à¤¾-à¤•à¤¾à¤®à¥à¤¯à¤•à¤¾à¤¨à¤¨à¤•à¥€ à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤à¤²à¤•à¥¤ à¤µà¤Ÿà¤¤à¤°à¥à¤•à¥‡ à¤®à¤¾à¤¹à¤¾à¤¤à¥à¤®à¥à¤¯à¤•à¤¾ à¤œà¥à¤žà¤¾à¤¨à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥¨à¥¦ à¤¸à¥‡ à¥¨à¥¨à¥ªà¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¶à¥à¤•à¤°à¤¾à¤œ à¤µà¤¿à¤šà¤•à¥à¤·à¤£à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨à¥¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤¹à¥€ à¤¦à¥‚à¤¤à¤•à¥‡ à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤¶à¥à¤•à¤ªà¤•à¥à¤·à¥€ à¤¬à¤¨à¤•à¤° à¤†à¤¤à¥‡ à¤¹à¥ˆà¤‚ à¤‡à¤¸ à¤°à¤¹à¤¸à¥à¤¯à¤•à¤¾ à¤ªà¤°à¤® à¤®à¤§à¥à¤° à¤ªà¥à¤°à¤•à¤¾à¤¶à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥¨à¥«-** à¤¯à¤¹ à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤° à¤¹à¥ˆà¥¤ à¤¶à¥à¤¦à¥à¤§ à¤œà¤² à¤²à¥‡à¤•à¤° à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤‡à¤¸ à¤®à¤‚à¤¤à¥à¤°à¤•à¥€ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤œà¤ªà¤•à¤°à¤•à¥‡ à¤…à¤­à¤¿à¤®à¤‚à¤¤à¥à¤°à¤¿à¤¤ à¤œà¤² à¤ªà¥€à¤²à¥‡à¤‚à¥¤--- à¤¨à¤¿à¤¶à¥à¤šà¤¯ à¤¹à¥€ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤®à¤¹à¤¾à¤®à¤¾à¤¯à¤¾à¤•à¥€ à¤µà¤¿à¤¶à¤¿à¤·à¥à¤Ÿ à¤¶à¤•à¥à¤¤à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤…à¤­à¥à¤¯à¥à¤¦à¤¯ à¤¹à¥‹à¤—à¤¾à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥¨à¥¬ à¤¸à¥‡ à¥¨à¥©à¥© à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤°à¤¸à¤¾à¤¤à¥à¤®à¤• à¤¶à¥à¤°à¥€à¤¯à¤‚à¤¤à¥à¤°à¤•à¤¾ à¤ªà¥à¤°à¤•à¤¾à¤¶à¥¤ à¤œà¥€à¤µà¤¨à¤®à¥‡à¤‚ à¤…à¤¨à¥‡à¤• à¤¸à¤¿à¤¦à¥à¤§à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤ªà¥à¤°à¤•à¤¾à¤¶ à¤à¤µà¤‚ à¤¬à¥à¤°à¤œà¤­à¤¾à¤µà¤•à¤¾ à¤šà¤¿à¤¤à¥à¤¤à¤®à¥‡à¤‚ à¤¬à¥€à¤œ-à¤ªà¤²à¥à¤²à¤µà¤¨à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥©à¥­-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤œà¤ª--- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤µà¤¿à¤²à¤•à¥à¤·à¤£ à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤†à¤¨à¤¨à¥à¤¦à¤•à¥€ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿ à¤à¤µà¤‚ à¤†à¤¹à¥à¤²à¤¾à¤¦à¤¤à¤¤à¥à¤µà¤•à¤¾ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥à¤•à¤¾à¤°à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥©à¥® à¤¸à¥‡ à¥¨à¥ªà¥§ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¸à¤¨à¥à¤§à¤¿à¤¨à¥€ à¤®à¤¹à¤¾à¤¶à¤•à¥à¤¤à¤¿ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤•à¥‡ à¤¸à¥à¤µà¤°à¥‚à¤ªà¤•à¤¾ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥ à¤¦à¤°à¥à¤¶à¤¨à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥ªà¥¨-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤¯à¤¹ à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤° à¤¹à¥ˆà¥¤ à¤‡à¤¸à¤•à¥‡ à¤œà¤ªà¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤•à¤¾à¤¨à¤¨, à¤µà¥ƒà¤¨à¥à¤¦à¤¾à¤¦à¥‡à¤µà¥€ à¤à¤µà¤‚ à¤ªà¥à¤°à¤¿à¤¯à¤¾ à¤¶à¥à¤°à¥€à¤°à¤¾à¤§à¤¾, à¤°à¤¾à¤§à¤¾à¤¨à¥à¤œà¤¾ à¤®à¤‚à¤œà¥à¤¶à¥à¤¯à¤¾à¤®à¤¾à¤•à¤¾ à¤¸à¤¾à¤•à¥à¤·à¤¾à¤¤à¥ à¤¦à¤°à¥à¤¶à¤¨ à¤¹à¥‹à¤—à¤¾à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥ªà¥©-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤  à¤¯à¤¹ à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤° à¤¹à¥ˆà¥¤--- à¤‡à¤¸à¤•à¥‡ à¤œà¤ªà¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¹à¤‚à¤¸-à¤¹à¤‚à¤¸à¤¿à¤¨à¥€à¤•à¥‡ à¤¤à¤¤à¥à¤µ à¤°à¤¹à¤¸à¥à¤¯à¤•à¤¾ à¤œà¥à¤žà¤¾à¤¨, à¤ªà¥à¤°à¤¿à¤¯à¤¾-à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¨à¤¿à¤¤à¥à¤¯à¤¨à¤¿à¤•à¥à¤‚à¤œà¥‡à¤¶à¥à¤µà¤°à¤•à¥€ à¤‡à¤¨ à¤¦à¥‚à¤¤à¥‹à¤‚à¤•à¥‡ à¤°à¥‚à¤ªà¤®à¥‡à¤‚ à¤¸à¥à¤µà¤¯à¤‚ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨ à¤¹à¥€ à¤²à¥€à¤²à¤¾à¤°à¤¤ à¤¹à¥ˆà¤‚, à¤‡à¤¸à¤•à¤¾ à¤¸à¥à¤ªà¤·à¥à¤Ÿ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤…à¤¨à¥à¤­à¤µ à¤¹à¥‹ à¤œà¤¾à¤¯à¤—à¤¾à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥ªà¥ªà¤¸à¥‡ à¥¨à¥ªà¥¬ à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤‡à¤¸à¤•à¥‡ à¤œà¤ªà¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤…à¤¶à¥‹à¤•à¤¨à¤¿à¤•à¥à¤‚à¤œà¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨, à¤¨à¤¿à¤¤à¥à¤¯à¤¨à¤¿à¤•à¥à¤‚à¤œà¥‡à¤¶à¥à¤µà¤° à¤à¤µà¤‚ à¤¨à¤¿à¤¤à¥à¤¯à¤¨à¤¿à¤•à¥à¤‚à¤œà¥‡à¤¶à¥à¤µà¤°à¥€à¤•à¥‡ à¤‡à¤¸ à¤¨à¤¿à¤•à¥à¤‚à¤œà¤®à¥‡à¤‚ à¤²à¥€à¤²à¤¾à¤°à¤¤ à¤¦à¤°à¥à¤¶à¤¨à¥¤ à¤œà¤¨à¥à¤®, à¤¸à¥à¤¥à¤¿à¤¤à¤¿, à¤ªà¥à¤°à¤²à¤¯à¤¸à¥‡ à¤ªà¤°à¥‡ à¤¤à¥à¤°à¤¿à¤—à¥à¤£à¤¾à¤¤à¥€à¤¤ à¤…à¤ªà¥à¤°à¤¾à¤•à¥ƒà¤¤ à¤¨à¤¿à¤•à¥à¤‚à¤œ-à¤²à¥€à¤²à¤¾à¤§à¤¾à¤®à¤•à¥€ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤

**à¤›à¤¨à¥à¤¦ à¥¨à¥ªà¥­à¤¸à¥‡ à¥©à¥¦à¥© à¤¤à¤•-** à¤¸à¤®à¥à¤ªà¥‚à¤°à¥à¤£ à¤²à¥€à¤²à¤¾à¤•à¥‡ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤¦à¤¸ à¤ªà¤¾à¤  à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤•à¤°à¥‡à¤‚à¥¤--- à¤¸à¤®à¤—à¥à¤° à¤²à¥€à¤²à¤¾ à¤œà¥€à¤µà¤¨à¤•à¥‡ à¤…à¤¨à¥à¤¤à¤¿à¤® à¤ªà¤¡à¤¼à¤¾à¤µà¤¤à¤• à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤…à¤¨à¥à¤­à¤µà¤®à¥‡à¤‚ à¤®à¥‚à¤°à¥à¤¤ à¤¹à¥‹ à¤‰à¤ à¥‡à¤—à¥€à¥¤''');

        case 'à¤šà¤¤à¥à¤°à¥à¤¥ à¤¶à¤¤à¤•':
          return const _TopicPageContent(body: '''## (à¤šà¤¤à¥à¤°à¥à¤¥ à¤¶à¤¤à¤•)

**à¤›à¤¨à¥à¤¦à¤ƒ à¥©à¥©à¥ª à¤¸à¥‡ à¥©à¥¬à¥§à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤®à¤¾à¤²à¤¾ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¤¾à¤ --- à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¸à¤–à¥à¤¯à¤°à¤¸-à¤ªà¥à¤°à¤§à¤¾à¤¨ à¤¤à¤¤à¥à¤¸à¥à¤–à¤¿à¤¯à¤¾-à¤­à¤¾à¤µà¤•à¥€ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾à¥¤ à¤¶à¥à¤°à¥€à¤¦à¤¾à¤® à¤­à¥ˆà¤¯à¤¾à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨ à¤à¤µà¤‚ à¤®à¥ƒà¤¤à¥à¤¯à¥à¤•à¥‡ à¤ªà¤¶à¥à¤šà¤¾à¤¤à¥ à¤‰à¤¨à¤®à¥‡à¤‚ à¤ªà¥à¤°à¤¤à¤¿à¤·à¥à¤ à¤¾à¥¤ 

## (à¤µà¤¿à¤¶à¥‡à¤· à¤®à¤‚à¤¤à¥à¤°)
à¤¸à¤‚à¤¦à¥‡à¤¶    à¤à¤•    à¤¹à¥ˆ    à¤¶à¥à¤°à¥€à¤ªà¤¦à¤®à¥‡à¤‚   à¤‰à¤¨  à¤¨à¥€à¤²à¤¦à¥‡à¤µà¤¤à¤¾à¤•à¤¾,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¸à¥‡à¤µà¤¾ à¤¨ à¤¬à¤¨à¥€ à¤•à¥à¤› à¤­à¥€  à¤¸à¤šà¤®à¥à¤š, à¤…à¤°à¤¸à¤¿à¤• à¤®à¥à¤ à¤•à¤¿à¤‚à¤•à¤°à¤¸à¥‡, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤…à¤ªà¤¨à¥€  à¤¹à¥€  à¤“à¤°  à¤¦à¥‡à¤–   à¤‰à¤°à¤®à¥‡à¤‚  à¤…à¤µà¤¿à¤šà¤²  à¤¨à¤¿à¤µà¤¾à¤¸  à¤¦à¥‡à¤¨à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥ˆ à¤¨à¤¹à¥€à¤‚ à¤®à¤¨à¥‹à¤­à¥à¤°à¤®,  à¤¸à¤šà¥à¤šà¥€   à¤¹à¥ˆ  à¤˜à¤Ÿà¤¨à¤¾  à¤¸à¤¬  à¤‡à¤¸  à¤µà¤¨à¤•à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤®à¤¾à¤²à¤¾  à¤¹à¥ˆ  à¤à¥‚à¤²   à¤°à¤¹à¥€   à¤‰à¤°à¤ªà¤°,  à¤à¥‚à¤²à¥‡à¤—à¥€   à¤¨à¤¿à¤¤à¥à¤¯  à¤¤à¤¥à¤¾,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
*****
à¤¬à¥‹à¤²à¤¾ 'à¤¶à¥à¤°à¥€à¤ªà¤¦à¤®à¥‡à¤‚  à¤ªà¥à¤°à¤£à¤¤à¤¿  à¤¸à¤°à¤¸  à¤‰à¤¨à¤•à¥€  à¤ªà¤² à¤ªà¤² à¤¶à¤¤ à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥ˆ   à¤”à¤°  à¤µà¤¿à¤¨à¤®à¥à¤°  à¤¨à¤¿à¤µà¥‡à¤¦à¤¨  à¤¯à¤¹,  à¤‰à¤¨à¤•à¥‡  à¤…à¤¨à¥à¤¤à¤¸à¥à¤¤à¤²à¤•à¤¾,  à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
'à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡,  à¤°à¤–à¥‹,  à¤§à¥€à¤°à¤œ  à¤®à¥à¤à¤¸à¥‡ à¤…à¤¬ à¤¨à¤¿à¤¤à¥à¤¯ à¤–à¤¿à¤²à¤¨ à¤¹à¥‹à¤—à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤œà¤¯ à¤¹à¥‹ ! à¤œà¤¯ à¤¹à¥‹ ! à¤¨à¤¿à¤°à¤µà¤§à¤¿ à¤œà¤¯ à¤¹à¥‹ ! à¤¶à¥à¤°à¥€à¤šà¤°à¤£à¤¸à¤°à¥‹à¤°à¥à¤¹à¤•à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !

**--à¤‡à¤¨ à¤®à¤‚à¤¤à¥à¤°à¥‹à¤‚à¤•à¥€ à¤¦à¤¸ à¤®à¤¾à¤²à¤¾à¤•à¥‡ à¤œà¤ªà¤¸à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¨à¥€à¤²à¤¸à¥à¤¨à¥à¤¦à¤° à¤¬à¥à¤°à¤œà¥‡à¤¨à¥à¤¦à¥à¤°à¤¨à¤¨à¥à¤¦à¤¨à¤¸à¥‡ à¤¨à¤¿à¤¤à¥à¤¯ à¤…à¤µà¤¿à¤šà¥à¤›à¤¿à¤¨à¥à¤¨ à¤®à¤¿à¤²à¤¨à¤•à¤¾ à¤µà¤¿à¤§à¤¾à¤¨à¥¤**''');

        case 'à¤ªà¤‚à¤šà¤® à¤à¤µà¤‚ à¤…à¤¨à¥à¤¯':
          return const _TopicPageContent(body: '''## (à¤ªà¤‚à¤šà¤® à¤¶à¤¤à¤•)
à¤¸à¤®à¥à¤ªà¥‚à¤°à¥à¤£ à¤ªà¤‚à¤šà¤® à¤¶à¤¤à¤•à¤•à¥‡ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¥§à¥¦ à¤ªà¤¾à¤ à¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¸à¤®à¥à¤ªà¥‚à¤°à¥à¤£ à¤²à¥€à¤²à¤¾à¤•à¤¾ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¦à¤°à¥à¤¶à¤¨ à¤¹à¥‹à¤—à¤¾à¥¤ à¤®à¤‚à¤œà¥à¤¶à¥à¤¯à¤¾à¤®à¤¾à¤•à¤¾ à¤¤à¤¤à¥à¤µà¤°à¤¹à¤¸à¥à¤¯ à¤¹à¥ƒà¤¦à¤¯à¤‚à¤—à¤® à¤¹à¥‹à¤—à¤¾, à¤‰à¤¨à¤•à¥‡ à¤œà¤¨à¥à¤®à¥‹à¤¤à¥à¤¸à¤µà¤•à¥€ à¤à¤¾à¤à¤•à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤¹à¥‹à¤—à¥€à¥¤

## (à¤·à¤·à¥à¤ à¤® à¤¶à¤¤à¤•)	

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥«à¥¦à¥¬à¤¸à¥‡ à¥«à¥©à¥¦à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¥§à¥¦ à¤ªà¤¾à¤ à¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤µà¤‚à¤¶à¥€à¤¨à¤¾à¤¦ à¤¶à¥à¤°à¤µà¤£à¤—à¥‹à¤šà¤° à¤¹à¥‹à¤—à¤¾à¥¤ à¤šà¤° à¤…à¤šà¤°à¤ªà¤° à¤‰à¤¸à¤•à¥‡ à¤ªà¥à¤°à¤­à¤¾à¤µà¤•à¤¾ à¤ªà¥à¤°à¤¤à¥à¤¯à¤•à¥à¤· à¤…à¤¨à¥à¤­à¤µ à¤¹à¥‹à¤—à¤¾à¥¤

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥«à¥©à¥§à¤¸à¥‡ à¥«à¥«à¥­à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¥§à¥¦ à¤ªà¤¾à¤ à¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£ à¤à¤µà¤‚ à¤¸à¤–à¤¾à¤µà¤°à¥à¤—à¤•à¥€ à¤—à¥‹à¤šà¤¾à¤°à¤£à¤²à¥€à¤²à¤¾à¤•à¤¾ à¤¦à¤°à¥à¤¶à¤¨à¥¤ à¤¶à¥à¤°à¥€à¤¸à¥à¤¨à¥à¤¦à¤°à¥€à¤¸à¤°à¥‹à¤µà¤°à¤•à¤¾ à¤¦à¤°à¥à¤¶à¤¨à¥¤ à¤¸à¤¦à¥à¤¯à¤¸à¥à¤¨à¤¾à¤¤à¤¾ à¤•à¤¿à¤¶à¥‹à¤°à¥€ à¤°à¤¾à¤§à¤¾ à¤à¤µà¤‚ à¤¸à¤–à¤¿à¤¯à¥‹à¤‚à¤•à¥‡ à¤¸à¥Œà¤¨à¥à¤¦à¤°à¥à¤¯à¤•à¤¾ à¤¦à¤°à¥à¤¶à¤¨à¥¤ à¤¬à¥à¤°à¤œà¤•à¤¿à¤¶à¥‹à¤° à¤¨à¥€à¤²à¤®à¤£à¤¿à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µà¤°à¤¾à¤—à¤•à¥€ à¤¤à¤¤à¥à¤µà¤°à¤¹à¤¸à¥à¤¯ à¤¸à¤¹à¤¿à¤¤ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿à¥¤ 

**à¤›à¤¨à¥à¤¦ à¤¸à¤‚. à¥«à¥«à¥®à¤¸à¥‡ à¥«à¥­à¥«à¤¤à¤•-** à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤¨ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¥§à¥¦ à¤ªà¤¾à¤ à¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤­à¤—à¤µà¤¤à¥€ à¤ªà¥Œà¤°à¥à¤£à¤®à¤¾à¤¸à¥€à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨, à¤‰à¤ªà¤¨à¤¨à¥à¤¦à¤ªà¤¤à¥à¤¨à¥€ à¤ªà¥€à¤µà¤°à¥€, à¤¯à¤¶à¥‹à¤¦à¤¾à¤®à¥ˆà¤¯à¤¾, à¤•à¥€à¤°à¥à¤¤à¥à¤¤à¤¿à¤¦à¤¾ à¤®à¥ˆà¤¯à¤¾ à¤†à¤¦à¤¿ à¤®à¤¾à¤¤à¥ƒà¤µà¤°à¥à¤—à¤•à¥€ à¤µà¤¾à¤¤à¥à¤¸à¤²à¥à¤¯à¤µà¤¤à¥€ à¤—à¥‹à¤ªà¤¾à¤‚à¤—à¤¨à¤¾à¤“à¤‚à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨, à¤¸à¤®à¤—à¥à¤° à¤°à¤¨à¥à¤§à¤¨à¤²à¥€à¤²à¤¾à¤•à¥‡ à¤¦à¤°à¥à¤¶à¤¨ à¤¹à¥‹à¤‚à¤—à¥‡à¥¤

## (à¤¸à¤ªà¥à¤¤à¤®à¤¸à¥‡ à¤à¤•à¤¾à¤¦à¤¶ à¤¶à¤¤à¤•)
à¤‡à¤¨ à¤¶à¤¤à¤•à¥‹à¤‚à¤•à¥‡ à¤ªà¥à¤°à¤¤à¤¿à¤¦à¤¿à¤µà¤¸ à¤­à¤¾à¤µà¤¸à¤¹à¤¿à¤¤ à¥§à¥¦ à¤ªà¤¾à¤  à¤•à¤°à¤¨à¥‡à¤¸à¥‡ à¤œà¥€à¤µà¤¨à¤•à¥€ à¤¸à¤‚à¤§à¥à¤¯à¤¾à¤•à¥‡ à¤ªà¥‚à¤°à¥à¤µ à¤‡à¤¨ à¤¶à¤¤à¤•à¥‹à¤‚à¤®à¥‡à¤‚ à¤µà¤°à¥à¤£à¤¿à¤¤ à¤¸à¤­à¥€ à¤²à¥€à¤²à¤¾à¤“à¤‚à¤•à¥€ à¤…à¤¨à¥à¤­à¥‚à¤¤à¤¿ à¤¹à¥‹à¤—à¥€à¥¤''');
      }
    }
    else if (sectionId == 'topic4') {
  switch (title) {
    case '(à¤•)à¤¯à¥‹à¤½à¤¹à¤‚ à¤®à¤®à¤¾à¤¸à¥à¤¤à¤¿     à¤¯à¤¤à¥à¤•à¤¿à¤žà¥à¤šà¤¿à¤¦à¤¿à¤¹  à¤²à¥‹à¤•à¥‡  à¤ªà¤°à¤¤à¥à¤° à¤šà¥¤':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''## **à¤¸à¤®à¤°à¥à¤ªà¤£**

## **à¤¯à¥‹à¤½à¤¹à¤‚ à¤®à¤®à¤¾à¤¸à¥à¤¤à¤¿ à¤¯à¤¤à¥à¤•à¤¿à¤žà¥à¤šà¤¿à¤¦à¤¿à¤¹ à¤²à¥‹à¤•à¥‡ à¤ªà¤°à¤¤à¥à¤° à¤šà¥¤**
## **à¤¤à¤¤à¥à¤¸à¤°à¥à¤µà¤‚ à¤•à¥ƒà¤·à¥à¤£ à¤¤à¥‡ à¤¨à¤¾à¤¥ à¤ªà¤¾à¤¦à¤ªà¤¦à¥à¤®à¥‡ à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤à¤®à¥ à¥¤à¥¤**

à¤œà¥‹ à¤®à¥ˆà¤‚ à¤¹à¥‚à¤, à¤®à¥‡à¤°à¤¾ à¤œà¥‹ à¤•à¥à¤› à¤¹à¥ˆ- à¤²à¥‹à¤• à¤”à¤° à¤ªà¤°à¤²à¥‹à¤• à¤¸à¤­à¥€à¥¤
à¤•à¤° à¤…à¤°à¥à¤ªà¤¿à¤¤ à¤šà¤°à¤£à¥‹à¤‚à¤®à¥‡à¤‚ à¤¤à¤µ à¤®à¥ˆà¤‚ à¤¹à¥à¤† à¤ªà¥‚à¤°à¥à¤£ à¤•à¥ƒà¤¤à¤•à¥ƒà¤¤à¥à¤¯ à¤…à¤­à¥€ à¥¤à¥¤

## **à¤¯à¥‹à¤½à¤¹à¤‚ à¤®à¤®à¤¾à¤¸à¥à¤¤à¤¿ à¤¯à¤¤à¥à¤•à¤¿à¤žà¥à¤šà¤¿à¤¦à¥ à¤µà¤¿à¤¶à¥à¤µà¥‡à¤½à¤¸à¥à¤®à¤¿à¤¨à¥à¤®à¤¦à¥ à¤¨à¤¿à¤°à¥à¤®à¤¿à¤¤à¤®à¥ à¥¤**
## **à¤°à¤¾à¤§à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¤¿ à¤¤à¤¤à¥à¤¸à¤°à¥à¤µà¤‚ à¤¤à¥à¤µà¤¤à¥à¤ªà¤¾à¤¦à¤¯à¥‹à¤ƒ à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤à¤®à¥ à¥¤à¥¤**

à¤œà¥‹ à¤®à¥ˆà¤‚ à¤¹à¥‚à¤, à¤œà¥‹ à¤•à¥à¤› à¤¹à¥ˆ à¤œà¤—à¤®à¥‡à¤‚ à¤¦à¥ƒà¤¶à¥à¤¯à¤°à¥‚à¤ª à¤®à¥‡à¤°à¤¾ à¤¨à¤¿à¤°à¥à¤®à¤¾à¤£à¥¤
à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¤¿ à¤°à¤¾à¤§à¤¿à¤•à¥‡, à¤¸à¤¬ à¤¤à¤µ à¤šà¤°à¤£-à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤ à¤²à¥‡à¤¨à¤¾ à¤œà¤¾à¤¨à¥¤à¥¤

## **à¤¯à¥‹à¤½à¤¹à¤‚ à¤®à¤®à¤¾à¤¸à¥à¤¤à¤¿ à¤¯à¤¤à¥à¤•à¤¿à¤žà¥à¤šà¤¿à¤¦à¥ à¤µà¤¿à¤¶à¥à¤µà¤‚ à¤®à¤šà¥à¤›à¤¾à¤¸à¤¨à¤¾à¤¶à¥à¤°à¤¿à¤¤à¤®à¥ à¥¤**
## **à¤°à¤¾à¤§à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¤¿ à¤¤à¤¤à¥à¤¸à¤°à¥à¤µà¤‚ à¤¤à¥à¤µà¤¤à¥à¤ªà¤¾à¤¦à¤¯à¥‹à¤ƒ à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤à¤®à¥ à¥¤à¥¤**

à¤œà¥‹ à¤®à¥ˆà¤‚ à¤¹à¥‚à¤, à¤œà¥‹ à¤•à¥à¤› à¤­à¥€ à¤®à¤® à¤¹à¥ˆ à¤†à¤¶à¥à¤°à¤¿à¤¤-à¤¶à¤¾à¤¸à¤¿à¤¤ à¤¸à¤¾à¤°à¤¾ à¤µà¤¿à¤¶à¥à¤µà¥¤
à¤°à¤¾à¤§à¥‡ à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¤¿, à¤¸à¤­à¥€ à¤¤à¤µ à¤šà¤°à¤£à¤¸à¤®à¤°à¥à¤ªà¤¿à¤¤ à¤¸à¤•à¤² à¤¨à¤¿à¤œà¤¸à¥à¤µà¥¤à¥¤

**à¤œà¥‹ à¤­à¥€, à¤œà¤¬ à¤­à¥€, à¤œà¥ˆà¤¸à¥‡, à¤¤à¥à¤®à¤¸à¥‡ à¤®à¥‡à¤°à¥€ à¤¹à¥ˆ à¤®à¤¾à¤à¤— à¤¹à¥à¤ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥ˆ à¤‰à¤¸à¥‡, à¤‰à¤¸à¥€ à¤•à¥à¤·à¤£, à¤µà¥ˆà¤¸à¥‡ à¤¹à¥€, à¤¤à¥à¤®à¤¨à¥‡ à¤ªà¥‚à¤°à¥€ à¤•à¤° à¤¦à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥ˆ à¤¸à¤¤à¥à¤¯ à¤…à¤¨à¤¨à¥à¤¤à¤•à¤¾à¤²à¤¤à¤• à¤¤à¥à¤® à¤†à¤—à¥‡ à¤­à¥€, à¤à¤¸à¥‡ à¤¹à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¤à¤¿ à¤¯à¤¹à¥€ à¤¸à¥à¤µà¤­à¤¾à¤µ à¤¨à¤¾à¤¥ ! à¤…à¤ªà¤¨à¤¾ à¤¬à¤°à¤¤à¥‹à¤—à¥‡ à¤¹à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥ˆ à¤•à¤¿à¤¨à¥à¤¤à¥ à¤®à¥à¤à¥‡ à¤§à¤¿à¤•à¥à¤•à¤¾à¤°, à¤²à¤¾à¤– à¤¶à¤¤ à¤¬à¤¾à¤° à¤¸à¤°à¥à¤µà¤¦à¤¾ à¤¹à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¨à¥à¤¯à¥Œà¤›à¤¾à¤µà¤° à¤œà¥‹ à¤®à¥ˆà¤‚ à¤¹à¥‹ à¤¨ à¤¸à¤•à¥€ à¤•à¥‡à¤µà¤² à¤¸à¤š, à¤¤à¥à¤®à¤ªà¤° à¤¹à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**'à¤®à¥‡à¤°à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‹à¤‚à¤•à¥€ à¤°à¤¾à¤¨à¥€ à¤¹à¥‡ ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ ! à¤µà¤²à¥à¤²à¤­à¥‡ !' à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¸à¤®à¥à¤¬à¥‹à¤§à¤¿à¤¤ à¤¤à¥à¤®à¤¸à¥‡ à¤¨à¤¿à¤¤à¥à¤¯ à¤¹à¥à¤ˆ, à¤µà¤¿à¤—à¤²à¤¿à¤¤ à¤ªà¤° à¤‰à¤° à¤¨ à¤¹à¥à¤†, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤†à¤à¤–à¥‡à¤‚ à¤¨ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤à¤°à¥€à¤‚ à¤…à¤¹à¥‹ ! à¤•à¤¾à¤¯à¤¾ à¤ªà¥à¤²à¤•à¤¿à¤¤ à¤¨ à¤¹à¥à¤ˆ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¯à¤¹ à¤­à¤¾à¤µà¤°à¤¹à¤¿à¤¤ à¤®à¥ƒà¤£à¥à¤®à¤¯ à¤¬à¥‹à¤à¤¾ à¤•à¤¬à¤¤à¤• à¤®à¥ˆà¤‚ à¤²à¤¿à¤¯à¥‡ à¤«à¤¿à¤°à¥‚à¤, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**'à¤¹à¥ˆ à¤¬à¥à¤°à¤œà¤²à¥€à¤²à¤¾ à¤‰à¤¦à¥à¤¦à¥‡à¤¶à¥à¤¯ à¤®à¥à¤à¥‡ à¤²à¤¾à¤¨à¥‡à¤•à¤¾ à¤‡à¤¸ à¤¤à¤¨à¤®à¥‡à¤‚' à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤•à¤¹à¤¤à¥‡ à¤¹à¥‹ à¤¤à¥à¤®, à¤«à¤¿à¤° à¤•à¥à¤¯à¥‹à¤‚ à¤¨ à¤šà¤²à¥‡à¤‚, à¤–à¥‡à¤²à¥‡à¤‚, à¤¹à¥‹ à¤—à¤¯à¥€ à¤¦à¥‡à¤°, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !'''
      );

    case '(à¤–)à¤®à¥‹ à¤‡à¤šà¥à¤›à¤¿à¤¤ à¤•à¥ˆ à¤•à¥ƒà¤¸à¥à¤¨ à¤ªà¤¿à¤¯, à¤°à¥à¤šà¥ˆ à¤¬à¤¨à¤¿à¤‰, à¤¬à¤¨à¤°à¤¾à¤‰à¥¤':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''## (à¤¦à¥‹à¤¹à¤¾)

**à¤®à¥‹ à¤‡à¤šà¥à¤›à¤¿à¤¤ à¤•à¥ˆ à¤•à¥ƒà¤¸à¥à¤¨ à¤ªà¤¿à¤¯, à¤°à¥à¤šà¥ˆ à¤¬à¤¨à¤¿à¤‰, à¤¬à¤¨à¤°à¤¾à¤‰à¥¤**
**à¤¹à¥‹à¤‡ à¤¨à¤¿à¤°à¤¾à¤µà¤¿à¤² à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿ à¤¬à¥à¤¡à¤¼à¤¿ à¤œà¤¾à¤‰ à¥¤à¥¤à¥§à¥¤à¥¤**

**à¤¬à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ª à¤œà¤¸à¥à¤®à¤¤à¤¿-à¤¸à¥à¤…à¤¨ ! à¤…à¤¬ à¤µà¤¿à¤²à¤®à¥à¤¬ à¤œà¤¨à¤¿ à¤²à¤¾à¤‰à¥¤**
**à¤¹à¥‹à¤‡ à¤¨à¤¿à¤°à¤¾à¤µà¤¿à¤² à¤à¤¹à¤¿ à¤›à¤¿à¤¨ à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿ à¤¬à¥à¤¡à¤¼à¤¿ à¤œà¤¾à¤‰ à¥¤à¥¤à¥¨à¥¤à¥¤**

**à¤¬à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ª à¤¬à¤¿à¤¨à¤¤à¥€ à¤§à¤°à¤¤ à¤…à¤­à¤¿à¤¨à¥Œ à¤¸à¥à¤– à¤¬à¤¿à¤¸à¤°à¤¾à¤‰à¥¤**
**à¤•à¤°à¥Œ à¤…à¤¨à¥à¤—à¥à¤°à¤¹ à¤…à¤¬ à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿ à¤¬à¥à¤¡à¤¼à¤¿ à¤œà¤¾à¤‰ à¥¤à¥¤à¥©à¥¤à¥¤**

**à¤¬à¤¿à¤¸à¥à¤µà¤°à¥‚à¤ª à¤ªà¤¿à¤¯ à¤¬à¥‡à¤¨à¥à¤§à¤°, à¤¸à¤¾à¤à¤µà¤° à¤¬à¤¿à¤°à¤¦ à¤¬à¤¢à¤¼à¤¾à¤‰ à¥¤**
**à¤•à¤°à¥Œ à¤¤à¥à¤°à¤¨à¥à¤¤ à¤•à¥ƒà¤ªà¤¾ à¤®à¤¹à¤¾à¤­à¤¾à¤µ-à¤‰à¤¦à¤§à¤¿ à¤¬à¥à¤¡à¤¼à¤¿ à¤œà¤¾à¤‰ à¥¤à¥¤à¥ªà¥¤à¥¤**

## (à¤¸à¥‹à¤°à¤ à¤¾)

**à¤®à¥‹ à¤¸à¥à¤– à¤²à¤—à¤¿ à¤¤à¥à¤® à¤ªà¥€à¤‰, à¤…à¤¬ à¤²à¥Œà¤‚ à¤•à¤¹à¤¾ à¤¨à¤¹à¥€à¤‚ à¤•à¤¸à¥à¤¯à¥Œà¥¤**
**à¤¤à¥à¤®à¥à¤¹à¤°à¥Œ à¤ªà¥à¤¯à¤¾à¤° à¤…à¤¸à¥€à¤‰à¤, à¤¨à¤¿à¤¤à¥à¤¯ à¤…à¤¤à¥à¤² à¤à¤¸à¥‹à¤‡ à¤¹à¥ˆà¥¤à¥¤à¥«à¥¤à¥¤**

**à¤¦à¥‡à¤–à¥à¤¯à¥Œ à¤…à¤¦à¥à¤­à¥à¤¤ à¤–à¥‡à¤², à¤‡à¤¨ à¤®à¤¾à¤Ÿà¥€-à¤ªà¥à¤¤à¤°à¥€à¤¨ à¤•à¥Œà¥¤**
**à¤…à¤¬ à¤¤à¥à¤°à¤¨à¥à¤¤ à¤¦à¥‹ à¤ à¥‡à¤², à¤¸à¤¬à¤¨à¤¨à¤¿ à¤¬à¥à¤°à¤œ-à¤°à¤¸-à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚ à¥¤à¥¤ à¥¬ à¥¤à¥¤**

## (à¤›à¤¨à¥à¤¦)

**à¤¹à¥‡ à¤®à¤¹à¤¾à¤®à¤¹à¤¿à¤® ! à¤¹à¥‡ à¤¬à¥à¤°à¤œà¤¨à¤¨à¥à¤¦à¤¨ ! à¤•à¤°à¥à¤£à¤¾à¤µà¤°à¥à¤£à¤¾à¤²à¤¯ ! à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥‡ à¤•à¥ƒà¤·à¥à¤£ ! à¤ªà¥à¤°à¤¾à¤£à¤µà¤²à¥à¤²à¤­ ! à¤¸à¤¾à¤à¤µà¤° ! à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤°à¤¸à¤¿à¤¯à¤¾ ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥‡ à¤µà¤‚à¤¶à¥€à¤§à¤° ! à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥‡ à¤¸à¥à¤–à¤®à¥‡à¤‚ à¤¹à¥€ à¤¬à¤¸, à¤¸à¥à¤–à¤¿à¤¯à¤¾ ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥‡ à¤ªà¥à¤°à¤¾à¤£à¥‡à¤¶à¥à¤µà¤° ! à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤¨à¥ˆà¤¯à¤¾à¤•à¥‡ à¤–à¥‡à¤µà¥ˆà¤¯à¤¾ ! à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤…à¤¬ à¤¢à¤°à¥Œ à¤¤à¥à¤°à¤¨à¥à¤¤ à¤ªà¥à¤°à¤¥à¤® à¤…à¤ªà¤¨à¥‡ à¤‡à¤¨ à¤¦à¤¸ à¤°à¥‚à¤ªà¥‹à¤‚à¤ªà¤°, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤«à¤¿à¤° à¤¢à¤°à¥Œ à¤¤à¥à¤°à¤¨à¥à¤¤ à¤µà¤¿à¤¶à¥à¤µà¤®à¤¯ à¤¨à¤¿à¤œ à¤®à¤¦à¥à¤¦à¥ƒà¤¶à¥à¤¯ à¤°à¥‚à¤ªà¤ªà¤°, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¸à¤°à¥à¤µà¤¥à¤¾ à¤¸à¥à¤–à¥€ à¤¤à¥à¤® à¤¹à¥‹ à¤œà¤¾à¤“, à¤–à¤¿à¤² à¤‰à¤ à¥‹ à¤«à¥‚à¤²-à¤¸à¥‡, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤ªà¤²-à¤ªà¤² à¤¬à¤¢à¤¼à¤¤à¥‡ à¤¹à¥€ à¤šà¤²à¥‹ à¤­à¤¾à¤µà¤¸à¤¾à¤—à¤°à¤•à¥€ à¤“à¤° à¤¤à¤¥à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤œà¥‹ à¤¦à¥‹à¤· à¤¨ à¤¦à¥‡à¤–à¥‡ à¤•à¤¹à¥€à¤‚, à¤•à¤­à¥€, à¤à¤¸à¥‡ à¤¹à¥‹ à¤à¤• à¤¤à¥à¤®à¥à¤¹à¥€à¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤…à¤¤à¤à¤µ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¥€ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤®à¥à¤ à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤¬à¤¿à¤¨à¤¤à¥€ à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¯à¤¦à¥à¤¯à¤ªà¤¿ à¤†à¤µà¤¶à¥à¤¯à¤•à¤¤à¤¾ à¤¤à¥à¤®à¤¸à¥‡ à¤•à¤¹à¤¨à¥‡à¤•à¥€ à¤¥à¥€ à¤¨ à¤•à¤¿à¤¨à¥à¤¤à¥, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤•à¤¹ à¤—à¤¯à¥€ à¤”à¤° à¤•à¤° à¤—à¤¯à¥€, à¤¹à¥à¤ˆ à¤ªà¥à¤°à¥‡à¤°à¤¿à¤¤ à¤¤à¥à¤®à¤¸à¥‡ à¤¬à¤¿à¤¨à¤¤à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤•à¤¹à¤¨à¥‡à¤µà¤¾à¤²à¥€, à¤¸à¥à¤¨à¤¨à¥‡à¤µà¤¾à¤²à¥‡ à¤¦à¥‹à¤¨à¥‹à¤‚ à¤¤à¥à¤® à¤¹à¥€ à¤¤à¥‹ à¤¹à¥‹, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¯à¤¹ à¤–à¥‡à¤² à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤¨à¤¿à¤¤à¥à¤¯ à¤¸à¤°à¤¸ à¤à¤µà¤‚ à¤°à¤¹à¤¸à¥à¤¯à¤®à¤¯ à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤¹à¥ˆ à¤²à¤¹à¤°à¤¾à¤¤à¤¾ à¤¹à¥€ à¤°à¤¹à¤¤à¤¾ à¤µà¤¹, à¤¸à¤‚à¤µà¤¿à¤¦-à¤¸à¥à¤µà¤°à¥‚à¤ª à¤¸à¤¾à¤—à¤°, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**
**à¤‰à¤¨ à¤²à¤¹à¤°à¥‹à¤‚à¤•à¤¾ à¤¹à¥€ à¤¨à¤¾à¤® à¤¯à¤¹à¤¾à¤ à¤¸à¤‚à¤¸à¥à¤¥à¤¾à¤¨, à¤¸à¥ƒà¤œà¤¨, à¤²à¤¯ à¤¹à¥ˆ, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !**

## à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¤¶à¥à¤°à¥€à¤•à¥ƒà¤·à¥à¤£à¤•à¤¾ à¤‰à¤¤à¥à¤¤à¤°-

**à¤¹à¥ˆ à¤¸à¤¦à¤¾ à¤¤à¥à¤®à¥à¤¹à¤¾à¤°à¤¾ à¤¹à¥€ à¤¸à¥à¤– à¤¬à¤¸, à¤®à¥‡à¤°à¤¾ à¤¤à¥‹ à¤¸à¥à¤– à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥‡ ! à¤…à¤¹à¥‹ !**
**à¤®à¥ˆà¤‚ à¤•à¤° à¤¦à¥‚à¤à¤—à¤¾ à¤…à¤µà¤¶à¥à¤¯ à¤ªà¥‚à¤°à¥€ à¤ªà¥à¤°à¤¤à¥à¤¯à¥‡à¤• à¤šà¤¾à¤¹, à¤¨à¤¿à¤¶à¥à¤šà¤¿à¤¨à¥à¤¤ à¤°à¤¹à¥‹ !**
**à¤¹à¤® à¤¸à¤­à¥€ à¤…à¤­à¤¿à¤¨à¥à¤¨ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤° à¤¹à¥ˆà¤‚, à¤«à¤¿à¤° à¤­à¥€ à¤œà¥‹ à¤°à¥à¤šà¤¿ à¤¹à¥‹, à¤¤à¥à¤°à¤¤ à¤•à¤¹à¥‹à¥¤**
**à¤¹à¥‡ à¤®à¤¹à¤¾à¤­à¤¾à¤µà¤®à¤¯à¤¿ ! à¤¹à¤®à¥‡à¤‚ à¤²à¤¿à¤¯à¥‡, à¤°à¤¸-à¤¸à¥à¤§à¤¾-à¤¸à¤¿à¤¨à¥à¤§à¥à¤®à¥‡à¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤¬à¤¹à¥‹à¥¤à¥¤'''
      );

    case '(à¤—)à¤¸à¥à¤¨à¥à¤¦à¤° à¤‡à¤¸ à¤¨à¤¿à¤œ à¤šà¤°à¤¿à¤¤à¥à¤° à¤›à¤µà¤¿à¤•à¥‹ à¤®à¥‡à¤°à¥‡ à¤‰à¤°à¤ªà¤° à¤²à¤¿à¤–à¤¨à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''à¤¸à¥à¤¨à¥à¤¦à¤° à¤‡à¤¸ à¤¨à¤¿à¤œ à¤šà¤°à¤¿à¤¤à¥à¤° à¤›à¤µà¤¿à¤•à¥‹ à¤®à¥‡à¤°à¥‡ à¤‰à¤°à¤ªà¤° à¤²à¤¿à¤–à¤¨à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤²à¤¿à¤–à¤¤à¥‡ à¤²à¤¿à¤–à¤¤à¥‡ à¤œà¤¬ à¤•à¤°-à¤ªà¤²à¥à¤²à¤µ à¤¹à¥‹ à¤œà¤¾à¤¯ à¤…à¤§à¤¿à¤• à¤šà¤¿à¤•à¤¨à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤²à¥‡à¤¨à¤¾ à¤¤à¥à¤® à¤ªà¥‹à¤‚à¤› à¤‰à¤¸à¥‡ à¤…à¤ªà¤¨à¥‡ à¤ªà¥€à¤²à¥‡ à¤¦à¥à¤•à¥‚à¤²à¤®à¥‡à¤‚ à¤¹à¥€, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¦à¥‡à¤–à¥‚à¤à¤—à¥€ à¤®à¥ˆà¤‚ à¤‰à¤¨ à¤šà¤¿à¤¹à¥à¤¨à¥‹à¤‚à¤ªà¤° à¤¸à¤¹à¤šà¤°à¤¿à¤¯à¥‹à¤‚à¤•à¤¾ à¤¬à¤¿à¤•à¤¨à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤°à¤œà¤¨à¥€à¤•à¥‹ à¤œà¤¬ à¤µà¤¿à¤°à¤¾à¤® à¤¦à¥‡à¤¨à¥‡ à¤†à¤¯à¥‡à¤—à¥€ à¤‰à¤·à¤¾ à¤¸à¤–à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤†à¤¯à¥‡à¤‚à¤—à¥€ à¤¤à¤¬ à¤µà¥‡ à¤­à¥€ à¤¨à¤¿à¤•à¥à¤žà¥à¤œ à¤µà¤¾à¤¤à¤¾à¤¯à¤¨à¤•à¥‡ à¤¸à¤®à¥€à¤ª à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥‹à¤—à¤¾ à¤«à¤¿à¤° à¤¦à¥à¤µà¤¾à¤° à¤®à¥à¤•à¥à¤¤ à¤­à¥€à¤¤à¤° à¤¹à¥‹à¤‚à¤—à¥€ à¤…à¤ªà¤²à¤• à¤¸à¤¬ à¤µà¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¬à¤¾à¤¹à¤° à¤…à¤²à¤¿à¤¸à¥‡ à¤®à¥à¤–à¤°à¤¿à¤¤ à¤¹à¥‹à¤—à¤¾, à¤«à¥‚à¤²à¥‹à¤‚à¤¸à¥‡ à¤²à¤¦à¤¾ à¤¨à¥€à¤ª à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤®à¤‚à¤—à¤² à¤¨à¥€à¤°à¤¾à¤œà¤¨ à¤¹à¥‹à¤¨à¥‡à¤ªà¤° à¤¬à¤¾à¤¹à¤° à¤²à¤¾à¤¯à¥‡à¤‚à¤—à¥€ à¤µà¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¤® à¤¦à¥‹à¤¨à¥‹à¤‚à¤•à¥‹ à¤‰à¤¨à¤•à¥‡ à¤ªà¥€à¤›à¥‡ à¤ªà¥€à¤›à¥‡ à¤šà¤²à¤¨à¤¾ à¤¹à¥‹à¤—à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤•à¤¾à¤²à¤¿à¤¨à¥à¤¦à¥€à¤•à¥€ à¤‰à¤¨ à¤²à¤¹à¤°à¥‹à¤‚ à¤®à¥‡à¤‚ à¤¹à¤®à¤•à¥‹ à¤¨à¤¹à¤²à¤¾à¤¯à¥‡à¤‚à¤—à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤‰à¤¨à¤•à¥€ à¤°à¥à¤šà¤¿ à¤•à¥‡ à¤¸à¤¾à¤à¤šà¥‡ à¤®à¥‡à¤‚ à¤¹à¥€ à¤¹à¤®à¤•à¥‹ à¤¢à¤²à¤¨à¤¾ à¤¹à¥‹à¤—à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤…à¤¤à¤à¤µ à¤…à¤­à¥€ à¤¸à¥‡ à¤¸à¤š à¤¤à¥à¤®à¤•à¥‹ à¤‡à¤‚à¤—à¤¿à¤¤ à¤•à¤° à¤¦à¥‡à¤¤à¥€ à¤¹à¥‚à¤ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤®à¥ˆà¤‚ à¤¨à¤¿à¤¤à¥à¤¯ à¤…à¤¹à¥‹ à¤°à¤‚à¤—à¤¸à¥à¤¥à¤²à¤•à¥€ à¤œà¥‹ à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤Ÿà¥€ à¤ à¤¹à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥‹ à¤¨à¤¹à¥€à¤‚ à¤¸à¤®à¤¯à¤¸à¥‡ à¤ªà¤¹à¤²à¥‡ à¤¹à¥€ à¤à¤‚à¤•à¥ƒà¤¤ à¤¯à¤¹ à¤°à¤‚à¤— à¤®à¤‚à¤š à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤‡à¤¸à¤²à¤¿à¤¯à¥‡ à¤¬à¤¨à¥€ à¤¬à¥ˆà¤ à¥€ à¤¹à¥‚à¤ à¤®à¥ˆà¤‚ à¤—à¥‚à¤à¤—à¥€ à¤à¤µà¤‚ à¤¬à¤¹à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !'''
      );

    case '(à¤˜)à¤¹à¥ˆ à¤ªà¤¥ à¤¤à¥à¤²à¤¸à¥€ à¤µà¤¨ à¤œà¥‹à¤¹ à¤°à¤¹à¤¾ à¤¹à¤® à¤¦à¥‹à¤¨à¥‹à¤‚ à¤•à¤¾ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''à¤¹à¥ˆ à¤ªà¤¥ à¤¤à¥à¤²à¤¸à¥€ à¤µà¤¨ à¤œà¥‹à¤¹ à¤°à¤¹à¤¾ à¤¹à¤® à¤¦à¥‹à¤¨à¥‹à¤‚ à¤•à¤¾ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤¨à¥€à¤²à¥€ à¤¸à¤°à¤¿à¤¤à¤¾ à¤¹à¥‹ à¤µà¥à¤¯à¤¾à¤•à¥à¤² à¤¹à¥ˆ à¤•à¤° à¤°à¤¹à¥€ à¤¶à¤¬à¥à¤¦ à¤•à¤²-à¤•à¤² à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤¹à¥ˆ à¤…à¤ªà¤²à¤• à¤¬à¤¾à¤Ÿ à¤¨à¤¿à¤¹à¤¾à¤° à¤°à¤¹à¥€à¤‚ à¤µà¥‡ à¤µà¤²à¥à¤²à¤°à¤¿à¤¯à¤¾à¤ à¤«à¥‚à¤²à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤¸à¥à¤¸à¥à¤ªà¤·à¥à¤Ÿ à¤¦à¥‡ à¤°à¤¹à¥€ à¤¹à¥ˆ à¤‡à¤‚à¤—à¤¿à¤¤ à¤¸à¤¾à¤°à¥€ à¤¶à¥à¤• à¤ªà¤° à¤à¥‚à¤²à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤®à¥¤à¥¤
à¤•à¤¾à¤à¤Ÿà¥‹à¤‚ à¤•à¥€ à¤…à¤Ÿà¤µà¥€ à¤®à¥‡à¤‚ à¤®à¤¿à¤²à¤•à¤° à¤¦à¥‡à¤°à¥€ à¤¨ à¤•à¤°à¥‹ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤šà¥‡à¤°à¥€ à¤ªà¤° à¤šà¤°à¤£ à¤¸à¤°à¥‹à¤°à¥à¤¹ à¤•à¥€ à¤…à¤µà¤¿à¤²à¤®à¥à¤¬ à¤¢à¤°à¥‹ à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤¨à¤¶à¥à¤µà¤° à¤¤à¤¨ à¤•à¥€ à¤ªà¤—à¤¡à¤£à¥à¤¡à¥€ à¤ªà¤° à¤ à¤¹à¤°à¥‹ à¤¨ à¤¤à¤¨à¤¿à¤• à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤šà¤²à¤¤à¥‡ à¤œà¤¾à¤“, à¤šà¤²à¤¤à¥€ à¤œà¤¾à¤“, à¤°à¤¹à¤•à¤° à¤—à¥à¤®à¤¸à¥à¤® à¤ªà¥à¤¯à¤¾à¤°à¥€ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤œà¥‹ à¤•à¤¹à¥€à¤‚ à¤…à¤¨à¥à¤œ à¤…à¤§à¤¿à¤•à¤¾à¤°à¥€-à¤°à¥à¤šà¤¿ à¤¯à¤¾ à¤®à¤¹à¥€à¤ªà¤¾à¤²-à¤®à¤¤à¤¿ à¤•à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤†à¤¦à¤° à¤•à¤° à¤ªà¤°à¤¿à¤šà¤¯ à¤¦à¥‡à¤¤à¤¾ à¤œà¤—-à¤¸à¤®à¥à¤¬à¤¨à¥à¤§ à¤¨à¥‡à¤¹-à¤—à¤¤à¤¿ à¤•à¤¾ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤µà¥‡ à¤ªà¤¹à¥à¤à¤š à¤¨à¤¹à¥€à¤‚ à¤ªà¤¾à¤¤à¥‡ à¤…à¤¬ à¤¤à¤• à¤¸à¤šà¥à¤šà¤¿à¤¨à¥à¤®à¤¯ à¤®à¤‚à¤œà¤¿à¤² à¤ªà¤° à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤®à¤¾à¤¯à¤¾ à¤•à¤¾ à¤¤à¤¾à¤ª à¤¨à¤¹à¥€à¤‚ à¤®à¤¿à¤Ÿà¤¤à¤¾, à¤®à¤¿à¤²à¤¤à¤¾ à¤¨ à¤•à¥ƒà¤·à¥à¤£ à¤¤à¤°à¥à¤µà¤° à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤…à¤—à¥à¤°à¤œ à¤•à¥‡ à¤¸à¤¦à¥à¤¦à¥ƒà¤¶ à¤…à¤¨à¥à¤œ à¤¤à¤¨ à¤¸à¥‡ à¤œà¤¿à¤¨à¤•à¤¾ à¤¨à¤¾à¤¤à¤¾ à¤¥à¤¾ à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤
à¤µà¥‡ à¤ªà¤¹à¥à¤à¤šà¥‡à¤‚à¤—à¥‡ à¤¹à¥€ à¤¨à¤¿à¤¤à¥à¤¯ à¤œà¤¹à¤¾à¤ à¤•à¤¾à¤¨à¥à¤¹à¤¾ à¤—à¤¾à¤¤à¤¾ à¤¥à¤¾ à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® à¥¤à¥¤
**à¤‡à¤¸à¥€à¤²à¤¿à¤¯à¥‡ à¤µà¤¿à¤¶à¥à¤µà¤¾à¤¸, à¤•à¤¿à¤¯à¥‡ à¤°à¤¹à¥‹ à¤…à¤µà¤¿à¤šà¤² à¤…à¤¹à¥‹ à¥¤**
**à¤µà¥à¤°à¤œà¤ªà¥à¤° à¤¨à¤¿à¤¤à¥à¤¯ à¤¨à¤¿à¤µà¤¾à¤¸, à¤•à¥à¤‚à¤œ-à¤¸à¥à¤¥à¤² à¤ªà¤° à¤¦à¥ƒà¤— à¤°à¤¹à¥‡à¤‚à¥¥**
**à¤‰à¤ªà¤µà¤¨ à¤•à¥‡ à¤‰à¤¸ à¤ªà¤¾à¤° à¤¹à¤® à¤¸à¤¬ à¤¹à¥€ à¤®à¤¿à¤² à¤œà¤¾à¤¯à¥‡à¤‚à¤—à¥‡**
**à¤®à¤¾à¤¯à¤¾ à¤¸à¤°à¤¿à¤¤ à¤•à¤—à¤¾à¤° à¤ªà¤° à¤®à¤¿à¤²à¤¨à¥‡ à¤®à¥‡à¤‚ à¤¹à¤¾à¤¨à¤¿ à¤¹à¥ˆà¥¤**'''
      );

    case '(à¤¡à¤¼)à¤¸à¤¾à¤à¤µà¤°-à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤†à¤—à¥‡ à¤¹à¥ˆà¤‚, à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤ªà¥€à¤›à¥‡ à¤¹à¥ˆà¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''à¤¸à¤¾à¤à¤µà¤°-à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤†à¤—à¥‡ à¤¹à¥ˆà¤‚, à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤ªà¥€à¤›à¥‡ à¤¹à¥ˆà¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¸à¤¾à¤à¤µà¤°-à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤¦à¤¹à¤¿à¤¨à¥‡ à¤¹à¥ˆà¤‚, à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤¬à¤¾à¤¯à¥‡à¤‚ à¤¹à¥ˆà¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¸à¤¾à¤à¤µà¤°-à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤¨à¥€à¤šà¥‡ à¤¹à¥ˆà¤‚, à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤Šà¤ªà¤° à¤¹à¥ˆà¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¸à¤¾à¤à¤µà¤°-à¤¸à¤¾à¤à¤µà¤° à¤¹à¥€ à¤…à¤¬ à¤•à¥‡à¤µà¤² à¤¸à¤°à¥à¤µà¤¤à¥à¤° à¤…à¤µà¤¸à¥à¤¥à¤¿à¤¤ à¤¹à¥ˆà¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥ˆ à¤¤à¤¤à¥à¤¤à¥à¤µ à¤¬à¤¤à¤¾à¤¯à¤¾ à¤¤à¥à¤®à¤¨à¥‡ à¤¹à¥€, à¤¤à¥à¤®-à¤¹à¥€-à¤¤à¥à¤® à¤¹à¥‹ à¤®à¥‡à¤°à¥‡, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥ˆà¤‚ à¤¯à¤¾ à¤•à¥‡à¤µà¤² à¤°à¤¾à¤§à¤¾-à¤°à¤¾à¤§à¤¾, à¤«à¤¿à¤° à¤¨à¤¿à¤¤à¥à¤¯ à¤¯à¥à¤—à¤² à¤­à¥€ à¤¹à¥‹, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¯à¤¹ à¤®à¥ˆà¤‚ à¤ªà¥à¤°à¤¤à¤¿à¤¬à¤¿à¤®à¥à¤¬à¤¿à¤¤ à¤¹à¥ˆ à¤ªà¥à¤°à¤¤à¤¿à¤®à¤¾ à¤°à¤¾à¤§à¤¾à¤•à¥€ à¤®à¤¾à¤¯à¤¾à¤®à¥‡à¤‚, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤¹à¥ˆ à¤•à¤¿à¤‚à¤¤à¥ à¤¬à¤¿à¤®à¥à¤¬à¤¸à¥‡ à¤­à¤¿à¤¨à¥à¤¨ à¤•à¤¹à¤¾à¤ à¤¸à¤¤à¥à¤¤à¤¾ à¤›à¤¾à¤¯à¤¾à¤•à¥€, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤°à¤¾à¤§à¤¿à¤•à¤¾à¤°à¤®à¤£ à¤¨à¤¿à¤°à¤µà¤§à¤¿ à¤œà¤¯ à¤œà¤¯, à¤œà¤¯ à¤…à¤®à¥à¤¬à¥à¤œà¤¨à¤¯à¤¨ à¤¸à¤¦à¤¾, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤œà¤¯ à¤¸à¤¤à¤¤ à¤¨à¤¨à¥à¤¦à¤¨à¤¨à¥à¤¦à¤¨ à¤œà¤¯ à¤œà¤¯, à¤œà¤¯ à¤¨à¤¾à¤¥ à¤¨à¤¿à¤°à¤¨à¥à¤¤à¤°, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤—à¥‹à¤ªà¤¿à¤•à¤¾-à¤ªà¥à¤°à¤¾à¤£ à¤¸à¤°à¥à¤µà¤¦à¤¾ à¤¤à¤¥à¤¾ à¤œà¤¯ à¤®à¤¨à¥à¤®à¤¥à¤®à¤¥à¤¨ à¤…à¤¹à¥‹, à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !
à¤šà¤¿à¤°à¤•à¤¾à¤² à¤µà¤¿à¤¶à¥à¤µà¤°à¤žà¥à¤œà¤¨ à¤œà¤¯ à¤œà¤¯, à¤œà¤¯ à¤•à¥ƒà¤·à¥à¤£ à¤…à¤¹à¤°à¥à¤¨à¤¿à¤¶, à¤¹à¥‡ à¤ªà¥à¤°à¤¿à¤¯à¤¤à¤® !'''
      );

    default:
      return const _TopicPageContent(body: '''Content not yet set.''');
  }
}
    // 4. Default Fallback (Jab koi condition match na ho)
    return const _TopicPageContent(
      body: '''this is shrey ''',
    );
  }
}

