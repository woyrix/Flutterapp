import 'package:flutter/material.dart';
import '../data/books_data.dart';
import '../utils/book_search.dart';

class ReaderProvider extends ChangeNotifier {
  int _bookIndex = 0;
  int _pageIndex = 0;
  bool _searchActive = false;
  bool _sliderActive = false;
  bool _readingHeaderActive = false;
  String _searchQuery = '';
  int? _targetParagraphIndex;
  String? _targetParagraphNumber;
  bool _programmaticScrollActive = false;
  bool _pageAnimationRunning = false;
  int? _desiredPageIndex;
  int _pageAnimationGeneration = 0;

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
  int? get targetParagraphIndex => _targetParagraphIndex;
  String? get targetParagraphNumber => _targetParagraphNumber;
  PageController get pageController => _pageController;

  BookData get currentBook => BooksData.all[_bookIndex];
  BookPage get currentPage => currentBook.pages[_pageIndex];
  int get totalPages => currentBook.pages.length;
  bool get canPrev => _pageIndex > 0;
  bool get canNext => _pageIndex < totalPages - 1;

  void navigateTo(
    int bookIndex,
    int pageIndex, {
    int? paragraphIndex,
    String? paragraphNumber,
  }) {
    final newBook = bookIndex.clamp(0, BooksData.all.length - 1);
    final newPage = pageIndex.clamp(0, BooksData.all[newBook].pages.length - 1);

    final bookChanged = newBook != _bookIndex;
    _bookIndex = newBook;
    _pageIndex = newPage;
    _targetParagraphIndex = paragraphIndex;
    _targetParagraphNumber = paragraphNumber;
    _desiredPageIndex = null;
    _pageAnimationGeneration++;
    _pageAnimationRunning = false;
    _readingHeaderActive = false;
    _programmaticScrollActive = true;

    if (bookChanged) {
      _pageController.dispose();
      _pageController = PageController(initialPage: newPage);
      _programmaticScrollActive = false;
    } else {
      if (_pageController.hasClients) {
        _jumpProgrammatically(newPage);
      } else {
        _programmaticScrollActive = false;
      }
    }
    notifyListeners();
  }

  void goHome() => navigateTo(0, 0);

  void goToCurrentBookStart() => navigateTo(_bookIndex, 0);

  void nextPage() {
    final base = _desiredPageIndex ?? _pageIndex;
    if (base < totalPages - 1) {
      _queuePage(base + 1);
    }
  }

  void prevPage() {
    final base = _desiredPageIndex ?? _pageIndex;
    if (base > 0) {
      _queuePage(base - 1);
    }
  }

  void selectBook(int bookIndex) => navigateTo(bookIndex, 0);

  void onSwipedToPage(int index) {
    if (!_programmaticScrollActive && index != _pageIndex) {
      _targetParagraphIndex = null;
      _targetParagraphNumber = null;
    }
    _pageIndex = index;
    if (_desiredPageIndex == index) {
      _desiredPageIndex = null;
    }
    _readingHeaderActive = false;
    notifyListeners();
  }

  void _queuePage(int pageIndex) {
    final target = pageIndex.clamp(0, totalPages - 1).toInt();
    if (target == _pageIndex &&
        !_pageAnimationRunning &&
        _desiredPageIndex == null) {
      return;
    }

    _targetParagraphIndex = null;
    _targetParagraphNumber = null;
    _programmaticScrollActive = false;
    _desiredPageIndex = target;
    _readingHeaderActive = false;
    notifyListeners();
    _driveQueuedPageAnimation();
  }

  Future<void> _driveQueuedPageAnimation() async {
    if (_pageAnimationRunning || !_pageController.hasClients) return;
    final generation = _pageAnimationGeneration;
    _pageAnimationRunning = true;

    while (_desiredPageIndex != null &&
        _desiredPageIndex != _pageIndex &&
        _pageController.hasClients) {
      final desired = _desiredPageIndex!;
      final next = desired > _pageIndex ? _pageIndex + 1 : _pageIndex - 1;
      await _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
      if (generation != _pageAnimationGeneration) return;
      _pageIndex = next;
      _readingHeaderActive = false;
      notifyListeners();
      if (_desiredPageIndex == _pageIndex) {
        _desiredPageIndex = null;
      }
    }

    _pageAnimationRunning = false;
  }

  void _jumpProgrammatically(int pageIndex) {
    if (!_pageController.hasClients) {
      _programmaticScrollActive = false;
      return;
    }
    _pageController.jumpToPage(pageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _programmaticScrollActive = false;
    });
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

  List<SearchResult> get results {
    return BookSearch.searchBook(_bookIndex, currentBook, _searchQuery);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
