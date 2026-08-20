import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/app_provider.dart';
import '../providers/favourites_provider.dart';
import '../providers/reader_provider.dart';
import '../utils/text_formatting.dart';
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
  int? _queuedTopicIndex;
  bool _topicAnimationRunning = false;
  bool _isReading = false;
  bool _sliderActive = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.topics.length - 1).toInt();
    _controller = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().resetFontSize(10);
      }
    });
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

    setState(() {
      _index = newIndex;
      _queuedTopicIndex = newIndex;
      _isReading = false;
    });
    _driveTopicAnimation();
  }

  Future<void> _driveTopicAnimation() async {
    if (_topicAnimationRunning || !_controller.hasClients) return;
    _topicAnimationRunning = true;

    while (_queuedTopicIndex != null && _controller.hasClients) {
      final target = _queuedTopicIndex!;
      _queuedTopicIndex = null;
      await _controller.animateToPage(
        target,
        duration: _topicAnimationDuration(target),
        curve: Curves.easeOutCubic,
      );
    }

    _topicAnimationRunning = false;
  }

  Duration _topicAnimationDuration(int target) {
    if (!_controller.hasClients) return const Duration(milliseconds: 220);
    final current = _controller.page ?? _index.toDouble();
    final distance = (target - current).abs().clamp(1.0, 6.0);
    return Duration(milliseconds: (180 + distance * 34).round());
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
    final savedFontSize =
        context.select<AppProvider, double>((app) => app.fontSize);
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
              tooltip: isSaved ? 'Bookmark हटाएँ' : 'Bookmark करें',
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
                      ? 'Bookmark हटा दिया गया'
                      : 'Page bookmark में सहेज लिया गया',
                );
              },
            ),
            _TopicActionButton(
              tooltip: _sliderActive ? 'Text size बंद करें' : 'Text size',
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
                      savedFontSize: savedFontSize,
                      active: index == _index,
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
            'मुखपृष्ठ पर लौटने के लिए थोड़ी देर दबाकर रखें',
          ),
          onHomeLongPress: _returnHome,
        ),
      ),
    );
  }

  String _sectionTitle(String? sectionId) {
    return switch (sectionId) {
      'topic1' => 'पूज्य श्रीराधाबाबा संक्षिप्त जीवन परिचय',
      'topic2' => 'निवेदन',
      'topic3' => 'अनुक्रमणिका (सार संक्षेप)',
      'topic4' => 'सरलार्थ (प्रियतम काव्य)',
      'topic5' => 'षोडश गीत',
      'topic6' => 'फलश्रुतियाँ',
      'topic7' => 'काव्य-मय सन्देश',
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
  final String subtopicTitle;

  const _TopicHeaderStrip({
    super.key,
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
            label: 'मुखपृष्ठ',
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
      duration: const Duration(milliseconds: 75),
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
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
      onTapUp: widget.enabled ? (_) => _ctrl.reverse() : null,
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
  final double savedFontSize;
  final bool active;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onReadingHeaderChanged;

  const _TopicPage({
    required this.title,
    required this.content,
    required this.index,
    required this.total,
    required this.savedFontSize,
    required this.active,
    this.onTap,
    this.onReadingHeaderChanged,
  });

  Future<void> _copy(BuildContext context) async {
    final footer = content.boldFooter?.trim();
    final text = [
      title,
      TextFormatting.displayPlainText(content.body),
      if (footer != null && footer.isNotEmpty)
        TextFormatting.displayPlainText(footer),
    ].join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Page का पाठ कॉपी हो गया'),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
    }
  }

  // ... (aapke existing variables and _copy method)

  // यह जादुई फंक्शन ** और ## को पहचान कर Bold और Center कर देगा
  Widget _buildFormattedText(
      String text, TextStyle defaultStyle, Color primaryColor) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return SizedBox(height: (defaultStyle.fontSize ?? 13) * 0.38);
        }
        // अगर लाइन '##' से शुरू होती है, तो उसे सेंटर और बोल्ड करें
        if (line.trim().startsWith('##')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 7.0),
            child: Text(
              TextFormatting.displayPlainText(line),
              textAlign: TextAlign.center,
              style: defaultStyle.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: defaultStyle.fontSize! + 2,
                color: primaryColor,
              ),
            ),
          );
        }
        if (line.trim().startsWith('[C]')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              TextFormatting.displayPlainText(line),
              textAlign: TextAlign.center,
              style: defaultStyle, // Yahan 'defaultStyle' hi use hoga (no bold)
            ),
          );
        }
        // बीच में जहाँ ** लगे हैं उसे बोल्ड करें
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
          padding: const EdgeInsets.only(bottom: 3.0),
          child: RichText(
            textAlign: TextAlign.center,
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
          child: active
              ? ValueListenableBuilder<double>(
                  valueListenable: context.read<AppProvider>().fontSizePreview,
                  builder: (context, previewFontSize, _) =>
                      _buildTopicContent(context, previewFontSize),
                )
              : _buildTopicContent(context, savedFontSize),
        ),
      ),
    );
  }

  Widget _buildTopicContent(BuildContext context, double fontSize) {
    final cs = Theme.of(context).colorScheme;
    final textFontSize = fontSize.clamp(AppProvider.minFont, 24).toDouble();
    final defaultTextStyle = GoogleFonts.notoSerifDevanagari(
      color: cs.onBackground,
      fontSize: textFontSize,
      height: 1.62,
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (content.imagePaths.isNotEmpty) ...[
        _TopicImageCarousel(imagePaths: content.imagePaths),
        const SizedBox(height: 14),
      ],
      _buildFormattedText(
        content.body,
        defaultTextStyle,
        cs.primary,
      ),
      if (content.boldFooter != null) ...[
        const SizedBox(height: 16),
        Text(
          content.boldFooter!.trim(),
          textAlign: TextAlign.center,
          locale: const Locale('hi', 'IN'),
          style: GoogleFonts.notoSerifDevanagari(
            color: cs.onBackground,
            fontSize: (textFontSize - 8).clamp(9, 18),
            height: 1.62,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ]);
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
            '''         पूज्यश्रीचक्रधर मिश्र, जिन्हें बाद में श्रीराधा बाबा के नाम से जाना गया, उनका जन्म १६ जनवरी १९१३ को बिहार के फखरपुर गाँव में हुआ था। उनके पिता महिपाल मिश्र एक विद्वान और धर्मनिष्ठ ब्राह्मण थे, और चक्रधर मिश्र (श्रीराधाबाबा) अपने माता-पिता के चौथे पुत्र थे। उनकी माता, अधिकारिणी देवी भी एक अत्यंत पुण्यात्मा थीं।

       बचपन में ही श्रीराधा बाबा ने छह से सात भाषाओं पर योग्यता प्राप्त कर ली थी, जिससे उनकी विद्वता का परिचय मिलता है। यद्यपि, उच्च ज्ञान की उनकी जिज्ञासा ने उन्हें शिक्षा के पार आध्यात्मिकता की ओर अग्रसर किया।

       श्रीराधाबाबा का प्रारंभिक जीवन एक जिज्ञासु के रूप में आध्यात्मिकता के विषयों पर भिन्न-भिन्न तरीकों के अनुसंधान से भरा हुआ था। प्रारंभ में पूज्य बाबा ने वेदांत के मार्ग का अनुसरण किया, जो भारतीय दर्शन का महत्वपूर्ण अंग है जो आत्म-साक्षात्कार और आत्मा तथा ब्रह्मांडीय चेतना की एकता पर बल देता है, और आगे चलकर पूज्य बाबा एक दृढ़ वेदांती बने, जो सत्य की खोज के लिए बौद्धिक रूप से संकल्पित थे।

       यद्यपि, श्रीराधा बाबा के जीवन में एक महत्वपूर्ण मोड़ तब आया जब उनकी भेंट पूज्य श्रीभाईजी (श्रीहनुमान प्रसाद पोद्दार) से हुई। श्रीभाईजी एक महान आध्यात्मिक व्यक्तित्व थे, जो गीता प्रेस गोरखपुर के माध्यम से आध्यात्मिक साहित्य को संपादित और प्रकाशित कर धर्म ग्रंथों का प्रचार करते थे ॥ श्रीराधा बाबा का श्रीभाईजी से संपर्क जयदयाल जी गोयनका के माध्यम से हुआ, जो गीता प्रेस के संस्थापक थे। यही वह समय था जब श्रीपोद्दार जी के संग के प्रभाव से श्रीराधा बाबा 'वेदान्त मार्ग' से 'भक्ति मार्ग' के पथिक बन गए॥

       श्रीराधाबाबा का 'वेदांत मार्ग' से 'भक्ति मार्ग' की ओर परिवर्तन एकदम से नहीं हुआ। श्रीभाई जी के संग के प्रभाव से और भाईजी के मार्गदर्शन से श्रीराधा बाबा की कठोर वेदान्तिक प्रवृत्ति एक कोमल और भावनात्मक भक्ति मार्ग की ओर मुड़ गई, विशेष रूप से भगवान श्रीकृष्ण के प्रति। उन्होंने ब्रज साधना को अपनाया, जो भगवान श्रीकृष्ण के प्रेम और भक्ति में डूबने की साधना है, विशेषकर गोपी और राधाभाव में। यह परिवर्तन श्रीराधा बाबा के जीवन में एक नए चरण की शुरुआत थी। एक कट्टर बौद्धिक से, वे एक कोमल हृदय वाले, भक्ति से पूरित भक्त बन गए, जो श्रीकृष्ण के प्रेम में पूरी तरह डूब गए थे और आगे चल कर राधा भाव से श्रीकृष्ण की उपासना करने के कारण उन्हें श्रीराधा बाबा के नाम से जाना गया।

       श्रीराधा बाबा ने संत श्री चैतन्य महाप्रभु की परंपरा का अनुसरण किया, जो १६ वीं शताब्दी के संत थे और जिन्होंने भक्ति आंदोलन में श्रीकृष्ण के प्रति अपने गहन प्रेम और भक्ति का परिचय दिया। चैतन्य महाप्रभु की तरह, राधा बाबा की 'भक्ति नाम साधना' और 'भाव समाधि' (दिव्य प्रेम में गहन भावनात्मक अभिव्यक्ति) में प्रकट हुई। इन साधनाओं ने उन्हें गहन आध्यात्मिक आनंद की अवस्थाओं में पहुंचा दिया, जहां वे कई दिनों तक बाहरी दुनिया से पूरी तरह अनभिज्ञ रहते थे।

       श्रीराधा बाबा का जीवन कठोर तप और सादगी से भरा था, जो उस समय के संतों में भी दुर्लभ था। उन्होंने अपने पूरे जीवन सख्त अनुशासन का पालन किया, जिसमें वे दिन में केवल एक बार भोजन और जल ग्रहण करते थे। उनका यह सरल और अनुशासित जीवन किसी दिखावे के लिए नहीं था, बल्कि उनके आध्यात्मिक विश्वास की एक अभिव्यक्ति था। उन्होंने कभी धन को हाथ नहीं लगाया और न ही किसी विलासिता का कभी आनंद लिया। भौतिक सुख-सुविधाओं से उनका पूर्ण त्याग उनके आध्यात्मिक आदर्शों का प्रतीक था।

       श्रीराधाबाबा का श्रीभाईजी के साथ गहरा संबंध था, और उनका एक अनोखा आध्यात्मिक संबंध था। वे दोनों गोरखपुर के शांतिपूर्ण और आध्यात्मिक रूप से प्रबुद्ध स्थान गीता वाटिका में साथ रहते थे, जो भक्तों को आकर्षित करता था। जो लोग भाईजी का अनुसरण करते थे, वे स्वाभाविक रूप से श्रीराधा बाबा से परिचित हो ही जाते थे, लेकिन बाबा ने कभी भी अपने लिए अनुयायियों या प्रसिद्धि की चाह नहीं रखी। उनकी विनम्रता इतनी थी कि वे एक उत्कृष्ट लेखक और कवि होते हुए भी अपने कार्यों को अपने नाम से प्रकाशित नहीं करते थे। उनकी पुस्तकों और लेखों को गुमनाम रूप से "एक साधु" के रूप में प्रस्तुत किया जाता था। उनकी भक्ति से ओत प्रोत कविताएँ उनके गहरे आध्यात्मिक अनुभवों की अभिव्यक्ति थीं, लेकिन वे भी बिना हस्ताक्षर के रहीं।

       श्रीराधा बाबा की आध्यात्मिक साधना भगवान्नाम जप पर केंद्रित थी। उनका मानना था कि भगवान के नाम का जप सबसे उच्चतम आध्यात्मिक साधना है और सच्चे विश्वास के साथ की गई प्रार्थना आत्म-साक्षात्कार के लिए सबसे शक्तिशाली साधन है। उनके अनुसार, यदि पूरी भक्ति और विश्वास के साथ प्रार्थना और भगवान का नाम जप किया जाए तो वह कभी असफल नहीं हो सकता।

       श्रीराधा बाबा ने आध्यात्म के उच्च स्तर को प्राप्त किया, लेकिन उन्होंने कभी भी अपने आध्यात्मिक उपलब्धियों को उजागर नहीं किया और न ही कोई शिष्य बनाया। उनकी आध्यात्मिकता और अनुभव बहुत ही व्यक्तिगत थे, और उन्होंने इसके लिए कभी प्रसिद्धि की कामना नहीं की। बाबा की गहरी समाधि अवस्थाओं का साक्षात्कार उनके निकट रहने वाले लोगों ने किया, क्योंकि वे इन अवस्थाओं में कई दिनों तक दुनिया से पूरी तरह से विच्छिन्न रहते थे। यहाँ तक कि उन्होंने लगातार पंद्रह वर्षों तक "काष्ठ मौन" (पूर्ण मौन जिसमें कोई संकेत भी न करना) में बिताया जो अपने आप में एक अत्यंत कठोर साधना है।

       श्रीराधा बाबा का जीवन विनम्रता, भक्ति और त्याग का उदाहरण था। उन्होंने चुपचाप अपने गुरु श्रीहनुमान प्रसाद पोद्दार की छाया में जीवन बिताया और कभी व्यक्तिगत मान्यता की इच्छा नहीं की। उनकी महानता न केवल उनकी आध्यात्मिक उपलब्धियों में थी, बल्कि इसमें भी थी कि उन्होंने इन्हें प्रचारित करने से मना किया। उनकी कृष्ण के प्रति भक्ति, समर्पण और दिव्य प्रेम की काव्यात्मक अभिव्यक्ति 'प्रियतम काव्य' उन साधकों को प्रेरित करती रहती है जो प्रेम मार्ग का अनुसरण करना चाहते हैं।

       हालाँकि उन्होंने कोई औपचारिक शिष्य नहीं बनाए, परन्तु श्रीराधा बाबा की प्रार्थना की शक्ति, भगवान के नाम के जप का महत्व, और एक जीवन जो पूरी तरह से भगवान को समर्पित हो, उनकी शिक्षाएँ आज भी उनके भक्तों के बीच प्रतिध्वनित होती हैं। उनका जीवन एक शक्तिशाली अनुस्मारक है कि सच्ची आध्यात्मिकता बाहरी मान्यता में नहीं, बल्कि दिव्य प्रेम की निरंतर और अडिग खोज में निहित है। उनकी अंतिम इच्छा थी कि वे श्री हनुमान प्रसाद जी पोद्दार की समाधि के पास अपने शरीर को त्यागें और यह इच्छा पूरी हुई। वे संकल्प सिद्ध संत थे जिन्होंने अपनी इच्छा से शरीर का त्याग किया। उन्होंने अपने गुरु श्रीभाईजी को यह वचन दिया था कि वे उनकी (श्रीभाई जी) धर्म पत्नी 'जिन्हें सब माँजी कहते थे' की देखभाल उनके जाने के बाद करेंगे, तब तक जब तक वे शरीर में रहेंगी। पूज्य माँजी के शरीर त्यागते ही, कुछ दिनों बाद पूज्य श्रीराधा बाबा ने 'जाने' का संकल्प कर लिया और अर्थात १३ अक्टूबर १९९२ को हम सभी लोगों के मध्य से उन्होंने सदा के लिए विदाई ली॥

       महाभावनिमग्न श्रीराधा बाबा, जिनका 'अंतःकरण' श्रीराधा हैं, जिनका 'भाव देह' श्रीराधा हैं, जिनकी 'इंद्रियाँ' श्रीराधा हैं, जिनकी 'बुद्धि' श्रीराधा हैं, उनका संक्षिप्त जीवन परिचय कैसे लिखा जा सकता है ? फिर भी उनकी कृपा से ही कुछ अंश यहाँ दिया गया है पर सत्य तो ये है-
''',
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
            '''       स्वामीजीका मौन व्रत आजसे आरम्भ हो गया। इन दिनों स्वामीजीके पास जो लोग बहुत आये गये, जिन लोगोंसे स्वामीजीने बड़ी स्वच्छन्दतासे बात-चीत की, बहुत प्रेमका स्नेहसना व्यवहार किया, बड़ा अमृत उडेला, अब उन लोगोंके मनमें स्वामीजीके न बोलनेकी स्थिति उत्पन्न हो जानेसे क्षोभ होना स्वाभाविक है। अभीकी बात है कि मेरे घरके लोग, इतना ही नहीं, बच्चे और बूढ़े-बूढ़े लोग भी मेरे पास आये और रोने लगे। यह स्वाभाविक ही है। जिनसे लाभ मिला, जिनसे प्यार मिला, जिनसे स्नेह मिला, जिनसे अमृत मिला, उसका स्रोत यदि कहीं बन्द होता-सा दिखलायी दे तो स्वाभाविक ही मनमें क्षोभ होता है। पर स्वामीजीका यह मौन असलमें नया नहीं है। जो लोग बिलकुल नये नहीं हैं, वे जानते हैं कि लगभग दस वर्ष पहले इसी पंडालमें काष्ठमौनकी घोषणा स्वामीजीने की थी।
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
       तीसरी बात इससे भी और अधिक आवश्यक है संतकी सेवाके विषयमें। यह बड़ा सुन्दर है और सराहनीय है कि उनके न बोलनेके कारण हमें बोलीके वियोगमें दुःख होता है, पर जो उनकी सेवा करना चाहते हैं, उनके लिये उचित यह है कि हमने उनसे जो सीखा है, उन्होंने विभिन्न प्रकारसे जो शिक्षा दी है और इन दिनोंमें आने-जानेवाले लोगोंसे जिसके लिये जो उन्होंने कहा है, जैसे तुम सत्य बोला करो, तुम गरीबकी सेवा किया करो, तुम अमुक नामका इतना जप किया करो, तुम इतना पाठ किया करो, उसे अपने जीवनका व्रत मानकर अपने ''',
      );
    }

    // 3. Teesri Subheading add karein
    else if (sectionId == 'topic1' && title == 'श्रीराधाबाबा – जीवनयात्रा') {
      return const _TopicPageContent(
        imagePaths: [],
        body: '''**१.** १६ जनवरी, १९१३**\-** आविर्भाव

**२.** सन् १९२८ से सन् १९३१ तक**\-** राजनैतिक जीवन एवं जेल यात्रा

**३.** सन् १९३२**\-** कलकत्तेमें विद्यालयी शिक्षाका पुनः शुभारम्भ

**४.** १-१-१९३४ से १४-१०-१९३५**\-** भगवान्‌के नाम पत्र लिखना

**५.** १२ अक्टूबर, १९३५**\-** संन्यास-ग्रहण

**६.** अप्रैल, १९३६**\-** संन्यासी वेषमें इण्टरमीडिएटकी परीक्षा

देकर विद्यालयी शिक्षासे विमुखता

**७.** अप्रैल से सितम्बर,१९३६ तक**\-** अज्ञात वास, घोर एकान्त साधना एवं अद्वैत तत्त्वकी दृष्टिसे परम सिद्धि, कोढ़ियोंके मध्य बैठना, स्वामी श्रीरामसुखदासजीसे मिलन एवं सत्संग

**८.** अक्टूबर, १९३६**\-** श्रीसेठजीसे मिलन तथा उनके द्वारा बाबूजीसे मिलनेकी प्रेरणा

**९.** २७ अक्टूबर, १९३६**\-** गीतावाटिकामें सर्वप्रथम आगमन तथा बाबूजीसे प्रथम मिलन, बाबूजी द्वारा चरण स्पर्श एवं चरण-स्पर्शके माध्यमसे साकारोपासनाका बीजारोपण

**१०.** ३० अक्टूबर, १९३६**\-** गीतावाटिकामें इमली वृक्षके नीचे दिव्यानुभूति

**११.** नवम्बर, १९३६**\-** गोरखपुरमें राप्ती नदीके किनारे श्रीहनुमानगढ़ीमें वास करते हुए भगवान् श्रीकृष्णके दर्शन

**१२.** नवम्बर या दिसम्बर,१९३६**\-** श्रीसेठजीके साथ रहना तथा लगभग अढ़ाई वर्षोंतक निरन्तर साथ रहकर श्रीमद्भगवद्गीताकी टीकाके लेखन कार्यमें सहयोग देना।

**१३.** सन् १९३७**\-** गीताप्रेसके एक कमरेमें बाबाके शरीरमें गोपी-वपुका अवतरण एवं तिरोभाव

**१४.** २६ या २७ या २८ अप्रैल,१९३९**\-** बाँकुड़ामें क्षेत्र संन्यासका संकल्प एवं भगवान् श्रीकृष्ण द्वारा क्षेत्र-संन्यासका नवीन अर्थ बतलाया जाना एवं बाबूजीके वपुको 'सचल वृन्दावन' बतलाना।

**१५.** मई, १९३९**\-** फखरपुर ग्राममें श्रीमातृ-चरणके अन्तिम दर्शन

**१६.** ११ मई, १९३९**\-** बाबूजीके साथ नित्य रहनेका संकल्प

**१७.** जून या जुलाई या अगस्त,१९३९**\-** बाबूजीका सूक्ष्म देहसे पधारकर बाबाको 'दीक्षा' देना

**१८.** सन् १९३९ या १९४० में**\-** श्रीमञ्जुलीला-भावकी 'भाव-दीक्षा' (यह प्रथम भाव दीक्षा)

**१९.** २३ अगस्त, १९४१**\-** दिल्लीमें प्रथम बार 'श्रीराधाष्टमी' अति सूक्ष्म रूपसे मनाना

**२०.** सम्भवतः सन् १९४१-४२ में**\-** बाबूजीके संकेतपर प्रवचनका परित्याग एवं मौन व्रत

**२१.** सन् १९४२-४३ में**\-** 'केलिकुञ्ज' की लीलाओंका तथा 'प्रेम-सत्संग सुधा माला' का लेखन

**२२.** सन् १९४३-४४ में**\-** श्रीमञ्जुश्यामा भावकी 'भाव दीक्षा' (यह द्वितीय भाव दीक्षा)

**२३.** सन् १९४४-४५ में**\-** 'राधा' नामके जपसे लगाव

**२४.** १९ सितम्बर, १९४५**\-** गीतावाटिकामें प्रथम श्रीराधाष्टमी उत्सव; श्रीराधाष्टमीके दिन 'श्रीकाम-गायत्री मंत्र' से अर्चना

**२५.** सन् १९४६ से कई वर्षोंतक**\-** 'श्रीकृष्णलीला-चिन्तन' 'जगज्जननी श्रीराधा' आदि-आदि अनेक भावपूर्ण कृतियोंका प्रणयन

**२६.** सन् १९४९-५० **\-** बाबूजीकी आयु-वृद्धिके लिये देवाराधन

**२७.** २६ सितम्बर, १९५०**\-** 'देवर्षिपर श्रीवृषभानुनन्दिनीकी कृपा' नामक नाटिकापर अभिनय

**२८.** सम्भवतः सन् १९५० में**\-** भगवान् श्रीकृष्ण द्वारा भगवती श्रीत्रिपुर-सुन्दरीकी अर्चना करनेके लिये निर्देश

**२९.** २० जनवरी, १९५१**\-** गलेकी हड्डी टूटनेसे भगवती त्रिपुरसुन्दरीकी अर्चनामें विघ्न

**३०.** ९ मई, १९५१**\-** भगवती त्रिपुरसुन्दरी द्वारा निज मंत्रका दान (यह तीसरी भाव दीक्षा)

**३१.** सन् १९५१ से १९५४ तक**\-** अठारह पुराणोंका श्रवण

**३२.** २७ जनवरी,१९५६ से २६ अप्रैल,१९५६ तक**\-** तीर्थयात्रा ट्रेन द्वारा तीन धामोंकी पावन यात्रा

**३३.** १९ अक्टूबर, १९५६**\-** गीतावाटिकामें प्रथम काष्ठ-मौन व्रत

**३४.** ८-९ अप्रैल, १९५७**\-** 'राधा भाव' में प्रतिष्ठा, (यह चौथी भावदीक्षा)

**३५.** १ सितम्बर, १९५७**\-** रतनगढ़में विशिष्ट श्रीराधाष्टमी, 'रसोपासना' के दिव्य मंत्रोंका अलौकिक रीतिसे अवतरण

**३६.** जनवरी, १९५८**\-** मथुरा स्थित बिड़ला धर्मशालामें 'प्रियतम काव्य' के लेखनकी प्रेरणा तथा काष्ठ मौनावधिमें प्रणयन

**३७.** सन् १९६३-६४ में**\-** रासलीला द्वारा 'षोडश गीत' में प्राण प्रतिष्ठा

**३८.** १९ जनवरी, १९६४- भगवती श्रीविष्णुप्रियाजीका जन्मोत्सव मनाना

**३९.** २२ सितम्बर, १९६५**\-** गीतावाटिकामें स्थापित श्रीगिरिराजजीकी परिक्रमाका शुभारम्भ

**४०.** ७ अप्रैल, १९६७**\-** द्वितीय काष्ठ-मौन व्रत

**४१.** २२ मार्च, १९७१**\-** बाबूजीका महाप्रयाण तथा कुटियाका परित्याग

**४२.** १६ फरवरी, १९७५**\-** बाबाकी प्रेरणासे कैंसर अस्पतालकी स्थापनाका संकल्प

**४३.** २६ अगस्त, १९७६**\-** बाबूजीकी समाधिपर बन रहे स्मारकके निर्माण कार्यकी पूर्णतापर हर्षोल्लास

**४४.** २० अगस्त, १९७७**\-** लकवाका झटका

**४५.** ७ दिसम्बर, १९७८**\-** तृतीय काष्ठ-मौन व्रत

**४६.** सन् १९८२ एवं सन् १९८४ में**\-** दो अष्टयाम लीलाओंका आयोजन

**४७.**८ फरवरी,१९८५ से १७फरवरी,१९८५ तक**\-** बाबा द्वारा श्रीडोंगरेजी महाराजकी श्रीमद्भागवत कथाका श्रवण

**४८.** २१ जून, १९८५**\-** श्रीराधाकृष्ण साधना मन्दिरमें प्राण-प्रतिष्ठाका विशद आयोजन

**४९.** ५ अक्टूबर, १९९१ से २३ सितम्बर, १९९२ तक**\-** बाबूजीका जन्म-शताब्दी उत्सव सारे देशमें वर्षभर यत्र-तत्र मनाया गया

**५०.** २६ सितम्बर, १९९२**\-** पूज्या मैयाका महाप्रयाण

**५१.** १३ अक्टूबर, १९९२**\-** पूज्या मैयाके महाप्रयाणके उपरान्त श्राद्ध-कर्मकाण्डकी प्रक्रियाके सम्पन्न होते ही पूज्य बाबाकी महाप्रयाण लीला ॥

राधा राधा राधा राधा''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'महाप्रभु श्रीपोद्दार महाराज') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''       एक होता है रस-मार्ग और दूसरा ज्ञान-मार्ग। दोनों मार्गोंमें तत्त्वज्ञान अपेक्षित है। रस-मार्गका सिद्ध पुरुष तत्त्वज्ञानसे रहित नहीं होता और तत्त्वज्ञानीमें तत्त्वज्ञान रहता ही है, रस चाहे न हो।...... (बाबा) का काष्ठमौन केवल तत्त्वज्ञानमें स्थितिजनित पंचम भूमिकावाला नहीं, क्रियाके अभावके स्वरूपवाला नहीं, अपितु रस-समुद्रके लहरानेके स्वरूपवाला है। 
       (बाबा) के जो अन्तरंग जीवनके सम्पर्कमें आये हैं, उनको मालूम है कि महाभावकी जो अगले स्तरकी चीज है, जिसकी रूप-रेखा शायद गोस्वामी प्रभृत रस-मर्मज्ञों तकने भी नहीं खींची, वैसी चीज इनमें व्यक्त हुई, इनके अनुभवमें आयी।...... इस  प्रकारसे  इनका  काष्ठ-मौन  असलमें  इनका रस-समुद्रमें  निमज्जन है। ...... साधनाके क्षेत्रमें यह एक बड़ी विलक्षण वस्तु है कि जहाँ रस-तत्त्व और ब्रह्म-तत्त्व एक-दूसरेके अ-प्रतिद्वन्द्वी होकर एक साथ एक रूपमें रहते हों। ये रहे हैं पहले। ऐसा नारदादिमें था। भगवान शंकराचार्यमें भी ऐसा माना जाता है, लेकिन ये उदाहरण विरल होते हैं।''',
      );
    } else if (sectionId == 'topic2' &&
        title == 'परम पूज्य श्रीबालकृष्णदासजी महाराज') {
      return const _TopicPageContent(
        imagePaths: [],
        body: '''हरे  राम  हरे  राम  राम  राम  हरे  हरे।
  हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ॥ 
  

  \nसुनि  मेरो  वचन  छबीली  राधा, तैं  पायौ  रस सिंधु अगाधा॥ 
तू  वृषभानु  गोप  की  बेटी,  मोहन लाल रसिक  हँसि  भेंटी। 
जाहि  बिरंचि  उमापति  नाये, तापैं    तें   बन  फूल  बिनाये॥
जो रस नेति-नेति श्रुति भाख्यौ, ताको  अधर  सुधा रस चाख्यौ। 
तेरौ रूप कहत नहीं आवै,   हित  हरिवंश  कछुक  जस  गावै॥ 


       \nश्रीराधारससुधासिन्धुसे आन्दोलित-आह्लादित श्रीराधाचरणनखमणि-चन्द्रच्छटासे आलोकित अलंकृत महाभावनिमग्न श्रीराधाबाबा क्या हैं, हमने इस क्षणतक पहचाना ही नहीं। आप वहीं हैं, यहाँ नहीं, किञ्चत् भी नहीं, कदापि नहीं। आपकी वचनारसामृतधारामें होनेपर प्रतिपग प्रतिक्षण मूर्तिमान माधुर्यरससिन्धुका मिलन-ही-मिलन है, नव-नव लीलारसानुभव है। कोई लालसापूर्ण सौभाग्यवान पुमान् ही आपके वचनसुधारसप्रवाहमें प्रवाहित होकर श्रीराधा-माधव-मिलन-महोत्सवमें सम्मिलित हो सकेगा। श्रीयमुनालहर-समलंकृत निकुञ्ज-मन्दिरमें विक्रीड़ित-विलसित श्रीराधारससुधोन्मत्तके चरण-कमलोंसे चिह्नित रम्य पथमें पूर्णानुगत होकर निज-मधुप-स्वरूपमें पुनः आनेके लिये मधुर संकेत है, उनकी साक्षात्-समीपताका अलभ्य लाभ है, चिरकालतक मधुरसुधारसावगाहन करनेमें मधुर समागम है।
       'प्रियतम' मधुर नाम, बिना श्रीप्रियतमा राधासे मिले, एकाकी रहकर श्रवण कैसे कर सकते थे ? अपने प्रियतम-स्वरूपानुभव कैसे कर सकते थे ? असम्भव, असम्भव । (प्रियतम-प्रियतमा) कोई मधुर नाम लें, यही तो रहस्य संयुक्ततासे ओत-प्रोत आप्लावित है। प्रियतम-प्रसंगोंमें, प्रियतमा-प्रसंगोंमें, दोनोंमें एकको भी देखें तो लीला ही दीखेगी। अनुरंजितमें अनुरंजिता, अनुरंजितामें अनुरंजित । प्रेमका अपार अनुपमेय अवर्णनीय साम्राज्य है यह। संयुक्तताका ही होता है अनुभव श्रीप्रियतमकी चर्चामें। सम्यक् संयुक्ततानुभव कराते हैं प्रियतम । 'प्रियतम' यह मधुर नाम मूर्तिमान प्रियतम-प्रियतमा-परिमण्डित परस्पर-मिलित-रसानुभव है। दूरी व देरीकी कल्पनासे बेसुध करानेवाली, अविलम्ब समीप मिलनेवाली है रूपमाधुरीचर्चा लीलामाधुरीचर्चा।
       युगान्तरों-जन्मान्तरोंके सुदीर्घकालीन अन्तरको भुलाकर चिर रुचिर चारुनिधि प्राणवल्लभ प्रियतम श्रीकृष्णसे हमें मिलने लालासान्वित करती हो, ऐसी है यह अद्वितीय रससुधावर्षिणी-वचनपुष्पमाला 'जय जय प्रियतम'। हमें भी महापुरुषोंकी वाणीमें, चरणचिह्नमें गमन करना है वहीं, जहाँ वे पहुँचनेका संकेत करते हैं। वही उन्मुख गमन करना है। हमें भी वाणीको लेकर वहीं रहना है।
''',
      );
    } else if (sectionId == 'topic2' && title == 'श्रीमती सावित्रीदेवी फोगला') {
      return const _TopicPageContent(
        imagePaths: [],
        body:
            '''       बाबा जैसे शारदाके वरद पुत्रके अनुभूति ग्रन्थ प्रियतम काव्यको मैंने ही लिपिबद्ध किया था। भावोन्मादकी दशामें वे बोलते जाते और मैं लिखती रहती। अन्यान्य भावमयी लीलाएँ तथा पदोंकी संरचना भी पर्याप्त है, जिसे समझना मानवीय विद्या-कौशलके बूतेकी बात नहीं।
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


**एक द्वार रखि कुँअरि ने लीनी पैठ उठाय।** \n**रुचै जो रंचक कीनु पिय, बहिनी, भैया, माय।।**


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

**त्रिगुणरचित यह देह, महाभावमय करि रह्यौ।**
**ऐसो किरपा-मेह बरसायौ पिय साँवरौ ।।**
[R]--(पू. गुरुदेव श्रीराधाबाबा रचित सोरठा)

उनका त्रिगुणरचित देह रहा ही कहाँ था? वह तो कबका ही लहराते, नित्योच्छलित, महाभावसिन्धुकी ऊर्मि बन गया था ! तभी न,

**छाँड्यौ अपनौ नेम, सभी मोर साँचौ कयौं।**
**करै जोग अरु छेम, पिय सौ भयौ न होहिहै।।**

(पू. गुरुदेव श्रीराधाबाबा रचित सोरठा)

मेरे पू.गुरुदेव श्रीराधाबाबाके हृदयेश्वर, प्राणाराम, प्राणाधिक, प्रियतम ब्रजेन्द्रनन्दनका स्वभाव ऐसा ही है। वे अपना न्याय-नियम त्याग देते हैं और अपने आश्रित जनोंके मनोरथको सच्चा बनाकर पूर्ण कर देते हैं। उन मेरे प्रियतम जैसा योग-क्षेमका निर्वाह करनेवाला अन्य कोई हुआ है, न होगा ही।

उन मेरे प्रियतम श्रीकृष्णकी मेरे गुरुदेव श्रीराधाबाबापर अनन्त असीम प्रीतिको परखते हुए ही मेरा पूर्ण विश्वास है कि पू.गुरुदेवके भावजीवनके इस श्रुतिग्रन्थका जो भी पाठक भाव एवं श्रद्धासहित अवगाहन करेंगे, वे निश्चय ही महाभावस्वरूप प्रेमजगतमें प्रवेश पावेंगे।

यह निश्चय है कि मैं एक प्रेमशून्य जन्तु हूँ। ऐसे कृपावाक्य कहने-लिखनेकी मेरी सामर्थ्य सर्वथा नहीं है। किन्तु मेरे गुरुदेवपर उनके प्रियतम प्राणनाथकी प्रीति देखकर ही मैं महाप्रभु पोद्दार महाराजकी चरणरजको साक्षी बनाकर कहता हूँ कि मेरी वाणी अक्षरशः अखण्ड सत्य सिद्ध होगी।

पू.गुरुदेव श्रीराधाबाबा स्वयं और उनका यह लीलाचरित्र दो वस्तुएँ तो हैं ही नहीं। जहाँ पू.गुरुदेवके प्रियतम श्रीकृष्णका नाम, रूप, लीला, एवं धाम चारों वस्तुएँ पूर्ण परात्पर प्रियतम श्रीकृष्णस्वरूप ही हैं तो प्रियतम-प्रिया श्रीराधाका चरित्र प्रिया श्रीराधासे भिन्न कैसे संभव है? अतः मैं पू.गुरुदेव श्रीराधाबाबा रचित निम्न छन्दोंका आश्रय लेकर ही ऐसी मङ्गलमयी वाणीका उच्चारण कर रहा हूँ-

**(दोहा)**

**मो इच्छित कै कृस्न पिय, रुचै बनिउ, बनराउ।**
**होइ निराविल सर्वथा भाव-उदधि बुड़ि जाउ ।।१।।**
**बिस्वरूप जसुमति-सुअन ! अब विलम्ब जनि लाउ।**
**होइ निराविल एहि छिन भाव-उदधि बुड़ि जाउ ।।२।।**
**बिस्वरूप बिनती धरत अभिनौ सुख बिसराउ।**
**करौ अनुग्रह अब महाभाव-उदधि बुड़ि जाउ ।।३।।**
**बिस्वरूप पिय बेनुधर, साँवर बिरद बढ़ाउ ।**
**करौ तुरन्त कृपा महाभाव-उदधि बुड़ि जाउ ।।४।।**

**(सोरठा)**

**मो सुख लगि तुम पीउ, अब लौं कहा नहीं कस्यौ।**
**तुम्हरौ प्यार असीउँ, नित्य अतुल ऐसोइ है।।५।।**
**देख्यौ अद्भुत खेल, इन माटी-पुतरीन कौ।**
**अब तुरन्त दो ठेल, सबननि ब्रज-रस-सिन्धुमें ।। ६ ।।**

**(छन्द)**

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



[L]-प्रियतम श्रीकृष्णका उत्तर-
**है सदा तुम्हारा ही सुख बस, मेरा तो सुख प्रियतमे ! अहो !**
**मैं कर दूँगा अवश्य पूरी प्रत्येक चाह, निश्चिन्त रहो !**
**हम सभी अभिन्न निरन्तर हैं, फिर भी जो रुचि हो, तुरत कहो।**
**हे महाभावमयि ! हमें लिये, रस-सुधा-सिन्धुमें नित्य बहो।।**



**(भावार्थ)**
  


हे प्रियतम ! श्रीकृष्ण ! यदि आपको रुचिकर लगता हो तो मेरी इच्छाके अनुसार रूप धारण कर लीजिये। हे बनराइ (वृन्दावनके राजा), आप संसारगत मायावेश त्यागकर सर्वथा निराविल (निष्कल्मष) होकर भावसमुद्र प्रेमोदधिमें डूब जाइये ।।।१।।

हे विश्वरूप यशुमतिनन्दन ! अब विलम्ब मत करिये। इसी क्षण समग्र कल्मषरहित होकर भावसमुद्र प्रीतिसिन्धुमें डूब जाइये ।। २ ।।

हे विश्वरूप धारण किये मेरे स्वामी! मेरी प्रार्थनाको अपने चित्तमें धारण कर लीजिये। अब इन्द्रियजन्य नये-नये विषयोंमें सुखाशा छोड़ दीजिये। अब अपनी प्रिया मुझ आपकी आत्मापर अनुग्रह करिये एवं प्रीतिके सर्वोच्च सर्वशुद्ध महाभाव समुद्रमें डूब जाइये।।३।।

हे विश्वरूप धारणकिये वेणुधर श्यामसुन्दर ! अपने यशकी अभिवृद्धि करिये एवं मुझ अपनी आत्मापर तुरन्त कृपा करके महाभाव-समुद्रमें डूब जाइये।।४।।

हे प्राणनाथ ! आपने मेरे सुखके लिये अबतक क्या नहीं किया ? आपका प्रेम असीम अनन्त है। वह ऐसा है कि उसकी तुलना कहीं किसीसे हो ही नहीं सकती।। ५ ।।

मैंने इन पञ्चभूतरचित देहोंको धारण करनेवाली मृत्तिकामयी पुतलियोंका अद्भुत खेल खूब देख लिया। अब. तो इन सभी पुतलियोंको आप ब्रज-रस-सिन्धुमें ठेल दीजिये ।।६।।

हे महामहिम ब्रजनन्दन ! हे करुणावरुणालय ! हे कृष्ण ! हे प्राणवल्लभ साँवरे ! हे मुझ राधाके रसिया ! हे वंशीधर ! हे मुझ राधाके सुखमें ही सुखिया ! हे जीवनधन ! हे प्राणाधिक! हे प्राणेश्वर ! हे मुझ राधाकी नैयाके खेवैया ! हे प्रियतम ! सर्वप्रथम आप तुरन्त ही आपके इस दस नामरूप धारण किये स्वरूपोंपर (पू.गुरुदेवके दस प्रमुख कृपापात्रोंपर) अनुग्रहीत होओ एवं तब अविलम्ब अपने विश्वमय मेरे दृश्य बने रूपोंपर कृपालु हो जाओ। हे प्रियतम ! तुम सर्वथा सुखी हो जाओ एवं फूलकी तरह प्रफुल्लित होकर खिल उठो ।। ७ ।।

हे प्रियतम ! तुम प्रतिपल प्रेमके सर्वोच्च भावसमुद्रकी ओर बढ़ते ही जाओ। जो किसीका कभी दोष नहीं देखे ऐसे एकमात्र तुम्हीं हो। इसीलिये तुम्हारी प्यारी मुझ राधाकी तुमसे विनय है। हे प्रियतम ! सर्वान्तर्यामी होनेके नाते तुमसे अपनी प्रार्थना मौखिक कहनेकी यद्यपि कोई आवश्यकता नहीं थी, किन्तु फिर भी मैं तुम्हारे द्वारा ही प्रेरित हुई तुम्हें सबकुछ मौखिक कह गयी एवं प्रार्थना भी कर ही गयी। मैं यह बात भली प्रकार जानती थी कि प्रार्थना करनेवाली भी तुम ही बने हो, और सुननेवाले तो तुम हो ही। प्रियतम! अपने आपसे, अपने आपमें ही यह खेल नित्य सरस एवं रहस्यमय है। रहस्यमय इस अंशमें कि इसके भीतरका मार्मिक सत्य कोई जान नहीं पाता, वह सदैव अज्ञात ही रहता है; एवं सरस इस रूपमें कि दुखरूप क्षणभंगुर रहते हुए भी इसमें सुखाशा बनी ही रहती है। यह संविद् रूप समुद्र (चेतन-जीवमय संसार) लहराता ही रहता है। इस समुद्रकी लहरोंका ही नाम सृजन, स्थिति, एवं प्रलय है।

[L]--प्रियतम श्रीकृष्णका पू. गुरुदेवको उत्तर-

अहो प्रियतमे राधे ! सदैव तुम्हारा ही सुख बस, मेरा सुख है। मैं तुम्हारी प्रत्येक इच्छा अवश्य पूरी कर दूँगा, तुम निश्चिन्त रहो। तुम, मैं, एवं यह सृजन, स्थिति एवं प्रलयरूप जीव-समुदाय सभी परस्पर अभिन्न हैं। फिर भी जो तुम्हारी रुचि हो, तुम तुरन्त कहो। हे महाभावमयि ! तुम मुझे एवं मेरे अभिन्न स्वरूप सृष्टि, स्थिति, प्रलयरूप इस तुम्हारे दृश्यरूप विश्वको साथ लिये रस-सुधा सिन्धुमें नित्य बहती रहो।

\-------

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

इन छन्दोंकी रचनामें कोई क्रम नहीं थी, पर उस क्रमबद्धताके अभावोंमें से एक अद्भुत भवितव्यकी सम्भावना उभरकर सामने उपस्थित हो गयी। ऐसा लगता है कि इस अद्भुत भवितव्यको बाबाके समक्ष प्रस्तुत करनेके लिये किसी अचिन्त्य विधानसे छन्दोंकी रचनामें क्रमबद्धताका समावेश नहीं हो पाया। इस समय जिस प्रकारसे पंक्तियोंकी रचना हुई, उससे बाबाको अनुमान हो गया कि जिस काव्यकी भविष्यमें रचना होनेवाली है, उसके कुल ग्यारह शतक होंगे। प्रथम शतककी आठ पंक्तियाँ, द्वितीय शतककी चार अथवा आठ अथवा सोलह पंक्तियाँ, इस प्रकार प्रत्येक शतककी चार अथवा आठ अथवा सोलह पंक्तियोंकी रचना हो गयी। ग्यारह शतकोंकी आरम्भिक पंक्तियोंकी रचना उसी बिड़ला मन्दिरमें तत्काल हो गयी। क्रमकी विश्रृंखलताने ही संकेत दे दिया कि कुल ग्यारह शतकोंकी रचना होगी।

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
कोऊ प्रीति करें कैसेहू वह अपनो गुन ठानै ॥
भँवर भुजंग काक कोकिल को कबिगन कपट बखानै।
'सूरदास' सरबस जौ दीजै, कारौ कृतहिं न मानै ॥\n\*\*\*\*\*
मीठे बचन सुहाए बोलत, अंतर जारनहार।
भँवर कुरंग काक अरु कोकिल, कपटिन की चटसार ॥
\*\*\*\*\*
मधुप तुम देखियत हो अति कारे।
कपटी कुटिल निठुर निरमोही, दुख दै दूरि सिधारे ॥
\*\*\*\*\*
ऐसी ही कारैन की रीति।
मन दे सरबस हरत परायौ, करत कपट की प्रीति ॥
\*\*\*\*\*
काहें चरन छुवत रस लंपट, हम आगे यह गीत।
'सूर' इतै सौ बार कहा है, जो पै त्रिगुन अतीत ॥

'सूर सागर' में श्रीउद्धवजीसे भ्रमरके मिससे यही कहा गया है- हे दूत ! तुम मेरे चरणोंका स्पर्श मत करो, इसीलिये कि हम सरलाके प्रति तुम्हारी प्रीति कपटपूर्ण है। तुम कपटी हो, कुटिल हो, अकृतज्ञ हो, वंचक हो, लोलुप हो, लंपट हो, अतः दूर ही रहो। तुम मेरे चरणोंका स्पर्श मत करो।

'जय जय प्रियतम' काव्यकी श्रीराधा स्वरूप सर्वथा भिन्न है। महासदाशया श्रीराधा भ्रमरको उपालम्भ नहीं सुनाती, अपितु अपनी उलझनका निवेदन करती है। चरण-स्पर्शकी अभिलाषाकी अभिव्यक्ति होते ही कृष्णप्रेममयी श्रीराधाके हृदयमें भावोंका द्वन्द्व उठ खड़ा होता है और वह द्वन्द्व सीमाका अतिक्रमण करने लगता है। भाव द्वन्द्वके आधिक्यमें युगल चरण संकुचित हो जाते हैं। चरण-स्पर्श-हेतु-उत्सुक दूतसे प्रीति-विगलिता श्रीराधा कहती है-तुम मेरे प्राणधन प्रियतमके प्रिय दूत हो, अतः तुम्हारा और तुम्हारी प्रत्येक अभिलाषाका सम्मान करना ही मेरा परम कर्तव्य है, परन्तु तुम्हारी इस अभिलाषाने मुझे बहुत बड़ी उलझनमें डाल दिया है। एक ऐसी असमञ्जसकी स्थिति उत्पन्न हो गयी है, जिसका समाधान नहीं। मेरे प्राणधन प्रियतमने मुझसे वचन ले लिया है कि इन चरणोंपर एकमात्र मेरा ही स्वत्व रहे अथवा इन चरणोंका स्पर्श वे ही कर पायें, जिनका मन-मति-चित्त-अहं सब कुछ मुझसे एकाकार हो जाये।



हो गद्गद बोले-दान महा प्रियतमे ! मुझे यह दो, प्रियतम !
ये पोंछ चरण असमोर्ध्व रहूँ बड़भागी सुखी सदा, प्रियतम !
मेरी ही स्वत्व रहे इनपर, केवल छुएँ वे ही, प्रियतम !
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

बाबाका यह 'जय जय प्रियतम' काव्य उनकी काष्ठ-मौन अवधिका एक गौरवपूर्ण प्रसाद है। काष्ठ-मौनकी अवधिमें ही पूज्य श्रीबाबाकी श्रीराधाभावमें प्रतिष्ठा हुई। महाभाव-भावित श्रीराधाबाबाकी प्रीतिप्रदायिका परमपुनीता पद-रज-कणिकाको सतत वन्दन है ॥''',
      );
    }
    // --- अनुक्रमणिका (सार संक्षेप) (Topic 3) ---
    else if (sectionId == 'topic3') {
      switch (title) {
        case 'प्रथम शतक':
          return const _TopicPageContent(
              body:
                  '''शतक प्रारम्भ- प० पू० श्रीभाईजीकी धर्मपत्नीकी श्रीमत्त्रिपुरसुन्दरीके रूपमें तथा उनकी सुपुत्री पू० अ० सौ० सावित्रीबाईकी मंजुश्यामाके रूपमें वन्दना।



(१-१२)- पूज्य श्रीराधाबाबा द्वारा बालारूपसे साधनाकी अपनी प्रारम्भिक अवस्थाका चित्रण। श्रीकृष्णके पू० श्रीराधाबाबाके गुरुदेव बनकर आनेका विवरण।
(१३-१५)- श्रीराधारानीके परिवारजनोंका और सखीवर्गका वर्णन।
(१६-२०)- सात वर्षकी आयुमें किशोरीका राधाकाम्यवनसे पुष्पचयन करनेकी अनुमति अपनी मातासे चाहना।
(१७-१९)- राधाकाम्यवनका वर्णन।
(२१-३३)- माता कीर्त्तिदाको युवाकालसे अबतककी सभी घटित घटनावलिका स्मरण हो आना।
(३४-४१)- कुन्दवल्ली-चरित्र
(४२-४५)- युवराज श्रीदामका प्राकट्य
(४६-५५)- श्रीललिताजीकी प्राकट्य लीला
(५६-६२)- राक्षसोंके आक्रमणके भयसे महारानी कीर्त्तिदाका बहन शारदाको तथा समस्त नगरवासियोंको अपने नगरमें बसा लेना.
(६३-८८)- श्रीराधाका जन्म-प्रसंग
(९०)- भगवान् श्रीकृष्णका प्राकट्य
(८९-९६)- श्रीराधानुजा मंजुश्यामाका प्राकट्योत्सव
(९७-१०१)- माता कीर्त्तिदाका उक्त घटनाक्रमका स्मरण, पुत्री राधाके पुनः उद्बोधनसे जगकर उनका पिता श्रीवृषभानुजीकी अनुमति लेना।
सखियोंसहित श्रीराधाका श्रीसुन्दरीवनकी ओर प्रस्थान.
''');
        case 'द्वितीय शतक':
          return const _TopicPageContent(
              body: '''(१०२-१०७)- श्रीवृन्दावनकी शोभा एवं महिमाका वर्णन.

(१०८-११०)- गिरिराज श्रीगोवर्धनकी सुन्दरता एवं माहात्म्यका वर्णन
(१११-१२२)- श्रीललिताकुंजका वर्णन.
(१२३-१३०)- श्रीविशाखाकुंजका वर्णन.
(१३१-१३८)- श्रीचित्राकुंजका वर्णन.
(१३९-१४६)- श्रीइन्दुलेखाकुंजका वर्णन.
(१४७-१५४)- श्रीचम्पकलताकुंजका वर्णन.
(१५५-१६२)- श्रीरंगदेवीकुंजका वर्णन.
(१६३-१७०)- श्रीतुंगविद्याकुंजका वर्णन.
(१७१-१७८)- श्रीसुदेवीकुंजका वर्णन.
(१७९-१८६)- श्रीराधाकुण्डका विवरण.
(१८७-१९४)- श्रीकृष्णकुण्डका विवरण.
(१९५-१९८)- श्रीसूर्यकुण्डका विवरण.
(१९९-२०२)- जावट ग्राम एवं उसके वासियोंका वर्णन.
''');
        case 'तृतीय शतक':
          return const _TopicPageContent(body: '''**पूर्वराग**
(२०३-२०६)- राधाकिशोरीका सब सखियोंसहित श्रीसुन्दरीवनकी सीमामें प्रवेश.
(२०७-२१०)- विविध पक्षी दलों द्वारा श्रीकिशोरीका स्वागत.
(२११-२२३)- मानवभाषा-भाषी शुक द्वारा किशोरीका स्वागत एवं किशोरीका उसे स्नेहदान.
(२२४-२३३)- शुक द्वारा श्रीसुन्दरीवन एवं श्रीसुन्दरीसरोवरकी शोभा एवं महिमाका वर्णन। श्रीयंत्र का वर्णन एवं महिमा-प्रकाश.
(२३४-२३७)- सखियोंका सरोवरके जलपानसे निद्रित हो जाना.
(२३८-२४२)- श्रीराधा एवं अनुजा मंजुश्यामाका वनकी अधिष्ठात्री वृन्दाके आवासमें आतिथ्य
(२४३-२५०)- हंस तथा हंसिनीकी गूढ़ वार्त्ता.
(२५१-२६१)- निकुंजमें नील-गौर दम्पत्तिका परस्पर शृंगार-स्पर्धामें हार-जीतका अनिर्णय
(२६२-२७३)- प्रिया-प्रियतमका शिव-शिवारूपमें श्रृंगार.
(२७४-२७६)- परस्पर शोभादर्शनसे उत्पन्न उमड़े रससिन्धुमें दोनों महादेव-महादेवीका निमज्जित होकर अपरिमित कालके उपरान्त उच्छलन.
(२७७-२८८)- महादेवीका महादेवसे प्रथमतः उत्तरतटकी, फिर पश्चिम वनस्थलकी, फिर दक्षिणवनकी तथा अन्तमें पूर्वकी गतिविधिके सम्बन्धमें जिज्ञासा करना। महादेवका सब दिशाओंका विवरण बताकर ध्यानस्थ हो जाना
(२८९-२९८)- राधाकिशोरीका हंससे नित्यदम्पत्तिके पास पहुँचनेका मार्ग पूछना तथा हंसका दो विभिन्न पथोंका विवरण देना.
(२९९-३०३)- हंस-हंसिनीका उड़ जाना और किशोरीका अनुजा मंजुश्यामाको सोयी पाकर वनमें अकेले ही बढ़नेका निर्णय।
''');
        case 'चतुर्थ शतक':
          return const _TopicPageContent(
              body: '''(३०४-३०५)- वनमें स्थित परम शोभामय उद्यानका वर्णन
(३०६-३०८)- वेदीपर स्थित वेणुधारी बालककी नील-प्रतिमाका वर्णन.
(३०९)- श्रीराधाकिशोरीकी अनिर्वचनीय सुखद अनुभूतिका विवरण
(३१०-३१७)- प्रतिमातक जानेका किशोरीका उद्योग तथा प्रतिमा-द्वारा मार्ग-निर्देशन.
(३१८-३२२)- किशोरीमें यौवनोचित भावोंका उन्मेष होकर उनका प्रतिमाके गलेमें सुमनोंका हार पहनाकर आत्म-समर्पणके भावसे उसके चरणोंमें लुढ़क जाना
(३२३-३२६)- किशोरीका भुजा फैलाकर प्रतिमासे आलिङ्गन करना तथा प्रेमके निगूढ़ अन्तर्भावोंमें उसका संतरण.
(३२७)- प्रिया श्रीराधाकी उद्यानमें स्थित नीलमणि-प्रतिमासे स्नेहस्थापना ही आधारभूमि थी जिसपर प्रेमकी आठमंजिला अट्टालिकाका निर्माण होना.
(३२८-३३३)- अनुजा मंजुश्यामाका किशोरीके पास चले आना तथा प्रतिमाके विषयमें मौसीसे जो जानकारी मिली थी उसे किशोरीको बताने लगना.
(३३४-३४०)- नन्दनन्दन जिन वनोंमें सखाओंसहित गोचारण करते हैं उन वनोंका स्वामी कौन है इस विषयमें सखाओंमें जिज्ञासा होना, नन्दनन्दनका स्वयंको सभी वनोंका अधिपति बताना, मधुमंगलका उपहासपूर्वक इस उक्तिका खण्डन करना, मधुमंगलका परिचय, मधुमंगल द्वारा वृषभानुजीको सभी वनोंका राजा बतलाना
(३४१-३५२)- अपने सखा श्रीकृष्णकी कही बातको सत्य सिद्ध करनेके लिये वृषभानुपुत्र श्रीदामका अपने पितासे आग्रह करके उसी रात्रिमें सभी वनोंका दानपत्र श्रीकृष्णके नाम लिख देनेका आग्रह
(३५३)- वृषभानुजीका दूत भिजवाकर अपने कुलगुरु भागुरि ऋषिको बुला भेजना.
(३५४-३५७)- भगवान् सूर्यदेवके आदेशसे नीलसरोवरके तलसे महर्षि भागुरिका दो वस्तुएँ - नीलमणिप्रतिमा तथा स्वर्णपत्रमें पूर्वतया अङ्कित दानपत्र प्राप्त करना तथा उन्हें लेकर भानुनगरकी ओर प्रस्थान.
(३५८-३५९)- भगवान् नारायणके आदेशसे नन्दरायजीका भी अपने कुलगुरु सहित वृषभानुपुरकी ओर चलकर वहाँ पहुँच जाना.
(३६०-३६१)- दोनों कुलगुरुओंकी सम्मति से सुन्दरीवाटिकामें नीलप्रतिमाकी स्थापना तथा स्वर्णपत्रांकित दानपत्रका प्रतिमाके नीचे जड़ दिया जाना
(३६२)- संगिनी सहित नन्दरानी यशोदाका भी प्रतिमाके दर्शन करने नन्दभवनसे आना.
(३६३-३६४)- प्रतिमा एवं उद्यानकी अलौकिकताका वर्णन.
(३६५)- गुरुदेव भागुरि द्वारा ही श्रीराधाके सात वर्षकी वय प्राप्त होने तक दोनों कन्याओं श्रीराधाकिशोरी एवं उसकी अनुजा मंजुश्यामाको सखियों सहित इस वनकी सीमामें प्रवेश न करने देनेका आदेश कीर्तिदा मैयाको दिया जाना.
(३६६-३७१)- पुरानी घटनावली बतलाते हुए अनुजा मंजुश्यामा द्वारा श्रीराधाको प्रतिमाके नीचे जटित स्वर्णपत्र दिखलाना.
(३७२-३७४)- किशोरीका सखियोंकी स्मृति करना तथा उनके आनेपर उनके साथ वनसे लौट चलना
(३७५-३७६)- पथमें ही शुकपक्षीका आकर किशोरीको नीलप्रतिमामें विराजित नीलदेवका सन्देश सुनाना.
(३७७-४०१)- किशोरीका अपने प्रासादमें पहुँचना तथा उत्कट प्रेमावेशकी दिनों-दिन अभिवृद्धि होना। किशोरीकी विरहानुभूतिकी चरम दशामें उसके नेत्रोंसे चालीस प्रहर दो घड़ी पर्यंत अविरल अश्रुपात होना.
(४०२-४०३)- अचानक कीर पक्षीका आकर किशोरीको नीलदेवताका यह सन्देश सुनाना कि 'अब किशोरीका उनसे नित्य मिलन होगा'
(४०४)- यह सुख-सन्देश सुनते ही किशोरीके मुमूर्षु प्राणोंमें नवजीवनका संचार हो जाना, सर्वत्र सुखकी लहरोंका व्याप्त हो जाना.
''');
        case 'पंचम शतक':
          return const _TopicPageContent(
              body: '''**महर्षि दुर्वासा द्वारा श्रीराधाको वरदानकी प्राप्ति**
(४०५)- वृषभानुपुरमें परात्पर महाशक्तिके अवतरणकी सूचना पाकर महर्षि दुर्वासाका वृषभानुनृपतिके यहाँ अतिथिरूपमें पधारना.
(४०६)- महाराज-महारानी द्वारा उनकी अभ्यर्थना-पूजन तथा महर्षिका वहाँ सोलह प्रहर रुकनेका संकेत.
(४०७)- महाराजका उन्हें अपनी पुत्रियों श्रीराधा एवं मंजुश्यामाके सर्वाधिक सुविधापूर्ण आवासमें ठहराना। महर्षिका एक प्रहरके लिये एकान्तमें ध्यानस्थ होनेका संकेत देना
(४०८-४१०)- भयभीत महाराजका कुलदेवीकी प्रतिमाके सम्मुख प्रार्थना करना, महादेवीका उन्हें अपनी दोनों पुत्रियोंको महर्षिकी सेवामें नियुक्त करने तथा महर्षि के आगमन से उनका कल्याण होने का संकेत देना.
(४११-४१३)- महर्षिके समाधिसे उत्थान होनेपर महाराजा-महरानीका दोनों कन्याओं सहित यही निवेदन करना, महर्षिका कन्याओंके दर्शन होते ही रोमांचित होकर आसन त्यागकर करबद्ध मुद्रामें खड़े हो जाना, मंजुश्यामाके हँसने लगनेपर भी मुनिका कुपित न होकर उसे वैसे ही करने देनेका रानीको आदेश देना। महर्षिके दोनों नेत्रोंसे अविरल अश्रुपात होने लगना.
(४१४-४१८)- भावसमाधिमें महर्षिका छप्पन महीने, एक दिवस पूर्वकी वसंतपञ्चमीके दिन भानुपुर एवं नन्दग्रामके नर-नारियों द्वारा यमुनातटपर उत्सव तथा पंचदेवोंके पूजनकी घटना मानसनेत्रोंसे देखने लगना.
(४१९-४२१)- महारानी कीर्त्तिदाका अनुजाकी गोदमें अपनी शिशु कन्या श्रीराधाको सौंपना, मौसीका मनोरथ करना कि श्रीराधाकी एक और सहोदरा जन्म ले, आकाशवाणी द्वारा इस मनोरथका अनुमोदन होना.
(४२२-४४४)- श्रीराधाका मौसीकी गोदसे उतरकर ताली बजाकर गाने लगना तथा होलीकी धूमधाममें भीड़से घिर जाना, अचानक शिशु नन्दनन्दनका वहाँ आकर उसे भीड़में दब जानेसे बचाना, कीर्त्तिदाके मनमें अभिलाषा जगना कि इस साँवरी आकृतिकी कोई कन्या जन्म ले जो मेरी श्रीराधाकी अहर्निश देखभाल-सुरक्षा करे, अचानक जगज्जननीका आकाशमें प्रकट होकर इस मनोरथका अनुमोदन करना, इसी दैवी विधानसे कीर्त्तिदाकी कोख से मंजुश्यामाके प्राकट्यकी भूमिकाका निर्माण होना.
(४४५-४४६)- अतीतकी इस घटनाके दर्शनके बाद महर्षिको इन दोनों कन्याओंमें पराशक्तिके ही दर्शन होने लगना, मुनिके संकेतसे रानी-राजाके कक्ष से बाहर चले जाने पर एकान्त में महर्षि का स्तवन करने लगना.
(४४७-४५७)- अनुजा मंजुश्यामा द्वारा वाचालता प्रकट करते हुए महर्षिको आत्मीयताके बन्धनमें आबद्ध कर लेना.
(४५८-४६८)- दोनों भगिनियोंका महर्षिको मध्याह्नमें सरोवर ले जाकर नहलाना तथा किशोरीका खीर रन्धनकर अपने हाथों महर्षिको खिलाना
(४६९-४७४)- लाडिली द्वारा महर्षिका नीराजन करना, किन्तु भावावेशमें भरे महर्षिका नीराजनपात्रको अपने हाथोंमें ग्रहणकर लाडिलीकी प्रदक्षिणा एवं भावनृत्य करने लग जाना
(४७५-४७७)- दोनों बहिनोंका महर्षिको सन्ध्यापूजनके लिये सरोवरतटपर ले जाना। वहाँ महर्षिको सर्वत्र इन दोनों कन्याओंका ही दर्शन होने लग जाना.
(४७८-४८३)- मुनिवरकी अखण्ड समाधि लग जाना, दोनों कन्याओं द्वारा उनकी सम्हाल, शुक्ला षष्ठीकी रात्रिसे महाष्टमीके प्रातः कालतक दुर्वासाजीका समाधिमग्न रहना.
(४८४-४८९)- समाधिसे जागकर मुनिका दोनों राजपुत्रियों सहित वृषभानुजीके पास आना तथा दोनों कन्याओंकी सेवाकी भूरि-भूरि प्रशंसा करना
(४९०-४९२)- महर्षि द्वारा किशोरीको वरदान देना कि इसके द्वारा निर्मित भोज्य सामग्री तत्क्षण सर्वरोगहर, अक्षय तथा अनुपम सुस्वादु होगी। साँवरीकी मनोभिलाषाके अनुरूप महर्षिका अग्रजा श्रीराधामें ही उसकी प्रीति निरन्तर अभिवृद्ध होती रहे यही वरदान देकर चलनेको प्रस्तुत होना.
(४९३-४९६)- विदा करते हुए महाराजा, महारानी, दोनों राजपुत्रियों तथा स्वयं महर्षिका भी रोने लग जाना। इस रुदनको कोई नियामक महाशक्ति नहीं रोकती तो विकलतावश इस सम्पूर्ण दृश्यप्रपंचकी दसवीं दशा हो जाती। विदा होकर महर्षिका वनस्थलमें प्रविष्ट हो जाना.
(४९७-५०३)- एक वर्ष पश्चात् आयी शारदीय महाष्टमीको महर्षि भागुरि द्वारा संदेश भिजवाना कि विविध गोरस एवं भोज्य सामग्री सखियों सहित दोनों कन्याओंके हाथ ही आश्रममें भिजवा दें.
(५०४-५०५)- लौटते समय रविकुण्डमें साँवरी मंजुश्यामा द्वारा नहानेकी इच्छा प्रकट करना किन्तु सब सखियोंके अनुमोदनसे सन्निकटस्थ सुन्दरीसरोवरमें पहुँचकर निर्विघ्न स्वच्छन्द जलकेलि करने लग जाना.
''');
        case 'षष्ठम शतक':
          return const _TopicPageContent(body: '''**श्रीकृष्णका पूर्वराग**
(५०६)- शरदऋतुके प्रातः कालमें व्रजप्रदेशकी अपूर्व शोभा, नन्दभवनमें नन्दनन्दनकी प्रभातकालीन लीला, वेणुवादन करते श्यामसुन्दरका सखाओं एवं गोसमूह सहित वनके लिये प्रस्थान.
(५०७-५३०)- नन्दनन्दन द्वारा सखाओंके समक्ष वंशीवादनका सूर्य-चन्द्र, सरिता-पर्वत, पशु-पक्षी, चर-अचरपर, यहाँ तक कि पंचतत्त्वोंपर भी चमत्कारिक प्रभावका प्रदर्शन.
(५३१-५३३)- सुन्दरीसरोवरमें सखियों सहित श्रीराधाकिशोरीका उन्मुक्तवेश होकर स्वच्छन्द जलकेलि। भीगी अलकों द्वारा श्रीराधाकिशोरीके आननका बार-बार आवृत हो जाना। सुन्दरी-सरोवर पहुँचकर त्रिभुवन-मनमोहन श्रीकृष्णकी भी गति अवरुद्ध हो जाना.
(५३४)- नन्दनन्दनका कासारमें जलक्रीड़ारत किशोरी एवं सखियोंका अपलकभावसे दर्शन करते हुए स्तब्ध रह जाना। नन्दनन्दनमें किशोरीके दर्शनसे पूर्वराग-महाभावका उदय होना.
(५३५-५३७)- सखाओंके द्वारा ध्यानभंग किये जानेपर श्यामसुन्दरका उल्लासरहित होकर वनपथपर आगे बढ़ जाना.
(५३८-५४०)- सखाओंके क्रीड़ा-कौतुकमें, सहभोजनकी छीन-झपटमें तथा गौओंको स्नेह-दुलारदानमें भी नन्दनन्दनका गंभीर एवं अन्यमनस्क बने रहना.
(५४१-५४२)- श्रीकृष्णकी इस दशाको सखाओं द्वारा उनकी हुई किसी भूलका परिणाम अथवा किसी दुष्ट ग्रहके प्रभावके कारण हुई मानकर उसके परिहारका उपाय करने लगना.
(५४३)- श्रीकृष्णकी मनस्थितिका यह परिवर्तन श्रीराधाके साथ दृष्टि-विनिमयके उपरान्त हुआ है यह अनुमानमात्र श्रीकृष्णके सखा श्रीदाम एवं सुबलको होना.
(५४४-५५८)- श्रीकृष्णके पूर्वराग-महाभावके विकाससे उनकी भोजन-ग्रहणमें अरुचि, सर्वकालिक उल्लासरहित गंभीरता एवं किसी भी पीली वस्तु आदिसे उद्दीपनादि विभावोंका प्रकाश होना.
(५५९)- गैरिकवसना कल्याणमयी भगवती पौर्णमासीका परिचय.
(५६०-५६१)- सखा श्रीदाम एवं सुबल द्वारा श्रीकृष्णकी इस दशाके उपचार हेतु भगवती पौर्णमासीजीके आश्रममें जाकर उन्हें इस परिस्थितिको निवेदन करना.
(५६२-५८२)- पौर्णमासीजीका यशोदाजीके पास नन्दग्राम पहुँचना, श्रीकृष्णके नैरुज्यका उपाय पूछने उनका कीर्त्तिदा मैयाकी वृद्धा माँके पास यशोदाजीकी जिठानीको भिजवाना.
(५८३-५८६)- महर्षि दुर्वासा द्वारा श्रीराधाकिशोरीको प्रदत्त वरदानकी स्मृति करके वृद्धा-द्वारा श्रीराधाकी निर्मित रसोई नन्दनन्दनको खिलानेका उपाय बताना.
(५८७-५९४)- यशोदाजीके द्वारा अपनी जिठानी प्रभावतीको बरसाने महारानी कीर्त्तिदाके पास भिजवाना, कीर्त्तिदाका तत्काल श्रीराधाको अनुमतिके लिये पितामही सुषमाजीके पास ले जाना, वृद्धा पितामही द्वारा यह निर्णय किया जाना कि श्रीराधा द्वारा निर्मित एक कटोरी खीर प्रभावतीके हाथों अभी भिजवा दो, कलसे पितामहकी आज्ञा प्राप्त करके श्रीराधाको नित्य प्रातः काल रन्धनकार्यके लिये नन्दसदन भिजवा दिया जायेगा। उस खीरके खानेके प्रभावसे नन्दनन्दनकी समस्त उल्लासहीनताकी समाप्ति हो जाना, साँवरके स्वस्थ होनेके संवादसे व्रजवासियोंमें सर्वत्र हर्षकी लहर.
(५९५-६०२)- प्रातःकालमें सखियों सहित श्रीराधाकिशोरीका पितामह महीभानुजीसे नन्दसदन जाकर रन्धनकार्य कर आनेकी अनुमति माँगने जाना, अपनी दोनों पोतियों - श्रीराधाकिशोरी एवं मंजुश्यामाके दर्शनसे महीभानुजीमें दिव्य वात्सल्यका उद्रेक होकर प्रीति-महासिन्धुमें उनका निमज्जित हो जाना.
(६०३-६०६)- लाडिली द्वारा ब्रजेश-भवनमें सरस रसोईका निर्माण करके घर लौटना तथा प्रसन्नमन साँवरका वेणुवादनपूर्वक गोचारण हेतु वनके लिये प्रस्थान
''');
        case 'सप्तम शतक':
          return const _TopicPageContent(
              body:
                  '''**श्रीराधाकिशोरी-द्वारा स्वप्नमें परकीया-महाभावरसकी अनुभूति**
(६०७-६१२)- नन्दसदनसे रन्धनकार्यकर लौट रही श्रीराधाका सखियोंके आग्रहसे दिव्य कदम्बतरुके तले कुछ क्षण विश्राम करते हुए ही स्वप्न देखने लग जाना। स्वप्नमें उनका परकीया-महाभावानुभूतिमें निमग्न हो जाना। परकीया-महाभावका निरूपण.
(६१३)- भगवती योगमाया-द्वारा नवीन रंगस्थलका उद्घाटन.
(६१४)- श्रीराधाकिशोरी द्वारा स्वप्नके प्रारंभमें उसी दिव्य घटनाका स्मरण हो आना जिसमें नन्दरायजीका शिशु बालकृष्णको गोदमें लिये वनमें गोनिरीक्षण हेतु चले आना, अचानक भीषण झंझावात एवं वर्षाका प्रारंभ हो जाना, सामने ही वृषभानुकन्या श्रीराधाका दर्शन होना, नन्दरायजीका श्रीकृष्णको उनकी सुरक्षामें सौंप देना, वृन्दावनकी भूमिमें गोलोकके दिव्य रासमण्डलका प्रकट होना, श्रीकृष्णका नवकिशोरवेषमें श्रीराधाको उनकी नित्य गोलोकगत स्वरूपकी स्मृति कराना, विधाता ब्रह्माजीका प्रकट होकर विधिपूर्वक रासवेदीमें दोनोंका पाणिग्रहण-संस्कार सम्पन्न कराना। तदनन्तर श्रीराधाका पुनः बालवेषमें श्रीकृष्णको यशोदाजीको सौंपकर अपने गृहकी ओर प्रस्थान करना.
(६१५)- स्वप्नमें उनको नन्दनन्दनसे अपने नित्य सम्बन्धकी विस्मृति हो जाना
(६१६-६२९)- द्विरागमनके लिये श्रीराधाका अनुजा मंजुश्यामाके साथ दुर्मदके निर्देशनमें जाना, रविसेतुके आनेपर श्रीराधाका रविमन्दिरके दर्शनार्थ जाना, वहाँ कुछ काल एकान्त पाकर श्रीराधाका अपनी हृदय-व्यथाका अनुजाको बताना, अनुजाका क्रन्दन, दोनोंका परस्पर धैर्यदान, दोनोंका ससुरालके ग्राममें पतिगृहमें प्रवेश, किशोरीके द्वारा कुलदेवीका पूजन, वृद्धा सासके चरणोंमें शिर टेककर प्रणाम करना.
(६३०-६३९)- श्रीराधाकिशोरीका अचानक मूर्च्छित हो जाना, अनेक उपचारोंसे उनका संज्ञालाभ करना, भगवती पौर्णमासीजीका शुभागमन, उनका कूटभाषामें किशोरीको धैर्यदान, पौर्णमासीजीका नियमपूर्वक श्रीराधासे द्वादशवर्षीय सूर्यपूजा करवाये जानेके विधानका उसकी सास-द्वारा अनुमोदन, श्रीराधाकी सूर्यपूजा प्रारंभ होना.
(६४०-६५४)- दूसरे दिन सखियों सहित श्रीराधाका उद्यानमें पूजाके लिये पुष्पचयन करना, सखीके मुखसे उद्यानका नाम कृष्णक्रीड़ाकानन बतलानेसे 'कृष्ण' नाम सुनते ही श्रीराधाका भावावेशमें घर लौट जाना, अनाहार, निद्राका अभाव तथा भावावेशकी वृद्धि होना, अनुजा मंजुश्यामा-द्वारा सामयिक सेवा एवं सम्हाल.
(६५५-६६१)- सन्ध्यासमय किशोरीको वनमें गूँजती वंशीध्वनि सुनाई पड़ना, किशोरीका चित्त उस वंशीरवमें तल्लीन हो जाना, वंशीवादकके प्रति उसके हृदयका पूर्ण समर्पण हो जाना, भावावेगके कारण देहकी ही विस्मृति हो जाना, अनुजा मंजुश्यामा द्वारा सामयिक सेवा एवं सम्हाल करते रहना
(६६२-६६९)- अपराह्नकालमें सहचरी द्वारा किशोरीको नन्दनन्दनका चित्रपट दिखलाना, चित्रांकित छविका दर्शन करते ही बालामें उस बालकके प्रति आत्मसमर्पणके भाव जागना, भावदशामें उन्मादके लक्षणोंका प्रकट होना.
(६७०-६७९)- 'कृष्ण' नामधारी, मुरलीवादक एवं चित्रांकित छविवाले तीन विभिन्न व्यक्तियोंके प्रति आत्मसमर्पणके कारण अपनेको अपराधिनी मानकर बाला श्रीराधाका सहचरियोंके सन्मुख विलाप, सखी द्वारा यह समाधान पाकर कि ये तीन न होकर एक नन्दनन्दन ही हैं, बालाका संतोष-लाभकर सखीकी गोदमें सो जाना.
(६८०-६८६)- सखी द्वारा नन्दनन्दनको किशोरीके भावोंका परिचय करानेके अनेक प्रयत्न करना, श्रीकृष्णका उदासीनता दिखाना, अन्ततः किशोरी-द्वारा उन्हें अपने भावोंको दर्शाते हुए एक पत्र भिजवाना किन्तु निराशा ही हाथ लगना.
(६८७-६९५)- अगले जन्ममें मिलनकी आशासे किशोरीका देह-विसर्जनके लिये यमुनातट पहुँचना, सहचरीका आ जाना, किशोरीका उसे गाढालिंगनमें लेकर विलाप करना, अन्तिम दर्शनके लिये किशोरीकी सहचरीसे चित्रपटकी माँग किन्तु वह भी उस समय न मिलनेसे घोर निराशाकी प्राप्ति तथा दोनोंका क्रन्दन करने लगना.
(६९६)- अचानक नन्दनन्दनका वहाँ चले आना.
(६९७-७०६)- प्रिया-प्रियतम तथा सखीको उस मिलनमें जो अनिवर्चनीय सुख हुआ उसका चित्रण आजतक कोई नहीं कर सका है, दोनोंके अविरल अश्रुधारा-विमोचनसहित मिलनके दर्शनसे ही सहचरीके मनमें उठी प्रियतम प्रति रोषकी रेखा धुल गयी, उसका भी प्रेमसुखमें अश्रुधारा बहाने लगना.
(७०७)- राधाकिशोरीको इस स्वप्नके अन्तरालमें ही एक और स्वप्न भी हुआ था (उसका विवरण अगले आठवें शतकमें है).
''');
        case 'अष्टम शतक':
          return const _TopicPageContent(
              body:
                  '''(७०८)- प्रभातकालमें शयनकक्षमें उषासुन्दरीका प्रिया-प्रियतमको जगाना, उनका मिलन स्वप्नमात्र है अथवा वास्तविक इसी शंकामें दोनोंका पूरी रात सो न पाना.
(७०९)- प्रियाके मुखपर छितराई कुन्तलराशिका साँवर द्वारा सहेज दिया जाना, प्रिया-प्रियतमका वेष ही नहीं, स्वरूप भी एक दूसरेमें परिवर्तन हो जाना.
(७१०)- सहचरियोंके आनेकी कंकण-ध्वनि सुनायी देना। शयनकक्षमें आकर उनका प्रिया प्रियतमकी शोभापर न्यौछावर होना.
(७११)- मंगल-नीराजन, सखियोंकी समर्पणमयी सेवासे प्रिया-प्रियतमके मनमें 'हम तुम्हारे प्रेम ऋणसे कभी उऋण न हो सकेंगे' ऐसे भाव उमड़कर नेत्रोंमें प्रेमाश्रु छलक आना.
(७१२)- सौरभका उपहार लेकर शीतल समीरका प्रिया-प्रियतमसे वनपथपर पधारनेकी मनुहार करना
(७१३)- प्रिया-प्रियतमका शयनकक्षसे बाहर आना, रंगिणी मृगीका उनके समीप दौड़ी आना, रंगिणी मृगीका आत्मपरिचय, उसे उन्मादिनी गोपीका दर्शन होना
(७१४-७१६)- वृन्दावनधाममें विराजित काल-सत्ता, चकवा-चकवीका रसमय संवाद.
(७१७-७१९)- वनकी शोभा निहारते हुए प्रिया-प्रियतमका मन्द संचरण करते हुए कालिन्दीतटपर पहुँचना.
(७२०)- वहाँ खड़ी श्वेत हंसाकृतिकी नौकाओंपर सखियों सहित प्रिया-प्रियतमका आरोहण करना.
(७२१)- मिथ्या ज्ञानाभिमानी जनोंका वृन्दावनमें सूखे वृक्षोंके काठ बन जाना, कृपाशक्ति द्वारा उनसे सुन्दर नौकाका निर्माण कराके उनपर प्रिया-प्रियतमको आरूढ़ करा देना, परम सुदुर्लभ कृपाफलसे इस नौकाका प्रियाके हाथों संचालन होना.
(७२२)- प्रियाको डाँड चलानेका श्रम करते देख सखियोंका भी अलक्षित भावसे डाँड चलाने लगना, इसपर प्रियाका प्रियतमसे पूछने लगना कि क्या मैं इतनी निर्बल हूँ ?
(७२३-७२४)- 'प्रियाकी शक्तिसे जब मैं ही चंचल बना हूँ तो यह जड़ नौका तो प्रियाके मनोरथ मात्रसे चलेगी' यह कहते हुए प्रियतमका बिना किसीके डाँड खेये नौकाको चलती दिखला देना.
(७२५)- उजले हंस-हंसिनियों एवं कृष्णवर्णके जलकुक्कुटोंका नौकाके सम्मुख आना.
(७२६-७२७)- प्रियाके चरणोंका स्पर्श प्राप्त करनेको लालायित कालिन्दीकी वेगवती लहरोंका उमड़कर नौकाको डगमगा देना, उन्हें चरणस्पर्श दिलानेके उद्देश्यसे प्रियतमका प्रियासे कालिन्दीके छिछले तटपर पैदल चलनेका आग्रह करना
(७२८)- छिछले जलयुक्त तटपर पैदल चलनेसे प्रियाके लँहगेकी नीली किनारीका गीला हो जाना। प्रियाका इस निमित्त प्रियतमको हँस-हँसकर उपालम्भ देना
(७२९-७३०)- यमुनातटवर्ती तमालपंक्तियोंका जलको छू-छूकर हिलना.
(७३१)- कक्खटी मर्कटीका आत्म-परिचय-श्रीराधाके नन्दनन्दनसे पूर्वरागके कारण ब्रजमें निन्दा-परिवाद होने लगना, श्रीकृष्णका वैद्य-वेषमें आकर श्रीराधाके सतीत्वको सर्वोपरि सिद्ध कर देना - कक्खटी मर्कटी द्वारा इस लीलाका दर्शन किया जाना.
(७३२-७३३)- चलते-चलते प्रिया-प्रियतमका उस स्थलपर आना जहाँ उन्हें भिन्न दिशाओंमें चलकर अपने आवासमें पहुँचना है, दक्षिण-पश्चिमकी पगडंडीपर बढ़ते हुए प्रियतमका बार-बार प्रियाकी ओर मुड़कर ताकना, किशोरीका भी उन्हें आकुलता एवं विनयसहित निहारना अन्ततः प्रियतमका वृक्षोंकी ओटमें ओझल हो जाना.
(७३४-७३५)- निष्प्राण-सी प्रियाका धीरे-धीरे चलकर अपने भवनमें पहुँचकर अपने कक्षमें शैय्यापर आँखें मूँदकर पड़ जाना। सखियों द्वारा उनकी सम्हाल किया जाना, आवासमें पहुँचकर नन्दनन्दनकी सारी गतिविधिका प्रिया-द्वारा आँखें मूँदे-मूँदे ही दर्शन करते रहना
(७३६-७४०)- श्रीराधाकिशोरीके लीलादर्शनमें कालकी गतिका पीछे सरक जाना। उनके द्वारा नन्दभवनमें उषाके आगमनकालीन लीलाका दर्शन करने लग जाना, जननी यशोदाका जागरण, उनका नन्दनन्दनके शयनकक्षमें आकर उन्हें सोया हुआ ही समझकर दीपकी लौसे उनका निर्मञ्छन करने लगना, नन्दनन्दनका रात्रिकालीन विहार यशोदाको सर्वथा अज्ञात रहना, तदनन्तर यशोदाका दधिमंथनमें लग जाना, नवनीत-निर्माणके पश्चात् जननीका पुनः शयनकक्षमें जाकर सोये बालकृष्णके मुखपर छितराई कुन्तलराशिको निरवारित करना, अनेक उद्बोधनोंसे मैयाका श्यामसुन्दरको प्रबोध कराना, साँवरके जागते ही मुखधावन करते-न-करते गोशालाकी ओर दौड़ पड़ना, साँवरकी प्रातः कालीन शोभा निहारकर गोसमूह एवं वत्सादिकोंका आनन्दमग्न हो जाना.
(७४१)- श्यामसुन्दरकी प्रातः कालीन लीलाओंके दर्शन-सुखमें निमग्न किशोरीका सखियों द्वारा जगाया जाना। अनेक रसभरे उपायोंसे सखियोंका प्रिया श्रीराधाके मुखशोधन, उद्वर्त्तन, मज्जन आदि प्रातःकालीन कृत्योंका सम्पन्न करा पाना, रानीको प्रगाढ़ ध्यानमग्न होनेसे रोकनेके लिये ललिता-द्वारा चित्राको रातमें हुए स्वप्नका हाल प्रियाको सुनानेको कहना। चित्राके स्वप्नकी वार्ता.
(७४२-७४४)- नन्दसदनमें रन्धनकार्यके लिये प्रियाको बुलानेके लिये यशोदाजी द्वारा प्रेषित दूतीका भानुभवन पहुँचना, सखियों सहित प्रियाका वनमार्गसे नन्दभवनके लिये प्रस्थान, मार्गमें प्रफुल्ल वनकी शोभाको निहारना, नन्दभवन पहुँचकर रन्धनकार्यकी सम्पन्नता.
(७४५)- मैया यशोदा-द्वारा नन्दनन्दनका स्नान, शृंगार करवानेके लिये अनेक युक्तिपूर्ण उपायोंका अवलम्बन, मैयाका श्रीकृष्णको वाराहावतारकी कथा सुनाने लगना.
(७४६-७४७)- सखाओं सहित नन्दनन्दनका नन्दसदनमें भोजन करनेका अनुपम दृश्य, भोजनोपरान्त कुछ पल विश्राम करना। साँवरका वनकी ओर प्रस्थान करना। प्रिया श्रीराधा-द्वारा नन्दनन्दनके वनकी ओर निकलनेकी झाँकीका भवनकी अटारीमें जटित दर्पणमें प्रतिबिम्बित छवि द्वारा दर्शन.
(७४८-७५०)- नन्दावाससे किशोरीका अपने प्रासादकी ओर प्रस्थान करना, प्रियतमके अदर्शनसे प्रियामें प्रबल विरहावेशका उदय होना, सखियोंका उन्हें सम्हालना, कक्षमें चित्रित सारिकासे प्रियाका जीवन्तके समान वार्त्ता-व्यवहार करने लगना। प्रगाढ़ भावावस्थाकी चरम अवस्था- दसवीं दशातक पहुँचनेपर साँवरसे उनका मिलन होना।
(७५१)- प्रिया-प्रियतमका मिलन-सुख
(७५२)- राधाकुण्ड-कृष्णकुण्डके संगमपर पहुँचकर दोनोंका उसकी परिक्रमा-सी लगाना तथा वनशोभाका दर्शन। हंसाकृतिकी छः नौकाओंपर उनका सखियों-सहित आरोहण, हंसों एवं जलपक्षियोंका उनके सम्मुख आना, प्रियाका पक्षियोंको स्नेहदान-सहित मेवा खिलाना, प्रियतमके आग्रहसे उन्हें दूध पिलाना, सखियों एवं प्रियतमके बीच नौका-संचालन-स्पर्धा, कुसुम चयन लीला.
(७५३)- मधुमाधवीकुंजमें कदम्ब-वृक्षोंसे संचित मधुका पान करना, प्रियाका अपनी प्रत्येक सखीकी ओर निहारकर उसके भावोंसे तादात्म्य प्राप्त करके कुछ कालके लिये वही सखी बन जाना.
(७५४)- चन्दनकामिनीकुंजमें प्रवेश, उसके गवाक्षसे कल्पतरु वृक्षोंके वनकी शोभा निहारना.
(७५५)- कल्पतरु-वनकी गाथा सुनते-सुनते प्रियाको अपने स्वरूपकी विस्मृति होने लगना, प्रियतमका चकित होकर सोचना कि प्रियाको कैसे प्रबोध किया जावे ?...
(७५६)- परम भावोच्छलनसे प्रिया-प्रियतमका एक-दूसरेके स्वरूपोंमें परिवर्तन होना
(७५७)- विलम्बका भान होनेसे उनका अपने स्वरूपोंमें परिवर्तन तथा श्रीराधाकुण्ड पहुँचना.
(७५८-७६०)- प्रियाको जलकेलिकी इच्छा होना, कमलोंसे निर्मित कन्दुकोंसे सखियों एवं प्रियतमके बीच स्पर्धा, प्रिया-प्रियतमके श्रमविन्दुओंसे सारा सरोवर सुगन्धित हो उठना, जलकेलिको विराम, सखियोंका प्रिया-प्रियतमको नये वस्त्राभूषण धारण करवाना
(७६१)- बकुलकुंजमें प्रिया-प्रियतमका परस्पर एक-दूसरेका अद्भुत रीतिसे श्रृंगार करना.
(७६२)- सुमनकुंजमें प्रिया-प्रियतमका वनफलोंसे निर्मित विशिष्ट रसका पान करना.
(७६३)- मोहनकुंजमें प्रिया-प्रियतमका कुछ काल शयन, जागरणोपरान्त वृन्दा सखी द्वारा उन्हें वृन्दावनके पक्षियोंकी परस्पर अतिशय रसमय प्रेम-कलहके संवादोंको सुनवाना.
(७६४)- सुन्दर तृण-वेदीमें विराजित होकर सखियोंसहित प्रिया-प्रियतम-द्वारा अक्षक्रीड़ाका आयोजन
(७६५)- सूर्यास्त होते देख सखियोंसहित प्रियाका सूर्यपूजन हेतु सूर्यमन्दिरकी ओर प्रस्थान, सूर्यकुण्डके तटपर अवस्थित सूर्यमन्दिरकी अद्भुत शोभा, पूजा कराने ऋषिकुमारका आगमन तथा उसका स्वरचित मंत्र बोल-बोलकर पूजा करवाना, अन्तमें प्रियाका ऋषिकुमारके वेषमें आये प्रियतमको पहचान जाना, सर्वत्र आनन्दकी लहरें छा जाना.
(७६६)- साँवरका गायोंकी सम्हालके लिये चल पड़ना, प्रियाका अपने आवासमें आकर नन्दनन्दनकी आवनीकी झाँकी निहारनेको अपने भवनकी अटारीपर बैठ जाना.
(७६७)- सखियों-द्वारा शृंगारित प्रियाका श्यामसुन्दरको वनपथसे आते हुए देखना, दर्शनातुर नन्दग्रामकी गोपियोंका साँवरको घेर लेना तथा मैया यशोदाका उनको घेरेसे छुड़ाना.
(७६८)- सन्ध्या समय प्रियाका यमुनाके उसपारसे यमुनाघाटमें स्नानरत श्यामसुन्दरके दर्शन करना, फिर श्रीराधाका अपने भवनकी छतकी अटारीपर बैठकर साँवरके गोदोहनका दृश्य निहारना, प्रियाका कदम्बपत्रपर अपना स्नेह-निवेदन लिखकर पत्रको समीरमें उड़ा देना, मधुमंगल द्वारा साँवरका इस पत्रको प्राप्तकर पढ़ लेना, नन्दनन्दनका यशोदामैयाको वनचारणका हाल सुनाना, उनका सान्ध्य भोजन करना, निद्रालु देखकर मैयाका श्यामसुन्दरको उनके एकान्त शयनकक्षमें सुला देना, मैयाका भी अपने शयनकक्षमें जाकर सो जाना.
(७६९)- नियत संकेतस्थलपर सखियोंसहित प्रियाका नन्दनन्दनकी बाट जोहना, लवंगलताका प्रियाको उसके प्रियतमके साथ हुए मिलनकी गाथा सुनाना, लवंगमंजरीकी कथा, ललिता तथा अन्य सखियोंसहित प्रियतमका आ पहुँचना
(७७०-७७१)- शुभ्र वस्त्रालंकार धारण किये सखियों एवं प्रियाका पूर्ण चन्द्रकी निर्मल ज्योत्स्नामें अदर्शन हो जाना, प्रियतमके 'प्रियतमे' सम्बोधन तथा प्रियाके 'मैं आई' उत्तरके नादसे ही परस्पर दोनोंका अनुसंधान हो पाना
(७७२)- मयूर-मयूरियोंकी टोलीका नृत्य करना, साँवरका वेणुनादसे उसमें सहयोग करना, प्रियाका मयूरोंपर रीझकर पुष्प बरसाना, उन्हें मेवा खिलाकर जल पिलाना, यमुनापार जानेके लिये तटपर जलका वेग तथा गहराई कम करनेके लिये प्रियाका एक अंजलि जल प्रार्थना-मंत्र पढ़कर यमुनामें छीट देना, यमुनाजल शान्त एवं गुल्फ-परिमित गहरा हो जाना.
(७७३)- यमुना पार करते ही सैकततटपर रासवेदी दृष्टिगोचर होना, रासवेदीकी शोभा, वृन्दासखीका सामने आकर प्रिया-प्रियतमको वेदीपर निर्मित सिंहासनपर बैठाना.
(७७४)- प्रिया-प्रियतमको शीतल जल पिलानेके उपरान्त ताम्बूल-समर्पण करना, प्रियतमके अर्धचर्वित ताम्बूलखण्डका वृन्दाकी सभी सखियोंको वितरण, रासनृत्यका आरंभ, प्रियतम-द्वारा वेणुवादन तथा प्रियाका सखियोंसहित अनेक अद्भुत मंडलोंकी रचनाकर परम रसमय नृत्य करना.
(७७५-७७९)- रासनृत्यमें श्रान्त सखियों एवं प्रियाजीकी अपूर्व शोभा.
(७८०)- महारासमें स्वतः ही उत्तर एवं दक्षिण विभागोंका निर्माण। दक्षिणभागमें महारासनिशाकी अवधि छः मासकी हो जाना। उत्तर विभागमें निशान्तमें प्रियाका आनन्दमूर्च्छित होकर गिरने लगना, प्रियतमका मुरलीवादन स्थगितकर उन्हें हृदयसे लगाकर सम्हालना, सखियोंका भी वाद्य बजाना स्थगितकर रासनृत्यको विराम देना, तदनन्तर नौकानिर्मित सेतुसे चलकर सबका यमुना पारकर निकुंजभवनमें पहुँचना, विश्रामकक्षमें प्रिया-प्रियतमको शयन कराकर सखियोंका चला जाना, अवरुद्ध द्वारके बाहर चार-चार सखियोंका बारी-बारीसे सेवार्थ जागते रहना.
(७८१)- निभृतनिकुंजमें प्रियाका प्रियतमसे सरस विनोदके लिये पहेलियाँ बूझना.
(७८२)- पहली पहेली स्वाधीनभर्तृकाभावकी प्रधान सखी विशाखा एवं उसकी प्रमुख छः सखियोंके सम्बन्धमें होना, प्रियतमका उसे जान लेनेका संकेत देना.
(७८३)- दूसरी पहेली खण्डिताभावकी प्रधान सखी ललिता एवं उसकी प्रमुख छः सखियोंके सम्बन्धमें होना, प्रियतमका उसे पहचान लेनेका संकेत देना.
(७८४)- तीसरी पहेली प्रोषितभर्तृकाभावकी प्रधान सखी इन्दुलेखा एवं उसकी छः सखियोंके सम्बन्धमें होना, प्रियतमका उसे जान लेनेकी स्वीकारोक्ति करना.
(७८५)- चौथी पहेलीका प्रियतमके लिये गूढ़ सिद्ध होना, कई रसमयी लीलाओंकी स्मृति हो आनेपर उन्हें ज्ञात हो जाना कि यह पहेली वासकसज्जाभावकी प्रधान सखी चम्पकलता एवं उसकी प्रमुख छः सखियोंके सम्बन्धमें है, प्रियतमका उसे पहचान लेनेका संकेत देना.
(७८६)- पाँचवीं पहेलीका उत्कण्ठिताभावकी प्रधान सखी रंगदेवी एवं उसकी प्रमुख छः सखियोंके सम्बन्धमें होना तथा प्रियतमका उसे जान लेनेका संकेत देना.
(७८७)- छठी पहेली विप्रलब्धाभावकी प्रधान सखी तुंगविद्या एवं उसकी प्रमुख छः सखियोंके सम्बन्धकी होना तथा प्रियतमका उसे भी पहचान लेनेका संकेत देना.
(७८८)- सातवीं पहेलीका कलहान्तरिताभावकी प्रधान सखी सुदेवी एवं उसकी प्रमुख छः सखियोंके सम्बन्धमें होना तथा प्रियतमका उसे भी जान लेनेका संकेत देना.
(७८९)- आठवीं पहेलीका हल ढूँढना प्रियतमके लिये इसलिये भी सुगम हो जाना क्योंकि अब चित्रा ही शेष रहती है। आठवीं पहेलीका समाधान दिवाभिसारिकाभावकी मूर्त्तिमान् सखी चित्रा एवं उसकी सहयोगिनी छः सखियोंके रूपमें जानकर प्रियतम द्वारा प्रियाको जाननेकी स्वीकारोक्ति प्रदान कर देना.
(७९०)- प्रियाकी अन्तिम प्रश्नपहेली कि 'अब अन्तिम कौन ?' के उत्तरमें प्रियतमका मुखर होकर कहना कि उसे तो मैं छूकर ही बतलाऊँगा तथा प्रियाको आलिंगनबद्ध कर लेना, तदनन्तर जो प्रेम लहरोंका आलोड़न हुआ उसका अवर्णनीय होना.
(७९१)- महासिन्धुकी उत्ताल तरंगे ही तट भी बन जाती हैं
(७९२)- प्रियतमका प्रियाको कहानी सुनानेका आग्रह करना, कुछ झिझकके उपरान्त प्रियाका कहानी सुनाना प्रारंभ करना.
(७९३-८०३)- प्रियाका प्रियतमको श्रीमद्भागवतोक्त रासपंचाध्यायीकी कथा सुनाना.
(८०४-८०८)- प्रियतमको निद्रालु देखकर प्रियाका इस कथाके उपरान्त विरमित हो जाना। इस भाँति प्रियाके (इस शतकमें वर्णित) स्वप्नका भी विराम हो चलना.
''');
        case 'नवम शतक':
          return const _TopicPageContent(
              body:
                  '''(८०९)- नन्दभवनमें राजा कंस द्वारा भेजे गये दूत - अक्रूरका मथुरामें होनेवाले यज्ञोत्सवपर नन्दनन्दनको बुलाने आना.
(८१०-८१९)- सन्ध्या समय राधाकिशोरीको अपशकुन होना, सखियोंका भी अतिशय उदास दिखाई देना, अन्ततः सखियोंका यह संवाद राधाको सुनाना.
(८२०-८२५)- कुंजस्थलमें साँवरका राधाकिशोरीसे मिलना, दोनोंका अश्रुधारा बरसाना.
(८२६-८३७)- किशोरीका भाव-परिवर्तन, 'साँवरको जानेमें सुख है तो मैं उनके सुखमें विघातिका क्यों होऊँ।' किशोरीका पूछना- 'क्या सच जा रहे हो, नाथ!' साँवरका उत्तर देना- 'इस तनके कुछ काम वहाँ अवशेष हैं, मेरा मन तो इन चरणोंमें ही रहेगा।' सुनकर राधाकिशोरीका उत्तर देना- 'जाओ प्राणाधिक!' फिर साँवरका विदा लेकर अपने आवासकी ओर चल पड़ना। उनके आँखसे ओझल होते ही सहचरियोंसहित दौड़कर नन्दभवन पहुँचना, तोरणद्वारपर ही जाकर बैठ जाना.
(८३८-८४६)- साँवरका अग्रज-सहित रथारूढ़ होना, किशोरीका आकुल होकर 'भूकम्प हो रहा है, दौड़ो' आदि शब्दोंका उच्चारण, सहचरियोंका उन्हें सम्हालना, फिर किशोरीके मस्तकके अनुमतिसूचक हिलानेसे रथका आगे बढ़ना, सहचरियोंका एक-एककर गिरकर प्राणशून्य होते जाना.
(८४७)- उदुम्बर वृक्षके पास जहाँ पथ मुड़ता है, साँवरके तनसे दो नीली ज्योतियोंका निकलना, एकका राधामें प्रवेश होना, दूसरेका रथके साथ चला जाना
(८४८-८६१)- किशोरीका उन्माद‌युक्त प्रलाप सुनकरके सखियोंका उसके प्राण बचानेका यत्न करना, किन्तु किशोरीके महाकरुण रुदनसे वनके समस्त प्राणियोंका प्राणशून्य होकर गिर जाना.
(८६२-८६४)- किशोरीका यमुनाकी ओर प्रस्थान तथा यमुनातटपर बैठकर यमुनासे विनय करने लगना,
(८६५-८९६)- यमुना नदीको किशोरीका सन्देश.
(८९७-८९९)- किशोरीका यमुनामें आत्मविसर्जनके लिये प्रवेश। एक सहचरीका स्तब्ध हुई देखते रहना तथा दूसरी द्वारा उसका अनुसरण
(९००-९०१)- अन्तिम विन्दु प्राप्त होनेपर सहचरीका उसे अंकमें भर लेना, दोनोंका जलमग्न हो जाना.
(९०२-९०४)- अचानक गैरिकवसना जगज्जननी पौर्णमासीजीका आविर्भाव, यमुनाजलका तलतक घट जाना तथा राधाकिशोरीको अंकमें धारण किये उनका तटपर आना। सहचरियोंका भी प्राणसमन्वित हो उठना। जगन्माताका सबको धैर्यदान.
(९०५-९०९)- जगन्माताका अन्तर्धान हो जाना। सुन्दरी-सरोवरके रत्नमय आवासोंसे युक्त उस गाँवका भी विलुप्त हो जाना, किशोरी एवं उसकी सहचरियोंके विषयमें सबकी विस्मृति। किशोरीके लिये तो अब सौ वर्षकी वियोगनिशाका वर्तमान रहना तथा निरन्तर रुदन ही उसका जीवन बन जाना.
''');
        case 'दशम शतक':
          return const _TopicPageContent(
              body:
                  '''(९१०-९२४)- साँवरके वियोगमें वनकी उजड़ी हुई अवस्थाका तथा गोपीजनोंकी दुरवस्थाका चित्रण.
(९२५-९३१)- साँवर द्वारा प्रेषित दूत- उद्धवकी चर्चा.
(९३२-९३३)- सखियों द्वारा साँवरके दूतकी अभ्यर्थना.
(९३४)- सखियों-द्वारा उद्धवसे साँवरकी दिनचर्या सुना-सुनाकर रोने लग जाना
(९३५-९३६)- उद्धवका ज्ञानके प्रतिपादन द्वारा उनके दुःखहरणकी चेष्टा तथा साँवरका सन्देश उन्हें सुनाने लगना.
(९३७)- सबसे घिरी बैठी पर सबसे अतीत राधाकिशोरीकी मौन अवस्थिति
(९३८-९४०)- तालाब के किनारे उत्तरकी ओर मुख किये राधासहित सखी-सहचरियोंका एक-एककर साँवरकी स्मृतियाँ मानवती होकर कहने लगना.
(९४१-९८९)- ललितादि अष्टसखियोंका, मंजुश्यामा तथा मधुमती प्रभृति सहचरियोंकी पृथक-पृथक् मानयुक्त उक्तियाँ.
(९९०)- समस्त सहचरियोंका समवेत करुण क्रन्दन.
(९९१-९९२)- उद्धवके ज्ञानाभिमानका विगलन तथा साँवरके, राधाकिशोरीके रसतत्त्वके विषयमें परिचयकी प्राप्ति.
(९९३-९९७)- उद्धव-द्वारा राधाकिशोरीके दर्शनमें श्यामसुन्दर ही उनमें अनुस्यूत हैं - ऐसी अनुभूति तथा उसका 'पाहि पाहि हे साँवरके प्राणोंकी देवी!' कहकर आँखें मूँद लेना
(९९८-१००२)- उद्धव द्वारा वंशीध्वनिका श्रवण तथा श्यामसुन्दरके गोचारणकर लौटकर आनेका दर्शन.
(१००३-१००६)- उद्धवकी मन-ही-मन दैन्योक्ति.
(१००७-१००८)- उद्धवका रो-रोकर श्यामसुन्दरसे मन-ही-मन प्रार्थना करना कि उसे एक बार श्रीराधाकी वाणी सुननेको मिल जाय
(१००९)- मंजुश्यामा-द्वारा राधाकिशोरीसे उद्धवकी सिफारिश करते हुए उसे कुछ सन्देश देनेको प्रेरित करना.
(१०१०)- राधाकिशोरीका पहले विह्वल होकर रोने लग जाना फिर धैर्य धारणकर कुछ कहनेको प्रस्तुत होना.
''');
        case 'एकादश शतक':
          return const _TopicPageContent(
              body:
                  '''(१०११-१०५५)- साँवरके जाते समय पहनायी मालाको हाथमें लिये आँखोंसे अश्रु पौंछकर राधाकिशोरीका सन्देश देने लगना
(१०५६-१०८५)- 'मधुकर (उद्धव) को मैं अपने उन चरणोंको कैसे छूने दूँ जिसे तुमने अपनी अलकोंसे पौंछा था।' - कहकर कलिन्दनन्दिनीके तटकी सर्प सम्बन्धी एक लीलाका उल्लेख.
(१०८६-१०९२)- यमुनातटकी रेणुका का प्रसंग.
(१०९३-१०९८)- प्रिया-प्रियतमका कुंजकी ओर प्रस्थान तथा प्रियाका भृंगको अपने चरणों को छूनेके लिये मना करना.
(१०९९-११०१)- श्रीराधाकिशोरीका भृंगकी दिव्य चिन्मयी परिणतिके सम्बन्धमें वरदान देना.
(११०२-११०४)- प्रियाका मूर्च्छित होकर गिर जाना, ज्येष्ठा सहचरी ललिताका उसे सम्हालते हुए उद्धवसे राधा द्वारा मधुकरको दिये वरदानको अपने
ही लिये माननेका अनुरोध करना तथा राधाकी वाणीका त्रिकाल सत्य होनेकी पुष्टि.
(११०५)- यह कहकर ललिताका मूर्च्छित हो जाना, उद्धवका दोनोंकी चरणरजमें लोटनेके पश्चात् उन्मत्त-सा होकर वनसे प्रस्थान.
(११०६-११११ख)- अश्वत्थ पादपके नीचे सोयी बालाका स्वप्नसे जाग उठना, फिर उसे भान होना कि साँवर उसे गलबाँही देकर धारामय सरकी लीलाके दर्शनका आमन्त्रण दे रहे हैं। पुनः बालाका ललितानिकुंजमें पीपलके तले प्रियतमके साथ बैठे-बैठे स्वप्न देखने
लग जाना॥
''');
      }
    }

    // --- सरलार्थ (प्रियतम काव्य) (Topic 4) ---
    else if (sectionId == 'topic4') {
      switch (title) {
        case 'सरलार्थ एवं प्रथम शतक':
          return const _TopicPageContent(body: '''**(सरलार्थ)**

मेरी आत्मरूपिणी परम वन्दनीया, भगवती श्रीमन्त्रिपुरसुन्दरी ललिताम्बास्वरूपा रामदत्ता (रामदेई) नामसे जानी जाने वाली अपनी साध्वी धर्म माता की मैं वन्दना करता हूँ॥१॥राधा॥

श्रीहनुमानप्रसादजी पोद्दारकी सन्तति (पुत्री) सावित्रीकी मैं निश्चय ही वन्दना करता हूँ, धर्म-निष्ठा ही जिसका सर्वस्व है तथा जिसके रूपमें नीलसुन्दर कृष्ण ही मेरी चिरन्तन सहोदरा छोटी बहिन मञ्जुश्यामा बने हुए नित्य विराजित हैं॥२॥कृष्ण॥

**(पहला शतक)**

प्रियतम ! सुनो, मैं अपनी इन धुँधली आँखोंसे सब कुछ नहीं देख पाती। स्वप्नकी भाँति इस दृश्यमान् विश्वका रूप धारण किये हुए तुमको मैं प्यार नहीं दे पायी। वह बड़ा ही मनोहर खेल था, जिसमें तुम मेरे गुरुदेव पदपर आसीन हुए थे। पर हाय ! अब तो मेरे प्राणोंमें केवल व्यथा बची है और उसी उपकरणको लेकर मैं तुम्हारी अर्चना कर बैठी हूँ॥ १॥

प्रियतम ! मैं वही हूँ जिसको तुमने 'अहो मेरे प्राणों की रानी !' कहकर सम्बोधित किया था और फिर मेरे दोनों हाथोंको, जिनमे मेंहदी लगी हुई थी, अपने करसरोजमें ग्रहण कर लिया था। किन्तु मेंहदी-चर्चित, करोंवाली वह बाला जिसमें निवास करती थी, वह भवन टूटा हुआ-सा था। जब तुम पहली बार पधारे थे, रात्रि अंधकारमें डूबी हुई थी॥ २॥

वहाँ कोई दीपक तक नहीं था। भूमिपर रजके कुछ कण बिखरे हुए थे। यद्यपि वहाँकी धरती गोबर-मिट्टीसे लिपी-पुती थी, किन्तु गवाक्षके तथा द्वारके भी सभी कपाट टूटे हुए थे। समीर अपने दुकूलमें धूलि भर-भरकर लाया करता और गृहमें चारों ओर बिखेर देता था॥ ३॥

उस कच्चे घरमें रहते हुए भी तुम्हारी वह बाला अत्यन्त निर्मल थी। बाहरसे आया हुआ एक रजकण भी उसे छू नहीं सका था। उसमें सहस्र पावकपुञ्जोंकी शक्ति छिपी हुई थी। कहीं किसीमें भी ऐसी सामर्थ्य नहीं थी जो उसे दूषित-मलिन बना देता॥ ४॥

जो भी उस पथसे जाता था, उसे केवल टूटा हुआ घर ही सामने दीखता था। प्रियतम ! किसको कहाँ अवकाश था जो गृह के भीतर प्रविष्ट होकर वहाँकी वास्तविकताका दर्शन करता। प्रायः सबकी यही धारणा होती थी कि यह तो एक खण्डहर मात्र है। ऐसा इसलिये कि वे बेचारे राही थे, उनका ध्यान तो अपने पथपर लगा था॥ ५॥

तथाकथित राजाओंका दल, ऋषियोंकी, मुनियोंकी, कुछ सिद्धोंकी एवं गंधर्वो की टोली भी उधर आ जाती थी। उस भवनपर यदि उनकी पैनी दृष्टि कहीं पड़ जाती तो वह भवन या तो उनमें वैराग्यका संचार कर देता अथवा वह उनके लिये विनोदकी वस्तु बन जाता था॥ ६॥

उनमें कुछ विहंगम भी रहते थे, पर वे सब-के-सब सोये हुए थे। सभीके नीड़ भिन्न-भिन्न थे। उनकी सहचरियाँ भी उनके साथ थीं। उन सबका अपना अपना एक अलग संसार था। वे सभी उसीमें भूले हुए थे। वे भला क्या और कैसे जानते कि यहाँ कौन-सी बाला निवास करती है। उसका इतिवृत्त क्या है, उससे कैसे

अवगत हो सकते थे॥ ७॥

जिस रात्रिकी मैं बात कह रही हूँ वह चार पहरवाली नहीं थी, जो मिट जाती। जो सच्चे पण्डित हैं, वे सब के सब उसको अनादि बताते हैं। उनका यह भी कहना है कि उस रात्रिका अन्त केवल उसी व्यक्तिके जीवनमें होता है, जो अनिर्वचनीय, अद्भुत एवं अचिन्त्य रूपमयी सत्ताका दर्शन करनेमें समर्थ हो चुके हैं॥ ८॥

इसीलिये सारे विहंगम सोये थे। किन्तु वह बाला तो सदा ही जागती रहती थी। उसके जीवनमें क्षणभरके लिये भी नींद नहीं आयी थी। उसकी आँखें झरती रहती थीं तथा उरस्थलमें ज्वाला धधकती रहती थी। उसके पास कोई नहीं था, जो उसके आँसू पोंछ देता॥ ९॥

उसके काले कुञ्चित केश हरदम खुले रहते थे। उसका नीला परिधान उसके नयनोंकी धारासे निरन्तर आर्द्र रहता था। भवनके उन जीर्ण वातायनरन्ध्रोंसे लगकर वह निर्निमेष नयनोंसे आकाशको ही देखा करती थी॥ १०॥

सहसा उसे कभी भ्रम होता कि सूर्योदय हो चुका है। तब वह विहंगमोंका कलरव तथा भ्रमरोंका गुञ्जन भी सुनने लग जाती थी। कभी वह चातकका 'पी-कहाँ', 'पी-कहाँ' सुनने लग जाती थी और फिर दूसरे ही क्षण उसके कानोंमें कोयलका कुहू-कुहू स्वर प्रविष्ट होने लगता। इस प्रकार उसें दिन उग आनेकी प्रतीति होने लगती थी॥ ११॥

फिर क्या था, आशाकी वेलि लहलहा उठती-इस भावनासे कि आज कहीं प्रियतम आ ही जायँ। दूसरा क्षण बीतते-न-बीतते वह अनुभव करने लग जाती कि प्रियतम आ गये हैं और मेरा उनका मिलना सचमुच संघटित हो रहा है। फिर तो रसकी कल्लोलिनी उमड़ चलती, जिसमें न जाने वह कहाँसे कहाँ बह जाती। इतनेमें ही वह प्रतिहारी बना पक्षी धीरेसे बोल उठता था। बालाका वह भ्रम-मूलक स्वप्न टूट जाता और वह रोने लग जाती थी॥ १२॥

बाला राजा (वृषभानु) की पुत्री (श्रीराधा) थी। उसने स्वर्णिम दिनोंका सुख देखा था। महारानी कीर्तिदा उसकी माता थीं। उनकी आँखोंकी वह पुतली थी। उसकी एक छोटी बहिन (मंजुश्यामा) थी। वह बहिन उसके प्राणोंकी छाया ही थी। उसका एक सहोदर बड़ा भैया (श्रीदाम) था। वह तो उसके प्राणोंका सहचर ही था॥ १३॥

उसकी अगणित सहेलियाँ थीं। वे सब-की-सब उसके प्राणोंकी धारा ही थीं। दासी दासोंका समूह उसको घेरे रहता था। वह बाला उन सबकी प्राणस्वरूपिणी थी। उसके कुटुम्बीजनोंकी तो गणना ही नहीं हो सकती थी। वे सभी उसके प्राणोंकी लहरियाँ मात्र थीं और तो क्या, पशु-पक्षी तकके प्राणोंमें वह बाला ही नित्य निवास करती थीं॥ १४॥

उद्यानोंमें, आरामोंमें, वह विहंगिनीकी भाँति घूमती फिरती। महलोंमें लगी रहती। उसकी शैशव क्रीड़ाको सब लोग अपलक नेत्रोंसे देखा करते। ऐसा कहीं भी कोई नहीं था, जो उसपर न्योछावर न हो गया हो॥ १५॥

जब वह सात वर्षकी थी, तब एक दिन एक विचित्र घटना घटी-उसके मनमें आया कि मैं वनमें पुष्प-चयन करने जाऊँ। उसके ग्रामके ठीक उत्तरकी ओर एक बड़ा ही मनोहर, घना एवं विशाल वनस्थल था। शोभाका निवासस्थल वह वन कल-कल स्वर करनेवाली कलिन्दनन्दिनीके तटपर अवस्थित था॥ १६॥

ऐसा लगता था मानो शरद और वसंत दोनों ऋतुएँ सदा वहीं उसी उद्यानमें निवास करती थीं। किन्तु उस वनमें सबको जानेकी छूट नहीं थी। राजाकी अनुमति लेकर ही कोई उसमें प्रवेश कर सकता था। बात यह थी कि महाराजको उस वनमें अपनी कुलदेवीके प्रत्यक्ष दर्शन हुआ करते थे॥ १७॥

इसीलिये जब कभी पूर्णिमा आती अथवा अमावास्याकी तिथि होती, तब राज्यकी प्रजा उस वनकी फेरी दिया करती थी। उन फेरी देनेवालोंमें जिस व्यक्तिकी देवीके प्रति अतिशय निष्ठा होती, उसको उस वनमें महादेवीका प्रत्यक्ष दिव्य दर्शन भी प्राप्त हो जाता था॥ १८॥

अप्रतिम पवित्रताका अनुभव तो वहाँ जानेवाले सभी व्यक्तियोंको होता था। वे सब आ-आकर अपने-अपने अनुभवकी बातें कहा करते थे। उस राजतनयाने भी उन सबके मुखसे ही वहीं अपने भवनमें ही वनकी कथा सुनी थी। उसे सुनकर ही वहाँ जानेके लिये वह उत्कंठित हुई थी॥ १९॥

वह अपनी माता (कीर्तिदा) के समीप आकर पीयूष भरे स्वरमें बोली-'अरी मैया! मैं उस वनसे कुछ फूल बीनकर ले आना चाहती हूँ।' इतना कहकर वह हँस पड़ी। पुत्रीकी वाणी सुनकर जब उन्होंने उसकी ओर अपनी दृष्टि डाली, तब उसके बाल-मुखपर किशोरावस्थाकी लालिमाको प्रत्यक्ष अभिव्यक्त देखकर रानीकी आँखें भर आयीं॥ २०॥

महारानीकी आँखोंके आगे उनके जीवनकी एक प्राचीन घटना नाच उठी। वहीं-उसी स्थलपर वे नयी-नयी बहू बनकर आयी थीं। सुहाग रातका समय था। पर्यङ्कपर आर्यपुत्र (पतिदेव) मौन बैठे थे। महारानी वहीं उनके समीप ही बैठी थीं। वे महाराजके चरणोंमें नत-मस्तक थीं॥ २१॥

महाराजको अलौकिक सुन्दरी जीवनसंगिनीके रूपमें मिली थी। दोनोंमें ही नव-यौवनका उन्मेष हो चुका था, किन्तु प्रपंचके उन्मादी विषयभोगोंके प्रति वे दोनों ही सर्वथा विरक्त हो गये थे। फलस्वरूप दोनोंके ही अन्तस्तलमें सहसा एक ज्योतिर्मय निर्मल भाव जाग उठा॥ २२॥

महाराज बोल उठे-महारानी ! सुनो, हम दोनों अभी इसी क्षणसे कृपामयी त्रिभुवनजननीके चरण-सरोरुहमें समर्पित हो चुके हैं। हम दोनों सदाके लिये एकमात्र उनके ही क्रीत दास एवं दासी बन गये हैं। अतएव अब हम केवल-केवल उनकी ही सेवामें जीवन पर्यन्त जुटे रहेंगे॥ २३॥

देखो, उनका जब प्रत्यक्ष आदेश मिल जाय, तब भले हम दोनोंको एक संततिकी जनक-जननी बनना पड़े-वह भी इसलिये कि वह वीर पुत्र राजकुलकी परम्पराका निर्वाह कर दे। इसके पश्चात् तो हम दोनों सदाके लिये श्रीमहादेवीके चरण-नखमें ही लीन हो जायँ। हम ऐसा आदर्श उपस्थित कर दें, जिसको अंगीकार करके हमारी प्रजा भी सदाके लिये सुखी बन जाय॥ २४॥

इस निश्चयको अपनाकर महाराज-महारानी दोनोंने ही शान्तिपूर्वक कुछ महीने बिता दिये। उस वर्ष शिशर ऋतुमें, जब भगवान सदाशिवकी महाशिवरात्रि आयी, तब उस पर्वमें उन दम्पतिने अपने सद्‌गुरु (भागुरि ऋषि) से विधिवत् दीक्षा ली तथा आराधना पद्धतिकी निगमागमसम्मत शिक्षा भी प्राप्त की॥ २५॥

इस प्रकार शिक्षा-दीक्षासे सम्पन्न होकर जब अर्चना आरम्भ हुई, उस समय हरिशयनी एकादशीकी मनोहारिणी विभावरी वेला थी। श्रीमन्महात्रिपुरसुन्दरीकी प्रतिमा प्रासाद-कक्षमें ही विराजित थी। सुवर्णसे बनी हुई वह प्रतिमा अद्भुत थी। उसके प्रभावसे जो व्यक्ति मन्दिर परिसरमें आ जाता, उसका सिर अपने आप देवीके

चरण-सरोजमें नमित हो जाता था॥ २६॥

चाहे कोई कैसा भी हो, उसके चित्तकी वृत्ति कहीं भी क्यों न लगी हो, किन्तु मन्दिरकी सीमामें आते ही उसपर अचानक ऐसा प्रभाव पड़ता कि सब कुछ भूलकर वह व्यक्ति समाधिस्थ-सा हो जाता। फिर तो मन्दिरका प्रहरी ही 'दर्शन कर लीजिये!' ऐसा कहकर उनको होशमें लाता॥ २७॥

अब वह व्यक्ति अपनी अञ्जलीमें पुष्प भर लेता, उसकी आँखें गीली हो जातीं और वह मन्दिरमें जाकर अपने आपको महादेवीके चरणोंमें समर्पित कर देता। तब कहीं जाकर उसे ज्ञान होता कि उसे अब आगे क्या करना है ? अत्यन्त आश्चर्यका विषय तो यह है कि राजकुल में वे देवी वहाँ कबसे विराजित थीं, इसका किसीको ज्ञान तक नहीं था॥ २८॥

वर्तमान राजा जब युवराजके रूपमें प्रतिष्ठित थे, तभी उन्होंने ऋषितुल्य पितृचरणोंकी अनुमतिसे महादेवीकी सम्पूर्ण सेवाका भार अपने ऊपर ले लिया था। उसके पहले ब्राह्मणोंके द्वारा महादेवीकी अर्चना होती थी॥ २९॥

यद्यपि युवराज श्रद्धापूरित मनसे उन भूदेवोंके निकट उपस्थित होकर महादेवीका पुराना इतिवृत्त उनसे पूछते थे, पर वे महिदेव हँसकर केवल इतना कह देते थे-वत्स ! प्रतीक्षा करो, ये जगन्माता स्वयं ही जो कुछ बताना होगा, तुम्हें बता देंगी॥ ३०॥

तदनन्तर ब्राह्मण देवताओंने उन अत्यन्त विनयी, निपुण, बुद्धिमान् एवं धैर्यवान युवराजको एक-एक करके महादेवीकी सेवाकी सम्पूर्ण व्यवस्था सौंप दी। फिर अपना मंगलमय दक्षिण हस्त युवराजके सिरपर रखकर 'तेरी जय हो' ऐसा कहते हुए सब के सब देखते-देखते ही अन्तर्धान हो गये॥ ३१॥

उस दिनसे आज सत्तर वर्ष नौ महीना दो दिन हो चुके हैं। तबसे नृपने महादेवीकी अविराम भाव-पूरित अर्चना की है! 'सहधर्मिणी' संबोधन भी महारानीके जीवनमें जिस प्रकार अक्षरशः सत्य उतरा है, उसकी तुलना कहीं अन्यत्र उपलब्ध नहीं है॥ ३२॥

अब हरिशयनी एकादशीकी शुक्ला रजनी पुनः पधारी थी। आकाश बादलों से सर्वथा शून्य था। तारागण मानो हँस रहे थे। महारानी तथा मन्त्रीकी पत्नी भी अन्तर्सत्वा (गर्भवती) हो चुकी थी। महात्रिपुरसुन्दरी इस दीर्घकालीन अर्चनासे प्रसन्न जो हो गयी थीं॥ ३३॥

इस देवशयनी एकादशीसे नौ मास और कुछ दिन पहलेकी घटना है-महारानीको एवं समानशीला मंत्री-पत्नीको महादेवीके प्रत्यक्ष दर्शनका सौभाग्य प्राप्त हुआ था। उस समय महामाया हँस पड़ी थी। वे स्वयं इस प्रकार कह गयी थीं॥ ३४॥

पुत्रियों! सुनो, वह राजपुत्र आये, इससे पहले राजमन्त्रीका भवन मेरी क्रीड़ाकी भूमि बने और मैं ही रंगस्थलके उस प्रथम कृत्यका आरम्भ करूँ, जिसे नटी किया करती है। फिर ऐसी चिन्मयी लीला अभिनीत हो, जैसी कदाचित् ही कभी होती हो॥ ३५ ॥

आज राजभवन ही नहीं संपूर्ण राजधानीमें उत्सव हो रहा था। मध्यनिशा होनेमें मात्र आधी घड़ीकी देरी थी। हाथमें नीराजन लिये महाराज विराजित थे एवं महारानी उनके पास ही खड़ी थीं। महात्रिपुरसुन्दरीकी शोभाका क्या कहना ? वे सचमुच अलसायी-सी लग रही थीं॥ ३६॥

दासी दौड़ती हुई मन्दिरमें ही यह कहनेके लिये चली आयी थी कि सचिवगृहिणी प्रसववेदनाका-सा अनुभव कर रही हैं। कितना आश्चर्य है कि श्रीप्रतिमाके नेत्र-कमल भी क्षण भरके लिये हिल उठे। महारानीको स्पष्ट संकेत प्राप्त हो गया था वहीं चले जानेका॥ ३७॥

महारानी भी श्रीमहात्रिपुरसुन्दरीके चरणनखको छूकर तुरन्त चल पड़ी थीं। जैसे ही वे उस सदनकक्षमें पहुँची, उन्हें भान हुआ कि यहाँ तो सचमुच सर्वत्र अंशुमालीकी ज्योति फैली हुई है। महारानीके पीछे-पीछे दासी भी लौट आयी थी। दासीकी आँखें तो ज्योतिकी चकाचौंधसे बन्द हो गयीं और वह भीतर जा ही नहीं सकी॥ ३८॥

उस ओर मन्त्रीकी पत्नी आँखें बन्द करके ध्यानमग्न हो गयी थीं। देखते-न-देखते उनके अंकमें साक्षात् जगन्माता प्रकट हो गयीं। (श्रीकुन्दवल्लीका जन्म) अहा! कितना सुन्दर रूप था उनका ! उस समय वे अप्रतिम सुन्दरा नवजाता कन्याका वेश धारण किये हुए थीं। किन्तु उस अद्भुत घटनाको केवल महारानी ही देख सकीं॥ ३९॥

क्षण बीतते-न-बीतते उस बालिकापर एक निर्मल आवरण छा गया और नाल आदि जन्मके समयकी सभी वस्तुएँ अपने आप वहाँ प्रकट हो गयीं। वह बालिका भी इस प्रकार रो उठी, मानो हरिशयनीके आगमनपर उधर तो भगवान् नारायण निद्रित हो गये और इस ओर नारायणी जाग उठी हों॥ ४०॥

उस कन्याके मुखमण्डलपर श्रीदेवी ही जैसी मोहनी व्याप्त थी। सम्पूर्ण अंगोंसे भी ठीक-ठीक महादेवीके ही जैसा दुःसह तेज विस्फुटित हो रहा था। वह रो अवश्य रही थी, पर अहो! उसका वह रुदन श्रुति-मधुर तन्त्र-रवके समान था। दर्शकगण आनन्दविमूढ़ बन गये थे। सारी प्रकृति मानो खिल उठी थी॥ ४१॥

इसके पश्चात् श्रावण कृष्णा तीजकी तिथि आयी। उस दिन बुधवार था, अंशुमालीके अस्ताचलपर पहुँचनेमें पाँच घड़ीका विलम्ब था। उसी समय नगाड़ेके मंगलमय रवसे राजप्रसाद अचानक निनादित हो उठा और क्षण बीतते-न-बीतते राजपुत्र (श्रीदाम) के जन्मका मंगलमय संवाद सबके कानोंमें पहुँच गया॥ ४२॥

राजपुत्रके गोरे मुखकी शोभा कोई कैसे कहे! जिन आँखोंने उस शोभाको देखा था, वे तो कभी बोल नहीं सकीं और जो वाणी बोलती है, उसे कभी उस अप्रतिम शोभाका दर्शन ही नहीं हुआ। ऐसा लगता था, जैसे अपनी चारमेंसे दो भुजाओं तथा अपनी अप्रतिम नीलिमाको माया से आवृत करके सचमुच वे भगवान् मधुसूदन ही शिशु-वेश धारण करके पधारे हों॥ ४३॥

सम्पूर्ण राजपुरी दो पर्वतोंकी घाटीमें विराजित थी। उस पुरीके कण-कणमें बाईस दिनोंतक सुखकी चहल-पहल मची हुई थी। रात्रिमें रत्नोंकी ज्योतिसे पुरी उद्भासित रहती, मानो वह ज्योति राजपुत्रके एवं राजमंत्रीकी पुत्रीके परम मंगलमय विशुद्ध भावी सुयशका संकेत कर रही हो॥ ४४॥

महारानी एवं सचिवगृहिणी-दोनों ही सहोदरा बहिनें थीं। सचिवगृहिणीकी अभिलाषा थी कि मेरी पुत्रीका जन्मोत्सव तभी हो, जब राजपुत्रका आविर्भाव हो जाय। राजकुलकी देवीकी भी ऐसी ही रुचि थी। इसीलिये कृष्ण पक्षकी तीज वह रजनी निरन्तर अत्यन्त सुखदान करनेवाली निर्झरिणी-सी बन गयी थी॥ ४५॥

क्रमशः वह वर्ष भी बीत गया। अब भाद्रपदकी शुक्ला षष्ठीकी तिथि आ गयी थी। उस दिन रविवार था। अभी दो घड़ी पूर्व दिनकर उदित हो चुके थे। महारानीकी एक मौसेरी बहिन थी। उनका नाम शारदा था। वह सचमुच हंसवाहिनी शारदा (सरस्वती) ही लगती थी। उन्हीं शारदा देवीको उपर्युक्त समय एक कन्यारत्न की प्राप्ति हुई थी (श्रीललिताजीका प्राकट्य)॥ ४६॥

जो अघटनघटनापटीयसी महात्रिपुरसुन्दरी देवी हैं, उनकी ही चिन्मयी ज्योति कन्याका रूप धारणकर शारदाके अंकको विभूषित कर रही थी। आगे जो संविन्मयी लीला होनेवाली थी, जिसमें महादेवी स्वयं नटी बनी हुई थीं, उस चिन्मयी लीलाका संविन्मय पट तो वहाँ राजसचिवके घर ही उठा था अर्थात् उस ज्ञानोत्तर भावभूमिकी लीलाका वहीं प्रारम्भ हुआ था॥ ४७॥

वह एक संयोगकी बात थी, जो महारानी अपनी बहिनसे मिलने आयी थीं। मिलनेकी प्रेरणा उन्हें स्वयं कुलदेवी महात्रिपुरसुन्दरीके द्वारा ही प्राप्त हुई थी। जिस दिन महारानीने बहिन शारदादेवीके नगरमें अपने मंगलमय चरण रक्खे थे, उस दिन उनके अंकमें तेरह मास, सत्रह दिनका वह शिशु-राजपुत्र (श्रीदाम) भी विराजित था॥ ४८॥

महारानीके साथ, अपने अंकमें अपनी पुत्रीको लिये हुए उनकी अनुजा (मन्त्री-पत्नी) भी विराजित थीं। इन दोनोंकी आँखोंके सामने ही उस अभिनव क्रीड़ाका-लीलाके प्रथम दृश्यका पट खुला। दोनों शिशु परस्पर हाथोंमें हाथ लिये क्रीड़ारसमें निमग्न थे। मन्त्री-पत्नी, महारानी एवं शारदा देवी तीनों बहिनें उनकी क्रीड़ापर आँख टिकाये आनन्दमें डूबी बैठी थीं॥ ४९॥

इतने में ही रानीकी तीसरी बहिन (शारदा देवी) के उरस्थलमें, उदरमें तथा

लोचनोंमें मानो एक साथ सहस्र दिवाकर उदित हो गये हों, ऐसा प्रकाश फैल गया। देखते-न-देखते वह ज्योति तुरन्त एक बालिकाके रूपमें परिणत हो गयी। फिर वह बालिका माँ के अंकसे खिसक पड़ी और जहाँ वे दोनों शिशु विराजित थे, वहीं उनके बीचमें जा बैठी॥ ५०॥

तीनों बहिनें अपार आश्चर्यमें डूबी हुई सोच रही थीं कि हम यह स्वप्न देख रही हैं अथवा सचमुच ही ऐसी घटना घट रही है। इस सम्बन्धमें कुछ निर्णय कर लेना उनके लिये असम्भव हो गया था। इतना ही नहीं, उन तीनोंके रोम-रोममें जड़िमा छा गयी थी॥ ५१॥

उस ओर यन्त्रचालितकी भाँति वे तीनों शिशु खेलनेमें निमग्न थे। अहा ! उस अभिराम दृश्यका वर्णन कैसे हो? शाखा-चन्द्र न्यायसे भले ही कुछ कहा जा सके। तीनों शिशु अपनी आँखे नचा-नचाकर क्रमशः माताओंके कण्ठसे लगकर झूलने लग गये। उनके अधरोंसे मन्द-मन्द हँसी झर रही थी॥ ५२॥

'यह मेरी मैया है', 'नहीं मेरी मैया है', 'नहीं-नहीं यह तो मेरी मैया है', इस प्रकारकी अप्रतिम मधुर तोतली वाणी वहाँ गूंज उठी। केवल वह अलिंद ही झंकृत हुआ हो, इतना ही नहीं, वह वाणी सम्पूर्ण त्रिभुवनके भूत-भविष्यके उन सभी व्यक्तियोंके प्राणोंमें झंकृत हो रही थी, जो प्रियतम ! तुम नित्य श्यामघनसे जुड़े हुए थे॥ ५३॥

अन्तमें जब तीनों शिशुओंने परस्पर उत्फुल्ल नेत्रोंसे यह बात मान ली कि ये तीनों माताएँ तीनोंकी ही मैया हैं, तब उस मधुमय, अनन्त आनन्दमय पवित्र कौतुकने नया रूप धारण कर लिया। शिशुओंके मुखसे निकले क्रन्दनके-से स्वरको सुनकर माताओंकी दृष्टि भी बदल गयी उसपर एक आवरण आ गया॥ ५४॥

वैसी ही माया फैल गयी और सबको विश्वास पूर्वक वैसा ही लगने भी लगा कि मानो साधारण प्रपञ्चकी भाँति ही उस बालिकाने भी जन्म धारण किया हो। आनन्दका सिन्धु उमड़ चला। सारे जन्मोचित कृत्य किये गये। किन्तु वे तीनों माताएँ रह-रहकर विस्मय से भर जातीं॥ ५५॥

(भाद्रपदकी) पूर्णिमा तक महारानी उस नगरमें ही रहीं। प्रतिपदाके दिन सहसा उस नगरीमें एक अद्भुत समाचार प्रसरित हो गया। वहाँ के सभी निवासी अत्यधिक शंकित हो उठे कि कहीं यह नगर कल ही ध्वस्त न हो जाय। सूचना थी कि मनुष्यरूपमें राक्षसोंका दल आनेवाला है। अतएव महारानीने सम्मति दी कि हमलोग सभी यहाँ से अविलम्ब चल दें॥ ५६॥

यह बात सर्वथा असम्भव है कि हम उनसे लड़कर उनपर विजय प्राप्त कर सकें। इस स्थिति में यदि कोई निरापद स्थान है, तो सम्पूर्ण भूतल पर केवल मेरा वह नगर ही हैं। उस नगरपर जगदम्बाकी अनुकम्पा है। इसलिए किसीमें भी साहस नहीं है कि वह उस नगरके किसी भी प्राणीका किंचित् भी अनिष्ट कर सके। मनुष्य की बात तो दूर, वहाँ के लघुसे लघु कीट, पतंग, भृंगको भी कोई स्वल्प मात्र हानि पहुँचा दे, यह असम्भव है॥ ५७॥

इसीलिये सबको लेकर तुरन्त वहीं चली जाऊँगी। अविलम्ब छोटे-बड़े सब, यहाँ तक कि सारे पशु-पक्षी भी चल पड़ें। मन में तनिक भी आशंका न करें कि कहीं वे मनुजाद हमें पथ में ही नष्ट न कर दें। जगन्माताकी मुझपर अपरिसीम कृपा है। वे हमें बचा लेंगी॥ ५८॥

एकमात्र यही उपाय बचनेका था। इसीलिये वे सब के सब प्रातः होने से पहले ही ग्राम छोड़कर चल पड़े। गाड़ी में जितना सामान भर लेना सम्भव था, उतना उन्होंने शकटोंमें भर लिया। चल संपत्ति तो गाड़ियोंमें भर ली तथा अचल संपतिसे यह निश्चय करके आसक्ति मिटा दी कि संभव हुआ तो उसको फिर आकर हमलोग सँभाल लेंगे॥ ५९॥

इस प्रकार सबको विदा करके सबके पीछे महारानी 'जय दयामयि देवि ! जय जगदम्बे ! जय ललिते!' इस प्रकार उच्चारण करके एक सुविशाल रथमें अपनी दोनों बहिनों तथा उन छोटे शिशुओंको साथ लेकर निर्भय चल पड़ीं। उस समय ऐसा प्रतीत हो रहा था, मानो साक्षात् भगवती चली जा रही हों॥ ६०॥

आश्चर्यकी बात यह कि वे लोग कैसे वहाँ अविलम्ब जा पहुँचे, कुछ समझमें नहीं आता। केवल दो घड़ी (४८ मिनट) का समय बीता था कि वह राजपुरी इस प्रकार सम्मुख दिखायी पड़ने लगी, मानो, हँस-हँसकर सबका स्वागत कर रही हो। सीमापर स्वयं महाराज मंगलकलश लिये हुए खड़े थे॥ ६१॥

महाराजके उस नगरमें एक अद्भुत विभुता वास्तविक रूपसे प्रकाशित हो उठी थी। वहाँ सबके लिए सुन्दर-से-सुन्दर तथा पृथक् पृथक् रहने के लिए घर मिल गया। उन लोगोंको स्वप्नमें भी जो सुख-सुविधा प्राप्त नहीं हुई थी, वह उन्हें यहाँ उपलब्ध हो गयी। वे अपने पहले निवास स्थलको इस सुखके सामने बिल्कुल भूल गये॥ ६२॥

एक वर्ष बीत गया। पुनः पावन ऋतु का आगमन हुआ। भाद्रपद शुक्लाकी अष्टमी तिथि थी। महारानी इन दिनों अपने पीहर (रावल ग्राम) में विराजित थीं। अभी मध्याह्न नहीं हुआ था। उसमें दो घड़ीका विलम्ब था। तभी महाराज अचानक अपनी ससुराल आ पहुँचे॥ ६३॥

महारानीका उदर पुनः परम तेजोमय बन गया था। नौ महीने पूर्व की बात है, मार्गशीर्ष शुक्ला अष्टमीकी तिथि थी। हेमन्तकी सम्पूर्ण सम्पदा से धरणी विभूषित हो रही थी। प्रातः कालका समय था। महारानी उस समय देवी मन्दिर में अवस्थित थीं॥ ६४॥

महादेवी की प्रतिमाके चरणोंमें जो कुसुमावली बिखरी पड़ी थी, उसे वे अपने हाथ में उठा लेतीं फिर आँखों से छुला छुलाकर उसे अलग हटाती जा रही थीं। अभी महाराज महादेवीकी अर्चना करने के लिये मन्दिरमें नहीं पधारे थे। अकेली महारानी पूजाकी तैयारीमें संलग्न थीं॥ ६५॥

महारानीको सहसा यह दिखायी दिया कि महादेवी हँस रही हैं। तत्पश्चात् एक अद्भुत बात जो हुई वह यह थी कि महादेवीका उरस्थल धीरे-धीरे खुलता जा रहा था। उनके वक्षःस्थलपर सुशोभित अंचल परदेकी भाँति बायें और दायें सरकता जा रहा था। इस प्रकार एक द्वार बन गया, जिसमेंसे एक अत्यंत मनोहारिणी, अनिर्वचनीय सुन्दरी, गौरवर्णा, भोली-भाली, छोटी बालिका बाहर निकल आयी। महारानीके कुन्तलों की एक लटको हाथ में लेकर वह बोल पड़ी-'अरी मैया!' अहा! अमृतकी वर्षा करने वाला वह स्वर कितना मीठा था ! महारानीकी बाह्य चेतना तो सर्वथा लुप्त हो गयी॥ ६६-६७॥

किन्तु महारानीकी भीतरकी आँखें कोई और घटना देख रही थीं। महारानीकी उन आँखोंने जो कुछ देखा, उसका ज्यों-का-त्यों चित्रण तो नहीं कर पाऊँगी, कुछ संकेत भले ही कर सकूँ। महारानीने देखा सामने एक परम रमणीय पुष्पित कदम्बका वृक्ष खड़ा है। उसके नीचे एक नित्य किशोरी एवं एक नित्य किशोर विराजित हैं॥ ६८॥

उन दोनोंकी ओर ही अपनी दृष्टि केन्द्रित किये वहीं जगदम्बा भी उपस्थित हैं। वे त्रिभुवन जननी कह रही हैं- हे सती! आज तू मेरे उरस्थलका दर्शन कर ले, परिचय पा ले; जो सच्चिदानन्दमय रूप है, जिसके समान या जिससे बढ़कर कोई नहीं है तथा जो मधुरिमाका उद्गम स्थान है, वह इस कदम्ब तरुके नीचे विराजित यह नीली पीली द्युति ही तो है॥ ६९॥

जो रसमय है, ज्ञानमय है, जिसके अतिरिक्त और कुछ नहीं है, जिसके सिवा दूसरी सत्ता नहीं है, वह नील-पीतमय स्वरूप ही यह मेरा नित्य हृदय है, इसमें ही मैं सदा लीन हुई रहती हूँ; और जो लीलारसका पान करता हुआ नित्य युगल रूपमें विराजित है, जो दो होकर भी नित्य एक ही है-वही तत्त्व आज तुम्हारी आँखोंका विषय बन गया है॥ ७०॥

अभी-अभी यह नित्य किशोरी ही तुझसे 'री मैया' कहकर बोली थी। तुम भविष्यकी बात सुन लो, यह तेरे पयोधरोंका सुधामय दूध पीयेगी। किन्तु यह नित्य किशोर जब तुम्हारी उस प्राणसखीका दूध पी लेगा, तभी यह किशोरी दूध पीने आयेगी॥ ७१॥

यह किशोर तेरी उस प्राणसखी के प्राणोंमें ही नित्य समाया रहता है। इधर यह किशोरी तेरे प्राणोंमें नित्य समायी रहती है। यह तथ्य इनकी ही इच्छासे तुम दोनों ही भूल गयी हो। अब मैं याद करा देती हूँ। तुम दोनों सखियोंकी जय हो॥ ७२॥

महारानी ! इस किशोरी के करोंसे स्पर्शित हो जाने के कारण तुम्हारे इन केशोंमें से दिव्यातिदिव्य सुगन्धि निकलकर यहाँ सर्वत्र व्याप्त हो रही है। महाराज भी आ गये हैं। इनके मनमें एक बड़ा ही पवित्र संकल्प जाग उठा है कि मुझको पुनः एक संतति प्राप्त हो, जो ऐसी ही सुरभित अलकोवाली हो॥ ७३॥

किन्तु महारानी ! अपनी इस अनुभूतिको तुम महाराजको मत बता देना। आज रात्रिमें जब तुम्हारे सामने यह कह कर कि 'हे रानी! मेरा पतन हो गया, मेरा व्रत नष्ट हो गया।' वे फूट-फूटकर रोने लगें, तब तुम केवल इतना ही कह देना- 'जाइये, जगज्जनी से सब बातें पूछ लीजिये।'॥ ७४॥

उस समय मैं सब बातें बता दूँगी, इतना ही नहीं, आगे-पीछेकी सभी बातोंका प्रत्यक्ष दर्शन भी मैं महाराज को करा दूँगी। किन्तु तुम महाराजको इस बातके लिये प्रेरित मत करना कि वे मेरी कही हुई सब बात तथा मेरे द्वारा दिखायी हुई सब बातोंका विवरण तुम्हें भी बता दें। मैं आशीर्वाद दे रही हूँ कि तुम्हारे एवं महाराजके प्राणोंमें नित्य प्रतिक्षण सुखकी नयी-नयी लहरोंकी बाढ़ आती रहे। मेरी वाणी भूत, वर्तमान एवं भविष्य तीनों कालोंमें कभी मिथ्या नहीं होती॥ ७५॥

इतनेमें ही महारानीके मानसिक नेत्रोंके सामने का दृश्य तिरोहित हो गया। वे उस पवित्र समाधिसे जग पड़ीं। किन्तु उस दिन महादेवी त्रिपुरसुन्दरीकी अर्चना में वे महाराजके साथ सहयोग न कर पायीं। सम्पूर्ण दिवस वे बेसुध-सी हो रही थीं। उस दिनकी रजनीका प्रथम प्रहर बीत जानेके उपरान्त महारानी एवं महाराज अपने शयनागारमें भाव-निमग्न बैठे थे॥ ७६॥

महाराजके शरीरके कण-कणमें कुछ ऐसी विचित्र ज्योति भरी हुई थी, जिसका वर्णन वाणी तो क्या करेगी, किसीका मन भी उसके सम्बन्धमें ठीक-ठीक कल्पना तक नहीं कर सकता है। दोनों की ही आँखें रह-रहकर खुलतीं और पुनः बन्द हो जाती। किन्तु उनके प्राणों की अनुभूति कैसी थी, इसे तो प्रियतम ! तुम अन्तर्यामी ही जान सकते हो॥ ७७॥

भावविभोर महाराजने यन्त्र-परिचालितकी भाँति अपना दक्षिण हस्त रानी के हृद्देशपर एवं वाम हस्त उनके मस्तकपर रख दिया। तत्क्षण महाराज के अंगोंमें जो ज्योतिर्मय तेजोराशि प्रस्फुटित हुई थी, वह रानीके अंगोंमें प्रविष्ट हो गयी। वह तुरन्त सब जगह से सिमटकर उदरस्थल में केन्द्रित हो जगमग-जगम करने लग गयी॥ ७८॥

महाराज बाह्यज्ञान शून्य होकर महारानीकी गोदमें लुढ़क गये। वे तीस पल तक अचेत पड़े रहे। मूर्च्छा विगत होनेपर जैसा महादेवीने बताया था, उसी भाँति वे रो उठे। तब महामहिमामयी त्रिजगज्जननीने भूत-भविष्यके सम्पूर्ण घटना चित्रको उनकी आँखोंके सामने रख दिया। महाराज आनन्द-मग्न हो गये॥ ७९॥

उस पूर्वनियोजित घटना-चक्रका ही परिणाम था कि महाराज अकस्मात् अपने ससुराल में पधारे थे स्वागत करनेके लिए असमोर्ध्व महामहिमामय स्वयं भगवानके प्राणोंकी अधिदेवीका, जो उनकी पुत्री बनकर आविर्भूत होनेवाली थीं॥ ८०॥

केवल महाराज ही नहीं वरन् पृथ्वीतल, स्वर्लोक, पितरलोक एवं नागलोक तकके मुनिगणोंके जो मुकुटमणि थे, वे सब के सब अन्तर्यामीके द्वारा प्रेरित होकर दौड़े हुए आये थे। जो जिस वेष में थे, उसीमें आ गये थे, पर कुछने रूप परिवर्तन भी कर लिया था॥ ८१॥

पावस ऋतु होनेपर भी सूर्यदेव सबको अत्यंत सुखप्रद बनकर आकाशमें

चमक रहे थे। उस ओर धरणी पल-पल नवीन सुषमासे सुसज्जित होती जा रही थी। यद्यपि वर्षा ऋतुका समय था, किन्तु वहाँके सरोवरों, नदियों तथा निर्झरों का जल अभी दो घड़ी पूर्वसे उज्ज्वलतम मोतीकी भाँति निर्मल बन गया था॥ ८२॥

शीतल, सुगन्धित एवं मंदगामी समीर सब प्राणियोंको छू-छूकर मानों उनके कानोंमें कह रहा था- देखो! क्रमशः एक-से-एक उत्तुंग रस की लहरें इस भावसमुद्रमें आनेवाली हैं। तुम सभी उनमें अनन्तकालतक अवगाहन करते रहना॥ ८३॥

रविरथ के अश्व जब ठीक मध्य आकाशमें आकर अवस्थित हुए, बस उसी संधिपर ठीक मध्याह्नके समय महाराजकी पुत्रीका आविर्भाव हुआ (श्रीराधाका प्राकट्य)। उस समय कालोचित सभी मंगलमय योग उपस्थित हो गये। यही वह पुण्य घड़ी थी, जब रसराज और महाभाव दोनों ही परस्पर आबद्ध होकर एक हो गये थे॥ ८४॥

यहाँ ऐसा कोई चित्रकार नहीं हुआ और न कभी आगे होगा भी, जो उस सलोनी राजकुमारी का वास्तविक चित्र अंकित कर सके। मेरे प्राणाधिक प्रियतम ! सुनो, जिनके लोचन तुम्हारे चरणोंकी नख-चन्द्रिकासे उद्भासित हों, वे देख भले ही लें, किन्तु वे उसकी प्रतिच्छविको अंकित नहीं कर सकेंगे॥ ८५॥

पूरा विवरण तो असम्भव है, किन्तु अहो प्रियतम ! उस पार पहले भी दो बार उस मुख-सुषमाका एवं अवलोकन करनेवालोंके प्राणोंमें उमंगकी जो धारा उमड़ चली थी, उसका तथा वहाँ बाहर उसकी कैसी ज्योति प्रस्फुटित हो रही थी, उसका भी, तुमको स्मरण होगा, किंचित् चित्रण आत्मकथन रूपी निर्लज्जताको स्वीकार करके कर चुकी हूँ। (कदाचित् नवजात कुन्दवल्ली तथा श्रीदामके वर्णनकी ओर संकेत हो अथवा छन्द संख्या ६६-६७ और ७०-८१ की ओर लक्ष्य हो)॥ ८६॥

उसकी स्मृतिसे ही आनन्द-निमग्ना मैं अब केवल इतनी बात भले कह दूँ कि उन दिव्य अतिथियोंने (देखिये छन्द संख्या ८१), रानीने, उनकी बहिनोंने तथा उन अगणित चर-अचर लोचनोंने उस कन्याको एवं रसके उस महाप्लावनको देखा और बस देखा ही भर। (दर्शन मात्रके जादूने अन्य सब इन्द्रियोंको जड़ीभूत कर दिया।) जिस दिन रानी पुत्रीको लेकर पीहरसे श्वसुरालमें लौटी थीं, उस दिन मकर संक्रांति थी॥ ८७॥

कन्या की जन्म वाली अष्टमीसे अबतक पच्चीस महीने एवं सात दिन बीत चुके थे। नित्य प्रातः से लेकर अगले दिनके प्रातः काल तक अर्थात् आठों पहर महाराजकी विभिन्न पुरियोंमें भावों की जो नयी-नयी तरंगे उठती थीं, उनका वर्णन भला संभव है क्या ?॥ ८८॥

जो हो, जब राजपुत्री इतने दिनों (पच्चीस महीने सात दिन) की हो चुकी थी, तब महाराजके प्राण-समान उनके जो एक धर्मभाई थे, जो लोक-विख्यात 'गोपेश' की पदवी से विभूषित थे, उनके घर उस दिन शारदीय पूर्णिमाका उत्सव हो रहा था॥ ८९॥

एक बात और सुन लो ! जिस दिन वह नृप-तनया अवनी पर अवतरित हुई थी, उसके ठीक पंद्रह दिन पहलेकी रात्रिमें उन महामहिम गोपवर्यको एक ऐसा पुत्ररत्न प्राप्त हुआ था, जो सम्पूर्ण आभीर-कुलका दीपक तथा सबकी आँखोंका तारा था॥ ९०॥

तभीसे उन दोनों धर्म-बन्धुओंने ऐसा निश्चय कर लिया था कि शरद, वसन्त आदि समस्त ऋतुओंमें होनेवाले जो भी उत्सव हों, उन सबको आगेसे हम सदा दोनों कुल मिलकर ही मनाया करेंगे। भले ही वे उत्सव चाहे वनमें मनाने पड़ें अथवा राजभवनमें मनाये जायँ॥ ९१॥

यही कारण था कि आज महाराज सपरिवार उस आभीर नगरीमें आये हुए थे। समस्त प्रजा भी आयी थी। और तो क्या केवल दस दिन की आयुवाले शिशु तक आये थे। मानो महाराजकी पुरीकी पूरी नगरी ही उठकर आ गयी थी। उस अभीरपुरके सम्पूर्ण नर-नारियोंका उत्साह भी आज निराला था॥ ९२॥

गोपेश और वृषभानुपुर-नरेश दोनोंने अभी-अभी श्रीनारायण विग्रहकी चौंसठ उपचारोंसे अर्चना सम्पन्न की थी और इस आराधनासे अपनेको कृतकृत्य अनुभव कर रहे थे। अब उद्दाम नारायण-नाम संकीर्तन में ये दोनों संलग्न हो रहे थे। सम्पूर्ण पुरवासी भी वैसे ही स्वरमें स्वर मिलाकर योगदान कर रहे थे॥ ९३॥

अर्धनिशा बस अभी-अभी बीती ही थी। केवल पाँच पल (दो मिनट) ही हुए थे कि नन्दपुत्रको वृषभानुपुर की महारानीकी बहिन वहाँ उस संकीर्तन मंडपमें ले आयीं। वह चञ्चल शिशु उनकी गोदीसे शीघ्रतासे उतर पड़ा। वह सदासे ही निर्भय स्वभावका था, अतः गोदीसे उतरते ही झटसे भीड़में घुस गया॥ ९४॥

महाराज वृषभानुके पुत्र (श्रीदाम) को वह 'श्रीभैया' कहकर सम्बोधित करता था। संकीर्तन में विभोर हुए गोपेशके समीप वह जा पहुँचा और अपने चञ्चल हाथोंसे उनके वस्त्र को खींचते हुए बोल पड़ा- 'ओ बाबा ! ओ बाबा ! मेरी मैयाने मुझको तुम्हारे पास तुमसे यह कहनेके लिये भेजा है कि अभी-अभी श्रीभैया को पुनः एक छोटी बहिन प्राप्त हुई है।'॥ ९५॥

उस नील-कलेवर बालककी वाणी में सदा टोना-सा भरा रहता था। उसकी

वाणी कानोंमें जाते ही पलभरमें सभीकी वह भाव समाधि टूट गयी। भगवान् नारायणका जो शारदीय उत्सव परम उल्लाससे चल रहा था, वह वृषभानु नरेशकी नवजात कन्याकी महा बधाईमें परिणत हो गया॥ ९६॥

इस प्रकार उपर्युक्त सम्पूर्ण घटनाओंको (छन्द संख्या २१ से ९६ तककी) महारानी मानो वे घटनाएँ अभी-अभी घटित हुई हों, प्रत्यक्षकी भाँति क्षण भरमें फिरसे देख गयीं। उनकी पुत्री उनसे इस समय वनस्थलमें पुष्पंचयन करनेकी अनुमति लेने आयी थी और उत्सुकता भरी आँखोंसे अपनी जननी की ओर देख रही थी। अन्तमें उससे रहा नहीं गया; वह बोल उठी- 'अरी मैया! तू क्या सोच रही है री?' यह कहकर अपनी जननीके अञ्चलको उसने खींच लिया। तब कहीं जाकर उनका स्वप्न भंग हुआ॥ ९७॥

अपनी पुत्री के अधरोंपर, कपोलोंपर वात्सल्य रससे पूरित अनेक चिन्होंको अंकित करके फिर अपनी छोटी बेटीको भी वैसे ही वात्सल्य-रससे स्नान कराकर, इतना ही नहीं, वहाँ बड़ी बेटी की जो भी सहचरियाँ उसके साथ आयी थीं, सबको वैसे ही उसी भाँति रस-सरोवरमें निमग्न करके सबको साथ लिये हुए वे चल पड़ीं॥ ९८॥

उन सबको लिये हुए वे देवीके अर्चना-मन्दिरमें जा पहुँचीं। महाराज वहीं ध्यानस्थ बैठे हुए थे। बेटीकी जो रुचि थी, उससे महारानीने महाराजको अवगत करा दिया। महाराजके नयन झर-झर बहने लग गये। वे पूर्णकाम हो गये। उनके मानस-तलमें देवीने जो बात कहीं थी, वह गूंज उठी -॥ ९९॥

'वत्स ! देखो, जब तुम्हारी पुत्री सात वर्षकी होकर हँस-हँसकर मेरे वनमें आनेकी अभिलाषा प्रकट करे, तब समझ लो कि वह एक ऐसा खेल खेलेगी जो अनन्तकालतक त्रिभुवन के समस्त चराचर को पावन, पावनतर, पावनतम बनाते हुए सबकी नित्य निधि बन जायेगी।'॥ १००॥

गद्गद कण्ठसे महाराजने देवीके उद्यानमें पुत्रियोंको जानेकी अनुमति दे दी। महारानीने भी सबको गहने-कपड़ोंसे सजा दिया और वे बालिकाएँ तुरन्त ही देवी-काननकी ओर चल पड़ीं। उनका द्रुत गमन सचमुच ऐसा लग रहा था मानो (गीता, अध्याय ८ के ९वें श्लोकमें जिनको 'कविं पुराणं' कहा गया है और जो नित्य तथा सर्वज्ञ हैं उन परब्रह्मकी किशोर मूर्तिके मनकी सुन्दरता-परब्रह्मकी किशोरमूर्ति श्रीकृष्ण और उनके मनमें समायी हुई सुन्दरता श्रीराधा) प्रवाहिणी (सरिता) का रूप धारण करके आगेसे आगे एक निश्चित दिशाकी ओर विगलित होकर बह चली हो॥ १०१॥

''');
        case 'दूसरा शतक':
          return const _TopicPageContent(
              body:
                  '''उन वनकी पूर्वी सीमा-निर्माणका काम ऊँची-ऊँची चोटियों से युक्त एक पर्वत करता था। पश्चिम दिशामें उससे सटकर श्याम-सलिला यमुनाजी बहती थीं। उत्तरमें घने वृक्षोंसे आच्छादित अत्यंत लम्बा-चौड़ा राजपथ था, जो कोसों तक चलकर रत्नमय गोवर्धन पर्वतसे जा मिला था॥ १०२॥

उस पर्वत से निकलकर झर-झर बहनेवाले झरनेने एक छोटी किन्तु चपल गति से प्रवाहित हो रही स्रोतस्विनीका रूप धारण कर लिया था। आगे बढ़कर वह नीलसलिला कालिन्दीसे जा मिला था। वह उस वनकी दक्षिण सीमापर हँस-हँसकर कल-कल निनाद करता था। वर्षा ऋतुमें भी उसकी धारापर मोतीके समान उज्ज्वल बुदबुदे बिखरे रहते थे॥ १०३॥

उस वनमें सभी दिशाओंमें जानेवाली सीधी टेढ़ी पगडंडियाँ थीं, जो कहीं-कहीं मनोरम घास-फूसकी झुरमुटोंमें खो जाती थीं। सुगंध लुटानेवाले पुष्पोंसे आकर्षित होकर संगीतरत भौरे वहाँ उड़ा करते थे और उनके गुञ्जनसे वह कानन भरा रहता था॥ १०४॥

विहग-वृन्द का कलरव उस वनमें निवास करनेवाली तरुणियोंको प्रियतमसे मिलनेके अनुकूल-प्रतिकूल अवसरोंका संकेत प्रदान करके मधुर रसपानकी कलाका मानों पाठ पढ़ाया करता था। उस पक्षी-समूहके कलरव से ही उन्हें पता चल जाता था कि आज किस लीलामें किस भूमिकाका निर्वाह करना है। उनका कल-गान उस दिनकी लीलाका सच्चा प्रतीक हुआ करता था, अतः वे सब उनका बहुत आदर करती थीं॥ १०५॥

उन वनके किसी भी चौपायेमें हिंसाकी वृत्तिका नितान्त अभाव था और सभी पशु एक दूसरेसे निर्भय रहकर दिन-रात सुखसे उस वनमें भ्रमण किया करते थे। उन सभी पशुओंमें अपने आप मुनियोंकी-सी दृष्टि उतर आयी थी। ऐसा लगता था कि सबमें एक ही आत्माका दर्शन करके मानों सबको अपना ही स्वरूप मानने लगे थे॥ १०६॥

उस गोवर्धन पर्वतमें एक-से-एक बढ़कर सुन्दर गुफाएँ थी। उसमें जब वे पशु आँखें मूदकर विश्राम करने लगते थे, तब उनकी निस्तब्धता तथा चञ्चलताका अभाव एक ऐसे वातावरणका सृजन कर देता था, जिससे लगता था कि समस्त वनस्थली समाधिलीन हो गयी हो॥ १०७॥

दूसरी ओर उस पर्वतका कण-कण मानो सजीव था और ऊँचा सिर किये वह सतत देखा करता था कि वनमें किसे, कहाँ, किस वस्तुकी आवश्यकता है। वह वहीं खड़े-खड़े ही सबको सँभाल लिया करता था॥ १०८॥

उस वनमें निवास करनेवाली छोटी-से-छोटी बीरबधूटी तकको भी आघात पहुँचाये बिना यथासमय वह शैल सभीको आहार प्रदान करता था। जिसकी जो रुचि हुआ करती थी, उसके अनुसार उसकी वाञ्छित वस्तु वह उसके समीप रख देता था और उसे सुखसे भर देता था॥ १०९॥

वह शैलराज केवल बड़ी आयुके लोगोंका ही आदर करता हो, यह बात नहीं थी, अपितु शिशुओंतकके मनोरंजन के लिए उन्हें नीलम, पुखराज और लाल आदि रत्न देता था। उस पर्वतराजकी समता, धीरता और प्यार-वितरणकी कहीं कोई तुलना ही नहीं थी। अतः उसकी ही आँखों से आँखें मिलाकर, उसकी दृष्टि और अपनी दृष्टि एक करके मैं उस वनका चित्रण कर रही हूँ॥ ११०॥

ललिता कुञ्जका वर्णन -

वहाँ धरतीपर फूली हुई लता वृक्ष से रूठी हुई सी प्रतीत होती थी। वृक्ष अपनी डालियोंको झुकाकर मानो पल्लवरूपी अपने हाथोंसे लताकी भुजाओंको छूकर कह रहा है कि मेरे हृदयमें (तने में) तुम्हें जो कमलसे सुन्दर पुष्प झलमल करते दिखाई दे रहे हैं, वह तुम्हारी प्रेममयी आँखोंका भ्रम है। वस्तुतः तुम्हारी छाया ही मेरे हृदयमें प्रतिबिम्बित हो रही है। (ललिताका विशुद्ध माधुर्यमय खण्डिता-भाव\* विभूषित रूप)॥ १११॥

जहाँ उज्ज्वल सत्त्व वाली गुरुचकी लता नीमके वृक्षसे लिपटी हुई, फैली हुई है। (यह ललिता का प्रच्छन्न-रस-सम्पुटित खण्डिताकी छाया लिये महामाया रूप है।)॥ ११२॥ जहाँ वट वृक्षसे लिपटी हुई शंखालु नाम वाली लता है। (ललिताका प्रच्छन्न-रस-सम्पुटित खण्डिताकी छाया लिये जगज्जननी रूप)॥ ११३॥

जहाँ करील (टेंटी) की जड़के पास श्यामक घास विपुल मात्रा में उगी हुई है। (ललिताका प्रच्छन्न-रस-सम्पुटित खण्डिताकी छाया लिये योगमाया रूप)॥ ११४॥

वृन्दा देवी से कामिनी लता प्रजापति (तितली) की नाना पुष्पों के संगकी केलि-क्रीड़ा के विषय में कह रही है और कुमुदिनी चंद्रमासे उस भँवरेका वृत्तान्त बता रही है जो उसका रस पीनेके कारण मदमत्त होकर सुखपूर्वक उसके कोषमें सो गया था। (यह ललिताका जाग्रत, स्वप्न, सुषुप्ति भावापन्न रूप है)॥ ११५॥

जहाँ सूर्यमुखी (पुष्प) अपनी गाथा सूर्यके सम्मुख खोलकर रख देती है। (ललिताका जाग्रत, स्वप्न, सुषुप्तिसे अतीत तुर्य-तत्त्वात्मक रूप)॥ ११६॥

जहाँ निर्मल जल वाली मानसी गंगा नामक नदी खिन्न चित्तसे अपने पतिको खोज रही थी, पर असफल होकर वह पीछेकी ओर मुड़ पड़ी। किन्तु गिरिराजकी गुफाने बताया कि तुम्हारे प्रियतमकी श्यामवर्णा दूती यहाँ तुम्हारी बाट देख रही है। यह सुनकर वह उन यमुनाजीसे जा मिली। (ललिताका गंगा-यमुनात्मक रूप)॥ ११७॥

जहाँ चंदन आदि नव वृक्षोंसे निर्मित नव निकुञ्जोंकी अवली है। (ललिताका विशुद्ध-रस-सम्पुटित प्रच्छन्न नवदुर्गात्मक रूप)॥ ११८॥

जहाँ कटहल आदि दस वृक्षोंसे निर्मित दस निकुञ्जोंकी पंक्ति है। (ललिताका विशुद्ध-रस-सम्पुटित प्रच्छन्न दशविद्यात्मक रूप)॥ ११९॥

जहाँ कल्पवृक्षकी छायामें प्रतिष्ठित देवीकी प्रतिमाकी चरणपीठकी उपासना कालका नियामक सूर्य करता है। (ललिताका विशुद्ध-रस-सम्पुटित भगवती महात्रिपुरसुन्दरी रूप)॥ १२०॥

जिसका युगपत् उज्ज्वल तथा नीलमणि जैसा प्रकाश है। (यह ललिताका विशुद्ध-रस-सम्पुटित भगवत्ता है)॥ १२१॥

जहाँ बेल (श्रीफल) के वृक्षोंसे निर्मित कुञ्जकी परिक्रमा सूर्य कर रहा है। ललिताका विशुद्ध रसमय श्रीमातृत्व रूप।)॥ १२२॥

विशाखा कुञ्ज का वर्णन -

(विशाखा स्वाधीन भर्तृका भावकी प्रतीक हैं।) जहाँ स्थल कमल रूपी सुन्दर स्तनमण्डलोंपर खिले हुए कचनार, अगस्त्य, सहिजन तथा अशोकके पुष्पोंके

गुच्छे सुशोभित हो रहे हैं और जहाँ धरतीपर हरसिंगार (पारिजात) के पुष्प एक

विचित्र सुषमाका विस्तार कर रहे हैं, जिसको देखकर चन्द्रमा भी मोहित हो गया है॥ १२३॥

जहाँ वृक्षों का स्वभावतः लताओंके प्रति दास्य भाव है॥ १२४॥

जहाँ आमके निकुंजोंकी पंक्तियाँ हैं॥ १२५॥

जहाँ बिजौरेकी पंक्तिसे निर्मित कुंज हैं॥ १२६॥

जहाँ केलेका वन है॥ १२७॥

जहाँ अनारके वृक्षोंसे निर्मित निकुंज श्रेणी है॥ १२८॥

जहाँ (प्रिया-प्रियतम) के गेंद खेलने का स्थान है॥ १२९॥

जहाँ मणियोंसे निर्मित विश्राम गृह हैं॥ १३०॥

चित्रा कुञ्ज का वर्णन -

(दिवाभिसारिका भाव) जहाँ दिन रहते छुईमुई छिपकर अभिसार करती थी। भँवरोंका उड़ना देखकर जो भ्रममें पड़ गयी तथा उसे ऐसा भान होने लगा कि मेरे प्राण-प्रियतमने करोड़ों रूप धारण कर लिये हैं, पर जब उसने आँखें मूँदी, तब उसे प्रतीत हुआ कि अपने वे प्रियतम मुझे छोड़कर अन्यत्र चले गये॥ १३१॥

जहाँ सौ दल वाले कमलोंका वन है॥ १३२॥

जहाँ तुलसी वन है॥ १३३॥

जहाँ दूबके मैदान है॥ १३४॥

जहाँ सुपारीके वृक्षोंकी पंक्ति है॥ १३५॥

जहाँ तालके वृक्ष पंक्तिबद्ध खड़े हैं॥ १३६॥

जहाँ खजूर के वृक्षों की श्रेणी है॥ १३७॥

जहाँ कर्णिकार पुष्प का वन है॥ १३८॥

इन्दुलेखा कुञ्ज का वर्णन -

(प्रोषितपतिका भाव) शरद ऋतुमें कुंदके सफेद पुष्पोंपर दिखायी देनेवाले ओस कण वस्तुतः उसके अश्रुकण हैं। यह मानती है कि इस प्रकार अपना श्रृंगार करके मैं अपने आपको ठग रही हूँ। मेरी यह धारणा कि प्रियतम आयेंगे-केवल सपना मात्र है, जो क्षण भरमें टूट जायेगा। मेरा प्रेमका दिखावा केवल एक दम्भ है। इस चिन्तासे ही वह रोती रहती है॥ १३९॥

जहाँ आमड़ेके वृक्षोंकी श्रेणी है॥ १४०॥

जहाँ इममलीका वन है॥ १४१॥

जहाँ करौंदा नामक वृक्ष है॥ १४२॥

जहाँ सुगन्धित पत्तोंवाले दौनेका वन है॥ १४३॥

जहाँ देखनेमें सुन्दर, परन्तु गन्धहीन वैजयंती (जैता) पुष्पका वन है॥

१४४॥

जहाँ अशोक वृक्षोंकी श्रेणी है॥ १४५॥

जहाँ नीले कमल-पुष्पों का वन है॥ १४६॥

चम्पकलता कुञ्ज का वर्णन -

(वासकसज्जा भाव) जहाँ चम्पा पीले फूलोंकी साड़ी पहने हुए ऐसा अद्भुत राग अलापती है, जैसा वहाँ पहले कभी किसीने नहीं सुना। किन्तु उसमें कोई मोहिनी शक्ति अवश्य भरी है, जिसके कारण विधाताका विधान भी मिट गया था और एक भँवरा उससे प्रेम करने लगा था॥ १४७॥

जहाँ महुएके वृक्षोंकी पंक्ति है॥ १४८॥

जहाँ गन्धराजका वन है॥ १४९॥

जहाँ पलाशकी पंक्तियाँ हैं॥ १५०॥

जहाँ सुगंधित पत्तोंवाले इंगुदी वृक्षके बने हुए कई निकुञ्ज हैं॥ १५१॥

जहाँ गुलाब तथा जामुन अथवा गुलाबजामुनके वृक्ष हैं॥ १५२॥

जहाँ मदारकी पंक्ति है॥ १५३॥

जहाँ पीत चन्दनका वन है॥ १५४॥

रङ्गदेवी कुञ्ज का वर्णन -

(उत्कण्ठिता एवं विप्रलब्धा भावों का युगपत् रूप) जहाँ रंग-बिरंगे मोतियों पुष्पोंकी शोभा ऐसी अनुपम है कि वह आकाशमें विचरण करनेवाले अर्थात् बड़ी ऊँची-ऊँची बातें करनेवाले मुनियोंकी बुद्धिको भी कुण्ठित कर देती है। उनकी तो कौन कहे, जहाँ उन मुनियोंके विचारोंका पोषण करनेवाले महासिद्ध वेदान्त परिनिष्ठोंकी बुद्धि भी इतनी मोहित हो जाती है कि उसमेंसे कोई भी आजतक उसका वर्णन नहीं कर पाया॥ १५५॥

जहाँ शमी वृक्षोंका झुण्ड है॥ १५६॥

जहाँ आँवलेके वृक्ष हैं॥ १५७॥

जहाँ आकके पेड़ोंका वन है॥ १५८॥

जहाँ कदम्ब वृक्षोंकी पंक्ति है॥ १५९॥

जहाँ अत्यन्त कोमल शिरीष पुष्पोंके वृक्षोंकी पंक्ति है॥ १६०॥

जहाँ कैथे के कई गुंज हैं॥ १६१॥

जहाँ जम्बीर का वन है॥ १६२॥

तुङ्ग‌विद्या कुञ्ज का वर्णन -

(उत्कण्ठिता भाव) जिस कुंजमें लता-भवनोंपर मालती कुछ इस भाँति फूली हुई थी, जिससे ऐसा लगता था मानो गर्वसे फूली नहीं समा रही है। जहाँ पवनकी साँय-साँय ध्वनि सुनकर प्रियतम आ रहे हैं, ऐसा अनुमान करके उनसे मिलनेके लिये वह अत्यन्त लालायित हो उठती थी। परंतु जब वे उसे दृष्टिगोचर नहीं होते, तब वह झूम-झूम कर तथा ठहर-ठहरकर जूहीसे बातें करने लगती थी॥ १६३॥

जहाँ पीपलके वृक्ष हैं॥ १६४॥

जहाँ प्लक्ष (पाकड़) के वन हैं॥ १६५॥

जहाँ तगर नामक वृक्ष हैं॥ १६६॥

जहाँ सालके वृक्षोंकी पंक्ति है॥ १६७॥

जहाँ देवदारुका वन है॥ १६८॥

जहाँ भोजपत्रके वृक्षोंका वन है॥ १६९॥

जहाँ कदली वृक्षोंका समूह है॥ १७०॥

सुदेवी कुञ्ज का वर्णन -

(कलहान्तरिता भाव का प्रतीक) जहाँ लाल फूलों वाली जपा (अड़हुल)

नीचा मुख किये हुए खड़ी थी, उन फूलोंकी ही लाली मानो उसकी आँखों में उतर आयी थी। पास ही खड़ा हुआ नील तमाल अपनी दीनता और व्यथा व्यक्त कर रहा था और पुरवैया हवाके झोंकोंसे वह बार-बार झुक झुक जाता था। पूर्वसे पश्चिमकी ओर बहने वाली उस हवामें संध्या होते-होते साँय-साँयका स्वर भर जाता। ऐसा लगता मानो वह जपा रो रही हो॥ १७१॥

जहाँ गूलरके वृक्षोंकी पंक्ति है॥ १७२॥

जहाँ बेरके वन हैं॥ १७३॥

जहाँ बेंतके वृक्षोंसे बने कुंजोंकी पंक्ति है॥ १७४॥

जहाँ बाँसका वन है॥ १७५॥

जहाँ अर्जुन वृक्षोंका झुण्ड है॥ १७६॥

जहाँ पृथ्वीसे उत्पन्न होने वाले समस्त तरु-लतादिका निवास है॥ १७७॥

पर जहाँ लीलाके अनुसार अवसर तथा स्थानके अनुरूप वे प्रकट होते अथवा छिपते रहते हैं॥ १७८॥

राधाकुण्ड का वर्णन -

वस्तुतः यह श्रीराधाजीका ही प्रतीक है। राधाकुण्डमें क्रमशः उठने-गिरनेवाली अनवरत लहरोंने धाराका रूप धारण कर लिया था। चल लहरोंपर बैठा हुआ होनेके कारण चञ्चल बना हंस अपनी प्रेयसी हंसिनीसे कहता है कि प्रिये! देख, ये तरंगें तुमको पाद्यर्पण कर रही हैं- १-पाद्यके अनन्तर इनकी २-अर्घ्य और ३-आचमनकी भी अर्चना स्वीकार करो॥ १७९॥

ये लहरें अपने प्राणोंके रससे तुम्हें ४- स्नान करा रही हैं तथा उनका प्राण जो जल है, उसीका ५-परिधान धारण कर रही हैं। कुण्डके चारों किनारोंपर अवस्थित वृक्षोंसे फूलोंके गुच्छे उन लहरोंमें झरते हैं, उनका ही ६-आभूषण वे तुम्हें पहना रही हैं॥ १८०॥

अपने हृदयपर बिखरे हुए पुष्प-परागोंका ही ये लहरें ७-सुगन्धि अर्पित कर रही हैं और अपने उरपर खिले हुए कमल ८-पुष्पको तुमपर चढ़ा रही हैं। तुम्हारी अर्चनामें तुमपर समर्पित हो जानेका उत्कट उमंग ही मानो सूर्यकी किरणें हैं, जिससे आकर्षित होकर इनका उरस्थल भाप सदृश बनकर उड़ने लगता है। वही मानो पूजाका चतुर्थ उपचार ९-धूप हैं॥ १८१॥

इन तरङ्गोंके भीतर दिनके समय सूर्यका तथा रात्रिमें चन्द्रमा एवं तारागणोंका प्रतिबिंब झलकता है; वे ही १०-दीप हैं। इस कुण्डके हृदयपर खिलनेवाले कमलोंके छत्तोंके भीतर जो प्रीतिके उज्ज्वल रसके समान स्वेत वर्णवाली (कमलगट्टा नामकी) जो वस्तु भली-भाँति सँजो कर रखी हुई है (अथवा इनके वक्षःस्थलमें सञ्चित उज्ज्वल प्रीति-रस है) वहीं ११- नैवेद्यके रूपमें अर्पित है॥ १८२॥

ये लहरें अपने निर्मल जलसे तुम्हें १२-आचमन कराती हैं और जो लाल रंगके कमल हैं, उनके दलोंसे १३-ताम्बूलकी रचना करती हैं। इनके हृदयमें स्थित उज्ज्वल रस ही इनकी १४-तर्पणकी सामग्री है और इन लहरोंका प्यार भरा स्वर ही सुमधुर १५-स्तुति है॥ १८३॥

अपने स्वरूपमें स्थित ये लहरें सभी दिशाओंमें घूम रही हैं। यही इनकी शत-शत १६-परिक्रमा और प्रणाम है। इनकी निगूढ़ पूजाके ये ही मनको हरनेवाले षोडश उपचार हैं। इस प्रकार प्रतिदिन हंसिनीका प्रियतम (श्रीकृष्ण) अपनी प्रेयसीके चित्तको विगलित, आकर्षित करनेवाले गीत गाता रहता था॥ १८४॥

हंस (श्रीकृष्ण) का यह गीत सुनकर उसकी प्रिया (राधा) रीझ जाती तथा अपनी मूक सम्मति देकर हंसपर झुक पड़ती थी। दोनों हंस-हंसिनी (राधा-कृष्ण) कण्ठसे कण्ठ मिलाकर सरोवरकी लहरोंमें प्रविष्ट हो जाते और लहरें आनन्दमें मतवाली होकर तटोंसे टकराने लगतीं॥ १८५॥

उन लहरियोंके भीतर ही भीतर दोनों चलते रहते और जलमें उनकी स्थिति किस समय कहाँ है, इसको भाँपते हुए जल-तलके ऊपर-ऊपर जल-पक्षिणियोंका समूह चलता रहता।

हंस-हंसिनी तथा विहगी समूहमें जो मनोहर दाँव-पेंच चलता, उसका चित्रण करनेकी चेष्टा करनेवाली चित्रकारकी कँची अपनेको असमर्थ जानकर शक्ति-सम्पन्न होनेके लिये कृष्णकुण्डमें (उसके चित्रणमें) निमग्न हो गयी॥ १८६॥

कृष्ण कुण्ड का वर्णन -

वहींपर उसीसे सटकर एक दूसरा गंभीर कुण्ड था, जिसका जल नीले रंगका था। योगी जन अनेक प्रयत्न करनेपर भी उसकी गहराईका पता न लगा पाये थे। जो युग-युग तक श्वास रोके रह सकते थे, ऐसी क्षमतावाले योगी भी उसकी थाह लेनेके लिये उसमें उतरे, किन्तु उसका इतना अगाध जल था कि उन्हें भी हार माननी पड़ी और उदास-मुख वे लोग बाहर आ गये॥ १८७॥

ऐश्वर्य, धर्म, यश, ज्ञान, वैराग्य तथा सत्य इन छः विभूतियों से युक्त पूर्ण भगवत्ताका पुंजीभूत रूप उसके कण-कणमें व्याप्त था। उसका कण-कण पूर्ण भगवत्तामय था। उसके उसी जलसे वनकी लताएँ तक सींची जाती थीं। उनमें जो फूल लगते थे उनके सुगंधकी कहीं तुलना नहीं है॥ १८८॥

उस श्याम कुण्डके जलका स्पर्श होते ही तनका सारा रंग तो बदल ही जाता था, इसका एक कण सेवन कर लेनेवालेकी अन्य सभी आसक्तियाँ समाप्त हो जाती थीं। उसको देखते ही आँखोंमें ऐसी नीलिमा छा जाती कि जो भी उस जलको देखकर फिर कहीं, कभी, किसी, वस्तुपर दृष्टि डालता, वह श्याम ही श्याम दिखायी देने लगता था-संसारकी प्रत्येक वस्तुमें श्रीकृष्णका भान होने लगता था॥ १८९॥

जो भी उस सरोवरकी चर्चा सुन लेता, उसे उसके अतिरिक्त दूसरी कोई भी बात सुहाती न थी। उसके जलकी सुगन्धिको लेकर वायु जहाँ-जहाँ भी जाता, वहाँके सारे प्राणी उस सुगन्ध से ही मोहित होकर उस जलराशिपर निछावर हो जाते॥ १९०॥

उसके चारों तटोंका निर्माण पीले रंगकी मणियोंसे हुआ था। प्रतिदिन उस कुण्डका जल चार बार बढ़कर प्रचण्ड धाराका रूप धारण कर लेता था। पहले उसका वेग उत्तरकी ओर इतना बढ़ जाता मानो बेलके वृक्षोंसे निर्मित कुञ्जोंको वह खण्डित करके रख देगा (खण्डिता ललिता)॥ १९१॥

पूरब और अग्निकोणमें जब उसकी धारा बढ़ने लगती, तब उसकी (श्रीकृष्णकी) गति देखकर यही प्रतीत होता था कि वह किसीको सुखदान करने जा रहा है; उदाहरणके लिये दिनमें यदि कोई तरुणी (दिवाभिसारिका चित्रा) अभिसार करके आयी हो तो उसको अथवा यदि कोई तरुणी (प्रोषितपतिका इन्दुलेखा) जिसका पति परदेश चला गया हो उसको॥ १९२॥

जब वह दक्षिणकी ओर जाने लगता, तब ऐसा प्रतीत होता कि कोई

(श्रीकृष्ण) महुएसे निर्मित मदिरा पीकर अपने शरीरकी सुधि भूलकर भटकता हुआ चल रहा हो और वह उसके तीरपर खड़े वृक्षोंसे टकराकर किंचित् रुकता-सा प्रतीत होता फिर भी उसकी अन्तश्चेतना उसको किधर जाना है, इसका संकेत दे देती थी॥ १९३॥

जब वह (श्रीकृष्ण) पश्चिमकी ओर बढ़ने लगता तो अत्यन्त विह्वल हो जाता। पीत मणियोंकी किरणें (राधाजी) मानो उसे समझाने लगतीं कि मैं तो तुम्हारे हृदयमें ही हूँ फिर भी उसकी अधीरता मिटती नहीं थी और वह (श्रीकृष्ण) वनमें घूम-घूमकर प्रतिक्षण नयी-नयी शोभाका विस्तार करता रहता॥ १९४॥

सूर्यकुण्ड का वर्णन -

वहीं एक अन्य स्थानपर भगवान् मानो आकाशके अतिरिक्त एक हीरक निर्मित प्रतिमा बनकर अब फिर पृथ्वीपर मूर्त हो गये थे। उनकी पूजा उस वनके वासीगणों (तरुणी युवतियों) द्वारा हुआ करती थी। मन्दिरके सामने जलसे भरा एक कुण्ड था, जो सभी ऋतुओंमें खिले हुए कमलोंसे सुशोभित रहता था॥ ११५॥

उस मन्दिरकी रचना कुछ ऐसी कुशलतासे हुई थी कि उसके भिन्न-भिन्न कक्षोंमें सब समय सभी ऋतुएँ उपस्थित लगती थीं। उसकी सीमामें प्रविष्ट होनेवाला कोई भी व्यक्ति कितना ही सजग क्यों न हो, मार्गमें कहीं कोई मोड़ आते ही उसे दिशा-भ्रम हो ही जाता था॥ १९६॥

उस सूर्य-विग्रहकी यह विशेषता सभीके ध्यानमें आ जाती थी कि प्रतिदिन जबतक सूर्य आकाशमें ऊपर चढ़ते रहते, तबतक उस प्रतिमाके नखोंसे पुखराजकी राशि झरती रहती थी और ज्यों ही सूर्य अस्ताचलपर जाने लगते थे, वे रत्न पानी बनकर गलने लगते॥ १९७॥

आराधनाके समय भी एक चमत्कार यह हुआ करता था कि अर्चना करनेवालेके प्राण, देह और मन सभी तेजोमय बन जाते थे और उतने क्षणके लिये केवल एक दिव्य रसमयी सत्ता शेष रह जाती, जो समस्त भेद ज्ञानके नष्ट हो जानेपर जब आत्मा और परमात्मा एकाकार हो जाते हैं, तब उदित होत है। पूजा करनेवाले (वाली) प्रत्येकका यही अनुभव था॥ १९८॥

जावट ग्राम का वर्णन -

सरोवरके तीरपर एक छोटा-सा अद्भुत ग्राम था, जहाँ रहनेवालोंके सभी घर रत्नोंसे जड़े हुए थे। सब ग्रामवासी देवीके कृपा-पात्र थे तथा सभी सदैव निर्भय रहते थे। उनका जीवन राजाओं जैसा था, पर वे शीलवान थे॥ ११९॥

जो सिद्धि पवित्र तंत्र एवं मंत्रोंके द्वारा मिलती है, वह उस ग्राममें बसनेवाली प्रायः सभी युवतियोंको सहज ही प्राप्त थी, परंतु उनके जीवन भरका यह अडिग व्रत था कि वे अपने सुखके लिये कभी किसी सिद्धिका उपयोग नहीं करेंगी॥ २००॥

उनका परस्पर एक दूसरेसे इस जातिका प्रेम था कि वे एक दूसरेके सुखके लिये प्रतिक्षण मर मिटनेको प्रस्तुत रहती थीं। सचमुच उन सभीके प्राण एक दूसरेके साथ गुँथे हुए थे। अन्यत्र कहीं भी इस प्रकारका घनिष्ठ सखीभाव न था, न है और न होगा ही ॥ २०१॥

वे तरुणी युवतियाँ दिनमें उस वनकी कुञ्जोंमें घूमा करतीं औ श्याम-सलिला यमुनाके किनारे उनका रात्रि-विहार होता। देवीकी ऐसी विलक्षण माया थी कि कोई भी जान नहीं पाता था कि गाँव कहाँ है, सरोवर किधर है और उनके क्या नाम हैं॥ २०२॥


''');
        case 'तीसरा शतक':
          return const _TopicPageContent(
              body:
                  '''मन्द मन्थर गतिसे चलकर महाराज वृषभानुकी पुत्री राधाकिशोरी उत्तराभिमुख होकर सुन्दरीवनस्थलके सामने आकर खड़ी हो गयी और वह मनोहर हँसी हँस रही थी। स्वर्णप्रतिमाके सदृश उसकी सहचरियाँ उसे चारों ओरसे घेरकर खड़ी थीं। सब ओर सौन्दर्यकी किरणें बिखेरती हुई किशोरीकी आँखोंसे सरलताका स्रोत प्रसरित हो रहा था। एक और विशेषता थी किशोरीमें -जो सहचरी उसे देखती, उसे अनुभव होता कि किशोरी मेरी ही ओर मुख किये खड़ी हैं॥ २०३॥

उसके कपोलपर, भालपर मोतीके समान श्रम-कण व्यक्त हो रहे थे। झुर-झुर करती शीतल बयारका झोंका उसके श्रीअङ्गोंको छू जाता, मानो बयार उसके श्रीमुखका स्वेद पोंछनेमें व्यस्त थी। मखमल-सी कोमल हरी दूर्वा सामने लहरा रही थी। उसका स्पन्दन देखकर ऐसा लगता था मानो वनस्थलीकी धरा किशोरीका मनुहार करके कह रही हो- 'अरी ! तनिक बैठ जा सही।'॥ २०४॥

किंतु राजतनुजामें अत्यन्त शीघ्रता भरी थी; वह किस भाँति विश्राम करे; क्योंकि समक्षका कमनीय वनस्थल वनस्थलकी धरा उसे आकर्षित जो कर रही थी। अतएव तितली-सी उड़ती हुई वह शीघ्र से शीघ्र वनस्थलकी सीमामें प्रविष्ट हो गयी। मेहँदीकी झाड़ीका पथ आगे फैला हुआ था। सबको साथ लिये वह उसी पथसे ही आगे चल पड़ी॥ २०५॥

इतनेमें शुभ शकुनका संकेत करते हुए कुछ खञ्जनोंपर ही अब सर्वप्रथम उसकी दृष्टि जा पड़ी। उस ओर सबसे अधिक चतुरा सहचरी बोल उठी-'अरी सखि ! यहाँ निश्चय ही कोई अप्रतिम मङ्गलका अनुभव हम सबोंको होगा। इस शकुनका निश्चय ही यही सङ्केत है।' सहचरीकी यह उक्ति सुनते ही किशोरीकी उत्कण्ठा अतिशय परिवर्धित हो गयी॥ २०६॥

तत्क्षण उस ओरसे मानो किशोरीका अभिनन्दन करने आया हो, इस भाँति शीघ्रतासे उड़कर एक कपोत सामने आया। कपोत अपना पंख फैलाकर, कण्ठ फुलाकर नृत्यकी मुद्रामें अवस्थित हो गया- नृत्यकी भङ्गिमाका प्रदर्शन करने लगा। अब क्या था, 'पीहू' बोलता हुआ मयूर भी वहाँ आ पहुँचा और उसने छतरी तान दी। एक मनोहर तरुवरकी डालीपर-किशोरीके दक्षिणकी ओर-एक शुक पक्षी बैठा दीख गया। उसकी दृष्टि पड़ते ही शुकने प्रणिपात किया, अपना सिर डालीसे सटा दिया। अब उड़कर नीलकण्ठ आया; अपनी ग्रीवा झुकाकर, मुख किशोरीकी ओर किये गुड़क-गुड़ककर चलने लगा। नीलकण्ठके साथ ही बटेर, तीतरकी पंक्तियाँ भी उड़कर आयीं और किशोरीके समक्ष मण्डलकी रचना करके, फिर तत्क्षण मण्डलका विघटन करके उन आगन्तुक अतिथियोंकी वह विहंगम-समूह प्रदक्षिणा करने लगा॥ २०७, २०८॥

इस प्रकार रंग-बिरंगे कितने विहंगम क्रमशः आये, उनकी गणना करके मैं कैसे बताऊँ? 'नीलसुन्दर देवता! देखो, प्रकृति नित्य नूतन रूप धारण करती ही रहती है और उससे प्रतिक्षण नानापन सृष्ट होता रहता है। मानो यही विविधता विहंगम बनकर किशोरीका स्वागत करने आयी हो-इतना ही कह सकूँगी मैं।'॥ २०९॥

नृपतिनन्दिनी हँस-हँसकर उनको निहार लेती और सहचरियोंसे कहने लगती-'अरी! इन्हें मैं क्या दूँ? जो अनुराग अपने उरस्थल में लिये ये आये हैं, यह तो इनकी ही निधि है। बस, मेरा भी रोम-रोम इनपर न्योछावर है, इतनी ही उक्तिसे अनुभूतिका संकेत कर सकती हूँ।'॥ २१०॥

'देखो बहिनो! मैं इनकी भाषा नहीं जानती। मैं क्या बात करूँ इनसे, कोई तुममेंसे मुझे बतला सके तो तनिक बतला दो भला!' किशोरी की उक्ति पूरी होते-न-होते वही कीर-जिसने पहले प्रणाम किया था-उड़कर किशोरीके समक्ष आ गया और मानवकी भाँति सुमधुर बोली में सुस्पष्ट वह बोल उठा- 'राजनन्दिनी ! तुम जो भी कहना चाहती हो, हमसे कह दो। तुम्हारी वाणी सुनकर हमारे श्रवणपुटोंमें सुधाकी धारा प्रवाहित होने लगेगी, हम सभी निहाल हो जायेंगे। और सुनो, हमारा इस वनस्थलका निवास सब ओरसे सुखसे परिपूर्ण है; कालसे अविच्छिन्न है और सच तो यह है कि तुम्हारे स्वरसे निःसृत अमृतरस, जो मेरे कर्णपुटोंमें समाया हुआ है, रसका समुद्र बनकर अविलम्ब उमड़ चलेगा सही !'॥ २११, २१२॥

राजपुत्री कुछ पल अपलक रहकर, विस्मयमें डूबी हुई चुपचाप खड़ी रही। एक बार उसने फिरसे उस अद्भुत तोते पर अपनी दृष्टि डाली और अपनी ज्येठा सहेलीको देखने लगी। ज्येष्ठा सहचरीने कुछ सोचकर कहा-'बहिन री! यह शुक कहीं प्रतिपालित हो चुका है। यह विहंगम स्वभावसे ही अनुकरणशील होता है इसकी जातिमें ही यह गुण अनादिसिद्ध है।'॥ २१३॥

किन्तु इस उत्तरसे नृपतितनूजा को संतोष नहीं हुआ। वह तत्क्षण बोल उठी- 'अच्छा बहिन ! तू यह बतला-इसने मेरा परिचय कैसे प्राप्त कर लिया ? देख, तू पता लगाने की चेष्टा कर, यह किसके घर प्रतिपालित हुआ है। इसकी यह प्रतिभा स्वाभाविक है अथवा यह मात्र इसकी रटी हुई विद्या है।'॥ २१४॥

लाडिलीकी बात सुनकर सहचरी सोचने लग गयी। इतनेमें कीर बोल उठा। बोलनेसे पहले उसने अपने अरुण चञ्चुसे धरणीका स्पर्श किया। आनन्द से उसके दृग घूमने लग गये तथा वह बोलता जा रहा था- 'राजकुमारी हे! हम सभी उनके नित्य दास-दासी हैं, जिनके तन की कालिमा एवं गौरपन-निरुपम ही मात्र नहीं, अपितु उनके तनसे यह निरवधि संलग्न भी है भला !'॥ २१५॥

'और सुनो, वे ही जब जितनी शिक्षा देते हैं- हमें पढ़ाते हैं भला, उतना-सा ही ज्ञान हममें उदित हो जाता है। हम तो उनके ही यन्त्रमात्र हैं। देवि ! जय हो, जय जय जय हो तुम्हारी ! देखो, हमारे दृगका पाँवड़ा तुम्हारे स्वागतके लिए तुम्हारे सामने आस्तृत है..... हमारा बड़ा सौभाग्य है, जो तुम यहाँ आज पधार ही गयीं॥ २१६॥

अब तो राजनन्दिनीके विस्मयकी सीमा न रही...। शुक की ओर बार-बार निहारती हुई वह उत्तरकी ओर अग्रसर हुई। एक-से-एक रमणीय सुन्दर प्राकृतिक दृश्य उसके सम्मुख आ जाते, उन दृश्योंपर उसकी दृष्टि टिक जाती और किशोरी चलते-चलते रुककर इस अनुपम सौंदर्यको निहारने लग जाती॥ २१७॥

जिन सबोंने इस वनकी प्रदक्षिणा बाहर-बाहरसे की थी और जिन्होंने इस वनके सौन्दर्यका वर्णन किया था, उनका वह वर्णन - वर्णनका सौंदर्य-किशोरीको ऐसा लगा मानो इस क्षण शतगुणित होकर इसके समक्ष आ गया। पश्चात्तापकी एक लहरी-सी किशोरीके मनको आत्मसात् करने लगी। मन-ही-मन वह सोच रही थी-हाय रे! मैं दूसरे दूसरे वनस्थल में खेलती रही, यहाँ अबसे पहले ही क्यों नहीं आयी.....।'॥ २१८॥

किंतु सुकुमारी राजपुत्री अब सहचरियोंको अत्यधिक थकी-सी दिखने लगी-अविराम वह चलती जो रही है। सहचरियोंकी बातमें, उस वनस्थलके सौन्दर्यमें, उसकी आँखें, मन फँस जो चुका था। यद्यपि अत्यंत कठिनाईसे सहचरियाँ उसे विश्रामके लिये सम्मत कर सकीं, राजनन्दिनी कुछ पग आगे चलकर एक बटतरुकी छाया में बैठ गयीं॥ २१९॥

उस ओर वह तोता भी साथ-साथ उड़ता आया था। वह भी उस वटतरुकी एक डालीपर जा बैठा, पर वह क्षणभर भी चुपचाप न रह सका। वनस्थलके मानचित्रका चित्रण करनेमें संलग्न हो गया वह। वनका मानचित्र अत्यन्त रहस्यभरा था भला। शुक उसकी ओर संकेत करता हुआ बोल रहा था। यहाँ क्या-क्या वस्तुएँ अवश्य, अवश्य दर्शनीय हैं- इसका आकर्षक वर्णन वह किशोरीके समक्ष कर ही बैठा॥ २२०॥

राजनन्दिनी शुककी कही हुई बातोंको पूरे मनोयोगसे सुन रही थी। जैसे-जैसे सुनती जाती थी, तोते के प्रति उसका अनुराग बढ़ता जाता था। और अब तो अत्यधिक बढ़ चुका था। वह बरबस बोल उठी- 'कीर रे! तू आकर मेरे समीप बैठ जा। मैं अपने दोनों हाथोंसे छू-छूकर तुझे प्यार करूँ, यह मेरी अभिलाषा है, तू सुन ले।'॥ २२१॥

पलक पड़ते-न-पड़ते वह सौभाग्यशाली तोता किशोरीके सम्मुख आ गया। सम्मुख ही नहीं, किशोरीके कर-पल्लवपर आकर बैठ गया। किशोरीने अपने प्राणोंके रससे उसका अभिषेक किया, वह करती ही जा रही थी एवं उस ओर शुककी ऐसी दशा हुई, वह आनन्दमें ऐसे विभोर होता जा रहा था मानो उसकी समाधि लगने जा रही हो॥ २२२॥

उस ओर किशोरीकी सहोदरा बहिन मञ्जुश्यामा दौड़ पड़ी। समीप ही एक वृक्ष था। उस वृक्षसे पके हुए फल टप टप कर गिर रहे थे। क्षण बीतते-न-बीतते उसकी अञ्जलि सुपक्व सुमिष्ट फलोंसे भर गयी और वह आकर किशोरीके हाथों पर फल रखकर उसकी ओर देखने लगी; तथा बहिन किशोरी एक-एक फल उठाकर शुक के मुँह में डालने भी लग गयी॥ २२३॥

किशोरीसे इतना आदर-सम्मान पाकर अतिशय नम्रतापरिपूरित वाणीसे शुक बोलने लगा- 'हे देवि ! मैं इस वनका पथ तुम्हें दिखलाऊँ। मैं इसके कोने-कोनेसे परिचित हूँ। इसी वनमें मैं रमा हुआ हूँ। देवि ! अतिशय नगण्य सेवा है यह मेरे द्वारा तुम्हारी। तुम मेरी प्रार्थना स्वीकार कर लो और मेरे पीछे चली चलो॥ २२४॥

देखो किशोरी ! सर्वप्रथम इस वायुकोण के पथसे चलकर उस दिव्य सरोवरको देख लो। इस सरोवरका जल अनुपम सुमिष्ट है। इस जल में महामायाकी कुछ शक्ति प्रत्यक्ष भरी हुई प्रतीत होती है, क्योंकि जल पीते ही आँखें तत्क्षण बदल जाती है, जल पीनेवालेको विचित्र दर्शन होने लगते॥ २२५॥

राजनन्दिनी ! इस सरोवरके वक्षस्थल-जलपर फूले हुए सरोजकी सहायतासे एक नित्यचित्र अंकित है और इसी सरोजके चित्रमें नीले अरविन्द पुष्पोंसे ठीक बीच में एक बिन्दु निर्मित हुआ है। उस बिन्दु बने हुए पुष्प को घेरकर पीतवर्णके नीरज सुमनोंसे निर्मित एक त्रिकोणका अंकन हुआ है और उस त्रिकोण पर घेरा डाले अरुण सरोरुहोंसे एक अष्टकोण बना हुआ है॥ २२६॥

उसको घेरे हुए पीतारुण कमलोंसे फिर दो दशकोण निर्मित हुए हैं। क्रमशः दोनों ही आकृतिमें बड़े होते गये हैं और देखो भला! सतत नव-नव शोभा ये दोनों दशकोण धारण करते रहते हैं। उन दोनों को आवृत करते हुए एक विशाल-श्यामल नव सरोरुहोंसे निर्मित नित्य नवीन नवीन शोभा धारण करनेवाला-चतुर्दशकोण निर्मित हुआ है। अहो ! यह चतुर्दशकोण नित्य अद्भुत सौरभसे परिपूरित रहता है और क्षण-क्षण एक नवीन शोभा इसमें दिखती हैं॥ २२७॥

इनको घेरे हुए अब रामुज्वल नवल अम्भोरुहके अष्टदल परिशोभित हैं और आश्चर्य यह है कि ये सचमुच मानो सूर्यकी किरणों जैसी आभा बिखेर रहे हैं। इनको भी अपने उरस्थलमें लिये हुए श्वेत कमलोंके षोडश दल हैं। वे अद्भुत चन्द्र-ज्योत्स्नाकी शोभाका अपहरण कर रहे हैं॥ २२८॥

उनके चारों ओर मनोहर पद्योंका चतुरश्र निर्मित है, जो पल-पल में क्रमशः सात रंगोंका प्रकाश करता है! इतना ही नहीं, उनपर दृष्टि पड़ते ही ऐसा विभ्रम-सा होने लगता है-न जाने कौन-सी ऋतु है?- पावन, वसन्त, शरद, शिशिर, ग्रीष्म, हेमन्त - क्या है ?॥ २२९॥

और सुनो किशोरी ! जिस समय उपर्युक्त उस नील सरोज-बिन्दुपर आकाशसे-मध्यगगनसे-अंशुमालीकी किरणें पड़ने लगती हैं, तब अहो ! एक अतिशय आश्चर्यजनक घटना घटती है-इस वनस्थलमें जितने भ्रमर हैं, वे सब-के-सब उड़कर यहाँ आ ही जाते हैं। सबकी अद्भुत एकता-सी होकर असंख्य भौरें मिलकर एक सुन्दर कृष्णवर्णके बितानकी रचना कर देते हैं। और ज्योंही मध्याह्नकाल समाप्त हुआ कि देखते-देखते सब-के-सब उड़ जाते हैं॥ २३०,२३१॥

तथा जिस समय तरणिकी किरणें अस्त-गिरिमें प्रवष्टि होने लगती हैं, ठीक इसी समय गूँ-गूँका स्वर भरता हुआ एक भ्रमर दक्षिणके पथसे वहाँ आ जाता है। कुछ पल उन ऊपर वर्णित नलिनोंकी फेरी देकर वह नीचेकी ओर ढल पड़ता है पीत जलरुहके उरस्थलपर और प्रभाततक वह वहीं रहता है भला !॥ २३२॥

राजनन्दिनि ! कह-कहकर मैं कैसे समझाऊँ तुम्हें ? वह कमलोंका बना हुआ चित्र कितना चमत्कारपूर्ण है, इसे प्रत्यक्ष देख लो। देख रही हो, यह जो दुमोंकी पंक्तियाँ उस ओर हिलती दीख रही है, वे सरोवरके कूलोंपर ही तो हैं। बस, दो-अढ़ाई-सौ पद चलनेभरकी देर है, तुम उसके तटपर अपने श्रीचरण रख दोगी॥ २३३॥

इतना ही कहकर तोता उसी ओर उड़कर चलने लगा। राजनन्दिनी किशोरी भी सखियोंको साथ लिये उसी ओर चल पड़ी। पाँच पल पूरा होते-न-होते सरोवरका अग्निकोणवाला तट आ गया। अत्यन्त आश्चर्यमें डूबी किशोरी अनुभव करने लग गयी कि कीरने जो बातें कही थीं, वे सर्वथा सर्वांशमें सत्य हैं॥ २३४॥

उधर कम या अधिक मात्रामें किशोरी एवं सहचरियिोंको प्यास लग चुकी थी तथा सामने ही स्वच्छ जलसे भरा कासार भी मानो उनका ही स्वागत कर रहा था। और तो क्या, पहली ही सीढ़ीके आधे अंशको कासारका जल समीरके वेगसे हिल-हिलकर बार-बार छू रहा था। बस, सब-की-सब अञ्जलिमें जल भर-भरकर उस अमृतकी भाँति सुमिष्ट नीरका पान करने लगीं॥ ३२५॥

और देखो, अहो! आश्चर्य, महा आश्चर्य! केवल मात्र दो घूँट जल कण्ठसे भीतर जाते ही सबके प्राण शीतल हो गये। एक अद्भुत सुखानुभवमें सबका कलेवर-कलेवरका कण-कण निमग्न हो गया। साथ ही सबकी आँखोंमें एक अभिनव रसमयी खुमारी-सी भर आयी। सबके गात्र निस्पन्दन हो गये। सब-की-सब क्षणभरमें वहीं धरापर ढल पड़ीं॥ २३६॥

उस ओर राजनन्दिनी वृषभानुकिशोरीको वहाँ अनुभव होने लग गया कि मानो मैं अनुजाको साथ लिये यहाँ अकेली खड़ी हूँ, और कोई नहीं है मेरे साथ। आगे-पीछेकी सभी बातें उसे विस्मृत हो गयीं। वह आनन्दकी हिलोरोंमें इधर-से-उधर बहकर सरोवरको निहारने लगी॥ २३७॥

अचानक किशोरी अपनी अनुजासे बोल उठी- 'अरी बहिन ! चल, अब हम पूरे सरोवरको घूमकर देखें।' वाक्य पूरा होते-न-होते अनुजाका दाहिना हाथ पकड़कर किशोरी तटके मार्गका अनुसरण करती हुई प्रतीचीकी ओर धीरे-धीरे चल पड़ी। बीस-तीस पग आगे गयी होगी कि एक गौरवर्णा अत्यन्त सुन्दरी अनोखी रमणी सामने आती हुई मिली। यौवनके मदसे वह मत्त-सी दीख रही थी॥ २३८॥

वह रमणी कुछ भी प्रतीक्षा किये बिना दोनों नृपदुहिताओंसे बोल उठी-'शशीमुखी दोनों भगिनियों! चलो, तुम मेरे घर पधारो। तनिक भी विलम्ब मत करो, अतिकाल हो चुका है, पहले चलकर किंचित् भोजन कर लो। मैं ही इस वनकी अधिदेवी हूँ और तुम्हारी नित्य सेविका हूँ।'॥ २३९॥

उस रमणीकी वाणीमें सुमधुर आकर्षण परिपूरित था। राजनन्दिनी अपनी अनुजाको साथ लिये, सरोवरके पश्चिम तटपर अवस्थित उसके आवासमें अपना पैर रख ही बैठी। वह भवन बड़ा ही विशाल था। उसमें पैर रखते ही दोनों बहिनोंको ऐसा प्रतिभात होने लगा, मानो वह सचमुच अपना ही घर हो॥ २४०॥

छोटी बहन अत्यन्त चञ्चला थी ही। वह पहुँचते ही खेलमें तन्मय हो गयी। गृहमें प्रतिपालित जो सुन्दर-सुन्दर पक्षी थे, वे ही किशोरीकी छोटी बहिनके क्रीड़ोपकरण बन गये। किंतु बड़ी राजनन्दिनी चुपचाप सोच रही थी- 'मैं पहले इस गृहमें आ तो कभी अवश्य चुकी हूँ।'॥ २४१॥

उसी क्षण किशोरीकी कानोंमें मानो कोई कह रहा हो-'अहो, जय हो ! सदा जय हो ! काननकी स्वामिनीकी इस रसमयी मुग्धताकी जय हो ! सदा ही जय हो! यह उन्हींका अपना ही सच्चिदानन्दमय आवासस्थल है, किन्तु वह उसे भी भूल रही हैं भला, अपनेको भी भूल रही है, मुझको भी भूल रही हैं।'॥ २४२॥

ऐसा भान होते ही भानुकिशोरी अकचक-सी हुई, सावधान हो उठी। बोलनेवालेका-कानमें संकेत करनेवाला-स्वर तो सर्वथा परिचित-सा लगा। यह स्वर किसका है, इसे वे इस समय जान न पायीं। सामने हंस-हंसिनी-युगलदम्पति बैठे हुए झूम-झूमकर तन्मय हो रहे थे। सहसा हंस बोल उठा मानवी भाषामें- 'प्रियतमे ! मैं एक कथा कह रहा हूँ, एकाग्र चित्तसे तुम सुनो भला॥ २४३॥

उस ओर देखो ! देख रही हो न वनस्थलको ? उसमें जो वह पुष्पित अशोक श्रेणी है, वह अनादि है भला ! और देखो, उसके उत्तरकी ओर जो वह निकुञ्ज-स्थल है, जिसका निर्माण अशोक-तरुओंने ही किया है-हाँ! उसी निकुञ्ज में नित्य, सनातन, अब वे सच्चिदानन्दमय दम्पति निवास करते हैं भला ! जिसका भाग्य अत्यन्त ऊँचा है, वही उनको देख सकता है॥ २४४॥

प्राणप्यारी ! कैसे बताऊँ, वह कबकी घटना थी या है। जब इस वनस्थलपर शासन करनेवाला 'काल' ही वहाँ नहीं है, तब कब बना था, कैसे बना है-कैसे निर्णय हो? बस, अहो! इतना-सा ही कह सकता हूँ कि यह निकुञ्ज- स्थल त्रिकालसत्य है, कालसे परे रहकर नित्य सत्य है यह। वाणी मात्र इतना-सा ही इस निकुञ्जस्थलके सम्बन्धमें संकेत कर सकती है॥ २४५॥

इसी भाँति ही 'वह निकुञ्जस्थल है' - इन शब्दोंको तुम सुन भले लो, किंतु 'देश' नामसे कथित वहाँ कोई वस्तु ही नहीं है भला! अहो! 'तब वह कहाँ है?'-इसका उत्तर देने जाकर इतना ही कहना बनता है- 'वह अपनी ही महिमामें नित्य परिनिष्ठित है भला !'॥ २४६॥

अच्छा, तो प्राणाधिके ! सुनो, अहो! उन निकुञ्ज-दम्पतिके जीवनमें परस्परकी प्रीति अहा कैसी लहराती रहती है; दोनों ही परस्पर एक-दूसरेको निरन्तर निहारते रहते हैं, तथापि निरन्तर अतृप्ति भी बढ़ती ही जाती है; ऐसा भान जो होता रहता है- 'हाय रे, दर्शनका सुख तो मिला ही नहीं'- बस, इतना-सा ही कह सकता हूँ-॥ २४७॥

....अच्छा, आगे सुनो! दोनोंके प्राण सर्वथा एकरूप हो जाते, एक अभिनव विचित्र गति उनकी हो जाती। उन्हें ऐसी प्रतीति होने लगती - अहो ! 'मैं', 'मेरा' इन दो शब्दोंका उच्चारण भले कर लूँ, पर 'मैं', 'मेरा'- इनका अस्तित्व ही कहाँ है? अस्तु, कहनेके लिए वे इसी बिन्दुपर कालको स्वीकार करते हैं। काल उन दोनों का स्वरूप ही है। अस्तु.... फिर खेल आरम्भ होता है॥ २४८॥

उनकी पलकें खुल जातीं। दोनोंके अधरोंपर सुस्मित भर आता। वे नयन-- पुतरियाँ भी जो सुस्थिर थीं, अब कुछ चञ्चल हो जातीं। वे गलबाहीं दिये धीरे-धीरे उठ पड़ते, धीरे-धीरे चलने लग जाते। अहा! उनका स्पर्श पाकर धरा जड़िमासे विभूषित हो जाती.....॥ २४९॥

.... क्रमशः उसके आनन्दका प्रवाह आगेकी ओर चलता। और अहा हा! वे परस्पर जुड़े हुए उसीमें न जाने कहाँ-से-कहाँ बहते रहते। उस धारामें पीछे लौटनेका प्रश्न तो कभी बनता ही नहीं। सृजन और संहारजनित परिणाम तो उस प्रवाहमें किसीने क्षणभरके लिये कभी देखा जो नहीं॥ २५०॥

जो हो, वह घटना तबकी है, जब दम्पति परस्पर अपने गौर-नील तनमें श्रृंगार धरानेकी इच्छा लेकर बड़े ही उत्सुक हो रहे थे। दोनोंमें इस बातकी होड़ लगी थी कि हम दोनोंकी परस्पर श्रृंगार-रचनाकी इस पहली घटनामें- मैं जीतती हूँ कि तुम, मैं जीतता हूँ कि तुम, इसकी आज परीक्षा हो जाय। अस्तु....॥ २५१॥

श्रृंगार आरम्भ हुआ। प्यारीको देख-देखकर ही प्यारे। रचना करते थे और प्यारेको देख-देखकर ही प्यारी रचना करती थी। अचरज यह था कि अपने आप ही उनकी अँगुलियोंमें शृंगारके वे उपकरण आ जाते-जब, जितने, जो आवश्यक होते॥ २५२॥

ग्रीवामें धारण करानेकी माला अपने आप आ जाती, वास्तव में तो प्राणोंकी अभिलाषा ही माली बनती थी। प्राणोंका ही उल्लास सुरभित सुमन बनकर आता था। प्राणोंका स्नेह ही निर्मल नीला-पीला फुलेल बनता था। प्राणोंका अनुराग ही तरल-शीतल विलेपनका रूप धारण करता॥ २५३॥

प्राणोंकी सदा नवीन सुख देने-ही-देनेकी जो परस्पर वृत्ति थी उनमें, प्राणोंकी नित्य नये रसमें सन जानेकी आशा, परस्पर मिले रहनेकी नित्य अभिसंधि-ये ही प्राणोंसे झर-झरकर चित्रांकनकी तूलि बन जाते॥ २५४॥

प्राणोंकी ममता ही काली कबरी डोरी बनती, परस्परका प्राणोन्मादी मोह ही काजल बन जाता। प्राणोंमें जो अद्वयपनका मद था, वही चू-चूकर भ्रू-मध्यका बिन्दु बनता। प्राणोंका प्रणय रोष ही लाल महावर बनता॥ २५५॥

प्राणोंमें बढ़ी हुई प्रीति बंकिम गतिसे चलकर कंघीका रूप धारण कर लेती। परस्परकी प्राणोंकी रति ही उज्ज्वलतम दर्पणके रूपमें परिणत हो जाती। प्राणोंमें बढ़ी हुई पल-पलकी उनकी पारस्परिक आसक्ति ताम्बूलका रूप धारण कर लेती। प्राणोंकी रुचि ही उनका नीला-पीला अम्बर-परिधान बन जाती॥ २५६॥

प्राणोंका स्पन्दन-संचालन ही पयोधरका आवरण बनता था; प्राणोंके स्वर ही किशोरीकी सात बंदवाली चोली बनते। प्राणोंका विश्वास ही उनके लिये अचल-कभी नष्ट न होनेवाला पुष्पसार बनता। प्राणोंका सौन्दर्य ही हाथको विभूषित करनेवाला लीलाकमल बनता॥ २५७॥

इस प्रकार अपने आप प्रस्तुत हुई चिन्मय सामग्रियोंको लेकर, उसमें तल्लीन हुए वे निरुपम वेश-रचना करने लगे। भावोंके आवर्तसे दोनोंके कर-सरोज रह-रहकर हिल जाते और कुछ-के-कुछ चित्र बन जाते; दो तीन बारमें ही एक श्रृंगार पूरा होता॥ २५८॥

इस प्रकार जब वेश-रचना पूरी हो गयी, तब वे कहने लगे- 'बोलो, किसने बाजी जीती ? पहले किसका श्रृंगार (अधिक सुन्दर ढंग से) पूरा हुआ ?' नीलसुन्दर कहते- 'बाजी तुमने जीती प्राणेश्वरी राधे! पहले तुम्हारा श्रृंगार (अधिक सुन्दर ढंग से) पूरा हुआ।' किशोरी राधा कहती- 'प्रियतम ! तुम्हारा श्रृंगार (अधिक सुन्दर ढंग से) पहले पूरा हुआ है, अतः तुमने बाजी जीती।' कोई भी 'पहले' का निर्णय देनेके लिये प्रस्तुत न हुआ। बस, वे परस्पर गलबाहीं दिये हुए झूल-झूलकर हँसने लगे॥ २५९॥

आखिर बड़ी गम्भीर-सी मुद्रा बनाकर किशोरी बोल उठी- 'प्रियतम ! विजेता तुम्हीं सचमुच हो भला।' और क्षणभरका विलम्ब न करके नीलसुन्दर भी उसी स्वरमें बोल उठे- 'प्रियतमे ! सच मान लो, जय तो तुम्हारे ही कर-सरोजमें है।' और फिर दोनों अपनी-अपनी उक्ति दुहराते जाते तथा उनके रवसे सचमुच मधु-सा झरता रहता। निकुञ्ज-वनका कण-कण मुखरित होता रहता उनके मधुमय स्वरसे॥ २६०॥

'अच्छा प्राणेश्वरि ! विचारकर देखो, सच कभी दो होता है क्या? तुम सोचो और निर्णय दो, मेरी बात सत्य है कि नहीं?' और किशोरी उत्तर में तत्क्षण बोल उठती- 'प्रियतम! मुझे सर्वथा स्वीकार है कि सत्य एक ही होता है; अतः तुम भी बार-बार विचार कर देखो कि मेरा कहना सत्य है कि नहीं।'॥ २६१॥

इस प्रकारकी मनोरम बतकही- पवित्र से पवित्र रससे भरी हठमूलक यह चर्चा-परस्पर लगभग साठ पल (चौबीस मिनट) चलती रही। अन्तमें राधाकिशोरीने कहा-'अच्छा, छोड़ो इसे, एक बात कहती हूँ, बड़े ध्यानसे सुनो भला ! अब मैं चाहती हूँ कि अपने आप अपने तनका श्रृंगार करूँ; किंतु तुम्हें आधी घड़ीके लिए अपनी आँखें बंद रखनी ही होंगी॥ २६२॥

प्रियतमने हँसकर ऐसा करना स्वीकार कर लिया...। और कुछ सोचकर उन्होंने दो शर्तें रखीं- 'प्राणवल्लभे ! सुनो! नयनोंको निमीलित मैं रख लूँगा, किंतु तुम्हारे चरणोंके दश नखचन्द्रोंको मैं निरन्तर स्पर्श करता रहूँ। फिर जब मैं भी अपने अंगोंको सँवारने लगूँगा, तब तुम भी आँखें बंद किये रखना।'॥ २६३॥

मन्द-मधुर स्मितके साथ प्यारीने शर्त स्वीकार कर ली और निमेष बीतते-न-बीतते नवीन कौतुक प्रारम्भ हो गया। प्रियतमाके पद-नखचन्द्रको अपने मुट्ठीमें धारण करके नील देवता शांत बैठे रहे और प्रियतमा राधा अपने तनका श्रृंगार करने बैठीं-उनका अभिनव अद्भुत श्रृंगार आरम्भ हुआ॥ २६४॥

मन-ही-मन किशोरी राधा बोल उठी- 'हाय रे ! मैं अबतक प्रियतमको सुख न दे सकी। ये सदा मुझसे अनेक बातें पूछते रहते हैं और मैं लज्जा में डूबकर कुछ भी बोल नहीं पाती। अतएव अपना एक रूप मैं और निर्मित कर लूँ निरवधि, अनन्त कालतकके लिये॥ २६५॥

मेरा वह रूप कर्पूरकी भाँति गौरवर्णका हो और वह करुणासे नित्य परिपूरित रहे। उस रूपकी अलकें अत्यंत कमनीय बन जायें अहो! पर साथ ही मस्तक विभूषित हो जाय नीली जटासे। मेरा वह रूप कभी परिधान धारण न करे; नित्य आवरणहीन रहे वह। किंतु उसके गात्रपर भूषण सब ज्यों-का-त्यों वर्तमान रहें। अवश्य ही वे आभूषण मेरे प्रियतम के पद-सरोजके प्रतिबिम्बसे ही निर्मित हों भला !॥ २६६॥

मेरा वह रूप देवीके बदले प्यारेको नित्य महादेव ही दिखे। प्यारेकी प्रियता भी उसमें पल-पल परिवर्द्धित होती रहे। और मैं युगपत् अपने इस तनको और महादेव-तनको देखती रहूँ, किंतु मेरी यह मुग्धता भी अक्षुण्ण रहे भला !॥ २६७॥

और इसके अनन्तर अहो! जब भी, जो भी प्रश्न ये करें, उस समय तत्क्षण ही उसका सुन्दर समाधान मैं कर पाऊँ, ऐसी योग्यता मुझमें निरन्तर विद्यमान रहे। 'प्रियतमको सुख-ही-सुख दूँ, इसीलिए मेरा जीवन है'- यदि यह बात सत्य है तो मैं अपना जो रूप बनाना चाह रही हूँ, वह रूप प्रियतमकी आँख खुलते ही उनको दीख जाए।'॥ २६८॥

विपल बीतते-न-बीतते प्रियतमके नयन-सरोरुह उन्मीलित हो गये। प्रियतमाका यह अद्भुत रूप निरखकर उनके होठोंपर मुस्कान भर आयी और फिर वे तत्क्षण बोल उठे- 'जय जय हे महादेव! जय जय जय!' इतना कहकर वे नतमस्तक हो गये.....। तथा तुरन्त अपने नये वेषकी रचना करनेमें संलग्न हो गये॥ २६९॥

अस्तु, नीलसुन्दरकी वृत्ति प्रियतमाके चिन्तनमें ही लगी थी-अबसे लगभग तीस पल पहलेतक। और ऐसी अखण्ड तन्मयता थी, जो प्रियतमको प्रियतमा में ही प्रायः परिणत कर बैठी। इसलिये पहले तो उनका साँवरपना गौरवर्णसे आवृत्त हो गया॥ २७०॥

क्षण बीतते-न-बीतते तरुणीके सभी चिन्ह उस नये रूपमें अभिव्यक्त हो गये। वे अप्रतिम सुन्दरी गौरवर्णा रमणीके रूपमें परिणत हो गये-नीलसुन्दर रमणसे रमणी हो गये। सम्मिश्रित भावोंका बोझा इतना गुरु, गुरुतर था, जिसके भारसे दबकर आँखोंने गंभीर-चाञ्चल्यहीन मुद्रा धारण कर ली॥ २७१॥

प्रियतममें अब भी प्यारेपनकी किंचित्-सी गंध बची अवश्य थी। इसलिये रमणी-तनमें बैठे-बैठे वे इस भाँति सोचने लग गये- 'प्रियतमाके अनुरागभरे सभी मनोरथ पूर्ण हो जायें, पूर्ण होते रहें अनन्तकालतक...। और मैं तो अब इन महादेवकी नित्य महादेवी हूँ ही॥ २७२॥

यद्यपि हम चारोंमें ही स्वरूपतः कोई भेद नहीं है- ये चारों-के-चारों सर्वथा सच्चिदानन्दमय हैं ही; किंतु हम चारों-चार पृथक-पृथक सत्ता रखते हुए ही-अनन्त कालतक लीलाप्रिय बने रहकर खेलते रहें भला ! साथ ही मुझमें युगपत् एक कालमें नित्य मुग्धता एवं नित्य संविद भी अभिव्यक्त रहे।'॥ २७३॥

उपुर्यक्त वाक्य पूरा होते-न-होते उन महादेवकी आँखें खुल गयीं...। उन नव देवी की शोभा निहारकर वे मुग्ध हो गये। साथ ही वे पार्श्ववर्तिनी नव देवी क्षणमें ही उन महादेवसे चिरपरिचित हो बैठीं। फिर तो रस-सिन्धु उमड़ पड़ा और देवीको साथ लिये हुए वे महादेव उस महासमुद्रमें निमग्न हो गये॥ २७४॥

उस महासमुद्रमें तरंगें उठने लगीं। पहली लहर में ही उत्तरकी कुञ्ज परिपूर्णतया प्लावित हो गयी। दूसरी लहरमें काननका प्रतीची अंश सर्वथा डूब गया। अत्यंत ऊँची तीसरी लहरमें दक्षिणका वन विलीन हो गया। प्राचीका पूरा-पूरा चौथे प्रवाहमें उस प्लावनमें-रसमग्न हो गया॥ २७५॥

इतना होनोपर-अबतक असंख्य युग-युगान्त बीत चुके थे भला-तब कहीं जाकर इस प्लावनका विराम हुआ। वे महादेव, वे महादेवी इतने कालके अनन्तर उससे बाहर निकल सके। उन चारों प्लावनमें निमग्न रहनेका निरुपम आनन्द, जो उन्हें अनुभूत हुआ था, उसकी ही चर्चा छिड़ गयी॥ २७६॥

मानों रसका स्रोत उमड़ पड़ा हो, ऐसे मधुरिम स्वरमें देवी बोलीं- 'नाथ हे! उत्तर निकुञ्जवाली कुछ बातें बताओ सही!' यह सुनना था कि महादेव गद्गद हो गये और तत्क्षण बोल पड़े- 'हे सती ! सुनो, शाखाचन्द्र न्यायसे किंचित् बात कहता हूँ-॥ २७७॥

युगपत् नित्य निस्पन्द एवं नित्य उच्छलित रहना ही नित्य-रसका स्वरूप है। शब्दों में तो मात्र इतना ही कहना बनता है कि जहाँ वे अपने स्वरूपमें देश-कालसे परे हैं, वहाँकी ही यह चर्चा है। किंतु जो तटपर अवस्थित है, उसकी आँखों के अनुभव में नित्य रसका यह स्वभाव, अहो! क्रमशः ही व्यक्त होता है भला !॥ २७८॥

प्रियतमे ! देखो, वस्तुतः आस्वादन, आस्वादक एवं आस्वाद्य नामवाली वस्तु-इन तीनोंमें कोई भेद नहीं है। फिर भी जहाँ वह रसराज है, वहाँ वह महाभाव भी है ही। इन दोनोंकी ही क्रीड़ा उत्तर निकुञ्जमें चलती रहती है॥ २७९॥

'प्राणाधिक! अच्छा, पश्चिमके वनस्थल की क्या गति है?' यह कहते-कहते देवीकी आँखें झर-झरकर बहने लग गयी। तथा उन जटावाले महादेव की भी ऐसी दशा हुई, मानों भावोंकी प्रवाहिणी उनको ले डूबेगी॥ २८०॥

जैसे-तैसे महादेवने अपनेको संयत किया। तथापि ज्योंही वे कुछ कहने

चलते कि कण्ठ रुद्ध हो जाता। आखिर वे इतना ही बोल सके-'प्रियतमे ! देखो, वहाँ देखो! नित्य रसराज निरुपम शिशु बनकर वहाँ खेल रहा है भला !'॥ २८१॥

'स्वामिन् ! दक्षिणके वनमें क्या है?'- देवीने यह प्रश्न किया किंतु प्रश्नकी शब्दावली पूहा होते-न-होते वे महादेवके अंगपर ढल पड़ीं। उनके श्रीमुखकी मुद्रा ऐसी थी, मानो बिना कहे ही महादेवके उत्तरका आभास उन्हें प्राप्त हो गया हो। साथ ही उस आनन्द अनुभूतिमें ही उनकी चेतना सवा घटिका (सत्तर पल) के लिए विलीन हो गयी !॥ २८२॥

अनुरागभरे अपने शीतल करसे अपनी प्राण-प्रियतमाके अंगोंको सहला-सहलाकर महादेव उनको प्रबुद्ध करने लगे। महादेवके नयनोंसे टपटप अनर्गल अश्रुकी बूँदें झर रही थीं और महादेवीके श्रीअंगोंका उन अश्रुकी बिन्दुओंसे अभिषेक हो रहा था ॥ २८३॥

इस अश्रुवारिसे स्नान करके ही महादेवी प्रकृतिस्थ हो सकीं और तब कहीं महादेवने पुनः चर्चा आरम्भ की- 'प्रियतमे ! देखों, उस दक्षिणके अरण्यस्थलमें ही तो महाभाव नित्य अवनीशनन्दिनी बना हुआ है। देखो, रसराज तो ताना बना है और महाभाव बना है बाना। इनसे ही एक विशाल वितानका आकाशमें निर्माण हुआ है। इसीसे ये दोनों वन-प्रान्तर आच्छादित हैं।'॥ २८४॥

महादेवीके मृदुल कलेवरमें गुदगुदी-सी चल पड़ी। मानो महारस भरते-भरते ऊपरतक भर गया, और तो क्या, उरका-हृदयस्थलका बाँधतक स्पन्दित हो उठा। महादेवी रह-रहकर हँसने लगीं और उनके मुखारविन्दसे मात्र 'पूरब, पूरब' केवल यह शब्द ही निःसृत हो रहा था॥ २८५॥

'अच्छा, तो अब जीवनसंगिनि ! सुन लो, प्राचीके वनकी रहस्यमयी चर्चा भी कर ही दूँ।' वे महादेव बोलते जा रहे थे- 'अभिनव सुन्दर मधुरभावका पवित्र रंगस्थल वही वनस्थल है भला ! यहीं प्रीतिका आश्रय और विषय परस्पर वे दोनों ही तो बने हुए हैं॥ २८६॥

किंतु वहाँ प्रीति अद्भुत साँचेमें जो ढली हुई है। सुनो, उस साँचेपर दोषका आवरण तो निर्मित है, किंतु वास्तवमें वह नित्य निराविल है, पावनतम हैं, पल-पलमें नवीन-नवीन रूप धारण करनेवाला है। इसकी कहीं भी तुलना न है, न हो सकी है और न आगे कभी होगी ही।'॥ २८७॥

इतना कहते-कहते ही महादेवी-महादेव-दोनों ही ध्यानस्थ हो गये। ऊपरसे पुष्पित अशोककी एक डाली झुक पड़ी उन दोनोंपर ही। उन महादेव-महादेवी पर ही डाली सुरभित बयार करने लगी भला! इसके दूसरे क्षण ही हंस हंसिनीसे यह भी बोल गया- 'प्रियतमे हंसिनि ! हम दोनों भी उसी क्षण उन दम्पत्ति (महादेव-महादेवी) के साँस से ही तो झर पड़े हैं- अभिव्यक्त हो गये हैं !'॥ २८८॥

अस्तु, यह उपर्युक्त इतिहास हंस हंसिनीसे कह गया। राजनन्दिनी राधाकिशोरी भी तन्मय होकर इतिहासको सुन रही थी। इतने में ही मराल मरालीको साथ लिए धीरे-धीरे राधाकिशोरीकी ओर चला आया। आकर वे वृषभानुराजनन्दिनीके आगेकी धराको बार-बार स्पर्श करने लगे॥ २८९॥

नीरव निस्पन्द भानुकिशोरी खड़ी रह गयीं। वे कुछ अपनी भूली बातोंको स्मरण-सी कर रही थीं- नीरव रहकर उस पहेलीकी गुत्थी सुलझाती-सी थीं। कुछ पलोंके लिये उनका चित्त इस भावनासे भावित हो उठा- 'यह हंसके द्वारा कथित इतिवृत्त तो मुझसे अवश्य जुड़ा हुआ है अहो !'॥ २९०॥

राजनन्दिनी यह भी सोचने लगी- 'क्यों नहीं मैं मरालसे ही जाकर निर्णय करा लूँ इसका ?' किंतु संकोचसे किशोरीका कण-कण सहसा परिपूर्ण हो गया। मनमें आने लगा- 'आखिर यह हंस विहंग-पुरुष है।' इसीलिये किशोरीने तनिक चतुराईका पथ अपनाया। वे बोल उठीं- 'हंस हे! जहाँ वे दम्पति हैं, मैं जा सकती हूँ क्या?'॥ २९१॥

राजनन्दिनीको उत्तर देता हुआ हंस अविलम्ब बोल उठा- 'निर्बाध, अवश्य ! अवश्य !... अहो! राजचनन्दिनि ! जब चाहो, तभी जा सकती हो. तुम्हारे श्रीचरणोंका ही तो वे नित्य-निरन्तर ध्यान कर रहे हैं। सभी पथिक इसी रस-समुद्रमें ही तो जा-जाकर स्नान करते हैं। किंतु कही अपने आप रस-वारिधि स्वयं उमड़कर समीप आ जाये !....तो यह सौभाग्य कितना दुर्लभ है राजनन्दिनी !'॥ २९२॥

इतना कहकर हंस राजपुत्रीकी फेरी देकर उनकी ओर देखने लगा। राजपुत्री को गुत्थी सुलझती-सी दिखी। किंतु उसका मन तो क्रमशः उलझता जा रहा था उस नेहके जालमें, जो दैवयोगसे हठात् मरालकी ओट लेकर सामने किसी अलक्षित कर-पल्लवने विस्तारित किया था॥ २९३॥

लज्जाका भान हो रहा था राजकिशोरीको; कुछ क्षण रुककर वह धीरेसे बोल उठी- 'मराल! इतना सा और बता दो, मैं वहाँ किस पथसे जाऊँ? मुझे निकुञ्जकी बातें भूली-सी लग रही हैं। तुम सहृदय हो, इसीलिये तुमसे पूछनेका साहस हो रहा है।' ॥ २९४॥

उत्तरमें तत्क्षण मराल बोल उठा- 'महीपनन्दिनि ! दो पथ हैं। तुम जिस पथसे जाना चाहो, जाओ। पहले पथमें दोनों ओर खिले हुए उज्ज्वल सुमनोंसे परिशोभित वृक्षावलि लगी है। हाँ, वह पथ पथरीला अवश्य है, ठण्डापन, सूनापन भी लिये हुए है। इतना ही नहीं, आगे चलकर इस पथमें सभी पदचिन्ह भी अव्यक्त हो जाते हैं॥ २९५॥

दूसरे पथमें पीली लता नीले द्रुमसे लिपटी हुई है। वह पथ बारहों मास नवीन बना रहता है। उसके वृक्ष नौ प्रकारसे फूलते रहते हैं। पुष्प झर-झरकर उसपथको परागमय बना देता है। यह पथ लालिमासे परिपूर्ण रहता है। यह पथ अरुणिम वर्णका है। इसपर चलनेवालेके सुरस्पष्ट पदचिन्ह पद-पदपर उपलब्ध होते हैं॥ २९६॥

वृषभानुनृपनन्दिनि ! सुनो, पहला पथ तो उनका है, जिनका धीरज कभी नहीं छूटता; जिनकी आँखे कभी बाहर नहीं जाती और जिनकी मति सहस्त्रारमें लगी रहती हैं। उस पथके पथिक कभी विश्राम नहीं लेते, अपने पास वे कुछ भी नहीं रखते और यात्रा आरम्भ करनेके पहले ही उनका अहं सर्वथा निकल जाता है ॥ २९७॥

फूली लताओंका पथ उनका है, जो पल-पलमें व्याकुल होते रहते हैं, जिनकी आँखें सौन्दर्यको देखकर फँस जाती हैं; वे अपने अञ्चलमें फूल लिये रहते हैं; उनकी रसमयी अहंताकी छाया क्षणभरके लिये भी उनका परित्याग नहीं करती ॥ २९८॥

'नृपतितनूजे ! अपने इस किंकर मरालकी इस विनतीको तुम सुन लो ! तुम तो तनिक हँसकर केवल अपने चरण-सरोरुहसे दोनों पथको छू भर लेना भला ! इस अग्रिम उपवनसे ये दोनों पथ आरम्भ होते हैं और सटे सटे ही वे अग्रसर होते हैं।' हंसके इतना कहते-न-कहते हंसिनी उड़ पड़ी और उसके पीछे हंस भी उड़ गया ॥ २९९॥

राजनन्दिनी राधाकिशोरी बारह-चौदह पलतक खोई हुई-सी वहीं खड़ी रही। जिधर वे हंस-दम्पत्ति उड़े थे, उसी ओर देख रही थीं वे। सहसा किशोरीकी चित्तवृत्ति अपनी अनुजाकी ओर चली गयी। किशोरीने देखा-वह तो गहरी निद्रामें सुखसे सोयी हुई हैं॥ ३००॥

'क्या करूँ?'-राजनन्दिनी सोचने लगी- 'राजनन्दिनी सोचने लगी' क्या मैं इसे जगा दूँ या मैं ही किंचित् ठहर जाऊँ?' किंतु वे कर्त्तव्यका निर्णय न कर सकीं। उस स्थलपर अनोखी निर्भयता परिपूर्ण थी। गूहका कण-कण भयशून्य था। अतः राधाकिशोरीके मनमें अपनी अनुजाके लिये किसी भी अनिष्टाशङ्काकी बात आयी ही नहीं ॥ ३०१॥

किशोरी सोचने लगी- 'मैं इसी उपवनमें किंचित् घूम लूँ, तबतक अनुजा अपने आप जग सकती है। जगनेपर यह मुझे खोज ही लेगी। मैं दूर जाऊँगी ही नहीं।'- इस प्रकार निश्चय करके राजनन्दिनी उपवनमें प्रविष्ट हो गयीं। लगभग सौ पग चलनेपर ही एक ऊँची-सी शिला उन्हें दिखायी दी॥ ३०२॥

राजनन्दिनी अविलम्ब उस शिलापर चढ़ गयीं और चारों ओर उन्होंने अपनी दृष्टि डाली। किशोरीके जीवनका यह पहला अवसर था कि वे सर्वथा अकेली खड़ी थीं। सहसा उन्हें अनुभव होने लगा कि कोई उन्हें पुकार रहा हो-'प्रियतमे ! इधर आओ! मैं तुम्हारा पथ देख रहा हूँ।'॥ ३०३॥


''');
        case 'चौथा शतक':
          return const _TopicPageContent(
              body:
                  '''वृषभानुराजनन्दिनी जिस शिलापर खड़ी थीं, उसके ठीक सामने प्रतीचीकी ओर सुषमाका आकर एक उद्यान परिशोभित था। उद्यानके कण-कणमें एक ऐसा अप्रतिम पवित्र आकर्षण भरा था कि उसे चित्रित कर देना कठिन ही नहीं, असम्भव-सा ही है। और तो क्या, कोई प्राणी क्षणभरके लिये स्वप्नमें भी-उद्यानके उस सौन्दर्यको यदि देख लेता तो उसकी प्रवृत्ति केवल मात्र इतनी बच रहती- 'चाहे मेरा सर्वस्व स्वाहा हो जाय, पर मुझे उस उद्यानमें प्रवेश करनेका अधिकार मिले।'॥ ३०४॥

उस उद्यानमें पूर्वकी लताओंसे मण्डित राशि-राशि तमालके वृक्ष सुशोभित थे। दक्षिणमें, प्रतीचीमें, उत्तर दिशामें कदम्बोंकी मनोहर श्रेणी समीरसे स्पन्दित हो रही थी। वाटिकाकी भूमि सर्वत्र अनुपम पद्मरागमणिसे विरचित थी; और भानुनन्दिनी जिस शिलापर अवस्थित थीं, उसके ठीक सामने पुष्पोंसे आच्छादित एक क्यारीमें एक वेदी थी। वह वेदी भी पद्मरागसे ही बनी हुई थी॥ ३०५॥

इस लालमणिकी वेदीपर पुष्पित लताओंके बीच नीलम-निर्मित एक मूर्ति थी। मानो, बस ! वह बोल ही उठी, ऐसा लगता था। मूर्ति एक अभिनव सुन्दर बालककी थी जो अपने हाथोंमें वेणु लिये थी और वेणुके छिद्रोंमें जैसे वह स्वर भरने ही जा रही हो; किंतु मुद्रासे ऐसी भी प्रतीति हो रही थी कि अब वह कुछ विचारमें पड़ गयी हो॥ ३०६॥

राजनन्दिनी राधाकिशोरी इस प्रतिमाके ठीक सामने ही प्राची में उस शिलाखण्डपर अवस्थित थीं। प्रतिमामें और किशोरीमें केवल तीन-चार सौ पदका ही अन्तर था। वह तमालकी वृक्षावली उस शिलाका स्पर्श कर रही थीं ॥ ३०७ ॥किशोरीने शिलापर से ही प्रतिमाको सुस्पष्ट देखा था। अवनीशनन्दिनीको वहींसे-उसी प्रतीची दिशासे उन्हें बुलानेका स्वर सुन पड़ा। नीलम निर्मित प्रतिमाका दर्शन एवं उस आह्वानके स्वरका श्रवण, - दोनों एक साथ, एक ही कालमें किशोरीको हुए थे भला !॥ ३०८॥

किशोरीकी उस सुखद-सुन्दर नवीन अनुभूतिका चित्रण कैसे हो? वाणीके वशकी बात ही यह जो नहीं है। ऐसे सभी अवसरोंपर वाणीका कोष सबको रिक्त ही मिलता है। किसीकी गिराको भी उसे व्यक्त करनेकी समुचित शक्ति आजतक श्रवणोंके द्वारा, लोचनोंके माध्यमसे भी नहीं मिली॥ ३०९॥

जो हो, यन्त्रवत् नृपनन्दिनी तत्क्षण उस शिलाखण्डसे नीचे उतर आयीं। आस-पास किशोरको कोई भी पगडंडी न मिली, जो नीलम मूर्तिके पास उसे सीधी पहुँचा दे। वे सघन लताएँ परस्पर जुड़कर जाल-सी बन गयी थीं। उत्तरकी ओरका पथ तो मिलता था, पर प्रतीचीकी ओर अग्रसर होनेवाली कोई क्षीणतम पगडंडी भी उसे दीख नहीं रही थी॥ ३१०॥

उस ओर किशोरीको इन बातोंपर विचार करनेका अवकाश भी कहाँ था। उसका धैर्य छूट जो चुका था। देखते-देखते उन लता-वल्लरियोंके छिद्रमें अपना सिर डाल दिया। जैसे-तैसे वह स्वयं ही पथका निर्माण करने लगी। हाँ, वह पूर्ण सजग थी कि कोई वल्लरी उसके इस प्रयासमें तनिक-सी भी खण्डित न हो जाय॥ ३११॥

निसर्गका नियम है कि मानव बाहर जैसी भावनाका दान करता है, उसके अन्तर्हदयमें तदनुरूप भावना ही आती है और इसीलिये मानो वल्लरियोंके हृदयमें यह भाव जाग ही उठा कि हम इस किशोरी बालिकाका हृदय न तोड़े। इसीलिये वे लता-वल्लरियाँ अपने आप बायें दाहिने, ऊपर-नीचे अपसरित होने लगीं। सचमुच एक छोटा-सा द्वार बन ही गया। देखते-न-देखते राजनन्दिनी उस पार जा पहुँची॥ ३१२॥

किशोरी भावोंसे विभोर हो चुकी थी, इसलिये वास्तवमें उसे दिग्भ्रम हो गया। उसे सीधे प्रतीचीकी ओर चलना था, किंतु वह उत्तरकी चल पड़ी, बस, इतनेमें ही उसके कानोंमें वैसी ही मधुस्यन्दी गिरा झंकृत हो उठा- 'प्राणोंकी रानी हे! तुम तो अपनी बायीं ओर अभी तुरंत मुड़ ही चलो भला।'॥ ३१३॥

किशोरीके नेत्रोंका आवरण हट गया, उसे अनुभव हुआ कि सचमुच प्रतिमा तो बायीं ओर ही है। उसके हत्तन्त्रीके तार उस वैखरी ऊर्मिको स्पर्शकर झंकृत हो उठे। उसे भ्रम होने लगा- 'क्या वास्तवमें वही मूर्ति बोल रही है? अन्यथा मैं इतनी दूरीसे इतना धीमा स्वर कैसे सुन पायी ?'॥ ३१४॥

....वह सब सुध-बुध खोकर, नीचे पथ कैसा है- इसकी भी विस्मृति करके, उस ओर ही दौड़ चली। आश्चर्यका विषय यह था- अरे ! वह वृक्षोंसे टकरायी कैसे नहीं ?... दो-तीन पलोंमें ही वह पद्मराग निर्मित वेदीपर जा पहुँची। वहाँकी हरीतिमासे पूर्ण द्रुमावली, अपने पत्रोंसे निर्मित छत्र ताने खड़ी-खड़ी मानो उसकी प्रतीक्षा कर रही थी॥ ३१५॥

उस वेदीपर-सर्वथा सामने ही- सुरभित पुष्पोंसे निर्मित एक गजरा पड़ा था। किशोरीके मृदुल पग उससे अनजानेमें ही छू गये। ऐसा लगता था, जैसे किसीने जान-बूझकर एक अत्यन्त सुन्दर सरोजके पत्तेपर सजाकर उसे पथके बीचमें रख दिया हो !॥ ३१६॥

किशोरी इतने निकटसे प्रतिमाकी शोभाको आज प्रथम बार निहार सकी। दर्शन होते ही भावोंकी एक आँधी-सी चल पड़ी; और समीरके उस उद्वेलनमें मानों उसका चित्त उड़ गया। अब वातके चञ्चल प्रवाहमें किशोरीके लिये पीछे लौटना सम्भव नहीं रह गया। और तो क्या, जीवनका सम्पूर्ण मानचित्र ही दस-बारह पलोंमें परिवर्तित जो हो चुका था॥ ३१७॥

भोलेपनसे परिपूर्ण शिशुताका भाव जो राजनन्दिनीमें था, वह क्षण बीतते-न-बीतते अन्तर्हित हो गया। उसके स्थानपर, प्राणोंके विनिमयको उद्दीप्त करनेवाले भाव जाग्रत हो उठे। किशोरीके चितवनकी रीति बदल गयी; उसके वारिज-मुखका रंग भी बदल गया; वह अङ्गोंकी संचालन-शैली भी पूरी-की-पूरी परिवर्तित हो गयी॥ ३१८॥

राजनन्दिनीकी दृष्टि ज्योंही प्रतिमाकी ओर जाती- प्रतीत होता, मानों प्रतिमा अर्द्धनिमीलित नेत्रोंसे उसकी ओर निहारती हुई सजीव-सी हो उठी हो। रह-रहकर उसे बार-बार ऐसा ही अनुभव होने लगा, मानों सचमुच अनुपम नीलसुन्दर एक किशोर वयका बालक अपनी साँसोंको रोककर किशोरीको ही ठग रहा हो !॥ ३१९॥

किशोरी भावोंकी आँधीमें बहने लगी-उड़ चली। वह सोचने लगी-फिर अब विलम्ब क्यों हो? क्षणोंमें ही कहीं काल कुछ हेर-फेर कर दें तो....? यह नियम है, स्वर्णिम वेला पल-आधे पलमें ही चल देती है! इस चिन्तनका प्रवाह थमते-न-थमते राजपुत्री पुष्पमालाको अपने कर-सरोजमें उठाकर उस ओर चल पड़ी, जहाँ प्राणोंकी दो सरिताएँ मिलकर एक हो जाती हैं.....एक होकर, महाभाव-समुद्रमें अनन्तकालके लिये निमग्न हो जाती हैं! अस्तु,॥ ३२०॥

अचानक राधाकिशोरीकी बड़ी-बड़ी आँखें क्षणभरके लिये चञ्चल हो उठीं। जब उसने देखा कि वहाँ कोई अन्य दर्शक नहीं है, तब तत्क्षण उसने सुमन-हारको अपनी अञ्जलीमें ले लिया। मानो वह हार उसके जीवनका-यौवनका, सब-कुछका प्रतीक हो-ऐसी भावनासे भावित हुई किशोरीने अविलम्ब उसको प्रतिमाकी ग्रीवामें डाल दिया और दूसरे ही क्षण वह उसके चरणोंमें लुढ़क पड़ी॥ ३२१॥

......किशोरीके नेत्रोंसे अर्नगल अश्रुधारा बह चली। उन बूँदोंसे इन्द्रनीलमणिसे विरचित प्रतिमाके पद-नखोंका अभिषेक होने लगा। अब नृपदुहिता व्याकुल थी केवल इस बातके लिये- अरे हाय! किस उपायसे मेरे प्राण अभी, इनमें प्रविष्ट हो जायँ ? और फिर अनन्तकालतक मैं इनको, केवल इनको ही देखती रह जाऊँ !॥ ३२२॥

किशोरीको विस्मृत हो गया मैं कौन हूँ? कहाँ हूँ? यह विस्मृति कितने क्षणोंकी थी, इसे कौन बताये ? युग-युगान्त बीत गये अथवा क्षण-दो-क्षणोंका ही प्रश्न था यह ? श्रीप्रतिमाके नख मणियोंमें वह कितनी देर लीन रही-कौन निर्णय दे? जो हो, सहसा उसकी आँखें खुल गयीं। उसे भान हुआ कि वह मूच्छित हो गयी थी। अपना सर्वस्व उनको ही समर्पणकर, वह उनकी दासी होकर अपनी सारी सुध-बुध खो चुकी थी॥ ३२३॥

वास्तवमें तो यह किसी व्यक्तिकी प्रतिकृति मात्र है।.... किंतु कुछ भी हो, यह त्रिकालसत्य है कि मैं एकमात्र अब इसकी ही वस्तु हूँ। हम दोनोंका परस्पर ऐसा ही अधिकार है। यह व्यक्ति मुझे मिले अथवा न मिले, इसकी क्या चिन्ता ? निसर्गका अनादि नियम है- परस्पर प्राणोंका सौदा कुछ क्षणोंमें ऐसे ही हुआ जो करता है!॥३२४॥

अपने जीवनकी एकमात्र साध मैं अभी-अभी ही पूरी कर लेती हूँ-एक बार इस मनोहर कण्ठसे भेट लूँ; मुझे एकान्तमें ऐसा अवसर मिले अथवा कभी न मिले ! और तो क्या, मैं इस वनमें फिर आ पाऊँगी, यह भी भाग्यलिपिकी ही बात है.....॥ ३२५॥

...किशोरीकी आँखें पुनः छल-छल करने लगीं; वह उठ पड़ी; बिना परिश्रम उसकी भुजाएँ फैल गयीं। अब.... आगे क्या हुआ ? अहो ! नीलसुन्दर प्राणेश्वर देवता ! तुम उसे स्वयं ही देख लो भले ही.... अहा ! किशोरीका कण्ठसे झूलने लग जाना कितना सरस था.... जय जय जय !.... अरे! मैं अधमा इसकी पवित्रताका चित्रण करके, वाणीसे उसका निरूपण करके, उसकी अनिर्वचनीय पावनताको नष्ट करनेका पाप क्यों बटोरूँ ? मेरे सम्पूर्ण जीवनका एकमात्र सम्बल इतना ही तो है, इसे मैं क्यों खोऊँ.....?॥ ३२६॥

..इतना-सा ही कहना सम्भव है, वह आधे पलका-आधे क्षणका किशोरीका मिलन मानो, आधारशिला बन गयी और उसपर तत्क्षण प्रासादका निर्माण भी होने लग गया। साथ ही अहो! स्नेह, मान, प्रणय, राग, अनुराग, भाव और महाभाव- ये सात अप्रतिम विभाग भी अभिव्यक्त हो ही उठे भला !॥ ३२७॥

राजनन्दिनी राधाकिशोरी ही यद्यपि उस निर्मित प्रासादकी, सातों कक्षोंकी अधिदेवी थीं, किंतु इस समय, जो 'स्नेह' नामसे अभिहित कक्ष था, है और रहेगा, उसमें ही वे अपना पैर रखे हुए थीं। और देखो! इतनेमें ही उनकी अनुजा भी उन्हें ढूँढ़ती हुई झट वहीं आ पहुँची। वह किशोरीके पद-चिन्होंपर ही चलकर आयी थी-धरापर वे पदचिन्ह अङ्कित जो हो गये थे। अस्तु,॥ ३२८॥

किशोरी इस समय प्रतिमासे दो हाथ हटकर बैठी थी। पीछेसे अनुजाने

आकर उसके कंधोंका स्पर्श किया। उसपर हाथ रखकर ही वह बोली-अरी बहिन ! तेरा मन कहाँ है री? तुम मुझे छोड़कर क्यों चली आयी ? अच्छा, जाने दे, अब यह बतला, यहाँ क्या-क्या, कैसे करना है ?॥ ३२९॥

किशोरी अब मानो समाधिसे जग उठी हो-इस प्रकार सचेत हो उठी। उसे किंचित् लज्जाका भी अनुभव होने लगा। वह कैसे यहाँ पहुँची थी, विस्तारसे एक-एक बात उसने अनुजाको बतला दी। बड़ी बहिनसे पूर्ण विवरण सुन लेनेके अनन्तर अनुजा बोल उठी-देख बहिन ! मैं पहलेसे ही इस प्रतिमाकी कुछ बातें जानती हूँ भला !॥ ३३०॥

राजनन्दिनी चौंक उठी-मानों जिस पेटीको वह खोलना चाहती थी उसकी ताली उसे मिल गयी भला! किशोरीकी महानिधि उस पेटीमें ही तो बंद थी। वह बहिनके कंधेको कम्पित करते हुए कह उठी-अरी! तुझे जो कुछ भी पता है, सब-का-सब मुझे अविलम्ब, अभी बता दे। इतना ही कह पायी वह और कनिष्ठाको अपने कण्ठसे लगा लिया......॥ ३३१॥

अच्छा, सुन ले-अनुजाकी आँखें, वाणी, दोनों ही चञ्चल हो उठीं-अरी! जिस दिन मुझे मौसीने ये बातें बतलायी थीं, उस दिन तू रूठी हुई थी भला ! अबसे एक वर्ष पहले की बात है; आश्विन मासकी घटना है; अमावसकी तिथि थी; संध्याका समय था; आज हम सभी साँझीके फूल चयन करके देर से घर लौट पायी थीं॥ ३३२॥

मौसीने मुझे कहा था-अरी सुन, यह लाडिली जो है, बड़ी बावली है भला! तू छोटी तो उससे है, किंतु सच तो यह है कि तू छोटी होकर भी सब बात अच्छी तरह समझती है। मैं बतलाऊँ? आज तुम सबकी मैया तुमपर रुष्ट क्यों हुई? और

आज तुम सब ज्यों ही आयीं, तनिक-सी खीझभरी वाणीमें क्यों बोली ?॥ ३३३॥

सुन, अबसे ग्यारह महीने दो दिन पहलेकी घटना है। एक स्थलपर तेरा श्रीभैया गायोंको चरानेके लिये वनमें ले गया था। सभी बैठे थे और दैवयोगसे शिशुओंमें यह चर्चा छिड़ गयी-इन समस्त अरण्योंका राजा कौन है, कोई बतलाओ तो भला ?॥ ३३४॥

गोपराज नन्द महाराजका पुत्र बोल उठा-अरे भैया, सुन लो तुम सब; यहाँ जितने वन हैं, पहले थे और आगे होंगे, उन सबका स्वामी मैं ही हूँ भला! नन्दनन्दनकी बात पूरा होते-न-होते वह हँसोड़ा शिशु-ब्राह्मण-बालक मधुमङ्गल-हँस पड़ा। मधुमङ्गल सदा ही बारह वर्षकी आयुका ही बना रहता था॥ ३३५॥

अरे मधुमङ्गल ! तू सच बता, क्यों हँसा?- सभी शिशु मधुमङ्गलके पीछे पड़ गये। किंतु मधुमङ्गल भी पक्के गुरुका शिष्य था। किसीके चंगुलमें फँसना उसने सीखा जो न था। हाँ, एक दुर्बलता उसमें अवश्य थी, जो उसे पद-पदपर अपने निश्चयसे च्युत कर देती। कोई मीठी वस्तु उसे किंचित् खिला दे, फिर तो मानो उसने मधुमङ्गलको सदाके लिए मोल ही ले लिया॥ ३३६॥

....सभी शिशुओंने इसी उपायका आश्रय लिया। मधुमङ्गलके आगे उन सबोंने मोदककी भेंटरखी। वह हँसता जा रहा था और उसे खाता जा रहा था। खाते-खाते बोल उठा-अब बतलाता हूँ। देखो, तुम सभी याद कर लो। श्रीभैयाके जो बाबा हैं वृषभानुजी महाराज, वे ही राजा हैं। केवल इस वनके ही नहीं, सभी वनोंके। और तो क्या, जितने भी वन हैं और उनके जो राजा हैं, उनके भी शासक वृषभानु महाराज हैं। और सुन लो, पहले इस नीलसुन्दरके बाप नन्दबाबा भी श्रीभैयाके बाप को कर दिया करते थे॥ ३३७॥

वे जो हम सबोंके दादाजी हैं महीभानु महाराज, सर्वप्रथम उन्होंने ही कर लेना बंद किया था। इतना ही नहीं, उसके पश्चात् दोनों कुलों में- नन्दकुलमें और वृषभानुकुलमें ऐसी अद्भुत मित्रता हो गयी, जिसकी तुलना अन्यत्र नहीं हो सकती-दो राजवंश स्नेहके बन्धनमें ऐसे बँध गये, मानो वे दोनों एक ही माताके पुत्र हैं और दोनों ही अपने पिताकी गद्दी लेनेके अधिकारी हैं॥ ३३८॥

इसीलिये इस नन्दपुत्रको छूट मिली हुई है कि वह जिस काननमें चाहे, गो-चारण कर सकता है। इसे कोई भी, कहीं भी रोक नहीं सकता। केवल श्रीभैयाके बाबा अवश्य ऐसे हैं कि यदि वे चाहें तो इसकी गति-विधिको नियन्त्रित कर दें....। फिर इसके बाबाका जो छोटा-सा वन है, उसमें ही यह घूमता रहे॥ ३३९॥

विशेषतया यह वन, जिसमें हमलोग बैठे बाते कह रहे हैं, वह वन तो केवल केवल जगज्जननीकी ही सम्पत्ति है। इसीमें तो जगदम्बा प्रत्यक्ष निवास करती हैं। इस नन्दपुत्रको कुछ ज्ञात तो है नहीं, तब भी बिना सोचे-समझे यह बोल उठा था- मैं ही स्वामी हूँ- इसके इस भोलेपनपर ही मुझे हँसी आ गयी थी॥ ३४०॥

मधुमङ्गलकी बात सुनकर नन्दनन्दन अपने दृगोंके कोनेसे उसे देखकर मन्द-मन्द मुसकरा उठे। उधर श्रीदामभैयाका प्यार उमड़ चला। उसे वेदना-सी होने लगी- मेरे नित्य सखा नीलसुन्दरकी वह उक्ति क्यों मिथ्या हुई? और वह हँसकर मधुमङ्गलसे पूछ ही बैठा-॥ ३४१॥

अरे भैया मधुमङ्गल ! तू तो पण्डित है, सभी बातें जानता है; तू इतना-सा और बता-क्या कोई उपाय है कि कलका सूर्योदय होनेसे पहले ही मेरे भैया नीलसुन्दरकी यह बात सच्ची हो जाय ? - आज जिस-जिस वनपर मेरे बाबाका अधिकार है, उन सभी वनोंका स्वामी अनन्त कालतक के लिये मेरा प्राणसखा

नीलसुन्दर ही हो जाय ?॥ ३४२॥

विदूषक मधुमङ्गलने इसका उत्तर हाथ-का-हाथ दे दिया-यह कौन-सी बड़ी बात है। बापका इकलौटा बेटा तू ही तो युवराज है। कहीं तू सच्चे हृदयसे इस पदका त्याग कर दे कि मैं इसे स्वीकार ही नहीं करूँगा, तब तो क्षणोंमें ही सब काम बन जाय। देख! तेरी दो बहनें, जो सहोदरा हैं, उनके सम्बन्धमें तुम्हें कुछ पता है कि नहीं, इसे तो तू ही जान! और यदि नहीं जानता है तो मैं बतला दे रहा हूँ, सुन ले। इस गोपराज नन्दके बेटे नीलसुन्दरसे ही तो तेरी इन दो बहिनोंकी सगाई हो चुकी है !.....॥ ३४३॥

अच्छा, अब आगेकी बात ध्यानसे सुन-ब्याह कभी हो, इससे क्या ? यदि आज रातको तेरे बाबा दानपत्र लिख दें- अरे दहेजका दानपत्र रे....! बस, फिर तो जैसा तू चाह रहा है, वैसा-का-वैसा होगा ही-सम्पूर्ण अरण्योंका एक छत्र राजा यह नन्दका बेटा कलसे ही हो जायगा। कोई भी इस बातको जाने-न-जाने, इससे क्या ? अस्तु,॥ ३४४॥

इस प्रकारकी यह चर्चा सभी सखाओंके लिये तो आयी गयी हो गयी। किंतु मेरी छोटी लाडली री, सुन ! तेरे श्रीभैयाके मनसे यह बात नहीं निकली ।.....और जब वह संध्याके समय वनसे लौटा, तब चुपचाप श्रीदेवीके ही मन्दिरमें ही जाकर बैठ गया; तेरी मैयाके पास आज वह नहीं आया। हम सभी चिन्तित हो उठे-वह सदाकी भाँति - घरपर अपनी मैयाके पास क्यों नहीं आया ! अतएव हम सभी उसके पास मन्दिरमें ही जा पहुँचे- मेरे लाल ! आज कोई नयी बात हुई है क्या? किंतु उसने उसका कोई कारण नहीं बताया। उसका मुख आज किंचित् उदास था। तेरी मैया, तेरी मौसी मैं,फिर स्वयं तेरे बाबा और तेरे मौसा-हम चार जने वहाँ थे। बस, इतनेमें तो वह व्याकुल होकर रोने लग गया॥ ३४५, ३४६॥

मैंने समझाया, तेरी मैयाने, बाबाने, मौसाजीने बड़ी अच्छी-अच्छी बातें कहीं; पर तेरे श्रीदामभैयाकी तो रोते-रोते घिग्घी बँध गयी! वह तो केवल इतना-सा बोल सका-बाबा, पहले तुम प्रण कर लो कि मैं अभी जो तुमको कहूँ, उसको तुम ज्यों-का-त्यों सत्य कर ही दोगे॥ ३४७॥

आश्चर्यकी बात यह हुई कि तेरे बाबाने भी पलभरके लिये भी सोचातक नहीं। समीपकी झारीमें अर्चनाके लिये जो जल था, उसे उन्होंने अपने दक्षिण करकी अञ्जलिमें किंचित् ले लिया और गद्गद कण्ठसे बोल उठे-अरे मेरे लाल ! मेरे घर तो तू जगदम्बाका दिया हुआ, भेजा हुआ आया है-उनकी देन है! तू जो भी कह देगा, मैं वैसे-के-वैसे ही कर दूँगा भला !॥ ३४८॥

श्रीभैयाकी आँखोंमें पुनः जल भर आया। वह बोल उठा-बाबा ! मुझे साँवरा प्राणोंसे भी अधिक प्रिय है। आज वनस्थलमें..... इस प्रकार बातें हुई हैं; मेरे हृदयमें इतनी अधिक व्यथा है कि मैं तुम्हें कैसे बताऊँ। बस, उस समय मधुमङ्गल भैयाने जो अन्तिम निर्णय दिया था, उसे ही तुम सत्य कर दो॥ ३४९॥

श्रीदामने रोते-रोते अपने बाबाके कटिदेशमें अपना हाथ डालकर उसे वेष्टित कर दिया, पकड़ लिया उसे। बाबा ! बाबा !...... गद्गद कण्ठसे वह कहता जा रहा था। मेरे जीवनमें छाया की छाया मात्र भी यह अभिलाषा नहीं है कि मैं कभी राजा बनूँ। यह मेरा भी सौभाग्य है कि मेरी प्राणोपम दो बहिनें इस प्रकार असमोर्ध्व भाग्यवाली मुझे मिली है। वे दोनों तो साँवरेकी हो ही चुकी हैं, अब मैं भी धन्य हो जाऊँ-मेरा भैया नीलसुन्दर राजा हो, और मैं उसके पास रहकर उसकी निरवधि सँभाल करता रहूँ॥ ३५०॥

मेरी छोटी लाडली री! हम चारों भी इतने स्नेह-विभावित हो गये थे कि

हम सभी विकल होकर फूट-फूट करके रोने लगे। अहा ! श्रीदामका कितना विशाल हृदय है!... अहा ! बारम्बार इसकी स्मृतिसे हम चारों ऐसे निमग्न हो रहे थे कि हमारे आठों दृगोंसे अविराम अश्रुधाराका अनर्गल प्रवाह बहता ही जा रहा था। तुम्हारे बाबा हम सबोंकी अश्रुधारामें स्स्रान करके सर्वथा उस प्रवाहमें मानो डूबते जा रहे थे। बड़ी कठिनाईसे किंचित् धीरज धारण करके वे बोल सके॥ ३५१॥

......मेरे जीवनमें आज प्रथम बार ऐसे सुन्दर क्षणकी उपलब्धि मुझे हुई है, जिस क्षणमें मैं उच्च स्वरसे सबको सुनाकर कह सकूँ अहा! मेरा पितृत्व आज धन्यातिधन्य हो गया, जो मुझे तेरे जैसा पुत्र मिला। अरे लाल ! मेरी भी यही आन्तरिक अभिलाषा थी। तू धन्य धन्य धन्य है, जो बिना माँगे ही आज सब कुछ दे दिया। अहो !.....॥ ३५२॥

अरी मञ्जु ! इससे अधिक तेरे बाबा बोल नहीं सके ।.... श्रीदामने देखा, मौसीकी आँखें पुनः बरबस झरने लग गयीं। बोल वे भी नहीं सकती थीं। बार-बार अपने अञ्चलसे आँखें पोंछतीं, पर तुरंत पुनः नवीन अश्रुधारा प्रसृत होने लगती और उनका कण्ठ रुद्ध हो जाता। अस्तु, उसी समय महाराज वृषभानुने दूतको बुलाया। उनकी आज्ञा हुई-दूत ! गुरुदेव महोदय महर्षि भागुरिको तुम शीघ्रतिशीघ्र बुला लाओ। दूत आज्ञा-पालनमें तत्क्षण लग गया.....। और गुरुदेव महोदय भी सौ पल (४० मिनट) रजनी चढ़नेके पूर्व ही, वृषभानुपुरमें आ पहुँचे। आज उनके साथ भी एक विचित्र घटना घटी थी। वे सायं-संध्याके लिये ज्यों ही स्नान करने चले कि मानो आकाशसे दिवाकरदेव उन्हें प्रत्यक्ष आदेश दे रहे थे-॥ ३५३॥

.... जाओ, तुम अभी नील सरोवरपर चले जाओ। पहले उस सरोवरको दण्डवत् प्रणाम कर लेना। जाते समय पथके उपवनसे ही कुछ पुष्पचयन कर लेना। उसे अञ्जलिमें लिये हुए उत्तर-पूर्वके कोणपरसे सरोवरमें प्रविष्ट होना। क्रमशः धीरे-धीरे अग्रसर होते जाना और जहाँ अपने आप तुम्हारी अञ्जलि ढीली हो जाय तथा पुष्प जलमें गिर पड़ें, वही रुक जाना॥ ३५४॥

आज प्रथम बार केवल, केवल तुम्हें उस अगाध तलका अनुभव होगा। तुम उस पावनतम जलमें निमग्न होकर, जलके तलपर बैठकर हाथोंसे टटोलने लगना। वहाँ अपने आप तुम्हें निरुपम दो वस्तुएँ प्राप्त होंगी। उन्हें हाथोंमें ले लेना। अपने उत्तरीयसे उसे आवृत कर लेना और फिर जलसे बाहर आकर आर्द्र वस्त्रको पहने-ही-पहने वृषभानुपुरकी ओर चल देना। तुम्हें बुलानेके लिये आया हुआ दूत पथमें ही मिल जायेगा। उसे महाराज वृषभानुने तुम्हें बुलानेके लिये भेजा है॥ ३५५॥

अंशुमालीकी उक्तिके अनुसार ही सब बातें महर्षि भागुरिको ज्यों-की-त्यों मिलीं। वे महासिद्ध पुरुष थे। जो वस्तु मिली थी, उसे अपने उत्तरीयसे ढके हुए वे वृषभानुपुर जा पहुँचे। प्राप्त हुई वस्तुओंमें एक तो नीली प्रतिमा थी और एक स्वर्णनिर्मित पुरइनकी आकृतिका पत्ता था, जिसपर कुछ अक्षर लिखे हुए थे॥ ३५६॥

वह स्वर्णपत्र भविष्यमें दिये जानेवाले दहेजका दानपत्र ही था। और तो क्या, मेरी लड़ैती श्यामे ! देख, भला, तेरे बाबाके हस्ताक्षर उसपर पहलेसे ही अङ्कित थे। उस दिन धनत्रयोदशीकी जो तिथि थी, वह भी पहलेसे ही अङ्कित थी। दो साक्षी थे- एक गुरुवर महोदय और दूसरे भगवान् तरणि। उनके भी चिन्ह उस पत्रपर बने हुए थे। अस्तु,॥ ३५७॥

अग्रिम सभी व्यवस्था गुरुदेव महोदयने की। उस ओर गोपराज नन्द महाराजको-ज्यों ही उन्होंने श्रीनारायणका नीराजन संध्यामें सम्पन्न किया-ऐसा अनुभव होने लगा, मानो भगवान् नारायणका मणिमय श्रीविग्रह मन्द-मन्द मुस्कराकर कह रहा हो॥ ३५८॥

वत्स ! तुम्हारा वह धर्मभाई वृषभानु महाराज तुम्हें बुला रहा है भला ! अतएव कुलगुरु शाण्डिल्यजीको साथ लेकर तुम तो वहाँके लिये अविलम्ब प्रस्थान करो। इस प्रकार भगवत्प्रेषित हुए नन्द महाराज दो घड़ी रात बीतते ही वृषभानुपुर जा पहुँचे- मानो शकटके बलिवदोंमें उड़नेकी शक्ति थी और वे उड़कर आये हों॥ ३५९॥

दोनों धर्मबन्धुओंने मिलनेपर सभी बातोंकी चर्चा की और दोनों ही भावविह्वल हो उठे। दोनों कुलगुरुओंका एक साथ अपने आप निर्णय यह हुआ-बस, अभी सुन्दरी वाटिकामें हमलोग चले चलें। प्रतिमाको वहीं प्रतिष्ठित कर दें और प्रतिमाके चरण-प्रान्तमें ही नीचे यह दानपत्र अखण्ड रूपसे जड़ दिया जाय॥ ३६०॥

री मञ्जुश्यामे ! मैं तो तुम दोनों बहिनोंकी सँभाल करनेके उद्देश्यसे यहाँ वृषभानुपुरमें रुकी रही। उधर तेरी मैया, तेरे बाबा, महाराज नन्द और वे दोनों महामुनीन्द्र- ये पाँचों तेरे श्रीभैयाको आगे करके चल पड़े; सुन्दरी वाटिकामें जा पहुँचे तथा अर्द्धनिशा हो पायी, उससे पूर्व ही वहाँके सारे कृत्य विधिवत् सम्पन्न कर दिये गये॥ ३६१॥

चतुर्दशीके प्रातःकाल जब तुम दोनों खेलनेके लिये बाहर चली गयीं तथा उस ओर जब नीलसुन्दर कलेवा करके वनमें गो-चारणके लिये चला गया, तब उधरसे तो नन्दरानी अपने साथ एक सङ्गिनी लेकर आ पहुँचीं और इधरसे हम दोनों बहिनें भी सुन्दरी उद्यानमें पहुँच गयीं। प्रेमपूर्ण मिलन हुआ हम चारोंका॥ ३६२॥

हम सभी चारों प्रतिमाका सौन्दर्य निहार-निहार करके विथकित हो रही थीं। नन्दरानीके पुत्र नीलसुन्दरकी आकृति ज्यों-की-त्यों उस प्रतिमासे मिलती थी। आश्चर्यकी बात थी कि प्रतिमाका एक अद्भुत वैचित्र्य सबको प्रत्यक्ष यह दीखता था-वह दिनके समय अंशुमालीकी किरणोंको तो नीलाभ बना देती थी और रात्रिमें साढ़े चौबीस चन्द्र उसमेंसे निस्सृत होते रहते थे॥ ३६३॥

उसी दिन वह उद्यान प्रायः सबोंकी दृष्टिसे अदृश्य बना रहता। अमावस्या एवं पूर्णिमाके दिन जो-जो भी उस वनकी फेरी दिया करती थीं उनमेंसे जिसे वहाँ जगदम्बाका प्रत्यक्ष दर्शन हो जाता था, उसको वह ज्योतिर्मय श्रीविग्रह पल-दो-पलके लिये दीख जाता था॥ ३६४॥

गुरुवर जिस समय हम लोगोंसे विदा ले रहे थे, उसी समय उन्होंने तेरी मैयासे यह भी कहा था- मैं बिल्कुल समीप ही खड़ी थी-गुरुवरकी बड़ी गम्भीर मुद्रा थी; और वे बोल उठे थे-रानी ! सावधान होकर सुन लो। अपनी इन दो पुत्रियोंको सँभाले रखना वे दोनों एक उस निश्चित अवधितक सुन्दरीवनमें प्रविष्ट न होने पायें॥ ३६५॥

मेरे प्राणों-की-प्राण छोटी लाडली री मेरी! तेरी जो बुढ़िया नानी है, और हम दोनोंकी जो जननी है, उसीने आज मध्यान्हमें आकर यहाँ हम लोगोंसे यह कहा-अरी छोरियों! सुनती हो, यह जो तेरी छोटी-बड़ी दोनों छोरियाँ हैं, दोनों ही उस वनकी सीमामें घुसती हैं भला ! - बस इतना सुनते ही मैया अत्यधिक घबरा उठी॥ ३६६॥

उसने तुरंत मुझे भेजा। मैं दौड़ी हुई उस वनमें पहुँची, किंतु तुम दोनोंमेंसे कोई भी वहाँ नहीं मिली। खोज-खोजकर मैं थक गया। आखिर क्या करती, लौट आयी। लौटनेके पथमें मैंने देखा - तुम दोनों सूर्य-मन्दिरमें खेल रही थीं। मैं चुपचाप घर लौट आयी॥ ३६७॥

तुम दोनों भी मेरे पीछे-पीछे ही आ पहुँचीं। बस, अब क्या था, मैया बड़े जोरसे तुम दोनोंपर खीझ उठी। यही हेतु है, तुम्हारी मैयाके रुष्ट होनेका। किंतु बड़ी लाडली इस बातसे अनभिज्ञ है। तू बड़ी सयानी है री; अपनी बहिनको सभी बातें ठीकसे समझा दे कि गुरुवरकी रुचिका पालन करना ही हम सबके लिये बड़ा मङ्गलकारी होगा.....॥ ३६८॥

राधाकिशोरीकी अनुजा इतना कहकर कुछ क्षणोंके लिये रुक गयी, और फिर अपनी बड़ी बहिनका कंधा हिलाकर बोली- अरी बहिन ! मौसी जब मुझे यह बातें कह रही थीं, तब तू भी तो पास ही बैठी थी। केवल दस-बीस हाथका ही तो अन्तर था। हाँ, मौसीका स्वर बहुत ही धीमा था और तू मुँह फुलाये हुए थी। इसीलिये यह रहस्यपूरित घटना तू सुन नहीं पायी॥ ३६९॥

मैं जब तुझसे कहने तेरे पास आयी कि बस, इतनेमें ही बाबा आ गये, उनके द्वारा परिलालित होकर तू रूठना भूल गयी और सर्वथा प्रसन्न हो उठी। उसके उपरान्त व्यारू का समय हो गया; हम सभी उसमें संलग्न हो गये; मैं भी बातोंमें फँस गयी और तुझसे यह कहना भूल ही गयी॥ ३७०॥

अतएव देख ले, खूब अच्छी तरह देख ले-उस दिन रातके समय यही प्रतिमा प्रतिष्ठित हुई थी। तू देख सही, प्रत्यक्ष देख ले, यहाँ दिनकरकी किरणें नीली-नीली दीख रही हैं। सब ओर नीला प्रकाश भी फैला हुआ है तथा वही तो वह स्वर्णपत्र है, जो प्रतिमाके चरणोंमें जटित हो रहा है। अहा हा! अपने आप प्रतिमाके दर्शनका संयोग हम लोगोंके लिये लग गया॥ ३७१॥

अब तू बता बहिन, किधर चलना है, किधर चलें ?.... दो-तीन पलतक अनुजा कुछ भी न बोली; केवल देखती रही अपनी बड़ी बहिनको। राधाकिशोरी अपनी अनुजाको कुछ भी उत्तर न दे सकीं। वे किसी गम्भीर चिन्तामें पड़ी हुई दीखती थीं। सहसा किशोरीके मुखसे निकला-अरी! सखियाँ सब कहाँ चली गयीं? तथा यह शब्दावली निस्सृत होते-न-होते किशोरीकी समाधि टूट गयी॥ ३७२॥

बाह्य ज्ञान होते ही किशोरीने देखा सामने वही सुमिष्ट जलका सरोवर लहरा रहा है और घबरायी-सी होकर सखियाँ उसको ही निहार रही हैं। तोता भी एक द्रुमकी डालीपर बैठा वैसे ही देख रहा है। शीतल समीरका झोंका भी वैसा ही बार-बार सबको स्पर्श कर रहा है॥ ३७३॥

सहचरियोंने किशोरीसे पूछा-अरी! तुझे क्या, कैसा अनुभव हुआ, किंचित् बता तो सही ? किंतु किशोरी क्या कहती, उसकी आँखोंमें बरबस पानी भर आया। अब उसके मनमें तनिक भी उत्साह नहीं रहा था, तनिक-सी भी इच्छा नहीं बची थी कि वह आगे बढ़कर वनकी शोभा निहारे। वह चुपचाप उसी पथसे लौट पड़ी, जिससे आयी थीं॥ ३७४॥

घड़ीका चतुर्थांश बीतते-न-बीतते वह वनकी दक्षिणी सीमाके रूपमें स्थित मेंहदीकी झाड़ीके समीप आ पहुँची। राजनन्दिनीने उदास मनसे ज्यों ही उस झाड़ीको पार किया कि उड़ता हुआ वही कीर वहाँ आ पहुँचा। राधाकिशोरीके चरणोंमें प्रणाम करके वह बोल उठा-श्रीचरणोंमें निवेदन कर देनेके लिये नीलदेवताने एक संदेश भेजा है॥ ३७५॥

कीर बोलता ही चला गया-नीलसुन्दरदेवने यह कहा है कि मुझ किंकरके द्वारा कुछ भी सेवा न हो सकी; सचमुच तुम्हारा यह किंकर अत्यधिक अरसिक है। देवि ! तुम अपनी ओर देखकर अपने इस किंकरको अपने हृदयमें अविचल निवास देनेकी कृपा करना भला ! और देखो, तुम इन अनुभूत घटनाओंको अपना मनोभ्रम बिल्कुल मत मानना ! इस वनकी सभी घटनाएँ सच्ची-से-सच्ची हैं। तुम्हारी पहनायी हुई पुष्पोंकी माला मेरे उरपर वैसे ही झूल रही है और नित्य झूलेगी ही॥ ३७६॥

इतना-सा ही कहकर वह तोता वायुकोणमें उड़कर चला गया। राजनन्दिनी भी अपने घरकी ओर अग्रसर हुईं, किंतु उनका मन उस वनस्थलमें ही फँसा रह गया। चारों ओर सहचरियाँ बोल रही थीं; पर राधाकिशोरी एक शब्द भी न बोलीं- भाव-विद्युत्से परिचालित उनके तनका ढाँचामात्र ही घरकी ओर लौट रहा था॥ ३७७॥

घर आते ही मैयाने राधाकिशोरीको हृदयसे लगा लिया। अपने नयनोंकी धारासे किशोरीको नहलाकर वे पूछने लगीं- मेरी लाडिली री! तूने वनमें क्या-क्या, कैसे देखा ?... किशोरीकी सहचरियोंने तो अपनी-अपनी बातें बतायीं; किंचित्-सी बात लाड़लीकी छोटी बहिनने भी कही; नीरव तो एकमात्र राधाकिशोरी ही रहीं। वे चेष्टा करनेपर भी कुछ बोल न सकीं॥ ३७८॥

राजप्रसादसे सटा हुआ जो विशाल उद्यान था, जिसमें किशोरी प्रायः संध्याके समय अवश्य जाती थीं, उसमें वह आज भी जा बैठीं। उस दिनकी संध्या हो चुकी थी, तभी किशोरी उद्यानमें आयीं थीं, किंतु आज किशोरीको सर्वथा एकाकीपन प्रिय था। उसे अनुभव हो रहा था, मानो उस वनकी वह नीली प्रतिमा सम्मुख खड़ी है॥ ३७९॥

किशोरीके कर्णपुटोंमें तोतेके द्वारा प्रेषित नीलुसन्दरके संदेशकी ध्वनि गूँज रही थी; उमसें कहीं भी तनिक विराम नहीं हुआ था। और तो क्या, उस संदेशमें भरी हुई मधुकी धारा उत्तरोत्तर वेगवती होती जा रह थी। उसकी स्पर्शेन्द्रिय एवं नासिकामें तथा रसनामें भी-नीली प्रतिमाकी ग्रीवामें भुजा समर्पणके समय जो अनुभूति हुई थी वही परिपूर्ण हो रही थी॥ ३८०॥

रजनी दो घड़ी बीतते-न-बीतते, सहचरियाँ उसके समीप आ बैठीं, किंतु किशोरीको वे क्षणभरके लिये भी वहाँ खड़ी हुई दीखी नहीं। किशोरीने तो यह अनुभव किया कि पाँच सातकी संख्यामें नीली प्रतिमा ही उसके सम्मुख मूर्त्त हो रही है-आत्यन्तिक विस्मयमें भरी हुई उसकी आँखें सहचरियोंको निहार रही थीं॥ ३८१॥

सखियाँ न जाने कितनी ही बार कितनी ही बातें कह गयीं, किंतु किशोरीके कर्णपुटोंमें उनकी कहीं हुई उक्तियाँ, एक भी उक्ति स्थान न पा सकी। उसे अनुभव हो रहा था कि नीली प्रतिमा सामने खड़ी है। उसके होंठ हिल रहे हैं और होठोंके अन्तरालसे यह शब्द निःसृत हो रहे हैं- प्रियतमे ! वल्लभे ! प्राणेश्वरि.....॥ ३८२॥

चिन्तामें निमग्न हुई सखियाँ अपने कर्त्तव्यका निश्चय करने लगीं, किशोरीको शीघ्रातिशीघ्र महलमें ही ले चलना चाहिये-सबका यही निश्चय हुआ। जैसे ही उस सयानी सहचरीने उसका हाथ पकड़ा कि राधाकिशोरीको यह अनुभव हुआ-नीली प्रतिमाने ही मेरा हस्त-धारण किया है-एक प्राणस्पर्शी अनिवर्चनीय सुखका अनुभव करके किशोरी भूल गयी अपने आपतकको॥ ३८३॥

...जैसे-तैसे सखियाँ उसे विश्रामकक्षमें ले आयीं। अनुजाने सुरभित विलेपन किशोरीके तनमें लगाना आरम्भ किया, किंतु किशोरीको अनुभव हुआ कि यह सौरभ तो नीली प्रतिमासे झर-झरकर मेरे अङ्गोंमें लगता जा रहा है, मेरे अङ्गोंमें भरकर उनको सुरभित कर दे रहा है॥ ३८४॥

कोई भी सहचरी उसे आज ब्यारू न करा सकी। कोई उपाय न देखकर अनुजाने एक मिठाईको अधजूठ करके बड़ी बहिनके होठोंपर रख दिया। बड़ी बहिनको अनुभव हुआ-अहा! यह तो नीली प्रतिमाका अद्भुत अनुग्रह है.....इस प्रकार अनुजाकी दी हुई मिठाईको वह खाने लगी॥ ३८५॥

ऐसे ही अनुजाने उसे जल भी पिलाया तथा भुला-भुलाकर उसको पान भी खिला दिया, किंतु किशोरी तो अनुभव कर रही थीं कि यह नीली प्रतिमाका ही प्रीतिदान है। उसकी यह अनुभूति गाढ़ी-से-गाढ़ी होती चली जा रही थी॥ ३८६॥

रजनी एक प्रहर व्यतीत हो चुकी थी कि सहसा किशोरी उठ बैठी। अपनी ही दोनों हथेलियोंपर उसकी आँखें जा टिकीं। उसे अनुभव हुआ-अरे! यह तो पूरी-की-पूरी नीली प्रतिमा जैसी है। और तो क्या, बाहुमूलतक उसके दोनों हाथ नीलवर्णके हो गये थे॥ ३८७॥

दो-तीन पलोंके अन्तरसे किशोरीने अपने लहँगेको किंचित् ऊपरकी ओर सरकाया और ध्यानसे अपने चरणोंको देखने लग गयीं- अहो! यह कैसे यह गुल्फ, ये घुटने सर्वथा नीली प्रतिमा जैसे हैं। ज्यों-की-त्यों वही नीलापन सम्पूर्ण चरणोंमें परिपूरित जो है॥ ३८८॥

एक पल जाते-न-जाते किशोरीको भान हुआ-अरे! किशोरीपनका तो कोई भी चिह्न मेरे अङ्गोंमें नहीं है। मेरा सम्पूर्ण शरीर नीली प्रतिमा जैसा ही है। और देखो, अरे! आभूषणके बदले यह तो वेणु धारण किये हुए है॥ ३८९॥

एक-दो पलतक तो राधाकिशोरीकी दशा अत्यन्त विचित्र-सी हो रही थी। इस भाँतिके ऊहापोहमें उनका मन पूरी तरह उलझ गया था। यहाँतक कि वे यह भी निर्णय नहीं कर पा रही थीं कि वे सर्वथा पुरुष- वह नीली प्रतिमा-ही हैं अथवा रमणी हैं! यह परिवर्तन जो उन्हें दीख रहा है, यह वास्तविक है अथवा भ्रमित हो रही हैं वे। क्या उन्हें अपने स्वरूपतककी भी विस्मृति हो रही है ?॥ ३९०॥

आधे पलके लिये किशोरीकी आँखें मुँद गयीं और उन्हें निर्णय मिल गया। उनका मन उसीमें लीन हो गया-किशोरीका सम्पूर्ण मैं-पना उस नीली प्रतिमामें ही सर्वथा पर्यवसित हो गया भला !..... अब वहाँ सब ओर नीली-नीली लहरें फैल रहीं थीं॥ ३९१॥

इसके पश्चात् नीलिमाकी अभिव्यक्त परिस्थितिका और इसके भी आगे-आगेसे-भी-आगे संविन्मयी उसकी नीली रस-सत्ताका, जिसमें एक अनिर्वचनीय, अचिन्त्य, अप्रतिम पीतिमा नित्य विराजित है- अहो, वह तो अज्ञेय है भला ! उसका निर्देश मैं कैसे करूँ ?॥ ३९२॥

जब उस शुक्ल पक्षकी- शरद-निशाकी प्रथम प्रतिपदा बीत चुकी थी, तब कहीं जाकर राजतनूजाको अपने गौरवर्ण तनका भान हुआ। मैया, मौसी, सभी सहचरियाँ भारी चिन्तामें पड़ी हुई थीं- किशोरीके मनका जो अचानक अद्भुत परिवर्तन हुआ था, उसको लेकर॥ ३९३॥

मैया कहती-मेरी लड़ैती री! सचमुच बतला दे, तुझे क्या हो गया है? तू जो भी वस्तु चाहेगी, तुझे अवश्य-अवश्य दे दूँगी। किंतु लड़ैती क्या उत्तर दे? अब उसमें कोई भी रुचि अवशिष्ट जो न रही थी। उसकी सम्पूर्ण अभिलाषायें उन नील देवतामें जाकर मिल चुकी थीं; अपना अस्तित्व खो बैठी थीं वे। अस्तु,॥ ३९४॥

आज भी किशोरीका कोई-सा व्यवहार संतुलित रूपसे नहीं हो सका। सखी जब उसके हाथपर पान रखकर बोलीं- अरी! बतला, क्या है? उसके उत्तरमें किशोरी बोल उठी-विद्युत् वारिदमें रहती है; किंतु पहले विद्युत् चमकती है, तब जलधर झरने लगता है!॥ ३९५॥

एक सहचरी अलककी रचना करने आयी। उसने किशोरीसे प्रस्ताव किया। पहले तो उसने कोई उत्तर ही नहीं दिया और जब बोली, तब कह उठी-प्रियतामें सुख है और सुखमें स्वभावसे ही प्रियता है। यह भेद नित्य क्यों बढ़ता रहे ? दोका अस्तित्व इसीलिये तो है !॥ ३९६॥

अरी क्यों! आज सुमन लेकर तू अर्चना करने नहीं जायेगी? उच्च स्वरसे चित्रा बोल उठी। किंतु किशोरीने सुना या नहीं-कौन बतलाये ? उसके कण्ठसे तो एक धीमा स्वर मात्र निकला - पपीहेको किसने यह बुद्धि दी? मैंने या उनने ? अथवा इसने अपने से ही उसे पा लिया ?॥ ३९७॥

अनमनी-सी हुई किशोरी बैठी थी। सामने कुछ फूल खिले हुए थे। सहेलीने आकर कुछ कहा; किंतु वह कुछ और ही समझ बैठी। वह अन्यमनस्क-सी बोल गयी- यौवन ऐसा ही है, जैसे ये पुष्प खिलते हैं। यह नियम तो है नहीं कि भ्रमर प्रत्येक पुष्पका रस तो पी ही ले ?॥ ३९८॥

....इस प्रकार तीस घड़ी बीतनेके अनन्तर द्वितीया तिथिकी रजनी आयी। रजनीके प्रत्येक प्रहरमें ही वह भावित होकर भाग चलती। पहले प्रहरमें किशोरीको दीखा-वे एक चम्पक माला लेकर आये हैं और झटसे मेरे कण्ठमें डालकर चल पड़े हैं... वह भी उनके साथ ही चल पड़ी॥ ३९९॥

दूसरे प्रहरमें उसे अनुभव हुआ-वे मल्लिका पुष्पोंका हार लिये सम्मुख खड़े हैं... तीसरे प्रहरकी विचित्र अनुभूति यह थी- यूथीका गजरा लिये खड़े हैं वे... चौथे प्रहरमें किशोरी देखने लगी- जपा-कुसुमोंकी माला उनके हाथोंमें सुशोभित है और वे मेरी ओर देख रहे हैं। आगे, नीलसुन्दरका उस ऊषाकालीन रसदान अत्यन्त निराले-से-निराला था भला॥ ४००॥

....इसके पश्चात् राधाकिशोरीके नयनोंसे जो अश्रुका स्रोत चल पड़ा, वह अविराम चालीस प्रहर और दो घड़ीतक निरन्तर चलता ही रहा! मानों वह राजसदन तो उसमें ही निमग्न होने चला। इसी समय उन नीलदेवताका अलक्षित कर-रक्षाके लिये प्रस्तुत हस्त-कमल-व्यक्त हो उठा। अस्तु,॥ ४०१॥

प्रातः समीर स्पन्दित हो उठा था कि इतनेमें ही वह बहुश्रुत शुक उसी कोनेसे आ पहुँचा। क्षणभर भी विराम न लेकर वह बोल उठा-" श्रीचरणोंमें उनकी शत-शत प्रणति स्वीकार करो किशोरी ! उनके अन्तस्तलका विनम्र निवेदन यह भी है- 'प्रियतमे ! धैर्य धारण करो, मुझसे अब तुम्हारा नित्य मिलन होगा'॥ ४०२॥

किशोरी ! सुनो, बारह शुभ मास इस क्षण पूरे हो रहे हैं, जब उन्मत्त हुए मुनिराज तुमसे विदा ले रहे थे। उनका दिया हुआ वही वरदान इसमें निमित्त बनेगा भला ! श्रीचरण सरोरुहकी जय हो, जय हो, निरवधि जय हो !"॥ ४०३॥

अवनीशनन्दिनीके वे तप्त अश्रु पल बीतते-न-बीतते अत्यन्त शीतल हो गये। मुरझाया हुआ आनन-सरोज अहो! क्षण बीतते-न-बीतते फिरसे खिल उठा, किंतु किसीको भी इस क्रन्दनका विराम अचानक कैसे हो गया, यह पता न लग सका। हाँ, अब तो सभी सुखकी लहरोंमें डूब उतरा रहे थे; ऊपर आकाशमें भगवान् अंशुमाली भी हँस रहे थे॥ ४०४॥



''');
        case 'पाँचवा शतक':
          return const _TopicPageContent(
              body:
                  '''महाराज वृषभानुके गृहमें एक दिन महर्षि दुर्वासा अतिथि हुए। वे अत्यन्त कोपन स्वभावके थे। उनके पिङ्गल वर्णकी दाढ़ी और सिरपर जटा सुशोभित हो रही थी। नेत्रोंमें अङ्गोंमें तपका तेज परिपूर्ण हो रहा था। ऐसा लगता था, मानो अग्निदेव उनके अङ्गोंके अन्तरालसे मूर्तिमान् हो रहे हैं- इतने तेजस्वी थे वे॥ ४०५॥

महाराजने उनके चरणोंमें प्रणिपात किया; महारानीने उनके चरणोंका प्रक्षालन किया। विधिवत् अर्चाके अन्य उपचार उनके समक्ष प्रस्तुत किये गये और तब महारानी और महाराज दोनों हाथ जोड़े उनके समक्ष खड़े होकर अग्रिम आज्ञाकी प्रतीक्षा करने लगे। गम्भीर स्वरमें मुनिराज बोले-'धर्मज्ञ राजन् ! सुनो, मुझे तुम्हारे इस गृहमें सोलह प्रहर रहना है, तुम जो भी स्थान बतलाओ, वहीं रह लूँगा।'॥ ४०६॥

जिस प्रासाद-कक्षमें राजपुत्री राधाकिशोरी प्रतिदिन शयन करती थी, वही स्थान सबसे सुन्दर था; वृषभानु नरेशने उसमें ही उन्हें ठहराया। मुनिराज दुर्वासा फिर बोले-'यहाँ मैं एक घड़ी एकाकी ध्यानस्थ होकर रह लूँ, उसके पश्चात् तुम आकर आवश्यक सेवा कर सकते हो।' उपर्युक्त वाक्य पूरा होते-न-होते मुनिराज ध्यानस्थ होकर बैठ गये॥ ४०७॥

महाराजने उनको नमस्कार किया और चल पड़े। वे सीधे अपनी कुलदेवीके मन्दिरमें दौड़ते हुए से वे चले आये ॥ महर्षि दुर्वासाके स्वभावसे वे परिचित थे। अतएव भयपूर्ण चित्तसे- जननी पाहि पाहि- कहकर विग्रहके श्रीचरणोंमें उन्होंने अपना मस्तक टेक दिया॥ ४०८॥

जगदम्बाके कनकमय विग्रहके अधरोंपर मुस्कान भर आयी। वीणासे भी अधिक सुमिष्ट वाणीमें जगदम्बाके अधरोंके अन्तरालसे हुए शब्द व्यक्त होने लगे-वत्स ! तुम चिन्ता मत करो; मुनिराजका मिलना तुम्हारे लिये अत्यन्त सुखद होगा, किंतु उनके समक्ष अपनी दोनों दुहिताओंको आगे करके जाना भला !॥ ४०९॥

और इस प्रकार कहना - 'मुनिपुङ्गव ! मेरा निवेदन कृपया सुन लें। जो मेरा एक पुत्र है, वह तो अत्यन्त चञ्चल है। उसके द्वारा आपकी यथोचित सेवा सम्पन्न न हो सकेगी। सेवाके योग्य तो मैं, महारानी और मेरी दो पुत्रियाँ-हम चार ही हैं। हम चारोंको अथवा दो को, जैसा उचित समझें, सेवाके लिये स्वीकार करें। आपके चरण-सरोरुहकी सेवा पाकर हम कृतार्थ हो जायँ। हाँ! जगज्जननीकी रुचि भी मैं निवेदन कर दे रहा हूँ-वे चाह रही हैं कि आप मेरी इन दो पुत्रियोंपर ही कृपा करें।'॥ ४१०॥

जगदम्बाके अधरपुटोंसे उपर्युक्त इतना-सा आदेश व्यक्त हुआ। किंतु इतना सुनते ही महाराज वृषभानुका मन निश्चिन्ततासे पूर्ण हो गया। रानी तथा दोनों पुत्रियोंको साथ लिये हुए, जहाँ मुनिराज ध्यानस्थ बैठे थे, वहीं अवनीश लौट आये। जब मुनिराजके नेत्र उन्मीलित हुए, तब जगदम्बाकी रुचिके अनुसार ही महाराजने मुनिके चरणोंमें निवेदन कर दिया। बड़ी कन्या गौरवर्णा थी और कनिष्ठा श्यामवर्णा। उन दोनों राजपुत्रियोंपर ज्यों ही मुनिराजकी दृष्टि पड़ी कि उन्हें ऐसा प्रतीत हुआ, मानो उनके सम्पूर्ण तनमें विद्युत्-सी व्याप्त हो गयी है॥ ४११॥

मुनिराज आसन छोड़कर उठ पड़े। उनका रोम-रोम कम्पित हो रहा था। नेत्रोंके पलक पड़ने बंद हो गये। अचानक अपने आप उनकी अञ्जलि बँध गयी। क्या हुआ, कैसे हुआ, महारानी एवं महाराज अचरजमें पड़ गये। हाथ जोड़े वे दोनों खड़े थे, किंतु वह छोटी राजकन्या हँस रही थीं ॥ ४१२ ॥

भयभीत होकर रानीने अपनी छोटी पुत्रीके अधरपुटोंको अपने हाथोंसे ढक दिया, किंतु व्याकुल हुए मुनिने हाथोंका नचा-नचा करके सङ्गेत किया-'इसे तुम छेड़ो मत; यह जैसे कर रही है, करने दो।' मुनिके दोनों दृगोंसे अश्रु-प्रवाह झर रहा था ॥ ४१३॥

मुनि भाव-समाधिमें निमग्न होने लगे। उनके सामनेका दृश्य बदल गया। वृषभानुराज-प्रासादके स्थानपर अब वे वनस्थलकी एक लीला देखने लग गये-आज तो आम्रमञ्जरी प्राशनकी वसन्त पञ्चमी है। वृषभानुपुर तथा नन्दग्रामके सम्पूर्ण स्त्री-पुरुष एकत्र हो गये हैं नील लहरोंवाली कलिन्दनन्दिनीके तटपर। होलीकी प्रथम दिन वाली लीला मुनिकी दिव्य आँखोंने देखनी आरम्भ की-यद्यपि यह लीला संघटित हुई थी आजसे छप्पन महीने और एक दिन पूर्व ॥ ४१४ ॥

उस दिन विविध उपचारोंसे पञ्चदेवताका आराधन वहाँ हो रहा था। महारानी सहयोग दे रही थीं। अपनी अलबेली पुत्रीकी-प्राणोंसे बढ़कर प्यारी बेटीकी रक्षाका सँभालका भार अपनी छोटी बहिनपर रखकर ही उन्होंने ऐसा किया था॥ ४१५॥

उस समय बड़ी लाड़िलीकी आयु सत्रह मास पूर्ण होनेमें तीन दिन घट रहे थे, किंतु अभी भी वह अपनी आँखें मूँदे ही रहती थी। हाँ, वह एक नाम सुनकर अपनी आँखें कुछ देरके लिये खोलती अवश्य थी; किंतु वह भी तभीसे, जब वे वीणाधारी महर्षि नारद वृषभानुपुर पधारे थे॥ ४१६॥

अथवा एक अवसर और था, जब उनकी आँखें अपने-आप खुल जातीं। जब कभी नन्दरानी अपने नीलसुन्दर पुत्रको साथ लेकर वृषभानुपुर आतीं और उस नीले शिशुका अप्रतिम अङ्ग सौरभ वृषभानुपुत्रीको प्राप्त होता - जबतक उस सौरभकी अनुभूति उसे होती रहती, तबतक उसके दृगनलिन खुले ही रहते। किंतु जैसे ही वह नीला शिशु उसके नेत्रोंसे ओझल होता कि बस, राजपुत्रीकी आँखें अपने-आप निमीलित हो जातीं॥ ४१७॥

आज भी उसी प्रकार राजपुत्रीकी सलोनी आँखें निमीलित एवं उन्मीलित हो रही थीं। उसी समय उसको अङ्कमें लेकर मौसी सोच रही थी ।..... मौसीका कलेवर रह-रह करके कम्पित हो जाता। पुलकावलि उदित हो जाती; नेत्रोंमें जल भर आता; रह-रह करके उन्हें अपने शरीरकी सुधि भी भूल जाती और वे रस-समुद्रकी लहरोंमे न-जाने कहाँ-से-कहाँ बहने लगीं....॥ ४१८॥

मौसी विचारके प्रवाहमें सोचने लगी- 'अहो! यदि ऐसी ही सुषमाशालिनी अप्रतिम सुन्दरी इसीकी एक सहोदरा, सुखकी पुञ्जभूता बहिन और होती तो ? अहो ! तब या तो मैं इसे अथवा उस कनिष्ठाको सदा अङ्कमें धारण किये रहती और मेरी बहिनके वक्षःस्थलपर या तो यह अथवा वह सुशोभित रहती।' अस्तु,॥ ४१९॥

मनमें ऐसी अभिलाषा उदित होते ही मौसी विकल हो उठी। तत्क्षण अनुग्रहमयी आकाशवाणी उनके कानोंमें गूँजी-'अरी मैया ! तुझे त्रिकाल-सत्यका सङ्केत हो रहा है। देखो, तुम इस लाड़िली पुत्रीको छूकर किसी वस्तुकी भी चाह करोगी तो वह वस्तु तुम्हें मिलेगी ही और तुम्हारा परम मङ्गल होगा।'॥ ४२०॥

मौसीके तन, मन आनन्द परिप्लुत हो उठे। उस ओर देवोंकी विधिपूर्वक अर्चना सम्पन्न हो गयी। अब डफ बजने लगे, आकाश अरुणाभ बन गया। अंशुमालीका किरणजाल गुलालसे धुँधला हो गया। अबीर और गुलालसे रचित आटोप क्रमशः घना-से-घना होता चला गया॥ ४२१॥

उस दिनके उस अतिशय विशाल जन-समारोहमें मौसीकी गोदीसे लाड़िली-राधाकिशोरी क्षणभरके लिये उतर पड़ी। इतनेमें ही नन्दग्रामकी सभी रमणियोंने कीर्तिदा महारानीको और फिर मौसीको-दोनोंको ही हाथोंमें रसकी भेंट लिये घेर लिया॥ ४२२॥

इसी बीचमें लाड़िली वैसे ही आँखें मूँदे कुछ दूर चली गयी। उसके होठोंपर मुस्कान थी और बड़े तालके साथ वह ताली दे रही थी। मन्द मधुर स्वरमें धीरे-धीरे कुछ गा भी रही थी। लाड़िलीका स्वर इनता मीठा था कि अनजानमें ही सबके प्राणोंमें उन्मत्तता भर उठी॥ ४२३॥

उस होली-क्रीड़ामें प्रायः सभीको, 'मैं कौन हूँ, कहाँपर हूँ, मुझे क्या करना है,' इस बातकी विस्मृति हो गयी। सबकी अञ्जलि तरल गुलालसे परिपूर्ण थी। सभी अनजानमें ही उस ओर दौड़ चले, जहाँ लाड़िली नेत्र बंद किये खड़ी-खड़ी रसकी प्रवाहिणीका सृजन कर रही थी। उस प्रवाहिणीमें नवीन-नवीन ऊर्मियोंका सुन्दर आवर्त्त-चित्र स्वतः अङ्कित होता जा रहा था॥ ४२४॥

अचानक नन्द-नन्दनका मधुरातिमधुर स्वर गूँज उठा- 'अरे ! ठहरो, ठहरो ! तुम सब क्या कर रहे हो? वृषभानु महाराजकी बेटी यहीं खड़ी है और यदि मैं यहाँ नहीं रहता तो तुम सबके द्वारा आज यहाँ पिस ही गयी होती !.... आभीर नरेश महाराज नन्दके पुत्र उस नीलसुन्दर बालकका स्वर सबके कानोंमें -सुखमत्त हुए एक-एकके कर्णपुटोंमें - सहसा ध्वनित हो गया॥ ४२५॥

फिर तो ज्यों-का-त्यों, जो जहाँ था, वहीं-का-वहीं रुक गया और सबको उस अनिष्टकी सम्भावना भी ज्यों-की-त्यों दीख गयी। एकत्रित हुए सम्पूर्ण तरुण-तरुणियोंको, वयस्कोंको एक साथ वैसा ही अनुभव होने लगा। सबकी आँखें छलक उठीं- 'अहो, आज तो भारी अनर्थ हो जाता।' प्रायः सभी स्तब्धसे होकर वृषभानुपुत्रीको निहारने लग गये। एक केवल आभीर राजपुत्र नन्दनन्दन मात्र हँस रहे थे और उनकी सौन्दर्यसुधाका वृषभानुनन्दिनी अपने नेत्रोंके द्वारा पान कर रही थी॥ ४२६॥

इस अवस्थामें ही पन्द्रह-सोलह पल बीत गये। इतने कालके अनन्तर ही वृषभानुपुरीकी महारानी प्रकृतिस्थ हो सकीं तथा हँसकर वे बोल उठीं- 'अरे मेरे लाल! मेरे नैनोंका तारा रे! मैं सत्य कह रही हूँ, तुम ही मेरी इस पुत्रीकी सँभाल करनेवाले सदासे थे, आज भी सँभाल करनेवाले तुम ही हो और अनन्तकाल तक निरवधि-इसकी सँभाल करनेवाले एकमात्र तुम ही रहोगे भी। मेरी बेटी तुम्हारे ही हस्तकमलकी छायामें नित्य सुरक्षित रहेगी, अस्तु,॥ ४२७॥

..सभीके नेत्र प्रफुल्लित हो उठे। कीर्तिदा महारानीकी यह उक्ति सबके कानोंमें झंकृत होने लगी। इतने में ही वह नीलसुन्दर बालक पुनः बोल उठा, शैशवकी सरलता उसकी वाणीमें परिपूरित थी, वह अपनी चञ्चल आँखोंको मटका रहा था और कहता भी जा रहा था- 'रानी! अब मुझे पुरस्कार तो दो भला ..... बतलाओ, अभी तुरंत दे दोगी या अपने घर ले जाकर दोगी ?'॥ ४२८॥

'देखो! यदि तुम मुझे यहीं कुछ दे दोगी तो बहुत सस्ते ही छूट जाओगी, किंतु कदाचित् मुझे अपने घर लिवा ले गयी तो दूना पुरस्कार देना होगा भला! हाँ, मुझे घर ले जानेमें एक लाभ तुम्हें अवश्य होगा। उसके पश्चात् तो तुम्हारी पुत्रीकी आँखें कभी निमीलित नहीं होंगी।'॥ ४२९॥

कीर्तिदा मैया क्षण भरका भी विलम्ब किये बिना बोल उठी 'अरे मेरे लाल ! तू मेरे घर चलकर तो देख सही कि मैं तुझे क्या-क्या देती हूँ, किंतु हाँ, फिर कुछ दिनोंके लिये तो तुम्हें मेरे घर ही रहना पड़ेगा। देख ! मैं तुझे अपना पूरा घर ही सौंप दूँगी और तू मनमानी करते रहना। मैं कभी भी तुम्हें रोकूँगी नहीं।'॥ ४३०॥

महारानी इतना कहते-कहते ठठाकर हँस पड़ी तथा नीलसुन्दरका कर-सरोज उन्होंने अपने हाथमें धारण कर लिया। नीलसुन्दर भी वृषभानुपुर जानेके लिये तुरंत प्रस्तुत हो गये। उस ओर गोपेश गेहिनी (नन्दरानी) मुस्कराकर बोल उठी- 'अरे साँवरा ! फिर मेरे घरको निरन्तर उद्भासित कौन करेगा रे ?'॥ ४३१॥

'अरी मैया ! अच्छा, तो सुन ले ! तू बात समझ नहीं पायी री। तू देख तो सही, मैं एक साथ ही दोनों घरोंमें रह लूँगा।' नीलसुन्दरका मधुस्यन्दी स्वर पुनः झंकृत हो उठा ।.... एक चमचम करता हुआ दर्पण पासमें ही पड़ा था। उसके समक्ष होकर वह साँवर-बालक बोल उठा॥ ४३२॥

'अच्छा, फिरसे सुन लो ! तेरे घर तो मैं स्वयं नित्य रहता ही हूँ और रहूँगा ही तथा देख ! एक नया खेल मैं कर दे रहा हूँ। लाड़िलीकी मैयाको, जो तू इस दर्पणमें मेरी प्रतिच्छाया देख रही है, उसे ही दे दूँगा। महारानीकी दृगपुत्री इन बेटी (श्रीजी) के साथ ही मेरी यह छाया खेलती रहेगी और मैं तो खेलूँगा ही।'॥ ४३३॥

अहा ! कुञ्जित अलकोंसे मण्डित वह नीला-नीला मुख-सरोज उस समय कितना मनोहर हो गया था- कैसे बताऊँ? जब आँखें उस रूप-सुधा-सिन्धुमें डूबने लगती हैं, तब तो वाणी रुद्ध हो जाती है और जब गिरा क्रियाशील होती है, तब उस समय वह रूप-माधुरी उसे ठग लेती हैं॥ ४३४॥

जो हो, अहो! उस लघुवय नील शिशुका रसपूर्ण वह विनोद सुनकर क्षणभरके लिये सबके मनकी विचित्र दशा हो गयी। उस समय एक और भारी अचरजकी बात यह थी सबको यही प्रतीति हो रही थी कि मैं ही इस नीले बालकके सर्वथा सन्निकट अवस्थित हूँ और वह श्यामसुन्दर इस प्रकार कह रहा है॥ ४३५॥

देव दिनकर अब ढल पड़े थे, तथापि प्रतिपल सबके प्राणोंमें नवीन उल्लास अदम्य बनकर उन्हें परिपूर्ण कर रहा था। सबकी आँखोंमें वृषभानु महाराजकी वह गोरी छोरी एवं नन्दका साँवरा छोरा- केवल यही दो भरे हुए थे। फिर कहाँ, किसको, कैसे इस परिदृश्यमान कालका अनुभव हो भला !॥ ४३६॥

हाँ, केवल वृषभानुगेहिनी अब अत्यन्त श्रमित हो गयी थीं, अतएव जनसमूहसे हटकर वे बाहरकी ओर आ बैठीं। उनके अन्तस्तलमें एक गम्भीर विचारधारा चल पड़ी थी। उनके नेत्र आधे खुले हुए थे, तथा उनकी वह बड़ी पुत्री लाड़िली उनके अङ्कमें विराजित थी। लाड़िल की मुट्ठी बँधी हुई थी। अस्तु,॥ ४३७॥

वह बात तो सर्वथा विनोदकी थी, किंतु वृषभानु महाराजके, रानीके अन्तस्तलमें गहरी-से-गहरी बनकर स्थान पा चुकी थी। उनके मनमें तीव्रतम लालसाका रूप धारण करके उनकी बुद्धिका, मनका मन्थन कर रही थी। वे सोच रही थीं- 'कदाचित् जगज्जननीकी रुचि मेरी इस लालसाको समर्थित कर दे और यह प्रतिबिम्ब नीला शिशु बनकर मेरे घर आ सकता !'.....॥ ४३८॥

'उस समय मैं अपनी बड़ी पुत्रीको उसी प्रतिबिम्बस्वरूप शिशुके पास रखकर निश्चिन्त हो जाती तथा यह अपनी सलोनी आँखोंको खोलकर हँस-हँस करके खेला करती और जब शुभ मङ्गल-वेला आती, इसके हाथ पीले होनेका क्षण आता, तब यह श्यामवर्णवाली छाया या तो इस नील शिशुमें मिल जाती अथवा मेरी बड़ी

पुत्रीकी नित्य संगिनी बन जाती।'॥ ४३९॥

रानीकी चित्तधारा विरमित हो, इससे पूर्व ही आँखोंमें सहस्त्रों दिनकरकी ज्योति भर उठी। उन्हें प्रत्यक्ष दीख पड़ा कि महामहिमामयी भगवती महात्रिपुरसुन्दरी आकाशमें खड़ी मुझसे पूछ रही हैं- 'रानी! सोचकर तुम बताओ सही, तुम्हारी क्या एक भी अभिलाषा अबतक ऐसी है, जो तुरंत पूरी न हो गयी हो ?'॥ ४४०॥

'सुनो! सामने विराजित इस नील बालककी प्रतिच्छाया अनुपम, सुन्दर एवं चिन्मयी कन्याका रूप धारणकर तुम्हारे उदरस्थलमें प्रविष्ट होगी। कुछ घटिकाओंके अनन्तर ही आज परम मङ्गलमयी पञ्चमी रजनी जो आ रही है, वह भविष्यमें सदाके लिये अनन्तकालतक के लिये अप्रतिम सुहागनिशा बन जायगी।'॥ ४४१॥

महादेवी इतना कहकर अन्तर्हित हो गयीं। और जब उस दिनके उत्सवका शुभ विराम होने चला- विराम हुआ, तब उस समय नारी-दल तो एक ओर, उससे कुछ हटकर पुरुष-दल कलिन्दनन्दिनीके प्रवाहमें अवगाहन करने लग गया॥ ४४२॥

महामायाने उस समय एक नयी लीला भी रच दी। अचानक महाराज वृषभानु कुछ रसमय भावोंसे भावित हो उठे। महाराज अप्रतिम जितेन्द्रिय थे; किंतु क्षणमात्रके लिये आज उनका मन चञ्चल हो गया। इतना ही नहीं, सहसा उनके मनमें एक तीसरी संततिकी प्रबल अभिलाषा जग उठी। अस्तु,॥ ४४३॥

स्नान आदिसे निवृत्त होकर वे अपने घर पहुँचे। उस समय संध्या हो चुकी थी। आज महाराज खिन्नसे दीख रहे थे। जगदम्बाके मन्दिरमें जाकर उनके पादपद्मोंमें सिर रखकर वे रोने लग गये।.... जब संधिनी-स्वरूपिणी महारानीमें एक संविन्मयी नीली छाया उस रजनीमें व्यक्त हो गयी, तभी महाराज वृषभानु सम्पूर्ण रहस्योंको

समझ सके॥ ४४४॥

आज अचानक अतीतका यह उपर्युक्त ज्योतिर्मय दृश्य ही सर्वथा वर्तमान जैसा बनकर महर्षि दुर्वासाके लोचनोंमें समा गया। अब गोरी या साँवरी-महाराज वृषभानुकी दो पुत्रियाँ उन्हें नहीं दीख रही थीं। उन्हें तो युगलरूप धारण किये हुए प्रत्यक्ष पर-देवता अनुभूत हो रहे थे॥ ४४५॥

महाराज वृषभानु और महारानी - महर्षि दुर्वासाका संङ्केत पाकर अविलम्ब शयनकक्षसे बाहर आ गये। वे दोनों ही उसी भाँति हाथ जोड़े हुए थे। कक्षके भीतर तो वे दोनों पुत्रियाँ रह गयी थीं। भाव-विह्वल मुनिने वाणीके पुष्पोंसे उनका अर्चन-स्तवन आरम्भ कर दिया॥ ४४६॥

महर्षि दुर्वासाके मुखसे निस्सृत श्लोकों को गम्भीर मुद्रामें खड़ी गौरवर्णा एवं श्यामवर्णा- दोनों छोरियाँ सुन रहीं थीं; किंतु बीच-बीचमें वह श्यामवर्णा-लाड़िलीकी अनुजा-रह-रह करके हँस दिया करती थी। दो दण्ड बीत जानेपर जब अचानक मुनिकी वाणी रुक गयी, तब चञ्चला श्यामा छोरी अत्यन्त मीठे स्वरमें मुनिराजसे बोल उठी -॥ ४४७॥

'मुनिराज ! तुम सचमुच अब थक गये होओगे। अबतक तुम खड़े जो रहे हो। सुनो, आसनपर विराज जाओ। मैं तो खड़ी खड़ी सचमुच थक गयी हूँ।'-इतना-सा ही बोलकर श्यामा अपनी अलकोंको कम्पित करके बड़ी बहिनसे कहने लग गयी॥ ४४८॥

'अरी बहिन ! तू चुपचाप कौतुक देख रही है; सुन सही! मुनिवर अत्यन्त क्षुधित होंगे। ये न-जाने कितने कोस चलकर हमारे घर आये हैं। तू पूछ तो सही, हम कौन-सी वस्तु ले आयें? किसपर इनकी रुचि है? हमारे घर रसकी सभी वस्तुएँ नित्य प्रस्तुत रहती हैं भला।'॥ ४४९॥

गौरवर्णा किशोरीने मन्द मन्द हँसकर अपनी छोटी बहिनको समझाया; उसे किञ्चित् अचञ्चल रहनेका सङ्केत किया। इसके पश्चात् करबद्ध होकर मुनिपुङ्गवसे बोली- 'ऋषिप्रवर! देव! हम दोनोंको आप अपनी पुत्रीवत् ही समझें। यह श्यामा अत्यन्त लाड़में पली है, इसीलिये अतिशय वाचाल बन गयी है।'॥ ४५०॥

'अब आप आसनपर विराजें। हम सबपर कृपा करें। अपनी सभी सेवाएँ हमें बतला दें। मैं पल-पलमें नवीन उत्साह लिये सभी सेवाएँ स्वयं सम्पन्न करूँगी। यह मेरी छोटी बहिन भी कुछ कर देगी। फिर हम दोनोंसे जो भूलें होंगी, उन्हें तो आप क्षमा कर ही देंगे, यह सच्चा विश्वास है मुझे।'॥ ४५१॥

राजपुत्रीकी वाणी क्या थी, मानो सुधामयी एक धारा प्रसरित हो रही हो। वह मुनिवरको उत्तरोत्तर और भी सुध-बुधहीन बनाती चली गयी। इतनेमें ही साँवरीने ऐसी चर्चा छेड़ दी, जिसे सुनकर किशोरी बरबस ऊँचे स्वरसे हँस पड़ी ॥ ४५२॥

......उस हास्यसे महर्षिकी भाव-समाधि शिथिल हो गयी। उसी क्षण उन्हें कुछ दैवी प्रेरणा भी हुई, साथ ही भावोंका संधिस्थल भी आ गया; एक माया-सी फैल गयी। यद्यपि दोनों राजपुत्रियोंमें मुनिराजका आकर्षण तो ज्यों-का-त्यों बना ही रहा, तथापि उनके असमोर्ध्व ऐश्वर्यपर एक झीना आवरण-सा आ गया॥ ४५३॥

उन महातपस्वी ऋषिवरका हृदय, जो अबतक अत्यधिक ऊसर था, वही अचानक क्षणभरमें मसृण हो उठा। उसमें अभिनव वत्सलताके अंकुर प्रस्फुटित होने लगे-उन दोनों राजपुत्रियोंके प्रति निर्मल ममत्वसे अभिषिक्त होते हुए भाव-वल्लरी बढ़ने लग गयी और ऐसी शीघ्रतासे बढ़ी कि उसे पल्लवित एवं पुष्पित होते किञ्चित् भी विलम्ब नहीं हुआ॥ ४५४॥

अब मध्याह्न हो चला था। मुनिपुङ्गवके दोनों हाथ छोटी बहिन श्यामाने पकड़ लिये। साथ ही वह बोल उठी 'देखो! तुम आजसे हम दोनों बहिनोंके नये बाबा हो गये भला; आज इसी क्षणसे हमारी जितनी सहचरियाँ हैं, वे सब भी सच्चे हृदयसे ऐसा ही मानती हुई तुम्हें इसी भाँति पुकारा करेंगी।'॥ ४५५॥

'हम दोनोंसे बड़ा हमारा अत्यन्त प्रिय जो सहोदर भाई है - वह तो इस समय वनमें गो-चारण करने गया हुआ है। संध्या होनेपर वह आयेगा। उसे भी मैं कह दूँगी। केवल वही नहीं, उसके सभी सखावर्ग भी तुम्हारे प्रति ऐसा ही भाव निरन्तर रखने लगेंगे।'॥ ४५६॥

'हाँ, वे सब-के-सब अत्यन्त ही चञ्चल हैं और कहीं तुम्हें भी छेड़ बैठें, तब तुम उनपर रुष्ट मत होना भला ! उनका स्वभाव ही ऐसा है। मैं उन सबकी अत्यन्त प्यारी बहिन हूँ, फिर भी वे कभी-कभी तो मुझे भी रुला देते हैं।'॥ ४५७॥

'अब चलो, सरोवरपर हम दोनों तुमको ले चलती हैं। उसीमें स्त्रान करायेंगी। उसमें ही हम दोनोंको मैया एवं मौसी प्रतिदिन नहलाती है। अहा! वह कमल-पुष्पोंसे भरा है। उसका जल अत्यन्त निर्मल है। वहाँ सुन्दर-सुन्दर विहङ्गम नित्य कलरव करते रहते हैं।'॥ ४५८॥

श्यामा छोरीकी सरस एवं सरल वाणी महर्षिके प्राणोंमें क्रमशः अनुपम मादकता भरती जा रही थी। वे मौन थे- क्या करें, उनसे क्या कहें- इस सम्बन्धमें वे कुछ भी निर्णय नहीं कर पा रहे थे। भावोंकी निर्मल जलधारा उनकी आँखोंसे

अनर्गल प्रवाहित हो रही थी॥ ४५९॥

कुछ भी निर्णय न कर पानेकी स्थितिमें.... उन्होंने आपको उन दोनों पुत्रियोंके हाथमें सौंप दिया। उनकी मुद्रा सुस्पष्ट सङ्केत कर रही थी- 'तुमको जो अच्छा लगे, कर लो।' उन दोनोंके प्रति पल-पलमें उनकी अनुभूति बदलती जा रही थी। कभी वे सोचते- 'ये दोनों राजपुत्रियाँ हैं।' किंतु कुछ ही क्षणोंमें यह भाव बदल जाता-'अरे नहीं! ये तो मेरी पुत्रियाँ हैं।' पाँच-छः पलोंके अनन्तर उन्हें सुस्पष्ट दीखने लग जाता- 'नहीं, नहीं, यह तो हमारे इष्ट देवता हैं भला।' तथा उन्हें अपने इष्टदेवकी ही झाँकी उन दोनोंमें प्रत्यक्ष होने भी लग जाती॥ ४६०॥

हँसकर वह बड़ी राजपुत्री जैसे-तैसे मुनिराजको सरोवरपर ले गयी। फिर उन्हें बार-बार सावधान करके ही स्नानकी क्रियाको सम्पन्न करवाया। श्यामाने महर्षि के अङ्गोंको पोंछकर हाथोंमें परिधानका वस्त्र दे दिया। वे मानों कठपुतली हों, इस भाँति उन्होंने वस्त्र भी धारण कर लिये॥ ४६१॥

उन दोनों राजपुत्रियोंके कहनेपर यन्त्रवत् ही वे अपने मध्यान्ह कृत्यको भी सम्पन्न कर गये। दोनों दो ओरसे उनका हाथ पकड़े पुनः उन्हें उसी कक्षमें ले आयीं, जहाँ वे ध्यानस्थ हो गये थे। जब वे आसनपर विराज गये तो बड़ी राजनन्दिनीने उनसे कहा- 'मुनीन्द्र ! अब मैं भोजनकी कौन-सी सामग्री ले आऊँ ?'॥ ४६२॥

बीचमे कनिष्ठा बोल उठी' अरी बहिन ! तू बड़ी भोली है। मुनि तो ध्यानमग्न हैं और तू बार-बार उन्हें छेड़ रही है। जैसे मैं कहती हूँ, तू कर ले। चल, खीर बना लायें हम दोनों। वे स्वयं खा लेंगे, तब तो ठीक है ही; अन्यथा तू खिला देना'॥ ४६३॥

श्यामाके यह कह देनेपर भी जब मुनिवरकी ओर आँखें किये बड़ी राजपुत्री

खड़ी देखती ही रही, तब महर्षिकी आँखोंसे अश्रुकी दो-चार बूँदें ढलक पड़ीं और उनका मस्तक किञ्चित् स्पन्दित होनेपर खीर लानेकी सम्मति भी प्राप्त हो गयी। बड़ी बहिनको हँसकर अपनी ओर आकर्षित करती हुई चञ्चला श्यामा बोल उठी- 'तू विश्वास कर ले, मेरी प्रत्येक रुचि मुनिवर मान ही लेंगे।'॥ ४६४॥

वे दोनों ही चल पड़ीं। जहाँ मैया प्रतीक्षा कर रही थीं; वहीं वे आ पहुँचीं। मैयाकी ग्रीवामें झूलती हुई साँवरी एक-एक बात बताने लग गयी, जो मैयाकी अनुपस्थितिमें घटी थी। सब सुननेके अनन्तर मैया आश्चर्यमें डूबकर दस पल तो अवाक्-सी देखती रह गयी। अस्तु,॥ ४६५॥

मैयाने पायस-रन्धनकी तैयार तुरंत कर दी। लाड़िलीने अपनने सलोने हाथोंसे रन्धनका कार्य सम्पन्न भी कर दिया तथा वह उसे लेकर मुनिवरके समीप आ पहुँची। विधिवत् समयोचित पवित्र आसन लगाकर एवं हाथ जोड़कर ऋषिसे विनती करके वह चुपचाप खड़ी रही॥ ४६६॥

मुनिवर उठ पड़े तथा आकर आसनपर विराज गये। आचमन भी उन्होंने कर लिया, किंतु अब आगे क्या करना है, इसे वे तुरंत भूल गये। लाड़िलीने अपने कर-सरोजसे स्वयं ग्रासका निर्माण करके उनके मुखमें रख दिया। अहो ! उसी क्षण आकाशमें जय ! जय !! जय !!! यह घोष हो उठा॥ ४६७॥

महर्षिका शरीर तो स्पन्दनहीन था, किंतु फिर भी वे खीर खाते चले जा रहे थे। खिलानेवाली लाड़िली जो थी! इसीलिये तो ऐसा हुआ। अन्यथा इस समय उनकी दशा ऐसी हो गयी थी कि खीर खा लेना तो दूरकी बात, उनके कण्ठमें एक नीर-कणतक नहीं उतर पाता॥ ४६८॥

पुनः लाड़िलीने मुनिवरको आचमन कराया; उन्हें मुखवास समर्पित किया तथा एक नीलवर्ण सुकोमल मखमलकी शैय्यापर उन्हें विराजित कर दिया। उसके अनन्तर महर्षिकी महिमा गाकर उनके तपका वर्णन करके उनका नीराजन करने लगी तथा बड़े ही सरसतम ढंगसे साँवरी भी किशोरीका अनुसरण कर रही थी॥ ४६९॥

भूत, वर्तमान, भविष्यमें किसीको स्वरोंका जो कुछ भी माधुर्य उपलब्ध हुआ है, उसका जो उद्गमस्थल है, जिसे वाणी, मन, बुद्धि छू तक नहीं सकी है, जो नित्य है, सनातन है, अद्भुत है, अनुपम माधुर्यमय है-उसको ही उन महातपस्वीने आज उन दोनों राजदुहिताओंके स्वरमें अनुभव कर लिया॥ ४७०॥

क्षणमें तो मुनिवर अन्तर्मुख होते और दूसरे क्षण बाह्य ज्ञान भी हो जाता। अन्ततः वे उठकर धीरे-धीरे उन राजपुत्रियोंके स्वरका अनुगमन करते हुए झूमने लग गये। अचानक नीराजन पात्रको उन्होंने लाड़िलीके कर-सरोजसे अपने हाथमें ले लिया तथा ओह!..... विक्षिप्त-से ऋषिवर्य नृत्य करने लग गये भला !॥ ४७१॥

साँवरी छोरी हँसकर, अपने नूपुरको रुन-झुन करके तथा तान भरकर उसी तालबन्धपर ही मुनिराजको सहयोग देने लग गयी। भावसे मत्त हुए मुनिराज अब बिना जाने ही नीराजन-पात्र हाथमें लिये लाड़िलीकी प्रदक्षिणा करने लग गये... राजनन्दिनी लज्जित-सी चुपचाप खड़ी देखती रह गयी॥ ४७२॥

जब लगभग सवा घड़ी काल व्यतीत हो गया, तब मुनिराजकी आँखें खुलीं । वे भौंचक्के से होकर उन दोनों राजपुत्रियोंको देखने लगे। बड़ी राजपुत्रीने बड़े आदरसे उन्हें आसनपर विराजित करके यह कहा- 'मुनीन्द्र ! अभी आप लोकोत्तर भावसे भावित हो गये थे।'॥ ४७३॥

'बस, आपके निर्हैतुक निस्सीम अनुग्रहसे ही हम दोनों बहिनें उसका दर्शन करके कृतार्थ हो गयीं। अब आपके संध्योचित कृत्योंका समय हो गया है। आप सरोवर-तटपर चलें अथवा यहीं संध्योपासन कृत्य सम्पन्न कर लें।'॥ ४७४॥

अन्यमनस्क से हुए मुनिराज उस सुन्दर-तटपर ही चले आये। स्नान करके अंशुमालीको जब वे अर्घ्य समर्पित कर रहे थे, उस समय अंशुमाली अस्तगिरिकी ओर ढल चुके थे। देव-दिनकर आज उनके दृष्टिपथमें न आ सके। दोनों राजपुत्रियाँ ही आकाशमें अवस्थित हो रही हैं, उन्हें ऐसा अनुभव हो रहा था॥ ४७५॥

अत्यन्त चकित होकर मुनिवरने सरोवरके तटपर अपनी दृष्टि डाली। वहाँ भी दोनों ज्यों-की-त्यों खड़ी मिलीं। अब दोनों ही ओर एक समयमें अपने योग-बलसे मुनिराजने देखना आरम्भ किया। उनको अनुभव हुआ-'अहो! यह क्या? दोनों एक समयमें ही तटपर भी अवस्थित हैं और आकाशमें भी।'॥ ४७६॥

फिर तो मुनिराज उत्तरकी ओर, पूर्व, दक्षिण, पश्चिम, ऊपर, नीचे, चारों कोनोंमें भी देखने लग गये। उनकी दृष्टि जहाँ पड़ती, उन्हें वे दोनों नरपालनन्दिनी ही अवस्थित दीखतीं ।.....॥ ४७७॥

मुनिकी आँखोंसे संसार हट गया और नेत्रोंमें बच गयी केवल मात्र दो ज्योतियाँ-एक थी नीलघन-सी और दूसरी सुतप्त कनकाभ थी। अब तो मुनिराजके मनकी सभी वृत्तियाँ उन दोनोंमें समा गयीं। मुनिवरकी अप्रतिम समाधि लग गयी॥ ४७८॥

मुनिवरका गात्र निस्पन्द हो गया था। दोनों राजपुत्रियोंने उनके शरीरको जैसे-तैसे जलसे बाहर निकाला। उनके गीले परिधानको बदल दिया। फिर उसी जलाशयके तटके सन्निकट जो एक वेष-गृह था, वहीं मुनिराजको लाकर बैठा दिया तथा दोनों उनके समक्ष खड़ी रहीं॥ ४७९॥

महर्षि दुर्वासाकी शारीरिक निस्पन्दता ज्यों-की-त्यों बनी रही। सम्पूर्ण रजनी बीत गयी। शरद ऋतुकी पहली शुक्ला सप्तमी आ गयी। आजका दिन भी बीत गया। संध्या होकर उस दिनकी रात्रि भी पुनः बीत गयी और अब हँसता हुआ प्रभात फिरसे लौटा था। यह प्रभात महाष्टमीका था॥ ४८०॥

अबतक दो दण्ड जैसे बीतते; महाराज एवं महारानी वहीं आ पहुँचते और कुछ दूरपर ही अवस्थित रहकर अन्तर्कक्षका दृश्य देख लेते। श्यामा उनके समीप जाकर सब बातें बतला देती। महाराज तो निश्चिन्त होकर लौटते, किंतु महारानी का मन चिंतातुर बना रहता। अस्तु......॥ ४८१॥

जगदम्बाकी अनुमति लेकर रानी चुपचाप वहाँ जाती-षष्ठी तिथिके प्रदोषमें और आगेके प्रातःकाल और फिर संध्यामें- बस, तीन बार अहो! अपनी दोनों बेटियोंको नहलाकर श्रृंगार धारण कराकर वे किञ्चित खिला पायी थीं॥ ४८२॥

बड़ी राजपुत्री तो दो रात बिल्कुल ही न सो पायी; प्रायः वह बैठी ही रहती। श्यामा अपनी बड़ी बहिनकी गोदमें सिर रखकर कुछ देर के लिए सो जाती। छोटीके अत्यन्त हठ कर लेनेपर लाड़िली लेट भर लेती मात्र बीस पल, तीस पल के लिये ही तथा फिर उठ बैठती। इतनेमें ही श्यामाका मन प्रसन्न हो जाता॥ ४८३॥

जो हो, महाष्टमीके प्रातःकाल, दो घड़ी बीतनेपर महर्षि दुर्वासाकी समाधि खुली। वे धीरे-धीरे उठ बैठे और उसी सरोवरपर आकर उन्होंने अपने कालोचित कृत्य सम्पन्न किये। इसके अनन्तर दोनों राजपुत्रियोंको साथ लिये राजभवनमें आये॥

४८४॥

मुनिराज वहाँ अपने आप आ गये, जहाँ महाराज एवं महारानी विराजित थे। दोनों ही पल-पल बढ़ती हुई उत्कण्ठासे उनकी प्रतीक्षा कर रहे थे। आठों अंगोंसे राजाने उन्हें प्रणिपात किया तथा भूमिपर रानी बार-बार अपना मस्तक झुका रही थीं॥ ४८५॥

.. सहसा तपोधनका कण्ठ भर आया। जैसे ही वे बोलने चले कि उनके कर-सरोज अभय मुद्रामें ऊपरकी ओर उठ गये। किन्तु अब उनका सारा शरीर काँपने लग गया; सम्पूर्ण अंगोंमें स्वेद भी भर उठा था। इस प्रकार दिव्य भावों से भावित होकर वे बारह-चौदह पलतक आँखें मूँदे चुपचाप खड़ थे॥ ४८६॥

बहुत साहस बटोरकर जैसे-तैसे उन्होंने अपने मनको धैर्य बंधाया। अपनी सतृष्ण आँखोंसे बार-बार दोनों राजपुत्रियोंके श्रीमुखको निहारकर बड़ी कठिनाईसे वे बोल सके- 'हे महारानी ! हे राजन् ! तुम सचमुच नित्य धन्य, धन्य, धन्य हो, जो इन अप्रतिम दो पुत्रियों की माता-पिता होनेका तुम्हें सौभाग्य मिला॥ ४८७॥

मैं भी परम कृतार्थ होनेके लिए ही तुम्हारे यहाँ इस गृह में अतिथि हुआ हूँ। इस धरणीका कण-कण पावनतम है भला; क्योंकि यह धरा तुम्हारी इन दोनों पुत्रियोंके अरुण-सरोजके सदृश चरणोंको छू-छूकर पावनतम बन चुकी है। इन चरण-सरोरुहोंका किञ्जल्क योगीन्द्र-मुनीन्द्रके लिए भी दुर्लभ है।'॥ ४८८॥

महर्षि क्षण भरके लिए रुक गये और उनकी रसमयी वाणी पुनः प्रस्फुटित हुई-इस भाँति जैसे प्रस्तुत प्रसंगकी धाराको अचिन्त्य शक्ति मोड़ दे। वे बोले- 'नृप-दम्पत्ति ! तुम्हारी इन दोनों पुत्रियोंने जैसी सेवा की है, वैसी अबतक कोई भी न कर सकी, न कर सका॥ ४८९॥

मैं इनको क्या दूँ?......... किंतु मेरी वाणी सफल हो जाय, इसलिए दैव इच्छासे कुछ कहूँगा अवश्य। देखो, तुम्हारी इस बड़ी लाड़िलीके कर-सरोजसे जो रसोई निर्मित होगी, वह तत्क्षण सम्पूर्ण रोगोंको नष्ट करनेवाली होगी; इसके द्वारा प्रस्तुत सभी पदार्थ अक्षय गुणशाली होंगे तथा अनुपम सुस्वादु भी होंगे॥ ४९०॥

महाराज ! महारानी ! सुनो, अभी मुझे ऐसी प्रतीति हुई कि अपनी बड़ी बहिन लाड़िलीको दिखाकर साँवरी कर रही है- 'मुनिराज ! मुझे तो यह वरदान देना.....इसके प्रति मेरा भाव, अनुराग सदा बढ़ता ही रहे।' उसी स्वरमें महर्षि दुर्वासा गद्गद कण्ठ से इतना सा और बोल गये- 'अतएव मैं भी तुम्हारी इस छोटी पुत्रीको 'एवमस्तु' कहकर वही दे रहा हूँ। इसकी इच्छित वस्तु ही इसे प्राप्त हो।'॥ ४९१॥

.....राजन् हे! रानी हे! मैं तो अब जा रहा हूँ। वे करुणामयी ललिताम्बा जहाँ मुझको ले जायें, वहीं....। यदि मेरा पुनः सौभाग्य उदय होगा तो मैं इस गृहमें आ सकूँगा और..... तुम्हारे इन दोनों शिशुओंको आँखें भरकर निहार सकूँगा।'॥ ४९२॥

ऋषिराजकी गिरा अवरुद्ध हो गयी वे सिसक-सिसक करके रोने लग गये; रानी भी रोने लग गयीं; अहो! विकल होकर महाराज भी रोने लगे। जो भाव-समुद्र उनकी आँखोंसे उमड़ चला, वह अबतक वर्तमान है और वत्सलतासे सम्पुटित ईशताको प्राणान्वित कर रहा है भला !॥ ४९३॥

इस ओर साँवरी और लाड़िली-दोनों बहिनें मुनिवरके श्रीअंगोंसे लिपट गीं 'बाबा! बाबा! तुम फिर आना, फिरसे आना।'..... दोनों पुत्रियाँ बार-बार मुनिवरके कटिदेशको वेष्टित कर रही थीं। उनकी आँखोंसे जो मुक्तायें झर-झर करके श्यामवर्ण और गौरवर्ण कपोलोंपर बिखर रही थीं, उन्हें रो-रो करके मुनिराज चयन करने लग गये॥ ४९४॥

..कदाचित् रानी, राजा एवं मुनिराजपर शासन करनेवाली कोई अचिन्त्य महाशक्ति यदि वहाँ क्रियाशील न हो जाती तो आसन्न, अनागत एवं भूत के इस सम्पूर्ण दृश्यप्रपञ्चकी विकलतावश दशमी-दशा हो जाती भला !....॥ ४९५॥

जो हो, अचानक भावोंका यह प्रवाह नियन्त्रित-सा हो गया। बार-बार महर्षिके पाद-पद्मोंमें गिरकर राजा एवं रानी उन्हें वृषभानुपुरके उत्तरके निर्झरतक पहुँचाने आये। उनकी अनुमति पाकर महाराज एवं महारानी तो लौट आये, किंतु महर्षि दुर्वासाकी दशा तो निराली हो गयी थी। वे सर्वथा विक्षिप्त-से हुए आगे के वनस्थल में प्रविष्ट हो गये। कहाँ गये, कौन बताये ?॥ ४९६॥

इसके पश्चात् एक वर्ष पूरा हो गया। पुनः शारदीय महाष्टमीकी संध्या आ गयी। महारानी एवं महाराज घरसे ज्यों ही निकले कि वह चिर-परिचित वटु उनके समक्ष आ गया। कुल गुरुदेव महर्षि भागुरिका एक आदेश लेकर वह आया था ॥ ४९७॥

'गुरुवर्यने कहा है', वह बोल उठा-'अब तुम दोनोंको आनेकी आवश्यकता नहीं रही। सहचरियोंके सहित अपनी दोनों दुहिताओंके द्वारा ही नवनीत, दुग्ध, दधि, घृत-वे बिना परिश्रम जितना उठा सकें, उन सामग्रियों को ही भेज देना। हाँ, दो घड़ी दिवस चढ़ने के पूर्व ही यह सामग्री आश्रमपर पहुँच जाय।'॥ ४९८॥

अतएव सदाकी भाँति इस बार नृप-दम्पति गुरुवरके पास नहीं गये। सुप्रभात होते ही उनका आज्ञाके अनुसार सभी वस्तुओंको एकत्रित करके, स्वर्णनिर्मित छोटे-छोटे कलशोंमें भरकर, रानीने अपनी कन्याओंके एवं उनकी शत-शत सहचरियोंके सिरपर रख दिया।... अश्रुपूरित नेत्रोंसे ही सबको जानेकी अनुमति वे दे सकीं॥ ४९९॥

सब-की-सब पहले तो राजपथसे चलीं, किंतु फिर उन्हें अरण्य-पथ ही सुन्दर एवं आकर्षक प्रतीत हुआ। वह पथ टेढ़ी-मेढ़ी पगडंडीसे विभूषित था। दोनों ओर फूलोंसे लदी लताएँ लहरा रही थीं। तरु-श्रेणी अत्यधिक फलोंका भार लिये नमित हो रही थीं॥ ५००॥

अगणित विहंगम ऐसी सरस रागिणीका सृजन कर रहे थे, जिनकी छायातक गन्धर्व-रमणियाँ भी छू नहीं सकतीं। सौ-दो सौ पग के अंतरसे पावस-जलके द्वारा शतशः छोटे-छोटे हृद् निर्मित हो गये थे। उनमें राशि-राशि कञ्ज प्रस्फुटित हो रहे थे॥ ५०१॥

गुन-गुन करता हुआ भ्रमरोंका समूह उड़ उड़ करके आता था। उनकी सचमुच रसीली मति वहाँ अपहृत हो रही थी। लाड़िली एवं सहचरियोंके तनसे अद्भुत सौरभ निस्सरित जो हो रहा था। उन सबके मुखकी शोभा अभिनव प्रस्फुटित अरविन्दके सदृश हो रही थी, मानो भ्रमर ऐसा ही अनुभव कर रहे थे। अस्तु,॥ ५०२॥

वे इसी सुन्दर पथसे गुरुवरके आश्रमपर जा पहुँची। गुरुवर- उन परमसिद्ध महर्षिने उन सब कुमारियोंकी अर्चना की; भावोंकी भेंट समर्पित कर तथा फिर रंगस्थलका पट-परिवर्तन करके, उसीमें तन्मय होकर उन्होंने सबको विदा कर दिया॥

५०३॥

वे सभी उत्तरकी ओर जानेवाली पगडंडीसे लौटीं। पथमें ही अंशुमालीका वह कुण्ड मिला। उसको देखकर श्यामा हठ कर बैठी कि मैं तो आज इसीमें नहाऊँगी। सदाका नियम था, साँवरीकी जो रुचि होती, बड़ी लाड़िलीकी रुचि भी उसीमें मिल जाती, किंतु बड़ी सहचरी ललिताने यह राय दी -॥ ५०४॥

'अरी! फिर तो हम लोग क्यों नहीं अब सुन्दरी-सरोवरपर ही चलें। वह अब अत्यन्त सन्निकट है भला ! अप्रतिम रमणीय भी है वह, अहा! कोई पीने भरको पानी माँगे और उसके बदले उसे पीयूष का निर्झर मिल जाय ! इसी भाँति अत्यन्त प्रसन्न होकर अपनी बड़ी बहिन लाड़िलीका दक्षिण कर पकड़कर साँवरी तो अविलम्ब चल ही पड़ी उत्तरकी ओर॥ ५०५॥


''');
        case 'छठवाँ शतक':
          return const _TopicPageContent(
              body:
                  '''उस समय की यह घटना है, जब व्रजमें शरद ऋतु विराजित थी। आज शुक्ला नवमी तिथिका दिन था। प्रातःकी वेला समाप्त हो गयी थी और अभी-अभी संगवकाल आरम्भ हुआ था। उसी समय अनेक सुन्दर शिशुओंको लेकर-जो प्रायः सब-के-सब समवयस्क थे-एक बालक मन्द मन्थरगतिसे चलता हुआ, अपनी मस्तीमें डूबा धीरे-धीरे जा रहा था॥ ५०६॥

यह व्रजेन्द्रनन्दन नीलसुन्दर ही थे, जो गो-चारणके लिए वनस्थलकी ओर अग्रसर हो रहे थे। उनके आगे-पीछे शत-सहस्त्र गायें चल रही थीं। वे रह-रह करके अत्यंत अल्प-कालके लिये रुक जाते और फिर अपनी वेणुमें स्वर भरने लगते। उस समय वेणुसे ऐसी स्वर लहरी निःसृत होती, जो देखते-देखते त्रिभुवनमें पूरित हो जाती। सम्पूर्ण आकाशमें, समीरके कण-कणमें, दिवाकरकी किरणोंमें, सम्पूर्ण जलमें, स्थलमें और सबके मनमें एकमात्र वेणुका स्वर ही बच रहता॥ ५०७॥

वेणु-ध्वनिका स्वाभाविक परिणाम यह होता कि सम्पूर्ण अचर-चरमें धर्मका विपर्यय हो जाता। सबके मनमें सब कुछ मिटकर एक मात्र वह वेणु-स्वर ही बच रहता, जिसकी झंकृतिमें सबका मन तन्मय हो जाता। इतनेमें ही वेणुनादका दूसरा स्वर गूंज उठता। इस बार सबकी विलुप्त हुई चेतना फिरसे लौट आती। सब अकचक-से हुए मानो देखने लग जाते कि अभी अभी कैसे, क्या उनको हो गया था ! सबकी दशा देखकर नीलसुन्दर हँसने लगते। उनके लिये तो यह एक कौतुक मात्र होता। आश्चर्यपूरित आँखोंसे गोप-शिशु नील-सुन्दरकी ओर देखने लगते। सबकी आँखें मानों पूछने लगतीं- 'भैया रे नीलसुन्दर ! यह तो तुम एक अद्भुत कौतुक जिानते हो रे! क्या तुम बतला सकोगे कि ऐसी विचित्र घटना कैसे संघटित कर बैठते हो ?'॥ ५०८॥

नीलसुन्दर मन्द स्मितके साथ उन शिशुओंको उत्तर देने लगते - ' भैयाओं ! देखो, मैं एक अत्यंत रहस्यपूरित मंत्र जानता हूँ। मैं पहले उसे मन-ही-मन पढ़ लेता हूँ, फिर वेणुमें स्वर भरता हूँ। स्वरका प्रभाव ऐसा होता है कि जो भी उसे सुने, वही अपनी स्वाभाविक चेतनता भूल जाता है। स्त्री हो, पुरुष हो, कोई भी हो, वह पागल एवम् पागल-सी हो जाता है। और तो क्या, तुम लोग प्रकृतिके इन पाँच तत्त्वों पर भी वेणुका प्रभाव तुरन्त अभी अभी प्रत्यक्ष देख लो।'॥ ५०९॥

नीलसुन्दरकी उपर्युक्त उक्तिके अनन्तर उन्होंने सबका ध्यान रत्नोंसे निर्मित उस गोवर्धन पर्वत की ओर आकर्षित किया। इसके पश्चात् क्षणभरके लिए वेणुका स्वर गूंज उठा। अहो! देखो, गोवर्धनके वे राशि-राशि हीरक, पुखराज आदि रत्न गलने लग गये भला! पीली उज्ज्वल धारा बनकर सामनेकी ओर बह चले। राशि-राशि गायें पीछे की ओर कूद-कूदकर रँभाने-सी लग गयीं !॥ ५१०॥

अब नीलसुन्दर किञ्चित् बायीं ओर मुड़ गये। कलिन्दनन्दिनीकी धारा में नीलमकी लहरें-सी उठ रही थीं। उन्होंने अब इन लहरोंपर ही वेणुनादका प्रभाव दिखलाना आरम्भ किया। देखते-देखते पूरी प्रवाहिणीका जल आवर्त्तके रूपमें परिणत हो गया। दूसरे ही क्षण वह मानो हिमखण्ड-सा जम गया। अब कलिन्दनन्दिनीकी धाराके स्थानपर हिमखण्ड-सी जमी हुई धरती परिलक्षित होने लगी !॥ ५११॥

आश्चर्यकी बात यह थी कि उन अगणित जल-विहंगमोंके गात्र तो सर्वथा अक्षत थे, किंतु उनके पद उस हिम-पिण्डमें जन्त्रित से हो गये। उनकी पाँखें मात्र हिलती दीखती थीं। वह आवर्त्त-स्थल विशाल वापी जैसा दीख रहा था। जलचारी मत्स्य आदि सब के सब उसमें निस्पन्द पड़े थे॥ ५१२॥

ऊपर दिनकर हँस रहे थे और इधर नीलुसन्दर भी स्थलपर चलते हुए हँस पड़े। इस बार वंशीका छिद्र- दिनमणिको लक्ष्य करके नीलसुन्दरके होठोंकी बयारसे पूर्ण होने लगा। शारदीय दिनकरकी वह किरणराशि सुधाकरकी ज्योत्स्नामयी किरणें बन गयीं। नवमी तिथिका वह दिवसकाल दस पलोंके लिए राकामयी रजनीकी भाँति प्रतिभात होने लगा॥ ५१३॥

धेनु-समूहोंकी, विहंगम-कुलकी, भ्रमरोंकी और राशि-राशि तरु-श्रेणीकी उतने क्षणतक रात्रिकालोचित दशा हो गयी। अवश्य ही इसके दर्शक नीलसुन्दरके शिशु-सखामात्र ही हैं। और ये सब-के-सब बड़ी शीघ्रता से बोल उठे- 'अरे भैया ! अब इनको फिर पहले की भाँति बना दो।' यह सुनना था कि नीलसुन्दर क्षणार्ध पर्यन्त वंशीके स्वरमें एक ललित स्वर भरने लगे तथा दूसरे ही क्षण नीली सरिता प्रवाहित हो उठी! और अंशुमाली भी अपनी प्रखर किरणोंको पुनः विस्तारित करने लग गये॥ ५१४॥

नीलसुन्दर अपनी स्वाभाविक मन्द मुस्कानसे सबको उल्लसित करके बोल उठे- 'देखो, तुम सबने सुना होगा-यह शीतल मन्द समीर सबका जीवनदाता है, किन्तु अब देखो, इस पवनपर मेरे वंशीरवका क्या प्रभाव होता है। जैसे ही में इस वंशीमें स्वर भरूँगा और पवनको सम्मोहित करना चाहूँगा, वैसे ही यह सम्पूर्ण समीर मेरे नासापुटोंमें, मुखमें और वंशीमें- सब जगहसे सिमटकर विलीन हो जायेगा।'॥ ५१५॥

सचमुच ऐसा ही हुआ था। सभी बालक आश्चर्यमें भरे हुए यह नूतन कौतुक देखने लग गये। सबकी जिज्ञासा है- 'अहो! यह क्या बात है? दूरपरकी बात तो छोड़ दो, हम सबने अभी-अभी यह अनुभव किया है कि हमारी साँस तक नहीं चल रही है, तब भी हम सब-के-सब सुखपूर्वक जीवित कैसे थे? बोलो भैयाओं! तुममेंसे कोई भी समीरका अनुभव कर रहा था क्या? और प्रायः सबकी ग्रीवा हिल गयी अस्वीकृतिकी मुद्रामें। अस्तु,॥ ५१६॥

बीस, पच्चीस पल बीतनेपर समीर जब पुनः गतिशील हुआ और वंशीके छिद्रोंसे रसमयी तान निःसृत होने लगी, तब शिशुओंने प्रश्न किया-'अरे कन्हैया ! भैया! हम सब के सब जीवित कैसे बचे हुए हैं? हमने सुना है कि श्वास रुक जानेपर प्राणी मर जाता है और अचरज तो देखो श्वास भी नहीं चल रही थी और हम सब के सब जीवित भी हैं!'॥ ५१७॥

नीलसुन्दर हँस-हँस करके सबका समाधान करने लग गये- 'देखो भैयाओं! वंशीके छिद्रोंसे जो सुधा बरसती है, कोई क्षणभर सपनेमें एक बार भी उसे पी ले, तो वह सदाके लिये अमर हो जाता है! और तुम सब तो नित्य-निरंतर यह सुधा पी रहे हो। फिर तुम सब क्यों नहीं जीवित रहते ?' शिशुओं के मनका नीलसुन्दरकी उक्ति सुनकर पूरा-पूरा समाधान हो गया। अस्तु,॥ ५१८॥

अब नीलसुन्दरकी दृष्टि निर्मल व्योमकी ओर गयी। वे बोले-'अच्छा भैया ! तुम सब बताओ, कोई भी बता दे कि ऐसा भी कोई है, जो सम्पूर्ण आकाशको अपनी एक अँगुलीके नखमें समेट ले? किंतु मैं तुम सबको अभी वंशी बजाकर ऐसा ही करके दिखा देता हूँ। तुम सब प्रत्यक्ष देख लोगे कि मेरे बायें पैर की अनामिकाके नख में यह सम्पूर्ण आकाश अभी आकर सिमट जायेगा।'॥ ५१९॥

इसके अनन्तर मधुकी धारा-सी वंशीके छिद्रोंसे बह चली। उस समय प्रत्येक शिशु-सखाको जो अनुभव हुआ, उसे मैं शाखाचन्द्र-न्यायसे ही कह दे रही हूँ' यद्यपि शिशुओंकी वह अनुभूति नित्य सत्य है, किन्तु अनिर्वचनीय भी है। जो हो, कुछ कालके लिये अवकाश देने वाली वस्तु केवल तुम्हीं बच रहे थे नाथ! उस अनुभूतिके सम्बन्धमें इतना मात्र ही कहा जा सकता है......।' अस्तु,॥ ५२०॥

जब पुनः वह पीयूषकी सरिता वंशीके छिद्रोंसे प्रसरित हुई, तब सब शिशु-सखाओंकी भाव समाधि टूटी। वे सब शिशु झूम-झूम करके उस अमृत प्रवाहिणीमें अवगाहन करने लगे। देखते-देखते हंसिनी, हंस उड़कर आ गये और उनके साथ ही जल-विहंगमोंका समूह भी उड़कर आ गया। इनके साथ सहस्र-सहस्त्र मयूरोंके दलने आकर नीलसुन्दरके सहित उस शिशु मण्डलीको घेर लिया॥ ५२१॥

देखने ही योग्य दृश्य था- नीलसुन्दरकी ग्रीवा वंशीमें स्वर भरते समय जिस ओर झुकती, उन्मत्त हुआ विहंगमोंका दल तत्क्षण उसी दिशा में ही गतिशील हो उठता। पल-पलमें नीलसुन्दरकी सरस भंगिमा बदलती और अपना पेट हाथोंसे थामकर हँसते-हँसते सभी शिशु आनन्दमग्न हो जाते॥ ५२२॥

जैसे ही क्षण-आधे-क्षण के लिये मधुर वेणु-रवका विराम होता-यद्यपि जान-बूझ करके, रह-रह करके श्यामसुन्दर ही ऐसा करते थे-उस समय विहंगमोंके समुदायमें जो प्रेमोत्थित जड़िमाका आविर्भाव होता-उसका एक भी निदर्शन ब्रह्माणी भी न पा सकीं भला॥ ५२३॥

जलकी सुमिष्ट बूँदे टप-टप करती हुई तरु-शाखाओंसे, पल्लवोंसे, फूलोंसे, वल्लरी-समूहोंसे निरन्तर झर रही थीं और नीलसुन्दर अपनी वंशीकी स्वर-लहरीके चालनसे विहंगमोंकी चोंचको बड़ी चतुराईसे उसके ठीक नीचे, ऊपरकी ओर कर देते। वे बूंदे उन चञ्चुओंमें ही गिरतीं। अप्रतिम सुन्दर दृश्य था वह !॥ ५२४॥

अब वन्य चतुष्पदोंकी बारी आयी नीलसुन्दर की वंशी-रवसे निःसृत

मधुधाराका पान करने की। जैसे ही साँवरेने उस गहन वनस्थलमें अपनी वंशीके छिद्रोंको अपने मुख सरोजके स्वाससे पूरित किया, वैसे ही मानो सब-के-सब निमन्त्रित हुए हों, इस भावसे वे व्याघ्र, हाथी, हथनियोंका दल, भल्लूक, मृग-मृगी आदि क्षण-भरमें नीलसुन्दरके समीप दौड़कर आ पहुँचे॥ ५२५॥

सभी शिशु जानते थे कि यहाँ के हिंसक पशु भी नित्य सर्वथा परस्पर वैरसे शून्य रहते हैं। इसीलिए किसीको किञ्चित् भी भय नहीं हुआ। गायें भी तनिक चिहुँकी तक नहीं एवं उस समय वहाँ जो अमृतमयी पयस्विनी पुनः प्रसृत हुई तथा वे चतुष्पद जिस भावमें निमग्न हो गये, उसका वर्णन करनेमें मेरे देवता! मैं सर्वथा असमर्थ हूँ भला ! संभव नहीं है उसका चित्रण मेरे द्वारा॥ ५२६॥

इस प्रकार बीस-पच्चीस पलतक क्रीड़ा करके उन वन्य पशुओंको रसमत्त बनाकर श्यामसुन्दरने अपने स्वर-संचालनके द्वारा ही उन्हें यथास्थान वन में ज्यों-का-त्यों लौटा दिया। शिशुओंने आश्चर्यसे पूछा- 'अरे कन्हैया ! यह सब वन्य पशु कैसे चले गये ? सबकी आँखें भी बन्द थीं और ज्यों-की-त्यों वंशी भी बज रही थी यहाँ, तब भी कैसे गये ?॥ ५२७॥

अब साँवरके अरुणिम अधरोंका वह सुस्मित मनोहर हास्यमें परिणत हो गया। आधे-क्षणके अनन्तर ही वंशीके छिद्रोंसे एक मधुभरी तान छिड़ गयी। इस बार शिशु-सखा आश्चर्यमें डूब गये। वे निर्णय नहीं कर सके कि वंशी-रव किस ओरसे प्रसृत हो रहा है। प्राचीसे अथवा प्रतीचीसे, दक्षिणकी ओरसे या उत्तरसे, ऊपरसे अथवा धरातलसे- किस ओरसे आ रहा है यह रव ?॥ ५२८॥

आँखोंमें आश्चर्य लिये हुए शिशु इसका निर्णय नीलसुन्दरसे जानना चाह रहे थे। नीलसुन्दरने भी अविलम्ब उनको उत्तर दे देना चाहा। वे बोले- 'भैयाओं! देखो, जब मैं वंशी बजाता हूँ, तो यह स्वर-लहरी सर्वत्र परिपूरित हो जाती है। किंतु मैं जिसको, जहाँ, जिस समय इस लहरीकी अनुभूति कराना चाहता हूँ, उसको ही, उसी समय इसकी अनुभूति होने लगती है। तथा तत्क्षण ही उसके तन-मनकी गति इस लहरीमें विलीन हो जाती है।......' ॥५२९॥

इस प्रकार अपनी वंशी-ध्वनिका प्रभाव शिशुओंको प्रत्यक्ष दिखलाते हुए और हँस-हँस करके स्वयं इस रसका पान करते हुए, मृग-छौना सदृश नीलसुन्दर आगे-से-आगे चलते जा रहे थे। अब वे एक अतिशय सुरम्य वनमें जा पहुँचे, जहाँ एक सुन्दर कासार सुशोभित हो रहा था, जिसके विशाल तट स्फटिकसे निर्मित थे॥ ५३०॥

कमलों से भरा हुआ जल दिनकर की किरणों से उद्भासित हो रहा था। साथ ही तडिल्लहरी जैसी आभा भी वहाँ फैली हुई थी। यहीं राधा किशोरी एवं उनकी सहचरियों के अवगाहन की स्वछन्द क्रीड़ा निर्बाध रूप से चल रही थी। तटकी वृक्षावली उनके रत्न-कंकणोंसे झंकृत हो रही थी॥ ५३१॥

राधाकिशोरी एवं उनकी सहचरियोंके श्रीअंग कटिसे ऊपर तो आवरणहीन थे। उनके अप्रतिम रूपकी उन्मादी धाराको एवं पौगण्ड तथा कैशोरकी सन्धिपर जगकर झाँकनेवाले भावोंको, उनकी भीगी अलकोंका जालमात्र रह-रह करके ढक दे रहा था॥ ५३२॥

जो हो, उस जल-विहारसे राधाकिशोरी एवं सहचरियोंके अरुणिम नयनों की सुषमासे एक अद्भुत सम्मोहिनी शक्ति बिखर रही थी। त्रिभुवनके स्थावर-जङ्गमकी बात तो दूर, आश्चर्यकी बात तो यह है कि वहाँ त्रिभुवन-मन-मोहनकी गति भी अचानक उसके प्रभावसे रुद्ध हो गयी भला !॥ ५३३॥

नीलसुन्दर सचमुच विश्वमोहन थे। किंतु संयोगकी बात, गायोंको लिये हुए जब वे आज उस सरोवरपर पहुँचे और उनकी दृष्टि राधाकिशोरी एवं उनकी सहचरियोंके आर्द्र कुंतलोंसे मण्डित मुखपर पड़ी, बस, उसी क्षण वंशीमें स्वर भरनेकी क्रिया विरमित हो गयी। उनकी वे चञ्चल आँखें अचानक अपलक हो गयीं। अस्तु,॥ ५३४॥

जब दो रसमय हृदयोंके परस्पर जुड़नेका समय आता है, तब उसका संयोग कहाँ कैसे लगता है-यह बात वे साँवरके सहचर-दुधमुँहे सरस शिशु भला क्या जानें ? इसीलिये वे अपने प्राणसखा नीलुसन्दरकी चादरको कर्षित करके तत्क्षण बोल उठे॥ ५३५॥

'अरे भैया! तू क्या देख रहा है? मुझसे सुन ले। तेरे श्रीभैयाकी बहिनें और उनकी सहचरियाँ सुखसे स्नान कर रही हैं, इतनी सी तो बात है, देख, अब जल्दी चल; बिल्कुल विलम्ब मत कर यदि तुझे आगे क्रीडा करनी हो तो। अन्यथा यदि तेरी भी यहीं नहानेकी रुचि हो, तो हम सबको स्पष्ट बतला दे।'॥ ५३६॥

नीलसुन्दरने शिशुओंको कुछ भी उत्तर नहीं दिया; उन्होंने तुरंत अपनी दृष्टि उधरसे हटा ली। इतना ही नहीं, वे आगे भी चुपचाप चल पड़े। प्रतिदिनके निर्धारित पथसे वे पूर्वकी ओर अग्रसर हुए। किंतु जो उल्लास उनके मुख-सरोजपर प्रतिदिन रहता था, उसकी छाया तक भी आज न थी॥ ५३७॥

शिशुओं ने अथक प्रयास किया, जिससे नीलुसन्दर हँस पड़े। पर उनके सभी परिश्रमका मात्र इतना ही फल हुआ कि कृत्रिम मुस्कान साँवरके होंठोंपर कभी क्षणभरके लिये नाच उठती। बस, इसके अतिरिक्त उल्लासका कोई भी चिह्न उनमें न दीखता। आज कोई भी अतुलित कौतुक नहीं हुआ, न परस्पर में कोई होड़ लग सकी उनमें। वेणु बजानेकी अथवा श्रृंग फूंकनेकी प्रतिस्पर्धा करने का खेल भी आज सर्वथा न हो सका....॥ ५३८॥

मध्याह्न होनेपर यशोदा मैया की भेजी हुई छाक आ गयी; उसे लेकर साँवर बैठ अवश्य गये, भोजन-रसका आस्वादन करनेवाले शिशु-सखाओंका मण्डल भी प्रतिदिनकी भाँति ही बना; किंतु उस दिन साँवरने केवल दो ग्रास अपने मुखमें रख लिये, इसीलिये शिशु-सखा भी कुछ भी न खा सके। साँवरने नहीं खाया तो वे कैसे खा लें? सम्पूर्ण सामग्री ज्यों-की-त्यों पड़ी रही..॥ ५३९॥

हरी-हरी कोमल तृण-राशिपर गायें सब ओर घूम रही थीं। अपने चालक-दलसे चालित होकर गायोंकी भिन्न-भिन्न दिशाओंमें गति भी होती रहती। अपराह्न कालतक गिरिवरके परिसरमें, परिसरके काननमें वे गायें घूमती रहीं, पर अचरजकी बात है कि वे चतुष्पद भी आज पेट भरकर चर न सके॥ ५४०॥

अकस्मात् साँवरकी ऐसी अत्यंत गंभीर उदासीके कारणका मित्रमण्डली अनुमान लगाने लगी-कोई सोचने लगता, क्या कोई मुझसे ही तो भूल नहीं हो गयी ? अथवा किसी शिशुसे चिढ़कर नीलुसन्दर इतना खिन्न तो नहीं हो गया है ?॥ ५४१॥

किसीके भोले मनमें भोलेपनकी यह बात भी आने लग गयी- 'अरे! क्षणभर में किसी की अलक्ष्य नजर भी तो इसे लग ही सकती है। अतएव सदा यशोदा मैया जैसी करती हैं, वैसे मैं भी कर देता हूँ।' तथा यह सोचकर गायोंकी पूँछ नीलसुन्दरके चारों ओर फिर-फिरा करके अपनी इस क्रियाका परिणाम वह देखने लगता॥ ५४२॥

श्रीभैया तथा उसके द्वारा ही संकेत मिलने पर अमित सद्‌गुणशाली सुबल-

बस, केवल ये दो-सरोवरपर नीलसुन्दरकी राधाकिशोरीसे आँख मिलनेकी बातकी कल्पना कर सके। मन-ही-मन श्रीदाम सोच रहा था-'भैया नीलसुन्दरकी आज मेरी सहोदरा गोरी किंतु अत्यन्त भोरी बहिन राधासे आँख मिली तो अवश्य है....।'॥ ५४३॥

देखते-ही-देखते प्रतीची दिशामें देव-दिनकर ढल पड़े तथा जब क्षितिज उनका स्वागत करने लग गया, तब नीलसुन्दर गोप-शिशुओंको साथ लिये अपने घरपर आ पहुँचे। प्रतिदिन तो उपवन की सीमासे ही वंशी-रव सुन पड़ता था, किंतु आज प्रथम बार उनका गोष्ठमें आगमन नीरव भाव से हुआ। न वंशीकी काकली सुन पड़ी और न उनके मुख सरोजपर कोई उल्लासका ही चिह्न था....॥ ५४४॥

सभी ग्रामवासी उद्विग्न हुएसे नंद-द्वारपर एकत्रित हो गये। मैया नीलसुन्दरको छातीसे लगाकर बेहाल-सी होने लग गयी। अपने अनमोल नीलमणिका मुख-सरोज इतना उदास उसने कभी भी नहीं देखा था। आजके पहले कभी भी, स्वप्रमें भी उसे ऐसी अनुभूति नहीं हुई थी। इसीलिये नंदरानीकी आँखोंसे अजस्त्र अश्रुधारा बह चली॥ ५४५॥

जननीकी यह दशा देखकर साँवर सूखी हँसी हँस देते, किञ्चित् प्रबोध भी देने लगते-'अरी! मैं सचमुच स्वस्थ हूँ।' किंतु जब वे ब्यारू करने के लिये आसनपर विराजे तब वे जननी को विश्वास न दिला सके; क्योंकि प्रत्यक्ष था कि वे थालमें परोसे हुए द्रव्योंका चतुर्थ अंश ही खा सके थे....॥ ५४६॥

नवमी बीतकर आज दशमीका प्रातःकाल लग चुका था, किंतु नीलसुन्दर की स्थिति में कोई परिवर्तन नहीं हुआ। मैया के हाथोंसे प्रस्तुत नवनीत, मीठा दही, आँटाया हुआ दूध, अत्यन्त गाढ़ा दूध-भात, विभिन्न भाँतिके मिष्टान्न, कलेवेकी सभी वस्तुएँ- मैयाने परोसी थीं, किंतु नीलुसन्दरने केवल नाममात्रके लिए उन्हें चख भर लिया.....। कलेवेकी वस्तुएँ ज्यों-की-त्यों धरीं रह गयीं॥ ५४७॥

अविलम्ब नीलसुन्दर गो-चारणका बहाना करके अटवीकी ओर चल पड़े। गायोंकी टोली, मित्रोंका समुदाय वैसे ही साथ चला, किंतु आज भी नीलसुन्दरका अन्यमनस्कपना जैसा कल था, वैसा-का-वैसा ही बना रहा। यह बात कभी-कभी उनके किञ्चित् हँस देने पर भी शिशुओं से छिप न सकी॥ ५४८॥

गो-संरक्षणका क्रम, दैनन्दिनीचर्या, अरण्यमें जैसे-तैसे कलकी भाँति ही पूरी हुई। संध्याके समय नीलसुन्दर वैसे ही घर भी लौटे। मैया के पूछने पर शिशुओंके द्वारा यह ज्ञात भी हो गया कि आज भी छाक भोजनकी लीला नाममात्रकी ही हुई। ब्यारूकी लीला भी, उसी भाँति नीलसुन्दरने कहनेके लिये पूरी कर दी....॥ ५४९॥

मैया धीरज न रख सकी। उसके प्राण विकल हो रहे थे। उसने वृषभानुपुरसे सुनिपुण वैद्यको बुलवाया। किंतु यह बात मैयाने किसीको ज्ञात होने न दी। वस्तुतः मैया भोली थी। अरे! मैयाके नित्य-निरामय शिशुकी नाड़ी परख सके, ऐसा वैद्य न तो कहीं कभी था, न है और न आगे कभी होगा ही॥ ५५०॥

दशमी निशाकी परिसमाप्ति हुई। पापांकुशा एकादशीका प्रभात विहँसने लगा। आज केवल मैया ही नहीं अखिलपुरवासी निरम्बु-व्रतके व्रती हो गये। सबने संकल्प किया-' भगवन् श्रीमन्नारायण हम सब पर दया करें, हमारा नीलसुन्दर नीरोग हो जाय।!' सब के सब निर्जल ही रह गये॥ ५५१॥

उस ओर नीलसुन्दर के मनकी क्या दशा थी- कौन बतलावे ? साँवरकी सम्पूर्ण गतिविधिको वे दोनों सयाने सखा बड़े ध्यानसे देखते जा रहे थे। नन्दनन्दनके हृत्तलमें भावकी जो लहरें उठतीं, वे उनके मुख सरोजपर प्रतिबिम्बित हो ही जातीं, नीलसुन्दरका मुख सरोज तद्भाव-भावित हो ही जाता, वे भले उन्हें रोकनेका कितना ही प्रयास करें॥ ५५२॥

उन दोनों सखाओंने देखा था-जब कर्णिकार वन आया था, तब नीलसुन्दरकी आँखें भर आयी थीं। फिर देखा, जहाँ गिरिगोवर्धनकी शिला पिंगल वर्ण की थी, आज भी नीलसुन्दर वहीं जाकर बैठे थे। अपने ही पीले दुकूलपर उनकी दृष्टि गयी थी तथा दृष्टि पड़ते ही उनके सारे शरीरमें क्षणिक कम्पन हो गया था। यह कम्पन दो बार हुआ था॥ ५५३॥

बड़ी गम्भीर दृष्टि से नीलसुन्दरने अरुणवर्णके सरोज दलोंको देखा था। उन्हें देखते ही उनके कपोलोंपर तत्क्षण प्रस्वेद भर आया था। और फिर जब वह हंसिनी उड़ी थी, तब कुछ जलकण उच्छलित हुए थे। नीलसुन्दरने ठीक उसी क्षण अपने ललाटका स्पर्श किया था....॥ ५५४॥

आज सरिताका निर्मल जल पीने पिरोइनी आई थी। जल पीते समय सरिताकी लहरोंके कुछ छींटे उसके मस्तक पर बिखर गये थे। उसकी रोमावलीके किञ्चित्से काले अंश भीग गये थे। बड़े ध्यानसे नीलसुन्दर उसे देख रहे थे और ठीक उसी समय उन्होंने अपनी अलकोंका स्पर्श किया था...॥ ५५५॥

नीलसुन्दर के शिशु सखा दस-पाँचकी संख्यामें अचानक जलमें कूद पड़े थे। उनका उद्देश्य था-नीलसुन्दरको जैसे-तैसे प्रसन्न करना। नीलसुन्दर तटपर ही बैठे थे। सखाओंके मुखपर जब भीगी चिकुरावली भहरा उठी थी, तब साँवरके गात्रमें सुस्पष्ट रूपसे जड़िमा अभिव्यक्त हो गयी थी....॥ ५५६॥

उसी जलाशयके समीप एक उत्तंगु तरुवर था। दो दिवसोंसे नीलसुन्दर उसके नीचे आकर किञ्चत् रुक अवश्य जाते थे। वन आते समय और लौटने के समय उनकी आँखें ऊपरकी ओर उठतीं और वे तटकी ओर देखने लगते, मानो किसी की आहट ले रहे हों॥ ५५७॥

इस प्रकार वे दोनों चतुर सहचर निरन्तर नीलसुन्दरकी गतिविधिको परख रहे थे- साँवरके मनोभावका मन-ही-मन विशेषण विश्लेषण कर रहे थे, किंतु नीलसुन्दर इसको जान न लें, इस विषयमें वे अत्यन्त सावधान थे। वे दोनों छिपकर परामर्श अवश्य करते कि क्या, कैसे किया जाय। अपने प्राणोंके प्राण सुहृद्वर नीलसुन्दरकी वे किञ्चित् भी सहायता कर सकें, इसके लिए वे अत्यंत व्याकुल-से हो रहे थे॥ ५५८॥

सहसा दोनोंके मनमें आया क्यों नहीं करुणामयी परम आदरणीया सबकी जगदम्बा, उन गैरिकवसना कुटीरवासिनी देवीका आश्रय ग्रहण किया जाय ? उनकी अपार महिमासे वे दोनों ही परिचित थे। अणिमा आदि सिद्धियाँ उन माताकी छायामें लोटा करती थीं। उनसे ये दोनों पूर्णरूपसे परिचित थे और उनकी इन दोनोंपर बड़ी कृपा भी थी॥ ५५९॥

दोनोंकी राय हुई, हमलोग चलकर उन्हींसे सबकुछ निवेदन कर दें। वे परम अनुग्रहमयी अम्बा हमदोनोंको उचित पथ अवश्य बतला देंगी। यद्यपि उनसे कुछ भी छिपा नहीं है, तथापि यह हम लोगोंका कर्तव्य है कि हमारा सबकुछ स्वाहा भले ही हो जाय, हम साँवरको सुखी करके ही रहेंगे॥ ५६०॥

इसीलिये द्वादशी तिथिका जैसे ही अरुणोदय हुआ कि वे दोनों प्रौढ़ शिशु सर्वथा अलक्षित रूपसे उन कल्याणमयी अम्बाके आश्रमपर जा पहुँचे। अम्बाके चरण-सरोरुहमें सिर रखकर उन्होंने सभी बातें बतला दीं। वे कुटीरवासिनी अम्बा दोनों को अपनी छाती से लगाकर हँस पड़ीं॥ ५६१॥

'मैं अभी तुम दोनों के साथ ही चलती हूँ। तुम निश्चिन्त रहो, यह तो भविष्यके उस परम सुखद अभिनयका आमुख मात्र है।' यह कहती-कहती ही तेजोमयी अम्बा उठ पड़ीं और मानों निमेष बीतनेसे पहले ही उन दोनों बालकोंका हस्त धारण किये हुए नन्द-प्रासादके द्वारपर पहुँच गयीं॥ ५६२॥

नीलसुन्दरकी उदास मैया दौड़ पड़ी। गैरिकवसना अम्बाके चरण उसने पकड़ लिये। नन्दरानी मैयाकी आँखें बरस रही थीं। भगवती की आँखोंसे भी अश्रुका निर्झर झर रहा था। फिर पुरवासी सभी नर-नारी मानो एक डोरीसे बँधे हों, इस भाँति आकर्षित होकर पलभर में ही नन्दरानीके प्रांगणमें एकत्रित हो गये॥ ५६३॥

सभी नीरव थे, किंतु अब सभीका चित्त प्रफुल्लित हो रहा था, वे पर्णकुटीरवासिनी इस समय उपस्थित जो हो गयी थीं। सबको यह अनुभव था कि गैरिकवसना माता सबकी रुचि रख देती हैं। इतना ही नहीं, वे सर्वथा असम्भवको भी सम्भव कर देती हैं॥ ५६४॥

अब निश्चित रूपसे हमारे प्राणोंका प्राण साँवरा रोगहीन हो ही जायेगा। हम सभीको यह भीख देने ही तो वे आयी हैं। वे सबके अन्तस्तलकी बात जानती हैं। यह देख लो, हम सबके व्रतका प्रत्यक्ष फल, बस, अब मिलने ही जा रहा है। अस्तु,॥ ५६५ ॥

जो हो, जब सुखमय मनोरथसे परिपूरित सात-आठ पल बीत गये, तब

पर्णकुटीरवासिनी देवी मुस्कराते हुए साँवरेकी मैया के सिर पर हाथ रखकर रुक-रुक करके बोल उठीं; उनका भी कण्ठ रह-रह करके भर जो आता था॥ ५६६॥

'अरी गोपराज रानी! अपनी जेठानी प्रभावतीसे कह दो - महादेवीके द्वारा प्रतिपालित जो वह सामने वृहत्सानुपर्वतकी द्रोणीमें नगर बसा हुआ है- वहाँ जाकर नरपालगेहिनी कीर्तिदा महारानी की उस वृद्धा-जननीसे वह मिल ले। अब वह वृद्धा मैया जामाताके घर ही निरन्तर रहने लगी है॥ ५६७॥

वृद्धा मैया एक अत्यंत सुन्दर उपाय- सर्वथा निर्दोष और अनोखा-सा उपाय बतला देगी। वह उपाय तुम सबके लिये ही बड़ा सुखकारी होगा। तुम लोग उसे कर लेना। फिर तेरा, मेरा और इस अखिल विश्वके हृदयका अनमोल हार यह नीलसुन्दर कभी क्षण भरके लिये भी रोगग्रस्त नहीं होगा।'.....॥ ५६८॥

देखते-न-देखते नीलसुन्दर वहीं आ पहुँचे और हँसते हुए उन गैरिकवसना जगदम्बाके चरणोंकी वन्दना करके बड़ी तीव्र गतिसे बोल उठे- 'भगवती माता ! मैं सचमुच स्वस्थ हूँ। मैया तो भोली हैं। मुझमें अत्यंत मोहवश यह मेरे लिये चिन्ता करती ही रहती है।'... नीलसुन्दरके मुख-सरोजपर एक पवित्र लज्जाकी छाया अभिव्यक्त हो गयी और वे दृष्टि नीची करके खड़े हो गये॥ ५६९॥

गैरिकवसना अम्बा ऊँचे स्वरसे हँस पड़ीं। साँवरको हृदयसे लगाकर उनकी ठोढ़ी छूकर, उनका सिर सहलाने लगीं। अम्बाकी आँखे बार-बार छलक उठतीं; किंतु स्नेहजनित अश्रु बाहर न आ सके। अम्बा कुछ ही क्षणमें संयत-सी होकर सबको लक्षित करके बोल उठीं॥ ५७०॥

'साँवरेकी नित्य जननी यह यशोदा अप्रतिम भाग्यशालिनी है तथा भोली

ही नहीं यह सचमुच बावरी भी बनी रहती है, किंतु अब इसका सलोना लाल सयाना हो गया है भला! कोई इसको कहकर देख लो, यह इतना भी मानेगी क्या ?'॥ ५७१॥

देवीकी यह उक्ति पूरी होते-न-होते नीलसुन्दर चञ्चल होकर अपना मुख देवीके अञ्चलमें ही छिपा लेते हैं। इतना ही नहीं, अञ्चलमें छिपे हुए श्रीमुखसे उन्होंने देवीसे कुछ विनती भी कर दी। किंतु उस विनतीको केवल जगदम्बा ही सुन सकीं और उन्होंने उसे स्वीकार भी कर लिया। गैरिकवसना अम्बाने 'एवमस्तु' इतना सा ही कहा और वे नीलसुन्दरकी अलकोंको सहलाने लगीं॥ ५७२॥

नीलसुन्दर अपनी जननीकी गोंदमें जाकर बैठ गये। मैयाका मुख प्रसन्नतासे खिल उठा। अपने पुत्रका मुख प्रसन्नतासे परिपूरित देखकर मैयाके लिये अब कुछ प्राप्तव्य ही नहीं था। सबका मन एक नीले आनन्दकी हिलोरों में डूब गया। जब कुटीरवासिनी अम्बा फिर बोली, तभी सबको बाह्य ज्ञान हुआ भला !॥ ५७३॥

देवी कह उठीं- 'नन्दरानी ! अब नीलसुन्दरको वनमें चले जाने दो। अभी जितना-सा यह कलेवा करना चाहे, इसे कर लेने दो। फिर तो उस वृद्धा माताकी बतलायी हुई विधिका तुम लोगोंने जैसे ही आदर किया कि बस, उसके पश्चात् तो नीलसुन्दरकी रुचि निरन्तर परिवर्धित होती ही चली जायेगी।'॥ ५७४॥

वे महाप्रभावमयी कुटीरवासिनी देवी समता, करुणा एवं वत्सलता की विग्रहरूपा थीं। सबकी जननी भी थीं। बस, वे उपर्युक्त बात कहती-कहती ही बाहरकी ओर चल पड़ीं। तोरण-द्वारतक तो सभी उनके साथ आये। इतनेमें ही अचानक पलक गिरते-न-गिरते वे तो अदृश्य हो गयी भला !॥ ५७५॥

नीलसुन्दरने मैयासे जल्दी-जल्दी छुट्टी लेकर, धेनु-समूहको आगे करके वनस्थलकी ओर चलनेके लिये तैयारी कर ली और मन्द मन्थर गतिसे चल भी पड़े। पथमें अपने शिशु-सखाओंसे हँसकर बोले- 'देखो भैयाओं! गत रजनीके ठीक अन्तिम क्षणमें मैने एक बड़ा ही सुन्दर स्वप्न देखा है। चलो ! मैं तुम लोगोंको सुनाता हूँ।'....॥ ५७६॥

उसी सुन्दरी-सरोवरका वह सुरम्य प्राची तट शीघ्र-से-शीघ्र आ गया। साँवरे गोपाललाल वहीं जा बैठे। सखा-सहचरोंकी आँखें उत्सुकतासे भरी थीं उस स्वप्नको सुन लेने के उद्देश्यसे। वृक्षावलीसे, वृक्षोंके सुमनोंसे टप-टप मधु झर रहा था, ऐसे ही सुरम्य समय में नीलसुन्दरकी स्वप्न वाली गाथा आरम्भ हुई....॥ ५७७॥

उस ओर नीलसुन्दरकी ताई प्रभावतीदेवी यशोदा मैयाके द्वारा प्रेषित होकर वृषभानुपुरके उत्तरकी सीमामें जा पहुँची तथा इस ओर वृद्धा नानीजीने गिरिवरके सोतेको पार करके घने अरण्यस्थलमें अपने पैर रखे। यहीं प्रभावती देवी भी आ पहुँची। संयोगकी बात, जिससे मिलने प्रभावती ताईजी आयी थीं वे वृद्धा नानीजी पथमें ही मिल गयीं॥ ५७८॥

वृद्धा नानीजीकी कमर किञ्चित् झुक गयी थी; मस्तकके सम्पूर्ण केश उज्ज्वल हो चुके थे। किंतु नेत्रोंकी ज्योति कुछ घट जानेपर भी अभी पर्याप्त थी। अपने दाहिने हाथमें वे लाठी लिये चलतीं और सम्पूर्ण व्रजमें घूम आतीं। सम्पूर्ण खेर एवं नगरके लोग उन वृद्धा नानीजीसे पूर्ण परिचित थे॥ ५७९॥

नानीजी नीलसुन्दरकी ताईसे अत्यन्त स्नेहपूर्वक मिलीं। नानी स्वाभाविक बोलती भी बहुत थीं और इसलिये ही उन्होंने प्रभावतीसे पूछ लिया- 'क्यों, कैसे तुम आज अकेली ही यहाँ खड़ी हो? अभी आयी दिखती हो ? सब प्रसन्न तो हैं नन्दरायजीके ग्रामके नर-नारी? नीलमणि तो पूर्ण स्वस्थ है न?' ....॥ ५८०॥

दैवगतिसे अपने ही आप सुन्दर भूमिका बन गयी। गत तीस प्रहरकी सभी बातोंको प्रभावती ताईजीने नानीजी को बतला दिया। बुढ़िया नानी प्रत्येक बात बड़े ध्यानसे सुनती जा रही थी; जहाँ ठीकसे नहीं सुन पातीं, उसको दोहराकर तुरन्त पूछ लेतीं॥ ५८१॥

जब नानीजीने उन ऐश्वर्यशालिनी गैरिकवसना अम्बाकी वह पवित्र रहस्यमयी उक्ति सुनी, जो उनसे ही सम्बद्ध थी, तब वे बड़े असमञ्जसमें पड़ गयीं तथा कुछ भी उत्तर न दे सकीं। नानीजीको एक वर्ष पूर्वकी घटना याद आ गयी॥ ५८२॥

वे सोचने लगीं-मेरी कीर्तिदा बेटीके घरपर एक अत्यन्त तेजस्वी ऋषि एक वर्ष पूर्व आये थे। अपनी साँवरी दौहित्रीसे फुसलाकर मैंने सब बातें पूछ ली थीं। साँवरीने भी मेरी मनुहारोंसे दबकर सब बातें ज्यों-की-त्यों बतला भी दी थी। मेरी बड़ी लाड़िली राधाको ऋषिवरने एक सुगुप्त वरदान भी दिया था॥ ५८३॥

गैरिकवसनाने जिस बातकी ओर संकेत किया है, वह तो यही है। सम्पूर्ण रोगों को नष्ट करनेवाला उपाय निश्चित रूपसे यही है, किंतु यदि मैं उसे प्रकट कर देती हूँ, तो साँवरी मुझसे अत्यधिक रुष्ट हो जायेगी; मुझे विस्वासघातिनी कह-कह करके नाकों दम कर देगी॥ ५८४॥

उस ओर नीलसुन्दर रुग्ण हो रहा है। साथ ही गैरिकवसना देवीकी रुचिकी अवहेलना किसीके द्वारा संभव भी नहीं है। मैं जैसे-तैसे साँवरीको फिर आगे भी फुसलाकर प्रसन्नकर लूँगी। इसके अतिरिक्त अब मैं और कर ही क्या सकती हूँ?....॥ ५८५॥

इस प्रकार आधी घड़ीतक नानी चिन्ता में पड़ी रहीं। आखिर प्रभावती ताईजीसे वह बात उन्होंने बतला ही दी और यह राय दी कि नीलसुन्दरको मेरी बड़ी दौहित्री राधाके द्वारा रन्धनकी की हुई वस्तुमें से किञ्चित् खिला दो, सीधा-से-सीधा उपाय यही हैं॥ ५८६॥

यह सुन्दर प्रभावती ताई तुरन्त नन्दरानी मैयाके पास लौट आयीं। बीच पथमें ही नन्दरानी मैया बैठी थीं। प्रभावती ताई और उनका वहीं मिलन हुआ। मैयासे बात करनेके अनन्तर प्रभावती ताईजी अत्यन्त वेगसे चलकर पुनः महादेवीसे रक्षित वृषभानुपुरीमें आ पहुँचीं ॥ ५८७॥

इस समय केवल डेढ़ प्रहर दिन बाकी बचा था। कीर्तिदा मैया अपने प्रांगण में बैठी दोनों पुत्रियोंसे खिलवाड़ कर रही थीं। दोनों बहिनें खेलनेके लिए आज बाहर वनस्थल में नहीं गयीं थीं। इसीलिए भाग्यसे बड़ा अच्छा संयोग लग गया। प्रभावती ठीक समयसे ही पहुँची॥ ५८८॥

अपने प्राणोंका प्यारभरा सुखमय आलिंगन देकर कीर्तिदा मैयाने प्रभावतीका स्वागत किया और उनके आनेका कारण पूछा। कारण जाने लेनेपर वे अविलम्ब राधाकिशोरीकी दादीजीके पास उन्हें ले गयीं। दादीजी अब निरन्तर केवल पति-सेवा में ही रहती थीं॥ ५८९॥

महाराज महिभानुदादाजी प्रायः अब समाधिमें ही रहते थे। दो-दो प्रहर बीत जाते थे, पर उनकी आँखें नहीं खुलती थीं। प्रातः काल एवं अद्धर्निशामें कुछ देरके लिये वे दो-चार वाक्य बोलते थे। दादीजी उसी समय उनसे जो कुछ करना आवश्यक होता, पूछ लिया करतीं॥ ५९०॥

इसीलिये दादीने भी सब सुनकर परम सुन्दर निर्णय यही दिया- 'अब आज तो बड़ी लाली तुरंत यहीं कुछ रंधन कर देगी। ब्यारूके समय नीलमणिको आज वह खिला देना। आज अर्द्धनिशामें वृद्ध महाराजकी अनुमति लेकर कल प्रातः कालमें ही इन सबको वहीं नन्दग्राम भेज दूँगी और वे रन्धन कर आयेंगी।'॥ ५९१॥

दादीजी उस भाँति ही स्नेहभरे स्वरमें इतना सा और बोल गयीं-'नन्दरानीसे मेरी शत-शत शुभाशीष कहना और कह देना कि वे सर्वथा किसी प्रकारकी चिन्ता न करें। नीलमणि नित्य निरोग रहेगा ही। मेरी लाली तो साँवरेकी ही निधि है, साँवर-जननीकी ही वस्तु है। नन्दरानी जब-जब चाहेंगी, यह जाकर वहाँ रन्धन कर आयेगी।'॥ ५९२॥

सब कुछ वैसे ही हुआ। जब द्वादशी संध्यामें दिवाकर अस्त गिरिमें चले गये और नीलसुन्दर वनसे लौटकर अलिन्दमें ब्यारू करने बैठे, तब वह एक कटोरा खीर, जिसे प्रभावती ताईजी वृषभानुपुरसे ले आयी थीं, उसकी कैसी महिमा प्रकट हुई, इसे जो व्यक्ति देख सके, वह देख ले....॥ ५९३॥

नन्दग्रामके लोगोंके लिये समस्त चिन्ताओंको हरने वाली वह रजनी नूतन उत्सव जैसी होकर बीत चली। ऊषाकी लालिमा आनेतक नन्दपुरीमें, पत्तनके कण-कणमें 'श्रीमन्नारायण नारायण' यह रव निरन्तर बँधे स्वर में गूँज रहा था....॥ ५९४॥

उधर वृषभानुगेहिनी कुक्कुटका रव सुनते ही उठ पड़ीं। सर्वप्रथम उन्होंने अपनी कुलदेवीका वन्दन किया। फिर बड़ी शीघ्रतासे अपनी दोनों पुत्रियोंका निर्मञ्छन करके उन्हें प्रबुद्ध किया। स्नान कराया और अतुल सुन्दर वेष-रचना कर दी उनकी॥ ५९५॥

इतनेमें ही सज-धजकर सब सहेलियाँ, सखियाँ आ पहुँचीं। इस समय प्राचीमें दिनकरका ज्योर्तिमय रथ उद्भासित-सा ही हुआ था। वृद्ध पितामह जिस मन्दिर में निवास करते थे, वे सब-की-सब वहीं एकत्र हुईं। आज लाड़िली राधाकिशोरीको उनका आशीर्वाद लेना अत्यन्त आवश्यक जो था॥ ५९६॥

अपनी दोनों पोतियोंपर, जो ठीक दादाजीके सामने खड़ी थीं, जैसे ही महिभानु दादाजीकी दृष्टि पड़ी, कि बस, वे आज अधीर हुए अपने आसनसे सहसा उठ खड़े हो गये। दादाजीके जीवनका यह प्रथम अवसर था, जो पोतियों को देखकर उनमें मोहका-सा आवेश हो गया भला !॥ ५९७॥

महिभानु महाराज अत्यन्त कर्तव्यपरायण थे। ऐसा होनेपर भी वे सदा आत्यन्तिक रूपसे निर्लिप्त रहते थे। उनका जन्म तो शाक्तकुल में हुआ था, पर वे साथ ही वैष्णवाग्र भी थे। क्षणभरके लिये भी उन्हें भगवच्चरण सरोरुहकी विस्मृति कभी न होती थी और अब तो व्यवहार जगत से सर्वथा अलग से हो गये थे।.... अस्तु,॥ ५९८॥

दादीने तुरंत हाथ पकड़कर उन्हें आसनपर विराजित कर दिया। लाड़िली, साँवरी एवं उन दोनोंकी सम्पूर्ण सहचरियोंने, जो वहाँ खड़ी थीं, सबने ही दादाजीके अंकमें सिर रखकर उनकी वंदना की। आज दादाजीके दृगोंसे झर-झरकर अश्रु-बूँदें निरंतर बरस रही थीं॥ ५९९॥

कोई भी समझ नहीं पाया कि दादाजीकी ऐसी अवस्था आज अचानक क्यों हो गयी। अतः मैं सङ्केतमात्र कर दे रही हूँ। दादाजीने देखा-'सच्चिदानन्दघन परत्तत्त्व, जो मन-वाणीसे सर्वथा परे है, अहो! वही तत्त्व इन गोरी-साँवरी एवं नीलसुन्दर- इनसे तो सर्वथा अभिन्न है भला !'....॥ ६००॥

इनका खेल अनिर्वचनीय, अचिन्त्य एवं निरुपम है। साँवरा जिसको जितना-सा जब दिखला दे, बस, वह उतना-सा ही देख ले। फिर भी उसका मर्म उसके लिये अज्ञात ही रहेगा। इसीलिये तो मैं अपनी दोनों पोतियोंको अबतक पहचान ही नहीं सका......।'॥ ६०१॥

पितामहको ऐसी अनुभूति आज सहसा हो गयी और फिर वे तुरन्त पूर्ण संविदके ऊपर वत्सलताकी जो लहर होती है, उसमें बहने लगे। सर्वनियन्ताकी इच्छा थी-अब दादाजी आगे इस रसोदधिमें निमग्न हो जायँ, जो ज्ञानसे भी परे है।.... अस्तु,॥ ६०२॥

कहीं विलम्ब न हो जाय-लाडिली आदि सबको डेढ़ योजनका पथ अभी तय जो करना है। सहसा दादीके ध्यानमें यह बात आयी। दादीने सबको हृदयसे लगाया और तत्क्षण विदा कर दिया। अहो! मानों जम्बूनदस्वर्णकी विगलित धाराके अन्तरालसे स्वर्णकी राशि चमक रही हो-चम-चम कर रही हो-इस भाँति वे सब-की-सब नन्दग्रामकी ओर अग्रसर हुईं॥ ६०३॥

पथकी दूरी सहसा, सचमुच सङ्कुचित हो गयी। आधी घड़ीका समय ही लगा और लाड़िली आदि सब-की-सब नन्दग्राममें आ पहुँचीं। साँवरकी जननीने राधाकिशोरी एवं उसकी सहचरियोंका कैसा स्वागत किया, वाणी इसे कहनेका साहस करके उसे विकृत कर देगी....॥ ६०४॥

फिर भी यदि प्रबल चाह इसे सुननेकी ही हो, तो अब यहाँ नहीं। इस वनकी सीमासे हम दोनों जब आगे जा पहुँचे, तब हे मेरे प्रियतम ! तुम मुझे याद दिला देना। मैं लज्जाका सर्वथा त्याग करके प्राणोंमें अङ्कित चित्रोंका विवरण कर जाऊँगी...॥ ६०५॥

प्राणरमण नीलसुन्दर ! अभी तो इतना ही सुनकर सन्तोष कर लो-एक घड़ीमें लाड़िलीने अत्यन्त सरस रसोईका निर्माण कर दिया।.... भोजन करके वेणु बजाते हुए नीलसुन्दर वनकी ओर जा रहे थे और नन्दरानी मैयाका अतुल प्यार लेकर राधाकिशोरी अपनी सहचरियोंके साथ घरकी ओर लौट रही थीं। अस्तु,॥ ६०६॥


''');
        case 'सातवाँ शतक':
          return const _TopicPageContent(
              body:
                  '''जहाँसे राधा-सरोवरके लिये पगडण्डीका पथ जाता था, वहीं एक अश्वत्थका पुराना वृक्ष बड़ी विचित्र सुषमा लिये न जाने कबसे खड़ा था, उसकी विशेषता यह थी कि पतझड़के समय उसकी पत्रावली कभी गिरती न थी। पतझड़के कालका कोई भी प्रभाव उस पर नहीं पड़ता। वह सदा हरीतिमा एवं आश्चर्यका पुञ्ज बना रहता था।

व्रजपुरवासियोंको सामान्य रूपसे यह चर्चा प्रायः सबको ज्ञात थी कि इसके नीचे वनकी अधिष्ठात्री देवी व्यक्त होकर - विराजकर बहुतोंको दर्शन दिया करती थीं॥ ६०७॥

इसीलिये इसपर कालका कोई प्रभाव नहीं था। उस अश्वत्थतरुकी एक विशेषता यह भी थी कि व्रजपुरवासियोंके सभी मनोरथ प्रायः पूर्ण हो जाया करते थे। जिसकी जैसी इच्छा होती, उसको उसकी रुचिकी वस्तु मिल ही जाती और परिणाममें सभी व्रजपुरवासियोंका परम मङ्गल ही होता॥ ६०८॥

इसी पादपके नीचे एक दिन राधाकिशोरी सो गयी थीं और उन्होंने एक विचित्र स्वप्न देखा था। वह कहने भरके लिये ही स्वप्न था-वास्तवमें वह किशोरीकी विचित्र अनुभूति ही थी। वे नन्दग्रामसे लौटी थीं और इस अश्वत्थके नीचे सहचरियोंके कहनेसे विश्राम करने लगी थीं। क्षणभरके लिये उनकी आँखें निमीलित हुईं और एक परम रहस्यमयी अनुभूति उन्हें हुई थी॥ ६०९॥

'प्राणरमण नीलसुन्दर ! यद्यपि किशोरीका यह स्वप्न रसका समुद्र सृजन करता है, किन्तु उसका मैं संकेतमात्र ही कर सकती हूँ। न जाने क्यों, अचानक गिरा कुण्ठित हो रही है। इस काननमें विविध जातिके असंख्य विहंगम हैं और वे सबके सब रस-लोलुप भी हैं, किन्तु वे सभी रस मर्मज्ञ हों, ऐसी बात नहीं। इसीलिये वे इसे यथोचित रूप से समझ नहीं सकेंगे।'॥ ६१०॥

'प्राणनाथ! यह वही सिन्धु है, जो अबतक किसीके द्वारा नापा नहीं जा सका। यह कितना गहरा है, आज तक कोई भी बतला न सका, बतला नहीं सकी। जो जितना भी नीचे बढ़ता चला गया, उसे इस सिन्धुकी गहराई बढ़ती ही प्रतीत हुई। वह उसीमें समाप्त हो गया, समाप्त हो गयी और जो बचकर बाहर निकल सका, निकल सकी वह सदा के लिये गूँगा अथवा गूँगी बन गयी है।'॥ ६११॥

उस गूँगीका अथवा गूँगेका संकेत कोई समझे अथवा नहीं समझ पाये। जो समझनेका दम भरता है, वह पूरा समझ गया है, यह भी नियम नहीं। जो गूँगी है, वह तो कभी अब निर्णय करने आयेगी नहीं। ऐसा इसीलिए कि वह बहरी तो थी ही, इसके बाद तुरन्त अन्धी भी हो गई। साथ ही बचकर निकलने वालीके प्रति जो नियम लागू पड़ते हैं, वे तो लागू होंगे ही। नियमतः जैसे बचनेवाले सभी विक्षिप्त हो जाते हैं, वैसे वह गूँगी भी पगली हो ही जाती है। अस्तु,॥ ६१२॥

जो हो, भगवती योगमायाके द्वारा रङ्गस्थलका उद्घाटन होता है॥ ६१३॥

राधाकिशोरी स्वप्न देखना आरम्भ करती हैं॥ ६१४॥

प्रियतम नीलसुन्दरसे जो उनका नित्य सम्बन्ध है, उसकी ही उन्हें विस्मृति हो जाती है॥ ६१५॥

उनका द्विरागमन हो रहा है, ऐसी अनुभूति राधाकिशोरी करती हैं....॥

६१६॥

अनुजाके साथ ही वे अपने गंतव्य स्थानकी ओर जा रही हैं.....॥ ६१७॥

दुर्मद आगेसे चलकर पथका प्रदर्शन करता जा रहा है॥ ६१८॥

पथमें किशोरीने अपने जिस विवाहके वृत्तको कभी अनुभव नहीं किया था, उसका वे चिंतन करने लगती हैं॥ ६१९॥

रवि सेतु आ जानेपर राधाकिशोरी वहाँ बैठ जाती हैं और अत्यन्त विनयकी मुद्रामें दुर्मदको कुछ आदेश देती हैं॥ ६२०॥

दुर्मद ज्यों-का-त्यों उस आज्ञाका पालन करता है॥ ६२१॥

राधाकिशोरी रवि मन्दिरका दर्शन करनेके लिये उस ओर अग्रसर होती हैं।....॥ ६२२॥

किशोरी अनुजाको अपने हृदयकी वेदना बतलाने लगती हैं।......॥ ६२३॥

अनुजा फुत्कारपूर्वक रोने लग जाती हैं।....॥ ६२४॥

राधाकिशोरी एवं उनकी अनुजा दोनों परस्पर धैर्य प्रदान करती हैं।....॥ ६२५॥

राधाकिशोरी ग्राममें प्रवेश करती हैं।....॥ ६२६॥

फिर उस विशाल गृहमें प्रवेश करती हैं ॥....॥ ६२७॥

किशोरीके द्वारा देवीकी अर्चना करवायी जाती है।....॥ ६२८॥

राधाकिशोरी वृद्धाके चरणोंमें सिर रखकर प्रणाम करती हैं।....॥ ६२९॥

अचानक राधाकिशोरीको गहरी मूर्च्छा आ जाती है॥ ६३०॥

वृद्धाके द्वारा विविध भाँतिके शीतल उपचारोंके माध्यमसे राधाकिशोरीको बाह्य ज्ञान होता है॥ ६३१॥

अचानक इसी समय वह पर्णकुटीरवासिनी देवी आ पहुँचती हैं। राधाकिशोरी पहलेकी भाँति उनको पहचान भी न सकीं। उस समय उनको केवल इतना-सा ही अनुभव हुआ-जगतमें मेरी रक्षा करनेवाली अब एकमात्र यह पर्णकुटीरवासिनी अम्बा ही हैं॥ ६३२॥

देवीके गूढ़ वचनोंको सुनकर राधाकिशोरीको अपने परित्राणकी आशा हो जाती है॥ ६३३॥

कुटीरवासिनी देवी राधाकिशोरीको सूर्यव्रतके लिये आदेश देती हैं।....॥ ६३४॥

देवींके द्वारा ही द्वादशवर्षीय उस व्रतके लिये नियम निर्धारित कर दिये जाते हैं।....॥ ६३५॥

वृद्धा अत्यन्त हर्षके साथ देवीकी प्रत्येक उक्तिका अनुमोदन करती चली जाती है॥ ६३६॥

राधाकिशोरीका एवं उनकी अनुजाका दुस्सह परिताप मिट जाता है; अपना अभीष्ट पाकर दोनों ही कुटीरवासिनी देवीके पदमें लोट पड़ती हैं। उन दयामयी अम्बाने उन दोनों को अपनी छातीसे चिपटा लिया। अम्बाकी आँखोंसे झर-झर अश्रु बहने लग गये। अन्तस्तल सीमामें बद्ध नहीं रह सका॥ ६३७॥

अस्तु, राधाकिशोरीके द्वारा सूर्यकी अर्चना आरम्भ होती है।.....॥ ६३८॥

संध्याके समय सभी सहचरियोंसे मिलन होता है।.....॥ ६३९॥

दूसरे दिनका प्रभात हो जानेपर राधाकिशोरी अर्चनाके लिये पुष्प चयन करने जाती हैं॥ ६४०॥

उद्यान में प्रवेश करती हैं।...॥ ६४१॥

उद्यानके सौन्दर्यका दर्शन करती हैं।.....॥ ६४२॥

सहचरियोंसे राधाकिशोरी कुछ प्रश्न करती हैं।.....॥ ६४३॥

एक सहचरी उत्तर देती है।....॥ ६४४॥

मानो सहचरीके उत्तरमें टोना-सा भरा था-किशोरीका कर कम्पित होकर पुष्पका दोना हाथोंसे गिर गया। राधाकिशोरी किसीसे कुछ कहे बिना ही वाटिकासे चल पड़ी और सीधे घर आकर गृहके अपने कक्षमें प्रविष्ट होकर उन्होंने कपाट बन्द कर लिये॥ ६४५॥

राधाकिशोरीके श्रवणपुटोंमें एक अद्भुत तन्मयताका आविर्भाव हो गया।...॥ ६४६॥

दिन भर उन्होंने कुछ भी भोजन न किया।....॥ ६४७॥

रात्रि भी पूरे अनाहारमें व्यतीत हुई॥ ६४८॥

किशोरीको आज तनिक भी निद्रा नहीं आयी ।....॥ ६४९॥

सूर्योदय होनेपर सहचरी उनसे मिलने आयी ।....॥ ६५०॥

सहचरी राधाकिशोरीकी दशा देखकर अत्यन्त आश्चर्यमें डूब गयी ।....॥ ६५१॥

सहचरीके अत्यधिक आग्रहके कारण राधाकिशोरीने अपनी ऐसी दशा हो जानेका हेतु बतलाया॥ ६५२॥

वह कारण सुनते ही उस नर्म सहचरीकी आँखें भर आयीं। साथ ही उल्लास एवं सहानुभूतिपूरित जलबिन्दु सहचरीकी आँखोंसे झरने लग गये। वह कुछ मूक संकेत किशोरीको देने लग गयी, किन्तु किशोरी और भी चंचल हो उठीं। सहचरीने क्षणभरके लिये आँखें बन्द कर ली। राधाकिशोरीकी अनुजा यह सब बड़े ध्यानसे देख रही थी।....॥ ६५३॥

अनुजाने राधाकिशोरीकी सामयिक सेवा की ।..॥ ६५४॥

संध्या हो गयी॥ ६५५॥

अचानक किशोरीके कर्णपुटोंमें मुरलीका रव झंकृत होने लग गया ।....॥ ६५६॥

वंशी-रवका सृजन करनेवालेके प्रति राधाकिशोरी अपना सम्पूर्ण आत्मनिवेदन कर बैठती हैं।.....॥ ६५७॥

किशोरीका चित्त उस वंशीनादसे सर्वथा एकत्व स्थापित कर लेता है। किशोरीके चित्तका रूप ही वंशीनादमय बन जाता है।....॥ ६५८॥

ऊषाकाल लग रहा है, किन्तु किशोरीको भ्रम होने लगता है-संध्या हो गयी; प्रदोष लग चुका है॥ ६५९॥

किशोरीको अपनी देहकी अत्यधिक विस्मृति हो जाती है॥ ६६०॥

अनुजा बहुत से उपायोंका आश्रय लेती है, तब कहीं जाकर राधाकिशोरीको कुछ बाह्य ज्ञान होता है। जैसे-तैसे प्रातः के कृत्योंका अधूरा सा निर्वाह हो पाता है। प्रतिपल अनुजा किशोरीको सँभाल रही थी। इसीलिए इस परिस्थितिका आभास तक वृद्धा एवं उसकी पुत्री न पा सकीं॥ ६६१॥

अपराह्नके समय सहचरीने लाकर किशोरीको एक चित्रपट दिया ।...॥ ६६२॥

राधाकिशोरी उस चित्रका सौन्दर्य देखने लगती हैं।....॥ ६६३॥

किशोरीको विचित्र अनुभव होता है।....॥ ६६४॥

उन अखिलरसामृतमूर्ति बालकके प्रति किशोरी अपना सम्पूर्ण आत्मोसर्ग कर बैठती हैं।.....॥ ६६५॥

किशोरीकी बुद्धि तद्रूप हो जाती है।...॥ ६६६॥

सर्वत्र उन्हें उस नील बालकके ही दर्शन होते हैं।.....॥ ६६७॥

उस रजनीमें किशोरीका चित्त अद्भुत विकलतासे पूरिपूर्ण हो जाता है।....॥ ६६८॥

रात भरमें ही किशोरीके चित्तकी दशा ऐसी हो गयी कि जिसे देखते ही वह सहचरी चिन्तित हो उठी। उन्माद रोगके सभी लक्षण राधाकिशोरी में परिपूरित दीखे। इतना भर अच्छा था कि राधाकिशोरी अपनी उस सहचरीको अब भी पहचान रही थीं॥ ६६९॥

सहचरीका नाम लेकर राधाकिशोरी बड़े उच्च स्वरसे बोल उठीं- 'मुझे मत स्पर्श करो, मुझे मत स्पर्श करो।' इस प्रकार कहकर भाग चलीं ।....॥ ६७०॥

सहचरी सामने आकर द्वार रोककर खड़ी हो गयी ।....॥ ६७१॥

राधाकिशोरी उच्च स्वरसे विलाप करने लगती हैं॥ ६७२॥

सहचरी उन्हें सान्त्वना देने लगती है।....॥ ६७३॥

राधाकिशोरी धीरे-धीरे अपने हृदयके अनिवार्य परितापकी बात कहने लगती हैं।....॥ ६७४॥

सहचरी उसे सुनकर उच्च स्वर में हँस पड़ती है॥ ६७५ ॥

अब वह राधाकिशोरीकी उस सरस भ्रांतिको दूर कर देती है॥ ६७६॥

धधकती हुई अग्निकी ज्वालापर मानो जलधरकी धारा बड़े वेगसे गिरने लगती हो-सहचरीके उस एक वाक्यका ऐसा ही परिणाम हुआ कि राधाकिशोरी सहचरीके अंकमें दस-पंद्रह पल तक पड़ी रहीं॥ ६७७॥

सहचरी सम्पूर्ण घटनाक्रमका परिचय देती है॥ ६७८॥

राधाकिशोरीके भावोंकी और भी अभिवृद्धि होती है॥ ६७९॥

सहचरी अवसर देखकर उस नीलबालकसे मिलकर राधाकिशोरीके सम्बन्धमें बातें करती है।....॥ ६८०॥

किन्तु बालक सहचरीको उत्तरमें इस प्रकारकी मुद्रा प्रदर्शित करता है, मानो वह इस प्रकारकी घटनाओंसे सर्वथा अनभिज्ञ है॥ ६८१॥

चार दिनोंके पश्चात्, राधाकिशोरीके प्रति उस बालकके मनमें आकर्षणका अत्यंत अभाव है-ऐसी चेष्टाओंका प्रदर्शन उस बालकके द्वारा होने लगता है।....॥ ६८२॥

सहचरीके द्वारा उस बालकके मनमें राधाकिशोरीके प्रति भावकी अभिवृद्धि हो-इसके लिये विविध प्रयास होने लगते हैं॥ ६८३॥

किंतु सहचरीको आत्यंतिक असफलता मिलती है॥ ६८४॥

आखिर राधाकिशोरीके द्वारा अपने कुल-भय, लज्जा एवं गौरव-सबका परित्याग करके, अपने सर्वस्व समर्पणका, अपनी आत्यंतिक विवशताका संकेतचित्र एक पवित्र पत्तेपर अपने नखमणिसे अंकित करके उस नीलसुन्दर बालकको भेज दिया जाता है॥ ६८५॥

तथापि सहचरीको, राधाकिशोरीको आत्यन्तिक निराशाकी उपलब्धि होती है।...॥ ६८६॥

राधाकिशोरी सोचने लगती हैं- 'मेरे कर्मोंके दुर्विपाकके फलस्वरूप इस जन्ममें मेरा प्राणनाथसे मिलन होना सम्भव नहीं दीखता, किन्तु यह निश्चय है, मेरे नवीन अयुत जन्मोंमें जगन्नियन्ता देव मुझपर अवश्य दया करेंगे, ऐसा सोचकर राधाकिशोरी अपने प्राण विसर्जन कर देनेके लिए उद्यत होती हैं।....॥ ६८७॥

कलिन्दनन्दिनीके समीप राधाकिशोरी चली आती हैं और उसके प्रवाहको देखने लगती हैं।....॥ ६८८॥

इसी समय वहाँ सहचरी पहुँच जाती है॥ ६८९॥

राधाकिशोरी सहचरीको अपने भुजपाशमें लेकर रोने लग जाती हैं॥ ६९०॥

अपने महाप्रयाणके समय, पाथेयके रूपमे नीलसुन्दर बालकके चित्रपटके दर्शनकी कामना उनके मनमें जग उठती हैं।.....॥ ६९१॥

किन्तु यह कामना पूर्ण नहीं हो पाती; क्योंकि यह चित्रपट वहाँ था जो नहीं।...॥ ६९२॥

'हाय-रे! मैं मन्दभाग्यवाली इतना सा सुख भी कैसे ले सकती हूँ ? इसीलिये मैं अपने आराध्य देवताका चित्र तक भी अन्तमें देख न सकी। उस दिन तो मेरी ऐसी दशा थी कि मेरे हृदयका कोना-कोना सर्वत्र उनकी छविसे परिपूरित था। देखूँ, कदाचित् हृदयके किसी कोनेमें उनका दर्शन हो जाये और मैं उनमें ही अपने प्राणोंको विलीन कर सकूँ ।.....॥ ६९३॥

यह कहती-कहती राधाकिशोरी अपनी आँखें बन्द कर लेती हैं।.....॥ ६९४॥

सहचरी राधाकिशोरीको अपने अङ्क में लेकर उच्च स्वरसे क्रन्दन करने लगती है।....॥ ६९५॥

बस, इसी क्षण महामरकतमणिकी द्युति धारण करनेवाले उस नीलसुन्दर बालकका वहाँ आगमन हो जाता है।...॥ ६९६॥

कदाचित् नील-पद्मकी संख्यामें मेरे मुखमें रसना होती तथा कालका बन्धन बिल्कुल ही नहीं होता, तब उस रसनाकी तूलिका लेकर मैं चित्र अङ्कित करती ही रह जाती ।... किसका चित्र ? उसका चित्र, जो सुखद अनुभूति सहचरीको तथा राधाकिशोरीको नीलसुन्दरके वहाँ सहसा आ जानेसे हुई ..... किन्तु लगता है, इतना होनेपर भी यथोचित चित्र मैं अङ्कित कर नहीं सकूँगी.....॥ ६९७॥

जैसे कोई कवि अपनी सरस कल्पनाओंको चुन-चुनकर, उनको मालामें गुम्फित करके, अपने प्राणोंमें ही छिपाकर रख ले, सम्मान एवं गर्वके हाथोंसे वह माला सर्वथा अस्पृष्ट रहे, उस मालामें जो एक नित्य उल्लास भरा होता है, वही उल्लास राधाकिशोरी एवं उस नील बालकमें सब ओरसे परिपूर्ण हो उठा॥ ६९८॥

जैसे अत्यन्त पवित्र-से-पवित्र अनुरागमय दो धाराएँ दृगोंसे बह-बहकर, फिर इस देश-कालकी सीमासे उस पार पहुँच करके संगमति हो जायें, उनमें जो नित्य शीतलता रहती है, वही शीतलता इस समय उन दोनोंके प्राणोंको आत्मसात् कर रही थी॥ ६९९॥

जहाँ यह अहंता नहीं है, बुद्धिकी वृत्ति भी नहीं है, न यह प्राकृत गुण ही हैं, और तो क्या, जहाँ यह प्रकृति भी नहीं है, तथा अहो! बस, जहाँ केवल चित ही चित है, जहाँ अद्वयपनकी नित्य निरुपम गम्भीरता परिपूरित रहती है-वही राधाकिशोरी एवं नीलसुन्दरके प्राणोंमें उस समय व्यक्त हो रही थी, भला !॥ ७००॥

इस कालमानसे उन दोनोंको अपने यथास्थित कलेवरमें लौट आनेमें कितना समय लगा, अहो! शतबार चतर्मुख जग-जगकर पुनः सो गये, इतना-साया-केवल दो दण्ड मात्र ही समय लगा, इसे तो एकमात्र तुम्ही जानते हो, मेरे नीलसुन्दर देवता !॥ ७०१॥

जो हो, रजनीके अंचलमें बसनेवाली वह सुषमा उनके लोचनोंकी पलकोंको छू-छूकर धीरेसे उस विशुद्ध रस-पद्धतिका जब संकेत करने लगी-वे तभी अपनी प्रकृतिको स्वीकार कर सके थे भला !॥ ७०२॥

राधाकिशोरीके, नीलसुन्दरके एवं सहचरीके मुख-सरोजसे कोई भी वाणी निःसृत न हो सकी। केवल सहचरीकी आँखोंमें प्रणयरोषकी छाया-सी क्षण भरके लिये झाँक गयी थी। सहचरी उस समय चंचल-सी हो गयी। उसके मुख पर उसके हृदयगत भाव सुस्पष्ट रूपसे अंकित हो गये थे। किन्तु सहसा सहचरी की आँखें राधाकिशोरी एवं नीलसुन्दरके मुखसरोज पर नाच उठीं॥ ७०३॥

राधाकिशोरी एवं उस नीलुसन्दर बालकके कपोलोंपर जो अश्रु की रेखा बन गई थी, बनती जा रही थी, उसीके अन्तरालसे उनका हृदय बोल रहा था। ऐसे समयमें अब सहचरी भला उन नीलुसन्दर बालकको क्या उपालम्भ देती। वह तो रसकी भाषाका ककहरा मात्र स्मरण करने लग गयी॥ ७०४॥

ऊपर नभमें वृक्षावलीसे ऊपर उठकर चन्द्रदेव साक्षी दे रहे थे। नीली प्रवाहिणी कल-कल रवके द्वारा मंगलमय शुभ गीतोंका गान कर रही थी। सहचरी अपने नयनोंके जलसे परिणयकी वेदीको प्रक्षालित कर रही थी।... तथा विद्युल्लहरी का करसरोज धारण किये कृष्ण जलधर सुशोभित हो रहा था॥ ७०५॥

यह एक निर्मल स्वप्न था। अहो! किन्तु यह किंचित अँधेरा भी लिये था। इसमें संकल्पकी कहीं कोई गंध भी न थी, फिर भी इसमें अद्भुत विक्षिप्तपना भरा था। यह संविद् रसमय था, तथापि हृत्तलकी आह लिये हुए था। राधाकिशोरीके लिये तो यह स्वप्न था, किन्तु सच पूछा जाय तो यह भूत, वर्तमान, भविष्यके संविन्मय रसका-संविन्मय जीवनका चित्र है॥ ७०६॥

उस स्वप्नमें ही राधाकिशोरीको जो एक दूसरा स्वप्न हुआ था, उसे कह देनेका प्रयास कर रही हूँ प्राणनाथ! किंचित् कह पाऊँगी तो! मैं निरन्तर रो रही हूँ, हृदयेश्वर ! प्राणोंको तो अनुभूति है, किन्तु वे बोल जो नहीं पाते। अतएव जो अन्तर्यामी है, वह जान सकता है नाथ! जीवनसर्वस्व !॥ ७०७॥


''');
        case 'आठवाँ शतक':
          return const _TopicPageContent(
              body:
                  '''नीलसुन्दर ! प्राणनाथ! जब शयनागारमें ऊषासुन्दरी आकर राधाकिशोरीको स्पर्श कर लेती, यह कहकर 'किशोरी! अब रजनी चली गई। मैं उसे अपने हृत्तलका प्यार दे रही हूँ, जो सम्पूर्ण रात्रि चिंतामें पड़कर सो न सका, सो न सकी। सारी रात वे सोचते ही रह गये कि यह स्वप्न-मिलन है अथवा यह सचमुच मिलन हो रहा है, ठीक इसी समय राधाकिशोरीकी समाधि खुल जाती॥ ७०८॥

नीलसुन्दर उनकी अलकें, जो मुखपर बिखरी हुई थीं, सहेज देते। उन दोनोंकी आलस्यभरी आँखें जब मिलतीं, तब उस समय नीलसुन्दर तो सर्वथा सर्वांश में राधाकिशोरी बन जाते एवं राधाकिशोरी सर्वथा नीलसुन्दर बन जातीं। केवल उनके प्राणोंका परिवर्तन होता था, यह बात नहीं! उनकी देह भी सर्वथा सर्वांशमें पलट जाती थी॥ ७०९॥

इतने में ही सहचरियोंकी कंकणकी ध्वनि सुन पड़ती और वे दोनों ही क्षणभर में पुनः पहले जैसे हो जाते। जब सहचरियाँ उन पर बलिहार जाती हुई भीतर प्रविष्ट हो जातीं, तब राधाकिशोरी लज्जित होकर अञ्चल से अपना मुख ढक लेतीं॥ ७१०॥

सभी सखियाँ, सहचरियाँ, मञ्जरियाँ उन दोनोंका मंगल नीराजन करतीं। 'दम्पति युगल ! तुम दोनों युग-युग जिओ।' यह कहकर सभी सुख में निमग्न हो जातीं। राधाकिशोरी एवं साँवर के दृगोंसे अश्रु के कण झर पड़ते और उन अश्रु कणोंमें यह रव परिपूरित रहता- हम कभी त्रिकालमें भी तुमसे उऋण न हो सकेंगे॥ ७११॥

शीतल समीर सौरभका उपहार लेकर इसी समय विनय करता- 'युगल दम्पति हे ! अब तुम चलो। काननकी वल्लरियाँ तुम्हारी प्रतीक्षा कर रही हैं। पुष्पित होकर, तरुसे जुड़कर, स्पन्दित हो-हो करके तुम दोनोंका वे पथ निहार रही हैं। वे आशा लिये हुए हैं तुम दोनों का मुखसरोज निहारकर वे परम कृतार्थ हो जायें।'॥ ७१२॥

गौर-नील दम्पति ज्यों ही बाहर आते कि वह रंगिणी नामकी मृगी दौड़ी हुई उनके समीप आ जाती। राधाकिशोरीके कटिदेशको स्पर्श करके वह संकेतोंमें कहती - 'किशोर एवं नील सुन्दर देवता! देखो, वे सम्पूर्ण चतुष्पद उन कुंजोंकी फेरी दे रहे हैं, भला ! जिनमें तुम दोनोंके श्री अङ्गोंकी सुगन्ध भरी हुई है।'॥ ७१३॥

नीलसुन्दर एवं राधाकिशोरीके अङ्गोंकी हरिताभ एवं पीत शोभाको अपने लोचनोंके आँचलमें भरकर, मदमाती-सी होकर अभी दो घड़ी पूर्व जब रजनी विदा ले रही थी, तब उस समय चकई चक्रवाकसे मिलकर चन्द्रमासे इस भाँति कहने लगी-॥ ७१४॥

'चन्द्रदेव! इस नीली सरिताके कूलोंपर तुम पुनः सुखसे आना भला ! यह दोनों विहंगम मुझे कोसेंगे, ऐसा समझकर तुम हमसे भयभीत मत होना। यहाँ इस वनमें राधाकिशोरी एवं नीलसुन्दर नित्य मिले हुए रहते हैं और कभी भी पृथक् नहीं होंगे। यहाँ निसर्गके दुःखद नियम कभी लागू होंगे ही नहीं। हम दोनों भी कभी पृथक् नहीं होंगे।'॥ ७१५॥

प्रतिदिन ही उन विहंग दम्पतिकी कुछ ऐसी रसीली चर्चा होती ही और फिर वे दोनों उड़कर शयनागारके प्रांगणमें आ जाते। सारिका एवं शुक आँखें गड़ाकर उन दोनोंको ही प्रतिदिन देखा करते। राधाकिशोरी तथा नीलसुन्दर सारी तथा शुक

और उन दोनों विहंगमोंकी मुद्रा देखकर उन्मुक्त हँसी हँसने लगते॥ ७१६॥

कुंजोंकी शोभा देखते हुए दम्पति मन्द मन्थर गतिसे चलते। उनके आगे-पीछे सभी सहचरियाँ चलतीं। फूलोंसे लदे हुए द्रुमोंकी श्रेणीसे राशि-राशि सुमन झरते और उन सुमनोंपर ही गौर-नील दम्पति अपने चरण-सरोरुह रखककर अग्रसर होते। वे लताएँ झूम उठतीं जब राधाकिशोरी अपने करसे उनको स्पर्श करतीं - अपने करमें लेकर फिर नीलसुन्दरको पकड़ा देतीं यह कहकर - 'प्राणाधिक! देखो, ये कैसी शीलवती हैं तथा मैं तुम्हें विश्वास दिलाती हूँ कि इनमें स्वसुखकी गंध भी नहीं है! आह ! इनकी जय हो।'॥ ७१७,७१८॥

इतनेमें ही सर्वथा सामने कलिन्दनन्दिनीका तट आ जाता। गौर-नील दम्पतिके श्रीमुखकी शोभा तटकी उज्ज्वलतामें प्रतिबिम्बित हो जाती तथा उस समय राधाकिशोरी भ्रमित हो जातीं- 'अहो! ये सच्चे हैं अथवा हम दोनों सच्चे हैं।' किशोरीकी बात सुनकर साँवर हँसने लगते। तब कहीं जाकर राधाकिशोरीको अपने भ्रमका भान होता॥ ७१९॥

मानों हंसिनी अपनी पीठपर गौर-नील दम्पतिको लेने आयी हो, लहरोंपर ऐसा नाचती-सी उज्ज्वल वर्णकी नौका दम्पतिके दृष्टिपथमें आती। फिर क्या था, राधाकिशोरी नीलसुन्दर को आकर्षित करके उस दिव्य घाटवाले पथपर चलकर अत्यन्त शीघ्रता से उस नौकापर आरोहण कर जातीं॥ ७२०॥

प्रतिदिन ही यह क्रीड़ा तनिक अन्तरसे प्रायः संघटित हो जाती- राधाकिशोरी नौकापर विराजकर अपने करसरोज में डाँड़ को लेतीं और कहतीं- 'अच्छा प्राणेश ! तुम देखो, मैं कितना सुन्दर नाव खेती हूँ भला !' किशोरीकी चितवनमें, वाणी में उस समय रसका निर्झर पूरित हो जाता, जो साँवर को रसमय बना देता। नीलसुन्दर

किशोरी पर ढल पड़ते॥ ७२१॥

'अहो ! बलिहार! बलिहार ! निकुञ्जरानीकी जय!' ऐसा कहकर सहेलियाँ राधाकिशोरीको उत्साहित करने लगतीं और शेष सहचरियाँ डाँड़ खेने लग जातीं। सहचरियोंका यह प्रयास होता कि वे डाँड़ खे रही हैं-इसे किशोरी जान न पायें। तथापि किशोरी इस बात को देख ही लेतीं और उल्लास भरे स्वर में कह बैठतीं- 'अरी! मैं इतनी निर्बल हूँ, डाँड़ खे नहीं सकती ?'॥ ७२२॥

उस समय साँवर-नीलसुन्दर मुस्कुराकर कह ही उठते- 'अरी ! तुम सब छोड़कर देखो कि मेरे प्राणोंकी रानीसे छू जाने का कैसा जादू होता है। इनको छू लेनेके फलस्वरूप जब मैं ही निरन्तर चंचल रहता हूँ, तब यह डाँड़ तथा नाव अपने आप चलेगी ही भला !'॥ ७२३॥

नीलसुन्दरकी यह रसीली बात सुनकर किशोरी लज्जित हो जातीं और डाँड़पर से अपना हाथ हटा लेतीं। उस ओर सरिताकी धारामें परिवर्तन हो जाता। लहरों से हिल्लोलित होकर तरणी चल पड़ती थी और उन्हें हृदय से लगाकर नीलसुंदर 'जय हो ! जय हो!' कहने लगते॥ ७२४॥

उज्ज्वल वर्णकी बरटा दम्पत्ति एवं जल-कुक्कुटों की कृष्णवर्ण टोली उड़-उड़ करके आती तथा अपनी पाँखें फैलाकर दोनों ही नावको घेर लेतीं। वे सभी विहंगम अपनी-अपनी ग्रीवा राधाकिशोरी एवं नीलसुंदरके सामने कर देते और उन विहंगमोंको सहला-सहला करके, उन्हें प्यार देकर गौर-नील-दम्पति उन्हें अभिषिक्त करते रहते॥ ७२५॥

अचानक लहरोंका वेग इतना अधिक बढ़ जाता कि नौका डगमग करने

लगती। राधाकिशोरी भयभीत हो जातीं। साँवर अञ्जलिमें किंचित् सरिताका जल ले लेते तथा राधाकिशोरीका पद धोकर उसे तरंगोंपर छींट देते। फिर क्या था, वे तुरंत धीमी पड़ जातीं॥ ७२६॥

अचानक नीलसुन्दर कहते- 'प्राणवल्लभे ! यह सरिता तुमको स्पर्श करना चाह रही है। अतएव चलो, इसकी इच्छाको हमलोग अवश्य पूर्ण कर दें। यहाँपर जल गम्भीर नहीं है। अपने लहँगेंको तुम किंचित् ऊँचा करके चलना।' इतना कहते-कहते साँवरकी आँखोंमें अश्रु छल-छल करने लगते। अस्तु,॥ ७२७॥

इस प्रकार कहकर नीलुसन्दर राधाकिशोरीको साथ लिये हुए जलमें उतर पड़ते। दोनों ही अतिशय सावधान चल रहे थे, तथापि लहँगेकी नीली किनारी किंचित् गीली हो ही जाती। राधाकिशोरी हँस-हँस करके नीलसुन्दरको उस समय रसमय उपालम्भ दिये बिना नहीं रहतीं॥ ७२८॥

अब दम्पति नीलीप्रवाहिणी के दक्षिण तट पर आ जाते। तमाल तरुकी श्रेणी जालको छू-छू करके स्पन्दित हो रही थी। साँवर अपने दक्षिण करसे उसे और भी नमित कर देते। वह सचमुच एक डोली-सी बन जाती और नीलसुन्दर किशोरीको उसपर विराजित कर देते॥ ७२९॥

किशोरीकी अनुपम शोभा निहारकर पलभरमें वे भी आरोहण कर जाते। सहचरियाँ अत्यन्त सुखमें डूबकर झोंटा-सी देने लगीं। सचमुच वह एक अभिनव झूलाका उत्सव-सा हो जाता। उस समय युगल दम्पति जब हँसते तो वह हँसी अत्यन्त मनोहर हो जाती। सभी सहचरियोंका मन उसमें विलीन होने लगता॥ ७३०॥

ठीक इसी समय उस झूला बने हुए तरुपर एक बन्दरिया चढ़ जाती-'अहो! मानों वह कालकी गतिका संकेत करने ही आयी हो। राधाकिशोरीका ध्यान उधर बँट जाता और आँखें चिन्ताकुल हो जातीं। साँवर भी स्वयं झूलेसे नीचे उतर आते और राधाकिशोरीको उस पर से वे नीचे उतार देते॥ ७३१॥

उस समय दोनोंकी आँखें भर आतीं, पर मस्तक झुक जाता था। परस्पर एक दूसरेका सिर एक दूसरेपर टिक जाता। उस समय वे कुछ भी बोल नहीं पाते। गात्रोंसे इतना अधिक प्रस्वेद निःसृत होता कि दोनों के ही वस्त्र उससे पर्याप्त गीले हो जाते, धुल-से जाते थे। इस प्रकार वे परस्पर मध्याह्नतकके लिये मानो विदा लेते॥ ७३२॥

वहाँसे दक्षिण-पश्चिमकी ओर एक पगडंडी जाती थी, उसी पर रुक-रुक करके नीलसुन्दर चलने लगते। रह-रह करके उनकी दृष्टि राधाकिशोरीकी ओर केन्द्रित हो जाती। वे आकुलता एवं विनय परिपूरित आँखोंसे किशोरी की ओर देखने लग जाते। इस प्रकार ३०-३५ पल व्यतीत होते और फिर नीलसुन्दर तरुजालोंमें किशोरी के दृष्टिपथसे ओझल हो जाते॥ ७३३॥

अब निष्प्राण-सी हुई राधाकिशोरी धीरे-धीरे चलने लगतीं। घर आकर आँखें मूँदे शैय्यापर पड़ जातीं। नीलसुन्दर ही तो उनके प्राण थे। तन कहीं भी रहे, उसमें रखा ही क्या था। तथापि किशोरीका स्थूल शरीर भी सखियोंको प्राणोंके समान प्रिय था और वे निरन्तर उसे सँभालती ही रहतीं॥ ७३४॥

भावका एक अद्भुत आवेश राधाकिशोरीमें अचानक हो जाता। वे ज्यों-की-त्यों सब घटनाओंको शैयापर पड़ी पड़ी वहींसे देखने लग जातीं। साँवरकी मैया नीलसुन्दरको अपने घरपर जैसे-जैसे सँभालती थीं; किशोरीके निस्पन्द दृगोंपर वह

ज्यों-का-त्यों अंकित हो जाता॥ ७३५॥

किशोरी देखतीं-कालकी गति सहसा पीछेकी ओर सरक गयी है। वे अघटनघटनापटीयसी महाशक्ति क्रियाशील हो रही हैं। इसीलिये सबकी दृष्टिमें ऊषाकाल अब आरम्भ हुआ है। नीलसुन्दरकी जननी यशोदा मैया जग उठी हैं, किंतु उनपर महामायाका ऐसा प्रभाव व्यक्त हो रहा था कि भोली मैया समझ तक नहीं पायी कि अभी-अभी सारी रात नीलसुंदर घर से बाहर अवस्थित रह चुके हैं। इसका किंचित् भी आभास वे न पा सकीं। अस्तु,॥ ७३६॥

अपने कोटि प्राणोंके प्राण नीलसुंदर का मैयाने दीपककी लौसे निर्मछन किया और फिर दधिमंथन करने लगीं। मैया सुधास्यंदी स्वर में गा रही हैं। उनके श्रवणपुटोंमें तो अपने पुत्रका रुनझुन-रुनझुन रव परिपूरित हो रहा है और आँखोंमें परिपूर्ण हो रहे हैं नीलमणि, जो प्रांगण में नाच रहे हैं॥ ७३७॥

नवनीत प्रस्तुत हो गया। अब मैयाकी समाधि टूट गयी। फिर शयन मंदिरमें वे धीरे-धीरे जा पहुँचीं। नीलसुन्दरके मुखसरोजपर भ्रमरावली-सी अलकें बिखर रही थीं। उन्हें मृदु करके अपसारित कर मैया फूली नहीं समा रही हैं॥ ७३८॥

'अरे मेरे लाल ! मैं अपने कोटि-कोटि अर्बुद प्राणोंको तुझपर न्योछावर कर रही हूँ। तूँ आँखे खोल। निद्राका परित्याग कर दे। सबेरा हो चुका है भला ! देख, तुझे गायें पुकार रही हैं। कुछ ही क्षणोंमें तेरे सभी सखा भी आ जायेंगे। तू पहले जाकर उन गायोंके दूध को दुह ले भला ! तू उठ तो सही।'॥ ७३९॥

इस भाँति प्रेमिल शत-शत मनुहारोंसे वे नीलसुन्दर को जगा सकीं तथा जैसे-तैसे वे मुखारी मात्र पूरी करवा सकी थीं, इतनेमें ही नीलसुन्दर तो भाग चले। गृहसे सम्बद्ध उस गोशालामें पल बीतते-न-बीतते वे आ पहुँचे। वह विशाल धेनु-समूह उनका नीला सुन्दर मुख देखकर निहाल होने लग गया॥ ७४०॥

इस भाँति अपने घरपर विराजित रहकर ही राधाकिशोरी इन सम्पूर्ण दृश्योंको देख लेतीं। इधर जैसे-तैसे सहचरियाँ उन्हें प्रबुद्ध करतीं। राधाकिशोरी आँखें खोलकर देखने लगतीं। रसभरे अनेकों उपायोंसे मुख-शोधनका, उद्वर्तनका, मज्जनका, परिधान धारण करानेका एवं आभूषणसे सुसज्जित होनेका-इन सभी कार्योंका निर्वाह सहचरियोंके आत्यंतिक सहयोगसे ही हो पाता भला !॥ ७४१॥

इतनेमें ही साँवरकी मैयाके द्वारा प्रेषित दूती आ जाती। यशोदारानी किशोरीको प्रातःकाल नित्य ही अपने घर बुलाया करतीं। उन्हें सदाका यह अनुभव जो था कि जो रसोई राधाकिशोरी प्रस्तुत करती हैं, नीलसुन्दर पेट भरकर उसे ही खाते हैं, अन्य कुछ भी नहीं खाते। अस्तु,॥ ७४२॥

दूती एवं सहचरियोंसे घिर हुई राधाकिशोरी चल पड़तीं। विचित्र-सी दशा किशोरीकी उस समय हो जाती। उन्हें सर्वत्र साँवर-ही-साँवर दीख पड़ते थे भला ! ऐसी दशा में ही विक्षिप्त-सी वे साँवरके घर पहुँचती। जब नीलसुन्दरका उन्हें दर्शन हो जाता, तभी जाकर वे प्रकृतिस्थ हो पातीं॥ ७४३॥

मैयासे मिलकर साँवरके अग्रज की जननी रोहिणीके तत्त्वाधान में रंधन के सभी कार्य सम्पन्न होते। हाथोंसे सब कुछ करते रहने पर भी राधाकिशोरीका मन तो प्रियतम नीलसुन्दर के नीले-नीले तनके अप्रतिम सौंदर्यमें ही डूबा रहता॥ ७४४॥

उस ओर मैया भी निरन्तर बस, एक नीलमणिकी सँभालमें ही लगी रहतीं। न जानें उन्हें कितनी ही नवीन नवीन गाथाएँ गढ़नी पड़ती थीं। तभी जाकर वे नीलसुन्दरको उबटन लगा पातीं। उनका स्नान सम्पन्न करा पातीं। श्रृंगार धरा पातीं और इन सबके अनन्तर भोजन गृहमें नीलसुन्दरको लिये हुए आ पहुँचतीं ।.....॥ ७४५॥

सम्पूर्ण सखाओंके साथ नीलसुन्दर हँस-हँस करके कलेवा करते। उनके भोजनका यह दृश्य सबकी आँखोंके लिये एक अप्रतिम निधि बना रहता। मैयाका आन्तरिक स्नेह नीलसुन्दरको दबा लेता और जैसे-तैसे २५-३० पल के लिये हँस करके उन्हें मैयाके आग्रहका आदर करना ही पड़ता, विश्राम लेना ही पड़ता॥ ७४६॥

यह सब हो जाने के अनन्तर अब पत्तन मुरली-रव से मुखरित होने लगता। तोरणद्वारसे मानो उज्ज्वल धारा निःसृत हो रही हो - इस भाँति गो-श्रेणी चल पड़ती। उस अपार गो-राशिके एकमात्र चालक वे नील देवता ही थे, इसीलिये वे भी साथ-साथ ही चलते। राधाकिशोरी अटारीसे इस दृश्य को निहारती रहतीं॥ ७४७॥

साँवर की जननीके हृत्तलकी निर्मल वत्सलता अब राधाकिशोरीको अभिषिक्त करने लगती। उनका कण-कण इस वात्सल्य रस से परिपूरित हो जाने पर मैयाकी अनुमति लेकर किशोरी अपने वासस्थलपर लौट आतीं। पहलेकी भाँति दसों दिशाओंमें केवल साँवरको सर्वत्र भरे हुए देखीं। उस समय राधाकिशोरीमें बाहरका ज्ञान नहीं-सा ही रहता था॥ ७४८॥

पगली-सी हुई वे अपने आवाससे बाहर आकर बैठ जातीं अब नूतन रंगस्थलका, सरोवरके तटपरके द्वितीय पटके उद्घाटनका समय जो हो चुका था। वनगमन जनित वियोगकी अग्नि सहसा अपनी क्रीड़ाका विस्तार करने लगती, उसकी लीला आरम्भ होती। उद्गमस्थल -राधाकिसोरीका हृदेश जलने लगता। जैसे-तैसे सखियाँ उस आगको संयत किये रहतीं॥ ७४९॥

गिरिराज परिसरका वह सुन्दर वन, जिसमें वे आठ कुंजें सुशोभित हैं, उनमेंसे ही किसी कुंजमें सहचरियाँ राधाकिशोरीको ले आतीं। वहीं विराजित रहकर राधाकिशोरीको नीलसुन्दरकी प्रतीक्षा करनी पड़ती, परन्तु प्रतीक्षाका एक-एक पल किशोरीको युग-सा प्रतीत होता। सचमुच जब राधाकिशोरीकी दसवीं दशा आने जैसी परिस्थिति बन जाती, तब नीलसुन्दर सरोवर-तटपर आ पाते थे।.....॥ ७५०॥

सरोवरपर दोनोंका मिलन हो जानेपर अब रसका महासमुद्र जो लहराने लगता, उसका ऊँचापन कितना है- आजतक किसने उसे आँका है? उस रसके महासमुद्रमें सहचरियोंकी आँखें ही डूबती थीं और वे उतराकर कभी तटपर आयी ही नहीं। इसीलिये इसका चित्रण कौन करे? उन कुञ्जोंकी द्रुम-लतायें तो तबसे अभी आज इस क्षण तक जड़िमा परिपूरित हैं। वे क्या, कैसे संकेत-दान करें भला !॥ ७५१॥

जो हो, नीलसुन्दर राधाकिशोरीको लिये हुए उन दोनों सरोवरों श्रीराधाकुण्ड और श्रीकृष्णकुण्डकी परिक्रमा-सी करने लगते। वे साधारण सरोवर तो हैं नहीं! नित्य प्रियतमाके स्वरूपसे ही वे नित्य प्रभावित रहते हैं। उनकी परिक्रमाका सौन्दर्य कितना अप्रतिम, अद्भुत, होता होगा-कौन कहे ? बाह्य चित्रण इतना-सा ही सम्भव है कि वे गौर-नील दम्पति नौकारोहण करके हँस-हँसकर विकसित सरोजवनकी फेरी देने लगते। सौरभसे भरपूर अरविन्दोंका बार-बार चयन करके अपने स्पर्शका उन्हें अप्रतिम सुखदान करते॥ ७५२॥

निकुञ्जके तरुपत्रोंसे मधुके निर्झरका दृश्य देखने ही योग्य होता। स्थान-स्थानपर नैसर्गिक निर्झर झरते रहते। किसी भी ऋतुमें इस निर्झरका विराम होता ही नहीं। यहीं इनके समीप ही नीलसुन्दर राधाकिशोरीको खींचकर ले जाते। इनके समीप पहुँचते ही झरना द्विगुणित वेगसे झरने लगता। नीलसुन्दर कमलपत्रके दोनेमें प्रकृतिके इस मधुदानका आस्वादन राधाकिशोरीको कराते और स्वयं भी इसका रस लेते॥ ७५३॥

चन्दनकी तरुश्रेणीसे कामिनीके वृक्षोंका जाल निर्मित हो गया था। सामने ही कुञ्जोंकी कुटीर बनी हुई थीं। गौर-नील दम्पति भाव-विभोर होकर किसी एक कुञ्जकुटीमें प्रविष्ट हो जाते। वहाँसे ठीक उत्तरकी ओर कल्पतरुका वन सुशोभित दीखता। कल्पतरुओंकी शोभा निराली थी। पूरे वनको ज्योतिर्मय तथा उज्ज्वल नील आभासे वे उद्भासित करते रहते; दम्पति उसकी ही गाथा कहते एवं सुनते॥ ७५४॥

राधाकिशोरीमें कल्पतरुके वनकी गाथा सुनते-सुनते ऐसी तन्मयता आ जाती कि उन्हें अपने स्वरूपका भी विस्मरण हो जाता। अपनेको भूली हुई वे अपने ही सम्बन्धमें नीलसुन्दरसे कतिपय प्रश्न करने लग जातीं, जिन्हें सुन-सुन करके साँवर स्वयं भ्रमित हो जाते और सोचने लगते -' अहो ! प्रियतमाको कैसे क्या समझाऊँ मैं ?॥ ७५५॥

ऐसे अवसरोंपर पुनः वही घटना घट जाती-जो महाभाव है वह एक पल में ही रसराज बन जाता, उधर रसराज महाभाव-वपुमें अभिनिविष्ट हो जाता। 'प्राणरमण नीलसुन्दर ! उस अनिर्वचनीय रसमय विनिमयकी गाथा क्या कहूँ, कैसे कहूँ ?'॥ ७५६॥

सहसा दिनकरकी एक किरण लता-वल्लरियोंके छिद्रसे झाँककर उन्हें छू लेती। फिर तो तत्क्षण उनमें संकल्प जग उठता- 'अहो! बड़ी देर हो गयी।' साथ ही अपने स्वरूपमें वे पुनः लौट आते और हँसते हुए चल पड़ते। सामने ही राधाकिशोरीके नामसे विभूषित कासार श्रीराधाकुण्ड पुनः दीखने लगता-मानो वह दम्पत्तिको निमंत्रित कर रहा हो॥ ७५७॥

किशोरीमें, नीलसुन्दरमें उसी में अवगाहन करने की इच्छा सहसा जाग उठती। उस ओर निदाघ ऋतुका स्पष्ट अनुभव होने लगता। वृन्दाकाननमें सम्पूर्ण ऋतुएँ दम्पत्तिकी रुचिका अनुसरण करती रहती हैं। पलभर पहले जलमें, थलमें, कोई भी ऋतु क्यों न हो, वह तत्क्षण विलीन हो ही जाती और नव सुषमासे विभूषित होकर नया काल सबको तदनुरूप क्रीड़ाकी प्रेरणा देने लगता॥ ७५८॥

किशोरी जलका स्पर्श करने लगतीं। फिर क्या था, नीलसुन्दर तत्क्षण जलमें उछल पड़ते और प्रियतमाको अङ्कमें लिए, संतरणकी क्रीड़ा आरम्भकरते। कमलपुष्पोंसे विरचित कन्दुककी भी एक नई अद्भुत क्रीड़ा होती। सम्पूर्ण सरोवर दम्पत्तिके तनका निरुपम सौरभ अपनेमें लेकर उसे जलपर सर्वत्र बिखेर देता। गौर-नील अंगोंका सौरभ सरोवरके कण-कणमें परिपूर्ण हो जाता॥ ७५९॥

जब भीगते-भीगते राधाकिशोरीके दृग अत्यधिक अरुण हो जाते, तब कहीं उस पवित्र निराविल अत्यंत सुखमयी जलकेलिको दम्पत्ति विराम देते। उस समय किशोरीके-नीलसुन्दरके आर्द्र कुन्तलोंको, उनके गौर-नील तनको बार-बार मृदु करसे पोंछ-पोंछ करके जब सहचरियाँ उन्हें वस्त्र धारण करातीं, अहा! उस समयका यह दृश्य, उस दृश्यका गूढ़ इतिहास कैसा अप्रतिम है-कौन बतावे ?....॥ ७६०॥

तदनन्तर मन्द मंथर गतिसे चलकर वे बकुलकुञ्जमें पधारते। परस्पर श्रृंगार धारण कराते समय एक रसमयी बतकही छिड़ जाती। सच तो यह है, अनादिकालसे अबतक यह निर्णय नहीं हो सका-किसको किसने पहले विभूषित करनेमें सफलता प्राप्त की? इसका निर्णय कौन बतावे ?....॥ ७६१॥

उस कुञ्जसे सम्बद्ध एक अतिशय सुन्दर निकुञ्ज और भी है-उसीमें दम्पति पधारते और वहीं पीयूषके सदृश रसमय वनफलके रसका आस्वादन करते। किशोरीके अधरपल्लवोंपर साँवरका और फिर साँवरके बिम्बाधरपर किशोरीका फल रखना सहचरियिोंके लिये दृगफल हो जाता॥ ७६२॥

पीत-हरित मणियोंसे विरचित जो एक मोहन-निकुञ्ज अत्यंत सन्निकटमें ही विराजित है, उसीमें एक दण्डके लिये दम्पति पुष्पोंकी शैयापर विश्राम करते। इस निद्रा-सुखके अनन्तर वे शीतल जलका पान करते और तब शुक-सारीकी अद्भुत पाण्डित्यपूर्ण रचना सुननेकी बारी आती। वह रचना इतनी भावमयी होती कि उसे सुनते-सुनते दम्पति सुखसे अचेत हो जाते॥ ७६३॥

इसी समय तृणकी एक मनोरम वेदीपर सोलह कौड़ियाँ लेकर दम्पति परस्पर अपने अंगोंका ही दाँव लगाकर नवीन क्रीड़ा आरंभ करते। जो दाँव जीत लेता अथवा जीत लेती, उसको यही अनुभव होता कि मैं तो हार गया, मैं तो हार गयी। कौड़ियोंकी उस क्रीड़ाके कुछ ऐसे ही रसभरे नियम जो बने हुए थे।....॥ ७६४॥

अब इस समय प्रतीचीके गगनमें अंशुमाली ढले हुए दीखने लग जाते। फिर तो अविलम्ब दम्पति हीरक रवि मंदिरमें अर्चना करने आ जाते। नीलसुन्दर अतिशय मनोहर शैलीसे अपने ही द्वारा विरचित मंत्रों का पाठ करके रविदेवकी अर्चना करवाते। उनकी दिनकरकी यह पूजा सम्पन्न होते देखकर किशोरीकी आँखोंमें, मनमें नवीन-नवीन सुखकी आशा भरने लगती ।.....॥ ७६५॥

इसके पश्चात् परस्पर बिछुड़नेकी वही आग धक् धक् करके जलने लग जाती। नीलसुन्दर अपनी गायोंको, सखासमूहोंको सँभालनेके उद्देश्यसे उस ओर चल पड़ते। अन्तर्हृदयमें रजनीके आनेपर पुनर्मिलनकी उस आशाको लिये हुए राधाकिशोरी एक मुरझाई माला-सी अपने घर आकर शैया पर निमीलित नेत्रोंसे ढल पड़तीं ।...॥ ७६६॥

सहचरियाँ राधाकिशोरी की नवीन वेषभूषा का निर्माण करतीं। इतनेमें ही वेणुरवसे वनका कण-कण पूरित होने लगता। नीलमणि संध्याके समय मैयाके पास जानेके उद्देश्यसे नन्दप्रासादकी ओर अग्रसर होते। कुछ पलोंके लिये दूर से ही राधाकिशोरी प्रियतम नीलुसन्दरका दर्शन करके कृतार्थ होतीं।...॥ ७६७॥

प्रत्येक वस्तुमें अपने प्राणोंका रस भर-भर करके यशोदा मैया अपने प्राणोपम पुत्रका उन वस्तुओंसे संलालन करतीं और सुखमें निमग्न होती रहतीं। इस प्रकार प्रदोषका क्रम पूरा करके नीलसुन्दर सो जाते तथा उस ओर त्रिभुवन-मोहन-मोहिनी शक्ति जननी यशोदाको भी आवृत कर लेतीं॥ ७६८॥

जब निस्तब्ध निशाका आरम्भ हो जाता तो अचानक नीलसुन्दर उठ पड़ते और बड़ी सावधानीसे कलिन्दनन्दिनीके तटके उस वटके समीप आ जाते। उसी संकेतस्थल पर राधाकिशोरी पहलेसे ही आयी रहतीं। किशोरीका यह निराला अभिसार सभीको अज्ञात ही रहता, किसीको इसकी गन्धतक नहीं लग पाती॥ ७६९॥

अचानक दोनोंमें ही भावोंका एक विचित्र आवेश हो जाता। परस्पर प्रत्यक्ष सामने ही विराजित रहनेपर भी दोनों एक दूसरेको देख नहीं पाते। फिर तो अत्यन्त व्याकुल होकर निरुपाय हुए एक दूसरे को ढूँढ़ने लगते। अहा! दोनोंके लिये ही यह अखिल दृश्य जगत् ध्येयमय बन जाता था॥ ७७०॥

भावकी यह लहर प्रशमित होते-होते एक घड़ीका समय लग ही जाता।

फिर परस्पर भुजबन्धन में दम्पति बँध पाते। जो भी बड़भागिनी सहचरी खड़ी- खड़ी उस खोज-मिलनकी लहरोंमें अवगाहन करती हुई डूब पायी, वही, रस क्या वस्तु है-इसको समझ सकेगी भला !॥ ७७१॥

अब शुभ्र चाँदनीमें गौर-नील दम्पतिका धीरे-धीरे चलना, कलिन्दनन्दिनीका जल गुल्फपरिमित होकर उन्हें पथ दे देना, दोनोंका ही हँसते-हँसते उस पार चले जाना, इसका विस्तृत विवरण देने जाकर मैं इसकी सुन्दरताको भी खो दूँगी-ऐसा अद्भुत है यह॥ ७७२॥

आगे रासस्थलकी स्वर्णिम वेदी, स्वर्णिम वह विशाल मंच, स्वर्णिम दण्डोंसे जुड़ी हुई वे स्वर्णिम वल्लरियाँ, वह पुष्पोंसे निर्मित स्वर्णिम वितान, स्वर्णिम विहंगोंकी श्रेणी-यह सब गौर-नीलदम्पतिको अपनी ओर बरबस आकर्षित कर लेते !॥ ७७३॥

दम्पति इनके समीप आ जाते ! इनको छू-छू करके वे दोनों खिल उठते । सहचरियाँ पहलेसे ही सब कुछ प्रस्तुत करके रखतीं। नीलसुन्दर वहाँ आकर अपने करसरोजसे सबको ताम्बूल अर्पित करते और फिर कुछ ही क्षणोंमें गौर-नीलदम्पति का नृत्य आरंभ हो जाता॥ ७७४॥

यह नृत्य कबतक चलता-अहो! मैं कैसे बतलाऊँ? अभीतक आँखों में हल्लीसक मुद्राएँ ज्यों-की-त्यों परिपूरित हैं। निर्मल मध्य नभके बीचमें शशधर मति भूले वैसे ही अवस्थित हैं। मुग्ध होकर सब देख रहे हैं, सबकी आँखें केन्द्रित हैं गौर-नीलदम्पतिके मनोहर नृत्य पर।....॥ ७७५॥

पल-पलमें राधाकिशोरीकी कटि उस भाँति ही झुक जाती है। वक्षस्थलका

अम्बर भी वैसे ही चञ्चल हो रहा है। दोनों कर्णकुण्डल भी वैसे ही चञ्चल हो रहे हैं

और आनन-सरोजपर वैसे ही प्रस्वेदकण झलमल कर रहे हैं।....॥ ७७६॥

अलकोंसे सुमन झर-झर करके वैसे ही रासस्थलको आभूषित कर रहे हैं। नीलसुन्दर अपने दुकूलमें उन सुमनोंका चयन करते जा रहे हैं। उस भाँति ही नाच-नाच करके साँवर भी बालाकी नृत्यभंगिमाका सरस अनुमोदन कर रहे हैं।....॥ ७७७॥

रसमय तन्त्रोंके तार वैसे ही झंकृत हो रहे हैं। नूपुरका रुनझुन रव वैसे ही सहयोग दे रहा है। तालबंध उस भाँति ही पल-पलमें नवीन होता जा रहा है और वैसे ही रह-रह करके नीलसुन्दरकी करताली भी बज उठती है। अस्तु...॥ ७७८॥

इसपर मैं एक सरस झीना आवरण डालकर ही आगे चल रही हूँ। साँवरको, राधाकिशोरी को अपनी आँखोंमें लिये हुए ही आगे बढ़ रही हूँ। उस ओर उन दोनोंका नृत्य भी अविराम चल ही रहा है। साथ ही उधर देखो, उसी क्षण वे निकुञ्ज पथमें भी अग्रसर हो रहे हैं॥ ७७९॥

इस प्रकार युगपत् एक ही कालमें, एक ही साथ उत्तर विभाग, दक्षिण विभाग क्रीड़ाका स्थल बन जा रहा है। दोनों ही ओर केवल वे ही दोनों खेल रहे हैं, किन्तु हम तो अब उत्तरकी ओर चलें। अब केवल दो घड़ीकी ही देर है। वह देखो ऊषा सखी हम दोनोंसे मिलने आनेवाली ही है॥ ७८०॥

जो हो, निकुञ्जभवनमें जब दम्पति आकर विराज जाते, तब उन दोनोंमें रहस्यमय कौतुक अत्यन्त विचित्र-सा पहेलियोंका कौतुक आरम्भहोता। राधाकिशोरी नीलसुन्दर के समक्ष कुछ सरस पहेलियाँ रख देतीं और नीलसुन्दर किञ्चित् सोचकर हँस-हँस करके उन पहेलियोंका उत्तर देते जाते॥ ७८१॥

राधाकिशोरी पूछतीं-पहली कौन है?

नीलसुन्दर उत्तर देते-जो स्निग्ध बनी।

फिर कौन है?

उत्तरमें नीलसुन्दर कहते- जो अत्यन्त शीतल है।

तीसरीको बलाओ?-किशोरी पूछतीं।

उत्तर में नीलसुन्दर कहते- जो तरल एवं सुरभित है।

अब चौथी कौन? किशोरीका प्रश्न होता।

उत्तरमें नीलसुन्दर कहते-वही सुस्मित वाली।

पंचम कौन ? बतलाओ, प्रियतम !

उत्तरमें नीलसुन्दर कहते- वह उज्ज्वल मणिमाला जो है।

अच्छा, छठी कौन ?

नीलसुन्दर-जो असीम मधुर है।

किशोरी-मिल गयी?

नीलसुन्दर-अनुग्रहमयी! तुम साथ जो हो, इसीलिये मैं नित्य निहाल हूँ॥ ७८२॥

किशोरी-अब पहली ?

नीलसुन्दर-जो नित्य अरुण है।

किशोरी-फिर ?

नीलसुन्दर-जो जीवनका जीवन है।

किशोरी - तीसरी ?

नीलसुन्दर-लावण्यकी निधि है।

किशोरी- अब ?

नीलसुन्दर-मुखमें बसी हुई है।

किशोरी-पाँचवीं ?

नीलुसन्दर-अमल बूँदोंवाली है।

किशोरी-छठी ?

नीलुसन्दर-सुचिह्नित है।

किशोरी-मिल गयी।

नीलसुन्दर-अनुग्रहमयी! तुम साथ जो हो, इसीलिये मैं नित्य निहाल हूँ॥ ७८३॥

किशोरी-अब पहली ?

किशोरी-काली ताली है।

किशोरी-फिर ?

नीलुसन्दर-पद्मराग रेखा है।

किशोरी - तीसरी ?

नीलसुन्दर-निराविल और पोली।

किशोरी-फिर ?

नीलसुन्दर-दीना पदवाली है।

किशोरी- अब ?

नीलसुन्दर-शशिके गुणसे विभूषित है।

किशोरी-फिर ?

नीलसुन्दर-पदकी अँगुलीमें है।

किशोरी-मिल गयी ?

नीलुसन्दर- अनुग्रहमयी! तुम साथ जो हो, इसीलिये मैं नित्य निहाल हूँ॥ ७८४॥

किशोरी-अब कौन ?

नीलसुन्दर-सरसती रहती है।

किशोरी-फिर

नीलसुन्दर-रस-कलसीवाली।

किशोरी-अब कौन ?

नीलसुन्दर-छाप छलनेवाली।

किशोरी-आगे ?

नीलसुन्दर- प्रस्वेदभरी।

किशोरी-फिर ?

नीलसुन्दर-वह तिरछी चितवन में है।

किशोरी- अब ?

नीलसुन्दर-तोरण लतिका है।

किशोरी-मिल गयी ?

नीलसुन्दर-अनुग्रहमयी ! तुम साथ जो हो, इसीलिये तो मैं नित्य निहाल हूँ॥ ७८५॥

किशोरी-अब पहली ?

नीलसुन्दर-जो बँधी हुई है।

किशोरी-फिर ?

नीलसुन्दर-दृगमें निवास करनेवाली है।

किशोरी - आगे ?

नीसुन्दर-वह निर्मल हास्यमयी है।

किशोरी-फिर ?

नीलसुन्दर-असित बिन्दुवाली है।

किशोरी - पञ्चम ?

नीलसुन्दर-आवरण कण्ठ में है।

किशोरी-छठी ?

नीलसुन्दर-माँग भरत है।

किशोरी-मिल गयी ?

नीलसुन्दर-अनुग्रहमयी! तुम नित्य साथ जो हो, अतएव मैं नित्य निहाल हूँ॥ ७८६॥

किशोरी-अब पहली ?

नीलसुन्दर-कर धरनेवाली।

किशोरी-फिर ?

नीलसुन्दर-कर एवं पद गति वाली।

किशोरी-अब ?

नीलसुन्दर-काली रेखा है।

किशोरी-आगे ?

नीलसुन्दर-पलकों से जुड़ी हुई है।

किशोरी - पञ्चम ?

नीलसुन्दर-पदकंज विभूषित है।

किशोरी-फिर ?

नीलसुन्दर-आलस्यभरी है।

किशोरी-मिल गयी ?

नीलसुन्दर- अनुग्रहमयी ! तुम नित्य साथ जो हो, इसीलिये तो मैं नित्य

निहाल हूँ॥ ७८७॥

किशोरी-अब पहली ?

नीलसुन्दर-लाल सलों वाली।

किशोरी-फिर ?

नीलसुन्दर-उर पर रहती है।

किशोरी-फिर ?

नीलसुन्दर-पीली, नीली और पोली है।

किशोरी- अब ?

नीलसुन्दर-होठों में बसी है।

किशोरी - पञ्चम ?

नीलसुन्दर-पद-रेखावाली है।

किशोरी-वह छठीं ?

नीलसुन्दर-भुजा में है।

किशोरी-मिल गयी ?

नीलसुन्दर - अनुग्रहमयी ! तुम नित्य साथ जो हो, इसीलिये मैं नित्य निहाल हूँ॥ ७८८॥

किशोरी-अब पहली कौन ?

नीलसुन्दर-कुण्डलवाली।

किशोरी-फिर ?

नीलसुन्दर-जो तनके कण-कण में है।

किशोरी- अब ?

नीलसुन्दर-जो पद-पदपर मुखरा है।

किशोरी-चौथी ?

नीलसुन्दर-कटि थामे है।

किशोरी - पंचम ?

नीलसुन्दर-कुञ्चित कचमें है।

किशोरी-फिर ?

नीलसुन्दर-कर धारण करके पीन बनी हुई है।

किशोरी-मिल गयी ?

नीलसुन्दर- अनुग्रहमयी ! तुम नित्य साथ जो हो, इसीलिये मैं नित्य निहाल हूँ॥ ७८९॥

किशोरी- अब अन्तिम कौन है?

नीलसुन्दर- उसे तो मैं छूकर बतलाऊँगा।

यह कहकर साँवर राधाकिशोरीको अपनी करमाला पहना देते हैं। तद्नन्तर उस रसमुद्रमें जो लहरें उठती हैं, उनमें तो स्वरूपसे ही मज्जन करने की पद्धति है भला !॥ ७९०॥

अपने ऊपर, अपने से ही, अपने को ही, अब आगे वे लहरें रसमय कूलका रूप दान करती हैं, जिसपर साँवर उतराते हैं, राधाकिशोरी उतराती हैं। कुछ पलके लिये यह आनन्द लेकर उनमें बातें होने लगती हैं॥ ७९१॥

नीलसुन्दर कहते हैं- 'प्रियतमे ! एक कहानी कहो। तुम तो बहुत-सी कहानी जानती हो।'

प्रियतमा राधाकिशोरी तुरन्त उत्तर देती हैं- 'प्राणाधिक! मैं सब भूल गयी। तुम तो कहानी कह सकते हो !'

नीलसुन्दर बोल उठते हैं-' प्राणवल्लभे! नहीं, नहीं, तुम मेरी यह रुचि रख ही दो।' राधाकिशोरी एक क्षणके लिये कुछ सोचती हैं और फिर कहती हैं- 'अच्छा तो सुनो, पर सुनकर हुँकारी अवश्य देते रहना।'॥ ७९२॥

'सुनो!'- किशोरीकी कहानी प्रारम्भ होती है। 'अहीरोंकी एक बस्ती थी।

उनका एक अधिपति भी था। उसका एक पुत्र था। बड़ा ही चञ्चल था वह। उस पुत्रका गात्र काले रंगका था। त्रिभुवनके समस्त प्राणियोंका मन मोहित कर देनेकी शक्ति जिस सुन्दरतामें है, ऐसी सुन्दरता उस चपल बालकने पायी थी। वहाँकी सभी तरुणियाँ उस छोरेपर बिना मोलके ही बिकी हुई थीं॥ ७९३॥

अभी कुछ देर पहले की घटना बतलाती हूँ। उस काले बालकने अपनी वंशीमें एक ऐसी तान भरी कि जिसे सुनते ही वहाँकी सभी तरुणियाँ मोहित हो गयीं और क्षण भरके लिये भी रुक न सकीं। आधा क्षण बीतते-न-बीतते सब कुछ परित्याग करके उस काले बालकके समीप आ गयीं॥ ७९४॥

उस कृष्णवर्ण बालकने पहले उनका स्वागत किया। फिर उसने उनकी एक कड़ी परीक्षा ली। काले बालकने उन सबको पहले तो भय दिखलाया, फिर खूब बहकाया। इसके पश्चात् धर्मोचित शिक्षा भी उसने दी। फिर बालकने अपने प्रति भाव बढ़नेका उन सबोंको एक नूतन पाठ पढ़ाया। बालककी बातें सुन-सुन करके उन सब तरुणियोंके प्राणोंमें टीस-सी चलने लगीं॥ ७९५॥

वे तरुणियाँ रो-रो करके उस बालकको उत्तर दे-दे करके उस परीक्षा में खरी उतर आयीं। फिर तो उस बालकके रसमय हृत्तलमें करुणाकी ऊर्मियाँ उठने लगीं। तरुणियोंके जीवनकी सभी साध उसने उसी क्षण पूरी कर दी, किन्तु प्रीतिकी रीति बड़ी निराली होती है। बालक तुरन्त कहीं वहीं छिप गया॥ ७९६॥

अहो! उस बालकको एक अच्छा-सा बहाना भी मिल गया। एक छोरी थी, उसीमें उस बालकका मन फँसा हुआ था। वह छोरी गौरवर्णा थी। उस राजाकी बेटी थी, जिस नृपतिके तनमें वे देवदिवाकर नित्य निरंतर पूरित होकर सदा निवास करते थे। अस्तु...॥ ७९७॥

उस छोरीको अपने साथ लिये वह बालक सबको छोड़कर भागा था। अचानक उस बालकको उस छोरीका मुख म्लान दीखने लगा था। इसीलिये असंख्य सुन्दरियोंका स्नेहजाल व्यर्थ सिद्ध हुआ। उस जालमें अब सामर्थ्य नहीं रही थी, जो उस बालकको उलझाकर रोक सके॥ ७९८॥

उधर उस छोरीमें पल-पलमें सभी बातोंको भूलनेका स्वभाव निसर्ग दत्त था। छोरी बालकके अङ्कमें ही विराजित थी। किन्तु छोरी भ्रमित होकर समझ बैठी कि वह बालक मुझे भी छोड़कर चला गया। इस ओर तो छोरी भ्रमवश ऐसा समझ बैठी, उधर रसके नियमोंमें बँधा हुआ बालक उन तरुणीगणके दृगपथसे सचमुच ही हट गया था॥ ७९९॥

इस प्रकार वियोगकी दो सरिताएँ दो विभिन्न दिशाओंसे उमड़ चलीं। दोनों सरिताएँ पथमें आकर संगमित भी हो गयीं। वहीं उसी तटपर बालक खड़ा भी था। उसके कानों में प्रवाहिणीकी ध्वनि गूँज रही थी और उसके हृत्पटपर सभी लहरों के चित्र ज्यों-के-त्यों अङ्कित हो रहे थे।....॥ ८००॥

हाय रे! उस महामोहन सुन्दरातिसुन्दर पदसरोजको किञ्चित् भी कोई-साक्षत न लग जाये इस भयसे नित्य भयभीत हुई हम सभी उस पदकंजको अपने कर्कश हृदयपर धारण करतीं। किन्तु हाय-रे-हाय ! उस पदसरोजकी इस समय कैसी दयनीय दशा हो रही होगी; क्योंकि सर्वत्र काँटे बिखरे हुए हैं। पत्थरके तीक्ष्ण कणोंसे भूमि परिपूरित है और सर्वत्र घोर अँधेरा भरा हुआ है॥ ८०१॥

जैसे ही करुणासे सिक्त हुई यह लहरी उस बालकके हृद्देशपर प्रतिचित्रित हुई कि बस, उसी क्षण वह श्यामवर्ण बालक उनके दृगके आगे हँसता हुआ खड़ा हो गया। अब रसके आदान-प्रदानमें कोई अर्गला न रही। उन असंख्य सुन्दरियोंको उस समय क्या कैसा अनुभव हुआ, इसे कोई भी चित्रित कर ही नहीं सकता॥ ८०२॥

इसके पश्चात् परम मनोहर नृत्यका बृहत् आयोजन हुआ। गौरवर्णा छोरी नाची, फिर उस बालकका नृत्य हुआ। सब-की-सब तरुणियाँ अपना-अपना नृत्य दिखाकर आनन्दके समुद्रको तरंगित करने लगीं। उनकी इस नृत्यकहानीका एक अंशमात्र अब मेरे मानस-पटलपर अङ्कित है भला! शेष सभी मैं सर्वथा भूल गयी हूँ॥ ८०३॥

राधाकिशोरी इतना-सा ही कहकर अर्द्ध-निमीलित-नयना होकर रुक गयीं! नीलसुन्दर तुरन्त ही बोल उठे- 'प्रियतमे ! क्या तुम मुझे आज्ञा दे रही हो मैं तुम्हें फिरसे याद करा दूँ?' उत्तर में अन्यमनस्का-सी हुई राधाकिशोरी तुरंत कह बैठीं- 'क्या करना प्रियतम ! अब तुम श्रमित हो रहे हो। विश्राम करो।' राधाकिशोरीका यह उत्तर पूरा होते-न-होते उनकी आँखें झपने लग गयीं॥ ८०४॥

उधर नीलसुन्दरके नयनसरोज भी निमीलित होने लग गये। दोनोंकी भावमयी निरुपम समाधि आरम्भ हुई। सविकल्प और निर्विकल्प कही जाने वाली सत्ताएँ उनकी उन समाधिको स्पर्श भी नहीं कर सकतीं- ऐसी वह अद्भुत समाधि थी ।...॥ ८०५॥

उसका प्रतिबिम्ब मन, बुद्धि, वाणी, कहीं छू भले लें और उसे छूनेका यह फल हो जाये कि सदा के लिये वे तद्रूप होकर कृतार्थ हो जायें- इतना-सा ही सम्भव है। इसके आगे और मैं क्या कहूँ प्राणरमण! प्राणाधिक हे ! तुम सागरको गागरमें निहार लेना भला !॥ ८०६॥

जो हो, आगे की ओर तो मैं बढ़ ही नहीं सकती। बायीं ओर मुड़ जाती हूँ। धारामें सर्वथा सीधे संतरण करना सुखद नहीं होता ... और स्पष्ट देखो! वे गौर-नीलदम्पति अब तो इसी ओर आ रहे हैं भला !.... अचानक राधाकिशोरी की आँखें खुल गिईं। किन्तु हायरे ! उन्हें पुनः क्रन्दन ही करना है।...॥ ८०७॥

जो हो, राधाकिशोरीका रसभरा यह स्वप्न भी आखिर बदल ही गया। सदाका ही यह नियम है-सुखके दिन थोड़े से ही होते हैं, यद्यपि दुःख बीज ही है उस सुखका-जो नित्य है, सनातना है। पर एक बार तो राधाकिशोरीका हृदय मानो शूलोंसे छिद ही गया; प्राण सर्वथा विद्ध हो गये उनके ....॥ ८०८॥


''');
        case 'नौवाँ शतक':
          return const _TopicPageContent(
              body:
                  '''वहाँ गोपेश नगरी गोकुल ग्राममें कोई एक दूत (अक्रूर) आया हुआ था, जो उस राजा (कंस) का भेजा हुआ था, जिसके अधीनस्थ करदाता राजागण निरन्तर भयभीत बने रहते थे, क्योंकि वह कंस अत्यन्त नृशंस प्रकृतिका था। कौन जाने, वह क्या कर डाले ? समस्त राजागण उसे कौशल पूर्वक संतुष्ट करके ही उससे बच पाते थे॥ ८०९॥

उस राजा कंसने कपटपूर्ण अभिसन्धिसे एक वृहत् यज्ञोत्सवका आयोजन किया था, जिसमें सम्मिलित होनेके लिये उसने उस साँवर किशोर नन्दनन्दनको भी बुलवा भेजा था। वह दूत (अक्रूर) उस राजा कंसके उस सन्देशको लेकर ही वहाँ पहुँचा था। सुनो, सन्ध्याकी अरुणिम किन्तु धूमिल रश्मियाँ क्षितिजको आत्मसात् कर चुकी थीं। अपशकुन हो रहे थे किशोरीको॥ ८१०॥

कुन्तलमें गुम्फित सुमन सहसा म्लान हो गये। नयनोंका अञ्जन तरल होकर कपोलोंपर ढलक पड़ा और जिस अवनीपर किशोरी बैठी थीं, उसपर भी न-जाने कितनी मात्रामें अञ्जनकी काली रेखाएँ अङ्कित हो गयीं अपने-आप। सौरभ बिखेरते विलेपन के कनक-पात्र ढलक गये और हाय रे! किशोरीके कण्ठका नीलम-हार छिन्न होकर उर-स्थलसे नीचे गिर गया॥ ८११॥

धक् धक् कलेजा कर रहा था किशोरीका। इन अपशकुनोंका कोई अर्थ नहीं पा रही थी वह। इतनेमें उसे भान हुआ- आज समीरकी साँय-साँयमें क्रन्दनकी प्रच्छन्न ध्वनि अनुस्यूत है और उस वेलाकी नीरवता मानो किसी महाअशुभकी ओर इङ्गित कर रही थी॥ ८१२॥

उपवन-परिसरकी अट्टालिकाके उत्तुङ्ग ऊपरके कक्षमें किशोरी विराजित थी

और आज ही ऐसा संयोग था, पहले कदापि ऐसी घटना घटित नहीं हुई थी-किशोरी एकाकिनी थी। अमङ्गलकी आशङ्कासे उसके प्राण काँप उठे और वह अपने हृद्गत भावोंको व्यक्त करनेके लिये, अपनी प्रतिक्रियाका अपनी सहचरियोंको भान करानेके लिये नीचेकी ओर दौड़ पड़ी। दो सहचरियाँ नीचेके कक्षमें थीं, किन्तु उनका मुख अत्यधिक उदास था॥ ८१३॥

किशोरीकी आँखोंमें अँधेरा भर आया। भय उसमें विभ्रमका सृजन कर रहा था और पहली स्फुरणा उसके अन्तर्देशमें जगी' ओह! कहीं मेरे प्राणनाथका, नीलसुन्दरका कोई अनिष्ट तो नहीं हुआ है! और इसीलिये मेरी इन दोनों प्राणसहचरियोंकी मुद्रा इतनी खिन्नतासे पूरित दीख रही है।' सिर थामकर वह वहीं बैठ गयी, लुढ़क-सी चली थी; पर न जाने क्यों, कैसे, गिरते-गिरते बच गयी !॥ ८१४॥

प्रौढ़ा सहचरीने उसे अपने भुज-बन्धनमें बाँध लिया। सहचरी चाह रही थी, कुछ बोल दे; किंतु भान था उसे-सुनते ही किशोरीका हृदय फट पड़ेगा; यदि कहीं किंचित् भी आभास पा सकी वह उस बातका, जो उससे छिपायी जा रही थी॥ ८१५॥

दोनों सहचरियाँ देख रही थीं किशोरीकी ओर और उनकी आँखें कुछ कह भी रही थीं, किंतु किशोरी इतना ही भाँप सकी कि इनकी आँखोंमें व्यथाका स्रोत फूटने जा रहा है। किशोरीकी कुम्हलायी आँखें देखती भर रह गयीं उनकी ओर-क्या पूछती वह ? हृत्तल दुर दुर करने लगता था॥ ८१६॥

......और अन्तमें सहचरियोंके दृगोंसे उत्तप्त धाराएँ बह चलीं। वह गुप्त

समाचार उनके अन्तर्देशमें आवृत न रह सका। जल-जल करके निकल पड़ा-धाराका तापमान इतना प्रबल था। और टूटे-फूटे शब्द व्यक्त हो ही गये- 'बहिन मेरी! हाय रे !! नीलसुन्दर इस वनसे दूर, अब दूर जा रहे है वहाँ, वहाँ-वहाँ, जहाँ वह क्रूर नराधम राजा..... राजा रहता है।'॥ ८१७॥

भावी महाप्रलयका आभास आरम्भ हो गया। ज्वालाओंसे घिर गयी किशोरी। नयन स्पन्दन-हीन हो गये और पुतलियाँ टँगी रह गयीं, मानो वे प्राणोंको उड़ जानेके लिये पथ दे देने को प्रस्तुत थीं, किंतु प्राण भी उड़ते कैसे। गतिहीन जो हो चुके थे और उनके ऊपर दुःख का इतना भार - भारका अम्बार लग चुका था, जो वे तिलभर हिल तक न सकते थे। वे ज्यों-के-त्यों अपने स्थानपर ही पिस-से गये। उत्क्रमणका प्रश्न नहीं था अब, लय का द्वार ही अवशिष्ट रहा था॥ ८१८,८१९॥

विलयकी सीमापर वे अवस्थित थे, किंतु अकरुण नियतिका विधान अनेकों वर्षों तक जलते रहनेका जो था। इसीलिये ही प्राणोंको यह सौभाग्य न मिला और नीलसुन्दर सामने आ गये। देश-काल भी परिवर्तित हो गये। रजनीका विराम हो गया था। आठों घटिकाएँ बीत चुकी थीं और वहाँ कुञ्जस्थल था। एकाकिनी किशोरी नीलसुन्दर के अङ्कमें विराज रही थी; साँवर अत्यन्त म्लान थे। बाह्य चेतना आने पर किशोरीने, किशोरीके दृगोंने यही देखा-यही अनुभव किया, और भाव-संधिके एक बिन्दुका आभास लेकर किशोरी अनुभव करने लगी- 'जगन्नियन्ताकी अहा! कितनी करुणा है मुझपर ! उस नृशंस के देशमें जाकर मेरे प्रियतम लौट आये हैं!' उत्फुल्लता की ये किरणें आधे पलतक किशोरीके नयनों में नाचती रहीं, किन्तु सत्य तथ्य क्या था, नीलसुन्दरकी मुखमुद्रा कह बैठ ही। अवकाश रहा नहीं- किशोरी कुछ भी नीलसुन्दरसे कह सकें अथवा नीलसुन्दर कुछ कह सकें प्राणप्रियासे। चारों दृगोंसे अनर्गल उत्तप्त वारिधारा प्रसरित हो रही थी। मात्र इतना ही कुञ्जस्थलकी लता-वल्लरियाँ देख रही थीं॥ ८२०,८२१,८२२॥

रह-रह करके किशोरीकी चेतना लुप्त होती और रह-रह करके नीलसुन्दरका विवेक भी पूरा-पूरा कुण्ठित हो जाता नहीं-नहीं, विलयके अतल तलमें समा जाता। अनुरागके महासमुद्रको अपने हृत्तलमें सँजोये दो हृदय तड़प रहे थे-विवेक उन्हें शान्तिका दान कर दे; यह न तो हुआ है, न कालके अनन्त प्रवाहमें होगा ही। किशोरीके हृदयकी वेदना, वेदनाका तापमान इतना गुरु-गुरुतर था, जिसे अचेतनता - मूर्च्छा भी सह न पायी। दो-तीन पल बीतते-न-बीतते उसके (मूर्च्छाके) अङ्ग जल जाते थे- पूरी-पूरी झुलस जाती थी और भाग छूटती वह किशोरीके तन-देश, मन-देश को छोड़कर॥ ८२३,८२४॥

और नीलसुन्दर के नयन-सरोरुहसे निरन्तर अश्रुका निर्झर झर रहा था। उस महाक्रन्दनकी तप्त ऊर्मियोंमें, अवचेतनाकी छायामें पल-पल आगे बढ़ती रजनी अवसानकी ओर अग्रसर हो रही थी। गोष्ठका काल उस समय कुछ भी हो, यह तो निकुञ्जका देश था, निकुञ्जका काल था, और सम्पूर्ण रजनी इस महाक्रन्दनकी धारामें अवगाहन कर रही थी- श्रान्त होकर तटका आश्रय लेने जा रही थी।

नीलसुन्दरके हृत्तलमें स्फुरणा जागी - 'कैसे विदा लूँ प्राणप्रियासे ?' विवेक बुद्धिका सम्पूर्ण कोष रिक्त हो चुका था। टीस चल रही थी अनवरत रूपसे -जाना तो है ही, पर नीरस यात्रा, नीरस अभिसंधि, सब कुछ नीरस... हाहाकार !॥ ८२५॥

अचानक किशोरीकी आन्तरिक भावनाओंमें, उन महातप्त ऊर्मियोंमें एक कुछ परिवर्तनका आभास परिलक्षित हो उठा और भावसिन्धुकी वह लहरी नाच उठी, जिसे आज तक किसीकी भी आँखें देख न सकी थीं- 'नीलुसन्दर प्राणनाथ प्रियतमके जानेका प्रश्न बना क्यों? इसीलिये तो कि वहाँ, उस नरपतिके नगरमें जानेमें सुखका अनुभव है इन्हें? तो मैं इस सुखकी विघातिनी क्यों होऊँ ?'॥ ८२६॥

....किशोरी संयत-सी हो गयी। नीलसुन्दरकी ग्रीवामें किशोरीकी भुजमाला

झूल रही थी। मधुस्यन्दी गिरा किशोरीके अरुण अधरों से निःसृत हो रही थी- 'प्राणनाथ! क्या सच जा रहे हो? तो मुझे बतला दो, मैं तुम्हें जानेकी अवश्य सम्मति दे दूँगी.... मैं तो इन पद-नलिनोंकी ही अनादि नित्य क्रीत किंकरी हूँ, भला !'॥ ८२७॥

और कहते-कहते किशोरीका कण्ठ रुद्ध हो गया। विचित्र दशा थी नीलसुन्दरकी भी। वे इतना ही कह पाये- 'मेरे प्राणोंकी रानी ! वहाँ कुछ कृत्य अवशेष हैं इस तनके, और मन तो, मनका कण-कण तो इन पीत पद-नखमणियोंमें ही निरन्तर था, है और रहेगा ही।'॥ ८२८॥

'जाओ, प्राणाधिक!' धीमे स्वरमें इतना ही व्यक्त हो सका। बस, वाणीका विनिमय इतना ही हो पाया। शेष नयनकी पुतलियाँ, आर्द्र रोमावलि अपनी नीरव भाषामें जो कहना था, कह गयीं.... !॥ ८२९॥

.... और अन्तिम बारके लिये उरःस्थलका परस्पर संलग्न होना कैसा था-क्या कहूँ, क्या सुनाऊँ? चेतना खो दोगे उसे सुनते ही, और इसलिये यह इतिवृत अधूरा क्यों रहे?... यह उचित न होगा। अतः सुनो, आगे वे दोनों निकुञ्जसे कैसे निःसृत हुए-॥ ८३०॥

अभी भी दोनों गलबाँही दिये हुए ही थे। यन्त्रवत् चरण-सरोरुहोंकी गति दक्षिण की ओर हो गयी; कलिन्दनन्दिनीकी धाराको दोनोंने पार कर लिया और वनस्थलका वह द्रुम आ गया, जहाँ वे प्रतिदिन कुछ घटिकाओंके लिये विदा लेते थे, किंतु उस स्थल पर आते ही वात-व्याधिसे प्रभावितकी भाँति सम्पूर्ण चरणदेश, दोनोंका ही-झनझन कर उठा॥ ८३१॥

..... क्षमता न रही किशोरीमें कि अब वह अपने नयनों को उन्मीलित रख

सके। पुतलियाँ मानो कह उठीं- 'क्यों देखें नीली वामभुजाकी मालाको स्कन्ध-देशसे अपसारित होते।' किंतु फिर भी पलकें स्थिर न रह सकीं। दस-बारह पलकें अन्तरसे पलकें बरबस खुल गयीं। नीलसुन्दर अपने दृगों में लोरकी लड़ी लिये दो पद दूर खड़े थे.....॥ ८३२॥

'दोनों कर-पल्लवोंसे वक्षःस्थल थामे किशोरी मौन खड़ी देख रही थी....। किशोरीका मस्तक सम्मतिकी मुद्रामें किंचित् कम्पित हो जाता था और तभी नीलसुन्दर उस दिशामें (नन्दभवनकी ओर) एक पदविन्यास कर पाते थे। ऊषा म्लान दृगोंसे इसे निहार रही थी, वनस्थल फूँ-फूँ रो रहा था। जब साँवर गोपेशपुरीके उस कानन-जालमें विलीन हो गये, तब अचानक किशोरीके चरणोंमें गति आयी; उन्मादका प्रबल प्रवाह उसके कण-कणमें परिव्याप्त हो उठा। वह दौड़ी उसी पगदण्डीपर उनके पीछे। आज सहचरियोंने उसे नहीं रोका; वे भी उन्मादिनी हो दौड़ी जा रही थीं उसके पीछे-पीछे। वे केवल इतनी ही सावधान रह सकी थीं- किशोरी गिर न जाय। इतनी ही चेतना उनमें बच रही थी। पगडण्डीपर झूमती हुई वन-वल्लरियाँ धरापर प्रसरित लताएँ किशोरीके चरणोंसे उलझतीं अवश्य; किंतु उसके तनकी ऊष्मासे वे धक् धक् जलने लग जातीं और इसीलिये वे उसे तुरन्त छोड़ देतीं.....पथ मिल जाता किशोरी को !'॥ ८३३,८३४,८३५॥

... दस पलमें ही वह नन्दालयके तोरणद्वारके समीप जा पहुँची-कैसे, कौन जाने, कौन कहे ? नीलसुन्दरकी जननीके बहिर्द्वारपर, तोरणके समीप ही आज वह जाकर प्रथम बार बैठी; भीतर कक्षमें न गयी। सुस्पष्ट थी सबकी आँखों में उसकी उन्मत्त दशा। अलकें उन्मुक्त थीं, ओढ़नी सिरसे धरापर गिर गयी थी, कटिसे ऊपर मात्र कञ्चुकीका आवरण बच रहा था। किसी भाँति सहचरियाँ उसके तनपर आवरणका निर्माण कर सकीं। अब किशोरीमें लज्जाकी, अपने तनकी आत्यन्तिक विस्मृति जो हो चुकी थी...। हृत्तलमें अवश्य ही हुतभुक्की भट्ठीधक् धक् जल रही थी। फिर भी प्राण कैसे बच रहे थे- यह मैं तुम्हें कह न सकूँगी; तुम सुनकर भी समझ न सकोगे।'॥ ८३६,८३७॥

'नन्द-सदनके भीतर कालोचित सभी व्यवस्थाएँ पूरी हो चुकी थीं। साँवरके साथ जानेवाले यात्री प्रस्तुत थे। गोपेश भी खड़े थे। शिशु-सखाओंकी मण्डली भी वहीं विराजित थी। नीलसुन्दर एवं अग्रज के बाहर आनेभरकी देर रह गयी थी। अब भी सदनके अन्तर्देशमें मैया दोनोंके श्रृंगारकी रचना कर रही थी; पर मैयाके हाथ काँपते थे और वह श्रृंगार धरा न पाती थी। वह क्षण-क्षण में भूल जाती थी... क्या, कैसे करना है।.... अवश्य ही वह अत्यन्त सजग थी-एक बूँद भी अश्रु न गिर जाय; मेरे लालका अमङ्गल न हो जाय। नीलमणिके ऐसे गमनके समय मेरे द्वारा किसी अपशकुनका निर्माण न हो जाय। जैसे-तैसे आखिर साँवरको, अग्रजको अपने ही प्राणोंके स्नेहसे सिक्तकर मैया उन्हें बाहर ले आयी। और.... और... नीलसुन्दर भी रथ पर जा बैठे। विस्फारित नयनोंसे किशोरी दूर खड़ी यह दृश्य देख रही थी। उसकी निःस्पन्द पुतलियाँ प्रस्तर-पुतलीकी भाँति बन चुकी थीं।'॥ ८३८,८३९,८४०॥

अचानक फटे हुए, किंतु अत्यन्त ऊँचे स्वरमें वह पुकार उठी- 'देखो ! देखो !! भूकम्प हो रहा है। वे टूट-टूट करके द्रुमजाल गिर रहे हैं! अरे! दौड़ो, सब दौड़ो, इस रथके पहियेमें प्रविष्ट हो जाओ। थाम लो इसे, बचा लो इसे। इसपर एक शाखा-खण्ड भी न गिरने पाये। और यह धरा नाच रही है रे! अरी! क्यों सब, तुम सबकी सब.....!'॥ ८४१॥

एक किञ्चित् वयस्का सहचरीने उसके होठोंपर अपनी अँगुलियाँ रख दीं, पर अब तो सबकी दृष्टि केन्द्रित हो चुकी थी किशोरीपर ही। उसकी गिरामें वेदनाकी ऐसी ऊर्मि परिव्याप्त थी, जिससे एक साथ ही, क्षण बीतते-न-बीतते सबका धैर्य

छिन्न-भिन्न हो गया॥ ८४२॥

....उस महाविषम परिस्थितिको साँवरकी कातर आँखोंने सँभाला! बार-बार साँवरके आकुल दृग-किशोरीकी पुतलियोंसे संनद्ध होते और किशोरीका मस्तक अनुमति देता-सा किंचित् हिल जाता। अश्रुकी दो बूंदे नीलसुन्दरके कपोलोंपर ढलकीं। इस बार किशोरीकी पुतलियाँ झुकी-सी होकर हिल गीं। साथ ही रथका पहिया धीरे-धीरे घड़-घड़का रव करके चल पड़ा....॥ ८४३॥

यह घड़-घड़का रव एक-एकपर, जो साथ न जा सकी थीं, न जा रही थीं, उनपर अपना प्राणहारी प्रभाव व्यक्त करने लगा। कदली-थम्भ-जैसी वे क्रमशः कट-कट करके गिरती जा रही थीं-क्रूर कालका उद्दाम चक्र इस अबला-वनपर चल पड़ा था। जो कम्पित हो-हो करके उस दुर्धर्ष संहार-चक्रसे बच पाती थीं, बच पायीं; उन कमनीय कदलि-श्रेणियोंको, हाय रे! उसने समूल उत्पाटित कर दिया। और सुनो! देखो, वह उन्हें साथ ही लिये जा रहा है......। महाप्रलयका यह महाभीषण झंझावात है रे! देखो-ओह! अभी-अभी तो यह उठा था, कितना दुर्धर्ष वेग कुछ क्षणोंमें ही इसका हो गया है। हाय रे! रथकी गतिसे ही इसका वेग बढ़ रहा है, प्रत्यक्ष देख लो....॥८४४,८४५॥

'इस झंझावातसे आवृत किशोरीकी ओर देखो! देख रहे हो? उसका तन उड़ता जा रहा है, भला ! और आँखोंको झुकाकर देखो! झंझाका प्रकोप अन्तस्तलमें कितना प्रबल है! हाय रे !... मस्तिष्ककी भीषण आँधी क्या परिणाम सृजन करेगी....? हा-हा-हा-हा- हँस रही है किशोरी और झर-झर आँखें बह रही हैं उसकी ! क्या होगा.... ?॥ ८४६॥

तो यह उदुम्बर-तरु आ गया। बस, यहींसे मधुपुरीका पथ मुड़ेगा.... यह

क्या ? साँवर रथपर उठ खड़े हुए। अँय ! अँय !! अँय !!! यह नीली ज्योति सत्य-सत्य दो-सी हो गयी.... एक तो किशोरीके हृद्देशमें समा गयी और दूसरीको लेकर रथ भाग गया, छिप गया....। बस, अन्धकार -और कुछ नहीं....॥ ८४७॥

इस गिरिशृंगकी ओटमें, वनस्थलके सघन जालमें रे, रथ तो दृष्टिपथसे ओझल हो गया। आधा पल भी तो नहीं गया। देखो, किशोरीके मुखसे अट्टहास ! वनका कण-कण प्रतिनादित हो उठा है। देखो, किशोरीकी भुजाएँ ऊपर उठ गयीं; चरणोंमें कितनी विचित्र गति है! हैं! हैं !! मानो अब चरण-विन्यास रास-नृत्यकी भङ्गिमीमें बँधे हों.... तो क्या रासका समय हो गया है ?॥ ८४८॥

'बहिनों! नाचो, नाचो, मैं तुम्हें नाचना सिखाऊँगी। सुनो, प्रीतिकी जय हुई है। बहिनों! मेरी जय बोलो- नहीं-नहीं, उनकी, उनकी, उनकी - जय ! जय !! बोलो जय ! जय !! जय !!! उनकी, उनकी, उनकी.....।'- वन प्रान्तर मुखरित हो उठा किशोरीकी इस ध्वनिसे। यह क्या ? धरा गलने लग गयी! वह देखो, अत्यन्त समीपका वह प्रस्तर किशोरीके तनसे निःसृत ज्वाला का स्पर्श पाकर पिघल गया; अरे! पानी बनकर बह रहा है....॥ ८४९॥

'किशोरी जीवित नहीं रहेगी' सहचरियोंके प्राण हाहाकार कर उठे। किसीभाँति कुछ क्षण प्राणोंका योग बना रहे, इस चिन्तासे सबका मन भावित था। कौन-सी युक्ति हो? कुछ तो करना ही है; अन्यथा किशोरीके प्राण साँवरके सहचर तुरंत बनेंगे ही। और यह विश्व घन-तिमिरसे निरवधि आच्छन्न होकर ही रहेगा.॥ ८५०॥

'अरी बहिन ! चलें, हम सभी वनमें चलें ! बहुत अधिक विलम्ब हो चुका है री! अबतक सुमन चयन भी न हो सका। हम सबोंकी प्रतीक्षामें नीलसुन्दर एकाकी खड़े-खड़े म्लान हो रहे होंगे, बहिन !' - एक सहचरी साहस बटोरकर इतना-सा बोल ही पड़ी, किंतु उसकी छाती फटती चली जा रही थी। दृगोंमें कृत्रिम उल्लासकी मुद्रा लिये, गिरामें कृत्रिम उत्साहकी छाया लिये वह थी अवश्य, पर उसका हृदय टूक-टूक होता जा रहा था। वह बार-बार झकझोर रही थी किशोरीको, जैसे-तैसे उसे भुलावा देनेका प्रयास कर रही थी॥ ८५१,८५२॥

किसी अचिन्त्य प्रेरणासे किशोरीकी वृत्ति केन्द्रित हुई उस सहचरीकी ओर, सहचरीके नयनोंपर। निर्निमेष चक्षुओंसे किशोरी कुछ पलोंतक देखती रही उसे और कदाचित् उसे पहचान भी गयी।

'अरी बहिन ! मैंने एक स्वप्न देखा है। अत्यन्त भयंकर स्वप्न था री! देख, मेरे प्राण काँप रहे हैं। सुन तो, क्या सचमुच अभी ऐसा ही यहाँ होनेवाला है री? तू दुःस्वप्नोंका परिहार जानती है? कोई सा अमोघ परिहार बता दे, बहिन ! मैं अभी-अभी पहले उसका आश्रय लूँगी और तब वनमें जाऊँगी पुष्प-चयन करने, बहिन ! ओह! साँवर, मेरे प्राणनाथ नित्य सुखी रहें, मेरा भले ही जो होना हो, वह हो जाय !'- उन्मादभरे स्वरमें, एक साँसमें किशोरी बड़-बड़ कर गयी॥ ८५३,८५४॥

किंतु रथके पहियोंका चिह्न तो सामने प्रत्यक्ष था। पुनः किशोरीकी आँखें उसपर ही केन्द्रित हो गयीं। सहचरीकी कृत्रिम फुल्लता अब उसे ठग न सकी। धक् धक् भट्टीकी ज्वाला और भी प्रदीप्त हो उठी। अवश्य ही इस बार ज्वाला एक अभिनव बाना धारण किये व्यक्त हो रही थी॥ ८५५॥

'देख, बहिन ! वह कौआ मुझे कुछ संदेश दे रहा है री! मेरे प्राणनाथ नीलसुन्दर सुखपूर्वक वहाँ पहुँच गये हैं- इतना संकेत तो इस काककी वाणीसे निश्चित पा चुकी हूँ, अब आगे तू उससे बात कर ले। पूछ ले, 'उस दनुजराजने अपनी इहलीला संवरण कर ली क्या? और, और, और मेरे प्राणनाथ यहाँके लिये रथपर आसीन हो चुके हैं क्या? रथ चल पड़ा है क्या? वृन्दा-काननसे कितनी दूरपर पुनः लौट आया है...? अथवा कुछ विलम्ब है क्या? हाय रे, ज्वाला.... आग, अन्धकार.... स्वाहा.... अस्फुट उक्ति किशोरीके मुखसे निःसृत हुई अवश्य, किंतु आँखें पथराने लग गयीं। सहचरियोंके हाहाकारसे वनस्थल गुञ्जित हो उठा॥ ८५६॥

इस महाकरुण रवने अन्तर्देशमें बढ़ी हुई वेदनाको पुनः बाहर आनेका दृग दे दिया। अत्यन्त विह्वल किशोरी फूट-फूट करके रोने लग गयी। ऐसी रोयी कि.... वन्य जन्तु सचमुच, उसके साथ हू-हू करके रो रहे थे; विहङ्गम चीत्कार कर रहे थे और क्रमशः शत-सहस्रकी संख्या में भद् भद् करके तरुशाखाओंसे गिरते जा रहे थे- प्राण-शून्य होकर। मानो सम्पूर्ण समीरमें कालकूट विष परिपूरित हो गया हो किशोरीके क्रन्दनका ऐसा भीषण परिणाम चारों ओर व्यक्त हो रहा था। और दूसरे ही क्षण एक साथ ही एक महाघोर रवसे वनस्थल नादित हो उठा एक साथ ही सम्पूर्ण चतुष्पद भी सदाके लिये प्राणशून्य होकर ज्यों-के-त्यों, जहाँ-के-तहाँ ढेर हो गये। तरुराशि सर्वथा निस्पन्द थी; मात्र अवशिष्ट थी किशोरीके, सहचरियोंके क्रन्दनकी ध्वनि...॥ ८५७,८५८,८५९॥

अश्रुके निर्झर में अवगाहन करती हुई किशोरी अग्रसर हुई। अनुसरण कर रही थी वह पहियेकी चिह्नरेखाका। क्षण-क्षणमें रुक जाती। व्यथाका भार अश्नु बनकर जितने परिमाणमें बाहर निःसृत हो जाता, उसके अनुपातसे ही किशोरीके चरणोंमें गतिका संचार होता था॥ ८६०॥

निरन्तर सहचरियोंका जाल उसे सँभाल रहा था। फिर भी किशोरी कितनी बार पछाड़ खाकर गिरी-हाय रे! कौन बतावे ? जब उस पीत तनका गाहक ही चला गया, तब उसे वह क्यों रखती? क्यों उसकी सँभाल करती? उसे तो, उस तनको तो अब निष्प्राण-सी बनी सहचरियोंको ही ढोना था अपनी निस्पन्द पुतलियोंपर, अपने गतिहीन करतलोंपर....॥ ८६१॥

आज पथ न जाने कितना लम्बा हो गया था। उसका अन्त किशोरी पा नहीं रही थी और नीली सरिता उसके नयोंके पथमें आ नहीं रही थी। जहाँ, जिस स्थलपर उस रत्नशैलको गिरिराजको छू-छूकरके नीली प्रवाहिणी बङ्किम पथसे दिशा-परिवर्तन करती थी, वहाँ पहुँचते-पहुँचते मध्याह्न होने जा रहा था।.....॥ ८६२॥

इन इनी-गिनी घड़ियोंमें किशोरीका करुण विलाप कितना, कैसा हृदय-विदारक था और सहचरियोंपर क्या बीती थी, और परस्पर किशोरीमें, सहचरियोंमें क्या, कैसे वाणीके विनियम हुए थे- इसे सुनकर, सुनना आरम्भकरते ही आगेके इतिवृत्तको नहीं सुन सकोगे ! अतएव रहने दो इसे यहीं! और आगे नीली कल-कल-निनादिनीकी लहरोंमें किशोरीने जैसे अवगाहन किया था, उसे ही सुन लो.......। अस्तु,

कल्लोलिनीके उस तटपर, जहाँ गिरिवर अपने चरणोंको प्रक्षालित कर रहा था, किशोरी वहीं पहुँची और अपनी अञ्जलिमें नीले नीरको भर लिया उसने ।.... अपने मस्तकको उस वारिसे अभिषिक्त कर बोल उठी॥ ८६३,८६४॥

'बहिन नीली शैवालिनी ! आज मैं तेरे समीप रोने आयी हूँ। अरी! क्या तू मुझे अपने उरःस्थलकी किंचित् शीतलताका दान करेगी ? मेरे प्राण, तन-सभी जल रहे हैं, बहिन ! तेरे शैत्यका स्पर्शकर ये भी शीतल हो जायँ, क्षणभरके लिये ही....। मैंने तेरा अपराध किया है। मैं गर्वमें भरी थी, बहिन ! उस समय मेरे प्राणनाथ नीलसुन्दर नित्य साथ थे मेरे। उन्हें निरन्तर अपने समीप अनुभवकर इठलाती फिरती थी मैं। उनके नील कलेवरपर एकछत्र अधिकार पाकर मेरी मति बौरी हो गयी थी। कितनी ही बार मैंने तुझे अपने पदोंसे ठुकराया है, बहिन ! देख, मेरे दृगोंमें नीला श्रीमुख भरा था, निरन्तर पूरित था और मैंने तेरी परवाह न की। नीला कर-सरोज मेरे कण्ठको आवृत्त किये रहता था और मैं तुझे गिनती तक न थी -तुच्छातितुच्छ अनुभव करती थी। नीले तनका सौरभ मुझे सतत मत्त बनाये रहता था और मैं कभी तेरे समीप न आयी। एक नीले तरुका आश्रय मुझे मिल गया था; उसपर राशि-राशि अमृत-फल समुदित होते रहते। मैं उन्हीं फलोंका रस पीती रहती और तुझसे कभी मिलने न आयी। देख, नीले मुखका मधुस्यन्दी रव सुना करती और इसीलिये तेरे कल-कलकी उपेक्षा कर देती थी। मुझे नीले अङ्ककी शय्या मिल गयी थी; तेरी गोदीका स्पर्श मुझे सुहाता न था। नीले कराम्बुज मेरे पदोंको सेते रहते, इसीलिये तेरी सेवा मुझे न रुचती थी। वह नीली अलकावलि मेरे श्रमकणका मार्जन करती और मैं तुझे भूल बैठी॥ ८६५,८६६,८६७,८६८॥

किंतु सुन, बहिन ! अब वह मेरी निधि, अप्रतिम नीली निधि मुझसे छिन गयी है; अब मैं भिखारिणी हूँ। कल जो मैं इन सब निकुञ्जवनोंकी सत्य-सत्य महारानी थी, वही आज मैं दीना भिक्षुकी हूँ। मेरा सब गर्व चूर्ण--विचूर्ण हो चुका है। अत्यन्त नगण्या बन चुकी हूँ मैं। और इसीलिये अब आज मैं तेरे शीतल अङ्कमें ही सदाके लिये सोने आयी हूँ, बहिन .....तू मुझे निराश न करना, भला! मुझे ठुकरा मत देना। मुझसे जो तेरा अनादर हुआ है, उसे विस्मृत कर देना। अपने अप्रतिम शीलसे, अपने निस्सीम अनुग्रहसे ही तू मुझे अपने नीले शीतल उरःस्थल पर ठौर दे देना......।'-टूटे कम्पित स्वरमें किशोरी बोलती ही चली गयी॥ ८६९, ८७०॥

'किंतु कालिन्दनन्दिनी बहिन ! उस चिर-विश्रामसे पूर्व, उस शयनसे पूर्व मैं तुझे कुछ और बातें भी कह दूँगी। तू परम दयामयी है, बहिन ! जब तू मुझे आश्रय दान कर देगी, तब उसके उपरान्त मेरी यह सेवा भी अवश्य कर देना। ऐसा मैं क्यों कह रही हूँ बतलाऊँ? मुझसे तो मेरे नीलसुन्दर प्राणनाथ भले ही अलग हो जायँ, किंतु वे तुझे कदापि न छोड़ेंगे, तेरा परित्याग न करेंगे बहिन ! और तू तो वहाँ भी है

ही, जहाँ मेरे प्राणाधार-प्राणसारसर्वस्व हैं, जिस नगरीमें विराजित हैं....!'॥ ८७१॥

'तो सुन, बहिन ! वे अवश्य आयेंगे अपने-आपको तेरे रससे शीतल करने। मैं, मैं तो अभागिन उनके पदपद्मोंकी रजसे, रज-कणिकासे भूषित न हो सकी-ऐसा ही मेरा दुर्दैव था..... किंतु मेरी यह अभिलाषा अब तू ही पूरी कर देना। सुन, बहिन ! मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर उनके चरण-सरोरुहको प्रक्षालित कर देना, भला....॥ ८७२॥

और सुन, कुछ गुप्त हेतुओंसे वह सुख... उनको मैं दान न कर सकी। हाय रे! वे तरसते ही चले गये- मुझसे निराश होकर। वह क्या सुख था, बताऊँ, अब तू सुन ले बहिन ! मैं अपनी ओरसे पुरी उमङ्गका विनियोगकर अपने उरःस्थलपर उन्हें धारण न कर सकी। तू मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर यह सुख उन्हें अवश्य दे देना॥ ८७३॥

और सुन, मैं सोचती ही रह गयी उनका, मेरे प्राणारामका, नीलुसन्दरका अभिषेक करूँ। किंतु हाय रे! आखिर वे चले ही गये और यह अवसर नहीं आया।.... और अब वे तेरे समीप आयेंगे। कृष्ण-कुटिल अलकावली वैसे ही उनके मुखसरोजपर झूलती रहेगी। तो उस क्षण मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर रससिक्त कर देना, अभिषिक्त कर देना उन्हें॥ ८७४॥

और सुन, वे सदा लोलुप बने रहते मेरे मुख-सौरभका आस्वादन करनेके लिये। इस ओर सतत अतिशय लज्जा मुझे घेरे रहती। हाय रे! आजतक उनका यह मनोरथ मैं पूर्ण न कर सकी। नील-कल्लोलिनी बहिन ! मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर तू ही यह भी कर देना॥ ८७५॥

और सुन, निकुञ्जमें जब मैं सोने लगती-उस समय, उस क्षण उनमें लालसा

जगती.... मेरे प्राणोंकी रानी ! तुम किसी ऐसे चित्रका निर्माण करो, जो नित्य नवीन बनता रहे। अङ्कित कर दो उस चित्रको... तो बहिन री! उनका मुख-सरोज ही एकमात्र ऐसा चित्र था- मैं उरः स्थलपर अङ्कित भी कर देती, सत्य, सत्य, बहिन ! अपने उरः स्थलपर लिख ही देती। किंतु उसका दर्शन मैं उन्हें नहीं कराती.....! आह ! आग लगी है मेरे प्राणोंमें.... बहिन री मेरी ! मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर उस चित्रका दर्शन करा देना अब उन्हें !॥ ८७६॥

और सुन, मुझसे वे पूछते-'अप्रतिम सुख-स्पर्श क्या है ?' प्रत्येक निशामें पूछा करते। किंतु मुझे तो निरन्तर यही अनुभव होता-उनके नीले अंगोंका स्पर्श ही परम सुखस्पर्श है। यही अनुभूति निरन्तर बनी रहती थी, किंतु वाणीसे मैं उनके इस प्रश्नका उत्तर न दे पाती। अवश्य ही मेरे तनकी चञ्चलता संकेत कर देती। अब तू ही मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर यह सुस्पष्ट बतला देना॥ ८७७॥

और सुन, रजनी आती। उस समय सदा ही वे मुझसे विनोद करते-'वल्लभे ! बतलाओ, मेरी यह वंशिका क्या गीत गाती है?' मैं उत्तर देती-'अच्छा सुनो! वंशिकाकी स्वर लहरी क्या अर्थ रखती है, क्या गाती है? शिव, हरि, मार, बिन्दु-यही मेरे नामसे सम्पुटित है.....। पर मैं इसका रहस्य न खोलती। अब नीली सरिता बहिन ! मेरे प्राणोंमें अपने प्राण सर्वथा संगमितकर अपने कल-कल रवमें.....इस रहस्यका उद्घाटन कर देना॥ ८७८॥

और सुन, प्रत्येक रजनीमें परस्पर यह प्रश्नोत्तरी अवश्य होती; हाँ केवल भाषा बदली रहती-प्रियतमे ! चित्-पीयूष कहाँ है?' मैं कहती 'प्रियतम ! दो अरुणिम नवल पल्लवोंमें है।' मृदु-कलरवे बहिन ! तू भी ऐसी ही कहना, भला! और मेरे प्राणोंमें अपने प्राण सर्वथा संगमितकर यह अवश्य करना॥ ८७९॥

और सुन, मेरे उरःस्थलपर वे अपने कर-किसलयसे कर्पूर-विलेपन लगाते और उस क्षण उनकी आँखें भी झर-झर झरने लगीं। मैं उस अश्रु-निर्झरके मार्जनमें निरन्तर व्यस्त रहती; उसे पोंछती रहती। तू भी ऐसे ही करना-मेरे प्राणोंमें अपने प्राण सर्वथा संगमितकर समीर करतलके माध्यमसे !॥ ८८०॥

और सुन, प्रातःकी बेलामें वे मेरी आँखोंमें गोदोहनकी मुद्रा धारण किये समा जाते। मेरी पलकें उन्हें ढूँढ़ लेतीं। गोकुल परितृप्त बने, तबतक तू भी उनको ऐसे ही ढँके रहना-मेरे प्राणोंमें अपने प्राण सर्वथा संगमितकर अपने तटके द्रुमजालोंके माध्यमसे, भला...... !॥ ८८१॥

और सुन, दिवसके द्वितीय प्रहरमें वे अरण्यमें निवास करते थे। उस समय मेरा प्यारा भाई, अग्रज श्रीदाम मेरी सहायता करता था- मैं एक पत्र प्रेषित करती। तू भी ऐसे ही करना मेरे प्राणोंमें अपने प्राण सर्वथा संगमितकर नलिनोंपर अङ्कित करके....॥ ८८२॥

और सुन, अपराह्नमें दिवाकरकी अर्चना होती....... मेरी आशा-वल्लरी क्रमशः हरी होने लगती.... मैं तरणिको अर्घ्य देती थी! तू भी अर्घ्यदान अवश्य करना-मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर, लहरोंको उच्छलित करके॥ ८८३॥

और सुन, संध्याकी रश्मियोंमें वे मुझे दीखते काननसे आवासकी ओर आते हुए। और जैसे ही वे मेरे समीप आते-एक कन्दुक उछाल देते; मैं उसे अञ्जलिमें पकड़ लेती....। मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर ऐसे ही आचरण करके उनको प्रसन्न करना, भला !॥ ८८४॥

और सुन, प्रदोष आ जाता। मैं अनुभव करती - वे मुझे ढूँढ़ रहे हैं। और मैं नीले किंवा उज्जवल परिधानसे अपने-आपको सज्जित कर लेती और फिर उनके संकेतकी प्रतीक्षा करती। मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर तू भी ऐसे ही करना। कदापि, स्वप्नमें भी उनको खिन्न न कर देना॥ ८८५॥

और सुन, निशीथमें उनका मेरा मिलन होता और उस समय वे अपने स्वरूप को विस्मृत कर जाते। कहने लग जाते- 'मैं रमणी हूँ, रमणी।' मैं उन्हें चेत कराती। मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर तू भी सतर्क रहना और मेरे जीवन-सर्वस्व नीलसुन्दरको सँभाल लेना, बहिन ! सँभाल लेना, बहिन ! सँभाल लेना, बहिन !॥ ८८६॥

और सुन, उस अपर रात्रिमें भावोंकी आँधी आ जाती। उसके प्रवाहमें उनका मन उड़ता चला जाता दूर, दूर, अत्यन्त दूर! और मैं भी साथ-साथ उड़ती चली जाती। मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर तू भी ऐसे ही उड़ चलना। उनको रसमें निमग्न कर देना-आनन्द-दान करना !॥ ८८७॥

और सुन, ऊषा आती, और हम दोनोंकी पारस्परिक अर्चना आरम्भ होती। बताऊँ, उस समय क्या होता था? सुन, बहिन ! प्राणोंका, तनका भी पूरा-पूरा स्वरूप-विनिमय हो जाता। और फिर क्षणमें ही पहले सी स्थिति बन जाती। मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर ऐसे ही बन-बन करके यह सेवा भी अवश्य कर देना। प्रत्येक ऊषामें ही करती रहना॥ ८८८॥

और सुन, एक-से-एक बड़ी सुन्दरियाँ अपने उरः स्थलमें अनुरागका समुद्र, सँजोये इस काननमें बसती थीं, निवास करती थीं- अपना सर्वस्व उनके चरणनख-चन्द्रोंमें निरन्तर न्योछावर किये रहकर ।! अहो! अरी बहिन मेरी ! मैं उन सबोंको मेरे प्राणनाथसे मिला देती थी-रस-मिलन संघटित कर देती थी। तू भी मेरे प्राणोंमें अपने प्राणोंको सर्वथा संगमितकर मेरे साँवरके सुख-वर्धनका यह व्रत ले ही लेना॥ ८८९॥

और सुन, मेरे इतना, यह सब कहनेका केवल इतना-सा उद्देश्य है, बहिन ! कि जो सेवाएँ मैं न कर सकी और जो सेवाएँ प्रतिदिन किया करती थी-उन सबका भार अब मैं तुझपर ही डाल रही हूँ। तू अनन्तकालतक यह कर्त्तव्य निभा देना बहिन !.......॥ ८९०॥

सुन बहिन ! मैं तुझसे नित्य एक बनी रहकर, तुझसे आत्यन्तिक एकतामें परिनिष्ठित रहकर यह सब देखूँगी ही, किंतु तू उन्हें कदापि मत बतलाना कि मैं तुझसे मिली हुई हूँ। अन्यथा मेरे प्राणरमण नीलुसन्दर, मेरे प्राणवल्लभ साँवर मेरी उस प्रच्छन्न उपस्थितिसे संकुचित हो जायेंगे। अतएव तू सावधान रहना। हरदम पूरी तरह सतर्क रहना- उन्हें मेरी उपस्थितिकी गन्ध-की-गन्ध भी न लगने देना॥ ८९१॥

और बहिन ! यदि तू कोई उपाय कर सके तो अवश्य करना-वे मुझे सदा के लिये सर्वथा सर्वांशमें भूल जायें, मुझे अपने मनसे निकाल फेकें ।... मैं न तो कभी थी... न कभी हूँ और आगे काल के प्रवाह में न कभी होऊँगी-उनकी चित्तवृत्ति ठीक-ठीक ऐसी बन जाय। उनके मनसे मेरा चिन्तन सर्वथा विलुप्त हो जाय..॥ ८९२॥

देख, मेरे प्राणाधिक नीलसुन्दर, मेरे जीवन-सार-सर्वस्व साँवर निरवधि सुखी रहें-मैं केवल यही देखूँ। इसके अतिरिक्त मेरी कदापि कोई अन्य चाह न थी, न है, न होगी ही। मैं सत्य-सत्य कह रही हूँ और तेरे नील उरःस्थलपर यही अंकित भी कर दे रही हूँ, बहिन !'॥ ८९३॥

नीलिमामयी मेरी चिरसंगिनी बहिन ! कोई भले ही न सुने, कोई इसे न देखे, क्षणभरके लिये भी किसीके कर्णपुटोंमें, किसी के नयन-पथमें यह न आये-इससे क्या हुआ? तू तो सुनती ही है, तू तो देख ही रही है। बहिन ! मैं तुझसे भी यह बात न बतलाती, किंतु निरुपाय थी। उनकी सँभालकी चिन्ता जो थी मुझे। अतएव यह सुना बैठी॥ ८९४॥

कल-कल निनादिनी बहिन ! भाव-लहरियोंका कोई इतिवृत्त नहीं होता। भावों की ये ऊर्मियाँ कभी ससीम नहीं होतीं। जो अपने-अपने उर-स्थलमें नीलिमा लिये होते हैं, जिनके प्राण एक साँचे में ढले होते हैं, उन-उनमें उन-उनसे ये संक्रमित होती हैं भला.... और तेरे तो, बहिन ! कण-कण में नीलिमा ही परिपूरित है। इसीलिये आज आकुल हुई मैं अपना उरःस्थल तेरे समीप खोल गयी हूँ-अनावृत कर गयी हूँ। तू मेरी इन बातोंको अपने जीवन में भूल न जाना। देख, जो लहरी विलीन हो गयी, वह तो कदापि, कभी लौटकर नहीं आयेगी, पुनः नहीं स्पन्दित होगी......।'॥ ८९५,८९६॥

किशोरी इतना-सा ही कह सकी और हाथ जोड़कर अपने चरणोंको कलिन्दनन्दिनीके प्रवाहमें रख बैठी। केवल दो सहचरियोंमें उस क्षण उनके प्राणोंकी वृत्ति अवश्य शेष थी। एक तो किशोरीके साथ-साथ पीछे-पीछे बढ़ती जाती और एक पूरी जड़िमासे परिव्याप्त होकर तटपर खड़ी देख रही थी मात्र...। किशोरी नीली प्रवाहिणीके प्रवाहमें अग्रसर हो चली। ज्यों-ज्यों आगे बढ़ती, नीले नीरकी गम्भीरता बढ़ती चली जाती.... कटि-देश डूब गया। क्रमशः किशोरीके वक्षःस्थलको स्पर्शकर धारा प्रसरित हो रही थी....। उल्लास-भरे स्वरमें रह-रह करके वह हँसती और उसके श्रीमुख से इस मधुस्यन्दी गिराका निर्झर प्रसरित हो रहा था-॥ ८९७,८९८॥

'साँवर, साँवर ही तो आगे हैं; साँवर, साँवर ही तो पीछे हैं; साँवर, साँवर ही तो दाहिने है; साँवर, साँवर ही तो वामपार्श्वमें विराजित हैं; साँवर, साँवर ही तो नीचे हैं; साँवर, साँवर ही तो ऊर्ध्वदेश में प्रतिष्ठित हैं; साँवर, साँवर ही तो अन्तस्तल में विराजमान हैं; साँवर, साँवर ही तो बहिर्देश में परिशोभित हो रहे हैं; बस, केवल साँवर ही साँवर, साँवर, साँवर ही सर्वत्र अवस्थित हैं......!'॥ ८९९॥

नीला नीर अब किशोरीके चिबुकको स्पर्श करने लगा। अत्यंत चञ्चल होकर वह रो रहा था। किशोरीके कर-नलिनोंकी अञ्जलि ऊपरकी ओर उठ गयी।.... जो सहचरी उसका अनुसरण कर रही थी, प्रवाहिणीकी चञ्चल धारामें, उसने किशोरीको पीछेसे अपनी भुजाओंमें भर लिया-अन्तिम प्रयास था उस दीनाका किशोरीके प्राण-रक्षणका....॥ ९००॥

नीली लहरें अब किशोरीके मस्तक के ऊपर से प्रसरित थीं, किंतु वह अब भी वैसे ही आगे बढ़ती जा रही थी। अब मात्र दीख रहे थे किशोरी के मणिबन्ध अंश.... और अन्त में किशोरीकी पीली अञ्जलि। और धीरे-धीरे वह अञ्जलि भी नीली लहरोंमें विलीन हो गयी॥ ९०१॥

अचानक वहीं, कालके उस बिन्दुपर ही अघटत-घटना-पटीयसी अचिन्त्य लीला-महाशक्ति योगमायाका आविर्भाव हुआ। गैरिक वसनाकी चिन्मयी नवीन मायाका विस्तार हो उठा और दृश्य बदला। कल-कल-निनादिनीका वह जल एक विपलमें ही घट गया..... और वे महिमामयी किशोरीको अपने अंकमें लिये कलिन्दनन्दिनीके कूलकी ओर आ रही थीं। वह जलनिमग्न सहचरी भी उनके पीछे-पीछे आ रही थी-प्राण-समन्वित होकर॥ ९०२॥

वे असमोर्ध्व-महिमामयी तटके ऊपर उठ आयीं और उनके दृगोंकी बंकिम

दृष्टि गतिशील हो उठी कल्लोलिनीके कूलपर अवस्थित सबपर ही एक साथ। सबके प्राण स्पन्दित हो उठे और सबको लिये वे चल पड़ीं सुन्दरी-सरोवरकी दिशामें। आधे पल में सरोवरका वह कगार भी आ ही गया। उनके चरण-तलका स्पर्श कर रहा था वह॥ ९०३॥

सबको उन्होंने वहीं विराजित कर दिया और वे करुणामयी बोल उठीं-'मेरी पुत्रियों ! धैर्य धारण करो। देखो, इस महादुःखकी रजनीका अवसान होकर ऊषा तुम सबका अभिनन्दन करने आयेगी ही; तुम सब-की-सब साँवरसे मिलकर सुखिनी होओगी ही। अनन्त, अपरिसीम आनन्द सिन्धुमें अनन्तकाल तक के लिये निमग्न होओगी ही, लहराओगी ही।'॥ ९०४॥

जगज्जननी महादेवी अम्बा यह सन्देश दानकर अन्तर्हित हो गयीं......। रत्नमय आवासोंसे भरा हुआ सुन्दरी-सरोवरका वह गाँव भी अदृश्य हो गया। उसके वन-परिसरपर भी एक अभिनव माया फैल गयी। इस क्षणके अनन्तर उस वन-परिसरकी किंचित् भी सत्ता किसीको भी उपलब्ध न होती थी॥ ९०५॥

विरजा-धाराकी घटना सबको अज्ञात थी। उस मान लीला का इतिहास सबके मानस-तलमें अप्रकट था और फिर सम्पूर्ण काननवासी साँवरके वियोगसे व्याकुल थे। यह तो विधिका विधान ही था और इसीलिये ऐसा हुआ॥ ९०७॥

यद्यपि सित रजनी थी वह, फिर भी सर्वत्र घन तिमिरका साम्राज्य था। पुनः यों तो चार प्रहरोंके अंतरालसे दिनकरकी किरणें भी उद्भासित हो उठीं, किन्तु किशोरीकी आँखें निरन्तर मुँदी रहतीं। उसके लिये तो अब सौ वर्ष भी कृष्णनिशाका ही अस्तित्व बच रहा था और उसे निरन्तर रोना था.....॥ ९०८॥

अहो प्राणाधिक! मैं आगेके उन करुण चरित्रोंका वर्णन कैसे करूँ, अब तो मेरे प्राणोंमें प्रतिपल वेदना की लहरें जो उठ रही हैं। किन्तु तुम्हारी अभिलाषा सुनने की है, अतः फिर भी मैं थोड़ा-सा कहती हूँ। मेरे प्राणोंके प्राण! मैं तुम्हींसे निरन्तर प्रेमकी प्राप्ति करती हूँ तथा तुम्हींको उसीका प्रतिदान करती हूँ॥ ९०९॥



''');
        case 'दसवाँ शतक':
          return const _TopicPageContent(
              body:
                  '''वृन्दा-कानन ध्वस्त हो चुका था। एक दिन जहाँ रस की कल्लोलिनी हिलोरें लेती थीं, वहाँ मरुस्थलका झंझावात परिव्याप्त था; सर्वत्र असहाय अनाथोंका चीत्कार, हाहाकार प्रतिध्वनित था। समीर गोपसुन्दरियों के धक् धक् करते प्राणों से जाकर जुड़ता और निरन्तर ज्वालाकी वर्षा करता रहता ! गोपसुन्दरियों के प्राणों के हाहाकारको सह न पाता था स्वयं पवन ही और भाग छूटता था असह्य ऊष्माका वितरण करते हुए। अपने में लिये हुए उस तापको नभमें, जलमें, थलमें भरता रहता। और हाय रे! क्या दशा थी गोपसुन्दरियों के प्राणोंकी ! वे मात्र उनकी देहमें रुद्ध थे- इस आशापर कि हमारे प्राणनाथ आयेंगे तो अवश्य॥ ९१०॥

अब गोपसुन्दरियोंके होठोंपर ताम्बूलकी अरुणिमा न थी। विशुद्ध मधुर प्यारसे भरी चितवनकी वक्रता भी अब उनके नयनों में व्यक्त न हो पाती थी-आधे क्षणके लिये भी। मस्तकसे झूलते कुञ्चित केशोंके स्पन्दनका दर्शन कोई भी न कर पाता था। उनकी सुन्दर वेणीको नाचते देखकर अब कोई भी विथकित न होता था। अलकोंका सौन्दर्य, वेणीका सौन्दर्य सर्वथा तिरोहित हो चुका था। उनके अंगोंपर अब किसी भी आभूषणकी झंकृति न थी और उनके मुखसे वीणा-जैसे स्वरकी मधुरिमासे अब किसीके भी कर्णपुट पूरित न होते थे। और हाय! उनकी देह भी, देहका आवरण भी कभी त्रुटिभरके लिए नीले-पीले परिधानोंकी ज्योति न बिखेरता था॥ ९११॥

अब शिरीष सुमनोंकी मृदुलता उनके अंगोंपर परिलक्षित न होती। अब तो क्षीण अस्थियोंका एक पिञ्जरमात्र धूमिल परिधानोंमें आवृत दीखता था। अविराम अश्रुकी एक पतली धारा उनके कपोलोंपर चलती ही रहती! हाँ, जिस समय व्यथाके भार को न सह सकनेके कारण वे मूच्छित हो जातीं, उस समय क्षणिक अश्रुका तार टूटता-सा दीखता और फिर द्विगुणिता वेगसे आगे चिबुक-परिसरसे होते हुए वक्षःस्थल को आर्द्र करने लगता॥ ९१२॥

अब वृन्दाटवीमें विहंगमोंका कलरव नहीं था। कोकिल अपने कुहू-कुहूके रवसे गाकर रसका विस्तार वन में न करती थी। शुक निरन्तर नीरव ही बना रहता एवं सारिका अपने रसमय पाठसे किसी भी प्राणीके प्राणोंको रसपूरित न करती थी। और तो क्या, निरन्तर वाचाल पिरोइयाँ भी 'अरी गोपी मिल लो' इस सरस संकेतसे लवमात्रके लिये भी अरण्यको गुञ्जित न करतीं। भ्रमर भी विस्मृत कर चुका था, सच-सच, गुन-गुन करना-और एक पुष्पसे दूसरे पुष्पपर जानेकी प्रवृत्ति भी उसकी समाप्त हो चुकी थी। मृतपाय वह उस पुष्पपर जानेकी प्रवृत्ति भी उसकी समाप्त हो चुकी थी। मृतप्राय वह उस पुष्पपर ही ज्यों-का-त्यों आसीन था जिस समय नीलसुन्दर विदा हुए थे, तबसे॥ ९१३॥

काननकी लता-वल्लरियोंमें हरीतिमाका कोई चिह्न न था; द्रुमजालकी शाखाएँ प्राणशून्य-सी बनीं, प्राण संचारक गतिका कोई परिचय न देतीं और वह चिर-परिचित वट-तरु, हाय रे, देखो! पत्र-विरहित हो चुका है! अरे! क्या सचमुच इसने संन्यास ले लिया और मुण्डित योगीकी भाँति वह स्पन्दनशून्य, समाधिस्थ सा खड़ा है? नहीं नहीं देखो! रह-रह करके उससे टप-टप बूंदे चू रही हैं, अंगोंमें गतिके बिना ही रो पड़ता है वह। रह-रह करके सोच रहा है- 'नीलसुन्दरने मुझे ही संकेत-स्थलका अप्रतिम सौभाग्य दिया था। वे इस प्रवाहिणीके तटपर पहले मेरी ही छायामें आकर सब ओर देखते थे और फिर इतनेमें वृषभानुनन्दिनी राधाका वह ज्योतिर्मय कलेवर मुझे दूरसे ही दीख जाता ! क्षण बीतते-न-बीतते दोनों परस्पर भुजपाशमें आबद्ध हो जाते।' इसकी स्मृति ही बूँदें बनकर टप टप झर पड़ती थीं, रह-रह करके उसकी सूखी शाखाओंके अंतरालसे॥ ९१४॥

गिरिवरकी कन्दरामें सूनेपनका साम्राज्य था। सरोरुहोंसे निर्मित शय्या मुरझायी, सूखी थी। हाय रे! ऐसा सन्नाटा, मानो कन्दरा उदास खोई-सी बैठी अपनी आँखें उस सूखी शय्यापर केन्द्रित करके व्यथाके प्रवाहमें डूबी हुई सोच रही हो- 'एक दिन था, मैं सोच रही थी आयेंगे वे दोनों अवश्य और इतनेमें उस चिन्तामें ही दिनकर अस्त हो गये! निशाका अञ्चल मैं प्रत्यक्ष देख रही थी और वे दोनों मेरे प्राणनाथ नीलसुन्दर और वृषभानुनन्दिनी श्रीराधा गरबाँही दिये आये। श्रान्त थे वे दोनों और उन्होंने इस सरोज शय्यापर ही विश्राम किया था।'॥ ९१५॥

काननके सभी सरोवर ऊर्मिहीन हो चुके थे-व्यथाके भारसे उनका हृदय हिम-जैसा होकर जड़िमाके आवरणमें शान्त स्थिर दीखता। उनका वह सुख लुट चुका था। वेदनासे प्रस्तर बना हृदय सोचता रहता- 'नीलसुन्दर आये थे, आते थे; अपनी अञ्जलिमें वे मेरे उरः स्थलका रस भर लेते! आधा रस, जल, वृषभानुनन्दिनी प्राणप्रिया राधाके मुख सरोजमें भर देते और फिर शेषका स्वयं आस्वादन करते।'॥ ९१६॥

अब तुलसी-काननमें-अंशुमालीकी गतिमें उल्लासका कोई चिन्ह न बचा था और वे किरणमाली अब और भी मन्द मन्दतर गतिका ही अपने रथमें संचार करते। बड़ी ही धीमी गति थी उनकी- किन्तु उनका तापमान अपने लिये ही और भी दुस्सह हो गया था। वेदनासे रवि के उरःस्थलका कण-कण परिपूर्ण था। अब नीलसुन्दरकी स्मृति ही उनकी आँखोंमें बची थी। वे भूल गये थे कि इस वनस्थल के उस पार भी उनकी आँखें क्रियाशील हो सकती हैं। रथ आगे बढ़ता अवश्य, किन्तु अब वे सम्मानदानी यशोदाके नीलमणि उन्हें उस वनस्थलमें न दीखते और वे इस विचार में तन्यम हो जाते-'अब मुझे कौन करेगा नीलसुन्दरकी इस रसमयी वाणीसे सिक्त। सुषमाका मैं इस वनस्थलमें कहीं दर्शन जो नहीं कर पा रहा हूँ। हाय रे!' देव-दिवाकर सोचते थे- नन्दनन्दनने ही तो कहा था- नहीं-नहीं, प्रतिदिन ही कहते-प्राणप्रिये प्रियतमे राधे! देखो, अर्घ्यदान करो इन्हें, भानुदेवको। देखो, इनके ही निमित्तसे मैं तुम्हें पा सका हूँ। इन्होंने ही तुम्हें दान किया है मुझे। इस अनमोल निधिका स्वामी मैं बन सका इनके ही निमित्तसे। मैं क्या परिशोध कर सकूँगा इनके इस ऋण का? प्राणाधिके राधे ! जब भी मैं अर्घ्यदान अवसरपर इन्हें देखता हूँ, उस समय मेरा उरः स्थल कृतज्ञताके भारसे झुककर यही संकल्प करता है कि ये सभीके द्वारा चिरकाल अर्चित हों, सभी के द्वारा ये चिरवन्दनीय, समर्हणके अधिकारी रहें। दिवाकरका रथ इसीलिये असह्य वेदनाके भारको ढोनेमें असमर्थ होकर जैसे-तैसे निर्धारित क्रमका अनुसरण करता और धीरे-धीरे चलकर केवल अग्नि बिखेरते अस्तगिरिमें विलीन हो जाता। और जब क्षितिजको सुधांशु छूने आते, तब अत्यन्त करुण अवस्था उनकी भी होती; और शैत्य खोकर वे भी हुतभुक किरणें बिखेरने लग जाते। संयोग की बात थी-इन मयंकने ही तो नीलसुन्दरके द्वारा, व्रजसुन्दरियोंके द्वारा, अत्यधिक आदर पाकर ब्रह्मनिशापर्यन्त सबको अभिषिक्त किया था और विथकित नेत्रोंसे वे उस महारासका दर्शन करते सर्वथा अपने-आपको भूल गये थे। किंतु अब वृन्दा-काननमें राधाकिशोरी उनको दृष्टि उठाकर न देखती थीं और पावक-पुञ्ज जग उठता निशाकरके उरः स्थलमें -'हाय रे, दुर्भाग्य ! कृष्ण-प्राण-प्रियाने मेरी ओर दृष्टि नहीं डाली। अभागा मैं यो ही आया हूँ।' इसीलिये कहीं भी शीतलता की गन्धतक नहीं बची थी मयंककी कायामें॥ ९१७,९१८॥

जगत्प्राण सौरभहीन हो चुका था-प्रवाहित होनेकी शक्ति भी उसके अन्दर न रही थी; निसर्गके नियमों का अनुसरण कर उसमें गति तो आनी अनिवार्य थी ही, पर स्वतः उनकी प्रवृत्तिमें वैराग्य ओत-प्रोत हो चुका था। पहले तो व्रजसुन्दरियोंके श्वास-प्रश्वास उसमें अग्निका सृजन करते ही, फिर उसमें, पवनके मानस-तलमें एक स्मृति जाग उठती - 'आह ! नीलसुन्दरने ही तो हँसकर कहा था-न जाने कितनी बार उनका वह विनोद व्यक्त हुआ था-अपनी प्राणप्रियाको छूकर वे कह बैठते- 'मेरे प्राणोंकी रानी! परम बड़भागी तो यह नभस्वान् है। हृदयेश्वरी राधे! यह तुम्हारे अन्तर्देशको और बाहर भी स्पर्श करता है। यह मेरे सौभाग्य की गरिमा नहीं है कि मैं तुम्हारे अन्तर्देशको छू सकूँ।' किंतु अब इस प्रकार की उन्मुक्त हँसी हँसकर ऐसी रसमयी उक्तिका सृजन करनेवाला रसिक वह नीला शिशु नहीं था और उसके अभावमें वृषभानुनन्दिनीके तनपर पुष्पोंका कोई आभूषण भी न था। वनस्थल भी सुमनोंसे शून्य हो चुका था-कहाँसे आती सौरभकी गन्ध भी समीरमें। एक पुष्प नहीं, वनस्थलके किसी कोनेमें भी और एक भी सुमन नहीं किशोरीके किसी भी श्रीअंगपर॥ ९१९॥

हाय रे, दिन बदला तो कैसा बदला ! एक दिन था, वृषभानुनन्दिनी श्रीराधाके कर्णपुटोंमें साँवर कुछ धीरेसे कह देते और फिर अधरोंपर मुरलिकाको स्थान देकर उसमें न जाने किन-किन गीतोंका सृजन करते। इसकी स्मृति व्योमके कण-कणमें भरी थी- और वह सोचता 'क्या प्रयोजन है मेरी सत्ता का ? क्या अर्थ है अपने अंदर शब्द-गुणको धारण करनेका- मेरे अस्तित्वका ?' पर समझ नहीं पा रहा हूँ कि वह उन्मादिनी ध्वनि, मुरलिकाका वह मनोहर नाद, उसकी वह रसधारा कहाँ चली गयी? इसीलिये गम्भीर चिन्तामें निमग्न सर्वथा असंग रहकर व्योम केवल 'हा-हा-हा-हा' का ही रव सृष्ट कर पाता। पीड़ाके आवेशमें व्योम-आकाश भूल चुका था कि वृन्दा-काननके अतिरिक्त भी कहीं उसकी सत्ता है। अपनी सार्थकताका एकमात्र उपयोग नीलसुन्दरके वृन्दा-कानन-विलासको धारण करनेमें, अवकाश देने में, उनकी रसधाराको शब्दके रूपमें प्रसारित करनेमें ही वह अनुभव करता और उसके अभावमें अनिच्छासे ही उसके द्वारा केवल हाहाकारके रवका ही वितरण होता॥ ९२०॥

काननके अधिवासी जरायुज, उद्भिज्ज, अण्डज प्राणी जो भी थे-वे सब-के-सब मनस्तत्त्वसे शून्य हो चुके थे। उनके समीप मन-नामकी वस्तु ही नहीं रही थीं; उनका मन तो मधुपुरीकी ओर जाते हुए नीलसुन्दरके मुखपर उड़कर, जाकर, वहीं अपनेको विलीनकर, भागता चला गया था मधुपुरीकी ओर। अबतक लौटा नहीं था वह। हाँ! उसकी छाया अवश्य अब भी व्रजसुन्दरियोंकी कायामें बच रही थी। मनकी प्रतिच्छाया अवशिष्ट थी उन सबमें। पर रही थी केवल-केवल रोनेके लिये, हाहाकारके रवको प्राणदान करनेके लिये ही॥ ९२१॥

अरे! मनकी बात दूर, बाहरकी बात अत्यन्त दूर-काननके अधिवासियोंको यही भान न था कि मैं कौन हूँ? सामने क्या वस्तु है? कैसी है? उनका संसार मिट चुका था। व्यवहार शून्यमें समा गया था। वे जीवित हैं, इसका एकमात्र चिह्न उनमें यही अवशिष्ठ था कि अश्रुधारा निःसृत हो रही थी उनके नयन कगारोंसे और आहोंका रव फूटता रहता उनके अधर-पुटोंके अन्तरालसे ! किन्तु छोड़ो अब इस करुण इतिवृत्तको-वाणी इससे आगे बढ़ नहीं सकेगी। अरे! तुम्हारा मेरा अस्तित्व विलीन होकर रहेगा उस व्यथाके महासमुद्रमें, अगर एक पद भी इस दिशाकी ओर रखोगे तो... सुनते हो ?...॥९२२,९२३,९२४॥

इतना ही नहीं, सुनने जाओगे तो फिर इस महाध्वंसकी गाथा ऐसी अधूरी रह जायेगी, जिसे कालके प्रवाहमें कोई संकेत तक दान न कर सकेगा। अमरोंकी अमरता विलीन हो जायेगी और कदाचित् दो-चार वे इस महाध्वंससे बच भी जायें तो उनके लिये अमरता अभिशाप बन जायेगी और केवल-केवल रोनेके लिये उनका, अस्तित्व बच रहकर, जीवन दूभर हो जायेगा। अतएव चलो, यहाँ से, हट चलो, और अब तम्हें उस परदेसीकी, उद्धव नामके उस भक्तकी कुछ गाथा सुना दूँ। ये परदेसी उद्धवजी नीलसुन्दरके नवीन दूत बनकर आये थे। बड़े सुन्दर थे उद्धवजी। नीलसुन्दरके समान ही उनका श्यामवर्ण था और साँवर के सदृश ही वे भेष-भूषासे सज्जित थे। वे तुलसी- काननमें कुछ बात कहने-करने आये थे राधाकिशोरीसे। अन्तर्यामीकी प्रेरणासे एक खिन्ना-दीना गोपसुन्दरी सहसा बोल उठी 'देखो सही, क्या वही-वही पुनः आया है, जो मेरे प्राणधन साँवरको रथपर चढ़ाकर, भगाकर ले गया था?' गोपसुन्दरीके करुण कण्ठ से निःसृत हुआ यह स्वर सम्पूर्ण काननमें क्षण बीतते-न-बीतते प्रतिनादित हो उठा और एक साथ सबकी आँखें खुलीं-बाहरकी ओर वे खोयी-सी देख रही थीं॥ ९२५,९२६॥

सबकी आँखें केन्द्रित हो गयीं उस पथपर, जिस पथसे नीलसुन्दर गये थे। यही प्रातः बेला थी, जब वे इन्हें छोड़कर गये थे-मधूपुरी के लिये विदा हुए थे। उनके सामने उद्धव उन सबको प्रणाम कर चुपचाप हाथ जोड़े खड़े थे-ऐसे, जैसे कोई गूंगा, वाणीकी शक्तिसे सर्वथा विरहित प्राणी खड़ा हो॥ ९२७॥

व्रजसुन्दरियाँ उद्धवकी ओर देख रही थीं और वे देख रहे थे उनकी ओर। वे कुछ भी बोल नहीं पाते थे और दुःखकी महा-अग्निमें धक् धक् जल रह थीं व्रजसुन्दरियाँ। क्षण-क्षण करते चार घड़ियाँ बीत गयीं, तब अचानक उद्धव यह बोल पाये- 'साँवरका मित्र हूँ। नीलसुन्दरने मुझे भेजा है।'॥ ९२८॥

जैसे समान स्वरमें बँधे हुए तन्त्रके तारोंको कोई शिशु सहसा छेड़ बैठे और वे तार झंकृत हो उठें, वैसे ही साँवरका नाम सभी सुन्दरियोंके कर्णपुटोंमें जाकर भावोंकी रागिनी उद्बुद्ध करनेमें हेतु बन गया। उरः स्थलमें विराजित महाभाव-समुद्र नवीन फेनसे फेनिल हो उठा॥ ९२९॥

सुनो ! उद्धवको उन गोपसुन्दरियोंके द्वारा कितना सम्मान मिला-वे साँवरके सहचर जो थे। उन्हें, उद्धवको अभिषिक्त करनेके लिये उन व्रजबालाओंमें स्नेहका कितना, कैसा मनोरम उत्स फूट पड़ा था और उद्धव कैसे उसमें सर्वथा निमग्न हो गय थे-इस गाथाको सुनने के लिये तुम नीलसुन्दरके चरण-सरोरुह में डूब जाओ; फिर वे तुम्हें अपनी आँखोंकी किञ्चित् ज्योतिका दान अवश्य कर देंगे। फिर देख लेना; अन्य उपाय नहीं है, भला....॥ ९३०॥

पर जब तुम इतनी उत्कण्ठा लेकर सुनना ही चाहते हो तो किंचित् सुन लो-यह इतिवृत्त अत्यन्त गोपनीय है, भला ! और भी एक रहस्यकी बात है-समझ सको तो समझ लो-रसकी गति दीपककी लौ के समान है, भला ! निर्वात-स्थलमें तो वह अपने रूपमें परम शोभनीय रहती हैं- स्थिर गतिसे विराजित रहती है, किन्तु ज्यों ही बहिर्देशमें वह लौ लायी गयी कि बस, समीरको छूकर या तो वह स्पन्दित होगी या निर्वापित ही हो जायगी! अस्तु,॥ ९३१॥

सुनो, गोपसुन्दरियोंने विलाप करुण विलापके पूत जलसे उद्धवके चरणोंमें पाद्यके उपचारका आयोजन किया, उनके पद धोये। किंतु इतनेमें अर्चनाकी उत्कण्ठामें मूर्च्छा दौड़ पड़ी-उन गोपसुन्दरियोंकी नित्य दासी थी वह और उसने ही अर्घ्य समर्पण किया। एक साथ ही व्रजबालाएँ चेतनाशून्य होकर उद्धवके चरणोंमें लुढ़क पड़ीं और फिर कहना कठिन है, कितनी देरके अनन्तर उनमें व्रजवामाओंमें सिसकियोंका संचार हुआ मूर्च्छा टूटनेपर। यही उद्धवके प्रति उनका आचमन-निवेदन था। हाय रे! कितना करुण दृश्य था वह ! जो हो, इतना होनेके अनन्तर मर्यादाकी परम्पराके अन्तर्गत होनेवाली अर्चनाका क्रम आरम्भ हो सका। आसन, जल आदिकसे उद्धवका समर्हण हुआ॥ ९३२॥

अर्चना हो चुकी, किंतु अब, कैसे कहूँ? अच्छा, ध्यानसे सुनो-विस्फारित नेत्रोंसे सर्वथा विमूढ़ हुए उद्धव उन व्रजवामाओंकी ओर देख रहे थे और व्रजवामाएँ उद्धवकी प्रदक्षिणा कर रही थीं। इस प्रदक्षिणाके उपचारमें जब पुनः दो घड़ियाँ बीत गयीं; तब कहीं कुशल-क्षेमका प्रश्न करनेके लिये गोपबालाओंमें वाग्वादिनीका संचार हुआ। पर, हाय रे! अत्यंत खिन्न परिधानमें गिरा उनके अधरपुटोंके अन्तरालसे झाँक झाँक करके पीछेकी ओर ही लौट जाती। कितनी बार लौटी और फिर बाहर आनेका साहस बटोर सकी, यह भी कहना कठिन है॥ ९३३॥.

हाँ! धीरे-धीरे भावके समुद्रमें बुदबुदका उन्मेष हुआ और क्रमशः फेनिल हो उठा वह भाव-पयोनिधि। वे उद्धवके पूछनेपर ही सुनाने लग गयीं उद्धवसे- 'देखो ! साँवरके सखा !! ऐसे मेरे साँवर प्राणनाथ इस वनमें निवास करते थे। वे कैसे रहते थे, क्या-क्या करते थे, इस काननमें कैसी रसकी धारा बहती थी, सब तुम पहले हमसे सुन लो।' भाव कैसा होता है और वे गोपसुन्दरियाँ उसमें कैसे विभोर हो गयीं थीं- वाणीकी तूली उसे अंकित नहीं कर सकती। इतना ही विचित्र हो सकेगा कि नीलसुन्दरके कानन-जीवनकी अत्यन्त साधारण-सी घटना, अतिशय नगण्य-सी बात भी वे पगलीकी भाँति उद्धवसे बतलाती जा रही थीं और रोती जाती थीं। साँवरकी दिनचर्याकी प्रत्येक घटना समाप्त होते-न-होते गोपवामाओंका हृदय मानो फटकर बाहरकी ओर बह चलता- इतने वेगसे अश्रु-प्रवाह निःसृत होता॥ ९३४॥

अविराम प्रसरित होकर वेदनाकी यह कल्लोलिनी एक मोड़ लेने चली, और फटी आँखोंसे वे सब-की-सब यन्त्रवत् मौन हो गयीं एक भी कुछ भी न बोल सकी। उस ओर उद्धवके मनमें इनकी अपार दुःखराशिको दूर करनेकी प्रवृत्ति जगी; पर उस प्रवृत्तिमें ज्ञानकी अहंताका पुट था। अरे! एक बड़ी सुन्दर और मोटी ज्ञानकी पेटी अनावृत हो गयी-हँसकर नीलसुन्दरने ही अपने सखाको दी थी वह पेटी। उद्धवका प्रवचन आरम्भ हुआ; बड़ी सुबोध और अभिनव शैली थी ज्ञानोपदेष्टा महाराजकी और धाराप्रवाह रूपसे सप्रमाण नीलसुन्दरकी सर्वत्र व्यापकताका प्रतिपादन हो रहा था। उद्धव महाराजको, सखाजीको जब यह भान होने लगा कि ज्ञानकी इस गरिमा का प्रभाव तो निश्चय अब इनपर होकर रहेगा-तब अनमोल निधिके रूपमें नीलसुन्दरकी इस उक्तिकी, उनके इस संदेश की व्याख्या आरम्भ हुई॥ ९३५॥

'सुनती हो, गोपसुन्दरियों!' ध्यानसे सुनना, भला, ! मैं तुम सबके नयनोंका तारा अवश्य हूँ, किन्तु फिर भी तुमसे दूर क्यों चला आया और दूर आकर यहाँ बस गया हूँ, इसका कारण जानती हो? देखो, मेरा बड़ा ही पुनीत उद्देश्य है-तुम सबका मन, बस, एकमात्र मुझमें ही, केवल-केवल मुझमें ही निरन्तर रमा रहे-इस अभिसंधिसे ही मैं दूर हट आया हूँ, भला!' प्रवचनका पूर्ण विराम भी न आ सका कि श्रोता-मण्डलीके नयन-सरोरुह निमीलित हो गये। एक साथ ही सबने अपनी आँखें बंद कर लीं और क्षण बीतते-न-बीतते उनमें सहसा एक दिव्यातिदिव्य अप्रतिम आवेशका संचार हो उठा॥ ९३६॥

उस ओर वृषभानुनन्दिनी राधा यद्यपि बैठी तो थीं इन सहचरियोंसे आवृत होकर, किंतु बहिर्जगत्का भान उन्हें कथनमात्रको ही था। कोई एक दूत आया है-इतना-सा भान तो अन्तर्यामी की प्रेरणासे ही उन्हें अवश्य हो चुका था; किंतु उनके नयन-सरोज उन्मीलित न हुए, काया स्पन्दिततक नहीं हुई। साथ ही अबतक उद्धव और गोपसुन्दरियोंके बीच क्या चर्चा हुई, क्या ज्ञानोपदेश हुआ-इसे वृषभानुनन्दिनी कितना सुन पायीं अथवा सर्वथा सुन ही न सकीं, यह कौन कहे ?॥ ९३७॥

इतना अतुलित सम्मान उद्धवको तो उनकी (श्रीराधाकी) सहचरियोंके द्वारा ही मिला था-हाँ, सब कुछ हुआ था वृषभानुदुलारीकी संनिधिमें ही। सुन्दरी-सरोवरके दक्षिण तटपर किशोरी उस समय आसीन थीं। उत्तरकी ओर मुख था उनका एवं उनकी समस्त सहचरियोंका। नीलसुन्दरके जानेके अनन्तर ये सब-की-सब निरन्तर यहीं, इस तीरपर ही विराजित थीं और इसीलिये उद्धवको भी उनके दर्शन यहीं हुए॥ ९३८॥

जो हो, दो-एक पल बीतते-न-बीतते महाभाव-समुद्र पहले तो मानकी अप्रतिम ऊर्मियोंसे सज्जित हो गया और फिर दो-चार पल और बीते ही थे कि रागकी उत्ताल तरंगे उन मानकी लहरोंमें मिश्रित हो गयीं- वाणी क्या, लेखनी क्या चित्रण कर सकेगी उसका ! हाँ! किशोरीके अतिरिक्त सबने अपने मुँह फेर लिये उद्धवकी ओरसे और मानो सब-की-सब विस्मृत कर गयीं इस बातको भी कि ये उद्धव, मेरी चर्चाके श्रोता, एक पुरुष हैं तथा अनर्गल रूपसे अपने-अपने जीवनकी कुछ अनुभूतियाँ राधाकिशोरीसे बतलाने लग गयीं। नीलसुन्दरके साथ निभृत निकुंजमें उनकी कुछ बातें जो हुई थीं, उनका कियद् अंश सुस्पष्ट कहने लग गयीं अपनी प्राणरूपिणी बहिन राधासे॥ ९३९॥

यन्त्रित-सी हुई जब एक कुछ कहकर उन्मत्तकी भाँति या तो हँसने लगती या करुण-क्रन्दनके प्रवाहमें बह जाती और उसका हास्य अथवा क्रन्दन थम जाता, तभी दूसरीके मुखसे वह रसमयी चर्चा वेदनाकी आगमें सनी-सी, झुलसी-सी होकर निःसृत होती। राधाकिशोरीको सम्बोधन करके वह कहने लग जाती। सच-सच ऐसा लग रहा था, जैसे कोई भीतरसे उनके द्वारा कह रहा हो, कहलवा रहा हो॥ ९४०॥

'अरी सुनती हैं, अब नीलुसन्दर भूल गये हैं- ताम्बूलकी वह घटना नीलसुन्दरको विस्मृत हो गयी है, बहिन राधे! मैंने तेरे अधरों पर पानकी वह बीड़ी रखी थी। तू उसका आधा अपने मुँखमें दाँतोंके नीचे दबाकर शेषको मेरे अधरोंपर रख बैठी। मैं निर्निमेष नयनोंसे तेरी शोभा निहार रही थी। ताम्बूलका अंश ज्यों-का-त्यों प्रस्तर-प्रतिमाके मुखकी भाँति मेरे अधरोंपर रखा भर था। मैं उसे अपने मुखमें ले भी न सकी थी और अचानक न जाने कहाँसे, कुंजके द्वारसे चुपचाप नीलसुन्दर आये और झटककर, छीनकर मेरे पानके उस अंशको अपने मुखमें रख लिया। उस समय वे जो बोले थे, तुझे स्मरण है, बहिन ! अरी! अक्षरशः बतला रही हूँ-हँसते हुए कह बैठे थे 'ललिते, इस हिस्सेके बदले मैं तेरा निरवधि नित्य क्रीतदास हो गया, भला!' पर बहिन ! दुर्दैव देखो। हम सबका दिन कितना फिर गया, बहिन। आज खरीदा हुआ दास अपनी स्वामिनीके प्रति इस प्रकार ज्ञान-संदेश भेजनेका साहस कर बैठा है-तत्त्वबोधका संदेश-प्रेषक बन बैठा है'- उन्मत्तकी भाँति ललिता हँस रही थी, न जाने कितनी देर हँसती रही॥ ९४१॥

'अरी बहिन, अब नीलसुन्दर क्यों याद करेंगे उस तिथिकी घटनाको, किंतु मैं कैसे भूल जाऊँगी बहिन ! सुन, भाद्रपद कृष्ण प्रतिपदिा थी-संध्याकालीन अरुणिमा प्रतीची क्षितिजसे गवाक्ष रन्ध्रोको स्पर्श कर रही थी और मैं व्यस्त थी तेरी कुन्तल रचनामें। न जाने कहाँ वे, वहीं किस स्थानमें छिपकर विराजित थे। पत्रोंके जालमें ऐसे निलीन थे कि कहीं कोई आभास तक हम दोनों न पा सकी थीं-सहसा वे बोल उठे थे- 'जिसकी ये अलकें हैं और जो रचना कर रही हैं, वे मेरे उरः स्थलमें अनन्तकालतक निवास करें और मैं अनन्तकालतक निर्बाध रूपसे उनके चरण-सरोरुहकी सेवा करूँ।' कहकर वे तुरंत भाग गये। सुस्पष्ट देख तो हम दोनोंने लिया था। हाय रे! कहाँ तो इस प्रकार प्राणोत्कण्ठाके प्रवाहमें प्राणनाथ नीलसुन्दर बह रहे थे-एक दिन वह था-और कहाँ इस प्रकार स्वरूपस्थितिकी अहंताका यह प्रदर्शन है।'

फूट-फूट करके विशाखा उच्च स्वरसे रो रही थी-॥ ९४२॥

'ओह! आज समझ पायी, बहिन ! साँवर कहते कुछ हैं, करते कुछ हैं। दिनका शुभ्र प्रकाश सर्वत्र फैला था- मध्याह्न भी नहीं हुआ था। तूने मुझे लजवन्ती-कुञ्जमें भेजा था उनके समीप... उस, उस, उस, उस, उस अभिसंधिसे और जब मैं लौटने लगी थी, वे बोले थे-ज्यों-की-त्यों उनकी उक्ति यह थी- 'प्राणेश्वरी राधाका, तेरा, तुम दोनोंका ही मै कालके प्रवाहमें अनन्तकालतक ही ऋण-परिशोध कर सकूँ- यह तो असम्भव असम्भव है। हाँ! जबतक मेरा अस्तित्व है, तबतक तुम दोनों जैसे कहोगी, ठीक-ठीक वैसे ही आचरण करके अपने मनको मैं संतोष देता रहूँगा। आधे क्षणके लिये एक सुखका अनुभव करूँगा कि आज आधे क्षणके लिये तुम दोनोंकी सेवा मैं कर सका; तुम दोनों के अनुग्रहसे ही हो सकी। "जय हो वञ्चकशिरोमणि नन्दनन्दनकी !'- उन्मत्त अट्टहास करती हुई चित्रा प्रतीचीकी ओर दौड़ी चली जा रही थी और दस पदपर ही मूच्छित होकर गिर गयी॥ ९४३॥

'तिमिरसे आच्छन्न रजनी थी। नीलसुन्दरके पीत दुकूलसे अचानक मेरे अञ्चलका छोर जा सटा- मैं तेरी उस...... उस सेवाके लिये आयी थी, उस कुञ्जस्थलमें तेरी प्रतीक्षा कर रही थी। वे मेरे चरणोंमें महा-महादीन होकर पड़े थे। मेरी मनुहार कर रहे थे, अञ्जलिसे बारंबार मेरे चरणोंको छू-छू करके। और फिर आगेकी उक्तियाँ, हम दोनोंकी संधिकी नियमावली? क्यों कहूँ! क्यों कहूँ !! क्यों कहूँ !!!'- रोती हुई, विकृत स्वरमें उच्चारण करती हुई इन्दुलेखा अपने सिरको बारंबार हाथसे पीट रही थी॥ ९४४॥

'बहिन राधे! वाग्युद्ध था उस दिन मेरा और नीलसुन्दरका। वे कहते-भ्रमर है, मैं कहती- नहीं, भ्रमरी है। और तू ही तो निर्णयकर्त्री बनी थी बहिन ! वे हार गये थे निर्णयमें, मैं जीत गयी थी और बहिन राधे, उनके हस्तकमलोंको कुन्तलकी लटोंसे बाँधनेका दृश्य कितना मनोरम था, बहिन ! क्या उस समय हम दोनोंने आशा की थी-आशंका की थी अपने इस दुर्दिनकी ? क्या सोच सकी थी, बहिन, तू, अरी मैं- यह बात स्वप्नमें भी री ! कि साँवर इतने झूठे हैं?'.... चम्पकलतिकाकी आँखें पुनः बंद हो गयी थीं और अनर्गल अश्रुप्रवाहसे वह भिगो रही थी अपने कपोलोंको॥ ९४५॥

'हेमन्तकी निशा थी, बहिन ! निशा बीत चुकी थी, हाँ, हाँ, हाँ हेमन्तकी प्रथम निशा थी; षष्ठीकी निशा थी री, बहिन ! कृष्णा षष्ठी थी ! कृष्णा षष्ठी थी !! कृष्णा षष्ठी थी !!! मुझे नींद आ गयी थी बहिन ! और नींदमें सपना देख रही थी, देवीकी अर्चना कर रही थी और वे ठीक उसी क्षण, मैं तो बहिन ! देवीको उपचार समर्पित कर रही थी कि वे चपल होकर उच्च स्वरमें बोल उठे थे- 'मैं तो तुम सबके एक-एकके प्रति इस बन्धनमें बँधा हूँ ही, निरवधि केवल-केवल तुम सबकी ही सेवा करूँ, निरन्तर इस बन्धनके आनन्दमें डूबता-उतराता रहूँ, मेरा यह बन्धन कभी न टूटे !' मैं तत्क्षण जाग उठी थी, बहिन ! और जगकर देखती हूँ, बहिन ! कि उनकी उक्ति सचमुच सर्वथा सर्वांशमें सत्य है। कैसे बताऊँ-बहिन ! सम्भव है मैं जगी न होऊँ, उस समय स्वप्नमें ही सुन रही थी। स्मृति साथ नहीं दे रही है बहिन, स्वप्न था या जाग्रत, सम्भवतः ये रसस्यन्दी स्वर स्वप्नमें ही मैं सुन पायी थी; पर जगनेपर भान हुआ था उनके व्यवहारोंसे कि उनकी यह उक्ति क्रियात्मक रूपसे सत्य ही है, सत्य ही है, सत्य ही है। पर अनुभव कर रही हूँ बहिन, कि सपना सपना ही होता है। सपनेकी घटना नित्य सत्य नहीं होती। इसीसे तो बहिन, वे हम सबके प्रति किये हुए व्रत-बन्धनको तोड़कर चले गये। तो स्वप्न ही था! तो स्वप्न ही था !! स्वप्न ही था !!!-सच कह रही हूँ न ?'... रंग सबसे रो-रो करके पूछती जा रही थी- हँसती जा रही थी और फिर मूच्छित होकर गिर पड़ी॥ ९४६॥

'किशोरी बहिन ! ऋतुराज और शिशिरकी संधि हुई थी, बस, दो दिन पूर्व। मैं अटारीपर खड़ी थी, बहिन - भानुपुरकी अटारी थी, याद है न तुझे, और दिनकर प्रतीची-क्षितिजको छू रहे थे, अब तो तू ही बता सकेगी कि मुझे भ्रम हुआ था अथवा सत्य-सत्य नीलसुन्दर भानुपुरीके उस उद्यानमें पधारे थे और उनका पीत दुकूल बन्धक रख दिया गया था-अब उस बन्धकका क्या अर्थ है- निरर्थक है। अच्छा, जाकर देखूँ, कदाचित् पीत दुकूल भी वहाँ पड़ा हो।'-हाः हाः हाः हाः हाः हाः हाः अट्टहास करती हुई तुङ्ग‌विद्या टकरा-सी गयी किशोरीसे और न जाने कितनी देरके अनन्तर उसके अट्टहासका विराम हुआ॥ ९४७॥

'तो...तो..... तो..... ग्रीष्मका मध्याह्न तप रहा था और मेरा उरःस्थल भी जल रहा था। उनकी तेरे प्रति, बहिन राधे ! जो सुस्पष्ट वञ्चनाएँ हुई थीं, उन्हें प्रत्यक्ष अनुभव कर लपटें निकल रही थीं मेरे उरःस्थलसे ! व्यथामें भरी-सी तू भी मूच्छित-सी हो गयी थी और वे आँखोंमें आँसू भरकर चन्दन-विलेपके माध्यमसे तेरे तापका अपहरण कर रहे थे। मेरे हाथमें तालवृन्त था ! उसपर उन्होंने कुछ अक्षर अङ्कित किये थे। अक्षरोंके अन्तरालमें कितनी अडिग प्रतिज्ञा अङ्कित थी और मुझे प्रसन्न करनेके लिये कितने विशाल औदार्यका परिचय दिया था उन्होंने ! सब-की-सब वे उक्तियाँ, वे अक्षर मिथ्या, मिथ्या, मिथ्या थे; हाँ-हाँ मिथ्या थे। अच्छा-समझ लूँगी, आने दो ! कितनी देर है संध्यामें। आते ही होंगे-नहीं, नहीं, नहीं आयेंगे। खूब रोऊँ, खूब रोऊँ, तिरस्कार जो मैंने किया है उनका...।'-आकाश फट-सा रहा था सुदेवीके करुण-क्रन्दनसे और उन्मत्तकी भाँति वह अपनी अलकोंको नचा रही थी ॥ ९४८ ॥

'उस दिन बहिन ! मैं तेरे अङ्कसे लगकर गम्भीर निद्रामें निमग्न थी। क्या, कैसे हुआ था, इसे तू तनिक स्मरण तो कर ले ! तबसे, तबसे ही तो मैं देख रही हूँ कि मेरे हृत्सरोजपर तू निरन्तर विराजित है और फिर तेरे हृत्सरोरुहके दलोंपर वे नित्य-निरन्तर विराजित हैं। मुझमें तू बसी है, तुझमें वे बसे हैं। फिर भी मैं निरन्तर क्यों रोती हूँ, बहिन ! अच्छा, तू बता - यह मेरी भ्रान्ति है, बहिन ! कि सत्यानुभूति है? मैं तो समझ ही नहीं पा रही हूँ। देख, जब मेरी आँखें तेरे अनर्गल अश्रुप्रवाहकी ओर जाती हैं, तब अनुभव करती हूँ कि हम सबके प्राणवल्लभ नन्दनन्दन अब मधुपुरमें निवास कर रहे हैं.....।'-कहती हुई मञ्जुश्यामा फू-फू करके रोने लगती है और ढलक पड़ती है राधाकिशोरीके दक्षिण स्कन्धपर॥ ९४९॥

'बहिन लाडिली! मेरा स्वर अत्यन्त नीरस था और अब भी यह नीरस ही है; किंतु तेरे मधुमय स्वरकी इसपर प्रतिच्छाया पड़ती थी और यही कारण था कि नीलसुन्दर सदाके लिये मेरे हाथ बिके हुए थे; किंतु वे क्यों चले गये, बहिन ! इसे वे ही जानें....।'- मधुमती अत्यन्त करुण हाहाकारके समुद्रमें डूब गयी॥ ९५०॥

'एक दिन था, जबकि मेरे तनका गोरापन उन्हें इतना आकर्षित करता था कि मुझे देखते ही 'मैं कौन हूँ' इसकी उन्हें विस्मृति हो जाती। बहिन री ! मेरे तनका रंग तो अब भी वैसा ही है और मेरे मनका रंग भी वही है; किंतु बदले हैं वे मेरे नीलसुन्दर ही। कोई अचरजकी बात नहीं, बहिन ! अपना ही प्रतिबिम्ब भी तो अँधेरेमें साथीपनका परित्याग कर देता है।'- र्निमेष नयनोंसे देखती हुई विमला अपने

नयनोंकी धारासे वृषभानुनन्दिनीके जानुदेशको भिगो रही थी॥ ९५१॥

'काले मेघोंकी ओट लेकर कलंकी मयङ्क आया था यहीं, इसी व्रजमें एक रातको। मैं शङ्कित हो गयी थी उन प्रश्नोंके समाधानको लेकर और नीलसुन्दर भानुपुरीकी उस वाटिकामें कहीं निलीन थे। मैं तेरी प्रतीक्षा कर रही थी। यदि मैं नीलसुन्दरका साथ न देती उस रजनीकी क्रीड़ामें तो क्या कर लेते वे मेरा ? पर बहिन री ! तेरे प्रति मेरे अन्तः प्राणोंका मोह मिट जाना असम्भव था; इसलिये, इसलिये, इसलिये, ही मैंने उनकी अभिसंधिकी पूर्णता सम्पन्न की थी-जिसे वे, नहीं री तू-अप्रतिम लाभके रूपमें, अपनी अनन्तकालीन प्रसन्नताके रूपमें चित्रित कर बैठी थी, जिससे अधिक जीवनका कोई लाभही नहीं है, यह रूप दिया था तुमने इस अभिसंधिको ! देख रही है न उस लाभका अब नग्न रूप ? कृष्णवर्णके पुरुष ऐसे ही होते हैं....।' - श्यामला करोंसे वक्षःस्थलपर ऐसे आघात कर रही थी, मानो विदीर्ण कर देना चाहती हो उसे वह॥ ९५२॥

'बहिन राधे ! बड़े ध्यानसे सुनना, भला! नील वारिधरने ही वल्लरीको सींचा था। किंतु जब उसमें पुष्प लगे - सौरभसे भर उठी वह, तब नीलपयोधर चला गया। मैं उस समय यह कह बैठी थी- देखो, नील मेघ! ठगना मत-और प्रत्युत्तरमें श्याम पयोदने कहा था-अरी! क्या प्राणोंका सम्बन्ध भी टूटता है? कैसी विडम्बना है सत्यकी बहिन ! आकाशकी ओर झरती आँखोंसे देख रही थी पालिका और दो पलोंके अनन्तर लुढ़क गयी सरोवर-तटकी उस तृण-राशिपर॥ ९५३॥

'तो वह प्रथम मिलन था, बहिन राधे! हाँ, री प्रथम ही तो था। जैसे-तैसे नीली किरणोंका स्वागत मैं कर पायी। किंतु बहिन ! मेरी आँखें झप-झप जाती थीं। यह शील उनका था कि मेरा, बहिन ! जो मैं विश्वास कर बैठीं, उस भाद्रशुक्ला त्रयोदशीकी षष्ठी-पूजनकी पद्धतिमें!'- कहती हुई भद्राकी आँखें बंद हो गयीं और

बंद आँखोंसे उठकर वह उदीचीकी ओर चली जा रही थी, न जाने कहाँ ?॥ ९५४॥

'चैत्र-पूर्णिमाकी निशा थी बहिन ! उस क्षणसे मेरे चरणोंमें एक कम्पन निरन्तर वर्तमान है। वे स्थिर नहीं रह सकते। तबसे युग-युगान्त बीत गये, एक उल्लासकी किरण मेरे मनमें थी कि मैं तुझे, क्षणभर ही सही; सुखदान कर सकी। पर आज नीलसुन्दरकी यह चेष्टा ? समझ गयी, बहिन ! मेरा भ्रममात्र था....।' ...उन्मत्त होकर धन्या नाच रही थी, किन्तु नूपुर तो अब थे नहीं, जो उसे उद्दीपन दान करते। आँख खोलकर फटी दृष्टिसे देख रही थी अपने गुल्फों की ओर वह॥ ९५५॥

'एक दिन था बहिन लाडिली! मेरी प्रत्येक साँस नीलसुन्दरके उरः स्थलमें चित्रका निर्माण कर देती थी। तू समझ गयी न? पर विधिकी विडम्बना देख-व्रजका नीलचन्द्र भी ज्ञानके दिनकरसे प्रतिभासित हो रहा है; तो तारक-राशियों में आभा कहाँ आयेगी! बहिन ! छोड़, इस प्रपञ्चको...।' सुबुक-सुबुक करके रो रही थी तारकमञ्जरी॥ ९५६॥

'भाद्र सित प्रतिपदाकी वह उक्ति क्या अर्थ रखती है बहिन ! अप्रतिम लावण्य तुझमें ही है री! विश्वमें किसीका विश्वास नहीं बहिन ! जब नीलसुन्दर ही कपटी हैं तो और की क्या बात ?'...... रूपकी आँखें झर रही थीं॥ ९५७॥

'अभी-अभी आये वसन्तकी रजनी थी। कृष्ण नवमीकी निशा थी और केवल मैं पहुँच पायी थी उन्हें लेकर-नीलसुन्दरको लेकर तेरे पास और हास्य-भरे स्वर में उनका यह विनोद था- निर्णय बतलाओ - इस निकुंजस्थलमें किसका मुख सौरभ परिपूरित है ?..... तो..... तो उस विनोदका पर्यवसान यहाँ हुआ राधा बहिन.....।' कहती कहती, उक्ति पूरी होते-न-होते लवंग मूच्छित होकर गिर पड़ी॥

९५८॥

'बहिन राधे! उस दिन विवाद छिड़ा था- पारिजात सुमन सुरभित है या मेरी प्राणेश्वरी राधाकी कुञ्चित अलकें। निर्णय जानना चाहते थे नीलसुन्दर। देख, बहिन ! मैं तेरी ममतासे दबी थी और उनके भुलावेमें आ गयी। हाय रे! उस दिन क्या मुझे पता था कि नीलसुन्दरकी वह अधीनता भ्रमजाल मात्र थी। चन्दनकी आँखोंमें, उर-स्थलमें आग-सी लग रही थी और वह ताली पीट-पीट करके हूँ-हूँ-हूँ-का उच्चारण कर रही थी॥ ९५९॥

'अपना सर्वस्व दान करके मैंने उनकी रुचि रख दी थी, राधा बहिन ! आषाढ़ कृष्ण द्वितीयाका वह दिन मैं कैसे भूलूँगी, बहिन ! आँखोमें आँसू भरकर नीलसुन्दरने कहा था-ऐसे ही निरवधि नेहका निर्वाह मैं भी करूँगा री तेरे प्रति ! परन्तु जिसने यह आशा दी थी, उसने ही इस आशाको सर्वथा चूर्ण-विचूर्ण कर दिया।' कर्पूर की आँखें अनर्गल अश्रुप्रवाहका सृजन करके निमीलित तो हुईं, पर ऐसा लग रहा था कि प्रलयके बिन्दुको छू रही हैं॥ ९६०॥

'आम्र-तरुओंमें मञ्जरियाँ लग चुकी थीं। वे अर्चनकी विधिका निर्णय मुझसे लेना चाहते थे। मैं मौन थी, बहिन राधे! किन्तु वह मेरी मूक मुद्रा ही मेरी अप्रतिम, अनमोल निधि बन गयी थी- धरोहर थी मेरी-उनकी ही वाणीमें री ! किन्तु आज समझ रही हूँ कि यह सब उनका चकमा मात्र था।'- एक बार पुनः रतिमञ्जरीके अट्टहाससे आकाश मानो फटने-सा लग गया; किन्तु पुनः वह भी एैसा मौन हुई, मानो दशवीं दशाको ही स्पर्श कर रही हो॥ ९६१॥

'विजयादशमी थी और उनकी भी आज अद्भुत जय हुई थी उनकी, राधा बहिन ! जो सदा हारे-ही-हारे थे। और उसके अनन्तर अचानक मेरी किंकिंणीकी झंकृति और उसके पश्चात् वह हम सबकी रसमय पराजय थी उनकी-तू ही बतला सकेगी, बहिन राधिके ! यदि पराजय थी उनकी तो विजयका पुरस्कार हमारे भाग्यमें यही था....?' गुण फटी आँखोंसे देख रही थी प्रतीचीकी ओर और उस ओर ही उठकर चल पड़ी; किंतु मूर्च्छाने उसे अंकमें ले लिया॥ ९६२॥

'अनामिकामें अञ्जन भरकर वे तेरे नयन-सरोजोंको अलंकृत करने चले थे, किन्तु नील कर पल्लवोंमें कम्पनका वेग इतना अधिक था कि वे -नीलसुन्दर री! अपनेको सँभाल नहीं पाते थे। बाँयें करको तू सँभाल रही थी और मैं उनके दक्षिण हस्तको थामे हुए थी- उसका बदला - प्रतिदान, यह मिला है हम सबको। बलिहारी है दुर्दिनकी!' केलि कहती-कहती लुढ़क पड़ी किशोरीके चरण-प्रान्तमें॥ ९६३॥

'शत-सहस्त्र निहोरोंसे दबकर मैं साहस बटोर पायी थी, बहिन ! दस पल नाचनेके लिये और उनका नीरज-मुख खिल उठा था मेरा वह नृत्य देखकर। राका-चन्द्रको साक्षी देकर उन्होंने जो मुझे दान दिया था, वह दान इतना ही मोल रखता है-आज मुझे यह भान हुआ। रोना जीवन भर ही है, बहिन !' विलासकी वेदना अन्तर्हृदयमें सीमित न रह सकी; उन्मत्तकी भाँति वह कासारके तृणोंपर अपना सिर पटक रही थी॥ ९६४॥

'बहिन राधे ! तू भूल गयी क्या री! नीलसुन्दर की उस दिन की उक्तिको -मेरी प्रशंसा करते हुए वे अघाते न थे। यहाँ तक बोल बैठे- 'अरी ! कविताका सौंदर्य क्या होता है, आज मैं हृदयंगम कर सका हूँ। तू मेरे कर्णपुटोंमें निरवधि ऐसे ही रसके कलश उड़ेलना, भला!' मैंने तेरी आँखोंके सौन्दर्यका चित्रण किया था। इसका ही पुरस्कार उन्होंने दिया था। मैं फूली नहीं समाती थी। पर मेरे भालके अग्रिम अक्षर इतने मलिन हैं, यह भी प्रत्यक्ष हो गया बहिन!'-वाक्य पूरा होते-न-होते लासिकाके मुखसे फुत्-फुत् करके फेन निःसृत होने लगा और फिर जड़िमामें निमग्न

हो गयी वह॥ ९६५॥

'आषाढ़ शुक्ला त्रयोदशी थी। अपराह्न था, बहिन ! आठों कुञ्जोंमें घूम-घूम करके मैं अत्यंत थक गयी थी। प्रस्वेदसे लथपथ हो गयी थी। समीरमें कोई गति नहीं थी। उस समय हठात् नीलसुन्दर पधारे थे। और मुझसे उनकी कुछ बाते हुई थीं। हाय रे, नीलसुन्दर ! सर्वथा भूल गये उन बातोंको....!'-प्रेममञ्जरीका सम्पूर्ण कलेवर घर्माक्त हो गया। सम्पूर्ण अवयव थर-थर काँपने लग गये। वेदनाके भारसे एक अद्भुत वैवर्ण्यका संचार हो गया उसके सम्पूर्ण अंङ्गोंमें। आँखें बंद हो गयीं उसकी॥ ९६६॥

'देख, मेरा हँसना उन्हें अत्यंत प्रिय था, बहिन ! और तो क्या, बारंबार मेरे चरणोंपर हाथ रखकर वे मेरी मनुहार किया करते थे जरा-सा हँस देनेको। न जाने कितनी भंगिमाएँ नीलसुन्दर रचते थे और मैं आखिर हँस ही पड़ती। किंतु मुझे पता न था कि इस हास्य के अन्तरालमें मेरे क्रन्दन की भूमिका निर्मित हो रही थी।'- उन्मत्त की भाँति कुन्द खिलखिला करके हँस रही थी और मुखरित हो रहा था सरोवर-तीरका कण-कण॥ ९६७॥

'शिशिरका अन्त होने जा रहा था। फाल्गुन शुक्ला षष्ठीकी तिथि थी। अभी मध्यान्ह न हुआ था। पीयूष सरिताका नहीं-नहीं री! पीयूष सागरका उद्वेलन क्षणभरके लिये प्रत्यक्ष हो गया था मेरे सामने। किंतु उस दिन यह भान न हुआ कि उस रस-समुद्रमें भी बड़वानलका निवास रहता है........।'-मञ्जुलीला हाथ नचा-नचा करके सरोवरके जलमें सम्भवतः कूदनेके उद्देश्यसे चली जा रही थी; किंतु जलका स्पर्श होते-न-होते स्थलपर ही मूच्छित होकर गिर पड़ी॥ ९६८॥

'कुछ स्मरण है, राधा बहिन ! तेरे नामसे अभिहित उस सरोवरके वक्षःस्थलपर हंस-से तैरते हुए उस कुञ्जस्थलका। मेरे साथ श्यामा भी थी और नीलसुन्दर मुझसे मिलने आये थे। कहाँ एक दिन उनकी वह अतुल रसिकता और आज यह मेरे कण-कणको जलाती हुई विरसता -दोनों ही चित्र मेरे सामने हैं, बहिन राधे! तू बता, मैं हँसूँ कि रोऊँ-हँसूँ कि रोऊँ-हँसूँ कि रोऊँ।'- प्रत्येक गोपसुन्दरीके सामने ताली-पीट करके मदनसुन्दरी पूछती जा रही थी और मानो कदली-स्तम्भ हो, इस भाँति धरापर गिरकर चेतनाशून्य हो गयी॥ ९६९॥

'वह स्वर्णिम मृदुला वल्लरी नील तरुसे लिपटी है। निसर्गके इस स्वभावका जब द्रुम भी परित्याग नहीं करता, तब नीलुसन्दर तो नित्य अविचल हैं नेह निभानेमें। क्यों जी ?'- मैं पूछ बैठी थी। और नीलसुन्दरने कहा था-'एवमस्तु'। किंतु यह 'एवमस्तु' - श्रावण शुक्ला द्वादशीकी यह प्रतिश्रुति आत्यन्तिक मिथ्या थी। क्यों बहिन राधे! मैं सत्य कह रही हूँ तो....?'-'उफ' की एक वेदनाभरी लहरी-सी मञ्जरी के मुखसे निःसृत हुई और मञ्जरी मानो सचमुच ही समा गयी उस अन्तिम बिन्दुके कक्षमें॥ ९७०॥

'अशोककी शातल छायामें निर्मित उस निकुञ्जकी घटना मैं भूल नहीं पाती, बहिन राधे! तू अवस्थित थी और तेरे पार्श्वमें साँवरी बहिन विराजित थी और तुम दोनोंके बीचमें वे सुशोभित थे। फिर, फिर... फिर.... उस संदर्भमें नीलसुन्दरकी यह उक्ति हुई थी- 'तुम सब तो नित्य सुहागिन हो।' किंतु हाय रे! माँगका यह सिन्दूर आज हुतभुक्-सा जल रहा है। मस्तक फूट गया मेरा-मेरा-सिंदूरकी लपटोंमें दो टूक हो गया।'.... कहती हुई हँस रही थी अशोक॥ ९७१॥

'किशोरी बहिन ! सरोवरकी वह वायव्य कोणवाली कुञ्ज उस दिन कितनी सुषमाका विस्तार कर रही थी। तू बैठी थी और मैं, आये थे वे नीलदेवता। - मेरी मनुहार कर कह बैठे थे-तेरे नामके अनुरूप ही सुधाकी निर्झर है तू। मैं भोली थी, बहिन ! उनकी इस उक्तिको सत्य मान बैठी, मान बैठती थी; और इसीलिये गर्वमें भरकर कितनी बार मधुमयी खरी-खोटी सुना देती। किंतु... किंतु..... किंतु.... हाथीके दाँत खानेके और दिखानेके दो होते ही हैं, बहिन !'.... स्वरभङ्गका ऐसा अद्भुत आवेश सहसा सुधामें हुआ, जिससे उसका आन्तरिक रोष व्यक्त न हो पाता था। वह दो... दो... दि... दि... दि... खा..... खा.... खा... ने.....ने...ने.....ने... के. के. के. हा.... हा... थी..... ..के...... के......हा... हा... थी..... थी..... थी.... कहती हुई प्राचीकी ओर भागी जा रही थी॥ ९७२॥

'बहिन लाडिली! मनोहर अभिनय तू भी नहीं भूल सकेगी- उस दिनवाले अभिनयकी बात, बहिन, जब गँठबन्धनका स्वाँग पूरा करने मैं चली थी और कह बैठी थी कि बिना नेग लिये गँठबन्धन मैं करूँगी नहीं। आँखोंमें झर-झर अश्रुका प्रवाह चल पड़ा और उस प्रवाहमें बहते हुए नीलसुन्दर बोले थे-अरी ! प्रियतमा तो नित्य तेरी हैं ही, अब आज से मैं भी तेरा ही नित्य हूँ। आजतक ऐसा ही लगता था मुझे कि सत्य-सत्य ही उन्होंने उस दिन कहा था, पर हाय रे! खेल खेल ही होता है। खेलकी बात सदा सत्य नहीं रहती. !'... मोदिनीकी आँखें पावसकी धारा बिखेर रही थीं॥ ९७३॥

'तो आँखमिचौनीकी क्रीड़ा थी और बहिन राधे! तू निर्णय दे बैठी कि इस क्रीड़ाके नियमोंमें मैं पक्षपात कैसे कर सकूँगी ? प्राणनाथ नीलसुन्दर तो अस्पृश्य हो गये। सुस्पष्ट में देख चुकी हूँ, माधवीने वल्लरीका स्पर्श कर लिया पहले, पीछे छू सके हैं नीलसुन्दर और फिर, बहिन राधे! दण्डविधानके अन्तर्गत दो पलका वियोग उन्हें इतना अखरा था कि वे विह्वल होकर बोल उठे थे मुझसे-'अरी! तू मेरी रक्षा कर ले और मुझे अनन्तकालतकके लिये खरीद ले।' क्या वह स्वप्नका दृश्य था.....?'..... कहती हुई माधवी अपने धूमिल अञ्चलको फाड़ रही थी॥ ९७४॥

'सम्पूर्ण कुञ्जस्थल मयङ्क-किरणोंसे उद्भासित था। तू बैठी थी, राधा बहिन ! और वे रागपूरित दृष्टिसे निर्निमेष होकर मुझे ही देख रहे थे। सहसा बोल उठे-'अरी! शशि-किरणोंसे भी तेरा स्मित अधिक उज्ज्वल है।' उस क्षण उनकी आँखें झर रही थीं। आज सोचती हूँ, बहिन ! उनका वह वाग्विलास और उनके नीलदृगोंका वह निर्झर- इनका दर्शन मेरा भ्रममात्र था। संगति नहीं लग सकती, बहिन! ऐसे सत्यके विलोपकी।'.... कह-कह करके खिलखिलाकर हँस रही थी शशिरेखा॥ ९७५॥

'बहिन किशोरी ! अवगाहनकी क्रीड़ा होनेके अनन्तर तू सरोवरसे बाहर आकर तटपर खड़ी थी और तेरे कुन्तलसे जलकी बूँदे टप टप झर रही थीं। मैं हँसकर कह बैठी- 'सच है, जिसमें कृष्णता होती है। कालापन होता है, उससे रस चूता ही है।' और तत्क्षण इसके उत्तरमें वे बोल उठे थे' और फिर वह रीता भी हो जाता है।' उनकी वह उक्ति सच थी, आज मैं समझ पायी....।'..... आज हारहीराके कण्ठदेशमें कोई भी माला न थी, कोई हार न था, फिर भी उन्मादिनी-सी होकर अपनी ग्रीवाके हारको मानो वह तोड़ रही हो, इस मुद्रामें दौड़ चली सरोवरकी ओर, किंतु लड़खड़ाकर चार-पाँच पद-विन्यासके अनन्तर ही गिर पड़ी वह॥ ९७६॥

'उस घटनाके अनन्तर शारदीय राका-रजनीके तृतीय प्रहरकी वेला थी। मैं नीलसुन्दरसे कह रही थी- 'सुनते हो, हाँ.... हाँ.... हाँ.... उस इन्द्रनीलमणिको मैं इस जम्बू सरितावाले पुरटकी अँगूठीमें ही जडूँगी, भला! मैं यही मूल्य लूँगी कुन्तल सँवारनेकी सेवाका।' और गद्गद कण्ठसे वे बोले थे- 'ऐसा ही हो! ऐसा ही हो! ऐसा ही हो!' तो उस वाक्यका यही अर्थ था क्या? हाय, नीलसुन्दर ! मिथ्यात्वकी भी एक सीमा होती है।'....टँग गयीं आँखें सुकेशीकी यह उद्‌गार पूर्ण होते-न-होते॥ ९७७॥

'बहिन राधे! उस परिणयका, प्रच्छन्न रूपसे पाणि-ग्रहणका उल्लासमय

आयोजन सम्पन्न हुआ था और मेरी अनादि साध उस समय प्रबुद्ध हो उठी थी कि बस, इस आयोजनका पर्यवसान हो मेरे द्वारा तेरे और उनके नित्य सुख-वर्द्धनमें ही! उन्होंने व्रजके सूर्य-चन्द्रकी साक्षितामें ऐसा ही होनेका वचनदान भी किया था, किंतु आशा सदा सारगर्भित ही हो, यह आवश्यक नहीं !.... वञ्चनाकी भी एक सीमा होती है!' कुन्दवल्लीकी आँखोंमें नीलसुन्दरके प्रति आत्यन्तिक वेदना भरे रोषकी एक रेखा कौंधी और दूसरे ही क्षण वह चेतनाशून्य हो गयी॥९७८॥

'मेरा एक प्रश्न था नीलुसन्दरसे- 'क्यों नीलम ! प्रीतिकी गति कभी सीधी नहीं होती, क्या बात है?' और उत्तरके रूपमें उन्होंने कहा था- 'रसकी वस्तु, तरल वस्तुएँ साँचेके अनुरूप ही ढलती हैं-मैं टेढ़ा हूँ, बङ्किम हूँ और इसलिये मुझे स्पर्श कर प्रीति सदा वक्र ही चलती है।'..... हा....हा...हा....हा कितना महान् ध्रुव सत्य आज मेरे सामने प्रत्यक्ष हो गया'.... सौदामिनीके अट्टहाससे गूँज उठा सरोवर-परिसर !॥ ९७९॥

'... मिलनेसे पहले अमिलनकी वेदना बड़ी भीषण होती है, किंतु मिलनके अनन्तर दो-पनेका भेद ही नहीं रह जाता।'- नीलसुन्दरने ही यह पाठ मुझे पढ़ाया था और मैं भी समझ यही बैठी थी कि जीवनकी धारा ऐसी ही होती है। अब पता लगा कि मेरे नीलदेवताकी यह शिक्षा खरी वञ्चनासे ओत-प्रोत थी।....तो अविराम मुझे रोना ही है।......ऐसा कहते-कहते अश्रुकी दो धाराएँ तीरकी तरह निःसृत हुईं; आगेकी ओर एक वितस्तितक उड़ीं और हंसिनी मानो जीवनके उस पार चली गयी॥ ९८०॥

'मेरी आँखोंमें तन्द्रा-सी थी, किंतु इससे पूर्व ही नीलसुन्दरकी आँखोंमें तन्द्राका दर्शन मैंने किया था! मैं यही चाहती थी कि ये विश्राम कर लें; अत्यन्त श्रमित हो गये हैं। अरी बहिन ! इससे पूर्व मैंने केवल तन्द्राका बहाना किया था री ! तुझसे क्यों छिपाऊँ; क्योंकि तू तो वहाँ थी ही। अब तू स्मरण कर ले, राधा बहिन ! उनकी उक्तिका। तू ही बता, क्या वह उक्ति कृत्रिम थी?'...... सुलोचनाकी आँखें अन्तर्वेदनाके भारको सह न सकीं, मुँदीं, पर ऐसा लगा, मानो अब वे न खुलेंगी कभी भी॥ ९८१॥

'उनकी आँखें भर-भर आती थीं। सम्पूर्ण अङ्गोंमें पुलकका उन्मेष हो गया था, वे मृगमदसे चित्र लिखते और उन्हें मिटा देते! क्यों मिटाते, इसे वे ही जानें; किंतु हुआ यह कि एक अङ्गके चित्रणमें ही निशाका विराम हो गया। प्राची क्षितिजमें ऊषा झाँकने लग गयी, किंतु नीलसुन्दरके दृगोंका उल्लास क्षीण न हुआ था! बहिन किशोरी! क्या यह दम्भका उल्लास था? प्राण फटते जा रहे हैं, बहिन !.... मञ्जुलाका कण्ठ रुद्ध हो गया और मानो महाप्रलयकी छाया उसके मुखपर अङ्कित हो गयी थी॥ ९८२॥

'नीलमयङ्क तेरी ग्रीवामें सुमनोंसे निर्मित पदकका आभूषण पहना रहे थे। मैं सर्वथा अपने-आपको भूल गयी, बहिन ! और उस पदकमें ही तन्मय हो गयी और जब अपनी इस काया में लौटी थी तो मध्याह्न हो गया था। तू तो प्रत्यक्ष देख ही रही थी, बहिन ! उस समय मेरे प्रति उनके प्यारदानको भी तू स्पष्ट देख ही रही थी। इसे विशुद्ध ठगीके अतिरिक्त और क्या कहूँ, बहिन !'..... पूरा-पूरा भावोद्गार बाहर भी न आ सका था कि चारुशीलाके नासापुटोंके समीरमें स्पन्दन न रहा। आगे स्पन्दन होगा या नहीं, कौन जाने॥ ९८३॥

''भाद्र शुक्ला षष्ठीकी निशा थी, बहिन ! नीले वनदेवने मुझसे यह कहा था-'अरी तडित्का स्वभाव तो तुझमें है ही, चपला तू है ही और इस ओर नील वारिधरके वर्णका साम्य मेरे तनमें है- अम्भोदके उरः स्थलमें ही तो तडित् निवास करती है। तेरा निकेतन तो मेरे कण-कणके अन्तर्देशमें ही है। तू मुझमें ही निलीन रहना। जब मैं तुझे व्यक्त करूँ, तभी प्रकाश-पुञ्जका वितरण करना। अपने नित्य निवासगृहको भूल गयी क्या री!' कितना मधुमय विनोद था उनका वह, बहिन ! हाय रे! मैं तो वैसी-की-वैसी हूँ, पर नील पयोदका ही स्वभाव बदला।'.... इतना ही कह सकी विद्युन्माला। उसका स्वर मन्द-मन्दतर होता जा रहा था। वह कालके उस काले बिन्दुकी ओर अग्रसर हो रही थी॥ ९८४॥

'बहिन राधे! साँझ हो रही थी। वे तेरे पदमें महावर लगा रहे थे, तेरे पदतलके सरोरुह-चिन्हमें उनका और मेरा, दोनोंका मन सहसा निमग्न हो गया था। जब हम दोनों पुनः प्रकृतिस्थ हुए थे, तब मयङ्क क्षितिजके उस पार जा चुका था और दिनकर झाँकने लग गया था। तेरे प्रति, मेरे प्रति उनके प्यारका वह निदर्शन, वह... वह.... वह.... वह निदर्शन तू भी न भूलेगी, बहिन ! और मैं भी नहीं भूलूँगी। एक दिन वह भी था और यह आजका दिन भी है।'... सरोजिनीकी वाणी रुद्ध हो गयी-सुस्पष्ट था, प्राणोंके विनिमयकी. वेला उसे आत्मसात् करती जा रही थी॥ ९८५॥

'अबतक कोई क्या समझ पायी थी, बहिन लाडिली! कि ऐसा क्यों होता था? हां, हाँ, हाँ, हाँ, हाँ, वही बात ! जब भी तुझे जँभाई आती तो नीलसुन्दरके दृग मीलित हो जाते; किंतु मैं उनके पीछे पड़ गयी थी और मेरा लाड़ रखते हुए उन्होंने अपने मनमें उस समय उत्थित होने वाले सरस भावोंका एक चित्र अङ्कित किया था! किंतु वह कोरी विडम्बना मात्र थी बहिन ! भावनाकी! सत्य होती तो वे क्यों छोड़कर जाते हम सबको।' कहते-कहते मदनालसाकी आँखें निमीलित हुईं और अब वह मानो चिरनिद्राके अङ्कमें विश्राम कर रही थी॥ ९८६॥

'रजनीके अवसान होने में अब मात्र दो घड़ीकी प्रतीक्षा थी। तू, वे, मैं-तीनों बैठे थे। आलस्यके भारसे सहसा तू दब-सी गयी और पङ्कजदलोंके पर्यंकपर लेट गयी। हम दोनोंकी दृष्टि-मेरी और उनकी दृष्टि बहिन ! तेरे वाम पदतलकी ऊध्वरेखापर केन्द्रित हो गयी और वे मुझे मधुस्यन्दी स्वरमें उस चिन्हका परम शुभ फल बतलाने लगे - उसकी महिमाका निर्देश करते-करते वे थक नहीं रहे थे। तेरे विश्राममें व्याघात न हो, इसलिये वे मेरे कानोंसे सटकर ही बतला रहे थे। तो बहिन, क्या वे उक्तियाँ भी सर्वथा मिथ्या हैं?' ......इतने ही स्वर निःसृत हो सके इन्दिराके अधरपुटोंके अन्तरालसे; और फिर कपोलोंपरकी अश्रुधारा धीमी पड़ गयी। विलयके वितानकी छाया उसके अङ्गोंपर सुस्पष्ट दीख रही थी ॥ ९८७ ॥

'किशोरी बहिन ! हेमन्तकी शुक्ला अष्टमी थी प्रथम मासवाली। हिमकर निकुञ्जवल्लरीकी ओटमें तेरा नमन कर रहा था और अनुमति ले रहा था। साथ ही तुझे एक रसमय संदेशका दान कर रहा था। उस समय नीलसुन्दर जो सहसा मुझे कह बैठे थे, उसे मैं कैसे भूलूँ, बहिन।' .... बुझते हुए दीपककी भाँति मनोहराके नयनोंमें ज्योतिकी एक रेखा-सी आयी और तत्क्षण वह विलीन हो गयी, मानो घनतिमिरमें सदाके लिये॥ ९८८॥

'अरी बहिन लाडिली! शुक्ला नवमी थी री वैशाखकी! गम्भीर निद्रामें हम सभी निमग्न थीं और साथ ही एक स्वप्न भी हम सबने - एक ही स्वप्न, भला-देखा था। नीलसुन्दरने ही हमें उस क्षण जगाया था और वे क्या बोले थे, तुझे बतला चुकी हूँ, बहिन!'.॥ ९८९॥

कैसे क्या हुआ, कहना कठिन है; पर साँवरके दूत उद्धवको यह प्रतीत हुआ कि एक साथ शत-सहस्त्र कण्ठोंसे उपर्युक्त रव निःसृत हो रहा है और फिर सहसा इतने कण्ठोंके एक समान अट्टहाससे सरोवर-परिसर मुखरित हो उठा-क्षणभरके लिये, किंतु दूसरे ही क्षण सारा वनस्थल परिव्याप्त हो गया महाप्रलयकी भीषण नीरवतासे- कितने क्षण कौन बताये ? इतनेमें अचानक आगका एक झंझावात-सा आया, मानो उस महाविलयकी पुनरावृत्ति हो। पर उस महाध्वंसके परिणाममें अन्तर था। नीरवता फिरसे मुखरित हो उठी। अचानक, एक साथ ही वृषभानुनन्दिनी राधाकिशोरीकी सम्पूर्ण सहचरियाँ ऐसे करुण स्वरसे रो उठीं कि उद्धवकी बात दूर, सरोवरका सम्पूर्ण नीर विकल हो उठा; सचमुच-सचमुच उसमें बाढ़ आ गयी और क्षण बीतते-न-बीतते वह चारों कूलोंको प्लावितकर, सरोवरकी सीमा का उल्लंघनकर, उन गोपसुन्दरियोंको कटितक निमग्नकर, वनस्थलके तरुजालोंसे टकराने लग गया। वनस्थलीकी सम्पूर्ण द्रुमावली, वल्लरियाँ व्याकुल होकर झूमने लगीं। इतना वेग था सरोवरके उस नीरमें। सह न सका था वह गोपसुन्दरियोंके करुण-क्रन्दनको। इतना विकल-विह्वल था इस समय वह॥ ९९०॥

और इसी प्रवाहमें उद्धवका सारा मल धुल गया। 'मैं परमतत्त्वका ज्ञाता हूँ, साँवरका किंकर हूँ'- यह अभिमान लेकर जो वे आये थे, यह अभिमान भी उसी प्लावनमें बहकर न जाने कहाँसे कहाँ जाकर इतिके बिन्दुमें विलीन हो गया। नीलसुन्दरसे जुड़ा हुआ जीवन कैसा होता है, होता रहता है, कैसे- से-कैसे हो जाता है-आज वे प्रत्यक्ष उसका तनिक-सा निदर्शन देख सके किशोरीकी सहचरियोंके जीवनमें॥ ९९१॥

उद्धवके अन्तरका द्वार खुल गया और आज उन्हें सच्चा प्रकाश मिला। उनकी आँखोंपर अनादि तिमिरकी एक छाया थी; वह आज, आज जाकर अपसारित हुई। नीलसुन्दर क्या वस्तु हैं, राधाकिशोरी क्या वस्तु हैं, रसतत्त्व क्या है-जिस पथसे चलकर कोई भी इसका यत्किंचित् आभास पा सका है, वही पथ आज उद्धवको भी प्राप्त हो गया॥ ९९२॥

अबतक भानुकिशोरी पुतली-सी निस्पन्द बनी बैठी थीं। उनके हृत्तलकी भावनाएँ विगलित होकर अविराम अश्रुके रूपमें परिणत होकर आँखोंके पथसे बाहर आती रही थीं और एक अश्रुकी अखण्ड रेखा निर्मित थी उनके कपोलोंपर। उद्धवकी आँखोंमें भानुनन्दिनीका वह रूप समा गया। निर्निमेष नेत्रोंसे वे देख रहे थे राधाकिशोरीकी उस अप्रतिम भावमयी धाराको -नयनोंके प्रवाहको। उनके उरःस्थलमें दो-एक बूँद जाते-न-जाते वे एक विचित्र अनुभूतिमें निमग्न हो गये॥ ९९३॥

उन्हें अनुभव हुआ, मानो सहसा विद्युत्-सी-बिजली-सी काँध गयी। राधाकिशोरी जो नीला लहँगा धारण किये हुए थीं, उसके अन्तरालमें ही वह विद्युत् प्रकाशपुञ्ज उन्हें दीख रहा था और वे अनुभव करने लगे कि सच-सच यह तो नीलसुन्दरका पीत दुकूल नीले लहँगेमें झलमल-झलमल कर रहा है। अरे! यह क्या! इस पीले अम्बरमें, पीत दुकूलमें, फिर देखो, राधाकिशोरीकी नीली साड़ी लहरा रही है। उफ् ! क्या हो रहा है- मैं क्या देख रहा हूँ-फिर इसी, इसी नीली साड़ीमें नीलसुन्दरका पीत परिधान सर्वथा सर्वांशमें ही स्यूत हो रहा है॥ ९९४॥

मानो नीले-पीले वस्त्रोंका एक क्रम निर्धारित कर दिया गया हो। नीलेमें पीला, पीलोमें नीला, फिर नीलेमें पीला ऐसे तह-पर-तह सजे हुए अगणित वस्त्रोंका अम्बार लगा हुआ हो। कहीं लहँगेकी आकृतिमें कोई असम्भावित दृश्य नहीं है-उतनी-की-उतनी आकृति है; पीत दुकूलकी आकृति भी ज्यों-की-त्यों है, किंतु एक-दूसरेके अन्तरालमें ज्यों-के-त्यों अनुस्यूत अनन्त, नील-पीत परिधान-खण्डोंमें वह अम्बार सुशोभित हो रहा है। 'हैं, हैं, यह क्या? यह देखो राधाकिशोरीके पद पृष्ठोंकी मृदुल अँगुलियोंकी स्वर्णिम छविमें नीला प्रकाशपुञ्ज भरा है। अरे! नीलमेघ नीलसुन्दर भरे हैं और फिर देखो, उन नीलमेघमें पुनः पीली लहरें उठ रही हैं....।'॥ ९९५॥

उद्धवकी आँखें जब राधाकिशोरीके कटिदेशसे ऊपर जातीं तो उन्हें प्रत्यक्ष अनुभव होता-राधाकिशोरीमें नीलसुन्दर परिपूरित हैं-खड़े हैं और फिर ओहो ! नीलसुन्दरमें राधाकिशोरी परिपूरित हैं- खड़ी हैं-बैठी हैं। जैसे-जैसे उद्धवकी आँखें भीतरकी ओर प्रविष्ट होतीं, उन्हें अनुभव हो रहा था- क्रमशः असंख्य नीलसुन्दर हैं और उन असंख्य नीलसुन्दरके अन्तरालमें असंख्य वृषभानुकिशोरी विराजित थीं॥ ९९६॥

इस प्रकार देखते-देखते उद्धव भ्रमित हो गये कि 'मेरे सामने नीलसुन्दर विराजित हैं या राधाकिशोरी विराजित हैं या दोनों विराजित है अथवा क्या है?' विवेक समाप्त हो गया, बुद्धि कुण्ठित हो गयी उद्धवकी। अजब-सी दशा थी और व्याकुल होकर वे पुकार उठे- 'नीलसुन्दरके प्राणोंकी अधिदेवी हे राधाकिशोरी ! हे देवीके देव नीलसुन्दर !! पाहि, पाहि, पाहि.......' उद्धव इससे अधिक देख न सके; उन्होंने अपनी आँखें बन्द कर लीं॥ ९९७॥

नयन निमीलित होते ही कर्णपुटोंमें मधुरतम वंशीकी ध्वनि, वंशीकी मधुस्यंदी तान उद्धवको सुन पड़ने लग गयी। उन्हें ऐसा प्रतीत हो रहा था, जैसे वह रव क्रमशः निकट निकटतर होता जा रहा है। वंशीकी स्वर लहरीमें ऐसी मादकता पूरित थी, जिसका अनुभव उन्हें कभी कहीं अनादिकालसे न हो सका था। उद्धव मोहित होकर झूमने लग गये।.... बरबस उद्धवकी बंद आँखें खुल गयीं और दीख पड़ा अप्रतिम सुंदर एक वनस्थल। संध्या हो रही है, नीलसुन्दर नन्दनन्दन गो-चारण करके धीरे-धीरे वनसे लौट रहे हैं-अत्यन्त समीप आ गये हैं, मेरे पास आ गये हैं। अब तो जहाँ वे अवस्थित हैं, वहाँ उनमें और मुझमें केवल दो हाथकी दूरी रह गयी है। मैं पथके एक किनारे खड़ा हूँ। अरे! नन्दनन्दन हँस रहे हैं। आ हा! वे मधुमय स्वरमें कह रहे हैं- 'अरे भैया! मेरा घर तो यही, यह वृन्दावन ही है।'॥ ९९८-९९९॥

'अरे देखो, उद्धव भैया! देखो, मेरी मैया वहाँ, वहाँ उस नन्दद्वारपर, नन्दभवनमें हाथमें नीराजन लिये आकुल प्राणोंसे मेरी प्रतीक्षा कर रही हैं, सोच रही हैं कि मेरा लाल नीलमणि आ ही रहा होगा। देखो, देखो, दृष्टि उठाकर उस ओर देखो! सुनो उद्धव ! बस, केवल तीन पहर ही बीते हैं-अपनी गायें लिये मैं अरण्यमें घूम रहा था और मेरी मैया व्यर्थमें चिन्ता कर रही हैं मेरे लिये। देर हो गयी है कुछ, रे भैया! आनेमें आज मुझे।'॥ १०००॥

क्षण बीतते-न-बीतते उद्धवको फिर यह अनुभूति हुई- कृष्णा-प्रवाहिणी-कलिन्दनन्दिनी अहा ! कैसी हिलोरें ले रही हैं-और दोनों तटोंपर निकुञ्ज सदनोंकी पंक्तियाँ लगी हैं। ये देखो, राधाकिशोरीको गरबाँही दिये नीलसुन्दर निकुञ्जकी ओटसे अब बाहर आ रहे हैं। किशोरीके दक्षिण स्कन्धपर उनके हस्त-कमल विराजित हैं। राधाकिशोरीसे वे कुछ कह रहे हैं। आँखोंसे प्यार झर रहा है। नीलसुन्दर विह्वल से हो रहे हैं...॥ १००१॥

'यह देखो, दोनों हँसते हुए चले जा रहे हैं उस ओर, उस निकुञ्जश्रेणीकी ओर।' आँखोंके आगे नवीन-से-नवीन अप्रतिम सुन्दर मनोहर दृश्योंका ताँता लग रहा था। उद्धव आनन्दमें उन्मत्त होते जा रहे थे। कौन बतावे, कैसे बतावे कि उद्धवने क्या-क्या देखा था। इतना ही कहना सम्भव है-नीलसुन्दर वृन्दा-काननसे कहीं बाहर नहीं गये हैं और राधाकिशोरीके साथ उनकी नित्य क्रीड़ा अविराम रूपसे चल रही है। यह प्रत्यक्ष अनुभूति उद्धवके प्राणोंको निरन्तर उन्मत्त बना रही थी और इसी प्रवाहमें मानो वे अपने आपतकको सर्वथा खो बैठे। कितने दिन, कितने मास, कितने संवत्सर, कितने युग-युगान्तके लिये यह अनुभूति उद्धवके मानस-तलमें लहराती रही-कालमानसे इसका निर्णय असम्भव है। उद्धवको सर्वथा विस्मृति हो गयी थी, वे कितने दिन पहले वृन्दा-काननमें आये थे। आनन्दकी लहरें उन्हें घेरे रहतीं और वे उसमें डूबे रहते-बोलते वे न थे। राधाकिशोरीकी सहचरियाँ जो कुछ उन्हें सुनातीं, वे सुनते रहते किंतु किशोरीके सम्मुख जाते ही वे रोने लग जाते थे- अविराम रोते ही रहते, जबतक किशोरी दीखती रहतीं॥ १००२,१००३॥

अस्तु, नीलसुन्दरका संकल्प जाग्रत् हुआ और अचानक उद्धवको यह भान हुआ कि वे यहाँ किस उद्देश्यसे आये थे और कब आये थे और इस प्रतीतिके साथ ही नीलसुन्दर निरन्तर यहीं रहते हैं, यह अनुभूति भी एक अभिनव आवरणमें विलीन हो गयी। उन्हें अब यह दीख रहा था-वेदनाका समुद्र हिलोरें ले रहा है, जिसमें गोपसुन्दरियाँ डूब रही हैं और वे तटपर खड़े हैं उस सागरके, एकटक देख रहे हैं- मात्र इतनी ही स्मृति रह गयी उद्धवमें॥ १००४॥

उद्धवके प्राण रोने लग गये। साथ ही दैन्यके स्रोत फूट पड़े उनमें ऐसे मानो उनके अस्तित्वको ही वे विलुप्त कर देंगे। धैर्य छूट रहा था उनका और वे सोचते जा रहे थे- 'हाय रे ! हाय रे !! मैं सर्वथा-सर्वथा अनधिकारी हूँ इन गोपसुन्दरियोंके दर्शन करनेका भी। स्वप्रमें भी इनके दर्शन मुझे हों-असम्भव ! किंतु मेरे साँवर मौखिक शरणागतिसे भी रीझ जाते हैं, ढर जाते हैं। मैंने उनकी केवल वाणीभरकी शरण ली हैं; इसीलिये वे मुझपर प्रसन्न हो गये थे और उन्होंने दया करके मुझे ही यहाँ भेजा॥ १००५॥

'पर अब तो मुझे यहाँसे जाना है। मेरे जैसा व्यक्ति राधाकिशोरीके चरण-सरोरुहोंकी छायामें कैसे रह सकता है। हाँ, यदि मैं अपने उरःस्थलको अविराम अनंत कालतकके लिये आँसूसे सींचता रहूँ, कभी मेरे अश्रुका विराम हो ही नहीं, तब कहीं जाकर वृन्दा-काननमें रहनेकी वह मेरी अभिलाषा, अभिलाषा-वल्लरीका बीज अंकुरित हो॥ १००६॥

'व्यथाका भार मैं ढो नहीं सकूँगा- केवल इस व्यथाका कि मुझे राधाकिशोरीके दर्शन तो हो गये, किंतु मेरे भाग्य ऐसे नहीं हुए कि मैं किशोरीका स्वर सुन सकूँ। कैसा मधुस्यन्दी स्वर होगा किशोरीका! मेरे जैसे महा-अभिमानीको इनसे विनय करनेका भी अधिकार नहीं है- सत्य-सत्य ही में अनुभव कर रहा हूँ। मैं इस पावन धराका स्पर्श कर सका, किशोरीके दर्शनसे मेरी आँखें सफल हुई-इतना ही बहुत-बहुत सौभाग्य मेरा है..। 'किंतु जीवित तो रह नहीं सकूँगा मैं, यदि किशोरीकी वाणी मैंने नहीं सुनी तो। कदाचित् एक-दो शब्द भी सुन लेता तो अनन्तकालतक मैं जीवित रह जाता और मुझे जीवनका पाथेय मिल जाता। साथ ही मेरे समान सौभाग्यशाली विश्वमें और कोई भी न होता।'॥ १००७॥

उद्धवकी आँखोंसे बूँदे बरस रही थीं और अवनी गीली हो रही थी। अत्यन्त अधीर हो उठे थे वे। राधाकिशोरीसे कुछ भी कहनेका अधिकारी नहीं, नहीं, नहीं हूँ मैं! किंतु साँवरसे तो कह ही सकता हूँ। जिन्होंने इतनी कृपा की-मुझे अपनी प्राणप्रियाका दर्शन कराया, वे कदाचित् मेरी अग्रिम विनयको भी सुन लें।' उद्धव मन-ही-मन चीत्कार कर उठे-दया, दया कृपा, कृपा! हे श्यामसुन्दर इतनी-सी दया मुझ पर और कर दो-मेरे ये कर्णपुट सदाके लिये प्यासे न रह जायँ, इतनी भीख और दे दो, दयामय ! वृन्दा-काननमें फिर, फिर, फिर आनेका सौभाग्य मुझ जैसोंके भाग्यमें नहीं है नाथ! कृपाकी भीख भीख भीख....।' उद्धवके प्राण भीख-भीखका स्वर भर रहे थे भीतर ही भीतर॥ १००८॥

नीलसुन्दर ही वियोगके दुःख-भारको सह्य बनानेके उद्देश्यसे, प्राणेश्वरी प्राणवल्लभा राधाके अमित माधुर्यको प्रस्फुटित करनेके उद्देश्यसे, महाभाव-रस-समुद्रको उद्वेलित करनेके उद्देश्यसे स्वयं ही राधाकिशोरीकी सहोदरा छोटी साँवरी बहिनके रूपमें विराजित रहते थे। उस समय भी किशोरीके दक्षिण पार्श्वमें अवस्थित थे। वह साँवरी ही करुणाकी प्रवाहिणीमें अवगाहन कर करुणाकी धारासे ओत-प्रोत स्वरमें सहसा कह उठी- 'अरी बहिन ! देख, एक दूत आया है-उनका सन्देश लेकर वह आया था और अब पुनः साँवरकी ही सेवामें लौटने जा रहा है। तू भी इसे कुछ सन्देश दे दे बहिन !'॥ १००९॥

मानो नीलसागरके अतल तलसे राधाकिशोरी ऊपर उठ आयी हैं, इस भाँति उनके नयन-सरोज उन्मीलित हुए। अपनी कनिष्ठा बहिनके चिबुकको छूकर किशोरी फूट-फूटकर रोने लग गयीं। सुबकी भर-भरकर वे रोती जा रही थीं; किंतु फिर न जाने कैसे उनमें समयोचित धैर्यका संचार हुआ और अपनी बहिनका लाड़ रखने चलीं वे.........॥ १०१०॥


''');
        case 'ग्यारहवाँ शतक':
          return const _TopicPageContent(
              body:
                  '''भानुकिशोरीने अञ्चलसे अपना अश्रुमार्जन किया। ग्रीवामें झूलती हुई वनमालाको उतारकर अपने वाम कर-सरोज पर स्थापित कर लिया वही माला यह है, जो नीलसुन्दरने तपन-तनयाके तटपर, तमाल-तरुकी छायामें, मधुपुर जानेसे पूर्व प्राणप्रियतमाको पहनायी थी। नहीं-नहीं, नीले कण्ठदेशसे नील भुजपाशका बन्धन शिथिल होते-न-होते यह सुमनहार अपने-आप सरक करके किशोरीके कण्ठदेशको आवेष्टित करने लग गया था। अस्तु, भानुराजनन्दिनीने अपनी दृष्टि उस हारपर केन्द्रित कर बोलना प्रारम्भकिया-दूत ! मैं तुम्हें अपने प्राणनाथके लिये क्या संदेश दूँ? पर तुम संदेश लेने आये हो-ऐसी बात मेरी बहिन कह रही थी। तो क्या कहूँ? अच्छा, तुम उनसे कहना-राधाने कहा है- 'मेरे प्राणरमण तुम सुखसे रहना। स्वप्नमें भी तुम्हें शोककी छाया भी न छू सके.....।'॥ १०११॥

सुन्दरीसरोवरकी धरा काँप उठी, जल फेनिल हो उठा; पर भानुकिशोरी उसी स्वरमें बोलती चली जा रही हैं- और फिर कहना 'मेरे असंख्य प्राणोंके आराध्यदेव ! विचित्र-सी स्थिति है मेरी। मैं अनुभव कर रही हूँ-यह मेरा उरःस्थल निकुञ्जदेशके रूपमें परिणत हो गया है। कबसे? जानती नहीं। किंन्तु यही निकुञ्जस्थल; और इसमें ही इसमें ही एक मात्र तुम्हीं नित्य-निरन्तर निवास करते रहते हो। कह नहीं सकती, प्राणवल्लभ ! कि यह मुझे निरन्तर भ्रम ही हो रहा है या सत्य है, यह- मैं समझ ही नहीं सकती। कितनी बार सोच चुकी हूँ, पर समझ न पायी। अथवा तुम दो बन गये हो, दो बनकर तुम निरन्तर मुझसे खेल रहे हो या मैं सचमुच ही उन्मादिनी हो गयी हूँ- इसका निर्णय कौन करे? हाय रे! तुम्हीं अपने मनमें इसका निर्णय कर लेना कि वस्तुस्थिति क्या है॥ १०१२॥

अच्छा ! सचमुच ही यदि तुम चले ही गये हो-अपनी इस दासीको यहीं छोड़कर वास्तवमें ही तुम अब कहीं अन्यत्र निवास कर रहे हो तो फिर नितान्त सत्य है-तुमने सर्वथा उचित ही किया है। और अब तुम्हारा जीवन सुखी होगा, मेरे नाथ! सुखके समुद्रमें तुम डूबे रहोगे। अबतक तुम एक दुष्पार भ्रान्तिमें पड़े थे; इसका हेतु यह था - तुम अप्रतिम सुन्दर हो। तुम्हारे हृत्तलमें निर्मल अनुरागकी ऊर्मियाँ निरन्तर हिलोरें लेती रहती हैं। और इसीलिये तुम्हें मुझमें सुन्दरताका भ्रम हो गया था। यह नियम है कि जो जैसा होता है, उसे सर्वत्र वैसी ही प्रतीति होती है। इसीलिये निर्मल अनुरागकी लहरियोंमें बहते हुए, सौन्दर्यपूरकी किरणें बिखेरते हुए तुम्हें मेरे अंदर सौन्दर्यकी भ्रान्ति हुई थी॥ १०१३॥

वस्तुस्थिति तो यह है, प्राणनाथ! कि सद्‌गुणका एक कण भी किसी भी सद्गुणका कणिकांश भी मुझमें नहीं है और सम्पूर्ण दोषोंकी जीवन्त प्रतिमा हूँ मैं। पर बलिहारी है तुम्हारे अनुरागभरे नयनोंकी- तुम्हारे सौन्दर्यपूर उरःस्थलकी कि तुम केवल मुझपर ही न्योछावर हो गये थे और तुम्हें मेरे अतिरिक्त अन्य सबकी विस्मृति हो गयी थी। एक बार नहीं, शत-सहस्र बार लज्जाके घन आवरणमें मेरे प्राण समा जाते थे, जब मैं अनुभव करती-तुम मुझे अपना सर्वस्व-समर्पण करके सजल आँखोंसे गद्-गद कण्ठसे 'प्राणेश्वरी' कहकर सम्बोधित करते और उरःस्थलमें स्थान देते-भुजपाशसे मुझे वेष्टित कर लेते- मुझ सर्वथा गुणसे, सौन्दर्यसे विरहिताको। हाय रे विधिकी विडम्बना....॥ १०१४॥

कालके प्रवाहमें न जाने असंख्य बार मैं सोचती थी कि जब मुझमें रूप नहीं, गुणका लेशमात्र भी नहीं, तब मेरे जीवन सर्वस्व जो तुम हो, उनका -तुम्हारा भ्रम मैं कैसे दूर कहूँ? मैं तुम्हें कैसे समझाऊँ? कोई उपाय मुझे सूझता न था, प्राणनाथ ! इतनेपर भी प्रतिदिन ही मैं किसी-न-किसी रूपमें तुम्हें प्रत्यक्ष संकेत कर ही देती थी कि तुम चेत जाओ, इस भ्रमजालसे ऊपर उठ जाओ, किंतु जब मैं थक जाती थी समझाते-समझाते, तब मेरे अन्तस्तलमें स्फुरणा जगती कि चलूँ श्रृंगार-कुञ्जमें और अपने अङ्गोंको सजाऊँ और देखें, क्या परिणाम होता है इसका....॥ १०१५॥

मैं सदा-प्रतिदिन ही श्रृंगार धराने, श्रृंगार धारण करने कुञ्जमें तभी गयी थी, गोष्ठके उस कक्षमें तभी प्रविष्ट हुई थी, जब मेरी चित्तवृत्ति एक प्रेरणा देती-कदाचित् सँवरनेसे, श्रृंगार धारण करनेसे मैं सुन्दरी हो जाऊँ, मैं सुन्दर दीखने लग जाऊँ। तनिक सा ही भान करा दे दर्पण अपने प्रतिबिम्बमें मुझे -'अरी राधा ! आज किञ्चित्-सी सौन्दर्यकी रेखा तेरे मुखपर आयी है।' और मैं नवीन परिधान धारण भी तभी करती थी, विभिन्न आभरणोंका चाकचिक्य तभी स्वीकार करती थी, चन्दनका विलेपन मुझे छू सके यह अनुमति मैं तभी देती थी, जब मुझे क्षणिक भ्रान्ति होने लगती थी हो सकता है, ये वसन-भूषण-चन्दन मेरे कुरूपको आवृत कर दें। मेरे प्राणनाथ नीलसुन्दरको आधे क्षणके लिये मेरा यह कुरूप सुखदान कर सके। और अपने अंदर सद्गुणोंके आविर्भावके लिये मैं अपनी इन सहचरियोंका ध्यान किया करती थीं-इस आशासे कि इनकी छाया भी मैं छू लूँ, इनके आदर्श गुणोंका एक स्वल्प, झीना प्रतिबिम्ब भी मेरे अंदर संक्रमित हो जाय॥ १०१६॥

किंतु सदा, सर्वथा, सर्वांशमें मुझे यही अनुभव होता आया था, आया है कि मैं गुणवती, सुरूपा बन ही नहीं सकी, जिसे तुम अपना सर्वस्व-दान कर सको। इतनेपर भी तुम्हारे द्वारा मुझे यह प्यार मिला था, जिसे अबतक कोई भी ले ही नहीं सकी। अनादि प्रवाहमें किसी भी गोप-सुन्दरीके प्रति तुम्हारे द्वारा वह प्यार-दान हुआ ही नहीं। आगे होगा या नहीं, इसे तो तुम्हीं बता सकोगे, मेरे प्राणनाथ....... !॥ १०१७॥

अतएव यदि यह सत्य है कि तुम अब मुझसे पृथक् हो गये हो और उस राजाकी नगरीमें जाकर सचमुच ही कहीं निवास करने लगे हो और सचमुच तुम्हारी रुचिके अनुरूप कोई जीवन-सङ्गिनी तुम्हें प्राप्त हो गयी है, अहा! तब तो आज-आज मेरा भाग्योदय हुआ, खुल गया मेरा भाग्य ! और सचमुच आज प्रथम बार मैं सुखिनी हुई हूँ.....॥ १०१८॥

विधिने मेरी विनती सुन ली-तुम जाग उठे, चेत गये तुम। मेरे प्रति जो महामोहका पाश तुम्हें बद्ध किये हुए था, वह छिन्न-भिन्न हो गया-टूट गया वह...। अहा ! प्राणाधिक! मेरे नीलसुन्दर! यदि सचमुच ही तुम अपने अन्तर्हृदयका प्यार किसीको देकर मुझे भूल गये हो- अपने स्मृतिपथसे दूर फेंक चुके हो मुझे तो अहा! तुम कितने सुखमें होओगे, मेरे जीवनसर्वस्व ! कितने असीम सुख-सिन्धुमें तुम अवगाहन कर रहे होगे प्राणरमण...॥ १०१९॥

देखो, सही! यह मैं कल्पना ही तो कर रही हूँ! पर जब यह कल्पना ही मुझे इतना अपार सुखदान कर रही है, तब कहीं यह सत्य हो जाय, फिर, फिर तो क्या कहना है.... यही तो मेरे जीवनकी साध थी- है- 'प्रियतम प्राणनाथ नीलसुन्दर मुझे भूल जायँ.....।' किंतु असंभव है यह होना, प्राणाधिक! तुम मुझे भूल सको-यह न हुआ है, न होगा। मैं अनादि कालसे प्रवाहमें परिचित हूँ तुम्हारे स्वभावसे- तुम्हारी चित्तवृत्तिकी ऊर्मियोंसे। मैं जानती हूँ, तुम कैसे हो प्रियतम.......'॥ १०२०॥

भानुकिशोरीके मुखपर अरुणिमाका संचार हो आया, उन्मादकी लहर आँखोंमें नाच उठी और वे दृष्टि घुमा-घुमा करके देखने लगती हैं वनस्थलकी लता-वल्लरियोंकी ओर... और फिर आकाशकी ओर, मानो किसीको ढूँढ़ रही हों उनकी आँखें। एक अट्टहास फूट पड़ता है उनके अधरोंके अन्तरालसे और फिर नीरवताके क्षणिक आवरणमें उनकी आँखें निमीलित हो जाती हैं। तथा निमीलित नेत्रोंसे ही बिना किसी लक्ष्यके वे कहने लगती हैं- 'तो कोई दूत बनकर आया है! अच्छा! अरे दूत! तुमसे कह रही हूँ, भला, और उनसे, उनसे, जो अगाध परिताप लेकर मुझसे कहा करती हैं उन सहचरियोंसे-बस, तुम दोनोंसे ही कह रही हूँ, और किसीसे नहीं, भला ! पर तुम इसे प्रकट मत करना किसीके समक्ष। अच्छा, तो सुनो! तुम सब-की-सब और दूत ! तुम भी चले जाओ नीलसुन्दर मेरे प्राणनाथके समीप और जाकर स्वयं देख लो कि क्या दशा है उनकी, मुझसे जुड़े रहनेके कारण। मेरे प्राणवल्लभके जीवनका रूप क्या हो गया है मुझसे सम्बद्ध होकर, यह स्वयं जाकर देख लो तुम दोनों॥ १०२१॥

देखो ! सीधे उनके सामने खड़ी हो जाना, खड़े हो जाना, अपनी अँगुलियोंको उनके वक्षःस्थलके बीच स्थापित कर देना। तुम्हारी अँगुलियाँ सुनने लगेंगी, कर्णरन्ध्रोंकी तो बात ही क्या है, तुम्हें स्पष्ट सुन पड़ेगा, वक्षःस्थलकी प्रत्येक धड़कनमें 'राधा-राधा-राधा'- यही स्वर स्पन्दित हो रहा है। और फिर क्या करना-आँखोंकी, उनके नयन-सरोजोंकी काली पुतलियोंकी ओर अपनी दृष्टि केन्द्रित कर देना। देखो, तुमको वहीं, तुरंत प्रत्यक्ष दीख जायेगा-उन नयन-सरोजोंकी काली पुतलियोंमें तुम्हें अपना प्रतिबिम्ब नहीं दीखेगा, अपितु वहाँ मैं, बस, इसी रूपमें, ज्यों-की-त्यों, खड़ी दीखूँगी। नयन-सरोरूहोंके असित-सित अंशोंके कण-कणमें 'मैं-ही-मैं, मैं राधा, मैं-ही-मैं, मैं राधा, मैं-ही-मैं, मैं राधा, मैं-ही-मैं, राधा', भरी हुई मिलूँगी। और फिर अपनी दृष्टि उनके श्रीअङ्गकी रोमावलीपर केन्द्रित करना - प्रत्येक रोममें मैं ही परिपूरित मिलूँगी। प्रत्येक रोममें मेरा ही रूप तुम्हें अभिव्यक्त मिलेगा। फिर देखना- जहाँ वे विराजित हों, जिस वृक्षके नीचे वे अवस्थित हों, जिस कक्षके जिस पार्श्वमें वे सुशोभित हों, उसके कण-कणमें, उस वृक्षके क्षुद्र-से-क्षुद्र अंशमें, उस कक्षके प्रत्येक परमाणुमें मैं-ही-मैं, मैं राधा, री, अरे दूत! मैं राधा, इसी-इसी राधाका मुख झलमल करता दीखेगा तुम्हें ! क्योंकि उनकी प्रत्येक वृत्तिमें मेरे अतिरिक्त किसीका अस्तित्व है ही नहीं। सुनते हो, ऐसा है उनका और मेरा सम्बन्ध.....॥ १०२२॥

किंतु एक बात अवश्य है- उनके अन्दर कोई शक्ति है, भैया दूत रे और बहिनों! कोई छिपी हुई शक्ति है उनमें। इसीलिये उन्हें कोई पहचान ही नहीं पाता। दूत ! तुम भी बड़े भोले हो और बहिनों! तुम और भी भोली हो। दूत ! सुनो-बहिनों! सुनो-उनका और मेरा वियोग होना असम्भव है। पर इसे जान लेना भी आसान नहीं है, इसे अनुभव कर लेना बड़ा ही कठिन है-निरन्तर निर्बाध क्रन्दनके द्वारा जब तुम्हारी आँखोंका मल सर्वथा धुल जायेगा, तभी तभी यह सत्य सामने आयेगा और एक बार उस सत्यका अनुभव कर लेनेपर वह सत्य तुम्हारा चिरसङ्गी बन जायेगा। तुम्हारे लिये वह सुलभ-से-सुलभ वस्तुका रूप धारण कर लेगा॥ १०२३॥

अच्छा ! तुम्हारे अंदर जिज्ञासा उत्पन्न हो गयी-तुम सब मेरी इतनी-सी बातपर विश्वास न कर सके और जानना चाहते हो कि 'तब फिर मैं रोती क्यों हूँ।' ठीक ही तो है- जब प्रियतम निरन्तर मेरे साथ हैं, उनका-मेरा वियोग होगा नहीं तो मैं रोती क्यों हूँ- यह भ्रम होना स्वाभाविक है। दोनों बातें साथ कैसे होंगी ? बड़ा ही अद्भुत मर्म है उसका। आज मैं निर्लज्ज हो गयी हूँ, इसीलिये बताती हूँ। नहीं तो नहीं बताती। अब क्या, क्यों, किससे संकोच करूँ? इसीसे कह दे रही हूँ। देखो, मेरा यह क्रन्दन अनादि है और इस क्रन्दनका कभी विराम भी नहीं होगा। अनन्तकाल तक निरन्तर यह क्रन्दन चलता ही रहेगा। ऐसा क्यों? तुम समझ सकोगे ? बता दूँ? अच्छा, समझ सको तो समझ लो, जान लो, देख लो,' यह क्रन्दन ही मेरा जीवन है; यही मेरा रूप है। मेरा जीवन अनादि अनन्त - क्रन्दन है !.....॥ १०२४॥

भानुकिशोरी पुनः अट्टहास कर देखने लगीं सरोवरके फेनिल जलकी गतिको। और फिर यन्त्रवत् अपना सिर दोलित करके बोलने लग गयीं- अरे दूत ! तुम स्मरण रख सकोगे मेरी इन बातोंको....? तो क्या करूँ? अच्छा, कुछ सुन लो। जितना-सा अंश तुम्हें स्मरण रहे, उतना-सा ही कह देना मेरे प्राणनाथको। पर उसे स्मरण रखनेकी कला मैं तुम्हें सिखा दे रही हूँ। सुनो ! सीखोगे उस कलाको ? देखो, मेरे उरःस्थलमें एक पाठशाला है-कब निर्माण हुआ इस पाठशालाका, जानती नहीं! पर मैं उसीमें न जाने कबसे पढ़ रही थी और आज भी उसमें ही पढ़ती हूँ। मैंने अपने-आपसे पूछा था-इस पाठशालाका नाम क्या है? कोई उत्तर न दे सका। तब हारकर वहीं अपने प्राणनाथ नीलसुन्दर, जो मेरे हृत्तलमें ही निरन्तर विराजित रहते हैं, उनसे पूछ बैठी मैं। उत्तरमें वे बोले नहीं, पर उनके नयन-सरोजोंसे अश्रुकी बूँदें ऐसी ढलक पड़ीं कि मुझे उस पाठशालाके नामका भान हो गया। उस पाठशालाका

नाम है- 'प्रेम-पाठशाला'। तुम्हारे लिये यही नाम सुबोध हो सकेगा।

तो मैं उसीमें पढ़ रही थी, पढ़ रही हूँ। उसका प्रथम पाठ है- वर्णमालाका उच्चारण करके उन वर्णोंको लिखना। देखो! पर तुम्हें तो मैं वर्णमालाका एक ही नाम बताऊँगी। सुनो 'कृष्ण' - इस वर्णका उच्चारण करते-करते शेष सम्पूर्ण वर्णमालाका तुम्हें भान हो जायगा और फिर तुम उस वर्णमालाकी आकृतियोंको, उनके रंगोंको अपने हृत्तलपर अङ्कित करते जाना। मैं यही करती हूँ, यही करती थी।

देखो ! उस कृष्णवर्णके अन्तरालमें अरुणाभवर्ण बीस नखमणियाँ दीखेंगी। उनपर वृत्ति केन्द्रित होते ही फिर एक अभिनव नारङ्गवर्णकी छटा व्यक्त होगी-कहाँ, कैसे, तुम स्वयं समझ लोगे। इन दोनों वर्णोंको अपने हृत्पटलपर मैं निरन्तर लिखती रहती थी; तुम भी लिखते रहना, भला।

इसके पश्चात् एक पीतवर्णके दर्शन होंगे- सर्वथा अभिनव है वह पिङ्गलवर्ण ! तुम निरन्तर उसे भी अपने हृत्पटपर बसाये रहना। फिर इसके अनन्तर एक हरिद्वर्ण समुद्भासित होगा क्यों, कैसे, तुम स्वयं जान लोगे। बतलानेमें संकुचित हो रही हूँ दूत ! पर इसे तुम प्रमुख स्थान देना, भला ! वृत्ति हटे ही नहीं इससे ! लिखते-लिखते श्रान्त कभी मत होना। फिर व्योमवर्ण, नीलवर्ण और वृन्ताकवर्ण-ये सब के सब उदित होंगे। अविरामभावसे 'कृष्ण-कृष्ण' उच्चारण करते रहना और इन वर्णोंकी आकृतिका निर्माण करते रहना। किंतु सावधान ! खड़िया मिट्टीसे नहीं, इसके लिये तुम्हारे अन्तस्तलसे अश्रुकी बूँदे निःसृत होंगी। काँचकी भाँति गोल-गोल बूँदें व्यक्त होती रहेंगी और तुम लिखते रहोगे उन वर्णोंको। अक्षरका ज्ञान इतनेमें ही तुम्हें हो जायेगा। सम्पूर्ण प्रीति-पाठशालाके मातृका-वर्ण इन्हीं वर्णोंमें पर्यवसित हो जायेंगे। फिर समझ पाओगे, दिनकरकी रश्मियोंमें इन्हीं वर्णोंकी छायाकी छाया प्रतिभात हो रही है।.....

जब तुम्हें अक्षरका बोध हो जायेगा, तब जानते हो, दृश्य-प्रपञ्चकी सत्ता सर्वथा तुम्हारी आँखोंसे विलुप्त हो जायेगी। एक सत्य, एक ज्ञान, एक आनन्द-एकरस सम्पूर्ण सत्य, एकरस सम्पूर्ण ज्ञान, एकरस सम्पूर्ण आनन्दकी बात तुमने कभी सुनी होगी न? उसे तो तुम घलुएमें प्राप्त कर लोगे। जो हो, बड़ी सावधानीसे इस प्रक्रियाका आश्रय लेकर वर्णोंको अङ्कित कर लेना सदाके लिये अपने उरःस्थलके अन्तरतम देशमें ।.......

अब आगे सुनो-जिसे अक्षरका बोध हो जाता है, जो वर्णमाला सीख जाती है, वह फिर शब्दोंको लिखती है। जानते हो, एक तो षड्जका शब्द आयेगा, एक ऋषभका, एक गान्धारका, एक मध्यमका, एक पञ्चमका, एक धैवतका और एक निषादका। पर यह शब्द-नामावली उस शब्दकी छायाकी छाया है, भला ! उन शब्दोंके लिये भी कोई नाम ही नहीं, रे दूत ! क्या बताऊँ? पर जैसे, जिस भाँति मैं समझी थी, पाठ पढ़ पायी थी, वैसे ही, उसी भाँति तुम समझ सको, इसलिये ही इतना-सा कह दे रही हूँ। कालके प्रवाहमें कब, कैसे, कितना इस प्रक्रियाका आश्रय मैंने स्वयं लिया, जानती नहीं, दूत ! बस, तुम मेरे संदेशको स्मरण कर सको, इसीकी कला सिखानेके उद्देश्यसे मैं इतना कह दे रही हूँ। अस्तु,

इसे सीखनेकी प्रक्रियामें भी रजताभ वारि-बिन्दु तुम्हारे नयनोंसे निरन्तर सृष्ट होते रहेंगे और शब्दोंको लिखना सीख जाओगे तुम। एक बाँसके खण्डसे ही ये शब्द निकले हैं, भैया! कैसा होता है उस खण्डसे निःसृत शब्द-इसे तुम अनुभव करना। वाणी क्या बतलायेगी उसे...

अब इसके अनन्तर संयुक्त वर्णांका भान होगा तुम्हें। कैसे वे संयुक्त वर्ण होते हैं, उन्हें सुनकर तो तुम सीख सकोगे। पर लिखनेका अभ्यास अवश्य करना उन्हीं रजताभ बिन्दुओंके माध्यमसे। ये संयुक्त वर्ण बहुत ही सरस होते हैं, दूत ! फिर आगे चलकर उन्हें लिखनेके लिये अपने-आप स्वर्णिम कणावली झरती रहेगी तुम्हारी आँखोंसे। तुम लिख-लिख करके पढ़ते रहना उन संयुक्त वर्णोंको॥ १०२५, १०२६॥

अब विधेय-उद्देश्यमयी उस भाव पंक्तिका पाठ आरम्भ होगा, किंतु उस पाठका अर्थ इतना गूढ़ रहता है, जिसे तुम जान ही नहीं सकोगे। अज्ञात रहेगा उस पाठका गूढ़ार्थ। इसके अनन्तर कुछ दिन प्रतीक्षा करते रहना। अपने-आप विशुद्ध सत्त्वमयी नयनोंकी अविराम धारा व्यक्त होगी और उसीसे लिखते-लिखते सम्पूर्ण पाठोंकी कुञ्जी तुम्हें प्राप्त हो जायेगी॥ १०२७॥

इसके पश्चात् क्या होगा, तुम्हें बताऊँ? एक होती है महाभाव विद्या, जो अबतक तुमने पढ़ी नहीं है दूत ! वह विद्या कैसी होती है, तुम्हें बता दूँ? अच्छा, सुनो! उस विद्याके आविर्भावमें किसीको अबतक हेतुका अनुसंधान प्राप्त नहीं हुआ है। बड़ा ही सूक्ष्म है वह। मलकी गन्धकी गन्ध नहीं है वहाँ-इतनी अमल है वह महाभावकी विद्या; और वह है प्रतिक्षण वर्धनशील। उसमें खण्डित होनेका कहीं भान नहीं होता। वह सर्वथा अखण्ड है। सीमाविहीन है वह। आजतक कोई भी उसका पार न पा सकी, न पा सका। और देखो! वाणी छू भी नहीं सकती उसे। सर्वथा, सर्वांशमें वह स्वसंवेद्य है। बड़ी ही गम्भीर है वह, भला! उस महाविद्याका 'अथ', सो भी कहनेके लिये, इस विशुद्ध सत्त्वमयी धाराके बिन्दुपर ही अवलम्बित है। उसी 'अथ'-को स्पर्श कर अब तुम अग्रसर होओगे......॥ १०२८॥

इसके पश्चात् क्या है, इसे तो कोई भी नहीं कह सकती और सत्य तो यह

है कि जो आगे जाकर उसमें निमग्न हो गयी, वह कभी लौटती ही नहीं। जो भी, जो कुछ भी, कोई कहने चलती है, वह इधरकी ही बात है, दूत ! मेरी भी यही दशा है- मुझ-सी कहनेवाली उस महाभाव विद्याके समुद्रमें कभी डूबी ही नहीं।'॥ १०२९॥

इतना कहते-कहते भानुकिशोरीमें एक अभिनव आकुलताका उन्मेष हुआ। वे दौड़कर चल पड़ती हैं। सम्मुख ही श्यामल तमालकी शाखा भानुकिशोरीके सिरपर झूल-झूल करके मानो कुछ कहना चाहती है। उसे किशोरीने अपने दक्षिण कर-सरोजमें ले लिया। किशोरीको भान हो रहा हैं-' सामने नीलसुन्दर खड़े हैं; मैं उनके कर कमलोंको अपने करमें धारण किये हुए हूँ। साथ ही गद्गद कण्ठसे भानुनन्दिनी बोलती भी चली जा रही है-मेरे जीवनकी एकमात्र निधि ! चलो, अब तुम चलो ! कहाँ ? वहाँ, वहाँ, वहाँ, उस नीले स्रोतके कूलपर। यही, यही माला, जो तुमने मुझे दी थी, पहनाई थी, उसीको मैं वहाँ, उसी स्थलपर तुम्हें पहना दूँगी॥ १०३०॥

देखो, मैं इसे अपने नयनोंकी बूँदोंसे आर्द्र किये रहती हूँ-कहीं यह मुरझा न उठे, म्लान न हो जाय। तनिक भी इसमें परिवर्तन न हो, इसी भयसे मैं इसे अपने आँखोंकी बूँदोंसे सिक्त करती रहती हूँ। अबतक इस पाठशालामें मैं केवल इतना-सा ही सीख सकी हूँ- 'जो वस्तु तुमसे प्राप्त हो, उसे वैसे ही, उसी रूपमें रखना है।'॥ १०३१॥

तो अब चलो-तुम्हें तो चलना ही है; इस वनसे दूर-दूर चले जाना है तुम्हें, और मुझे साथ ही लेकर जाना है, भला ! चिरसङ्गिनी हूँ मैं तुम्हारी। अच्छा, तुम रूठ गये हो? मैं विलम्ब कर बैठी, इसलिये तुम मुझसे खिन्न हो बैठे हो ? सुन लो- मैं क्यों ठहरी, इसका हेतु बतला दे रही हूँ। अरे! प्रत्यक्ष देख लो-यह माला ही तो मेरा बन्धन है। मैं इसे किसके हाथोंपर रखकर जाऊँ? किसे पहनाकर जाऊँ? ऐसी अबतक कोई भी मुझे न मिली, जिसके करतलपर इसे प्रतिष्ठित करके भाग चलूँ- तुम्हारे साथ उस नीले स्रोतकी ओर-इस वनस्थलके उस पार, उस पार, अत्यन्त दूर॥ १०३२॥

इसे मैं फेंक दूँ, यह भी सम्भव नहीं है मेरे लिये और इसे साथ ले जाऊँ, यह भी सर्वथा असम्भव है। इसे फेंक भी नहीं सकती, साथ भी नहीं ले जा सकती-कैसी उलझन है मेरे लिये? देखो, मैंने इसमें और तुममें कभी भेदका अनुभव किया ही नहीं, क्योंकि यह माला तुम्हारे उरःस्थलसे जुड़ी रही है। मैंने देखा है, प्रत्यक्ष देख रही हूँ- इसके कण-कणमें तुम विराजित हो रहे हो। अथवा और भी सुस्पष्ट कहूँ तो कह सकती हूँ-तुम्हीं, तुम्हीं यह माला बनकर मुझसे खेल रहे हो॥ १०३३॥

मेरी परिस्थितिको सोचकर देखो, तब न ! मैं क्या सोच रही हूँ, इसपर तो विचार करो। मेरी बुद्धिका अध्यवसाय विलुप्त हो चुका है और इसीलिये रह-रह करके सोचने लग जाती हूँ कि कहीं इन सहचरियोंकी ही उक्ति सत्य हो, तुम सचमुच ही चले गये हो, तो, तो, तो क्या होगा? यही होगा कि तुम अवश्य, अवश्य, अवश्य लौटोगे और यहाँ आकर यदि यह देखोगे कि इस मालाको, हाय रे ! जिसे मैंने प्राणेश्वरी माना था, अनुभव किया था, उसीने अपने हाथोंसे फेंक दिया है-उस हारको फेंक दिया, जिसके रूपमें मैं स्वयं ही मूर्त हूँ! सोचो तो सही, तुम कितने व्याकुल होओगे, प्रियतम ! इस प्रकारकी अनुभूति करके॥ १०३४॥

हाय रे! यदि इतनी ही बात होती कि तुम अन्यमनस्क होकर उस स्थितिमें ऐसा सोच लेते- अरे ! वह पगली थी! भोली थी !! दीना थी !!! और ऐसी ही कोई उक्ति तुम्हारे मुखसे निःसृत हो जाती और तुम उल्टे पाँव लौट जाते अपने देशमें-ऐसी सम्भावना होती, मुझे निश्चय होता कि वे मेरे प्राणनाथ ऐसे ही कर लेंगे, तब तो हे मेरे जीवनसर्वस्व ! मुझे इसकी चिन्ता न होती और मैं कबकी चली गयी होती। किंतु मैं, मैं निरन्तर अनुभव कर रही हूँ- उस स्थितिमें तुम्हारा क्रन्दन इतना भीषण होगा, इतना प्रलयंकर होगा कि तुम्हारे क्रन्दनसे इस व्योमका हृदय भी विदीर्ण हो जायेगा॥ १०३५॥

..प्राणरमण ! कल्पना करो-धूलमें सनी हुई माला मुरझायी हुई आकृतिसे धरापर चेतना-शून्य-सी पड़ी तुमसे कहीं संकेत कर बैठी- 'व्रजके देवता! चली गयी वह, वह चली गयी' और इस प्रकार मेरे विदा हो जानेकी वृत्तिने तुम्हें स्पर्श कर लिया और तुम सोच बैठे- 'हाय रे ! अब मेरे प्राणोंकी रानी मानिनी होकर कहीं इन निकुञ्जोंमें छिपकर नहीं बैठी है-अब तो दूर.... दूर, अत्यन्त दूर, एकाकिनी चली गयी है, ओह ! उस ओर, जिस ओर, जिस ओर जाकर कभी कोई लौटी ही नहीं, लौटा ही नहीं, इतिहासके पन्नोंमें, इतिवृत्तके चित्रोंमें कहीं इस प्रकारकी कोई गन्ध किसीको अबतक मिली ही नहीं कि कोई भी उस ओरसे लौटी हो, लौटा हो-उस समय तुम, तुम क्या यहाँ आवास निर्माण करनेके लिये, बसनेके लिये, जीवित रहोगे, प्राणरमण ! अरे, चुप, चुप, चुप, चुप। इस महाप्रलयकी कल्पनाको भी भ्रमसे भी मैं अपने चित्तमें नहीं आने दूंगी, आने नहीं दूँगी, नहीं आने दूंगी।'॥१०३६, १०३७॥

फटी आँखोंसे भानुकिशोरी निरावरण आकाशकी ओर देखने लग जाती हैं। और फिर कुछ ही क्षणोंके अनन्तर हास्यकी एक उन्मादभरी रेखा स्फुट रूपमें उनके होठोंपर व्यक्त हो उठती है! बायें-दाहिने, ऊपर-नीचे देखती हैं। पलकें स्पन्दित होती हैं और फिर कुछ बड़-बड़-सी करने लगती हैं। स्वर स्पष्ट सुन नहीं पड़ता। फिर ताली पीटकर अचानक बोल उठती हैं- ' अच्छा ! तुम उपदेश देने आये हो? नहीं-नहीं, जिज्ञासाकी मुद्रा है तुम्हारे मुखपर तो ! तो, कोई तो नहीं है यहाँ! तब किसने यह प्रश्न पूछा मुझसे ? किसीने पूछा होगा; क्यों, यही तो पूछ रहे हो तुम 'क्यों री, भोली ! इस मालाको साथ क्यों नहीं ले जाती ? इतना ऊहापोह तुम्हारे चित्तमें क्यों?' - यही तो जानना चाहते हो? तो सुनो, सुनो-जो भी हो, ऐसे जो पूछती है या पूछता है, उससे कह रही हूँ, भला ! क्षमा करना, क्षमा कर दे वह मुझे। वास्तवमें ऐसा कहनेवाली, ऐसा कहनेवाला जानती ही नहीं, जानता ही नहीं कि रसकी रीति क्या होती है! अरे! उसने कभी देखा ही नहीं प्राणनाथ! कभी उसकी आँखोंमें यह अभिव्यक्ति हुई ही नहीं कि राकाकी रजनीमें मेरा और तुम्हारा निरावरण मिलन कैसा होता है, कैसा होता है, कैसा होता है...... इसलिये जो, जैसी सलाह देना चाहे, दे दे, सुन लूँगी।'॥ १०३८॥

विरक्त-सी हुई किशोरी किंचित् रूखी-सी होकर बोल उठती हैं अब-'छोड़ो, क्या करना है! तो प्राणनाथ! मैं तो तुमसे बात कर रही थी। क्या-से-क्या बोल जाती हूँ! कोई तो नहीं है, तुम्हीं तो हो। तो मैं क्या कह रही थी ? अच्छा तो, जबतक इस मालाको तुमने अपनी ग्रीवामें झुला रखा था, अहा ! तबतक इसके सभी कुसुम सर्वथा अविकृत थे, और कैसी आवरणहीन हँसी इनके होंठोंपर थी प्राणरमण ! देखो, बड़ी भूल की तुमने ! तुमने इस मालाको, अपनी इस दासी मुझे, मुझ राधाको पहना दिया-बड़ी भूल की। परिणाम क्या हुआ, स्पष्ट देख लो ! मैं जैसी थी, उसके अनुरूप ही मेरी छाया सृष्ट हुई, उनपर पड़ी और ये सुमन उसी साँचेमें ढल गये.....॥ १०३९॥

जो निरन्तर तुम्हें देख रहे थे, वे दुर्दैववश प्रतिबिम्बगृहीत हो गये। हाय रे! उन्हें प्रतिबिम्ब अधिक प्रिय लगने लगा, अधिक आकर्षित करने लगा। और इस प्रकार उन्हें, उन सुमनोंको अपने स्वरूपकी विस्मृति हो गयी। अभिमानमें निमग्न, सुनते हो, सुनते हो, प्राणनाथ? अभिमानमें भरी मैं तुमसे अपने इस महामलिन नश्वर शरीरका आराधन करवाती थी और इसीलिये मेरा यह दोष इनमें भी संक्रमित हो गया; बस, बस, वज्र गिर जाय मेरे अस्तित्वपर...।'॥ १०४०॥

किशोरी उन्मादिनीकी भाँति फू-फू करके रोने लगती हैं और कुछ क्षणोंके अनन्तर फिर कहती हैं- अच्छा, अच्छा! अब, अब उसी पीले उरःस्थलपर इस मालाको मैं झुला दूँगी बस, यही, यही करना है मुझे। ये सुमन तुमसे मिलकर तब, तब, तब......। भानु किशोरीके अधरोंपर उन्मादकी उल्लासकी, और आगे, आगे भावात्मक महाप्रलयकी रेखा व्यक्त होती है उन्मुक्त हँसीके रूपमें। वे बारम्बार 'तब', 'तब', 'तब', 'तब', 'तब', 'तब', 'तब', की आवृत्ति कर रही हैं-पाँच-दस पलों तक निरन्तर...। पुनः एक अचिन्त्य शक्तिकी प्रेरणासे वही पूर्वकी वाक्यावली फूट पड़ती है-'हाँ-हाँ, तो ये सुमन तुमसे मिलकर तभी, तभी तुमको और मुझे पहचान पायेंगे-और उस धागेको, नीले धागेको, जिसमें ये नित्य पिरोये हुए हैं। उस समय तुम्हारा आनन्दोदधि कितना, कैसा उद्वेलित होगा, प्राणनाथ! सोचो तो सही, उसीमें हम दोनोंकी आँखोंसे आनन्दकी धारा कैसी बह चलेगी और फिर कैसे हम दोनों हँसेंगे! सोचो, सोचो उस अग्रिम दृश्यको; देखो, देखो उस महान आनन्द-क्रन्दनको। और महान आनन्दके हास्यको ! फिर हम दोनोंके अग्रिम नवीन रङ्गमञ्चका निर्माण होगा, नवीन क्रीड़ा-विलासकी लहरियोंमें हम दोनों संतरण करेंगे, अभिनव अप्रतिम सुन्दर खेल होगा वह-।' किशोरी पुनः उन्मत्त हँसी हँसने लगती हैं॥ १०४१॥

नीलसुन्दर सर्वथा मान उनके समक्ष खड़े हैं- इस अनुभूतिमें तन्मय हुई किशोरी अपनी आँखें बन्द कर लेती हैं- सचमुच उन्हें अनुभव हो रहा है कि एक नीलसुन्दर तो मेरे हृत्सरोजपर विराजित हैं और एक मेरे समक्ष अधरोंपर मन्द स्मित लिये। आठ-दस पलतक नीरवताके राज्यमें डूबी रहकर किशोरी पुनः अत्यन्त गम्भीर मुद्रामें कह उठती हैं किंतु 'किंतु इस वनमें नहीं, भला ! उधर आगे, आगे-से-आगे चलना है, प्रियतम! वहाँ, वहाँ जहाँ वह नित्य नीलरसोदधि गम्भीर, गम्भीरतर होता चला जा रहा है। अहा, एक-से-एक ऊँची ऊर्मि उठती है और उस नीले सागरमें विलीन हो जाती है। अनादि हैं, अनन्त हैं वे ऊर्मियाँ। उसमें, उसमें, उस नीले समुद्रमें, उस नीले समुद्रमें हम दोनोंकी क्रीड़ा होगी, प्राणवल्लभ !......।'॥ १०४२॥

सुन्दरी सरोवर पुनः एक अट्टहाससे गूंज उठता है और किशोरी तमाल द्रुमकी उस शाखाको छोड़कर आगेकी ओर चल पड़ती हैं। किंतु कुछ ही दूर जाकर फिर मुड़ जाती हैं पीछेकी ओर हँसती-हँसती कहने लगती हैं-'तुम सचमुच प्राणनाथ हो? नहीं, नहीं, यह तो मयूर बैठा है.....!' किशोरी अपने दोनों हाथोंसे माथा पीटकर अपनी उक्तिकी परिसमाप्ति करती हैं इन शब्दोंमें - प्राणनाथ नहीं हैं, मयूर नहीं हैं, मेरी बुद्धि बिगड़ी हुई है। यह तो भौंरा बैठा हुआ है॥ १०४३॥

अहा! गम्भीर मुद्रामें जैसे वे सोचते थे, मेरे प्राणनाथ किसी बातका विचार करते थे, वैसे ही यह भौंरा भी सोच रहा है। इसका रंग-ढंग भी प्रायः उन्हींसे, सबकुछ उन्हींसे मिलता-जुलता है। पर इतना म्लान यह भ्रमर क्यों है? हाय! इस समय मेरे सामने इसके मुखपर ऐसी म्लानता क्यों? ओहो ! अब समझी-बहुत सम्भव है, मुझ उन्मादिनीके अनर्गल प्रलापको सुनकर यह खिन्न हो गया है।'॥ १०४४॥

आँखें गड़ा किशोरी दूतकी ओर देख रही हैं- दो-तीन पलोंतक निर्निमेष नयनोंसे देखती रहती हैं और फिर आकुल मुद्रामें कह उठती हैं- 'हाय रे ! हाय रे !! मैं देख न सकी-भौंरा तो रो रहा है, इसकी आँखें अनर्गल अश्रु-प्रवाहका उद्गम बनी हुई हैं......। अहा! प्यारे भौरे तुम रोओ मत, मत, मत रोओ। क्या व्यथा है तुम्हें सबकुछ अपने मनकी सब बातें मुझे बता दो। जो कुछ भी तुम्हारे मनमें हो, निरावरण- बिना किसी संकोच के मेरे सामने प्रकट कर दो! देखो! मैं उनकी नीलसुन्दरकी दासी हूँ; अत्यन्त, अत्यन्त प्यारी दासी हूँ, तुम जो चाहोगे, वही वस्तु मैं तुमको दे दूँगी.....।'॥ १०४५॥

किशोरीका स्वर क्रमशः धीमा होता चला जाता है, पर वे अविराम बोलती चली जा रही हैं- 'देखो, मेरे प्राणनाथका कोष, मेरे नीलदेवताका कोष मेरे आराध्यदेवका कोष अप्रतिम है- नित्य, सर्वथा, सर्वांशमें अतुल है और अक्षय है; निःसीम है वह कोष। किंतु उस कोषकी स्वामिनी मैं ही हूँ भला ! सर्वथा, सर्वांशमें उस कोषपर मेरा ही आधिपत्य है-सच मानना रे भौंरे ! तुम प्रत्यक्ष देख लो, देखते ही उज्ज्वल तारोंकी इस कुञ्जीको; यह उसी कोषकी कुञ्जी है और मेरे प्राणाधिकने स्वयं अपने हाथोंसे मेरे अञ्चलमें इसको सदाके लिये बाँध रखा है। जिस समय-न जाने कबकी बात है-युग-युगान्तरसे असंख्य युग-युगान्तका कालमान तबसे व्यतीत हो गया, भला ! जिस समय, जिस क्षण वे इसे बाँध रहे थे-अपने कर-सरोजसे बाँध रहे थे, कैसी रसमयी अनाविल हँसी उनके अधरोंपर व्यक्त थी, तुम्हें कैसे बताऊँ, भौंरा !.....॥ १०४६॥

इसीलिये तुम्हें मैं असम्भव वस्तु भी दे दूँगी, तुम्हारे लिये सर्वथा असम्भवको भी सम्भव बना दूँगी। तुम विश्वास करो, उनकी यह दासी सत्य ही कहती है। मिथ्या आश्वासन मैं देना जानती ही नहीं, रे भौंरा ! रे भौंरा !! जो हो, ऐसा क्यों हुआ ? तुमपर इतना क्यों रीझ गयी, बताऊँ? अच्छा, देखो आँखोंकी बूँदोंका मूल्य देना बड़ा ही कठिन होता है- ये अनमोल होते हैं, इनका प्रतिदान होता ही नहीं। और तुम्हारी आँखोंसे वे ही बूँदें झर रही है। हाँ, कोई बिरला ही नयनोंकी इन बूँदोंका सुगुप्त रहस्य जान पाता है, इस अनमोल निधिकी महिमासे परिचित होता है और वह अपने दृगोंसे इन्हें बाहर लाकर इन्हें खो बैठनेकी भूल कभी नहीं करता। अपने-आप शरीरकी विस्मृति होकर जब ये पलकोंकी ओटसे झर पड़ती हैं, तब मैं स्वयं दौड़ पड़ती हूँ इनकी ओर। एक-एक बूँदका चयन कर लेती हूँ, कहीं भी देख लूँ मैं इन बूँदोंको ऐसा ही मेरा स्वभाव है। इतना ही नहीं, मैं तत्क्षण इन बूदोंसे एक अभिनव सुन्दर हारका निर्माण कर लेती हूँ-और मेरे प्राणवल्लभ नीलसुन्दरके उरःस्थलपर बूँदोंसे बने उस हारको स्थापित कर देती हूँ। इतने उल्लसित हो उठते हैं मेरे प्राणनाथ कि मुझे परिरम्भणके बन्धनमें बाँध लेते हैं और फिर क्षण बीतते-न-बीतते इस हारको मेरी ग्रीवामें झुला देते हैं। उस समय उनके करतल पर मेरा मस्तक अपने-आप झुक जाता है, प्रतिष्ठित हो जाता है। मैं विह्वल होकर रोने लगती हूँ। उस समय हम दोनोंके उस हँसने और रोनेका सुख केवल अनिर्वचनीय ही नहीं, वस्तुतः अचिन्त्य होता है। कौन समझ सकता है उस सुखकी गरिमाको ? कहना भी किससे क्या है ?॥ १०४७,१०४८,१०४९॥

इसलिये हे मिलिन्द ! आ! हा! हा! हा! कहो, बोलो- तुमने मुझे यह अनुपम भेंट जो दी है, यह भेंट देकर तुम मुझसे क्या लेना चाहते हो, क्या अभिलाषा है तुम्हारे चित्तमें? देखो सही, मैं सबकुछ लिये यहीं तुम्हारे सामने खड़ी हूँ। तुझे सच कहती हूँ-लेनेकी अपेक्षा निरन्तर देते रहनेमें ही मुझे अत्यधिक सुखका अनुभव होता है। केवल मेरा ही नहीं, मेरे प्रियतम नीलसुन्दरका स्वभाव भी ऐसा ही है। उनका, मेरा-दोनोंका ही स्वभाव चिरकालसे एक-सा ही है, भँवर !'॥ १०५०॥

सहसा भानुकिशोरीकी वाणी रुद्ध हो गयी। लज्जाका घन आवरण उनके श्रीअङ्गोंपर चारों ओर अभिव्यक्त हो गया; झुकी जा रही हैं भानुकिशोरी उसके भारसे। उन्हें प्रतीति हो रही थी-जो बात न कहनेकी थी, वह उनके मुखसे बरबस निःसृत हो गयी। पर अब क्या हो...... क्षणभरके लिये उनकी आँखें निमीलित हुईं और जब खुलीं, तब वे किंचित् सावधानीकी मुद्रासे भावित रहकर ही कहने लगे जाती हैं- 'भ्रमर ! तू सावधान रहना भला ! मेरे अङ्गोंकी महामलिन छायासे भी बचते रहना-भ्रमसे भी तू इसे मत छूना, रे! हाय! मैं कैसी हूँ, तुम्हें पता नहीं है। सच यह है, मुझे अपनी प्रशंसा बड़ी प्यारी लगती है और इसीलिये मैं स्वयं तुमसे केवल, केवल अपनी ही सुख्याति करती रही हूँ। तुम अत्यन्त निर्मल मति हो, मिलिन्द ! और इस कारण तुमने मेरी बातोंपर ज्यों-का-त्यों विश्वास किया है। मुझ ठगिनीकी ठगभरी सरलतासे तुम प्रभावित हो उठे और मेरे चरणोंके स्पर्शके लिये तुम अभी-अभी मेरी ओर दौड़े आ रहे थे- मुझ महामलिना अधमाके चरणोंको छूने दौड़ पड़े थे॥ १०५१,१०५२॥

तुम्हें सत्य, सत्य बतला दे रही हूँ, नीलसुन्दर प्राणनाथ प्रियतममें और मुझमें कितना अन्तर है। एक ओर उछलता हुआ सुधा-सिन्धु और दूसरी ओर एक छिल्लर की मलिन, अत्यन्त दुर्गन्धसे परिपूरित (गढैयाके) जलकी कणिका। एक ओर दिनकर और चन्द्रका किरण-दान, दूसरी ओर खद्योतके उड़ते समय उसके भुक्-भुक्से निःसृत प्रकाशका कण। एक ओर चिन्तामणि, दूसरी ओर मलसे सने टूटे काँचका एक मलिन खण्ड। इनमें परस्पर कितना अन्तर है, भ्रमर ! वैसे-के-वैसे मेरे प्राणवल्लभ नीलसुन्दरके शीलमें और मेरे शीलमें पृथकत्व निरन्तर प्रत्यक्ष प्रतिभासित मिलेगा तुमको। मेरे जीवनका कण-कण अभिलाषाओंके हाह्मकारसे परिपूरित है, मैं निरन्तर उनसे माँगती ही रही-कुछ-न-कुछ माँगती ही रही हूँ। लेती-लेती निरन्तर लेते रहनेपर भी मैं कभी श्रमित नहीं हुई और निरन्तर देते रहने पर भी वे श्रमित न हुए। इतनेपर भी सदा मैं उपालम्भ देती रही हूँ- 'मुझे तुमसे क्या मिला?' और उस ओर मेरे इस व्यंगके उत्तरमें वे सदा यही बोलते आये हैं- 'प्राणोंकी रानी ! मैं तुम्हें कुछ भी दे न सका।' मैं निरन्तर यही गर्व लिये रहती थी कि मैं प्रियतम नीलुसन्दरके लिये सब कुछ स्वाहा करके ही जीवन धारण कर रही हूँ और सदा ही गद्गद कण्ठसे वे यही कहते थे- 'अहा! मैं प्राणेश्वरी राधाके चरणसरोरुहमें हाय रे ! न्योछावर नहीं हुआ; धिक्कार है मुझे, शत-सहस्र धिक्कार है मेरे जीवनको ।'॥ १०५३,१०५४॥

'देखो सही, इस परिस्थितिमें मैं अधमा, लज्जाहीना, अपने प्राणवल्लभसे, नीलसुन्दरसे समता करने चली थी अपने शील-गुणकी, अन्य गुणोंकी। रसविद् मधुकर रे! मेरे द्वारा महान अपराधका ही सृजन हुआ। मेरी इस चेष्टासे क्यों नहीं होता? ऐसा होता ही। क्योंकि मैं सदासे दम्भ ही करती आयी हूँ। अब भी दम्भसे भरा ही मेरा जीवन है। क्षणभरके लिये स्वप्रमें भी मैं प्राणनाथ नीलसुन्दरको अपने अनाविल प्यारका एक कण भी न दे पायी।'॥ १०५५॥

भानुकिशोरी फूट-फूट करके रो रही हैं-और 'साँवर-साँवर' का स्वर निःसृत हो रहा है अधरपुटोंके अन्तरालसे। कभी अस्फुट स्वरमें यह भी कह उठती हैं- 'साँवर, साँवर प्रियतम हे! तुम मुझे एक वरदान दे दो-मेरे द्वारा किसीका कभी अपमान न हो, पर कैसे करूँ, प्राणवल्लभ साँवर ! तुम्हीं बताओ, इस भौंरेको मैं अपने चरण कैसे छूने दूँ? तुम्हें स्मरण है-रसमत्त हुए तुमने अपनी कुञ्चित अलकोंसे मेरे इन चरणोंको पोंछा था उस दिन, उस दिन। हाय रे! उन्हीं चरणोंको मैं भौंरेको कैसे छूने दूँ? पर भ्रमरका अपमान भी न हो, यह कैसे सम्भव है? कैसी असमंजसकी स्थिति है मेरी।'॥ १०५६॥

अनर्गल अश्रु-प्रवाहसे अपने कपोलोंको सिक्त करती हुई किशोरी अविराम भावसे कहती जा रही हैं-' भौरें! प्यारे मिलिन्द ! सुनो मेरे साथ घटित घटनाको मैं ज्यों-की-त्यों सुना दे रही हूँ तुमको। उस दिन प्रतिपदा की तिथि थी। अभी-अभी अपनी किरणोंको समेटकर दिनकर क्षितिजके उस पार गये ही थे-कलिन्दनन्दिनीका प्रवाह हम दोनोंके सम्मुख हिलोरें ले रहा था। मैं प्रत्यक्ष सचमुच सुन रही थी रे! भौंरा - सरिताकी लहरें मुझसे प्रार्थना कर रही थीं, माँग रही थीं कि निकुञ्जेश्वरी राधे! किंचित् और यहाँ तुम दोनों ठहर जाओ और मुझे दर्शनका सुखदान करो।....'

सहसा किशोरी भूल गयीं कि मैं भौरेसे बात कर रही हूँ और प्रत्यक्ष अनुभूतिके जालमें पड़कर ठीक-ठीक देखने लग गयीं- सामने मेरे प्राणनाथ नीलसुन्दर खड़े हैं और मैं तो उनसे ही बात कर रही हूँ- इस भावनामें डूबी हुई वे अविराम बोलती चली जा रही हैं-

'सुनते हो, प्राणवल्लभ ! ठीक-ठीक स्मरण कर लो प्रतिपदाकी उस संध्यावेलाको। श्यामा कल्लोलिनीकी लहरें मुझसे कह रही थीं कि ठहरो ! पर तुम कहते थे मुझसे कि प्रियतमे ! चलो, चलो। तिमिरसे परिपूरित यह रजनी है। सम्मुखका कान्तार भी अत्यन्त गहन है। बड़ी ही घोर है यह अटवी और यहाँसे उस ओरका पथ भी बड़ा बङ्किम है और मैं असमंजसमें पड़ी हुई थी, प्राणाधिक! कैसे करूँ, क्या करूँ ? तुममें तो अत्यधिक त्वरा भरी थी; बड़ी शीघ्रता थी मुझे यहाँसे वहाँ ले जानेकी और मनुहारभरी आँखोंसे कलिन्दनन्दिनीकी लहरें बूँदें उछाल उछाल करके बाध्य कर रही थीं मुझे वहीं ठहरे रहनेके लिये। मैं उनकी विनती अनसुनी कर दूँ या किंचित् और ठहर जाऊँ- यह प्रश्न था मेरे सामने। तुम हँस रहे थे, पर मैं चिन्तामें पड़ी थी। कुछ देर रुककर मैं तुमसे बोल उठी थी- प्रियतम! तुम बड़ी शीघ्रता करते हो! इतनी जल्दीकी आवश्यकता क्या है? और सच तो यह है कि तुम मुझे ठग रहे हो, मुझसे मिथ्या कह रहे हो। देखो! यह तो शुक्ला रजनी है। मैं उस क्षण भूल गयी थी, प्रियतम ! कि वस्तुतः तिथि तो भाद्रपद कृष्णा प्रतिपदाकी है और मैं तुमसे कह रही थी कि यह शुक्ल पक्षकी निशा है।'......॥ १०५७, १०५८॥

अब किशोरी अपना दक्षिण कर-सरोज आगे बढ़ाकर इस प्रकारकी मुद्राका प्रदर्शन कर बैठी मानों वे अपने प्राणनाथ नीलसुन्दरके कर-सरोजको स्पन्दित कर रही हों, उन्हें सावधान कर रही हों। साथ ही अधरोंपर यह मधुस्यन्दी स्वर एक अभिनव उल्लासकी गरिमा लेकर व्यक्त हो रहा था 'तो मैंने तुम्हें कहा था-जल्दी क्या करना है? शुक्ल पक्षकी निशा है यह। देखो, प्राचीमें शशधर, बस, आनेवाला ही है। और क्या? वह आये, मत आये, मुझे तो तुम्हारा यह श्यामल मुख ही निरन्तर प्रकाश देता ही रहेगा। जब तुम निरन्तर मेरे साथ हो, तब मुझे इस वनका क्या भय है, प्राणनाथ !....रससे परिपूरित मीठी-मीठी बातें तुम मुझे सुनाते रहना और हँस-हँस करके मुझे गलबाहीं दिये, हाँ, हाँ, हाँ, हाँ, मेरी ग्रीवामें यह अपना वाम मृदुल कर-सरोज डाले हँस-हँस करके आगे चलते रहना। यहाँ एक वनदेवी रहती हैं, वह हम दोनोंके लिये नवीन सुन्दर-से-सुन्दर पथका निर्माण कर देंगी और यहाँसे सीधे, सीधे, सीधे चलकर हम दोनों अपने निकुञ्ज-गृहमें पहुँच ही जायेंगे।'॥ १०५९,

१०६०॥

पुनः अविराम हँसने लग जाती हैं किशोरी, सर्वथा उन्मादिनीकी भाँति । फिर मानो एक बार प्रियतम नीलसुन्दरके दक्षिण कर-सरोजको झकझोर दे रही हों, इस मुद्रामें अपने बाँये हाथको चञ्चल करके कहने लगती हैं-'तो क्या प्रतिक्रिया हुई थी मेरी उक्तियोंकी तुमपर ? अरे रे, तुम कितने चतुर हो, प्रियतम ! तुम्हें तो मुझे ले चलनेकी त्वरा थी ही और कैसी मुद्रा बनायी थी तुमने उस समय। सर्वथा भय-विजड़ित मुद्रामें तुम मुझे निहारते हुए कह रहे थे-मेरे प्राणोंकी रानी! हे! अरे राम ! एक बड़ा ही भयंकर सर्प यहाँ रहता है-यहीं तो, जहाँ हम दोनों अभी खड़े हैं इस समय, बस, इसी धराके ऊपरके व्योममें रहता है, भला, पर छिपकर रहता है, अथवा इस धरामें ही धँसकर रहता है, धरामें समाया रहता है। कोई निर्णीत स्थान नहीं है उसका। इतना मायावी है वह उरग कि जिसकी मायाको कोई बिरला ही जीते तो जीत सकता है और देखो प्राणेश्वरी! संयोगकी बात, उस मायावी सर्पके पानी पीनेका यही समय है और यहीं इसी घाटपर पानी पीता है। कितना भयंकर है वह-तुमसे बतला देता हूँ। उसकी छाया पड़ते ही बेहोशी आ जाती है और ऐसी बेहोशी कि शत-सहस्र हकीम वैद्य हार जायँ, पर वह बेहोशी दूर होनेकी नहीं। इसीलिये प्राणाधिके ! उसके यहाँ आनेके पहले ही हम लोग इस प्रवाहसे दूर चले जायँ, कलिन्दनन्दिनीके प्रवाहसे दूर चले जायँ। लहरियोंका खेल तो कंभी किसी अन्य दिन देख लेंगे। क्यों व्यर्थ इतना भयंकर, इतना विकट संघर्ष इस सर्पसे हम लेने चलें। और बिल्कुल सत्य है, कहीं वह आ गया और तुम्हें डसनेके लिये दौड़ा तो तुम तो डर जाओगी- भागेंगे कैसे ?....आ हा हा! प्राणनाथ! कैसे चतुराई थी तुम्हारी ? पर मैं तो सदाकी हठीली ही ठहरी। हँसने लग गयी थी मैं तुम्हारी बात सुनकर और बोली थी- अच्छा, मैं भी देखना चाहती हूँ प्रियतम ! कि आखिरमें वह सर्प है तो कैसा है। मुझे तो केवल इतना ही बतला दो-वह प्राचीकी ओरसे आयेगा या प्रतीचीकी ओरसे, उत्तरकी ओरसे या दक्षिणकी ओरसे ? धरा-भेदन करके आयेगा अथवा व्योमपथसे ? आयेगा यदि वह तो अपनी तृषा शान्त करने आयेगा या हमारा सुख-अपहरण करने आयेगा? और इतना कहकर मैं हँस रही थी और वहीं बैठ भी गयी थी। तुम खड़े-खड़े हँस रहे थे॥ १०६१,१०६२,१०६३,१०६४॥

दो पलोंके अनन्तर तुम्हारी बङ्किम चितवन उत्तरकी धराकी ओर केन्द्रित हुई और मुझे एक स्थल विशेषकी ओर संकेत कर तुम बोले थे- जीवनेश्वरी ! देखो यह धरा कुछ फटती-सी दीख रही है। सम्भव है, इसी पथसे आ जाय। तुम्हारी उक्ति पूरी भी न हो पायी थी कि सचमुच एक अतिशय महाकाय कृष्णवर्ण विषधर फण काढ़े धराके उस छिद्रसे बाहर निकल आया। अरे ! मैं तो डरकर तुमसे चिपट गयी थी। कितना भयंकर वह सर्प था, पर तुम तत्क्षण कह उठे थे-प्राणेश्वरी! बिलकुल भय मत करो। मेरे प्राणोंकी रानीकी छायाको भी यह नहीं छू सकता, तुम्हें तो क्या छू सकेगा। किन्तु प्रियतमे ! यहाँ तुम चञ्चलतासे विरत हो जाना। कोई-सी चपलता मत कर बैठना; देखो, मेरा रंग भी काला और यह सर्प भी पूरा काला-कलूटा है। इस सर्पके मनमें यह बात आ गयी है मेरे लिये कि मैं उसका प्रतिपक्षी हूँ- ऐसा ही सोच रहा है यह कपटी-और इसीलिये मुझसे डर रहा है। देखो, प्राणेश्वरी ! जो स्वयं काला और टेढ़ा होता है, उसे काले और टेढ़ेसे ही भय होता है। और देखो ! तुम तो गौरवर्णा हो और अत्यन्त सरला भी हो; इसको तुमसे भय बिल्कुल नहीं लगेगा, अतः तुम तो बस, मुझसे सम्बद्ध रहना। तनिक भी हटना मत, भला !॥ १०६५, १०६६,१०६७॥

प्राणरमण! जलसे पूरित तुम्हारे उन नयन-सरोजोंको मैं भूल नहीं पाती, जिस समय तुम मुझे 'गोरी', 'सरला' सम्बोधित करके एकटक निहार रहे थे। प्राणवल्लभ ! प्राणोंके ऐसे संवेदन ही मेरी एकमात्र निधि हैं- कैसे-कैसे हैं वे, कितने सुन्दर वे हैं, कैसे तुम्हें बताऊँ? जो हो, सुनो, प्रियतम ! मैं अपलक होकर उस अहिको निहार रही थी, किंतु ओह! सहसा मुझे अनुभूति हुई, ऐसी प्रतीति मुझे होने लगी कि उसके उस विकराल मुखमें तुम ही, मेरे प्राणनाथ नीलसुन्दर ही विराजित हो रहे हो। इतना ही नहीं, प्राणाधिक ! तुम्हारे अधर पल्लवोंपर जो यह चिर-परिचित स्मित निरन्तर विराजित रह ता है, वह भी मुझे उस सर्पके मुखमें अवस्थित श्रीविग्रहके अधरोंपर ज्यों-का-त्यों निलीन-सा आभास हो रहा था, मानो वह अभी-अभी-तुरन्त विकसित हो उठेगा। मेरी आँख वहाँ केन्द्रित हुई ही थी कि दूसरे ही क्षण उस भुजंगकी आँखोंमें, काली परछाहीं-सी, तुम्हारे इन त्रिभंग अङ्गोंकी मुद्राके दर्शन होने लगे।

कैसी अप्रतिम सुन्दर सलोनी मुद्रा थी प्राणवल्लभ ! तुम्हारी उस भुजङ्गमकी आँखोंमें। और अब दो पल बीतते-न-बीतते विषधरके अङ्गोंके कण-कणमें ही, उसके सम्पूर्ण अवयवोंमें ही एकमात्र तुम्हीं, नीलसुन्दर ही, मेरे प्राणनाथ ही अभिव्यक्त हो उठे। मेरी आँखोंमें चञ्चल तुम्हीं; तुम्हीं वहाँ झलमल करते दीख रहे थे॥ १०६८, १०६९,१०७०॥

आश्चर्यमें डूबी हुई थी कि यह कैसे, क्यों संघटित हुआ। एक क्षणमें तुम्हें निहारती और दूसरे क्षण मेरी आँखें उस भुजंगपर केन्द्रित होती। और उस महा उरगके हृद्देशमें तो तुम प्रत्यक्ष यों-के-यों खड़े दीख रहे थे। मैं सोचने लग गयी थी कि यह अनुभूति सत्य है अथवा कोई अद्भुत स्वप्न तो मैं नहीं देख रही हूँ।......॥ १०७१॥

इतनेमें तुम्हारा मधुमय स्वर मेरे कानोंमें पड़ा। तुम मुझे कह रहे थे-मेरे असंख्य प्राणोंके प्राण ! देखो, क्रीड़ा तो हँस-हँस करके देख लो, भला ! पर आगे मत बढ़ जाना, सर्पकी ओर एक पद भी अग्रसर न हो जाना। क्या पता यह दुर्दमन महासर्प झपट पड़े और अपने विषमय दो दाँतोंसे तुम्हें डस ले। हाय रे ! फिर मेरे जीवनका क्या होगा ? तनिक अनुमान लगा लो सही उस विषम परिस्थितिका। मैं तो सर्वथा विमूढ़ हो गयी थी, प्रियतम! मेरे लिये यह भूल-भूलैयाका-सा खेल बन गया था। आखिर मैंने तुमसे सारी बात बतला दी-जो भी, जैसे मुझे अनुभव हो रहा था उस महा भुजंगमके तनमें। तुम हँस पड़े थे और तुमने कहा था- प्रियतमे ! तुमने मेरे ऊपर अपार करुणा की है, तुम मुझे अपनी दृगपुतरियोंमें ही निरन्तर निवास दिये रहती हो। इसीका परिणाम है कि तुम्हें महासर्पके स्थानपर मैं अनुभूत हो रहा हूँ, किंतु प्राणवल्लभे ! अब तो शीघ्र से शीघ्र हमलोग भाग चलें। अरे! यह विषधर तो मेरे समान बली बन गया है। तुमने इसपर अपनी आँखें डाल दीं, इसके कण- कणमें मुझको परिपूरित कर दिया। मेरा सम्पूर्ण बल उसमें चला गया और अब यह विषधर अत्यन्त दुर्धर्ष हो गया है। अतएव प्राणधिके! बस, चलो, अविलम्ब यहाँसे चलें। मेरी बात मान लो, प्राणवल्लभे ! इतना बलवान बन गया है यह सर्प कि यदि यह हम दोनोंपर पीछेसे टूट पड़े तो मैं इसका कर ही क्या लूँगा? बड़ी भारी भूल तुमने कर दी। बस, अब तो एक ही उपाय बचा है!- मैं तुम्हें अंकमें उठा लूँ और फिर इतनी तीव्र गतिसे भागूँ कि यह हम दोनोंको छू ही न सके। बस ! प्राणवल्लभ ! मैं सुन तो रही थी तुम्हारी बातोंको बड़े ध्यानसे, किंतु अब एक नवीन चिंताने मुझे आ घेरा। मैं सोचने लगी-कदाचित् यह महाविषधर फिर भी हम दोनोंका पिंड न छोड़े और दुर्दैववश कहीं इसके दौड़नेकी गति तुम्हारी अपेक्षा अधिक तेज हो जाय और उस परिस्थितिमें यह तुम्हारी नीली पीठपर क्षत लगा दे, तुम्हें काट खाय-धीरेसे ही काट ले, मायावी जो ठहरा, यह कोई-सी माया रच दे, तब मैं तो इन बातोंको जान नहीं पाऊँगी और तुम मुझे बतानेसे रहे कि तुम्हें सर्पने काट खाया है.....॥ १०७२,१०७३,१०७४,१०७५,१०७६॥

मैं इस प्रकार बहुत से उपायोंसे चिन्तनमें डूब-सी गयी, बहुत-सी बातें सोच रही थी। इतनेमें ही मेरे कानोंमें भयंकर फुफकारकी ध्वनि आयी और मैं सिहर उठी। साथ ही तुम तुरंत बोल उठे- ओहो, ओहो !! प्राणवल्लभे !! अब तो इसका रोष मेरे ही प्रति हो गया, भला! तुमने कुछ देर कर दी, अब तो इसके साथ भिड़ना ही पड़ेगा। इससे युद्ध लेना ही होगा मुझे॥ १०७७॥

तुम यह कहते जा रहे थे और अपने दुकूलको कटिमें कसते जा रहे थे, साथ ही तुम्हारे अधरोंपर एक अभिनव हास्य भी था। उस समय अचानक मेरे मनमें आया कि देखूँ सही, इस सर्पमें आखिर कितना बल है, मैं अबला अवश्य हूँ, किंतु मेरे भीतर-बाहर तुम तो निरन्तर विराजित हो ही। मेरा यह सर्प कर ही क्या सकेगा ? यदि मैं ही इसपर लपक पडूँ तो! कुछ भी अनिष्ट मेरा नहीं कर सकता यह सर्प-तुम, तुम, तुम, तुम मेरे साथ हो। तुम्हीं, तुम्हीं तो मुझे कह रहे हो कि मेरे द्वारा ही इसे बल मिला है, मेरे निमित्तसे यह बलवान बना है। इसके बलका उद्गम स्थल मेरी आँखें है। और फिर, भले मेरा भ्रम ही हो, पर मुझे दीख तो रहे हैं ये मेरे प्राणवल्लभ ही निरन्तर इसके अन्तरालमें। किंतु यदि मैं अपने मन का निश्चय इन्हें बतला देती हूँ, तब तो ये मुझे रोक लेंगे। आगे बढ़ने नहीं देंगे। चुपचाप अचानक मैं इसके सामने चली जाती हूँ और देखती हूँ कि क्या, कैसी वस्तु यहाँ है? क्या करता है मेरा यह ? प्राणनाथ ! उसके और मेरे बीचमें केवल साथ हाथका ही अन्तर था-मुझसे वह सर्प केवल सात हाथकी दूरी पर ही अवस्थित था। मैं क्षणभर तुम्हारे मुखसरोजको निहारती रही और फिर विद्युत्वेगसे उसके आगे उछल पड़ी, सर्वथा निकट-से-निकट जा पहुँची और बोल उठी कि अरे! तुझे जो करना है, कर ले। मैं सम्मुख खड़ी हूँ, अगर तू सचमुच सर्प है तो मुझे काट खा और नहीं तो यह मात्र भ्रमजाल है।......॥ १०७८,१०७९,१०८०॥

एक क्षणके लिये मेरी आँखें मुँद गयीं और तुम तो मेरे पीछे विराजित थे ही, तुमने अपनी भुजाओंमें मुझे भर लिया- मुझे ऐसी अनुभूति हो रही थी प्राणनाथ ! फिर भी मैने तुरंत आँखें खोल लीं और तुमसे बोली कि प्राणनाथ ! सर्प कहाँ गया? मैं चकित होकर देख रही थी, किंतु कहीं सर्प दीख जो नहीं रहा था और तुम, तुम अपने दृगसरोजकी धारासे मेरी अलकोंको सिक्त कर रहे थे। न जाने कब, कैसे मैं तुम्हारे अङ्कमें आसीन हो गयी थी और तुम्हारा अनर्गल अश्रुप्रवाह मेरे कुन्तलोंको आर्द्र कर रहा था.....॥ १०८१॥

जीवनसर्वस्व ! उस समय हम दोनोंका क्या हाल था, कैसी अभिनव अद्भुत विह्वलता थी-इसे तुम स्मरण कर लो, प्राणवल्लभ ! और मैं तो इसे मनमें ही रख लूँगी, इसे प्रकट नहीं करूँगी। क्या किससे कहना है......!'

अचानक भानुकिशोरी मानो भाव-समाधि-से जग, दृष्टि घुमाकर देखने लग जाती हैं और उन्हें भान होने लग गया है कि वे बात तो कर रही हैं अपने प्राणवल्लभ नीलसुन्दरसे, पर एक भ्रमर भी वहीं संनिकट देशमें ही बैठा है और उससे भी कुछ बातें कर चुकी हैं वे। उनकी मुद्रा क्षण-क्षणमें बदलती है, अङ्ग-भङ्गिमामें प्रतिपल परिवर्तन होता जा रहा है। कभी वे सामने खड़े हुए प्राणदेवताको निहारकर हँसने लगती हैं और कभी भ्रमरकी ओर दृष्टिपात कर मौन धारण कर लेती हैं। पाँच-सात पल इस स्थितिमें ही अवस्थित रहकर फिर कह उठती हैं- 'प्राणवल्लभ ! क्या, किससे कहनी है उस स्थितिकी बात और यह भ्रमर तो उसे क्या समझ पायेगा। हाँ, तुममें मुझमें यदि अपने प्राणोंको मिला दे सके, तो भले ही जान ले यह, हम दोनोंकी उस स्थितिको....॥ १०८२॥

मेरे प्राणरमण ! तुम्हें स्मरण होगा- मैं विकल हो उठी थी इतना-सा कहकर ! मुझे स्पष्ट प्रतीत हो रहा था कि भौंरा पुनः रोने लग गया है, इसलिये न चाहनेपर भी उसे कुछ कह देने चली थी मैं। अपने मनकी जो बात मैं प्रकट नहीं करना चाहती थी, उस बातका किंचित् अंश उसे बतला देने चली थी। यद्यपि बड़ी लज्जा लग रही है मुझे प्रियतम......।'

अचानक भानुकिशोरीको अनुभव हुआ कि वह कुछ असम्बद्ध प्रलाप कर रही हैं और उनका भ्रम है, जो वे अपने प्राणवल्लभको प्रत्यक्ष वहीं विराजित देख रही हैं। उनकी आँखें पुनः निमीलित होती हैं और वे सोचने लगती हैं कि कोई दूत आया है, उसे मैं संदेश दे रही हूँ। आधे क्षण इस भावनामें, इस प्रतीतिमें वे डूब जाती हैं और फिर नवीन क्षणका उन्मेष होते-न-होते अपने प्राणवल्लभसे ही रसमयी चर्चामें तन्मय हो जाती हैं और कुछ पलोंमें प्राबल्य हो जाता है प्राणवल्लभकी अवस्थितिका ही तथा कहने लग जाती हैं किशोरी-प्राणवल्लभ ! बड़ी लज्जा लग रही है मुझे उस सर्पके इतिवृत्तको कहनेमें। अच्छा, और तो कोई है नहीं, तुमसे ही तो कह रही हूँ। तुम सुनना चाहते हो, इसलिये कह रही हूँ-तो सुनो- कल्पनासे परे उस कालका कितना परिमाण व्यतीत हो चुका था, जब हम लोगोंकी वह भाव समाधि शिथिल हुई थी, इसे कौन बताये, तुम्हीं जानो। सर्प कहाँ चला गया, इसका उत्तर तुम मुझे दे रहे थे। कैसी मधुस्यन्दिनी गिरा थी तुम्हारी ! तुमने यही तो कहा था-प्राणवल्लभे ! प्राणप्रियतमे ! देखो! जिन महाभावमयी आँखोंमें मैं निरन्तर बसा हुआ हूँ, जिन आँखोंकी रसधारासे पाषाण विगलित हो जाता है, पावक शीतल हो जाता है, जो नयन-सरोरुह अतीत, वर्तमान एवं भविष्यके दृश्योंमें निरन्तर स्वभावसे ही रसमय सागरका निर्माण करते रहते हैं- रससागरको उच्छलित बनाते रहते हैं, उन्हीं आँखोंमें रमा हुआ, उनकी अप्रतिम गरिमामें सना हुआ, उनसे ही प्रेरित होकर तो मैं उस महाविषधरके कलेवरमें संनिविष्ट किया गया था। अतएव वह महाभुजंगम यदि गल गया, विगलित हो गया तो उसमें आश्चर्य ही क्या है, मेरे असंख्य प्राणोंकी प्राण राधे !......और वहाँ उस महा उरगके स्थानपर काला रंगमात्र बच गया तुम्हें उरमें भरनेके लिये तो अचरजकी कौनसी बात है ? प्रियतमे ! अधिक क्या कहूँ, मेरा कंठ अवरुद्ध हो रहा है॥ १०८३,१०८४,१०८५॥

प्रियतम ! उसके पश्चात् जो घटना घटी थी, उसे भी स्मरण कर लो-न जाने कौन-सा उद्दीपन पाकर श्यामा कल्लोलिनी बड़े वेगसे उच्छलित हो उठी थी-लहरें हम दोनोंके चरणोंको प्रक्षालित करने लगी थीं और दूसरे ही क्षण मैंने देखा था-वह समुज्ज्वल वर्ण रेणुका मेरे पदतलमें आकर लिपट गयी थी। मैंने स्पष्ट सुना था, प्राणधन ! उसे ठीक-ठीक ऐसा कहते दम्पति हे! क्या तुम मुझे यहीं छोड़कर चले जाओगे? और उस समय तुम्हारी आँखें ऊपरकी ओर उठ रही थीं-सम्भवतः तुम कालका अनुमान लगा रहे थे। उचित ही था। हिमकर अपनी किरणोंका वितान तान रहा था ठीक हम दोनोंके मस्तकपर। अस्तु,॥ १०८६॥

मैं अत्यन्त व्यथित हो उठी थी, प्राणवल्लभ ! रेणुकाकी उस प्रार्थनाकी मुद्रामें की हुई उक्तिको स्मरण कर और बिना सोचे-समझे मैं मन-ही-मन कह गयी थी-कोई भी हो, कैसी भी हो, जो एकबार मुझसे जुड़ चुकी, उसे तो मैं कदापि छोडूँगी ही नहीं, उसकी आशा मैं क्यों तोडूँ ? तुम, तुम, साँवर मेरे प्राणप्रियतम! तुम मेरे ही हो, मेरे ही थे, मेरे ही रहोगे। मैं तुम्हें जो भी कह दूँगी, वही तुम तत्क्षण कर ही लोगे, फिर मैं भला, क्यों किसीको कभी क्षणभरके लिये भी निराश करूँ? नहीं-नहीं, मुझसे ऐसा हो नही सकता और यह रेणुका तो अभीतक मेरे पदतलमें ज्यों-की-त्यों लिपटी पड़ी है। अहा! कितनी मृदुला है यह, कितनी हल्की है यह, इसका हृदय कितना निर्मल है-उज्ज्वल है और देखो सही- यह मेरे लिये ही तो, मेरे लिये ही तो अपने चेतन-भावपर आवरण डालकर, अपना अपनपा मिटाकर सर्वथा जड़ बनकर यहाँ कलिन्दनन्दिनीके प्रवाहमें, प्रवाहके परिसरमें पड़ी रहती है। मैं आऊँगी और इस रेणुकाके वक्षःस्थलपर चरण रखकर चलूँगी। कहीं, कोई क्षत मेरे पदतलमें न लग जाय, मेरे सुखके लिये इतना त्याग इस रेणुकाने किया है-मात्र इसे इतना ही सुख है कि मेरे पदतलमें कोई पीड़ा न हो जाय और इसीलिये चेतनताको जलाञ्जलि देकर जड़ताको वरण किया है इसने। अरे! मैं तो साँवर, मेरे प्राणवल्लभ, तुम, तुम, तुम-नीलसुन्दरकी दासी हूँ न प्राणनाथ ! और इसीलिये कैसे सम्भव था मेरे लिये कि मैं रेणुकाकी इर निष्ठाको भूल जाऊँ। बस, इसी भावमें बहकर मैं कह बैठी थी मन-ही-मन हे धूलि ! तेरा परम मङ्गल हो, मेरे प्राणवल्लभ नन्दनन्दन तुझे स्वीकार कर लें।'........॥ १०८७,१०८८॥

'प्राणनाथ! मेरी आँखें भर आयी थीं उस समय और मैं भी अपने अश्रु छिपानेके उद्देश्यसे आकाशकी ओर देखने लग गयी थी कि कहीं वे बाहर व्यक्त न हो जायँ। और तब मुझे भी भान हुआ था कि सचमुच बड़ी देर हो गयी है-श्यामा प्रवाहिणीके विलासको देखते-देखते - सरिताके तटपरकी क्रीड़ाको देखते-देखते। इसीलिये मैं तुमसे बोली थी- हे मेरे श्यामचन्द्र ! मैं तुम्हारी सम्पूर्ण क्रीड़ाओंका स्वागत करती हूँ। पर मेरी आँखें अब भी व्योममें विराजित चन्द्रकी ओर थीं। मैं अन्योक्तिके छद्ममें मानों चन्द्रसे बातें कर रही थी, ऐसे बोल रही थी- हे नीलचन्द्र ! हे नीलमयङ्क ! मैं तुम्हारी किरणोंका स्वागत करती हूँ। तुम यहाँ अविराम सबको शीतलताका ही दान करना। फिर मैं तुम्हें रास-नृत्य दिखलाऊँगी। वास्तवमें मैं कह रही थी तुमसे ही और कह रही थी यह-प्राणवल्लभ ! तुमने जो मुझे महाभुजंगमकी लीला दिखलायी, उसका तो मैं स्वागत करती हूँ, किंतु जैसे तुम लहरोंकी मनुहार न माननेके लिये प्रेरणा दे रहे थे, वैसा न करना, भला! किसीके हृदयको न तोड़ना भला ! तभी तो मैं तुम्हें अपना निरावरण लास्य दिखाकर तुम्हारा मनोरञ्जन कर पाऊँगी, प्राणवल्लभ !.....॥ १०८९॥

और यह कहकर मैं तुरन्त चल पड़ी थी। ठीक-ठीकर स्मरण करो, ऐसे ही हुआ था न? जो हो, गलबाही दिये तुम मुझे आगे-आगे ले चल रहे थे। कुछ अत्यन्त रसीली बात कहकर हँस देते और सचमुच-सचमुच प्राणनाथ! तुम्हारी हँसीसे एक किरण-सी बिखर जाती थी और किरणें पुष्पके रूपमें परिणत हो जाती थीं। मेरे आगे पुष्पोंका आस्तरण आस्तृत हो जाता था, सुमनमय पथ बन जाता था। मैं उसपर आनन्दमें विभोर अग्रसर हो रही थी तुम्हारे वाम पार्श्वमें, तुम्हारे अनाविल प्यारमें अभिषिक्त होकर। पर अचानक मुझे दीखा था-तुम अपने चरण उन कुसुमोंपर नहीं रख रहे हो, अपितु दोनों ही पद ठीक-ठीक कुसुमोंको बचा-बचा करके रेणुकापर ही रखते जा रहे थे। मैं अचरजमें डूबकर तुमसे पूछ बैठी थी-ऐसा क्यों कर रहे हो प्राणनाथ! प्रियतम !! और तुम भी तत्क्षण उत्तर दे बैठे थे- मुझे अपनी उस चेष्टाका हेतु बतलाया था-प्राणवल्लभे ! यह रजःकणिका मुझे प्राणके समान प्यारी है। अहो ! जब दयामयी तुमने यह इच्छा कर ली, यह चाह लिया कि रजः कणिका मेरे साथ चलें, तब फिर मैं इनका त्याग कैसे कर सकता था ? अपितु मेरे मनमें तो उसी क्षण यह संकल्प जाग्रत हो उठा था कि मैं जहाँ रहूँगा, वहीं ये भी रहेंगी ही। तुम्हारी चित्तधारामें इन्हें साथ रखनेकी वृत्ति उत्पन्न होते ही मेरे अन्तस्तलमें यह संकल्प उदित हो गया था, प्राणवल्लभे! मैं सोचने लग गया था-अहा! कितनी महा-महा-महिमामयी हैं ये रजः कणिकाएँ! और अहो! देखो, ये तो मेरे प्राणोंकी रानीके पदमें चिपक गयी हैं। मेरी प्राणेश्वरी राधाके चरण-सरोरुहोंको इन्होंने अपने वक्षःस्थलपर धारण कर लिया है। अहो! इन अपरिसीम सौभाग्यशालिनी रजः कणिकाओंको मैं भला इसके बदले दे ही क्या सकता हूँ। मेरे पास है ही क्या? मैं नित्य इनका ऋणिया बना ही रहूँगा। इनके ऋणका परिशोध मेरे लिये तो असम्भव है॥ १०९०,१०९१॥

प्राणाधिक ! तुम्हारी प्रीतिकी गरिमासे पूरित इस उक्तिको सुनकर मैं फू फू करके रो उठी थी। मेरे लिये अब आगे पद-विन्यास करना बड़ा ही कठिन हो गया था। जड़िमा मानो सब ओरसे मुझे आवृत किये जा रही थी। फिर भी जैसे-तैसे तटिनी निकुञ्जोंमें तुम्हारे सहयोगसे पहुँच ही गयी और पद्मोंसे निर्मित शय्यापर जाकर लेट गयी, किंतु तुम मेरे चरणोंके समीप आकर बैठ गये ।....

गद्गद कण्ठसे तुम कह रहे थे- प्रियतमे ! मुझे भी यह एक दान दे दो-मैं भी अपने हृदयमें एक चिर लालसा सँजोये प्रतीक्षा कर रहा हूँ- मेरे भी आकुल प्राणोंकी अभिलाषा है कि मैं अपनी अलकोंसे तुम्हारे इन चरण-सरोरुहोंको पोंछ-पोंछ करके निरवधि असमोर्ध्व सौभाग्यशाली और सुखी बना रहूँ। प्राणेश्वरी राधाके चरणसरोरुहोंपर एकमात्र मेरा ही स्वत्व रहे -इन्हें केवल वे ही स्पर्श कर सकें- स्पर्श करें, जिनका मन, जिनकी बुद्धि, जिनकी अहंता ठीक-ठीक मेरे. समान ही, मेरे समान जलसम कृष्णवर्णताको धारण कर लें और अविराम इन्हें रससिक्त रखें॥ १०९२,१०९३॥

प्राणनाथ ! अतिशय लज्जामें मैं डूब गयी थी। सोच न पा रही थी-क्या उत्तर दूँ मैं तुमको। उसी क्षण मेरे प्राणोंकी ऐकान्तिक लालसा-एकमात्र अभिलाषा प्राणोंके अन्तरालमें हिलोरें लेने लगी। मैं मन-ही-मन इन भावनाओंकी आवृत्ति करने लग गयी थी- प्राणाधिक! जीवनसर्वस्व ! तुम्हें जिसमें सुख हो, तुम वही कर लो। बस, मैं उसीमें, उसमें ही सुखका अनुभव करती हूँ, करती थी, करूँगी। जीवनधन ! मैं तुम्हें कभी, किसी भी प्रसङ्गको लेकर म्लान नहीं देख पाऊँ- मेरी आँखें तुम्हारे मुखसरोजपर म्लानताकी क्षीण-से-क्षीण कोई-सी रेखातक कभी न देख पायें। मेरे सम्पूर्ण तनका-तनके प्रत्येक रोमका, मेरे मनका, मेरे चित्तका, मेरी बुद्धिका कण-कण, अणु-अणु, परमाणु-परमाणु रहे एकमात्र तुम्हारे लिये प्रतिपल नवीनसे नवीन सुखका सृजन करनेके लिये ही। इनका अस्तित्व रहे ही एकमात्र तुम्हें सुखदानके लिये॥ १०९४॥

प्राणाधिक ! मेरे प्राणोंका यह स्पन्दन मेरी पलकोंपर तुम्हें सुस्पष्ट अभिव्यक्त दीख रहा था। तुमने ही यह बात मुझे पीछे कही थी और उन्हीं भाव-भावित पलकोंसे तुमने अनुमति ले ली थी तथा अपने सुरभित कुन्तलोंसे मेरे चरणोंका संलालन करने लगे तुम। हम दोनोंको यह भान भी न हो सका था कि रजनीका विराम कब हो गया है.....।'

भानुकिशोरीके भाव-सिन्धुमें अचानक एक अतिशय वेगवान उच्छलनका आविर्भाव हुआ और उन्मादिनीकी भाँति वे सुन्दरी सरोवरकी उमड़ती हुई जलराशिकी ओर भाग चलीं। सहोदराने उन्हें अपने भुज-पाशमें आवृत कर लिया और बीस-तीस पलतक भानुनन्दिनी मूर्च्छामें निमग्न पड़ी थीं। सर्वत्र नीरवताका साम्राज्य था......।

और जब इस भाव समाधिका क्षणिक विराम हुआ, तब भानुकिशोरी किंचित् प्रकृतिस्थ-सी दीख पड़ रही थीं और निमीलित नेत्रोंसे ही मानो किसी भ्रमरको स्मरण कर कह रही हों- ऐसी मुद्रामें बोल उठीं- 'मधुकर ! तुम्हीं बतलाओं, मेरी इस परिस्थितिपर गम्भीर विचार करके तुम न्याय करना, भला ! और फिर निर्णय देना.... हाय रे! क्या कहूँ, मधुप ! इसीलिये, इसीलिये उन कुन्तलोंसे मार्जित मेरे इन चरणोंपर एकमात्र मेरे प्राणधन नीलसुन्दरका ही स्वत्व है। वे ही इन्हें स्पर्श करनेका अधिकार-दान कर सकेंगे। मधुप ! इसीलिये, इसीलिये मेरी विनम्र विनती, अत्यन्त मनुहारभरी विनतीको मान लो, तुम मेरे चरणोंका स्पर्श मत करो.....।'॥ १०९५॥

भानुकिशोरीकी उत्पल-दल-सी आँखें इस अन्तिम उक्तिके समय, 'स्पर्श मत करो' कहते समय आधे क्षणके लिये उन्मीलित हुई थीं अवश्य, किंतु पुनः निमीलित हो गयीं- यद्यपि वाणीसे अविराम भावसे अगणित रस-पूरित बातें कहती ही जा रही थीं, पर उनकी, उनकी उन महाभावमयी परम पावन उक्तियोंको केवल, केवल वे ही सुन सकीं, जो अपना सर्वस्व स्वाहा करके उनके चरण-सरोरुहपर न्योछावर हो चुकी थीं; जो मरु-मरीचिकाके जल-बुदबुदसे मोहित थीं या हैं, वे सुन ही कैसे पातीं !॥ १०९६॥

पाटल-दलों सदृश भानुनन्दिनीके होठोंका स्पन्दन इस दिनकरने अवश्य देखा है। यह निर्लिप्त व्योम विमुग्ध बना अपने हृदयमें उस ध्वनिको सँजोये अवस्थित है। उसे स्पर्श करके अनिल आज भी चञ्चल है और नीरमें सरसताका संचार वह ध्वनि आज भी कर ही रही है। धराने ध्वनिकी सहिष्णुता-उसके सर्जककी सहिष्णुताके अन्तरालसे व्यक्त होते हुए सौरभको छिपा लिया है अपने अन्तस्तलमें; किंतु इनका अनुभव करने आज कौन आ रही है, कौन आ रहा है ?॥ १०९७॥

दो दण्डकी पूर्ण नीरवता (स्वगत नीरवता) के अनन्तर महाभावकी पुत्तलिका मानो पुनः स्पन्दित हुई और वीणाके तारोंकी अपेक्षा भी अत्यन्त सुमधुर, मधुरातिमधुर स्वर निःसृत होने लगा- 'मैं अनर्गल क्या-क्या बक गयी; सचमुच विक्षिप्त हो गयी हूँ मैं; एक ओर यह षटपद् रो रहा है और मैं इसे कथा सुना रही थी। ओह! मिलिन्द रे !! मत रो। बतला दे-अपना हृदय खोलकर मेरे सामने रख दे। मैं तेरी सम्पूर्ण व्यथा हर लूँगी। क्या करूँ ?' कुछ क्षणोंके लिये किशोरी ध्यानस्थ हो गयीं, पर पुनः इस बार उन्मादका मानो एक नवीन झोंका आया और उसी प्रवाहमें उड़ती हुई वे बोलने लग गयीं- 'मिलिन्द तो कुछ भी बतलाता नहीं। अच्छा तो मैं अपने प्राणवल्लभनीलसुन्दरसे पूछ लेती हूँ इसके मनकी बात। वे तो मुझे बता ही देंगे...।

एक पल बीतते-न-बीतते भानुकिशोरी उच्च स्वरसे हँस पड़ीं और बोलीं-भ्रमर रे! मैं तो जान गयी तुम्हारे गुप्त मनोरथको; वह तो तुम्हें दे ही देती हूँ तथा किंचित् और भी अपनी रुचिसे दे रही हूँ॥ १०९८,१०९९,११००॥

देखो मिलिन्द ! तुम इस तुलसी-काननकी द्रुम-वल्लरियोंसे तादात्म्य लाभकर लो। प्राणवल्लभ नीलसुन्दरकी दासी मुझ राधाकी भुज-वल्लरियोंमें तुम्हारा अस्तित्व एकान्तिक भावसे पर्यवसित हो जाय। मेरे प्राणधन नीलदेवताका अपरिसीम सुखमय सांनिध्य तुम्हें नित्य-निरन्तर उपलब्ध रहे! इतना ही नहीं, और सुनो, मैं तुम्हें वरदान दे रही हूँ- इस सच्चिन्मय अरुणिम कंचुकीके बंदोंमें बँधी हुई राग-बहुला भावलहरियोंकी सत्ता-उस सत्तासे अनुप्राणित सच्चिन्मयी श्यामल अनुरक्ति आत्मसात् किये रहे तुम्हें निरवधि.... निरवधि।'॥ ११०१॥

भानुनन्दिनीको अपने शरीरकी विस्मृति हो गयी और उस अवस्थामें कटे कदली-स्तम्भकी भाँति धरापर गिरकर गम्भीर मुर्च्छामें समा गयी वे....... भानुकिशोरीका सिर अपने अङ्कमें धारण किये उनके मुख-सरोजको अनर्गल अश्रु-प्रवाहसे सिक्त करके ललिता बोल उठीं- दूत ! क्षणभरके लिये इसे तुम अवश्य दीखे थे; तुम्हें लक्ष्य करके यह कुछ शब्द बोल भी गयी थी; फिर भावममयी विस्मृतिका उन्मेष हुआ इसमें। इस तमालको ही प्राणप्रियतम साँवरके रूपमें अनुभव करने लगी यह और फिर इसकी आँखें तुमपर केन्द्रित हुईं तो अभिनव उन्मादमें यह सोचती थी तुम्हारे ही माध्यमको लेकर-मेरे प्राणवल्लभ नीलसुन्दर हैं? नहीं-नहीं मयूर है? नहीं-नहीं भौंरा है। और भ्रमरसे, तुमसे अपने उरः स्थलका भाव खोलकर बतला गयी। इसने अपनी जानमें मधुकरको वरदान दिया है, पर तुम इसे अपने लिये ही मान लो, भला ! साँवरके दूत !! साँवरके सखा !!! यह वरदान अक्षरशः सत्य होगा, मैं ललिता कह रही हूँ- मेरी उक्ति कभी मिथ्या नहीं होती.....।

मूच्छित हो गयी ललिता सुन्दरी भी। दूतकी आँखोंसे झर-झर अश्रुकी धारा प्रसरित हो रही है। एक अभिनव अद्भुत उन्मादका उन्मेष हो गया उसमें। दो दण्डतक अविराम लोटता ही रहा है वह धराकी उस रजमें, जहाँ अभी-अभी भानुकिशोरीके चरण टिके हैं और सहसा भाग छूटता है वह मधुपुरीकी ओर सर्वथा उन्मत्त दशामें। मेरे प्राणाधिक! यह समस्त इतिवृत्त तुम्हें ज्ञात है ही। तथापि मैंने इसे तुम्हें फिरसे थोड़ा-सा सुना दिया है॥ ११०२,११०३,११०४,११०५॥

उस पुरातन वटवृक्षके नीचे सोयी बाला राधा किशोरीका स्वप्न टूटनेपर वह जाग पड़ी और उठकर चल पड़ी। उसके चरण यों लड़खड़ा रहे थे मानो उसने कोई मद पी रखा हो। फिर उसे अनुभव हुआ मानो प्रियतम श्यामसुन्दर आकर उसके गलेमें बाहें डालकर उसे कह रहे हों- 'प्रियतमे ! उस सरोवरकी लहरोंका खेल देखने चलते हैं।'॥ ११०६॥

अब फिरसे राधाकिशोरी ललिता कुञ्जमें आकर विराजित हो गयी हैं। हे प्रियतम ! तुम भी उसे बाहु-बन्धनमें लिये अवस्थित हो। इस अवस्था में भी वह अपने स्वप्नलोकमें ही विचरण करती हुई देख रही हैं- एक ऐसा अश्वत्थ वृक्ष है, जिसकी जड़े ऊपरकी ओर तथा शाखाएँ नीचे फैली हैं। वह बाला राधाकिशोरी उसके नीचे अर्चन कर उसे शिक्षा दे रही है॥ ११०७॥

हे प्रियतम श्यामसुन्दर ! यह रहस्य मुझे तुमने ही बताया है कि सर्वत्र तुम-ही-तुम लीलायमान हो अथवा राधा-ही-राधा है; फिर तुम नित्य हम दोनोंके रूपोंमें भी लीला कर रहे हो। यह मेरी अहंता प्रतिमा-राधाकी मायामें प्रतिबिम्बित हो रही है, किन्तु बिम्बसे भिन्न छायाकी सत्ताका होना कैसे सम्भव है ?॥ ११०८॥

निरवधि राधारमणकी जय हो, अम्बुजनयनकी सदा जय हो, नन्दनन्दनकी सतत जय-जय-जय हो, निरन्तर मेरे प्राणनाथ प्रियतमकी जय हो, सर्वदा गोपिकाप्राणकी जय हो, मन्मथमथनकी जय हो, चिरकालतक विश्वरंजनकी जय हो, जय हो, अहर्निश मेरे प्रियतम श्रीकृष्णकी जय हो।

राधा-वनविहारी तथा राधा-कुञ्जविहारीकी जय हो, घुँघराले केशोंसे सुशोभित मुरलीधरकी जय हो, प्रियतमा राधाके नयनोंमें विहार करनेवाले विहारिणी राधाके भावोंमें आनन्द सरसाने वाले श्रीकृष्णकी जय हो॥ ११०९॥

मेरी यह वाणी उसी भाँति नाचती रही, जिस भाँति रसराज श्रीकृष्ण इसे नचाते रहे। मेरी रसनाकी गाँठ अनन्त कालतक उन्हीं नीलसुन्दरसे ही बँधी है। यह महाभाव लीला उसी भाँति होगी, जैसी वे कराना चाहेंगे। अहो! यशोदानन्दनकी जय हो, मोहनकी जय हो, वनमालीकी जय हो॥ १११०॥

प्राणाधिक श्रीकृष्णकी जय हो, कुञ्जजनेश्वरकी जय हो, कुजेश्वरी राधाकी जय हो, जय हो, प्राणेश्वरी राधिकाकी जय हो !॥ ११११ क॥

हे प्राणाधिक श्रीकृष्ण ! कुञ्जजनेश्वरकी जय हो! हे मेरे प्राणाधिक श्रीकृष्ण कुञ्जजनेश्वरकी जय हो॥ ११११ ख॥

''');
      }
    }

    // --- षोडश गीत (Topic 5) ---
    else if (sectionId == 'topic5') {
      switch (title) {
        case 'वंदना':
          return const _TopicPageContent(
            imagePaths: [],
            body: '''
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
            body: '''
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
          return const _TopicPageContent(body: '''##(श्लोक)

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
          return const _TopicPageContent(
              body:
                  '''**छन्द १०२ से ११० तक-** प्रतिदिन १० माला पाठ--- जीवनकी सन्ध्याके पूर्व अवश्य-अवश्य चिन्मय गिरिपरिसर एवं गिरिराजका दर्शन।

## (विशेष मंत्र)
**उस ओर शैलके कण-कणमें मानो चेतनता थी प्रियतम !**
**वह खड़ा सतत देखा करता ऊँचा सिर किये हुए, प्रियतम !**
-प्रतिदिन १० माला भावसहित पाठ--- चिन्मय गिरिपरिसर एवं गिरिराजका दर्शन।

## (विशेष मंत्र)
**जीवनकी धारा किधर मुड़े, भावी क्या है किसकी, प्रियतम !**
**सच्चा प्रतीक इसका वह था, आदर वे सब करतीं, प्रियतम !**
-प्रतिदिन १० माला भावसहित पाठ--- परमार्थकी ओर जीवनधारा मोड़नेके लिये विशेष मंत्र

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
          return const _TopicPageContent(body: '''
**छन्द २०६-** प्रतिदिन १० माला भावसहित जप--- पूर्ण जीवन निश्चय ही मंगलमय बन जायेगा।

## (विशेष मंत्र)
**'अप्रतिम यहाँ कोई मंगल निश्चय होगा, सखि री, प्रियतम !'**
---किसी भी कार्यकी मङ्गलमय संपन्नताके लिये इस मंत्रकी दस माला जप करें।

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
          return const _TopicPageContent(body: '''
**छन्दः ३३४ से ३६१तक-** प्रतिदिन १० माला भावसहित पाठ--- जीवनकी संध्याके पूर्व सख्यरस-प्रधान तत्सुखिया-भावकी प्रतिष्ठा। श्रीदाम भैयाके दर्शन एवं मृत्युके पश्चात् उनमें प्रतिष्ठा। 

## (विशेष मंत्र)
**संदेश    एक    है    श्रीपदमें   उन  नीलदेवताका,  प्रियतम !**
**सेवा न बनी कुछ भी  सचमुच, अरसिक मुझ किंकरसे, प्रियतम !**
**अपनी  ही  ओर  देख   उरमें  अविचल  निवास  देना, प्रियतम !**
**है नहीं मनोभ्रम,  सच्ची   है  घटना  सब  इस  वनकी, प्रियतम !**
**माला  है  झूल   रही   उरपर,  झूलेगी   नित्य  तथा,  प्रियतम !**
*****
**बोला 'श्रीपदमें  प्रणति  सरस  उनकी  पल पल शत है, प्रियतम !**
**है   और  विनम्र  निवेदन  यह,  उनके  अन्तस्तलका,  प्रियतम !**
**'प्रियतमे,  रखो,  धीरज  मुझसे अब नित्य खिलन होगा, प्रियतम !**
**जय हो ! जय हो ! निरवधि जय हो ! श्रीचरणसरोरुहकी, प्रियतम !**

--इन मंत्रोंकी दस मालाके जपसे प्रियतम नीलसुन्दर ब्रजेन्द्रनन्दनसे नित्य अविच्छिन्न मिलनका विधान।''');

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
    } else if (sectionId == 'topic7') {
      switch (title) {
        case '(क)योऽहं    ममास्ति    यत्किञ्चिदिह   लोके   परत्र  च।':
          return const _TopicPageContent(imagePaths: [], body: '''## **समर्पण**
**योऽहं ममास्ति यत्किञ्चिदिह लोके परत्र च।**
**तत्सर्वं कृष्ण ते नाथ पादपद्मे समर्पितम् ।।**

जो मैं हूँ, मेरा जो कुछ है- लोक और परलोक सभी।
कर अर्पित चरणोंमें तव मैं हुआ पूर्ण कृतकृत्य अभी ।।
 


**योऽहं ममास्ति यत्किञ्चिद् विश्वेऽस्मिन्मद् निर्मितम् ।**
**राधे प्राणेशि तत्सर्वं त्वत्पादयोः समर्पितम् ।।**

जो मैं हूँ, जो कुछ है जगमें दृश्यरूप मेरा निर्माण।
हे प्राणेशि राधिके, सब तव चरण-समर्पित लेना जान।।



**योऽहं ममास्ति यत्किञ्चिद् विश्वं मच्छासनाश्रितम् ।**
**राधे प्राणेशि तत्सर्वं त्वत्पादयोः समर्पितम् ।।**

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
**कहते हो तुम, फिर क्यों न चलें, खेलें, हो गयी देर, प्रियतम !''');

        case '(ख)मो इच्छित  कै  कृस्न पिय,  रुचै  बनिउ,  बनराउ।':
          return const _TopicPageContent(imagePaths: [], body: '''## (दोहा)

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



प्रियतम श्रीकृष्णका उत्तर-
**है सदा तुम्हारा ही सुख बस, मेरा तो सुख प्रियतमे ! अहो !**
**मैं कर दूँगा अवश्य पूरी प्रत्येक चाह, निश्चिन्त रहो !**
**हम सभी अभिन्न निरन्तर हैं, फिर भी जो रुचि हो, तुरत कहो।**
**हे महाभावमयि ! हमें लिये, रस-सुधा-सिन्धुमें नित्य बहो।।''');

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
इसलिये बनी बैठी हूँ मैं गूँगी एवं बहरी प्रियतम !''');

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



**अग्रज के सद्दृश अनुज तन से जिनका नाता था हे प्रियतम ।**
**वे पहुँचेंगे ही नित्य जहाँ कान्हा गाता था हे प्रियतम ।।**



**इसीलिये विश्वास, किये रहो अविचल अहो ।**
**व्रजपुर नित्य निवास, कुंज-स्थल पर दृग रहें॥**
**उपवन के उस पार हम सब ही मिल जायेंगे**
**माया सरित कगार पर मिलने में हानि है।**''');

        case '(ड़)साँवर-साँवर ही  आगे हैं,  साँवर  ही पीछे हैं, प्रियतम !':
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
चिरकाल विश्वरञ्जन जय जय, जय कृष्ण अहर्निश, हे प्रियतम !''');

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
