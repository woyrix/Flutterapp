import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/reader_provider.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF150800) : const Color(0xFF250E00),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: GoogleFonts.notoSerifDevanagari(color: Colors.white, fontSize: 16),
              cursorColor: cs.primary,
              decoration: InputDecoration(
                hintText: 'इस ग्रंथ में खोजें…',
                hintStyle: GoogleFonts.notoSerifDevanagari(
                    color: Colors.white38, fontSize: 15),
                prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          context.read<ReaderProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: cs.primary.withOpacity(0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: cs.primary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              onChanged: (q) {
                setState(() {});
                context.read<ReaderProvider>().setSearchQuery(q);
              },
            ),
          ),

          if (reader.searchQuery.isNotEmpty)
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: reader.results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text('कोई परिणाम नहीं मिला।',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 13)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: reader.results.length,
                        itemBuilder: (ctx, i) {
                          final r = reader.results[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.article_outlined,
                                color: cs.primary.withOpacity(0.7), size: 18),
                            title: Text(r.pageTitle,
                                style: GoogleFonts.notoSerifDevanagari(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(r.snippet,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white38),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            onTap: () {
                              context
                                  .read<ReaderProvider>()
                                  .navigateTo(r.bookIndex, r.pageIndex);
                              context.read<ReaderProvider>().toggleSearch();
                            },
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
