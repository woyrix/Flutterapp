import 'package:flutter/material.dart';
import '../data/books_data.dart';

class SearchResult {
  final int bookIndex;
  final int pageIndex;
  final String bookTitle;
  final String pageTitle;
  final String snippet;

  const SearchResult({
    required this.bookIndex,
    required this.pageIndex,
    required this.bookTitle,
    required this.pageTitle,
    required this.snippet,
  });
}

class ReaderProvider extends ChangeNotifier {
  int _bookIndex = 0;
  int _pageIndex = 0;
  bool _searchActive = false;
  bool _sliderActive = false;
  bool _readingHeaderActive = false;
  String _searchQuery = '';

  late PageController _pageController;

  ReaderProvider() {
    _pageController = PageController(initialPage: 0);
  }

  int get bookIndex => _bookIndex;
  int get pageIndex => _pageIndex;
  bool get searchActive => _searchActive;
  bool get sliderActive => _sliderActive;
  bool get readingHeaderActive => _readingHeaderActive;
  String get searchQuery => _searchQuery;
  PageController get pageController => _pageController;

  BookData get currentBook => BooksData.all[_bookIndex];
  BookPage get currentPage => currentBook.pages[_pageIndex];
  int get totalPages => currentBook.pages.length;
  bool get canPrev => _pageIndex > 0;
  bool get canNext => _pageIndex < totalPages - 1;

  void navigateTo(int bookIndex, int pageIndex) {
    final newBook = bookIndex.clamp(0, BooksData.all.length - 1);
    final newPage = pageIndex.clamp(0, BooksData.all[newBook].pages.length - 1);

    final bookChanged = newBook != _bookIndex;
    _bookIndex = newBook;
    _pageIndex = newPage;
    _readingHeaderActive = false;

    if (bookChanged) {
      _pageController.dispose();
      _pageController = PageController(initialPage: newPage);
    } else {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newPage,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
        );
      }
    }
    notifyListeners();
  }

  void goHome() => navigateTo(0, 0);

  void goToCurrentBookStart() => navigateTo(_bookIndex, 0);

  void nextPage() {
    if (canNext) {
      _pageIndex++;
      _pageController.animateToPage(
        _pageIndex,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
      );
      notifyListeners();
    }
  }

  void prevPage() {
    if (canPrev) {
      _pageIndex--;
      _pageController.animateToPage(
        _pageIndex,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
      );
      notifyListeners();
    }
  }

  void selectBook(int bookIndex) => navigateTo(bookIndex, 0);

  void onSwipedToPage(int index) {
    _pageIndex = index;
    _readingHeaderActive = false;
    notifyListeners();
  }

  void toggleSearch() {
    _searchActive = !_searchActive;
    if (_searchActive) _sliderActive = false;
    if (!_searchActive) _searchQuery = '';
    notifyListeners();
  }

  void toggleSlider() {
    _sliderActive = !_sliderActive;
    if (_sliderActive) _searchActive = false;
    notifyListeners();
  }

  void hideSlider() {
    if (_sliderActive) {
      _sliderActive = false;
      notifyListeners();
    }
  }

  void setReadingHeaderActive(bool value) {
    if (_readingHeaderActive == value) return;
    _readingHeaderActive = value;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  static const Map<String, String> _hinglishMap = {
    'ram': 'राम', 'raam': 'राम', 'rama': 'राम',
    'shiv': 'शिव', 'shiva': 'शिव', 'shankar': 'शंकर', 'mahadev': 'महादेव',
    'krishna': 'कृष्ण', 'krishan': 'कृष्ण', 'vasudev': 'वासुदेव',
    'hari': 'हरि', 'om': 'ॐ', 'aum': 'ॐ', 'hariom': 'हरि ॐ',
    'prem': 'प्रेम', 'pyar': 'प्यार', 'pyaar': 'प्यार',
    'atma': 'आत्मा', 'aatma': 'आत्मा', 'paramatma': 'परमात्मा',
    'bhagwan': 'भगवान', 'bhagwaan': 'भगवान', 'ishwar': 'ईश्वर',
    'maa': 'माँ', 'mata': 'माता', 'durga': 'दुर्गा', 'kali': 'काली',
    'lakshmi': 'लक्ष्मी', 'saraswati': 'सरस्वती', 'parvati': 'पार्वती',
    'brahma': 'ब्रह्मा', 'vishnu': 'विष्णु', 'mahesh': 'महेश',
    'hanuman': 'हनुमान', 'bhakti': 'भक्ति', 'bhajan': 'भजन',
    'aarti': 'आरती', 'arti': 'आरती', 'pooja': 'पूजा', 'puja': 'पूजा',
    'mandir': 'मंदिर', 'shanti': 'शांति', 'gyan': 'ज्ञान',
    'guru': 'गुरु', 'sant': 'संत', 'kabir': 'कबीर', 'rahim': 'रहीम',
    'tulsidas': 'तुलसीदास', 'tulsi': 'तुलसी', 'meera': 'मीरा',
    'doha': 'दोहा', 'dohe': 'दोहे', 'granth': 'ग्रंथ', 'kavya': 'काव्य',
    'priyatam': 'प्रियतम', 'mangalacharan': 'मंगलाचरण', 'adhyay': 'अध्याय',
    'virah': 'विरह', 'sagar': 'सागर', 'jay': 'जय', 'jai': 'जय',
    'sumiran': 'सुमिरन', 'naam': 'नाम', 'nam': 'नाम', 'sita': 'सिया',
  };

  String _normalizedQuery() {
    final raw = _searchQuery.trim().toLowerCase();
    if (raw.isEmpty) return '';
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(raw);
    if (hasDevanagari) return raw;
    return _hinglishMap[raw] ?? raw;
  }

  List<SearchResult> get results {
    final q = _normalizedQuery();
    if (q.isEmpty) return [];

    final out = <SearchResult>[];
    final book = currentBook;
    final b = _bookIndex;

    for (int p = 0; p < book.pages.length; p++) {
      final page = book.pages[p];
      final contentL = page.content.toLowerCase();
      final titleL = page.title.toLowerCase();
      if (contentL.contains(q) || titleL.contains(q)) {
        final idx = contentL.indexOf(q);
        String snippet;
        if (idx >= 0) {
          final start = (idx - 25).clamp(0, page.content.length);
          final end = (idx + 75).clamp(0, page.content.length);
          snippet = '…${page.content.substring(start, end)}…';
        } else {
          snippet = page.title;
        }
        out.add(SearchResult(
          bookIndex: b,
          pageIndex: p,
          bookTitle: book.title,
          pageTitle: page.title,
          snippet: snippet,
        ));
      }
    }
    return out;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
