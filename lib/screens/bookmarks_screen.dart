// lib/screens/bookmarks_screen.dart
//
// FIX — Bookmark navigation no longer causes a black screen.
// Pattern: Navigator.pop() the BookmarksScreen, then Navigator.pop() the
// Drawer (if still open), THEN update the provider.
// We let the caller (AppDrawer) decide how many pops to do, and just expose
// a callback.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/favourites_provider.dart';
import '../providers/reader_provider.dart';
import 'topic_section_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  void _closeToDrawer(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<FavouritesProvider>();
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: favs.items.isEmpty
            ? _Empty(cs: cs)
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: favs.items.length,
                separatorBuilder: (_, __) =>
                    Divider(color: cs.outline, height: 1),
                itemBuilder: (context, i) {
                  final bm = favs.items[i];
                  return ListTile(
                    leading: Icon(Icons.bookmark_rounded, color: cs.primary),
                    title: Text(bm.bookTitle,
                        style: GoogleFonts.notoSerifDevanagari(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: Text(bm.pageTitle,
                        style: GoogleFonts.notoSerifDevanagari(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6))),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: cs.onSurface.withOpacity(0.35)),
                      onPressed: () => favs.remove(bm),
                    ),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      if (bm.isTopicBookmark) {
                        navigator.pushReplacement(_slide(TopicSectionScreen(
                          topics: bm.topics.isEmpty
                              ? [bm.topicTitle ?? bm.pageTitle]
                              : bm.topics,
                          initialIndex: bm.pageIndex,
                          sectionId: bm.sectionId,
                          sectionTitle: bm.sectionTitle,
                        )));
                      } else {
                        navigator.pop();
                        context.read<ReaderProvider>().navigateTo(
                              bm.bookIndex,
                              bm.pageIndex,
                            );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

Route _slide(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: a, child: child),
      ),
    );

class _Empty extends StatelessWidget {
  final ColorScheme cs;
  const _Empty({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bookmark_border_rounded,
            size: 68, color: cs.primary.withOpacity(0.25)),
        const SizedBox(height: 16),
        Text('No bookmarks yet',
            style: GoogleFonts.notoSerifDevanagari(
                fontSize: 20,
                color: cs.onBackground.withOpacity(0.45))),
        const SizedBox(height: 8),
        Text('Tap the ribbon icon while reading',
            style: TextStyle(
                fontSize: 13, color: cs.onBackground.withOpacity(0.3))),
      ]),
    );
  }
}
