import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/books_data.dart';
import '../providers/reader_provider.dart';
import '../utils/book_search.dart';

class BrowseSearchScreen extends StatefulWidget {
  const BrowseSearchScreen({super.key});

  @override
  State<BrowseSearchScreen> createState() => _BrowseSearchScreenState();
}

class _BrowseSearchScreenState extends State<BrowseSearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = context.read<ReaderProvider>().searchQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openParagraph(SearchResult result) {
    context.read<ReaderProvider>().navigateTo(
          result.bookIndex,
          result.pageIndex,
          paragraphIndex: result.paragraphIndex,
          paragraphNumber: result.paragraphNumber,
        );
    Navigator.of(context).pop();
  }

  void _openBrowseItem(
    int bookIndex,
    int pageIndex,
    int paragraphIndex,
    String? paragraphNumber,
  ) {
    context.read<ReaderProvider>().navigateTo(
          bookIndex,
          pageIndex,
          paragraphIndex: paragraphIndex,
          paragraphNumber: paragraphNumber,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final book = reader.currentBook;
    final cs = Theme.of(context).colorScheme;
    final textStyle = GoogleFonts.notoSerifDevanagari;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'पद खोजें',
                      locale: const Locale('hi', 'IN'),
                      style: textStyle(
                        color: cs.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'बंद करें',
                    icon: const Icon(Icons.close_rounded),
                    color: cs.primary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: TextField(
                controller: _controller,
                autofocus: false,
                textInputAction: TextInputAction.search,
                style: textStyle(fontSize: 16, color: cs.onBackground),
                decoration: InputDecoration(
                  hintText: 'इस ग्रंथ में खोजें...',
                  hintStyle: textStyle(
                    fontSize: 15,
                    color: cs.onBackground.withOpacity(0.45),
                  ),
                  filled: true,
                  fillColor: cs.surface.withOpacity(0.72),
                  prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'साफ करें',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            context.read<ReaderProvider>().setSearchQuery('');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: cs.primary.withOpacity(0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: cs.primary.withOpacity(0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: cs.primary, width: 1.3),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {});
                  context.read<ReaderProvider>().setSearchQuery(value);
                },
              ),
            ),
            Expanded(
              child: reader.searchQuery.trim().isEmpty
                  ? _BrowseList(
                      bookIndex: reader.bookIndex,
                      book: book,
                      onTap: _openBrowseItem,
                    )
                  : _SearchResultsList(
                      results: reader.results,
                      onTap: _openParagraph,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final ValueChanged<SearchResult> onTap;

  const _SearchResultsList({
    required this.results,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = GoogleFonts.notoSerifDevanagari;

    if (results.isEmpty) {
      return Center(
        child: Text(
          'कोई परिणाम नहीं मिला।',
          locale: const Locale('hi', 'IN'),
          style: textStyle(
            fontSize: 15,
            color: cs.onBackground.withOpacity(0.55),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outline.withOpacity(0.25),
      ),
      itemBuilder: (context, index) {
        final result = results[index];
        final paragraphLabel = result.paragraphNumber == null
            ? ''
            : '  (${BookSearch.toAsciiDigits(result.paragraphNumber!)})';

        return ListTile(
          leading: Icon(Icons.article_outlined, color: cs.primary),
          title: Text(
            '${result.pageTitle}$paragraphLabel',
            locale: const Locale('hi', 'IN'),
            style: textStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _HighlightedSnippet(
              text: result.snippet,
              match: result.matchedText,
            ),
          ),
          onTap: () => onTap(result),
        );
      },
    );
  }
}

class _BrowseList extends StatelessWidget {
  final int bookIndex;
  final BookData book;
  final void Function(
    int bookIndex,
    int pageIndex,
    int paragraphIndex,
    String? paragraphNumber,
  ) onTap;

  const _BrowseList({
    required this.bookIndex,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: book.pages.length,
      itemBuilder: (context, pageIndex) {
        return _BrowsePageTile(
          key: PageStorageKey('browse-page-$bookIndex-$pageIndex'),
          bookIndex: bookIndex,
          pageIndex: pageIndex,
          page: book.pages[pageIndex],
          pageLabel: _pageLabel(pageIndex, book.pages[pageIndex].title),
          onTap: onTap,
        );
      },
    );
  }

  String _pageLabel(int pageIndex, String fallback) {
    const labels = [
      'प्रथम शतक',
      'द्वितीय शतक',
      'तृतीय शतक',
      'चतुर्थ शतक',
      'पंचम शतक',
      'षष्ठम शतक',
      'सप्तम शतक',
      'अष्टम शतक',
      'नवम शतक',
      'दशम शतक',
      'एकादश शतक',
    ];
    if (pageIndex < labels.length) return labels[pageIndex];
    return fallback;
  }
}

class _BrowsePageTile extends StatefulWidget {
  final int bookIndex;
  final int pageIndex;
  final BookPage page;
  final String pageLabel;
  final void Function(
    int bookIndex,
    int pageIndex,
    int paragraphIndex,
    String? paragraphNumber,
  ) onTap;

  const _BrowsePageTile({
    super.key,
    required this.bookIndex,
    required this.pageIndex,
    required this.page,
    required this.pageLabel,
    required this.onTap,
  });

  @override
  State<_BrowsePageTile> createState() => _BrowsePageTileState();
}

class _BrowsePageTileState extends State<_BrowsePageTile>
    with AutomaticKeepAliveClientMixin<_BrowsePageTile> {
  late final List<BookParagraph> _paragraphs;
  bool _expanded = false;

  @override
  bool get wantKeepAlive => _expanded;

  @override
  void initState() {
    super.initState();
    _paragraphs = BookSearch.paragraphsForPage(
      widget.bookIndex,
      widget.pageIndex,
      widget.page,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final textStyle = GoogleFonts.notoSerifDevanagari;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.only(bottom: 10),
      iconColor: cs.primary,
      collapsedIconColor: cs.primary,
      maintainState: true,
      onExpansionChanged: (value) {
        setState(() {
          _expanded = value;
        });
        updateKeepAlive();
      },
      title: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.primary.withOpacity(0.22),
              thickness: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 0,
            child: Text(
              widget.pageLabel,
              textAlign: TextAlign.center,
              locale: const Locale('hi', 'IN'),
              style: textStyle(
                color: cs.primary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: cs.primary.withOpacity(0.22),
              thickness: 0.8,
            ),
          ),
        ],
      ),
      children: _expanded
          ? [
              for (final paragraph in _paragraphs)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                  title: Text(
                    '(${paragraph.displayNumber}) ${paragraph.firstLine}',
                    locale: const Locale('hi', 'IN'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle(fontSize: 13.5, height: 1.35),
                  ),
                  onTap: () => widget.onTap(
                    widget.bookIndex,
                    widget.pageIndex,
                    paragraph.paragraphIndex,
                    paragraph.number,
                  ),
                ),
            ]
          : const [],
    );
  }
}

class _HighlightedSnippet extends StatelessWidget {
  final String text;
  final String match;

  const _HighlightedSnippet({
    required this.text,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseStyle = TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: cs.onBackground.withOpacity(0.65),
    );
    final highlightStyle = baseStyle.copyWith(
      color: cs.onPrimary,
      backgroundColor: cs.primary.withOpacity(0.82),
      fontWeight: FontWeight.w700,
    );
    final lower = text.toLowerCase();
    final target = match.toLowerCase();
    final index = target.isEmpty ? -1 : lower.indexOf(target);

    if (index < 0) {
      return Text(
        text,
        locale: const Locale('hi', 'IN'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return RichText(
      locale: const Locale('hi', 'IN'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + match.length),
            style: highlightStyle,
          ),
          TextSpan(text: text.substring(index + match.length)),
        ],
      ),
    );
  }
}
