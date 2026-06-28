// lib/providers/favourites_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/books_data.dart';

class Bookmark {
  final int bookIndex;
  final int pageIndex;
  final String? sectionId;
  final String? sectionTitle;
  final String? topicTitle;
  final List<String> topics;

  const Bookmark({
    required this.bookIndex,
    required this.pageIndex,
    this.sectionId,
    this.sectionTitle,
    this.topicTitle,
    this.topics = const [],
  });

  bool get isTopicBookmark => sectionId != null || topicTitle != null;

  String get bookTitle =>
      isTopicBookmark ? (sectionTitle ?? 'Topic') : BooksData.all[bookIndex].title;
  String get pageTitle =>
      isTopicBookmark ? (topicTitle ?? '') : BooksData.all[bookIndex].pages[pageIndex].title;

  Map<String, dynamic> toJson() => {
        'b': bookIndex,
        'p': pageIndex,
        if (sectionId != null) 'sid': sectionId,
        if (sectionTitle != null) 'st': sectionTitle,
        if (topicTitle != null) 'tt': topicTitle,
        if (topics.isNotEmpty) 'topics': topics,
      };

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        bookIndex: (j['b'] as num?)?.toInt() ?? 0,
        pageIndex: (j['p'] as num?)?.toInt() ?? 0,
        sectionId: j['sid'] as String?,
        sectionTitle: j['st'] as String?,
        topicTitle: j['tt'] as String?,
        topics: (j['topics'] as List?)?.whereType<String>().toList() ?? const [],
      );

  @override
  bool operator ==(Object o) =>
      o is Bookmark &&
      o.bookIndex == bookIndex &&
      o.pageIndex == pageIndex &&
      o.sectionId == sectionId &&
      o.topicTitle == topicTitle;

  @override
  int get hashCode => Object.hash(bookIndex, pageIndex, sectionId, topicTitle);
}

class FavouritesProvider extends ChangeNotifier {
  List<Bookmark> _items = [];
  List<Bookmark> get items => List.unmodifiable(_items);

  FavouritesProvider() {
    _load();
  }

  bool isSaved(int b, int p) => _items.any((x) => x.bookIndex == b && x.pageIndex == p);

  bool isTopicSaved(String? sectionId, String topicTitle) =>
      _items.any((x) => x.sectionId == sectionId && x.topicTitle == topicTitle);

  void toggle(int b, int p) {
    final bm = Bookmark(bookIndex: b, pageIndex: p);
    if (_items.contains(bm)) {
      _items.remove(bm);
    } else {
      _items.add(bm);
    }
    _save();
    notifyListeners();
  }

  void toggleTopic({
    required String? sectionId,
    required String sectionTitle,
    required String topicTitle,
    required List<String> topics,
    required int topicIndex,
  }) {
    final bm = Bookmark(
      bookIndex: -1,
      pageIndex: topicIndex,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      topicTitle: topicTitle,
      topics: List<String>.unmodifiable(topics),
    );
    if (_items.contains(bm)) {
      _items.remove(bm);
    } else {
      _items.add(bm);
    }
    _save();
    notifyListeners();
  }

  void remove(Bookmark bm) {
    _items.remove(bm);
    _save();
    notifyListeners();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('bookmarks');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      // Validate indices before loading to prevent crashes
      _items = list
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .where((bm) =>
              bm.isTopicBookmark ||
              (bm.bookIndex >= 0 &&
                  bm.bookIndex < BooksData.all.length &&
                  bm.pageIndex >= 0 &&
                  bm.pageIndex < BooksData.all[bm.bookIndex].pages.length))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('bookmarks', jsonEncode(_items.map((x) => x.toJson()).toList()));
  }
}
