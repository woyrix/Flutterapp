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
    if (sectionId == 'topic1' && title == 'संक्षिप्त जीवन परिचय') {
      return const _TopicPageContent(
        imagePaths: [
          'assets/images/sidebar/radha_baba_jivan_01.png',
          'assets/images/sidebar/radha_baba_jivan_02.jpg',
        ],
        body:
            '''पूज्यश्रीचक्रधर मिश्र, जिन्हें बाद में श्रीराधा बाबा के नाम से जाना गया, उनका जन्म १६ जनवरी १९१३ को बिहार के फखरपुर गाँव में हुआ था। उनके पिता महिपाल मिश्र एक विद्वान और धर्मनिष्ठ ब्राह्मण थे, और चक्रधर मिश्र (श्रीराधाबाबा) अपने माता-पिता के चौथे पुत्र थे। उनकी माता, अधिकारिणी देवी भी एक अत्यंत पुण्यात्मा थीं।
बचपन में ही श्रीराधा बाबा ने छह से सात भाषाओं पर योग्यता प्राप्त कर ली थी, जिससे उनकी विद्वता का परिचय मिलता है। यद्यपि, उच्च ज्ञान की उनकी जिज्ञासा ने उन्हें शिक्षा के पार आध्यात्मिकता की ओर अग्रसर किया।
श्रीराधाबाबा का प्रारंभिक जीवन एक जिज्ञासु के रूप में आध्यात्मिकता के विषयों पर भिन्न-भिन्न तरीकों के अनुसंधान से भरा हुआ था। प्रारंभ में पूज्य बाबा ने वेदांत के मार्ग का अनुसरण किया, जो भारतीय दर्शन का महत्वपूर्ण अंग है जो आत्म-साक्षात्कार और आत्मा तथा ब्रह्मांडीय चेतना की एकता पर बल देता है, और आगे चलकर पूज्य बाबा एक दृढ़ वेदांती बने, जो सत्य की खोज के लिए बौद्धिक रूप से संकल्पित थे।
यद्यपि, श्रीराधा बाबा के जीवन में एक महत्वपूर्ण मोड़ तब आया जब उनकी भेंट पूज्य श्रीभाईजी (श्रीहनुमान प्रसाद पोद्दार) से हुई। श्रीभाईजी एक महान आध्यात्मिक व्यक्तित्व थे, जो गीता प्रेस गोरखपुर के माध्यम से आध्यात्मिक साहित्य को संपादित और प्रकाशित कर धर्म ग्रंथों का प्रचार करते थे ॥ श्रीराधा बाबा का श्रीभाईजी से संपर्क जयदयाल जी गोयनका के माध्यम से हुआ, जो गीता प्रेस के संस्थापक थे। यही वह समय था जब श्रीपोद्दार जी के संग के प्रभाव से श्रीराधा बाबा ‘वेदान्त मार्ग’ से ‘भक्ति मार्ग’ के पथिक बन गए॥
श्रीराधाबाबा का ‘वेदांत मार्ग’ से ‘भक्ति मार्ग’ की ओर परिवर्तन एकदम से नहीं हुआ। श्रीभाई जी के संग के प्रभाव से और भाईजी के मार्गदर्शन से श्रीराधा बाबा की कठोर वेदान्तिक प्रवृत्ति एक कोमल और भावनात्मक भक्ति मार्ग की ओर मुड़ गई, विशेष रूप से भगवान श्रीकृष्ण के प्रति। उन्होंने ब्रज साधना को अपनाया, जो भगवान श्रीकृष्ण के प्रेम और भक्ति में डूबने की साधना है, विशेषकर गोपी और राधाभाव में। यह परिवर्तन श्रीराधा बाबा के जीवन में एक नए चरण की शुरुआत थी। एक कट्टर बौद्धिक से, वे एक कोमल हृदय वाले, भक्ति से पूरित भक्त बन गए, जो श्रीकृष्ण के प्रेम में पूरी तरह डूब गए थे और आगे चल कर राधा भाव से श्रीकृष्ण की उपासना करने के कारण उन्हें श्रीराधा बाबा के नाम से जाना गया। 
श्रीराधा बाबा ने संत श्री चैतन्य महाप्रभु की परंपरा का अनुसरण किया, जो १६ वीं शताब्दी के संत थे और जिन्होंने भक्ति आंदोलन में श्रीकृष्ण के प्रति अपने गहन प्रेम और भक्ति का परिचय दिया। चैतन्य महाप्रभु की तरह, राधा बाबा की ‘भक्ति नाम साधना’ और ‘भाव समाधि’ (दिव्य प्रेम में गहन भावनात्मक अभिव्यक्ति) में प्रकट हुई। इन साधनाओं ने उन्हें गहन आध्यात्मिक आनंद की अवस्थाओं में पहुंचा दिया, जहां वे कई दिनों तक बाहरी दुनिया से पूरी तरह अनभिज्ञ रहते थे।
श्रीराधा बाबा का जीवन कठोर तप और सादगी से भरा था, जो उस समय के संतों में भी दुर्लभ था। उन्होंने अपने पूरे जीवन सख्त अनुशासन का पालन किया, जिसमें वे दिन में केवल एक बार भोजन और जल ग्रहण करते थे। उनका यह सरल और अनुशासित जीवन किसी दिखावे के लिए नहीं था, बल्कि उनके आध्यात्मिक विश्वास की एक अभिव्यक्ति था। उन्होंने कभी धन को हाथ नहीं लगाया और न ही किसी विलासिता का कभी आनंद लिया। भौतिक सुख-सुविधाओं से उनका पूर्ण त्याग उनके आध्यात्मिक आदर्शों का प्रतीक था।
श्रीराधाबाबा का श्रीभाईजी के साथ गहरा संबंध था, और उनका एक अनोखा आध्यात्मिक संबंध था। वे दोनों गोरखपुर के शांतिपूर्ण और आध्यात्मिक रूप से प्रबुद्ध स्थान गीता वाटिका में साथ रहते थे, जो भक्तों को आकर्षित करता था। जो लोग भाईजी का अनुसरण करते थे, वे स्वाभाविक रूप से श्रीराधा बाबा से परिचित हो ही जाते थे, लेकिन बाबा ने कभी भी अपने लिए अनुयायियों या प्रसिद्धि की चाह नहीं रखी। उनकी विनम्रता इतनी थी कि वे एक उत्कृष्ट लेखक और कवि होते हुए भी अपने कार्यों को अपने नाम से प्रकाशित नहीं करते थे। उनकी पुस्तकों और लेखों को गुमनाम रूप से “एक साधु” के रूप में प्रस्तुत किया जाता था। उनकी भक्ति से ओत प्रोत कविताएँ उनके गहरे आध्यात्मिक अनुभवों की अभिव्यक्ति थीं, लेकिन वे भी बिना हस्ताक्षर के रहीं।
श्रीराधा बाबा की आध्यात्मिक साधना भगवान्नाम जप पर केंद्रित थी। उनका मानना था कि भगवान के नाम का जप सबसे उच्चतम आध्यात्मिक साधना है और सच्चे विश्वास के साथ की गई प्रार्थना आत्म-साक्षात्कार के लिए सबसे शक्तिशाली साधन है। उनके अनुसार, यदि पूरी भक्ति और विश्वास के साथ प्रार्थना और भगवान का नाम जप किया जाए तो वह कभी असफल नहीं हो सकता।
श्रीराधा बाबा ने आध्यात्म के उच्च स्तर को प्राप्त किया, लेकिन उन्होंने कभी भी अपने आध्यात्मिक उपलब्धियों को उजागर नहीं किया और न ही कोई शिष्य बनाया। उनकी आध्यात्मिकता और अनुभव बहुत ही व्यक्तिगत थे, और उन्होंने इसके लिए कभी प्रसिद्धि की कामना नहीं की। बाबा की गहरी समाधि अवस्थाओं का साक्षात्कार उनके निकट रहने वाले लोगों ने किया, क्योंकि वे इन अवस्थाओं में कई दिनों तक दुनिया से पूरी तरह से विच्छिन्न रहते थे। यहाँ तक कि उन्होंने लगातार पंद्रह वर्षों तक “काष्ठ मौन” (पूर्ण मौन जिसमें कोई संकेत भी न करना) में बिताया जो अपने आप में एक अत्यंत कठोर साधना है।
श्रीराधा बाबा का जीवन विनम्रता, भक्ति और त्याग का उदाहरण था। उन्होंने चुपचाप अपने गुरु श्रीहनुमान प्रसाद पोद्दार की छाया में जीवन बिताया और कभी व्यक्तिगत मान्यता की इच्छा नहीं की। उनकी महानता न केवल उनकी आध्यात्मिक उपलब्धियों में थी, बल्कि इसमें भी थी कि उन्होंने इन्हें प्रचारित करने से मना किया। उनकी कृष्ण के प्रति भक्ति, समर्पण और दिव्य प्रेम की काव्यात्मक अभिव्यक्ति ‘प्रियतम काव्य’ उन साधकों को प्रेरित करती रहती है जो प्रेम मार्ग का अनुसरण करना चाहते हैं।
हालाँकि उन्होंने कोई औपचारिक शिष्य नहीं बनाए, परन्तु श्रीराधा बाबा की प्रार्थना की शक्ति, भगवान के नाम के जप का महत्व, और एक जीवन जो पूरी तरह से भगवान को समर्पित हो, उनकी शिक्षाएँ आज भी उनके भक्तों के बीच प्रतिध्वनित होती हैं। उनका जीवन एक शक्तिशाली अनुस्मारक है कि सच्ची आध्यात्मिकता बाहरी मान्यता में नहीं, बल्कि दिव्य प्रेम की निरंतर और अडिग खोज में निहित है। उनकी अंतिम इच्छा थी कि वे श्री हनुमान प्रसाद जी पोद्दार की समाधि के पास अपने शरीर को त्यागें और यह इच्छा पूरी हुई। वे संकल्प सिद्ध संत थे जिन्होंने अपनी इच्छा से शरीर का त्याग किया। उन्होंने अपने गुरु श्रीभाईजी को यह वचन दिया था कि वे उनकी (श्रीभाई जी) धर्म पत्नी ‘जिन्हें सब माँजी कहते थे’ की देखभाल उनके जाने के बाद करेंगे, तब तक जब तक वे शरीर में रहेंगी। पूज्य माँजी के शरीर त्यागते ही, कुछ दिनों बाद पूज्य श्रीराधा बाबा ने ‘जाने’ का संकल्प कर लिया और अर्थात १३ अक्टूबर १९९२ को हम सभी लोगों के मध्य से उन्होंने सदा के लिए विदाई ली॥ 
महाभावनिमग्न श्रीराधा बाबा, जिनका ‘अंतःकरण’ श्रीराधा हैं, जिनका ‘भाव देह’ श्रीराधा हैं, जिनकी ‘इंद्रियाँ’ श्रीराधा हैं, जिनकी ‘बुद्धि’ श्रीराधा हैं, उनका संक्षिप्त जीवन परिचय कैसे लिखा जा सकता है ? फिर भी उनकी कृपा से ही कुछ अंश यहाँ दिया गया है पर सत्य तो ये है-''',
        boldFooter: '''      कोई  न चितेरा हुआ यहाँ, आगे न कभी होगा, प्रियतम ! 
  जो चित्र सलोनी नृपकी उस बेटीका सही लिखे, प्रियतम !''',
      );
    }
    // 2. Dusri Subheading add karein (Exact wahi title use karein jo drawer mein hai)
    else if (sectionId == 'topic1' &&
        title ==
            'श्रीराधाबाबा के द्वितीय काष्ठमौन पर पूज्य श्रीभाई जी के उद्गार पूज्य बाबाके लिए') {
      return const _TopicPageContent(
        // Agar isme bhi images chahiye toh unka path yahan dein, warna list khali chhod dein
        imagePaths: [],
        body:
            '''स्वामीजीका मौन व्रत आजसे आरम्भ हो गया। इन दिनों स्वामीजीके पास जो लोग बहुत आये गये, जिन लोगोंसे स्वामीजीने बड़ी स्वच्छन्दतासे बात-चीत की, बहुत प्रेमका स्नेहसना व्यवहार किया, बड़ा अमृत उडेला, अब उन लोगोंके मनमें स्वामीजीके न बोलनेकी स्थिति उत्पन्न हो जानेसे क्षोभ होना स्वाभाविक है। अभीकी बात है कि मेरे घरके लोग, इतना ही नहीं, बच्चे और बूढ़े-बूढ़े लोग भी मेरे पास आये और रोने लगे। यह स्वाभाविक ही है। जिनसे लाभ मिला, जिनसे प्यार मिला, जिनसे स्नेह मिला, जिनसे अमृत मिला, उसका स्रोत यदि कहीं बन्द होता-सा दिखलायी दे तो स्वाभाविक ही मनमें क्षोभ होता है। पर स्वामीजीका यह मौन असलमें नया नहीं है। जो लोग बिलकुल नये नहीं हैं, वे जानते हैं कि लगभग दस वर्ष पहले इसी पंडालमें काष्ठमौनकी घोषणा स्वामीजीने की थी।
काष्ठमौनका अर्थ केवल वाणीका मौन नहीं होता, अपितु 'जगतकी और शरीरकी सारी क्रियाओंसे सर्वथा अपनेको हटा लेना, सबसे मौन हो जाना' यह होता है काष्ठमौन।
 उसका विधान इस प्रकार है कि जो काष्ठमौन व्रत ले, वह सब कुछ परित्याग करके घरसे चल दे, कुटियासे चल दे हिमालयकी ओर। चलनेके लिये चल दे। उसके मनमें कहींपर विश्राम करनेके लिये अथवा ठहरनेके लिये संकल्प न हो। चलते-चलते दैवकी प्रेरणासे रास्ते में कोई कुछ खिला दे तो खा ले, कोई कुछ पिला दे तो पी ले। जहाँ शरीर अशक्त होकर गिर जाये, वहाँ नींद ले ले। फिर उठकर चल दे। इस प्रकार चलते-चलते जहाँ अन्तिम रूपमें शरीर गिर जाये, वहाँ गिर जाये।
उस दिन इसी पंडालमें काष्ठमौनका यही अर्थ स्वामीजीने समझाया था। उन्होंने कहा था कि इसीको लक्ष्य करके मैंने काष्ठ-मौनका मनमें विचार किया था और यही विचार है, परंतु इस प्रकारसे इतना कड़ा व्रत कुछ ठीक नहीं रहता। इसलिये किसीकी ओर न देखना, किसी प्रकारका संकल्प न करना, इशारेसे भी किसी बातका किसी तरह उत्तर न देना, ऐसा व्रत उन्होंने लिया और कई वर्षोंतक उन्होंने किसीकी ओर देखातक नहीं। आगे चलकर कुछ ऐसी कठिन समस्याएँ सामने आयीं कि उनके मौन व्रतमें कुछ शिथिलता आयी। वह शिथिलता भी, उनके स्वरूपमें शिथिलता नहीं, अपितु पद्धतिमें शिथिलता आयी। क्रमशः शिथिलता बढ़ती गयी। फिर उस शिथिलताको विराम देनेके लिये पुनः यह कलवाला रूप सामने आ गया।
कुछ भीतरी बातें ऐसी हैं, जिनको मैं संकेत रूपसे ही कह सकता हूँ। सब बात तो कहना उचित नहीं। काष्ठमौनमें और स्वामीजीके काष्ठमौनमें थोड़ा-सा अन्तर है। ये सब साधनाके क्षेत्रमें सिद्धांतकी बातें हैं। एक होता है रस-मार्ग और दूसरा ज्ञान-मार्ग। दोनों मार्गोंमें ही तत्त्वज्ञान अपेक्षित है। रस-मार्गका सिद्ध पुरुष तत्त्वज्ञानसे रहित नहीं होता और तत्त्वज्ञानीमें तत्त्वज्ञान रहता ही है, रस चाहे न हो। दोनोंमें इतना-सा अन्तर है। तत्त्वज्ञानीमें रस चाहे न हो, पर वह तत्त्वमें स्थित होता है, ब्रह्मनिष्ठ होता है, मुक्त होता है। इसी प्रकार रस-सिद्ध पुरुष भी तत्त्वज्ञानी होते ही हैं। उनकी दृष्टिमें जगत वैसा नहीं रहता, जैसा हम सांसारिक लोगोंकी दृष्टिमें है। वे जगतसे मुक्त हो जाते हैं, परंतु उनमें एक प्रकारके रसका आविर्भाव होता है, जो आगे जाकर समुद्र बन जाता है। उस महासमुद्रमें अनन्त तरंगें उठती हैं और उन तरंगोंमें वह लहराता है। कभी-कभी वह उस समुद्रके तटपर आता है तो बाहर दिखलायी देता है, अन्यथा वह उन्हीं तरंगोंमें रहता है। इस प्रकारसे समुद्रमें डूबे हुए लोगोंके उदाहरणस्वरूप वर्तमानमें हमारे सामने थे श्रीचैतन्य महाप्रभु। अन्तिम गम्भीरा लीलाके समय वे इस रस-समुद्रके तटपर भी नहीं आये, उसीमें डूबे रहे। उसी प्रकारसे स्वामीजीका जो काष्ठमौन था, वह काष्ठमौन केवल तत्त्वज्ञानमें स्थितिजनित पंचम भूमिकातक वाला नहीं, क्रियाके अभावके स्वरूपवाला नहीं, अपितु रस-समुद्रके लहरानेके स्वरूपवाला है। बस, इतना इसमें और उसमें अन्तर है। यह काष्ठमौन रसका है और वह काष्ठमौन तत्त्वज्ञानका है।
पहले ये श्रीराजेन्द्रबाबूजी ( प्रथम राष्ट्रपति श्रीराजेन्द्रप्रसाद जी ) के साथ राजनैतिक क्षेत्रमें काम करते थे। वे उम्रमें कुछ बड़े थे और ये छोटे थे, पर उनके साथ बिहारमें काम करते थे। ये स्कूलसे निकलकर जेल गये और जेलमें कई दिनोंतक रहे। भगवानकी लीला विचित्र होती है। मनुष्यको पतातक नहीं लगता कि भगवान किसको कैसे किस मार्गमें ले जाना चाहते हैं, पर वे ले जाते हैं। राजनैतिक क्षेत्रमें कार्य करते-करते उसी जेलमें इनके मनमें कुछ दूसरे प्रकारके भाव आये। जेलमें ही और जेलसे निकलनेके बाद इन्होंने अध्ययन किया। शुरूसे ही ये बड़े प्रतिभाशाली थे। कालेजसे पहले ही स्कूलमें ही इनकी प्रतिभाका ज्ञान अध्यापकोंको और अधिकारियोंको हो चुका था। इन्होंने अद्वैत तत्त्वका अन्वेषण, अध्ययन और साधन किया और ये उसमें बहुत आगे बढ़ गये। कलकत्तेमें ये बड़े विरक्त भावसे रहते, कभी फुटपाथपर पड़े रहते। कहीं खानेको मिल गया, खा लेते और जो मिल गया, ले लेते।
श्रीसेठजी (श्रीजयदयालजी गोयन्दका) का गीतापर विवेचन बड़ा सुन्दर हुआ करता था। इनके मनमें उनके पास जानेकी इच्छा जाग्रत् हुई। ये चले गये बाँकुड़ा। बाँकुड़ा जाकर ये श्रीसेठजीके पास रहे। यह जो गीता-तत्त्व-विवेचनी टीका है, इसमें भाव श्रीसेठजीके हैं, पर इस सारी टीकाको मूलतः इन्होंने अपने हाथसे लिखी है और इसमें टिप्पणी और सारा संशोधन मेरा किया हुआ है। वहाँ ये श्रीसेठजीके पास रहने लगे। ये बड़े कट्टर निर्गुणवादी थे। श्रीसेठजी यद्यपि अद्वैत निर्गुण तत्त्वके ही परिपोषक थे, इसपर भी वे साधनाके क्षेत्रमें सगुण तत्त्वका भी निरूपण किया करते थे और ये उसे माया कहकर खण्डन कर देते थे। इनका आपसमें तर्क-वितर्क चलता। तर्क-वितर्कमें कहीं कटुता नहीं आती। यह होता बड़ा सुन्दर और आनन्दपूर्ण, पर तर्क-वितर्कमें एक-दूसरेको समझा सकें, ऐसी स्थिति नहीं आयी। श्रीसेठजीके पास अनुभव था, पर गीताके अतिरिक्त अन्य शास्त्र नहीं था और इनके पास बड़ा भारी अध्ययन था। जब ब्रह्मसूत्रके सूत्रोंको लेकर और उपनिषदोंके मन्त्रोंको लेकर ये अपने मतको पुष्ट करने लगते, तब श्रीसेठजी सिद्धान्तकी बात तो कह देते, पर वे उत्तरका प्रत्युत्तर नहीं दे पाते। श्रीसेठजी उस प्रकारकी शास्त्रीय भाषामें अपने मतका प्रतिपादन नहीं कर पाते थे। एक दिन श्रीसेठजीने कहा- स्वामीजी ! आप भाई हनुमानके पास चले जाइये।
श्रीसेठजी मेरे बड़े मौसेरे भाई लगते थे। मैं उनसे छोटा था, अतः वे मुझे हनुमान ही कहते थे। श्रीसेठजीके ऐसा कहनेपर स्वामीजीने कहा वहाँ जाकर क्या करना है ?
श्रीसेठजीने कहा- आप एक बार हो तो आइये।
उन्होंने टिकट कटवा दी और ये यहाँ आ गये। उस समय यहाँ साल भरका अखण्ड हरिनाम संकीर्तन चल रहा था। अखण्ड कीर्तनके साधकोंके लिये घासकी बहुत-सी कुटियाएँ यहाँ बनी हुई थीं, इनको एक छोटी-सी कुटिया रहनेके लिये दे दी गयी। इन्होंने मुझसे बतलाया कि मैं किसलिये आया हूँ। मैंने कहा कि मैं तो कुछ जानता हूँ नहीं, पर आप रहिये।
यहाँ आनेके पश्चात् ये बिलकुल बदल गये। बदलते-बदलते ये रस-तत्त्वमें प्रवेश करके व्रज-रसके उपासक बन गये। दो चीज होती है। रस-तत्त्ववाले अद्वैतके विरोधी होते हैं और अद्वैत तत्त्ववाले रस-तत्त्वको अज्ञानकी भूमिकामें मानते हैं। अद्वैत मतावलम्बी सम्प्रदायमें कुछ ऐसे भी हैं, जो भगवानको भी मायाकी वस्तु मानते हैं और कहते हैं कि ईश्वर मायोपाधिक हैं तथा जीव अविद्योपाधिक है। अविद्या और मायाका निरसन हुआ कि न जीव है और न ईश्वर है। वे ईश्वरकी सत्ता भी तत्त्वतः स्वीकार नहीं करते। बस, साधनकालमें ईश्वरका उपयोग करना मानते हैं। वे अन्तःकरणकी शुद्धिके लिये ईश्वरका स्तवन करना, पूजन करना आवश्यक मानते हैं। इसलिये वे कहते हैं कि साधनाकालमें उपासना भी बड़ी लाभदायक होती है, पर उपास्य ईश्वर कोई तत्त्वकी वस्तु नहीं, अपितु वह तो साधनाकी चीज है। इसी तरहसे रस-तत्त्वके लोग भी अद्वैत-तत्त्वका बड़ा मखौल उड़ाया करते हैं और इसे जड़ तथा आकाशकी भाँति शून्य कहकर उपहास किया करते हैं। वह उपहास कुछ तो उनका विनोद होता है (और विनोदमें तो कोई आपत्ति नहीं), कुछ वह शास्त्रार्थके लिये हठ होता है, कुछ वह दुराग्रह होता है, (जो अच्छा नहीं) और कुछ तो वह अज्ञान ही होता है, जिसका दोनों ओरसे निरसन ही होना चाहिये। ये कुछ सिद्धान्तकी बातें हैं। अद्वैत-तत्त्वमें स्वामीजीकी निष्ठा होते हुए भी रस-तत्त्वमें इनका प्रवेश हुआ और वह प्रवेश उत्तरोत्तर वर्धित होता चला गया। जो इनके अन्तरंग जीवनके सम्पर्कमें आये हैं, उनको मालूम है कि महाभावकी जो अगले स्तरकी चीज है, जिसकी रूप-रेखा शायद जीव गोस्वामीजी तकने भी नहीं खींची, वैसी चीज इनमें व्यक्त हुई, इनके अनुभवमें आयी। वे व्रज-रसके उपासक बन गये और उसकी उत्तरोत्तर पुष्टि होती गयी और उसीका परिणाम था इनका पूर्वका काष्ठमौन। इस प्रकारसे इनका काष्ठमौन असलमें इनका रस-समुद्रमें निमज्जन है और रस-सागरमें जो भावतरंगें उठा करती हैं, सम्भव है, वे इनके जीवनमें उठें। कैसे उठें, क्या उठें, तरंगोंका कुछ पता नहीं चलता। इसलिये इनकी यह वस्तु आजकी कोई नयी नहीं, पुरानी चीज है और अवश्य ही साधनाके क्षेत्रमें यह एक बड़ी विलक्षण वस्तु है कि जहाँ रस-तत्त्व और ब्रह्म-तत्त्व एक-दूसरेके अ-प्रतिद्वन्द्वी होकर एक साथ एक रूपमें रहते हों। ये रहे हैं पहले। ऐसा नारदादिमें था। भगवान शंकराचार्यमें भी ऐसा माना जाता है, लेकिन ये उदाहरण विरल होते हैं, बहुत कम होते हैं। इससे लोगोंको शिक्षा लेनी चाहिये।
जो लोग ऐसा समझते हैं कि स्वामीजीके मौन हो जानेसे अब हम लाभसे वंचित हो गये, यह उनकी भूल है। असली बात तो यह है कि लाभसे वंचित होता है भावसे रहित व्यक्ति। शास्त्रोंमें संतकी महिमा तो यहाँतक कही गयी है कि यदि किसी देशमें संतका अस्तित्व है, भले वह किसीसे बोलता नहीं, मिलता नहीं, वह बातचीत तो करता ही नहीं, कोई उसे जानता नहीं, किंतु यदि उसका अस्तित्व है तो उस अस्तित्वसे ही जितने अंशतक उस संतमें प्रागल्भ्य है, जितना उसका तेज है, उसके अनुपातसे जगतको लाभ अपने आप होता है। जैसे कहीं बर्फ ढकी हुई रखी हो और हमको दिखलायी नहीं दे, भले न दीखे, पर उसकी ठण्ड हमें मिलेगी ही। इसी प्रकारसे संतका रहना जगतमें लाभदायक है।
दूसरी बात यह है कि यदि किसी संतमें किसी व्यक्तिकी वास्तविक श्रद्धा, विश्वास या प्रेम-प्रीति है, तो संतके अंदर जो भाव हैं, उन भावोंका संक्रमण उस प्रेमीमें अपने आप होता रहेगा। वह संत न मिले, न बातचीत करे तो कोई बात नहीं, पर उन भावोंका संक्रमण अपने आप होता रहेगा।
तीसरी बात इससे भी और अधिक आवश्यक है संतकी सेवाके विषयमें। यह बड़ा सुन्दर है और सराहनीय है कि उनके न बोलनेके कारण हमें बोलीके वियोगमें दुःख होता है, पर जो उनकी सेवा करना चाहते हैं, उनके लिये उचित यह है कि हमने उनसे जो सीखा है, उन्होंने विभिन्न प्रकारसे जो शिक्षा दी है और इन दिनोंमें आने-जानेवाले लोगोंसे जिसके लिये जो उन्होंने कहा है, जैसे तुम सत्य बोला करो, तुम गरीबकी सेवा किया करो, तुम अमुक नामका इतना जप किया करो, तुम इतना पाठ किया करो, उसे अपने जीवनका व्रत मानकर अपने जीवनमें उतार लें। उनकी रुचिके अनुसार जीवन बनानेसे सच्ची सेवा होगी और उनके द्वारा लाभ प्राप्त करनेका यह बड़ा माध्यम सिद्ध होगा।	
स्वामीजी आज मौन हो गये। उनका मौन होना बड़ा मंगलमय ! वे यदि रस-समुद्रमें डूबें और डूब जायें हमेशाके लिये तो स्वाभाविक ही उसके कुछ कण हमलोगोंको मिलेंगे ही। उनका डूबना बड़ा अच्छा !''',
      );
    }

    // 3. Teesri Subheading add karein
    else if (sectionId == 'topic1' && title == 'श्रीराधाबाबा – जीवनयात्रा') {
      return const _TopicPageContent(
        imagePaths: [],
        body: '''१. १६ जनवरी, १९१३-		आविर्भाव
२. सन् १९२८ से सन् १९३१ तक-	राजनैतिक जीवन एवं जेल यात्रा
३. सन् १९३२-			कलकत्तेमें विद्यालयी शिक्षाका पुनः शुभारम्भ
४. १-१-१९३४ से १४-१०-१९३५-	भगवान्‌के नाम पत्र लिखना	
५. १२ अक्टूबर, १९३५-		संन्यास-ग्रहण	
६. अप्रैल, १९३६-		संन्यासी वेषमें इण्टरमीडिएटकी परीक्षा 
देकर विद्यालयी शिक्षासे विमुखता
७. अप्रैल से सितम्बर,१९३६ तक-	अज्ञात वास, घोर एकान्त साधना एवं अद्वैत तत्त्वकी दृष्टिसे परम सिद्धि, कोढ़ियोंके मध्य बैठना, स्वामी श्रीरामसुखदासजीसे मिलन एवं सत्संग
८. अक्टूबर, १९३६- 	श्रीसेठजीसे मिलन तथा उनके द्वारा बाबूजीसे मिलनेकी प्रेरणा
९. २७ अक्टूबर, १९३६-	गीतावाटिकामें सर्वप्रथम आगमन तथा बाबूजीसे प्रथम मिलन, बाबूजी द्वारा चरण स्पर्श एवं चरण-स्पर्शके माध्यमसे साकारोपासनाका बीजारोपण
१०. ३० अक्टूबर, १९३६-		गीतावाटिकामें इमली वृक्षके नीचे दिव्यानुभूति
११. नवम्बर, १९३६-	गोरखपुरमें राप्ती नदीके किनारे श्रीहनुमानगढ़ीमें वास करते हुए भगवान् श्रीकृष्णके दर्शन
१२. नवम्बर या दिसम्बर,१९३६- 	श्रीसेठजीके साथ रहना तथा लगभग अढ़ाई वर्षोंतक निरन्तर साथ रहकर श्रीमद्भगवद्गीताकी टीकाके लेखन कार्यमें सहयोग देना। 
१३. सन् १९३७- 	गीताप्रेसके एक कमरेमें बाबाके शरीरमें गोपी-वपुका अवतरण एवं तिरोभाव
१४. २६ या २७ या २८ अप्रैल,१९३९-	बाँकुड़ामें क्षेत्र संन्यासका संकल्प एवं भगवान् श्रीकृष्ण द्वारा क्षेत्र-संन्यासका नवीन अर्थ बतलाया जाना एवं बाबूजीके वपुको 'सचल वृन्दावन' बतलाना। 
१५. मई, १९३९- 			फखरपुर ग्राममें श्रीमातृ-चरणके अन्तिम दर्शन
१६. ११ मई, १९३९- 		बाबूजीके साथ नित्य रहनेका संकल्प
१७. जून या जुलाई या अगस्त,१९३९- 	बाबूजीका सूक्ष्म देहसे पधारकर बाबाको 'दीक्षा' देना
१८. सन् १९३९ या १९४० में- 	श्रीमञ्जुलीला-भावकी 'भाव-दीक्षा' (यह प्रथम भाव दीक्षा)
१९. २३ अगस्त, १९४१- 	दिल्लीमें प्रथम बार 'श्रीराधाष्टमी' अति सूक्ष्म  रूपसे मनाना
२०. सम्भवतः सन् १९४१-४२ में-	बाबूजीके संकेतपर प्रवचनका परित्याग एवं मौन व्रत
२१. सन् १९४२-४३ में- 	'केलिकुञ्ज' की लीलाओंका तथा 'प्रेम-सत्संग सुधा माला' का लेखन
२२. सन् १९४३-४४ में- 	श्रीमञ्जुश्यामा भावकी 'भाव दीक्षा' (यह द्वितीय भाव दीक्षा)
२३. सन् १९४४-४५ में- 		'राधा' नामके जपसे लगाव
२४. १९ सितम्बर, १९४५- 	गीतावाटिकामें प्रथम श्रीराधाष्टमी उत्सव; श्रीराधाष्टमीके दिन 'श्रीकाम-गायत्री मंत्र' से अर्चना
२५. सन् १९४६ से कई वर्षोंतक-	'श्रीकृष्णलीला-चिन्तन' 'जगज्जननी श्रीराधा' आदि-आदि अनेक भावपूर्ण कृतियोंका प्रणयन
२६. सन् १९४९-५० -  		बाबूजीकी आयु-वृद्धिके लिये देवाराधन
२७. २६ सितम्बर, १९५०- 	'देवर्षिपर श्रीवृषभानुनन्दिनीकी कृपा' नामक नाटिकापर अभिनय
२८. सम्भवतः सन् १९५० में- 	भगवान् श्रीकृष्ण द्वारा भगवती श्रीत्रिपुर-सुन्दरीकी अर्चना करनेके लिये निर्देश
२९. २० जनवरी, १९५१- 	गलेकी हड्डी टूटनेसे भगवती त्रिपुरसुन्दरीकी अर्चनामें विघ्न
३०. ९ मई, १९५१- 	भगवती त्रिपुरसुन्दरी द्वारा निज मंत्रका दान (यह तीसरी भाव दीक्षा)
३१. सन् १९५१ से १९५४ तक- 	अठारह पुराणोंका श्रवण
३२. २७ जनवरी,१९५६ से २६ अप्रैल,१९५६ तक- 	तीर्थयात्रा ट्रेन द्वारा तीन धामोंकी पावन यात्रा
३३. १९ अक्टूबर, १९५६- 		गीतावाटिकामें प्रथम काष्ठ-मौन व्रत
३४. ८-९ अप्रैल, १९५७-		'राधा भाव' में प्रतिष्ठा, (यह चौथी भावदीक्षा)
३५. १ सितम्बर, १९५७- 	रतनगढ़में विशिष्ट श्रीराधाष्टमी, 'रसोपासना' के दिव्य मंत्रोंका अलौकिक रीतिसे अवतरण
३६. जनवरी, १९५८- 	मथुरा स्थित बिड़ला धर्मशालामें ‘प्रियतम काव्य’ के लेखनकी प्रेरणा तथा काष्ठ मौनावधिमें प्रणयन
३७. सन् १९६३-६४ में- 		रासलीला द्वारा 'षोडश गीत' में प्राण प्रतिष्ठा
३८. १९ जनवरी, १९६४- 		भगवती श्रीविष्णुप्रियाजीका जन्मोत्सव मनाना
३९. २२ सितम्बर, १९६५- 	गीतावाटिकामें स्थापित श्रीगिरिराजजीकी परिक्रमाका शुभारम्भ
४०. ७ अप्रैल, १९६७- 		द्वितीय काष्ठ-मौन व्रत
४१. २२ मार्च, १९७१- 		बाबूजीका महाप्रयाण तथा कुटियाका परित्याग
४२. १६ फरवरी, १९७५- 	बाबाकी प्रेरणासे कैंसर अस्पतालकी स्थापनाका संकल्प
४३. २६ अगस्त, १९७६- 	बाबूजीकी समाधिपर बन रहे स्मारकके निर्माण कार्यकी पूर्णतापर हर्षोल्लास
४४. २० अगस्त, १९७७- 		लकवाका झटका
४५. ७ दिसम्बर, १९७८- 		तृतीय काष्ठ-मौन व्रत
४६. सन् १९८२ एवं सन् १९८४ में- दो अष्टयाम लीलाओंका आयोजन
४७.८ फरवरी,१९८५ से १७फरवरी,१९८५ तक-	बाबा द्वारा श्रीडोंगरेजी महाराजकी श्रीमद्भागवत कथाका श्रवण
४८. २१ जून, १९८५- 	श्रीराधाकृष्ण साधना मन्दिरमें प्राण-प्रतिष्ठाका विशद आयोजन
४९. ५ अक्टूबर, १९९१ से २३ सितम्बर, १९९२ तक- 	बाबूजीका जन्म-शताब्दी उत्सव सारे देशमें वर्षभर यत्र-तत्र मनाया गया
५०. २६ सितम्बर, १९९२- 	पूज्या मैयाका महाप्रयाण
५१. १३ अक्टूबर, १९९२- 	पूज्या मैयाके महाप्रयाणके उपरान्त श्राद्ध-कर्मकाण्डकी प्रक्रियाके सम्पन्न होते ही पूज्य बाबाकी महाप्रयाण लीला ॥ 

    राधा राधा राधा राधा''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'महाप्रभु श्रीपोद्दार महाराज') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''एक होता है रस-मार्ग और दूसरा ज्ञान-मार्ग। दोनों मार्गोंमें तत्त्वज्ञान अपेक्षित है। रस-मार्गका सिद्ध पुरुष तत्त्वज्ञानसे रहित नहीं होता और तत्त्वज्ञानीमें तत्त्वज्ञान रहता ही है, रस चाहे न हो।...... (बाबा) का काष्ठमौन केवल तत्त्वज्ञानमें स्थितिजनित पंचम भूमिकावाला नहीं, क्रियाके अभावके स्वरूपवाला नहीं, अपितु रस-समुद्रके लहरानेके स्वरूपवाला है। 
(बाबा) के जो अन्तरंग जीवनके सम्पर्कमें आये हैं, उनको मालूम है कि महाभावकी जो अगले स्तरकी चीज है, जिसकी रूप-रेखा शायद गोस्वामी प्रभृत रस-मर्मज्ञों तकने भी नहीं खींची, वैसी चीज इनमें व्यक्त हुई, इनके अनुभवमें आयी।...... इस  प्रकारसे  इनका  काष्ठ-मौन  असलमें  इनका रस-समुद्रमें  निमज्जन है। ...... साधनाके क्षेत्रमें यह एक बड़ी विलक्षण वस्तु है कि जहाँ रस-तत्त्व और ब्रह्म-तत्त्व एक-दूसरेके अ-प्रतिद्वन्द्वी होकर एक साथ एक रूपमें रहते हों। ये रहे हैं पहले। ऐसा नारदादिमें था। भगवान शंकराचार्यमें भी ऐसा माना जाता है, लेकिन ये उदाहरण विरल होते हैं।''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'परम पूज्य श्रीबालकृष्णदासजी महाराज') {
      return const _TopicPageContent(
        imagePaths: [],
        body: '''हरे  राम  हरे  राम  राम  राम  हरे  हरे।
हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ॥

सुनि  मेरो  वचन  छबीली  राधा, तैं  पायौ  रस सिंधु अगाधा॥ 
तू  वृषभानु  गोप  की  बेटी,  मोहन लाल रसिक  हँसि  भेंटी। 
जाहि  बिरंचि  उमापति  नाये, तापैं    तें   बन  फूल  बिनाये॥
जो रस नेति-नेति श्रुति भाख्यौ, ताको  अधर  सुधा रस चाख्यौ। 
तेरौ रूप कहत नहीं आवै,   हित  हरिवंश  कछुक  जस  गावै॥ 

श्रीराधारससुधासिन्धुसे आन्दोलित-आह्लादित श्रीराधाचरणनखमणि-चन्द्रच्छटासे आलोकित अलंकृत महाभावनिमग्न श्रीराधाबाबा क्या हैं, हमने इस क्षणतक पहचाना ही नहीं। आप वहीं हैं, यहाँ नहीं, किञ्चत् भी नहीं, कदापि नहीं। आपकी वचनारसामृतधारामें होनेपर प्रतिपग प्रतिक्षण मूर्तिमान माधुर्यरससिन्धुका मिलन-ही-मिलन है, नव-नव लीलारसानुभव है। कोई लालसापूर्ण सौभाग्यवान पुमान् ही आपके वचनसुधारसप्रवाहमें प्रवाहित होकर श्रीराधा-माधव-मिलन-महोत्सवमें सम्मिलित हो सकेगा। श्रीयमुनालहर-समलंकृत निकुञ्ज-मन्दिरमें विक्रीड़ित-विलसित श्रीराधारससुधोन्मत्तके चरण-कमलोंसे चिह्नित रम्य पथमें पूर्णानुगत होकर निज-मधुप-स्वरूपमें पुनः आनेके लिये मधुर संकेत है, उनकी साक्षात्-समीपताका अलभ्य लाभ है, चिरकालतक मधुरसुधारसावगाहन करनेमें मधुर समागम है।
'प्रियतम' मधुर नाम, बिना श्रीप्रियतमा राधासे मिले, एकाकी रहकर श्रवण कैसे कर सकते थे ? अपने प्रियतम-स्वरूपानुभव कैसे कर सकते थे ? असम्भव, असम्भव । (प्रियतम-प्रियतमा) कोई मधुर नाम लें, यही तो रहस्य संयुक्ततासे ओत-प्रोत आप्लावित है। प्रियतम-प्रसंगोंमें, प्रियतमा-प्रसंगोंमें, दोनोंमें एकको भी देखें तो लीला ही दीखेगी। अनुरंजितमें अनुरंजिता, अनुरंजितामें अनुरंजित । प्रेमका अपार अनुपमेय अवर्णनीय साम्राज्य है यह। संयुक्तताका ही होता है अनुभव श्रीप्रियतमकी चर्चामें। सम्यक् संयुक्ततानुभव कराते हैं प्रियतम । 'प्रियतम' यह मधुर नाम मूर्तिमान प्रियतम-प्रियतमा-परिमण्डित परस्पर-मिलित-रसानुभव है। दूरी व देरीकी कल्पनासे बेसुध करानेवाली, अविलम्ब समीप मिलनेवाली है रूपमाधुरीचर्चा लीलामाधुरीचर्चा।
युगान्तरों-जन्मान्तरोंके सुदीर्घकालीन अन्तरको भुलाकर चिर रुचिर चारुनिधि प्राणवल्लभ प्रियतम श्रीकृष्णसे हमें मिलने लालासान्वित करती हो, ऐसी है यह अद्वितीय रससुधावर्षिणी-वचनपुष्पमाला 'जय जय प्रियतम'। हमें भी महापुरुषोंकी वाणीमें, चरणचिह्नमें गमन करना है वहीं, जहाँ वे पहुँचनेका संकेत करते हैं। वही उन्मुख गमन करना है। हमें भी वाणीको लेकर वहीं रहना है।
''',
      );
    } else if (sectionId == 'topic2' && title == 'श्रीमती सावित्रीदेवी फोगला') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''बाबा जैसे शारदाके वरद पुत्रके अनुभूति ग्रन्थ प्रियतम काव्यको मैंने ही लिपिबद्ध किया था। भावोन्मादकी दशामें वे बोलते जाते और मैं लिखती रहती। अन्यान्य भावमयी लीलाएँ तथा पदोंकी संरचना भी पर्याप्त है, जिसे समझना मानवीय विद्या-कौशलके बूतेकी बात नहीं।
बाबाका यह सारा रचना-संसार उनके मौनावधिकी प्रत्यक्ष अनुभूतिका जगत है, उन्हीं दृश्योंको यथावत चित्रित किया है उन्होंने। परन्तु इस अपनी जीवन-धाराको आत्यन्तिक सुगुप्त रखना अभिप्रेत था बाबाको, और तदनुरूप ही आदेश था मुझे। पानी पिलाने जब मैं जाती थी, उस समय वस्त्रोंमें छिपाकर छोटी पतली सी कॉपी साथ ले जाती, और वापस वैसे ही छिपाए ले आती। वर्षों तक मेरे परिवारमें भी किसीको यह भनक तक न लगी कि पानी पीते-पिलाते समय कैसी अनिर्वचनीय रस-चर्चा चल रही है, और उसे पंक्तिबद्ध करवाकर विश्व-मनीषा एवं अध्यात्म जगतको कैसा अप्रतिम उपहार दे रहे हैं बाबा। प्रतिभाके धनी बाबाकी भाषा-शैली, उसकी रसमयता, प्रभावोत्पादकता सब अनूठी थी। एकबार उस दिशामें उन्मुख हो आरम्भ करते ही, भावोंका अप्रतिम प्रवाह चल पड़ता और शब्दोंके चित्र सामने आकर खड़े हो जाते। मन्त्रमुग्धसा पाठक अनायास डूबता चला जाता उसमें। मैं तो स्वयं यन्त्रवत लिखती चली जाती। कैसे, क्या, कौन लिखवाता था- मुझे कुछ ज्ञान नहीं। अनेक बार तो ऐसा भी हुआ जब मेरी और बाबाकी हस्तलिपि-छविलिपि-सी प्रतीत होने लगी। बाबा और मैं-हम दोनों ही भ्रमित हो जाते थे कि यह लिखावट किसकी है ? आनन्द और रसके आवर्तोंके मध्य सृजन होता रहता, इस रस-सृष्टिका।
उर्दू, हिन्दी, व्रजभाषा - तीनोंमें बाबाने रचनाकी, और प्रत्येक आलेख स्वयंमें पूर्णताको प्राप्त था… भावोंका कोश था। गद्यमें भी बाबाने पर्याप्त लीलाएँ लिखवाईं…. परन्तु उन्हे प्रकाशमें लाना बाबाको वांछनीय नहीं था। अतः सारी चीजें एक साथ प्रकाशमें नहीं आईं। अन्य परिपत्रोंके साथ, प्रियतम काव्यके चार शतकोंके आधारपर भी बाबाने राधासे परिपत्र लिखवाए। बाबाकी भाषाका प्रभाव राधाकी लेखनीमें स्पष्ट है। बाबाके भावोंको ग्रहण करनेकी क्षमता उसे प्रभुने प्रदान की थी और अनेक बार बाबा उसे कहा करते थे- “बिटिया, जब बछड़ा गायके थनोंमें मुँह लगाता है, तब पिन्हाकर गाय दूध देने लगती है - अनायास उसके थनोंसे दूधकी धारा बह चलती है। ठीक वैसी ही दशा मेरी है, तेरी ग्राहकताके कारण मैं स्वयं उसी भावमें बहने लगता हूँ और चल पड़ता है रसका प्रवाह ।”
''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'परम पूज्य श्रीसाधुकृष्ण प्रेम जी') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''इस श्रुतिरूपा काव्यके उद्गाता ऋषि थे पू.गुरुदेव श्रीराधाबाबा, और श्रोता थे उनके भी गुरुदेव महाप्रभु श्रीहनुमानप्रसादजी पोद्दार महाराज। यह ग्यारह सौ ग्यारह छन्दोंका ग्यारह शतकोंमे विभाजित काव्य लेखनीके माध्यमसे तो लिखा ही नहीं गया। यह तो मात्र अवतरित हुआ था - छन्दोंके स्वरूपमें पू. गुरुदेव श्रीराधाबाबाके अन्तःकरणमें और उनके द्वारा ही इसे सुनाया गया था श्रीमहाप्रभु पोद्दार महाराजको। हाँ, जब ब्रजेन्द्रनन्दन नीलमणिकी इच्छासे ही -

एक द्वार रखि  कुँअरि  ने  लीनी  पैठ  उठाय।
रुचै जो रंचक कीनु पिय, बहिनी, भैया, माय।।

कुँअरि राधाने अपने प्रीति-वितरणकी पैठ उठा ही ली, मात्र एक द्वार- अ. सौ. सावित्रीबाई फोगला (सुपुत्री महाप्रभु श्रीपोद्दार महाराज) को ही निर्धारित कर दिया। उस समय पू.गुरुदेव श्रीराधाबाबाने ही अपने सर्वथा अप्राकृत भावजीवनके इस काव्यको बोल-बोलकर पूज्या अ.सौ. बाई सावित्रीको यह 'रसश्रुति' प्रदान कर दी। कुछ कृपापात्रोंको, जिनमें एक लेखक भी रहा, पू.अ.सौ. सावित्रीबाईने ही यह श्रुतिग्रन्थ कृपापरवश प्रदान कर दिया। 
इसमें कहीं कोई संशय नहीं कि इस श्रुतिकाव्यके नायक नायिका प्रिया-प्रियतम ब्रजेन्द्रनन्दन नीलसुन्दर एवं वृषभानुनन्दिनी बाला राधा सर्वथा अप्राकृत हैं। इन प्रिया-प्रियतमके माता-पिता, पितामह, ताऊ-चाचा, भाई-बहिन, सखा एवं सखीगण, इनके पितृकुल, मातृकुल एवं श्वसुरालयके भी सभी पात्र, उनके देहादि मायाके कार्य, पञ्चमहाभूतोंमें निर्मित माया-आवरणरूप कदापि कदापि नहीं हैं। इस रसश्रुतिमें वर्णित लीलाएँ अप्राकृत हैं जो अप्राकृत क्षेत्र, वृन्दाकानन, श्रीसुन्दरीवनके निकुञ्जओं, एवं ब्रजके ग्रामोंमें घटित हुई हैं एवं निश्चय ही अप्राकृत मन-बुद्धि एवं शरीरधारी अप्राकृत चिन्मय पात्रोंकी लीलाएँ हैं। इसीलिये इस प्रियतम काव्यका शब्द-शब्द मंत्र है एवं इन मंत्रोंके जापसे निश्चय ही अप्राकृत मन-बुद्धिका निर्माण संभव है। यही इस ग्रन्थका अपूर्व माहात्म्य है।
सर्वप्रथम जब इस श्रुतिरचनाका प्रथम छन्द पू.गुरुदेव श्रीराधाबाबाके अन्तःकरणमें अवतरित हुआ एवं उन्हें यह भासित होने लगा मानो उनके प्रियतम श्रीकृष्ण उनसे उनके भावजीवनको काव्यरूपमें प्रकट कराना चाह रहे हैं, एवं यह रचना ग्यारह शतकोंमें क्रमशः प्रसूत हो रही है, उस समय पू.गुरुदेवने अपने प्रियतम ब्रजेन्द्रनन्दनसे यही विनय की थी कि 'जब भूतकालके अनेकों महासिद्ध रसिकाचार्योंकी अनेकों वाणियाँ वर्त्तमानमें उपलब्ध हैं एवं साहित्यके उत्कृष्टतम प्रयोगों द्वारा राधाकृष्णकथाके सभी पक्ष अष्टछापके सूरदास, नन्ददासादि तथा इतर कवियों द्वारा भी प्रचुरतासे, वर्णित किये जा चुके हैं, फिर मेरे-जैसे व्यक्तिसे यह पिष्ट-पेषण करानेकी आवश्यकता ही क्या है ? यदि पूर्वके इन सभी रसिकाचार्यों एवं कवियोंसे मेरी यह रचना कुछ अपूर्व सिद्ध हो, तब तो इसकी सार्थकता है, अन्यथा यह क्रिया चर्वितका चर्वण मात्र ही तो होगी ?'
पू.गुरुदेवके इस निवेदनके उत्तरमें प्रियतम श्रीकृष्णने मुसकाकर उनसे इतना ही कहा 'तू इसे प्रकट तो कर ! तेरे द्वारा प्रकट इस श्रुतिका माहात्म्य उन सभी कृतियोंसे अपूर्व ही होगा। इस घोर कलिकालमें विशुद्ध भागवती प्रीतिकी प्रतिष्ठाके लिये ये तेरे श्रुतिछन्द अप्राकृत नेत्र, कर्ण, वाणी, मन एवं अन्तःकरणके निर्माणमें निश्चय ही हेतु होंगे। यह श्रुति कालजयी सिद्ध होगी एवं भविष्यमें पच्चीस सौ वर्षों तक इसका प्रभाव स्थायी रहेगा।'
निश्चय ही इस लेखक द्वारा व्यक्त यह प्रसङ्ग किन्हीं महासिद्ध रसिकाचार्योंकी कृतियोंकी हेठी सिद्ध करनेके हेतुसे सर्वथा उल्लेख नहीं किया गया है, न ही यह किसी मतविशेषपर आक्षेप ही है। लेखकने अपने गुरुमुखसे जो भी वाणी सुनी है, हृदयङ्गम की है, उपरोक्त शब्द लेखककी अपनी ही व्यक्तिशः निष्ठा एवं श्रद्धाको अभिव्यक्त कर रहे हैं। लेखकका यह आग्रह सर्वथा नहीं है कि उसके द्वारा लिखी बातोंको पाठक मान ही लें। यह तो मात्र लेखकके स्वयंके विश्वासकी बात है और लेखकका तो निश्चय ही इस विश्वासमें ही कल्याण है। लेखक आग्रहपूर्वक अपना विश्वास दूसरोंपर लादनेके लिये उपरोक्त लेखन सर्वथा नहीं कर रहा।
लेखककी प्रार्थना है कि पाठकगण इस विषयमें तर्कबुद्धिका आश्रय करके उससे प्रश्नोत्तरकी आशा कृपया नहीं रक्खें। विवादमें तो अपनी हार वह पहले ही स्वीकार कर लेता है एवं तर्क करना सर्वथा ही नहीं चाहता। अवश्य ही पू.गुरुदेव श्रीराधाबाबा एवं महाप्रभु श्रीपोद्दार महाराजपर उसकी सर्वोपरि निष्ठा, विश्वास, श्रद्धा क्षण-क्षण बढ़ती रहे और उनकेद्वारा कथित प्रत्येक शब्द उसे साक्षात् परमात्माकी वाणी ही अनुभव हो, अन्तर्यामी प्रभुसे उसकी रोम-रोमसे यही विनीत प्रार्थना है।
स्कन्दपुराणमें उल्लेख है 'भगवान् शिव पार्वतीजीसे गुरुमहिमाके विषयमें कहते हैं 'गुरुवक्त्रस्थितं ब्रह्म प्राप्यते यत्प्रसादतः' अर्थात् 'हे पार्वति ! गुरुके द्वारा निःसृत वाणी ही परात्पर परब्रह्म परमात्मा है, और गुरुप्रसाद, गुरुकृपा ही उसकी प्राप्तिका एकमात्र कारण है। इस निष्ठाके प्रद्योतक ही मेरे उपरोक्त शब्द हैं।
यदि यह मेरी निष्ठा नहीं होती तो रसिकेन्द्रशेखर ब्रजेन्द्रनन्दन रसराज श्रीकृष्ण मुझ जैसे प्राकृत मन-बुद्धि वाले पामर प्राणीसे जिसने आवरणरूपा मायामें ही जन्मग्रहण किया है, कदापि इस चिन्मय भागवती श्रुतिग्रन्थकी टीका नहीं कराते। उन्होंने मुझ पशुको इस पावनतम कार्यमें हेतु बनाया, इसका यदि कोई प्रकट कारण हो सकता है, तो यही है कि न जाने किस पुण्यबलसे मेरी बुद्धि दिवस-प्रतिदिवस, क्षण-प्रतिक्षण इसी निष्ठाको ग्रहण कर रही है कि 'जो राधा हैं, वही, वही, वही मेरे श्रीराधाबाबा हैं। जैसे दूधमें सफेदी, अग्निमें दाहिका शक्ति, और पृथ्वीमें गन्ध रहती है, उसी प्रकार महाप्रभु श्रीपोद्दार महाराजमें परात्पर रसिकेन्द्रशेखर प्रियतम श्रीकृष्ण एवं मेरे पू. गुरुदेवमें श्रीराधारानी रही हैं। फिर ये दोनों सदा अभिन्न एकरस एवं एकात्म हैं। प्रेमरससार मेरे पू. गुरुदेवका अस्तित्व ही आनन्दरससार परम पूज्य पोद्दार महाराजमें संगुप्त रसिकशेखर-रसराजतत्वको उजागर करानेके लिये ही था, है एवं रहेगा।
मैं यह सत्य, सत्य, सत्य कह रहा हूँ कि मैं रसशास्त्रसे एवं रसतत्वसे सर्वथा अनभिज्ञ, नितान्त अज्ञ हूँ, घोर विषयी, पामर कोटिका प्राणी हूँ। इस दृष्टिसे पू.गुरुदेवकी इस अप्राकृत भावजीवनीकी व्याख्या करनेमें सर्वथा एवं सर्वदा अपात्र हूँ। इसे संस्पर्श करनेका भी मुझ जैसे अघी प्राणीका अधिकार नहीं है। मेरे पू.गुरुदेवकी भावजीवनीकी व्याख्या तो राधाभावद्युति-वलित-तनु श्रीकृष्णचन्द्र ही कर सकते हैं। वे कर सकते हैं और साथ-ही-साथ वे भी नहीं कर सकते, क्योंकि चिन्मय, अप्राकृत, महाभावरूप प्रिया राधाके चरित्रकी ऐसी ही अपूर्व शोभा है। इसकी व्याख्या स्वयं रसराज श्रीकृष्ण भी नहीं कर सकते। वे कर सकते होते तो मुझ जैसे सर्वथा अनधिकारीका इस कार्यके लिये वे चयन करते ही नहीं। कारण सुस्पष्ट है। राधा प्रीति-गुण-स्वभाव-स्मृति मात्रसे ही वे रसिकेन्द्रशेखर इतने विहल, मुग्ध तथा गद्गदकण्ठ हो जाते कि उनके द्वारा उनके प्रिया-चरित्रका व्याख्या-लेखन संभव ही नहीं होता। तभी न, उन्होंने मुझ-जैसे सृष्टिके सर्वाधिक वज्र-कठोर नीरस प्राणीका चयन किया। उन्होंने मुझमें एक ही पात्रता पाई। वह पात्रता यही थी कि महाप्रभु श्रीपोद्दार महाराज एवं पू.गुरुदेव श्रीराधाबाबाके दिव्यातिदिव्य पद-रजकण ही मेरे परम आश्रय थे। मैंने अपने मस्तकको शताधिक बार इस पद-रजकणसे परिस्नात किया था। मुझ निरालम्बके मात्र वे ही अवलम्ब थे, एवं हैं। मुझ पतितको महाप्रभु पोद्दार महाराजका वाचिक वरदान प्राप्त था कि 'कभी-कभी महज्जन-चरणाश्रयसे सर्वाधिक निकृष्ट जीव भी सर्वोत्कृष्ट कृपाभिव्यक्तिमें हेतु हो जाता है'। उन हेतुरहित कृपाघनकी महान् अनुग्रहवर्षा ही मुझ पतित पामर प्राणीसे यह कार्य निष्पादन करा गयी है।
मैं सत्य कह रहा हूँ कि इस श्रुतिकाव्यके मर्मका परिचय मुझे महाप्रभु पोद्दार महाराजकी कृपासे ही मिला। ऐसे अनेकों प्रसङ्ग आये जहाँ मैं कुछ भी नहीं समझ पाया, मेरे सम्मुख वे लीलाएँ प्रकट हुई जिनका सूत्ररूपमें मात्र सङ्केत ही पू.गुरुदेव राधाबाबा कर गये थे। मैंने इस व्याख्यामें एक-एक शब्द पूर्ण प्रामाणिकतासे लिखनेकी चेष्टा की है, क्योंकि यह मेरे सर्वाधिक प्रिय, पूज्य, जीवनसर्वस्व, जीवननिधि गुरुदेवका भावचरित्र था। मैंने इस ग्रन्थकी व्याख्यामें कहीं भी अपनी मनोप्रसूत कल्पनाका सहारा नहीं लिया है। यदि मैं मनोप्रसूत कल्पनाकी छायाका संस्पर्श भी इस व्याख्यामें करता तो यह प्रीतिका निर्मलतम सूर्य मेरे अन्धतम 'काम' से ग्रस्त हो जाता। मै इस व्याख्याका शब्द-शब्द लिखते समय इस भयसे सदैव आशङ्कित रहा हूँ कि कहीं भी मेरी कल्पनाकी कोई काचमणि इस हीरक-हारावलिमें नहीं विजड़ित हो जाय, अन्यथा यह रचना सच्चे रसमर्मज्ञ जौहरियोंके लिये समादरणीय नहीं होगी। निश्चय ही यह ग्रन्थ लीलाजगत्में नित्य स्थित रसिकाचार्य चैतन्य महाप्रभु, महाप्रभु श्रीवल्लभाचार्य, परम वन्दनीय स्वामी हरिदासाचार्य, महाप्रभु हितहरिवंश, भक्तप्रवर वन्दनीय रूप-सनातनादि गौडीय आचार्योंके दृष्टिपथमें भी आवेगा। वे इस व्याख्यापर भी निश्चय ही दृष्टिपात भी करेंगे। वे रसिकशिरोमणि महासिद्ध आचार्यवर्य कहीं मेरी व्याख्यामें किञ्चित् भी लौकिकावेशकी गन्ध पा जावेंगे तो मेरे गुरुदेव श्रीराधाबाबाके नामकी किरकिरी हो जावेगी, क्योंकि अन्ततः शिष्य तो मैं उनका ही हूँ।
अस्तु, इस आशङ्काको ध्यानमें रखते हुए इस महाभावश्रुतिकाव्यके किसी भी छन्दके अर्थप्रकाशपर जहाँ कहीं भी मेरी बुद्धि कुण्ठित हुई है तो मैंने महाप्रभु श्रीपोद्दार महाप्रभुकी चरणरेणुका ही आश्रय लिया है। उन हेतुरहित कृपा-वरदानीकी चरणरेणुने मुझे कहीं भी निराश नहीं किया है। इस ग्रन्थके कूट-से-कूट स्थलोंके मर्मका प्रकाश तत्क्षण ही मेरे सम्मुख इस सरलतासे हुआ है कि मैं धन्य-धन्य कर उठा हूँ।
महाप्रभु श्रीपोद्दार महाराज तो व्यक्ति थे ही कहाँ ?

त्रिगुणरचित यह देह, महाभावमय करि रह्यौ।
ऐसो  किरपा-मेह   बरसायौ  पिय  साँवरौ ।।
        (पू. गुरुदेव श्रीराधाबाबा रचित सोरठा)

उनका त्रिगुणरचित देह रहा ही कहाँ था? वह तो कबका ही लहराते, नित्योच्छलित, महाभावसिन्धुकी ऊर्मि बन गया था ! तभी न,	

छाँड्यौ अपनौ नेम,  सभी मोर  साँचौ कयौं।
करै जोग अरु छेम, पिय सौ भयौ न होहिहै।।
        (पू. गुरुदेव श्रीराधाबाबा रचित सोरठा)

मेरे पू.गुरुदेव श्रीराधाबाबाके हृदयेश्वर, प्राणाराम, प्राणाधिक, प्रियतम ब्रजेन्द्रनन्दनका स्वभाव ऐसा ही है। वे अपना न्याय-नियम त्याग देते हैं और अपने आश्रित जनोंके मनोरथको सच्चा बनाकर पूर्ण कर देते हैं। उन मेरे प्रियतम जैसा योग-क्षेमका निर्वाह करनेवाला अन्य कोई हुआ है, न होगा ही।
उन मेरे प्रियतम श्रीकृष्णकी मेरे गुरुदेव श्रीराधाबाबापर अनन्त असीम प्रीतिको परखते हुए ही मेरा पूर्ण विश्वास है कि पू.गुरुदेवके भावजीवनके इस श्रुतिग्रन्थका जो भी पाठक भाव एवं श्रद्धासहित अवगाहन करेंगे, वे निश्चय ही महाभावस्वरूप प्रेमजगतमें प्रवेश पावेंगे।
यह निश्चय है कि मैं एक प्रेमशून्य जन्तु हूँ। ऐसे कृपावाक्य कहने-लिखनेकी मेरी सामर्थ्य सर्वथा नहीं है। किन्तु मेरे गुरुदेवपर उनके प्रियतम प्राणनाथकी प्रीति देखकर ही मैं महाप्रभु पोद्दार महाराजकी चरणरजको साक्षी बनाकर कहता हूँ कि मेरी वाणी अक्षरशः अखण्ड सत्य सिद्ध होगी।
पू.गुरुदेव श्रीराधाबाबा स्वयं और उनका यह लीलाचरित्र दो वस्तुएँ तो हैं ही नहीं। जहाँ पू.गुरुदेवके प्रियतम श्रीकृष्णका नाम, रूप, लीला, एवं धाम चारों वस्तुएँ पूर्ण परात्पर प्रियतम श्रीकृष्णस्वरूप ही हैं तो प्रियतम-प्रिया श्रीराधाका चरित्र प्रिया श्रीराधासे भिन्न कैसे संभव है? अतः मैं पू.गुरुदेव श्रीराधाबाबा रचित निम्न छन्दोंका आश्रय लेकर ही ऐसी मङ्गलमयी वाणीका उच्चारण कर रहा हूँ-

(दोहा) 
   मो इच्छित  कै  कृस्न पिय,  रुचै  बनिउ,  बनराउ।
   होइ  निराविल  सर्वथा   भाव-उदधि  बुड़ि जाउ ।।१।।
   बिस्वरूप जसुमति-सुअन ! अब विलम्ब जनि लाउ।
   होइ निराविल एहि छिन भाव-उदधि  बुड़ि  जाउ ।।२।।
   बिस्वरूप  बिनती   धरत   अभिनौ  सुख  बिसराउ।
   करौ  अनुग्रह  अब  महाभाव-उदधि  बुड़ि  जाउ ।।३।।
   बिस्वरूप   पिय   बेनुधर,   साँवर   बिरद  बढ़ाउ ।
   करौ  तुरन्त  कृपा  महाभाव-उदधि  बुड़ि   जाउ ।।४।।


(सोरठा)
    मो सुख लगि तुम पीउ, अब लौं कहा नहीं कस्यौ।
    तुम्हरौ  प्यार  असीउँ,   नित्य   अतुल  ऐसोइ  है।।५।।
    देख्यौ   अद्भुत    खेल,   इन   माटी-पुतरीन  कौ।
    अब  तुरन्त  दो  ठेल,  सबननि  ब्रज-रस-सिन्धुमें ।। ६ ।।

(छन्द)
हे महामहिम !  हे ब्रजनन्दन !  करुणावरुणालय !  हे प्रियतम !
हे कृष्ण ! प्राणवल्लभ ! साँवर ! मुझ राधाके रसिया ! प्रियतम !
हे वंशीधर ! मुझ राधाके  सुखमें ही  बस,  सुखिया ! प्रियतम !
हे    प्राणेश्वर   !  मुझ  राधाकी  नैयाके   खेवैया !   प्रियतम !

अब  ढरौ  तुरन्त  प्रथम  अपने  इन  दस रूपोंपर,  हे प्रियतम !
फिर  ढरौ  तुरन्त  विश्वमय  निज मद्दृश्य  रूपपर,   हे प्रियतम !
सर्वथा सुखी तुम हो जाओ,  खिल  उठो  फूल-से,  हे प्रियतम !
पल-पल  बढ़ते  ही  चलो  भावसागरकी  ओर  तथा, प्रियतम !

जो दोष  न  देखे  कहीं,  कभी,  ऐसे  हो  एक तुम्हीं, प्रियतम !
अतएव   तुम्हारी   प्यारी   मुझ   राधाकी  बिनती  है, प्रियतम !
यद्यपि  आवश्यकता  तुमसे  कहनेकी  थी  न  किन्तु,  प्रियतम !
कह गयी  और कर  गयी,  हुई  प्रेरित  तुमसे  बिनती, प्रियतम !


कहनेवाली,   सुननेवाले    दोनों   तुम   ही  तो  हो,  प्रियतम !
यह  खेल   तुम्हारा   नित्य  सरस   एवं  रहस्यमय है, प्रियतम !
है  लहराता  ही   रहता  वह,  संविद-स्वरूप  सागर,  प्रियतम !
उन लहरोंका ही नाम  यहाँ  संस्थान,  सृजन,  लय है, प्रियतम !

प्रियतम श्रीकृष्णका उत्तर—
है  सदा तुम्हारा ही सुख बस,  मेरा  तो सुख प्रियतमे ! अहो !
मैं   कर   दूँगा  अवश्य  पूरी  प्रत्येक   चाह,  निश्चिन्त  रहो !
हम सभी अभिन्न निरन्तर हैं, फिर भी जो रुचि हो, तुरत कहो।
हे  महाभावमयि  !  हमें लिये, रस-सुधा-सिन्धुमें  नित्य बहो।। 

(भावार्थ)

हे प्रियतम ! श्रीकृष्ण ! यदि आपको रुचिकर लगता हो तो मेरी इच्छाके अनुसार रूप धारण कर लीजिये। हे बनराइ (वृन्दावनके राजा), आप संसारगत मायावेश त्यागकर सर्वथा निराविल (निष्कल्मष) होकर भावसमुद्र प्रेमोदधिमें डूब जाइये ।।।१।।
हे विश्वरूप यशुमतिनन्दन ! अब विलम्ब मत करिये। इसी क्षण समग्र कल्मषरहित होकर भावसमुद्र प्रीतिसिन्धुमें डूब जाइये ।। २ ।।
हे विश्वरूप धारण किये मेरे स्वामी! मेरी प्रार्थनाको अपने चित्तमें धारण कर लीजिये। अब इन्द्रियजन्य नये-नये विषयोंमें सुखाशा छोड़ दीजिये। अब अपनी प्रिया मुझ आपकी आत्मापर अनुग्रह करिये एवं प्रीतिके सर्वोच्च सर्वशुद्ध महाभाव समुद्रमें डूब जाइये।।३।।
हे विश्वरूप धारणकिये वेणुधर श्यामसुन्दर ! अपने यशकी अभिवृद्धि करिये एवं मुझ अपनी आत्मापर तुरन्त कृपा करके महाभाव-समुद्रमें डूब जाइये।।४।।
हे प्राणनाथ ! आपने मेरे सुखके लिये अबतक क्या नहीं किया ? आपका प्रेम असीम अनन्त है। वह ऐसा है कि उसकी तुलना कहीं किसीसे हो ही नहीं सकती।। ५ ।।
मैंने इन पञ्चभूतरचित देहोंको धारण करनेवाली मृत्तिकामयी पुतलियोंका अद्भुत खेल खूब देख लिया। अब. तो इन सभी पुतलियोंको आप ब्रज-रस-सिन्धुमें ठेल दीजिये ।।६।।
हे महामहिम ब्रजनन्दन ! हे करुणावरुणालय ! हे कृष्ण ! हे प्राणवल्लभ साँवरे ! हे मुझ राधाके रसिया ! हे वंशीधर ! हे मुझ राधाके सुखमें ही सुखिया ! हे जीवनधन ! हे प्राणाधिक! हे प्राणेश्वर ! हे मुझ राधाकी नैयाके खेवैया ! हे प्रियतम ! सर्वप्रथम आप तुरन्त ही आपके इस दस नामरूप धारण किये स्वरूपोंपर (पू.गुरुदेवके दस प्रमुख कृपापात्रोंपर) अनुग्रहीत होओ एवं तब अविलम्ब अपने विश्वमय मेरे दृश्य बने रूपोंपर कृपालु हो जाओ। हे प्रियतम ! तुम सर्वथा सुखी हो जाओ एवं फूलकी तरह प्रफुल्लित होकर खिल उठो ।। ७ ।।
हे प्रियतम ! तुम प्रतिपल प्रेमके सर्वोच्च भावसमुद्रकी ओर बढ़ते ही जाओ। जो किसीका कभी दोष नहीं देखे ऐसे एकमात्र तुम्हीं हो। इसीलिये तुम्हारी प्यारी मुझ राधाकी तुमसे विनय है। हे प्रियतम ! सर्वान्तर्यामी होनेके नाते तुमसे अपनी प्रार्थना मौखिक कहनेकी यद्यपि कोई आवश्यकता नहीं थी, किन्तु फिर भी मैं तुम्हारे द्वारा ही प्रेरित हुई तुम्हें सबकुछ मौखिक कह गयी एवं प्रार्थना भी कर ही गयी। मैं यह बात भली प्रकार जानती थी कि प्रार्थना करनेवाली भी तुम ही बने हो, और सुननेवाले तो तुम हो ही। प्रियतम! अपने आपसे, अपने आपमें ही यह खेल नित्य सरस एवं रहस्यमय है। रहस्यमय इस अंशमें कि इसके भीतरका मार्मिक सत्य कोई जान नहीं पाता, वह सदैव अज्ञात ही रहता है; एवं सरस इस रूपमें कि दुखरूप क्षणभंगुर रहते हुए भी इसमें सुखाशा बनी ही रहती है। यह संविद् रूप समुद्र (चेतन-जीवमय संसार) लहराता ही रहता है। इस समुद्रकी लहरोंका ही नाम सृजन, स्थिति, एवं प्रलय है।

प्रियतम श्रीकृष्णका पू. गुरुदेवको उत्तर-
अहो प्रियतमे राधे ! सदैव तुम्हारा ही सुख बस, मेरा सुख है। मैं तुम्हारी प्रत्येक इच्छा अवश्य पूरी कर दूँगा, तुम निश्चिन्त रहो। तुम, मैं, एवं यह सृजन, स्थिति एवं प्रलयरूप जीव-समुदाय सभी परस्पर अभिन्न हैं। फिर भी जो तुम्हारी रुचि हो, तुम तुरन्त कहो। हे महाभावमयि ! तुम मुझे एवं मेरे अभिन्न स्वरूप सृष्टि, स्थिति, प्रलयरूप इस तुम्हारे दृश्यरूप विश्वको साथ लिये रस-सुधा सिन्धुमें नित्य बहती रहो।
-------
पू.गुरुदेव द्वारा अपने प्रियतम प्राणनाथ ब्रजेन्द्रनन्दन श्रीकृष्णसे की हुई उपरोक्त प्रार्थना एवं उनके सर्वभवनसमर्थ, कर्तुमकर्तुमन्यथाकर्तुम् समर्थ प्रियतम श्रीकृष्ण द्वारा उन्हें दियेगये उत्तरके आधारको लेकर ही पू. गुरुदेवके स्वरमें अपना निर्बल निरीह स्वर मिलाते हुए मैं सर्वथा अपात्र निम्न मङ्गलवचन कह रहा हूँ-
'पू.गुरुदेव श्रीराधाबाबाके भावजीवनके इस श्रुतिकाव्यमें जो भी पाठक भावसहित अवगाहन, निमज्जन करेंगे, वे एक ऐसे अनिर्वचनीय परम दुर्लभ विलक्षण चिदानन्दमय महारसकी उपलब्धि करेंगे, जो उनके समग्र विषय-व्यामोहको सदाके लिये मिटा देगा। मेरे पू.गुरुदेव श्रीराधाबाबाके भावजीवन इस प्रियतमकाव्यके पठनका यही माहात्म्य है। इसका अक्षर-अक्षर, इसके पूर्ण विराम, अर्ध विराम, अनुस्वार, चन्द्रविन्दुतक पूर्ण रसमय हैं। इसमें निरन्तर डूबनेवालेको दुर्लभ-से-दुर्लभ दिव्य देवभोगोंके आनन्दसे ही नहीं, परम तथा चरम वाञ्छनीय ब्रह्मानन्दसे भी अरुचि हो जायगी। श्रीप्रिया-प्रियतम ही उसके सर्वस्व होकर उसमें बस जावेंगे और उसको अपना स्वेच्छाचालित लीलायंत्र बनाकर धन्य कर देंगे।'
'नाथ ! हृदयेश्वर ! प्राणाराम ! प्राणाधिक! जीवनसर्वस्व ! नयनानन्द ! रसमय ! करुणामय! भावमय ! लीलामय ! प्राणाधार ! प्रियतम! श्रीकृष्ण ! सर्वथा अदोषदर्शी प्रियतम ! अनन्त कल्याणमय, स्वरूपभूत गुणगणशाली ! विश्वरूप विश्वेश्वर ! अखिलात्मन् ! सर्वज्ञ-सर्वविद् ! सर्वभवनसमर्थ ! अनन्तैश्वर्यनिकेतन ! सर्वलोकमहेश्वर ! करुणावरुणालय ! मेरे गुरुदेवकी रुचिका ही अनुसरण करनेवाले ! मेरे देवता! मेरे गुरुदेवकी रुचिको ही सर्वथा सर्वांशमें ही पवित्रतम ढंगसे, सर्वथा सर्वांशमें ही पवित्रतम ढंगसे, सर्वथा सर्वांशमें ही पवित्रतम ढंगसे, शीघ्र-से-शीघ्र, शीघ्र-से-शीघ्र, शीघ्र-से-शीघ्र पूर्णकरके उसे तत्क्षण अनन्त अपरिसीम परम मङ्गलमें, श्रीमहाप्रभु पोद्दार महाराजके और मेरे पू.गुरुदेवके महाभावके स्वरूप-विलास-समुद्रकी परम रमणीय ऊर्मिमें पर्यवसित करदेनेवाले मेरे नीलपद्म, प्राणप्रियतम श्रीकृष्ण ! प्राणधन ! प्राणरमण ! सर्वस्व! प्राणमूल प्रियतम श्रीकृष्ण! मेरे प्राणोंके परमाराध्य देव ! अखिल रसामृतमूर्ति प्रियतम श्रीकृष्ण ! अपना स्वेच्छाचालित लीलायंत्र बनाकर, अपनी चरणधूलिकी कृपाका वरदान देकर आपने इस पतितसे जो लिखाया, सब आपको ही समर्पित है।'
'आत्मस्वरूपिणि ! महाभावरूपिणि । जगज्जननीरूपिणि ! योगमायारूपिणि । जाग्रत्-स्वप्न-सुषुप्ति-भावापन्ने ! तूर्यतात्मिके ! यमुना-गङ्गा-सरस्वतीरूपिणि । ऋद्धि-सिद्धि-महासरस्वती-महालक्ष्मीरूपिणि ! आवयोः शिव-पार्वती-लीलायां शिवरूपिणि ! पुनश्च उमारूपिणि ! नवदुर्गारूपिणि । दशविद्यारूपे ! भगवति । श्रीमन्महात्रिपुरसुन्दरीरूपिणि ! क इति मंत्रसुलभे ! श्रीमातृरूपे ! ललितादि-परिकर-रूपिणि! मञ्जश्यामारूपं प्रत्यपि अपरिसीमानुराग भावयति ! मञ्जश्यामायां छायायां प्रत्यपि मच्छायायां प्रति च मच्छायायां छायायां प्रति च अपरिसीमानुराग-भाव-विधायिनि ! अनन्ताभिव्यक्त-नाभिव्यक्त शक्तिस्वरूपिणि ! सर्वस्वरूपे ! सर्व रूपे ! सर्वातीते ! नित्यानिर्वचनीयाचिन्त्य-विरुद्धधर्माश्रयत्वं विभूषिते ! राधे ! तव नित्यप्रियतमः नित्यप्राणाधिकः नित्यप्राणेश्वरः नित्यप्राणवल्लभः, नित्यनवनिकुञ्जेश्वरः नित्यवृन्दावनेश्वरः नित्यब्रजेन्द्रनन्दनः अहं श्रीकृष्ण एव तवात्मानं मन्नित्यप्रियतमा नित्यप्राणाधिका नित्यप्राणेश्वरी नित्यप्राणवल्लभा नित्यनवनिकुञ्जेश्वरी नित्यवृन्दावनेश्वरी नित्यवृषभानुपुत्री त्वं राधैव ममात्मा नित्यलीलार्थ भिन्नतया स्थितः सन् तवाङ्गस्य प्रत्येके कणे हि महाभावात्मकाह्लादरूपेण नित्यं वर्त्तमानः तव हृदयाकाशे तु बहिश्च निखिले रोमकूपे च यथानुभूतरीत्या त्वदभिलषिताभिव्यक्त नवनीरदवर्ण द्विभुजानन्तैश्वर्यनिकेतन सर्वलोकमहेश्वर स्वयंभगवत्प्रकाश पुरुषोत्तम प्रियतम प्राणाधिक प्राणेश्वर प्राणवल्लभ नित्यनवनिकुञ्जेश्वर नित्यवृन्दावनेश्वर नित्यब्रजेन्द्रनन्दनरूपेण मम प्रियतम ! प्रिया-प्रियतम युगल ! मेरे सम्मुख यहाँ मेरे हृदयमें सतत सम्प्रतिष्ठित हों एवं मेरी इस टीकापर अपना वरद अनुग्रह-हस्त रखकर इसे अनन्तकालतक, स्वइच्छित कालतक अपने एवं अपनी प्रियाके विशुद्ध प्रेम-वितरणके योग्य सिद्ध करें। एवमस्तु, इत्यलम् । 
''',
      );
    } else if (sectionId == 'topic2' && title == 'पूज्य श्रीराधेश्याम बंका') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            ''''जय जय प्रियतम' काव्यकी रचनाकी स्फुरणा महाभावनिमग्न प्रीतिरसावतार परमपूज्य श्रीराधाबाबाको सर्व प्रथम व्रज-भूमिमें हुई। बाबाने काष्ठमौन व्रत १९५६ के अक्टूबर मासमें लिया था। इसके एक मास बाद नवम्बरमें बाबा और बाबूजी (श्रद्धेय श्रीहनुमानप्रसादजी पोद्दार) रतनगढ़ (राजस्थान) चले आये थे। नवम्बर १९५६ से अप्रैल १९५८ तक बाबा और बाबूजी रतनगढ़में रहे। इसी १९५८ के जनवरी मासमें बाबा और बाबूजी रतनगढ़से व्रजभूमि गये थे श्रीगिरिराज भगवानकी परिक्रमा लगानेके लिये। साथमें भक्तोंका भी समुदाय था, जो भिन्न-भिन्न स्थानोंसे परिक्रमा हेतु वहाँ आ गया था। सभीके ठहरनेका प्रबन्ध किया गया था बिड़ला-मन्दिरमें, जो वृन्दावन और मथुराके मध्यमें स्थित है। इन दिनों बाबाका अति कठोर काष्ठ-मौन-व्रत चल रहा था, अतः इसी बिड़ला मन्दिरके एक कमरेमें बाबाके नितान्त एकान्त आवासकी व्यवस्था की गयी थी।
एक बार बाबा इस बिड़ला मन्दिरके एक खुले स्थानमें श्रीधाम वृन्दावनकी ओर मुख कर बैठे हुए थे। तभी अचानक नेत्रोंसे अश्रुका प्रवाह बह चला, साधारण नहीं, अनर्गल प्रवाह। कोई हेतु नहीं, फिर भी अनर्गल अश्रु-प्रवाह बाबाके कपोंलोंको रह-रह करके संसिक्त कर रहा था। उसी समय बाबाने एक मयूरको नृत्य करते हुए देखा। इससे और अधिक भावोद्दीपन हुआ। फिर भावोंका वेग इतना अधिक बढ़ चला कि समक्ष वृन्दावन और व्रजभूमिका दिखलायी देना बन्द हो गया। स्थूल वृन्दावन तिरोहित हो गया और बाबाके दृष्टि-पथपर अवतरित हो उठा दिव्य चिन्मय वृन्दावन, केवल दिव्य चिन्मय वृन्दावन ही नहीं, अपितु वहाँकी दिव्य रसीली लीलाकी अद्भुत-अभिनव अवली। तभी लीलाके प्रसंग और भाव, काव्यके छन्दोंमें ढलने लग गये।
इन छन्दोंकी रचनामें कोई क्रम नहीं थी, पर उस क्रमबद्धताके अभावोंमें  से एक अद्भुत भवितव्यकी सम्भावना उभरकर सामने उपस्थित हो गयी। ऐसा लगता है कि इस अद्भुत भवितव्यको बाबाके समक्ष प्रस्तुत करनेके लिये किसी अचिन्त्य विधानसे छन्दोंकी रचनामें क्रमबद्धताका समावेश नहीं हो पाया। इस समय जिस प्रकारसे पंक्तियोंकी रचना हुई, उससे बाबाको अनुमान हो गया कि जिस काव्यकी भविष्यमें रचना होनेवाली है, उसके कुल ग्यारह शतक होंगे। प्रथम शतककी आठ पंक्तियाँ, द्वितीय शतककी चार अथवा आठ अथवा सोलह पंक्तियाँ, इस प्रकार प्रत्येक शतककी चार अथवा आठ अथवा सोलह पंक्तियोंकी रचना हो गयी। ग्यारह शतकोंकी आरम्भिक पंक्तियोंकी रचना उसी बिड़ला मन्दिरमें तत्काल हो गयी। क्रमकी विश्रृंखलताने ही संकेत दे दिया कि कुल ग्यारह शतकोंकी रचना होगी।
ज्यों ही महाभाव-भावित बाबाको यह आभास हुआ कि ग्यारह शतकोंवाले किसी भावी काव्यकी रचनाके ये पूर्व-संकेत हैं, त्यों ही उन्होंने प्रियतम श्रीकृष्णसे किंचित् उपालम्भ-मिश्रित स्वरमें कहा- जो अबतक अनेक भक्त कवियों द्वारा लिखा जा चुका है, वही सब मेरे द्वारा पुनः लिखवानेसे क्या लाभ ?
बाबा तो श्रीराधा-भावमें थे। बड़े प्यार भरे शब्दोंमें परम ऐकान्तिक सम्बोधन करते हुए प्रियतम श्रीकृष्णने कहा- प्राणेश्वरि ! तुम रचना करो तो सही।
बाबाने पुनः उसी स्वरमें कहा- वह रचना पिष्टपेषण मात्र ही तो होगी। मुझसे व्यर्थमें श्रम क्यों करवा रहे हो? यदि रचना करवानी ही हो तो कुछ ऐसी करवाओ, जो आजतक हुई ही नहीं हो। वह एक नवीन रचना हो।
अपने अनुरोधमें और अधिक माधुर्य घोलते हुए प्रियतम श्रीकृष्णने कहा-प्राणाधिके ! तुम्हारी भावनाके अनुरूप ही रचना होगी।
प्राणाधिक प्रियतम श्रीकृष्णने जब बाबाकी भावनाका अनुमोदन कर दिया, तब और कुछ कहनेके लिये रह ही क्या गया था। बाबाके उस काष्ठमौनकी अवधिमें काव्यका सृजन आरम्भ हो गया। मौनव्रतकी कठोरताके कारण कागज-कलम माँगा जाना सम्भव नहीं था और जो-जो दिव्य लीलाएँ दृष्टि-पथपर आतीं, उनकी अभिव्यक्तिके क्रमका शुभारम्भ बिड़ला-मन्दिरसे ही हो चुका था अतः कई वर्षोंतक यह काव्य बाबाकी स्मृतिमें सुरक्षित रहा। जब यह व्रत शिथिल हुआ, तब बाबाने इसे आदरणीया बाई (श्रीसावित्री बाई फोगला) को लिखवाया। बाबा बोलते जाते थे तथा बाई लिखती जाती थी। इस लेखन कार्यमें बाईके अतिरिक्त पूज्य बाबूजीने भी सहयोग दिया। मौनव्रतके शिथिल होनेपर भी काव्य-सृजनमें विराम तो आया नहीं। अन्य प्रकारके काव्यकी रचनाका क्रम चलता रहा। यह आवश्यक नहीं कि जिस समय काव्य-रचना हो रही हो, उस समय बाई अथवा बाबूजी उपस्थित रहें। अनेकों पंक्तियोंकी रचना हो जाती और जब बाई आती, तब फिर बाबा बाईको लिखनेके लिये कहते। इससे अनेक बार ऐसा भी हुआ है कि उन विविध काव्योंकी रचित पंक्तियाँ विस्मृत हो जाती और जो विस्मृत हो गयीं, वे सदाके लिये विलुप्त हो गयीं।
ग्यारह शतकों वाला यह काव्य कहलाया 'जय जय प्रियतम'। इस काव्यकी प्रत्येक पंक्तिके अन्तमें 'प्रियतम' शब्द सम्बोधनात्मक शब्द है। प्रत्येक पंक्तिमें यह सम्बोधन इसलिये है कि अपने प्रियतमको सुनाते हुए ही प्रत्येक पंक्तिकी रचना प्राणप्रिया द्वारा हो रही है। यह काव्य आद्यन्त तुकान्त नहीं है। रचनाके प्रवाहमें तुक बैठ गयी तो उत्तम, अन्यथा तुक बैठानेका आग्रह मनमें नहीं था। रचित काव्यमें न तो संशोधन करना था और न परिवर्तन। पंक्तियोंमें जो भाव ढल गये और जिस प्रकारसे ढल गये, वही स्वीकार्य था। हाँ, एक स्थानपर एक परिवर्तन बाबाने नहीं किया, अपितु बाबासे प्रियतम श्रीकृष्णने करवाया। जब काव्य-रचना होती थी तो बाबाके सामने उपस्थित रहते थे प्रियतम श्रीकृष्ण। प्रथम शतकके आरम्भमें एक स्थानपर एक पंक्ति आयी है 'गोबर मिट्टीसे यद्यपि थी अवनी लीपी पोती, प्रियतम'। पहले 'गोबर' शब्द नहीं था। बाबाने रचना करते समय प्रयोग किया था 'गैरिक' शब्द। प्रियतम श्रीकृष्णने कहा- 'गैरिक' शब्दका प्रयोग मत करो।
प्रियतम श्रीकृष्णका ऐसा संकेत मिलते ही बाबाने शब्दका परिवर्तन कर दिया और 'गैरिक' शब्दके स्थानपर 'गोबर' शब्दका प्रयोग किया।
इसी प्रकार एक बार एक चरणकी पूर्ति स्वयं प्रियतम श्रीकृष्णने की। बाबाके द्वारा छन्दके तीन चरणोंकी रचना हो गयी, पर चौथा चरण उभरकर सामने नहीं आया. जब पर्याप्त विलम्ब होने लगा तो चौथे चरणको पूर्ण करते हुए प्रियतम श्रीकृष्णने कहा- "प्राणोंका सौदा होता है क्षणमें कुछ ऐसे ही, प्रियतम"।
प्रियतम-काव्यके चौथे शतकमें यह चरण-पूर्ति है। एक बाबा बाबाने बतलाया था-यह पंक्ति कोई साधारण वाक्य नहीं है, अपितु मन्त्र है।
'जय जय प्रियतम' काव्यकी रचनाके क्रममें श्रृंखला-बद्धताका अभाव रहा। कभी किसी शतककी रचना हुई और कभी किसी शतककी। काव्यकी वर्ण्य-वस्तुकी समग्रता तो ध्यानमें आ चुकी थी और पूर्वापरकी दृष्टिसे ग्यारहों शतकोंके क्रमका निश्चय भी तभी हो गया था, जब बिड़ला मन्दिरमें 'जय जय प्रियतम' काव्यकी पंक्तियोंका सर्व प्रथम स्फुरण हुआ था, परंतु ऐसा नहीं रहा कि आरम्भसे अन्ततक ग्यारहों शतकोंकी रचना, एकके बाद दूसरे और दूसरेके बाद तीसरे शतककी, इस प्रकार सभी शतकोंकी रचना क्रमशः होती चली गयी हो। कभी पहले शतककी रचना हो रही है तो कभी सातवें शतककी। इसका हेतु यही था कि जब जिस दिव्य लीलामें मन निमग्न होता, उसीकी रचनाका प्रवाह बह चलता। बाबाके निजी परिकर श्रीभगतजीने बतलाया-बाबा कलम-दवात-कागज लेकर थोड़े ही बैठते थे। अपनी कुटियाके एकान्तमें बैठे हुए गुनगुनाते रहते। ऐसा लगता था मानो कोई प्रेरित करता चला जा रहा है और वे भाव शब्दोंमें ढलते चले जा रहे हैं। जब बाई अथवा पूज्य बाबूजी आते तो बाबा बोलते जाते और वे लिखते जाते। कई बार ऐसा भी हुआ है कि बाई लिखनेके लिये कलम-कापी लेकर बैठी है, पर बाबा भावपूर्ण लीलाको देखकर 'भए प्रेम बस बिकल बिसेषी' और विह्वलाधिक्यके कारण वे लिखवानेकी स्थितिमें नहीं है। इधर बाबा अत्यधिक लीला-निमग्न हैं और उधर बाई अत्यधिक प्रतीक्षा-निमग्न प्रतीक्षा करते-करते बाईको कभी-कभी एक-डेढ़ घंटेतक बैठे रहना पड़ा और कभी-कभी परिस्थिति यहाँतक आती कि इससे भी लम्बी बैठकके बाद लिखने-लिखवानेके क्रमका उपक्रम बन ही नहीं पाता था। लीला-निमग्नताकी गहराईमें बाबाको देखकर बाई लेखन-कार्य अगले दिनके लिये स्थगित कर देती।
बाबाके काव्यमें वृषभानुननिन्दनी श्रीराधाका जो स्वरूप उभरकर सामने आया है, वह वस्तुतः अभूतपूर्व और अनूठा है। रसका सागर तो अनन्त और अगाध है और उसमें अनेक लहरें उठती रहती हैं। इन लहरोंकी संख्या अगण्य है और इनकी ऊँचाई भी भिन्न-भिन्न। विभिन्न कालके विभिन्न भक्त कवियोंने रस-सागरकी सरस लहरोंका दर्शन किया और दर्शनके अनुरूप ही उन भक्त कवियों द्वारा उन सरल लहरोंका वर्णन हुआ। ये सारे वर्णन रस-सागरकी लहरोंके ही है और नितान्त सत्य है। इसीसे एक तथ्य और जुड़ा हुआ है। रस-सागरमें एक-से-एक ऊँची लहरें उठती हैं और इनका वर्णन लीला-काव्योंमें हुआ है। काव्यमें रस-सागरकी जिन ऊँची-ऊँची लहरोंका वर्णन आ चुका है, अब यह तो नहीं कहा जा सकता है कि उन ऊँची लहरोंसे और अधिक ऊँची लहर रस-सागरमें उठेगी ही नहीं। रस-सागरके उद्वेलन और उच्छलनको सीमाबद्ध नहीं किया जा सकता। पता नहीं, रस-सागर कब इतना अधिक उच्छिलत हो उठे कि नवीन लहरकी ऊँची पिछली सारी ऊँची लहरोंको पार कर जाये। ऐसा लगता है कि 'जय जय प्रियतम' काव्यके साथ यह तथ्य मूर्त हो उठा है। प्रियतम श्रीकृष्णकी उपस्थितिमें जिस काव्यकी रचना हों, उस काव्यमें यह सत्य समन्वित हो उठे तो क्या आश्चर्य किया जाय? लीलाके प्रवाहका लालित्य, संवादमें दैन्यका माधुर्य, भावोंके द्वन्द्वकी पराकाष्ठा, अन्तरकी व्यथाकी प्रखरता, हृदयके भावोंकी कोमलता, स्वसुखकी वाञ्छाका अभाव, स्वार्थ-शून्य समर्पणकी असीमता, प्रतिदान-निरपेक्ष प्यारकी प्रबलता, आत्मार्पण जनित विनयकी अगाधता, भावावेगकी अतिशयतामें आत्म-विस्मृति, प्रीतिमें स्वयंकी आहुति, इस प्रकारकी कुछ दृष्टियोंमें देखनेपर यही लगता है कि यह काव्य वस्तुतः लोकोत्तर है।

प्रियतम-काव्यके एक प्रसंगका भाव-गाम्भीर्य वस्तुतः आस्वादनीय है। प्रियतम श्रीकृष्णके दूत श्रीउद्धव मथुरासे व्रजमें आते हैं और आकर वृषभानुनन्दिनी श्रीराधाकी भावमयी स्थितिको देखकर उनके श्रीचरणोंको स्पर्श करके प्रणाम करना चाहते हैं। श्रीउद्धवजीके ज्ञानकी गरिमाको तो गोपियोंके भाव-सागरकी
लहरें बहुत पहले ही बहा ले गयी थीं। ज्यों ही श्रीउद्धवजी प्रणाम करनेकी इच्छासे उठे, प्रीति-प्रतिमा श्रीराधाने अपने श्रीचरणोंको संकुचित कर लिया। श्याम-प्रिया श्रीराधा उद्धवजीको चरण स्पर्शसे विरत करना चाहती हैं और श्रीमद्भागवतमें श्रीराधाजी कहती हैं- 'मधुप मा स्पृशाङ्घ्रि'। मेरे चरणोंका स्पर्श मत करो।

इसी प्रसंगका वर्णन करते हुए भिन्न-भिन्न भक्त किवयोंने अपने-अपने ढंगसे भाव-पल्लवन किया है। भक्त हृदय श्रीसूरदासजीकी अनुपम कृति सूरसागरमें श्रीउद्धवजीके प्रति कटूक्ति है-
मधुकर स्याम कहा हित जानै।
कोऊ  प्रीति  करें  कैसेहू   वह  अपनो  गुन  ठानै ॥
भँवर भुजंग काक कोकिल को कबिगन कपट बखानै।
'सूरदास'  सरबस  जौ  दीजै,  कारौ कृतहिं न मानै ॥
*****
मीठे  बचन   सुहाए   बोलत,    अंतर    जारनहार।
भँवर कुरंग काक अरु कोकिल, कपटिन की चटसार ॥
*****
मधुप     तुम     देखियत      हो  अति    कारे।
कपटी कुटिल निठुर निरमोही, दुख दै दूरि सिधारे ॥
*****
ऐसी ही कारैन की रीति।
मन दे सरबस हरत परायौ, करत कपट की प्रीति ॥
*****
काहें  चरन  छुवत  रस लंपट, हम आगे यह गीत।
'सूर' इतै  सौ  बार  कहा है, जो पै त्रिगुन अतीत ॥

'सूर सागर' में श्रीउद्धवजीसे भ्रमरके मिससे यही कहा गया है- हे दूत ! तुम मेरे चरणोंका स्पर्श मत करो, इसीलिये कि हम सरलाके प्रति तुम्हारी प्रीति कपटपूर्ण है। तुम कपटी हो, कुटिल हो, अकृतज्ञ हो, वंचक हो, लोलुप हो, लंपट हो, अतः दूर ही रहो। तुम मेरे चरणोंका स्पर्श मत करो।
'जय जय प्रियतम' काव्यकी श्रीराधा स्वरूप सर्वथा भिन्न है। महासदाशया श्रीराधा भ्रमरको उपालम्भ नहीं सुनाती, अपितु अपनी उलझनका निवेदन करती है। चरण-स्पर्शकी अभिलाषाकी अभिव्यक्ति होते ही कृष्णप्रेममयी श्रीराधाके हृदयमें भावोंका द्वन्द्व उठ खड़ा होता है और वह द्वन्द्व सीमाका अतिक्रमण करने लगता है। भाव द्वन्द्वके आधिक्यमें युगल चरण संकुचित हो जाते हैं। चरण-स्पर्श-हेतु-उत्सुक दूतसे प्रीति-विगलिता श्रीराधा कहती है-तुम मेरे प्राणधन प्रियतमके प्रिय दूत हो, अतः तुम्हारा और तुम्हारी प्रत्येक अभिलाषाका सम्मान करना ही मेरा परम कर्तव्य है, परन्तु तुम्हारी इस अभिलाषाने मुझे बहुत बड़ी उलझनमें डाल दिया है। एक ऐसी असमञ्जसकी स्थिति उत्पन्न हो गयी है, जिसका समाधान नहीं। मेरे प्राणधन प्रियतमने मुझसे वचन ले लिया है कि इन चरणोंपर एकमात्र मेरा ही स्वत्व रहे अथवा इन चरणोंका स्पर्श वे ही कर पायें, जिनका मन-मति-चित्त-अहं सब कुछ मुझसे एकाकार हो जाये। 

हो गद्गद बोले-दान महा  प्रियतमे !  मुझे यह दो,  प्रियतम !
ये पोंछ चरण  असमोर्ध्व रहूँ बड़भागी सुखी सदा,  प्रियतम !
मेरी   ही  स्वत्व  रहे इनपर,  केवल  छुएँ  वे ही,  प्रियतम !	
जिनका मन बुद्धि अहं काला जलदाभ बने मुझ-सा, प्रियतम !

प्रियतमके चरणोंकी यह दासी प्रियतमसे भिन्न कुछ सोच ही नहीं सकती। उनकी रुचि ही मेरा जीवन है। उनको ऐसा वचन दे चुकनेके बाद अब तुम्हीं बतलाओं कि तुम्हारी अभिलाषाका सम्मान मैं कैसे करूँ?
'जय जय प्रियतम' काव्यकी महाभावस्वरूपा, महानुरागिणी, महासमर्पणमयी महाह्लादिनी, महाविनीता श्रीराधाका स्वरूप सर्वथा अद्वितीय तथा पूर्णतः लोकोत्तर है। आन्तरिक उलझनके कारण मनके भीतर जो असमञ्जस भरा संकोच है, उसीके कारण तो उनके वे चरण युगल संकुचित होकर सिमट गये। कहाँ वह उपालम्भ और कहाँ यह उलझन ? चरण स्पर्शका वर्जन दोनों ही स्थानोंपर होता है, किन्तु दोनोंके हेतु-निवेदनमें कितना महान अन्तर हैं? दोनोंका व्यक्तित्व सर्वथा भिन्न है।
इसी स्थानपर एक और तथ्य उल्लेखनीय है। इस तथ्यकी वैचित्री मनको बरबस चमत्कृत कर देती है। तीन धामोंकी तीर्थयात्रासे वापस आनेके बाद सन् १९५६ ई० में बाबूजी शरीरसे अस्वस्थ हो गये। चिकित्सकोंके परामर्शके अनुसार बाबूजी प्रायः एक एकान्त कमरेमें विश्राम करते रहते थे। विश्रामके निमित्त बाबूजीको परम मन-भावन एकान्त सुलभ हो गया। कमरेके इस एकान्तमें बाबूजीकी काव्य-धाराको बाधा-रहित गतिसे प्रवाहितक होनेका अवसर मिला। बाबूजी द्वारा काव्य-रचना तो पहले भी होती थी, पर अब काव्य-धाराकी गति कुछ और ही थी। भगवान श्रीकृष्णकी अहैतुकी कृपासे मन भगवल्लीलामें सदा ही लीन रहने लगा और गहरे भावोंमें नित्य निमग्नतावाली दशा होनेके कारण अब काव्यकी वर्ण्य-वस्तु था व्रज-व्रजेश व्रजांगनाका रस-सिन्धु। इसका स्पष्ट संकेत बाबूजीने अपनी लेखनीसे किया है, जो सबके सामने आ चुका है 'पद-रत्नाकर' की भूमिकाके रूपमें। अब बाबूजीकी कवितामें वर्णन था श्रीराधा-माधवका और उनकी पारस्परिक अकलुष प्रीतिका। बाबूजीके स्वस्थ हो जानेके बाद भी उनकी काव्य-धारामें विराम नहीं आया, अपितु जितनी ही गहरी भाव-दशा, उतनी ही उत्कृष्ट काव्य-रचना होती थी। इस उत्कृष्ट काव्य-रचनाका क्रम अखण्ड और अबाध गतिसे निरन्तर चलता रहा। इस स्तरकी काव्य-रचना मुख्यतः सन् १९५६ ई० से प्रारम्भ हुई।
इसी सन् १९५६ ई० में पूज्य बाबाने काष्ठ-मौनका कठोर व्रत लिया। काष्ठमौनकी अवधिमें ही बाबाको काव्य-रचनाका स्फुरण हुआ और इसी अवधिमें रचना आरम्भ हुई उनके 'जय जय प्रियतम' काव्यकी। 'जय जय प्रियतम' काव्यकी रचनाके समय कठोर मौन व्रत होनेके कारण बाबा किसीसे भी संभाषण नहीं करते थे, यहाँ तक कि बाबूजीसे भी नहीं। स्वीकृत नियमोंके अनुसार बाबा व्रतकी अवधिमें बाबूजीसे बात कर सकते थे, पर ऐसी आवश्यकता आयी ही नहीं। जब बाबा किसीकी ओर भी दृष्टि उठाकर नहीं देखते थे, तब किसीसे भी संभाषणकी संभावना ही कहाँ ?
सन् १९५६ ई० के बादसे बाबूजी और बाबा, दोनोंके ही द्वारा काव्य-रचनाका आरम्भ होता है। इन दोनों विभूतियोंका परस्परमें विचारों एवं भावोंका आदान-प्रदान तनिक भी नहीं होता था, इसके बाद भी दोनोंके काव्यमें वृषभानुनन्दिनी श्रीराधा एवं नन्दनन्दन श्रीकृष्णके 'पर-तत्त्व' के चित्रणमें और उनकी पारस्परिक प्रीतिके स्तर एवं स्वरूपके चित्रणमें अद्भुत साम्य है। इतना अधिक साम्य है, मानो दोनों विभूतियोंके मध्य नित्य ही परस्परालाप होता रहा है और मानो परस्परालापके मध्य श्रीप्रिया-प्रियतम विषयक चिन्तन-मनन होता रहा है। यदि ऐसा नहीं होता तो इन दोनों विभूतियों द्वारा रचित काव्यमें इतने अधिक साम्यका समावेश कैसे हो जाता ? साम्यको देखकर कोई भी व्यक्ति इस प्रकारकी बातको सोच ले सकता है, पर वास्तविकता यह है कि इन दोनों विभूतियोंकी काव्य-रचनामें श्रीप्रिया-प्रियतमके स्वरूप चित्रणमें जो साम्य है, वह वस्तुतः मनको चमत्कृत कर देता है और इस साम्यके अवतरणका हेतु भी अद्भुत है।
इस स्थलपर कुछ पुरातन प्रसंगोंकी ओर इंगित करना आवश्यक हो गया है। सन् १९३६ ई० में गीतावाटिकामें एक वर्षीय अखण्ड हरिनाम संकीर्तन हो रहा था। उस समय बाबा सर्व प्रथम गीतावाटिकामें आये थे। तब बाबा पूर्णतः शांकरमतानुयायी थे और उनकी निष्ठा सर्वथा अद्वैतवादी थी। सर्वप्रथम मिलनके समय बाबूजीने संन्यासी वेषमें पधारे हुए अपरिचित बाबाको चरण छूकर प्रणाम किया। गीतावाटिकाके अग्रभागमें चरण स्पर्शके माध्यमसे बाबूजीके 'स्थूल-संस्पर्श' का प्रभाव ऐसा था कि बाबा निराकारवादीसे साकारोपासक बन गये और वृन्दावन धामकी परम निधि श्रीराधा-माधवकी सरस सम्पत्तिका महादान बाबाको मिल गया।
सन् १९३९ के मई मासमें बाबा बाबूजीके नित्य साथ रहने लग गये। इसके बाद सम्भवतः जून या जुलाई १९३९ की बात है। बाबाका निवास गीतावाटिकाके पिछले भागमें एक कुटियाके अन्दर था। बाबाके मनमें व्रजभाव सम्बन्धी कुछ ऐसी गुत्थियोंका उद्भव हो गया, जिनको कोई सिद्ध रसिक संत ही सुलझा सकता था। बाबा जानते थे कि बाबूजी द्वारा यह कार्य हो सकता है, पर बाबूजी भला गुरु-पद क्योंकर स्वीकार करने लगे ? इधर बाबा अपनी गुत्थियोंमें उलझे हुए कुटियाके द्वारपर बैठे हुए थे, उधर बाबूजीकी अन्तर्भेदी दृष्टिने अधिकारीके मनकी कुण्ठा और खिन्नताको जान लिया। बाबूजी सूक्ष्म शरीरसे वहाँ पधारे, जहाँ बाबा कुण्ठित मनसे बैठे हुए थे। बाबूजीने अपनी अँगुलीसे बाबाकी अँगुलियोंके दसों नखोंका स्पर्श किया। एक प्रकारसे यह शक्ति-पात ही था। गीतावाटिकाके एकान्त भागमें नख-स्पर्शके माध्यमसे बाबूजीके 'सूक्ष्म-संस्पर्श' का प्रभाव ऐसा था कि बाबाकी सारी गुत्थियाँ खुल गयीं और रसोपासनासे सम्बन्धित सभी समस्याओंके स्थायी समाधानका महादान बाबाको मिल गया।
अब इस 'स्थूल-संस्पर्श' एवं 'सूक्ष्म-संस्पर्श' की परिधिसे दूर, बहुत दूर, अतीव दूर अब पूर्णतः इन्द्रियातीत स्तरपर एक ऐसी प्रक्रिया सक्रिय हो उठी, जिससे असम्भव भी सम्भव हो गया। बाबूजीसे बाबाका मन इतना अधिक जुड़ा हुआ था, दोनोंका भाव सम्बन्ध इतना अधिक प्रबल था कि वस्तु एक ओरसे दूसरी ओर स्वतः संक्रमित हो गयी। बाहरसे देखने भरमें बाबा बाबूजीसे नहीं मिलते थे, पर भीतरसे उनका नित्य मिलन है। प्रत्यक्षतः वियुक्त होते हुए भी वस्तुतः दोनोंमें नित्य संयुक्ति है। भावात्मक एकात्मताके कारण दोनोंमें परम सांनिध्य है और उस भावात्मक सांनिध्यने ही वस्तु-संक्रमणको सम्भव बना दिया। जिसकी सक्रियता बोधकी सीमामें सरलतापूर्वक नहीं आ पाती, ऐसे संक्रमणके द्वारा उन 'दो महादानों' से भी इस महत्तर दानकी प्रक्रियाँ सहज ही सम्पन्न हो गयी। वे दो महादान हुए थे उस प्रत्यक्ष गीतावाटिकामें और यह महत्तर दान हुआ था इस परोक्ष भाववाटिकामें। इस 'भाव-संस्पर्श' का प्रभाव ऐसा था कि पूर्णतः परोक्ष स्तरीय संक्रमणके माध्यमसे बाबाके हृदयमें वह स्वरूप प्रतिबिम्बित-प्रतिफलित हो उठा, जो बाबूजीके हृदयमें था। महाभावस्वरूपिणी श्रीराधा एवं रसराजस्वरूप श्रीकृष्णके 'गुणरहित-कामनारहित-प्रतिक्षणवर्धमान अविच्छिन्न-सूक्ष्मतर-अनुभवरूप' प्रेम-प्रणालीकी जो सच्चिदानन्दमयी छवि बाबूजीके हृदयमें थी, वही छवि बाबाके अन्तःकरणमें उद्भासित हो उठी। यदि एक ओर संक्रमित करनेकी योग्यता थी तो दूसरी ओर संक्रमितको ग्रहण करनेकी पात्रता थी। संक्रमित छविको बाबाने हृदयसे स्वीकार किया, जीवनमें अंगीकार किया और वे हो गये नखशिख सर्वथा तदाकार। बाबाने स्वयं कहा है- श्रीपोद्दार महाराज यदि गुलाबके पौधे हैं तो उस पौधेकी एक शाखापर खिलनेवाला मैं एक छोटा-सा गुलाबका फूल हूँ। मुझसे भी अधिक सुन्दरतर, अधिक श्रेष्ठतर पुष्प, एक नहीं, अनेकानेक पाटल पुष्प खिला देनेकी क्षमता इस पौधेंमें है।
बाबूजीके हृदयमें दिव्य युगल श्रीराधा माधवके दिव्य प्रेमकी जो परम सुन्दरतम, परम मधुरतम एवं परम पवित्रतम छवि थी, वही छवि संक्रमित हो उठी बाबाके हृदयमें और उसी परमोज्ज्वल छविकी अभिव्यक्ति हुई है बाबाके 'जय जय प्रियतम' काव्यमें।
बाबूजी और बाबाके द्वारा वृषभानुनन्दिनी श्रीराधा एवं नन्दनन्दन श्रीकृष्णके पारस्परिक प्रीतिका जैसा चित्रण हुआ है, वह सर्वथा अमानवीय धरातलकी वस्तु है। यह प्रीति सर्वथा शरीरातीत, आद्यन्त काम-गन्ध-शून्य, प्रतिक्षण वर्धनशील, नित्य पवित्रतम, प्रतिदान-भावना-निरपेक्ष, स्व-सुख-वाञ्छा-विरहित, तत्सुखैक-तात्पर्यमय, दिव्यानन्द-विधायक, एकमात्र अनुभव गम्य है और प्रीतिके इस लोकोत्तर स्वरूपके उद्घाटनने प्रेम-साधनाके क्षेत्रके उन सभी प्रकारके मालिन्य एवं कालुष्यको दूर कर दिया, जो अवसर पाकर इस साधना क्षेत्रमें जाने-अनजाने रूपमें प्रविष्ट हो गये थे। बाबूजी और बाबाके माध्यमसे प्रीतिका जो महोत्कृष्ट एवं महोज्ज्वल स्वरूप जगतके सामने आया है, उसकी स्मृति मात्रसे मन आह्लादित हो उठता है।
बाबाका यह 'जय जय प्रियतम' काव्य उनकी काष्ठ-मौन अवधिका एक गौरवपूर्ण प्रसाद है। काष्ठ-मौनकी अवधिमें ही पूज्य श्रीबाबाकी श्रीराधाभावमें प्रतिष्ठा हुई। महाभाव-भावित श्रीराधाबाबाकी प्रीतिप्रदायिका परमपुनीता पद-रज-कणिकाको सतत वन्दन है ॥ 
''',
      );
    }
    // --- षोडश गीत (Topic 5) ---
    else if (sectionId == 'topic5') {
      switch (title) {
        case 'वंदना':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''॥ षोडश गीत॥

(वंदना)

दोउ चकोर, दोउ चंद्रमा, दोउ अलि, पंकज दोउ।
दोउ चातक, दोउ मेघ प्रिय, दोउ मछरी, जल दोउ॥
आस्रय-आलंबन दोउ, बिषयालंबन दोउ।
प्रेमी-प्रेमास्पद दोउ, तत्सुख-सुखिया दोउ॥
लीला-आस्वादन-निरत, महाभाव-रसराज।
बितरत रस दोउ दुहुन कौं, रचि बिचित्र सुठि साज॥
सहित बिरोधी धर्म-गुन जुगपत नित्य अनंत।
बचनातीत अचिन्त्य अति, सुषमामय श्रीमंत॥
श्रीराधा-माधव-चरन बंदौं बारंबार।
एक तत्त्व दो तनु धरें, नित-रस-पाराबार॥''',
          );

        case '1.राधिके ! तुम मम जीवन-मूल।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(1)

राधिके ! तुम मम जीवन-मूल। 
अनुपम अमर प्रान-संजीवनि, नहिं कहुँ कोउ समतूल॥
जस सरीर में निज-निज थानहिं सबही सोभित अंग।
किंतु प्रान बिनु सबहि ब्यर्थ, नहिं रहत कतहुँ कोउ रंग॥
तस तुम प्रिये ! सबनि के सुख की एकमात्र आधार।
तुम्हरे बिना नहीं जीवन-रस, जासौं सब कौ प्यार॥
तुम्हरे प्राननि सौं अनुप्रानित, तुम्हरे मन मनवान।
तुम्हरौ प्रेम-सिंधु-सीकर लै करौं सबहि रसदान॥
तुम्हरे रस-भंडार पुन्य तैं पावत भिच्छुक चून।
तुम सम केवल तुमहि एक हौ, तनिक न मानौ ऊन॥
सोऊ अति मरजादा, अति संभ्रम-भय-दैन्य-सँकोच।
नहिं कोउ कतहुँ कबहुँ तुम-सी रसस्वामिनि निस्संकोच।
तुम्हरौ स्वत्व अनंत नित्य, सब भाँति पूर्न अधिकार।
कायब्यूह निज रस-बितरन करवावति परम उदार॥
तुम्हरी मधुर रहस्यमई मोहनि माया सौं नित्य।
दच्छिन बाम रसास्वादन हित बनतौ रहूँ निमित्त॥''',
          );

        case '2.हौं तो दासी नित्य तिहारी।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(2)

हौं तो दासी नित्य तिहारी।
प्राननाथ जीवनधन मेरे, हौं तुम पै बलिहारी॥
चाहैं तुम अति प्रेम करौ, तन-मन सौं मोहि अपनाऔ।
चाहैं द्रोह करौ, त्रासौ, दुख देइ मोहि छिटकाऔ॥
तुम्हरौ सुख ही है मेरौ सुख, आन न कछु सुख जानौं।
जो तुम सुखी होउ मो दुख में, अनुपम सुख हौं मानौं॥
सुख भोगौं तुम्हरे सुख कारन, और न कछु मन मेरे।
तुमहि सुखी नित देखन चाहौं निस-दिन साँझ-सबेरे॥
तुमहि सुखी देखन हित हौं निज तन-मन कौं सुख देऊँ।
तुमहि समरपन करि अपने कौं नित तव रुचि कौं सेऊँ॥
तुम मोहि ‘प्रानेस्वरि’, ‘हृदयेस्वरि’, ‘कांता’ कहि सचु पावौ।
यातैं हौं स्वीकार करौं सब, जद्यपि मन सकुचावौं॥''',
          );

        case '3.हे आराध्या राधा ! मेरे मनका तुझमें नित्य निवास।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(3)

हे आराध्या राधा ! मेरे मनका तुझमें नित्य निवास।
तेरे ही दर्शन कारण मैं करता हूँ गोकुलमें वास॥
तेरा ही रस-तत्त्व जानना, करना उसका आस्वादन।
इसी हेतु दिन-रात घूमता मैं करता वंशीवादन॥
इसी हेतु स्नानको जाता, बैठा रहता यमुना-तीर।
तेरी रूपमाधुरीके दर्शनहित रहता चित्त अधीर॥
इसी हेतु रहता कदम्बतल, करता तेरा ही नित ध्यान।
सदा तरसता चातककी ज्यों, रूप-स्वातिका करने पान॥
तेरी रूप-शील-गुण-माधुरि मधुर नित्य लेती चित चोर।
प्रेमगान करता नित तेरा, रहता उसमें सदा विभोर॥''',
          );

        case '4.मेरी इस विनीत विनतीको सुन लो, हे व्रजराजकुमार !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(4)

मेरी इस विनीत विनतीको सुन लो, हे व्रजराजकुमार !
युग-युग, जन्म-जन्ममें मेरे तुम ही बनो जीवनाधार॥
पद-पङ्कज-परागकी मैं नित अलिनी बनी रहूँ, नँदलाल !
लिपटी रहूँ सदा तुमसे मैं कनकलता ज्यों तरुण तमाल॥
दासी मैं हो चुकी सदाको अर्पणकर चरणोंमें प्राण।
प्रेम-दामसे बँध चरणोंमें, प्राण हो गये धन्य महान॥
देख लिया त्रिभुवनमें बिना तुम्हारे और कौन मेरा।
कौन पूछता है ‘राधा’ कह, किसको राधाने हेरा॥
इस कुल, उस कुल—दोनों कुल, गोकुलमें मेरा अपना कौन !
अरुण मृदुल पद-कमलोंकी ले शरण अनन्य गयी हो मौन॥
देखे बिना तुम्हें पलभर भी मुझे नहीं पड़ता है चैन।
तुम ही प्राणनाथ नित मेरे, किसे सुनाऊँ मनके बैन॥
रूप-शील-गुण-हीन समझकर कितना ही दुतकारो तुम।
चरणधूलि मैं, चरणोंमें ही लगी रहूँगी बस, हरदम॥''',
          );

        case '5.हे वृषभानुराजनन्दिनि ! हे अतुल प्रेम-रस-सुधा-निधान !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(5)

हे वृषभानुराजनन्दिनि ! हे अतुल प्रेम-रस-सुधा-निधान ! 
गाय चराता वन-वन भटकूँ, क्या समझूँ मैं प्रेम-विधान !       
ग्वाल-बालकोंके सँग डोलूँ, खेलूँ सदा गँवारू खेल।
प्रेम-सुधा-सरिता तुमसे मुझ तप्त धूलका कैसा मेल !  
तुम स्वामिनि अनुरागिणि ! जब देती हो प्रेमभरे दर्शन।
तब अति सुख पाता मैं, मुझपर बढ़ता अमित तुम्हारा ऋण॥
कैसे ऋणका शोध करूँ मैं, नित्य प्रेम-धनका कंगाल ! 
तुम्हीं दया कर प्रेमदान दे मुझको करती रहो निहाल॥''',
          );

        case '6.सुन्दर श्याम कमल-दल-लोचन दुखमोचन व्रजराजकिशोर।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(6)

सुन्दर श्याम कमल-दल-लोचन दुखमोचन व्रजराजकिशोर।
देखूँ तुम्हें निरन्तर हिय-मन्दिरमें, हे मेरे चितचोर !
लोक-मान-कुल-मर्यादाके शैल सभी कर चकनाचूर।
रक्खूँ तुम्हें समीप सदा मैं, करूँ न पलक तनिकभर दूर॥
पर मैं अति गँवार ग्वालिनि गुणरहित कलङ्की सदा कुरूप।
तुम नागर गुण-आगर अतिशय कुलभूषण सौन्दर्य-स्वरूप॥     
मैं रस-ज्ञान-रहित रसवर्जित, तुम रसनिपुण रसिक सिरताज॥
इतनेपर भी दयासिन्धु तुम मेरे उरमें रहे विराज॥''',
          );

        case '7.हे प्रियतमे राधिके ! तेरी महिमा अनुपम अकथ अनन्त।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(7)

हे प्रियतमे राधिके ! तेरी महिमा अनुपम अकथ अनन्त।
युग-युगसे गाता मैं अविरत, नहीं कहीं भी पाता अन्त॥
सुधानन्द बरसाता हियमें तेरा मधुर वचन अनमोल।
बिका सदाके लिये मधुर दृग-कमल कुटिल भ्रुकुटीके मोल॥
जपता तेरा नाम मधुर अनुपम मुरलीमें नित्य ललाम।
नित अतृप्त नयनोंसे तेरा रूप देखता अति अभिराम॥
कहीं न मिला प्रेम शुचि ऐसा, कहीं न पूरी मनकी आश।
एक तुझीको पाया मैंने, जिसने किया पूर्ण अभिलाष॥ 
नित्य तृप्त, निष्काम नित्यमें मधुर अतृप्ति, मधुरतम काम।
तेरे दिव्य प्रेमका है यह जादूभरा मधुर परिणाम॥''',
          );

        case '8.सदा सोचती रहती हूँ मैं—क्या दूँ तुमको, जीवनधन !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(8)

सदा सोचती रहती हूँ मैं—क्या दूँ तुमko, जीवनधन !
जो धन देना तुम्हें चाहती, तुम ही हो वह मेरा धन॥
तुम ही मेरे प्राणप्रिय हो, प्रियतम ! सदा तुम्हारी मैं।
वस्तु तुम्हारी तुमको देते पल-पल हूँ बलिहारी मैं॥
प्यारे ! तुम्हें सुनाऊँ कैसे अपने मनकी सहित विवेक।
अन्योंके अनेक, पर मेरे तो तुम ही हो, प्रियतम ! एक॥
मेरे सभी साधनोंकी बस, एकमात्र हो तुम ही सिद्धि।
तुमही प्राणनाथ हो बस, तुम ही हो मेरी नित्य समृद्धि॥
तन-धन-जनका बन्धन टूटा, छूटा, भोग-मोक्षका रोग।
धन्य हुई मैं, प्रियतम ! पाकर एक तुम्हारा प्रिय संयोग॥''',
          );

        case '9.राधे, हे प्रियतमे, प्राण-प्रतिमे, हे मेरी जीवन मूल !':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(9)

राधे, हे प्रियतमे, प्राण-प्रतिमे, हे मेरी जीवन मूल !
पलभर भी न कभी रह सकता, प्रिये मधुर ! मैं तुमको भूल॥
श्वास-श्वासमें तेरी स्मृतिका नित्य पवित्र स्रोता बहता।
रोम-रोम अति पुलकित तेरा आलिङ्गन करता रहता॥
नेत्र देखते तुझे नित्य ही, सुनते शब्द मधुर यह कान।
नासा अङ्ग-सुगन्ध सूँघती, रसना अधर-सुधा-रस-पान॥
अङ्ग-अङ्ग शुचि पाते नित ही तेरा प्यारा अङ्ग-स्पर्श।
नित्य नवीन प्रेम-रस बढ़ता, नित्य नवीन हृदयमें हर्ष॥''',
          );

        case '10.मेरे धन-जन-जीवन तुम ही, तुम ही तन-मन, तुम सब धर्म।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(10)

मेरे धन-जन-जीवन तुम ही, तुम ही तन-मन, तुम सब धर्म।
तुम ही मेरे सकल सुखसदन, प्रिय निज जन, प्राणोंके मर्म॥
तुम्हीं एक बस, आवश्यकता, तुम ही एकमात्र हो पूर्ति।
तुम्हीं एक सब काल सभी विधि हो उपास्य शुचि सुन्दर मूर्ती॥
तुम ही काम-धाम सब मेरे, एकमात्र तुम लक्ष्य महान।
आठों पहर बसे रहते तुम मम मन-मन्दिरमें भगवान॥
सभी इन्द्रियोंको तुम शुचितम करते नित्य स्पर्श-सुख-दान।
बाह्याभ्यन्तर नित्य निरन्तर तुम छेड़े रहते निज तान॥
कभी नहीं तुम ओझल होते, कभी नहीं तजते संयोग।
घुले-मिले रहते करवाते करते निर्मल रस-सम्भोग॥
पर इसमें न कभी मतलब कुछ मेरा तुमसे रहता भिन्न।
हुए सभी संकल्प भङ्ग मैं-मेरेके समूल तरु छिन्न॥
भोक्ता-भोग्य सभी कुछ तुम हो, तुम ही स्वयं बने हो भोग।
मेरा मन बन सभी तुम्हीं हो अनुभव करते योग-वियोग॥''',
          );

        case '11.मेरा तन-मन सब तेरा ही, तू ही सदा स्वामिनी एक।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(11)

मेरा तन-मन सब तेरा ही, तू ही सदा स्वामिनी एक।
अन्योंका उपभोग्य न भोक्ता है कदापि, यह सच्ची टेक॥
तन समीप रहता न स्थूलत:, पर जो मेरा सूक्ष्म शरीर।
क्षणभर भी न विलग रह पाता, हो उठता अत्यन्त अधीर॥
रहता सदा जुड़ा तुझसे ही, अत: बसा तेरे पद-प्रान्त।
तू ही उसकी एकमात्र जीवनकी जीवन है निर्भ्रान्त॥
हुआ न होगा अन्य किसीका उसपर कभी तनिक अधिकार।
नहीं किसीको सुख देगा, लेगा न किसीसे किसी प्रकार॥
यदि वह कभी किसीसे किंचित् दिखता करता-पाता प्यार।
वह सब तेरे ही रसका बस, है केवल पवित्र विस्तार॥
कह सकती तू मुझे सभी कुछ, मैं तो नित तेरे आधीन।
पर न मानना कभी अन्यथा, कभी न कहना निजको दीन॥
इतने पर भी मैं तेरे मनकी न कभी हूँ कर पाता।
अत: बना रहता हूँ संतत तुझको दुखका ही दाता॥
अपनी ओर देख तू मेरे सब अपराधोंको जा भूल।
करती रह कृतार्थ मुझको वे पावन पद-पङ्कजकी धूल॥''',
          );

        case '12.तुमसे सदा लिया ही मैंने, लेती-लेती थकी नहीं।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(12)

तुमसे सदा लिया ही मैंने, लेती-लेती थकी नहीं।
अमित प्रेम-सौभाग्य मिला, पर मैं कुछ भी दे सकी नहीं॥
मेरी त्रुटि, मेरे दोषोंको तुमने देखा नहीं कभी।
दिया सदा, देते न थके तुम, दे डाला निज प्यार सभी॥
तब भी कहते—‘दे न सका मैं तुमको कुछ भी, हे प्यारी !
तुम-सी शील-गुणवती तुम ही, मैं तुमपर हूँ बलिहारी’॥       
क्या मैं कहूँ प्राणप्रियतमसे, देख लजाती अपनी ओर।
मेरी हर करनीमें ही तुम प्रेम देखते नन्दकिशोर !॥''',
          );

        case '13.राधे ! तू ही चित्तरञ्जनी, तू ही चेतनता मेरी।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(13)

राधे ! तू ही चित्तरञ्जनी, तू ही चेतनता मेरी।
तू ही नित्य आत्मा मेरी, मैं हूँ बस, आत्मा तेरी॥
तेरे जीवनसे जीवन है, तेरे प्राणोंसे हैं प्राण।
तू ही मन, मति, चक्षु, कर्ण, त्वक्, रसना, तू ही इन्द्रिय-घ्राण॥
तू ही स्थूल-सूक्ष्म इन्द्रियके विषय सभी मेरे सुखरूप।
तू ही मैं, मैं ही तू बस, तेरा-मेरा सम्बन्ध अनूप॥
तेरे बिना न मैं हूँ, मेरे बिना न तू रखती अस्तित्व।
अविनाभाव विलक्षण यह सम्बन्ध, यही बस, जीवन-तत्त्व॥''',
          );

        case '14.तुम अनन्त सौन्दर्य-सुधा-निधि, तुममें सब माधुर्य अनन्त।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(14)

तुम अनन्त सौन्दर्य-सुधा-निधि, तुममें सब माधुर्य अनन्त।
तुम अनन्त ऐश्वर्य-महोदधि, तुममें सब शुचि शौर्य अनन्त॥
सकल दिव्य सद्गुण-सागर तुम लहराते सब ओर अनन्त।
सकल दिव्य रस-निधि तुम अनुपम, पूर्ण रसिक, रसरूप अनन्त॥
इस प्रकार जो सभी गुणोंमें, रसमें अमित असीम अपार।
नहीं किसी गुण-रसकी उसे अपेक्षा कुछ भी किसी प्रकार॥
फिर मैं तो गुणरहित सर्वथा, कुत्सित-गति, सब भाँति गँवार।
सुन्दरता-मधुरता-रहित कर्कश कुरूप अति दोषागार॥
नहीं वस्तु कुछ भी ऐसी, जिससे तुमको मैं दूँ रसदान।
जिससे तुम्हें रिझाऊँ, जिससे करूँ तुम्हारा पूजन-मान॥
एक वस्तु मुझमें अनन्य आत्यन्तिक है विरहित उपमान।
‘मुझे सदा प्रिय लगते तुम’—यह तुच्छ किंतु अत्यन्त महान॥
रीझ गये तुम इसी एक पर, किया मुझे तुमने स्वीकार।
दिया स्वयं आकर अपनेको, किया न कुछ भी सोच-विचार॥
भूल उच्चता भगवत्ता सब सत्ताका सारा अधिकार।
मुझ नगण्यसे मिले तुच्छ बन, स्वयं छोड़ संकोच-सँभार॥
मानो अति आतुर मिलनेको, मानो हो अत्यन्त अधीर।
तत्त्वरूपता भूल सभी नेत्रोंसे लगे बहाने नीर॥
हो व्याकुल, भर रस अगाध, आकर शुचि रस-सरिताके तीर।
करने लगे परम अवगाहन, तोड़ सभी मर्यादा-धीर॥
बढ़ी अमित, उमड़ी रस-सरिता पावन, छायी चारों ओर।
डूबे सभी भेद उसमें, फिर रहा कहीं भी ओर न छोर॥
प्रेमी, प्रेम, परम प्रेमास्पद—नहीं ज्ञान कुछ, हुए विभोर।
राधा प्यारी हूँ मैं, या हो केवल तुम प्रिय नन्दकिशोर॥''',
          );

        case '15.राधा ! तुम-सी तुम्हीं एक हो, नहीं कहीं भी उपमा और।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(15)

राधा ! तुम-सी तुम्हीं एक हो, नहीं कहीं भी उपमा और।
लहराता अत्यन्त सुधा-रस-सागर, जिसका ओर न छोर॥
मैं नित रहता डूबा उसमें, नहीं कभी ऊपर आता।
कभी तुम्हारी ही इच्छासे हूँ लहरोंमें लहराता॥        
पर वे लहरें भी गाती हैं एक तुम्हारा रम्य महत्त्व।
उनका सब सौन्दर्य और माधुर्य तुम्हारा ही है स्वत्व॥
तो भी उनके बाह्य रूपमें ही बस, मैं हूँ लहराता।
केवल तुम्हें सुखी करनेको सहज कभी ऊपर आता॥
एकछत्र स्वामिनि तुम मेरी अनुकम्पा अति बरसाती।
रखकर सदा मुझे संनिधिमें जीवनके क्षण सरसाती॥
अमित नेत्रसे गुण-दर्शन कर, सदा सराहा ही करती।
सदा बढ़ाती सुख अनुपम, उल्लास अमित उरमें भरती॥
सदा सदा मैं सदा तुम्हारा, नहीं कदा कोई भी अन्य।
कहीं जरा भी कर पाता अधिकार दासपर सदा अनन्य॥
जैसे मुझे नचाओगी तुम, वैसे नित्य करूँगा नृत्य।
यही धर्म है, सहज प्रकृति यह, यही एक स्वाभाविक कृत्य॥''',
          );

        case '16.तुम हो यन्त्री, मैं यन्त्र, काठकी पुतली मैं, तुम सूत्रधार।':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(16)

तुम हो यन्त्री, मैं यन्त्र, काठकी पुतली मैं, तुम सूत्रधार।
तुम करवाओ, कहलाओ, मुझे नचाओ निज इच्छानुसार॥
मैं करूँ, कहूँ, नाचूँ नित ही परतन्त्र, न कोई अहंकार।
मन मौन नहीं, मन ही न पृथक्, मैं अकल खिलौना, तुम खिलार॥
क्या करूँ, नहीं क्या करूँ—करूँ इसका मैं कैसे कुछ विचार ?
तुम करो सदा स्वच्छन्द, सुखी जो करे तुम्हें सो प्रिय विहार॥
अनबोल, नित्य निष्क्रिय, स्पन्दनसे रहित, सदा मैं निर्विकार।
तुम जब जो चाहो, करो सदा बेशर्त, न कोई भी करार॥
मरना-जीना     मेरा      कैसा,   कैसा  मेरा  मानापमान।
हैं सभी तुम्हारे ही, प्रियतम ! ये खेल नित्य सुखमय महान॥
कर दिया क्रीडनक बना मुझे निज करका तुमने अति निहाल।
यह भी कैसे मानूँ-जानूँ, जानो तुम ही निज हाल-चाल॥
इतना मैं जो यह बोल गयी, तुम जान रहे—है कहाँ कौन ?
तुम ही बोले भर सुर मुझमें मुखरा-से मैं तो शून्य मौन॥''',
          );

        case 'पुष्पिका':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''(पुष्पिका)

महाभाव-रसराज के मधुर मनोहर भाव । 
दिव्य, मधुरतम, रागमय, दैन्य-विभूषित चाव॥
दोनों दोनोंके लिए सहज सभी कर त्याग।
सुखद परस्पर बन रहे, छलक रहा अनुराग॥
दोनों दोनों के सदा प्रेमी-प्रेष्ठ महान।
नित्य, अनंत, अचिंत्य, शुचि, अनिर्वाच्य रसखान‌॥
सुख दुख दोनों ही सुखद, प्रियतम-सुखके हेतु।
अन्य सभी टूटे सहज मिथ्या निजसुख-सेतु ॥
राधा-माधव-प्रेम-रस वाचा-चित्त-अतीत।
करते शाखाचंद्र-से इंगित सोलह गीत ॥''',
          );

        default:
          return const _TopicPageContent(
            body: '''Topic content not found.''',
          );
      }
    }
    // --- फलश्रुतियाँ (Topic 6) ---
    else if (sectionId == 'topic6') {
      switch (title) {
        case 'श्लोक एवं प्रथम शतक':
          return const _TopicPageContent(body: '''## फलश्रुतियाँ

**श्लोक-ललिताम्बामयीं-** प्रतिदिन अर्थ-अवधारणा एवं अतिशय श्रद्धापूर्वक १०८ बार जप--- मृत्युके समय भगवती ललिताम्बाका साक्षात् दर्शन होगा। महाप्रभु पोद्दार महाराजका स्वरूप प्रकट होकर ब्रजभावमें प्रवेशकी भूमिका बन जायेगी। जीवनमें आर्थिक संकटोंसे निश्चय ही त्राण होगा।

**श्लोक कृष्णस्वरूपिणीं-** प्रतिदिन १०८ बार जप--- मृत्युके समय भगवान् श्रीकृष्णके दर्शन, ब्रजभावमें प्रवेशकी भूमिकाका अवश्यंभावी निर्माण। श्रीकृष्ण कृपाका जीवनकालमें ही अनुभव।

## (प्रथम शतक)

**छन्द सं. १-** प्रतिदिन १०८ बार जप--- जीवनकी संध्याके पूर्व ही 'संसार सत्य नहीं है, स्वप्नतुल्य है', इसका स्पष्ट अनुभव (पू.गुरुदेव द्वारा सन् १९६४ ई. में बताया साधन)

**छन्द सं. २-** प्रतिदिवस दस मालाका जप--- मायाकी आत्यन्तिक निवृत्ति। साक्षात् श्रीकृष्ण द्वारा हस्त- धारणकर निकुंजमें प्रवेश।

**छन्द सं. ४-** प्रतिदिन दस मालाका जप--- शक्तिपात होकर वैषयिक आकर्षणोंसे मुक्ति एवं वैराग्यकी अदम्य प्रतिष्ठा 

**छन्द सं. ८-** केवल चौथी पंक्तिकी दस मालाका नित्य जप---श्रीकृष्णका अनिर्वचनीय अद्भुत रूप-दर्शन।

**छन्द सं. १२-** प्रतिदिन दस मालाका जप--- श्रीकृष्ण विरहभाव का हृदयमें सच्चा प्रकाश।

**छन्दः १३ से १५ तक-** प्रतिदिन १ माला--- मृत्युके पूर्व श्रीराधाके बाल-चरित्रका हृदयमें प्रकाश। विशुद्ध वात्सल्यरसकी हृदयमें प्रतिष्ठा।

**छन्द १६ से १९ तक-** प्रतिदिन एक माला पाठ--- मृत्युके पूर्व राधा-काम्यकाननका प्रत्यक्ष अनुभव। भगवती लीला-महाशक्ति त्रिपुरसुन्दरीके श्रीयंत्रके रहस्यका ज्ञान। वृन्दादेवीके तत्व-रहस्यकी अनुभूति। वृन्दावनके पशु-पक्षियोंके तत्व रहस्यका ज्ञान। 

**छन्द २६ से २८ तक-** एक मालाका पाठ प्रतिदिन--- जीवनयात्रा अत्यन्त सुकर। चित्तवृत्तिमें आत्यन्तिक सात्विक शान्ति बनी रहेगी। कोई, कैसा भी हो, शनैः शनैः चित्तमें शान्ति एवं एकाग्रता स्वभावतः आवेगी। सच्ची आस्तिकताका उद्रेक होगा। इष्टके प्रति निष्ठा एवं श्रद्धा उपलब्ध होगी। पवित्र एवं निष्काम शक्ति-उपासनाके बीज पड़ेंगे।

**छन्द ३६से ४५ तक-** प्रतिदिन १ माला पाठ--- कुन्दवल्ली देवी एवं श्रीदाम भैयाके जन्मोत्सवका अनुभवपूर्ण दर्शन। बृषभानुपुरीके अपूर्व वैभवका प्रत्यक्ष प्रकाश। शुद्ध सख्य रसका प्रादुर्भाव। निष्काम तत्सुखिया भावसे हृदयके ओतप्रोत होनेकी भूमिकाका प्रादुर्भाव ।

**छन्द ४६ से ५५ तक-** १ माला प्रतिदिन पाठ--- ललिता भावकी अनुभूति। उनके जन्मोत्सवकी झाँकी। सखियोंके मध्यकी तत्सुखी प्रीतिका अन्तःकरणमें प्रादुर्भाव। कीर्त्तिदा मैया एवं वृषभानुपुरके अन्य मातृवर्गकी सखियोंके विशुद्ध वात्सल्यका बीज-वपन।

**छन्द सं. ६०-** ‘जय देवि दयामयि जय जगदम्बे जय ललिते’---  इस अमोघ जाग्रत मंत्रका प्रतिदिवस दस माला जपसे समग्र आसुरी शक्तियोंपर शत-प्रतिशत विजय।

**छन्द सं.६३ से ७२ तक-** दस माला प्रतिदिन जप--- यहाँ वर्णित सम्पूर्ण लीलाका निश्चय ही जीवनके अवसानके पूर्व दर्शन।

**छन्द ७३ से ८७ तक-** प्रतिदिन १० माला जाप--- राधा-जन्मोत्सवकी लीलाका जीवनके अवसानके पूर्व निश्चय दर्शन।''');

        case 'द्वितीय शतक':
          return const _TopicPageContent(body: '''## (द्वितीय शतक)

**छन्द १०२ से ११० तक-** प्रतिदिन १० माला पाठ--- जीवनकी सन्ध्याके पूर्व अवश्य-अवश्य चिन्मय गिरिपरिसर एवं गिरिराजका दर्शन।

## (विशेष मंत्र)
उस ओर शैलके कण-कणमें मानो चेतनता थी प्रियतम !
वह खड़ा सतत देखा करता ऊँचा सिर किये हुए, प्रियतम !
**-प्रतिदिन १० माला भावसहित पाठ---** चिन्मय गिरिपरिसर एवं गिरिराजका दर्शन।

## (विशेष मंत्र)
जीवनकी धारा किधर मुड़े, भावी क्या है किसकी, प्रियतम !
सच्चा प्रतीक इसका वह था, आदर वे सब करतीं, प्रियतम !
**-प्रतिदिन १० माला भावसहित पाठ---** परमार्थकी ओर जीवनधारा मोड़नेके लिये विशेष मंत्र

**छन्द १११ से १२२ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व ललिताकुंजके, भगवती ललिता सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १२३ से १३० तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व विशाखाकुंजके, भगवती विशाखा सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १३१ से १३८ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व चित्राकुंजके, भगवती चित्रा सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १३९ से १४६ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व इन्दुलेखाकुंजके, भगवती इन्दुलेखा सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १४७ से १५४ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व चंपकलताकुंजके,भगवती चंपकलता सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १५५ से १६२ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व रंगदेवीकुंजके, भगवती रंगदेवी सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्दः १६३ से १७० तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व तुंगविद्याकुंजके,भगवती तुंगविद्या सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १७१ से १७८ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व सुदेवीकुंजके,भगवती सुदेवी सखीके प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १७९ से १९४ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व प्रिया-प्रियतम निकुंजेश्वर एवं निकुंजेश्वरीके कुण्डोंका तत्वसहित रहस्यका प्रत्यक्ष दर्शन एवं अनुभूति।

**छन्द १९५ से १९८ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व वृषभानुपुरधामके अधिष्ठात्री देवता सूर्यदेवके प्रत्यक्ष दर्शन एवं उनकी विशेष कृपाकी अनुभूति।

**छन्द १९९ से २०२ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व परकीया भावके तत्व-रहस्यका प्रकाश एवं यावट ग्राम एवं उसकी महिमाके दर्शन।''');

        case 'तृतीय शतक':
          return const _TopicPageContent(body: '''## (तृतीय शतक)

**छन्द २०६-** प्रतिदिन १० माला भावसहित जप--- पूर्ण जीवन निश्चय ही मंगलमय बन जायेगा।

## (विशेष मंत्र)
'अप्रतिम यहाँ कोई मंगल निश्चय होगा, सखि री, प्रियतम !'
**---किसी भी कार्यकी मङ्गलमय संपन्नताके लिये इस मंत्रकी दस माला जप करें।**

**छन्द २०७से २१६तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व श्रीराधा-काम्यकाननके अन्तर्गत लीलाजगत्के अप्राकृत चिन्मय पक्षियोंके रूप, रहस्य, तत्व एवं उनकी तत्सुखभाव-भावित वृत्तियोंका साक्षात्कार। ब्रजमें पक्षीभावकी प्राप्तिकी भूमिकाका निर्माण।

**छन्द २१७से २१९ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व राधा-काम्यकाननकी निश्चय झलक। वटतरुके माहात्म्यका ज्ञान।

**छन्द २२० से २२४तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व शुकराज विचक्षणके दर्शन। प्रियतम श्रीकृष्ण ही दूतके रूपमें शुकपक्षी बनकर आते हैं इस रहस्यका परम मधुर प्रकाश।

**छन्द २२५-** यह विशेष मंत्र है। शुद्ध जल लेकर प्रतिदिन इस मंत्रकी १० माला भावसहित जपकरके अभिमंत्रित जल पीलें।--- निश्चय ही जीवनकी संध्याके पूर्व महामायाकी विशिष्ट शक्तियोंका अभ्युदय होगा।

**छन्द २२६ से २३३ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व रसात्मक श्रीयंत्रका प्रकाश। जीवनमें अनेक सिद्धियोंका प्रकाश एवं ब्रजभावका चित्तमें बीज-पल्लवन।

**छन्द २३७-** प्रतिदिन १० माला भावसहित जप--- जीवनकी संध्याके पूर्व विलक्षण चिन्मय आनन्दकी अनुभूति एवं आह्लादतत्वका साक्षात्कार।

**छन्द २३८ से २४१ तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व सन्धिनी महाशक्ति वृन्दाके स्वरूपका साक्षात् दर्शन।

**छन्द २४२-** प्रतिदिन १० माला भावसहित पाठ--- यह विशेष मंत्र है। इसके जपसे जीवनकी संध्याके पूर्व वृन्दाकानन, वृन्दादेवी एवं प्रिया श्रीराधा, राधानुजा मंजुश्यामाका साक्षात् दर्शन होगा।

**छन्द २४३-** प्रतिदिन १० माला भावसहित पाठ यह विशेष मंत्र है।--- इसके जपसे जीवनकी संध्याके पूर्व हंस-हंसिनीके तत्व रहस्यका ज्ञान, प्रिया-प्रियतम नित्यनिकुंजेश्वरकी इन दूतोंके रूपमें स्वयं प्रियतम ब्रजेन्द्रनन्दन ही लीलारत हैं, इसका स्पष्ट प्रत्यक्ष अनुभव हो जायगा।

**छन्द २४४से २४६ तक-** प्रतिदिन १० माला भावसहित पाठ--- इसके जपसे जीवनकी संध्याके पूर्व अशोकनिकुंजके दर्शन, नित्यनिकुंजेश्वर एवं नित्यनिकुंजेश्वरीके इस निकुंजमें लीलारत दर्शन। जन्म, स्थिति, प्रलयसे परे त्रिगुणातीत अप्राकृत निकुंज-लीलाधामकी अनुभूति।

**छन्द २४७से ३०३ तक-** सम्पूर्ण लीलाके भावसहित दस पाठ प्रतिदिन करें।--- समग्र लीला जीवनके अन्तिम पड़ावतक प्रत्यक्ष अनुभवमें मूर्त हो उठेगी।''');

        case 'चतुर्थ शतक':
          return const _TopicPageContent(body: '''## (चतुर्थ शतक)

**छन्दः ३३४ से ३६१तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व सख्यरस-प्रधान तत्सुखिया-भावकी प्रतिष्ठा। श्रीदाम भैयाके दर्शन एवं मृत्युके पश्चात् उनमें प्रतिष्ठा। 

## (विशेष मंत्र)
संदेश    एक    है    श्रीपदमें   उन  नीलदेवताका,  प्रियतम !
सेवा न बनी कुछ भी  सचमुच, अरसिक मुझ किंकरसे, प्रियतम !
अपनी  ही  ओर  देख   उरमें  अविचल  निवास  देना, प्रियतम !
है नहीं मनोभ्रम,  सच्ची   है  घटना  सब  इस  वनकी, प्रियतम !
माला  है  झूल   रही   उरपर,  झूलेगी   नित्य  तथा,  प्रियतम !
*****
बोला 'श्रीपदमें  प्रणति  सरस  उनकी  पल पल शत है, प्रियतम !
है   और  विनम्र  निवेदन  यह,  उनके  अन्तस्तलका,  प्रियतम !
'प्रियतमे,  रखो,  धीरज  मुझसे अब नित्य खिलन होगा, प्रियतम !
जय हो ! जय हो ! निरवधि जय हो ! श्रीचरणसरोरुहकी, प्रियतम !

**--इन मंत्रोंकी दस मालाके जपसे प्रियतम नीलसुन्दर ब्रजेन्द्रनन्दनसे नित्य अविच्छिन्न मिलनका विधान।**''');

        case 'पंचम एवं अन्य':
          return const _TopicPageContent(body: '''## (पंचम शतक)
सम्पूर्ण पंचम शतकके भावसहित प्रतिदिन १० पाठसे जीवनकी संध्याके पूर्व सम्पूर्ण लीलाका प्रत्यक्ष दर्शन होगा। मंजुश्यामाका तत्वरहस्य हृदयंगम होगा, उनके जन्मोत्सवकी झाँकी प्रत्यक्ष होगी।

## (षष्ठम शतक)	

**छन्द सं. ५०६से ५३०तक-** प्रतिदिन भावसहित १० पाठसे जीवनकी संध्याके पूर्व वंशीनाद श्रवणगोचर होगा। चर अचरपर उसके प्रभावका प्रत्यक्ष अनुभव होगा।

**छन्द सं. ५३१से ५५७तक-** प्रतिदिन भावसहित १० पाठसे जीवनकी संध्याके पूर्व श्रीकृष्ण एवं सखावर्गकी गोचारणलीलाका दर्शन। श्रीसुन्दरीसरोवरका दर्शन। सद्यस्नाता किशोरी राधा एवं सखियोंके सौन्दर्यका दर्शन। ब्रजकिशोर नीलमणिके पूर्वरागकी तत्वरहस्य सहित अनुभूति। 

**छन्द सं. ५५८से ५७५तक-** प्रतिदिन भावसहित १० पाठसे जीवनकी संध्याके पूर्व भगवती पौर्णमासीके दर्शन, उपनन्दपत्नी पीवरी, यशोदामैया, कीर्त्तिदा मैया आदि मातृवर्गकी वात्सल्यवती गोपांगनाओंके दर्शन, समग्र रन्धनलीलाके दर्शन होंगे।

## (सप्तमसे एकादश शतक)
इन शतकोंके प्रतिदिवस भावसहित १० पाठ करनेसे जीवनकी संध्याके पूर्व इन शतकोंमें वर्णित सभी लीलाओंकी अनुभूति होगी।''');
      }
    }
    else if (sectionId == 'topic7') {
  switch (title) {
    case '(क)योऽहं    ममास्ति    यत्किञ्चिदिह   लोके   परत्र  च।':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''## **समर्पण**

## **योऽहं ममास्ति यत्किञ्चिदिह लोके परत्र च।**
## **तत्सर्वं कृष्ण ते नाथ पादपद्मे समर्पितम् ।।**

जो मैं हूँ, मेरा जो कुछ है- लोक और परलोक सभी।
कर अर्पित चरणोंमें तव मैं हुआ पूर्ण कृतकृत्य अभी ।।

## **योऽहं ममास्ति यत्किञ्चिद् विश्वेऽस्मिन्मद् निर्मितम् ।**
## **राधे प्राणेशि तत्सर्वं त्वत्पादयोः समर्पितम् ।।**

जो मैं हूँ, जो कुछ है जगमें दृश्यरूप मेरा निर्माण।
हे प्राणेशि राधिके, सब तव चरण-समर्पित लेना जान।।

## **योऽहं ममास्ति यत्किञ्चिद् विश्वं मच्छासनाश्रितम् ।**
## **राधे प्राणेशि तत्सर्वं त्वत्पादयोः समर्पितम् ।।**

जो मैं हूँ, जो कुछ भी मम है आश्रित-शासित सारा विश्व।
राधे हे प्राणेशि, सभी तव चरणसमर्पित सकल निजस्व।।

**जो भी, जब भी, जैसे, तुमसे मेरी है माँग हुई, प्रियतम !**
**है उसे, उसी क्षण, वैसे ही, तुमने पूरी कर दी, प्रियतम !**
**है सत्य अनन्तकालतक तुम आगे भी, ऐसे ही, प्रियतम !**
**मेरे प्रति यही स्वभाव नाथ ! अपना बरतोगे ही, प्रियतम !**
**है किन्तु मुझे धिक्कार, लाख शत बार सर्वदा ही प्रियतम !**
**न्यौछावर जो मैं हो न सकी केवल सच, तुमपर ही प्रियतम !**
**'मेरे प्राणोंकी रानी हे ! प्रियतमे ! वल्लभे !' हे प्रियतम !**
**सम्बोधित तुमसे नित्य हुई, विगलित पर उर न हुआ, प्रियतम !**
**आँखें न निरन्तर झरीं अहो ! काया पुलकित न हुई प्रियतम !**
**यह भावरहित मृण्मय बोझा कबतक मैं लिये फिरूँ, प्रियतम !**
**'है ब्रजलीला उद्देश्य मुझे लानेका इस तनमें' प्रियतम !**
**कहते हो तुम, फिर क्यों न चलें, खेलें, हो गयी देर, प्रियतम !'''
      );

    case '(ख)मो इच्छित  कै  कृस्न पिय,  रुचै  बनिउ,  बनराउ।':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''## (दोहा)

**मो इच्छित कै कृस्न पिय, रुचै बनिउ, बनराउ।**
**होइ निराविल सर्वथा भाव-उदधि बुड़ि जाउ ।।१।।**

**बिस्वरूप जसुमति-सुअन ! अब विलम्ब जनि लाउ।**
**होइ निराविल एहि छिन भाव-उदधि बुड़ि जाउ ।।२।।**

**बिस्वरूप बिनती धरत अभिनौ सुख बिसराउ।**
**करौ अनुग्रह अब महाभाव-उदधि बुड़ि जाउ ।।३।।**

**बिस्वरूप पिय बेनुधर, साँवर बिरद बढ़ाउ ।**
**करौ तुरन्त कृपा महाभाव-उदधि बुड़ि जाउ ।।४।।**

## (सोरठा)

**मो सुख लगि तुम पीउ, अब लौं कहा नहीं कस्यौ।**
**तुम्हरौ प्यार असीउँ, नित्य अतुल ऐसोइ है।।५।।**

**देख्यौ अद्भुत खेल, इन माटी-पुतरीन कौ।**
**अब तुरन्त दो ठेल, सबननि ब्रज-रस-सिन्धुमें ।। ६ ।।**

## (छन्द)

**हे महामहिम ! हे ब्रजनन्दन ! करुणावरुणालय ! हे प्रियतम !**
**हे कृष्ण ! प्राणवल्लभ ! साँवर ! मुझ राधाके रसिया ! प्रियतम !**
**हे वंशीधर ! मुझ राधाके सुखमें ही बस, सुखिया ! प्रियतम !**
**हे प्राणेश्वर ! मुझ राधाकी नैयाके खेवैया ! प्रियतम !**
**अब ढरौ तुरन्त प्रथम अपने इन दस रूपोंपर, हे प्रियतम !**
**फिर ढरौ तुरन्त विश्वमय निज मद्दृश्य रूपपर, हे प्रियतम !**
**सर्वथा सुखी तुम हो जाओ, खिल उठो फूल-से, हे प्रियतम !**
**पल-पल बढ़ते ही चलो भावसागरकी ओर तथा, प्रियतम !**
**जो दोष न देखे कहीं, कभी, ऐसे हो एक तुम्हीं, प्रियतम !**
**अतएव तुम्हारी प्यारी मुझ राधाकी बिनती है, प्रियतम !**
**यद्यपि आवश्यकता तुमसे कहनेकी थी न किन्तु, प्रियतम !**
**कह गयी और कर गयी, हुई प्रेरित तुमसे बिनती, प्रियतम !**
**कहनेवाली, सुननेवाले दोनों तुम ही तो हो, प्रियतम !**
**यह खेल तुम्हारा नित्य सरस एवं रहस्यमय है, प्रियतम !**
**है लहराता ही रहता वह, संविद-स्वरूप सागर, प्रियतम !**
**उन लहरोंका ही नाम यहाँ संस्थान, सृजन, लय है, प्रियतम !**

## प्रियतम श्रीकृष्णका उत्तर-

**है सदा तुम्हारा ही सुख बस, मेरा तो सुख प्रियतमे ! अहो !**
**मैं कर दूँगा अवश्य पूरी प्रत्येक चाह, निश्चिन्त रहो !**
**हम सभी अभिन्न निरन्तर हैं, फिर भी जो रुचि हो, तुरत कहो।**
**हे महाभावमयि ! हमें लिये, रस-सुधा-सिन्धुमें नित्य बहो।।'''
      );

    case '(ग)सुन्दर  इस  निज चरित्र  छविको  मेरे  उरपर  लिखना, प्रियतम !':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''सुन्दर इस निज चरित्र छविको मेरे उरपर लिखना, प्रियतम !
लिखते लिखते जब कर-पल्लव हो जाय अधिक चिकना प्रियतम !
लेना तुम पोंछ उसे अपने पीले दुकूलमें ही, प्रियतम !
देखूँगी मैं उन चिह्नोंपर सहचरियोंका बिकना प्रियतम !
रजनीको जब विराम देने आयेगी उषा सखी प्रियतम !
आयेंगी तब वे भी निकुञ्ज वातायनके समीप प्रियतम !
होगा फिर द्वार मुक्त भीतर होंगी अपलक सब वे प्रियतम !
बाहर अलिसे मुखरित होगा, फूलोंसे लदा नीप प्रियतम !
मंगल नीराजन होनेपर बाहर लायेंगी वे प्रियतम !
हम दोनोंको उनके पीछे पीछे चलना होगा प्रियतम !
कालिन्दीकी उन लहरों में हमको नहलायेंगी प्रियतम !
उनकी रुचि के साँचे में ही हमको ढलना होगा प्रियतम !
अतएव अभी से सच तुमको इंगित कर देती हूँ प्रियतम !
मैं नित्य अहो रंगस्थलकी जो नित्य नटी ठहरी प्रियतम !
हो नहीं समयसे पहले ही झंकृत यह रंग मंच प्रियतम !
इसलिये बनी बैठी हूँ मैं गूँगी एवं बहरी प्रियतम !'''
      );

    case '(घ)है  पथ  तुलसी वन जोह  रहा हम दोनों का प्यारी  प्रियतम ।':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''है पथ तुलसी वन जोह रहा हम दोनों का प्यारी प्रियतम ।
नीली सरिता हो व्याकुल है कर रही शब्द कल-कल प्रियतम ।
है अपलक बाट निहार रहीं वे वल्लरियाँ फूली प्रियतम ।
सुस्पष्ट दे रही है इंगित सारी शुक पर झूली प्रियतम।।
काँटों की अटवी में मिलकर देरी न करो प्यारी प्रियतम ।
चेरी पर चरण सरोरुह की अविलम्ब ढरो प्यारी प्रियतम ।
नश्वर तन की पगडण्डी पर ठहरो न तनिक प्यारी प्रियतम ।
चलते जाओ, चलती जाओ, रहकर गुमसुम प्यारी प्रियतम ।
जो कहीं अनुज अधिकारी-रुचि या महीपाल-मति का प्रियतम ।
आदर कर परिचय देता जग-सम्बन्ध नेह-गति का प्रियतम ।
वे पहुँच नहीं पाते अब तक सच्चिन्मय मंजिल पर प्रियतम ।
माया का ताप नहीं मिटता, मिलता न कृष्ण तरुवर प्रियतम ।
अग्रज के सद्दृश अनुज तन से जिनका नाता था हे प्रियतम ।
वे पहुँचेंगे ही नित्य जहाँ कान्हा गाता था हे प्रियतम ।।
**इसीलिये विश्वास, किये रहो अविचल अहो ।**
**व्रजपुर नित्य निवास, कुंज-स्थल पर दृग रहें॥**
**उपवन के उस पार हम सब ही मिल जायेंगे**
**माया सरित कगार पर मिलने में हानि है।**'''
      );

    case '(ड़)साँवर-साँवर ही  आगे हैं,  साँवर  ही पीछे हैं, प्रियतम !':
      return const _TopicPageContent(
        imagePaths: [],
        body: '''साँवर-साँवर ही आगे हैं, साँवर ही पीछे हैं, प्रियतम !
साँवर-साँवर ही दहिने हैं, साँवर ही बायें हैं, प्रियतम !
साँवर-साँवर ही नीचे हैं, साँवर ही ऊपर हैं, प्रियतम !
साँवर-साँवर ही अब केवल सर्वत्र अवस्थित हैं, प्रियतम !
है तत्त्व बताया तुमने ही, तुम-ही-तुम हो मेरे, प्रियतम !
हैं या केवल राधा-राधा, फिर नित्य युगल भी हो, प्रियतम !
यह मैं प्रतिबिम्बित है प्रतिमा राधाकी मायामें, प्रियतम !
है किंतु बिम्बसे भिन्न कहाँ सत्ता छायाकी, हे प्रियतम !
राधिकारमण निरवधि जय जय, जय अम्बुजनयन सदा, प्रियतम !
जय सतत नन्दनन्दन जय जय, जय नाथ निरन्तर, हे प्रियतम !
गोपिका-प्राण सर्वदा तथा जय मन्मथमथन अहो, प्रियतम !
चिरकाल विश्वरञ्जन जय जय, जय कृष्ण अहर्निश, हे प्रियतम !'''
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

