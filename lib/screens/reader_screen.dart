import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/books_data.dart';
import '../providers/app_provider.dart';
import '../providers/reader_provider.dart';
import '../utils/book_search.dart';
import '../utils/text_formatting.dart';
import '../widgets/formatted_hindi_text.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int? _lastPrewarmBookIndex;
  int? _lastPrewarmPageIndex;

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final savedFontSize =
        context.select<AppProvider, double>((p) => p.fontSize);
    final book = reader.currentBook;
    _schedulePrewarm(book, reader.bookIndex, reader.pageIndex);

    return PageView.builder(
      controller: reader.pageController,
      physics: const BouncingScrollPhysics(),
      allowImplicitScrolling: true,
      itemCount: reader.totalPages,
      onPageChanged: reader.onSwipedToPage,
      itemBuilder: (context, index) {
        final page = book.pages[index];
        return _PageBody(
          bookIndex: reader.bookIndex,
          title: page.title,
          content: page.content,
          savedFontSize: savedFontSize,
          pageIndex: index,
          totalPages: reader.totalPages,
          active: index == reader.pageIndex,
          targetParagraphIndex:
              index == reader.pageIndex ? reader.targetParagraphIndex : null,
          targetParagraphNumber:
              index == reader.pageIndex ? reader.targetParagraphNumber : null,
          onReadingHeaderChanged:
              index == reader.pageIndex ? reader.setReadingHeaderActive : null,
        );
      },
    );
  }

  void _schedulePrewarm(BookData book, int bookIndex, int pageIndex) {
    if (_lastPrewarmBookIndex == bookIndex &&
        _lastPrewarmPageIndex == pageIndex) {
      return;
    }
    _lastPrewarmBookIndex = bookIndex;
    _lastPrewarmPageIndex = pageIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BookSearch.prewarmAround(book, bookIndex, pageIndex);
    });
  }
}

class _PageBody extends StatefulWidget {
  final int bookIndex;
  final String title;
  final String content;
  final double savedFontSize;
  final int pageIndex;
  final int totalPages;
  final bool active;
  final int? targetParagraphIndex;
  final String? targetParagraphNumber;
  final ValueChanged<bool>? onReadingHeaderChanged;

  const _PageBody({
    required this.bookIndex,
    required this.title,
    required this.content,
    required this.savedFontSize,
    required this.pageIndex,
    required this.totalPages,
    required this.active,
    this.targetParagraphIndex,
    this.targetParagraphNumber,
    this.onReadingHeaderChanged,
  });

  @override
  State<_PageBody> createState() => _PageBodyState();
}

class _PageBodyState extends State<_PageBody>
    with AutomaticKeepAliveClientMixin<_PageBody> {
  late final ScrollController _scrollController;
  List<GlobalKey> _paragraphKeys = const [];
  String? _lastScrolledTarget;
  int _targetScrollAttempts = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _syncParagraphKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
  }

  @override
  void didUpdateWidget(covariant _PageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _syncParagraphKeys();
      _lastScrolledTarget = null;
    }
    if (oldWidget.targetParagraphIndex != widget.targetParagraphIndex ||
        oldWidget.targetParagraphNumber != widget.targetParagraphNumber) {
      _targetScrollAttempts = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncParagraphKeys() {
    final paragraphs = BookSearch.paragraphsForPage(
      widget.bookIndex,
      widget.pageIndex,
      BookPage(title: widget.title, content: widget.content),
    );
    _paragraphKeys = List.generate(paragraphs.length, (_) => GlobalKey());
  }

  void _scrollToTarget() {
    if (!mounted) return;
    if (widget.targetParagraphIndex == null &&
        widget.targetParagraphNumber == null) {
      return;
    }
    final paragraphs = BookSearch.paragraphsForPage(
      widget.bookIndex,
      widget.pageIndex,
      BookPage(title: widget.title, content: widget.content),
    );
    final target = _resolveTargetIndex(paragraphs);
    final targetKey =
        '${widget.pageIndex}:${widget.targetParagraphNumber}:$target';
    if (target == null ||
        target < 0 ||
        target >= _paragraphKeys.length ||
        _lastScrolledTarget == targetKey) {
      return;
    }

    final context = _paragraphKeys[target].currentContext;
    if (context == null) {
      _retryTargetScroll();
      return;
    }

    _lastScrolledTarget = targetKey;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _retryTargetScroll() {
    if (_targetScrollAttempts >= 8) return;
    _targetScrollAttempts += 1;
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
    });
  }

  int? _resolveTargetIndex(List<BookParagraph> paragraphs) {
    final number = widget.targetParagraphNumber;
    if (number != null) {
      final byNumber = paragraphs.indexWhere((p) => p.number == number);
      if (byNumber >= 0) return byNumber;
    }
    return widget.targetParagraphIndex;
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: TextFormatting.displayPlainText(widget.content)),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: const Text('पृष्ठ का पाठ कॉपी हो गया'),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final paragraphs = BookSearch.paragraphsForPage(
      widget.bookIndex,
      widget.pageIndex,
      BookPage(title: widget.title, content: widget.content),
    );

    return GestureDetector(
      onTap: () => context.read<ReaderProvider>().hideSlider(),
      onLongPress: () => _copy(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: cs.background,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical) {
              widget.onReadingHeaderChanged
                  ?.call(notification.metrics.pixels > 8);
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  locale: const Locale('hi', 'IN'),
                  softWrap: true,
                  textAlign: TextAlign.center,
                  strutStyle: const StrutStyle(
                    fontSize: 13,
                    height: 1.28,
                    forceStrutHeight: true,
                  ),
                  style: GoogleFonts.notoSerifDevanagari(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                    letterSpacing: 0,
                    wordSpacing: 0,
                    color: cs.primary,
                  ), // letterSpacing removed
                ),
                const SizedBox(height: 6),
                _Divider(color: cs.primary),
                const SizedBox(height: 10),
                if (widget.active)
                  ValueListenableBuilder<double>(
                    valueListenable:
                        context.read<AppProvider>().fontSizePreview,
                    builder: (context, previewFontSize, _) =>
                        _buildParagraphs(context, paragraphs, previewFontSize),
                  )
                else
                  _buildParagraphs(context, paragraphs, widget.savedFontSize),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParagraphs(
    BuildContext context,
    List<BookParagraph> paragraphs,
    double fontSize,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          _HighlightedParagraph(
            key: i < _paragraphKeys.length ? _paragraphKeys[i] : null,
            highlighted: _isTargetParagraph(paragraphs[i], i),
            child: FormattedHindiText(
              text: paragraphs[i].text,
              primaryColor: cs.primary,
              style: formattedHindiBodyStyle(
                context,
                fontSize: fontSize,
                height: 1.72,
              ),
            ),
          ),
          if (i != paragraphs.length - 1) SizedBox(height: fontSize * 0.45),
        ],
      ],
    );
  }

  bool _isTargetParagraph(BookParagraph paragraph, int index) {
    final number = widget.targetParagraphNumber;
    if (number != null && paragraph.number == number) return true;
    return number == null && widget.targetParagraphIndex == index;
  }
}

class _HighlightedParagraph extends StatelessWidget {
  final bool highlighted;
  final Widget child;

  const _HighlightedParagraph({
    super.key,
    required this.highlighted,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: highlighted
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: highlighted ? cs.primary.withOpacity(0.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: highlighted
            ? Border.all(color: cs.primary.withOpacity(0.32), width: 0.8)
            : null,
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: color.withOpacity(0.25), thickness: 0.7)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('•',
            style: TextStyle(
                color: color.withOpacity(0.5),
                fontSize: 16)), // 👈 Clean dot instead of star
      ),
      Expanded(child: Divider(color: color.withOpacity(0.25), thickness: 0.7)),
    ]);
  }
}
