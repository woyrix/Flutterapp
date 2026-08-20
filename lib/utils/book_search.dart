import '../data/books_data.dart';

class BookParagraph {
  final int bookIndex;
  final int pageIndex;
  final int paragraphIndex;
  final String? number;
  final String text;

  const BookParagraph({
    required this.bookIndex,
    required this.pageIndex,
    required this.paragraphIndex,
    required this.text,
    this.number,
  });

  String get displayNumber => number == null
      ? '${paragraphIndex + 1}'
      : BookSearch.toAsciiDigits(number!);

  String get firstLine {
    final line = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => text.trim());
    return line.replaceAll(RegExp(r'\s+'), ' ');
  }
}

class SearchResult {
  final int bookIndex;
  final int pageIndex;
  final int? paragraphIndex;
  final String? paragraphNumber;
  final String bookTitle;
  final String pageTitle;
  final String snippet;
  final String matchedText;

  const SearchResult({
    required this.bookIndex,
    required this.pageIndex,
    required this.bookTitle,
    required this.pageTitle,
    required this.snippet,
    required this.matchedText,
    this.paragraphIndex,
    this.paragraphNumber,
  });
}

class BookSearch {
  static final RegExp _devanagari = RegExp(r'[\u0900-\u097F]');
  static final RegExp _latin = RegExp(r'[a-z]');
  static final RegExp _verseEndMarker = RegExp(
    r'(?:[\u0965|]{1,2})\s*([0-9\u0966-\u096F]+)\s*(?:[\u0965|]{1,2})',
  );
  static final Map<String, List<BookParagraph>> _paragraphCache = {};

  static const Map<String, String> _digits = {
    '0': '०',
    '1': '१',
    '2': '२',
    '3': '३',
    '4': '४',
    '5': '५',
    '6': '६',
    '7': '७',
    '8': '८',
    '9': '९',
  };

  static const Map<String, String> _asciiDigits = {
    '०': '0',
    '१': '1',
    '२': '2',
    '३': '3',
    '४': '4',
    '५': '5',
    '६': '6',
    '७': '7',
    '८': '8',
    '९': '9',
  };

  static String toAsciiDigits(String value) {
    var out = value;
    _asciiDigits.forEach((dev, ascii) {
      out = out.replaceAll(dev, ascii);
    });
    return out;
  }

  static const Map<String, String> _hinglishWords = {
    'adhyay': 'अध्याय',
    'arti': 'आरती',
    'aarti': 'आरती',
    'atma': 'आत्मा',
    'aatma': 'आत्मा',
    'bhagwan': 'भगवान',
    'bhagwaan': 'भगवान',
    'bhajan': 'भजन',
    'bhakti': 'भक्ति',
    'brahma': 'ब्रह्मा',
    'doha': 'दोहा',
    'dohe': 'दोहे',
    'durga': 'दुर्गा',
    'granth': 'ग्रंथ',
    'guru': 'गुरु',
    'gyan': 'ज्ञान',
    'hanuman': 'हनुमान',
    'hari': 'हरि',
    'ishwar': 'ईश्वर',
    'jai': 'जय',
    'jay': 'जय',
    'kali': 'काली',
    'kavya': 'काव्य',
    'krishan': 'कृष्ण',
    'krishna': 'कृष्ण',
    'lakshmi': 'लक्ष्मी',
    'maa': 'माँ',
    'mahadev': 'महादेव',
    'mahesh': 'महेश',
    'mangalacharan': 'मंगलाचरण',
    'mandir': 'मंदिर',
    'mata': 'माता',
    'meera': 'मीरा',
    'nam': 'नाम',
    'naam': 'नाम',
    'om': 'ॐ',
    'aum': 'ॐ',
    'paramatma': 'परमात्मा',
    'parvati': 'पार्वती',
    'pooja': 'पूजा',
    'prem': 'प्रेम',
    'pratham': 'प्रथम',
    'priyatam': 'प्रियतम',
    'puja': 'पूजा',
    'pyar': 'प्यार',
    'pyaar': 'प्यार',
    'raam': 'राम',
    'rahim': 'रहीम',
    'ram': 'राम',
    'rama': 'राम',
    'sagar': 'सागर',
    'sant': 'संत',
    'saraswati': 'सरस्वती',
    'shankar': 'शंकर',
    'shanti': 'शांति',
    'shatak': 'शतक',
    'shiv': 'शिव',
    'shiva': 'शिव',
    'sita': 'सिया',
    'sumiran': 'सुमिरन',
    'tulsi': 'तुलसी',
    'tulsidas': 'तुलसीदास',
    'vasudev': 'वासुदेव',
    'virah': 'विरह',
    'vishnu': 'विष्णु',
  };

  static List<BookParagraph> paragraphsForPage(
    int bookIndex,
    int pageIndex,
    BookPage page,
  ) {
    final cacheKey = '$bookIndex:$pageIndex:${page.content.hashCode}';
    final cached = _paragraphCache[cacheKey];
    if (cached != null) return cached;

    final chunks = _verseChunks(page.content);

    final paragraphs = [
      for (var i = 0; i < chunks.length; i++)
        BookParagraph(
          bookIndex: bookIndex,
          pageIndex: pageIndex,
          paragraphIndex: i,
          text: chunks[i].text,
          number: chunks[i].number,
        ),
    ];
    if (_paragraphCache.length > 48) {
      _paragraphCache.remove(_paragraphCache.keys.first);
    }
    _paragraphCache[cacheKey] = paragraphs;
    return paragraphs;
  }

  static void prewarmAround(BookData book, int bookIndex, int pageIndex) {
    for (final index in [pageIndex - 1, pageIndex, pageIndex + 1]) {
      if (index >= 0 && index < book.pages.length) {
        paragraphsForPage(bookIndex, index, book.pages[index]);
      }
    }
  }

  static List<SearchResult> searchBook(
    int bookIndex,
    BookData book,
    String query,
  ) {
    final digitQuery = _paragraphNumberQuery(query);
    final variants = queryVariants(query);
    if (variants.isEmpty && digitQuery == null) return const [];
    final out = <SearchResult>[];

    for (var pageIndex = 0; pageIndex < book.pages.length; pageIndex++) {
      final page = book.pages[pageIndex];
      final titleMatch =
          digitQuery == null ? _firstMatch(page.title, variants) : null;
      if (titleMatch != null) {
        out.add(SearchResult(
          bookIndex: bookIndex,
          pageIndex: pageIndex,
          bookTitle: book.title,
          pageTitle: page.title,
          snippet: page.title,
          matchedText: titleMatch,
        ));
      }

      for (final paragraph in paragraphsForPage(bookIndex, pageIndex, page)) {
        if (digitQuery != null && paragraph.number != digitQuery) {
          continue;
        }

        final matched = digitQuery ?? _firstMatch(paragraph.text, variants);
        if (matched == null) continue;

        out.add(SearchResult(
          bookIndex: bookIndex,
          pageIndex: pageIndex,
          paragraphIndex: paragraph.paragraphIndex,
          paragraphNumber: paragraph.number,
          bookTitle: book.title,
          pageTitle: page.title,
          snippet: _snippet(paragraph.text, matched),
          matchedText: matched,
        ));
      }
    }

    return out;
  }

  static List<String> queryVariants(String query) {
    final raw = _mapDigits(query.trim().toLowerCase());
    if (raw.isEmpty) return const [];

    final variants = <String>{raw};
    if (_latin.hasMatch(raw) && !_devanagari.hasMatch(raw)) {
      final words = raw.split(RegExp(r'(\s+)'));
      variants.add(words.map(_mapHinglishWord).join());
      variants.add(_mapHinglishWord(raw));
      variants.add(_transliterate(raw));
    }

    return variants.where((v) => v.trim().isNotEmpty).toList();
  }

  static String searchableFold(String value) {
    return _mapDigits(value.toLowerCase())
        .replaceAll(RegExp(r'[\u093C\u094D\u0951-\u0954]'), '')
        .replaceAll(RegExp(r'[\s।॥,.;:!?(){}\[\]' '"“”‘’-]+'), '');
  }

  static String? _firstMatch(String source, List<String> variants) {
    final lower = _mapDigits(source.toLowerCase());
    for (final variant in variants) {
      if (lower.contains(variant)) return variant;
    }

    final foldedSource = searchableFold(source);
    for (final variant in variants) {
      final foldedVariant = searchableFold(variant);
      if (foldedVariant.isNotEmpty && foldedSource.contains(foldedVariant)) {
        return variant;
      }
    }

    return null;
  }

  static String? _paragraphNumberQuery(String query) {
    final trimmed = query.trim();
    if (!RegExp(r'^[0-9०-९]+$').hasMatch(trimmed)) return null;
    return _mapDigits(trimmed);
  }

  static String _snippet(String text, String matched) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ');
    final lower = _mapDigits(compact.toLowerCase());
    final idx = lower.indexOf(matched.toLowerCase());
    if (idx < 0) {
      return compact.length <= 140 ? compact : '${compact.substring(0, 140)}…';
    }
    final start = (idx - 38).clamp(0, compact.length);
    final end = (idx + matched.length + 82).clamp(0, compact.length);
    return '${start > 0 ? '…' : ''}${compact.substring(start, end)}${end < compact.length ? '…' : ''}';
  }

  static String _mapDigits(String value) {
    var out = value;
    _digits.forEach((ascii, dev) {
      out = out.replaceAll(ascii, dev);
    });
    return out;
  }

  static String _cleanChunk(String chunk) {
    return chunk
        .replaceFirst(RegExp(r'^\s*\r?\n+'), '')
        .replaceFirst(RegExp(r'\r?\n+\s*$'), '')
        .replaceAll('\u00A0', ' ')
        .trimRight();
  }

  static List<_VerseChunk> _verseChunks(String content) {
    final normalized = content.replaceAll('\u00A0', ' ');
    if (!_verseEndMarker.hasMatch(normalized)) {
      return normalized
          .split(RegExp(r'\r?\n\s*\r?\n+'))
          .map(_cleanChunk)
          .where((chunk) => chunk.trim().isNotEmpty)
          .map((chunk) => _VerseChunk(chunk, _extractLooseNumber(chunk)))
          .toList();
    }

    final chunks = <_VerseChunk>[];
    final buffer = StringBuffer();
    final lines = normalized.split(RegExp(r'\r?\n'));

    for (final line in lines) {
      buffer.writeln(line);
      final lineMarkers = _verseEndMarker.allMatches(line).toList();
      if (lineMarkers.isNotEmpty) {
        final text = _cleanChunk(buffer.toString());
        if (text.trim().isNotEmpty) {
          chunks.add(_VerseChunk(
            text,
            _mapDigits(lineMarkers.last.group(1)!),
          ));
        }
        buffer.clear();
      }
    }

    final rest = _cleanChunk(buffer.toString());
    if (rest.trim().isNotEmpty) {
      chunks.add(_VerseChunk(rest, _extractLooseNumber(rest)));
    }

    return _mergeIntroInvocation(chunks);
  }

  static String? _extractLooseNumber(String text) {
    final marker = _verseEndMarker.allMatches(text).toList();
    if (marker.isNotEmpty) return _mapDigits(marker.last.group(1)!);
    final trailing =
        RegExp(r'([0-9\u0966-\u096F]+)\s*$').firstMatch(text.trim());
    return trailing == null ? null : _mapDigits(trailing.group(1)!);
  }

  static List<_VerseChunk> _mergeIntroInvocation(List<_VerseChunk> chunks) {
    if (chunks.length < 3) return chunks;
    final first = toAsciiDigits(chunks[0].number ?? '');
    final second = toAsciiDigits(chunks[1].number ?? '');
    final third = toAsciiDigits(chunks[2].number ?? '');
    if (first != '1' || second != '2' || third != '1') return chunks;

    return [
      _VerseChunk(
        '${chunks[0].text.trimRight()}\n${chunks[1].text.trimLeft()}',
        _mapDigits('0'),
      ),
      ...chunks.skip(2),
    ];
  }

  static String _mapHinglishWord(String word) {
    final clean = word.toLowerCase();
    return _hinglishWords[clean] ?? _transliterate(clean);
  }

  static String _transliterate(String input) {
    final words = input.split(RegExp(r'(\s+)'));
    return words.map((part) {
      if (part.trim().isEmpty) return part;
      return _transliterateWord(part);
    }).join();
  }

  static String _transliterateWord(String word) {
    const consonants = {
      'chh': 'छ',
      'kh': 'ख',
      'gh': 'घ',
      'ch': 'च',
      'jh': 'झ',
      'th': 'थ',
      'dh': 'ध',
      'ph': 'फ',
      'bh': 'भ',
      'sh': 'श',
      'k': 'क',
      'g': 'ग',
      'c': 'क',
      'j': 'ज',
      't': 'त',
      'd': 'द',
      'n': 'न',
      'p': 'प',
      'b': 'ब',
      'm': 'म',
      'y': 'य',
      'r': 'र',
      'l': 'ल',
      'v': 'व',
      'w': 'व',
      's': 'स',
      'h': 'ह',
    };
    const vowels = {
      'aa': ['आ', 'ा'],
      'ee': ['ई', 'ी'],
      'ii': ['ई', 'ी'],
      'oo': ['ऊ', 'ू'],
      'uu': ['ऊ', 'ू'],
      'ai': ['ऐ', 'ै'],
      'au': ['औ', 'ौ'],
      'a': ['अ', ''],
      'i': ['इ', 'ि'],
      'u': ['उ', 'ु'],
      'e': ['ए', 'े'],
      'o': ['ओ', 'ो'],
    };

    final buffer = StringBuffer();
    var i = 0;
    while (i < word.length) {
      final consonant = _matchToken(word, i, consonants.keys);
      if (consonant != null) {
        buffer.write(consonants[consonant]);
        i += consonant.length;
        final vowel = _matchToken(word, i, vowels.keys);
        if (vowel != null) {
          buffer.write(vowels[vowel]![1]);
          i += vowel.length;
        }
        continue;
      }

      final vowel = _matchToken(word, i, vowels.keys);
      if (vowel != null) {
        buffer.write(vowels[vowel]![0]);
        i += vowel.length;
        continue;
      }

      buffer.write(word[i]);
      i++;
    }

    return buffer.toString();
  }

  static String? _matchToken(
      String source, int start, Iterable<String> tokens) {
    for (final token in tokens.toList()
      ..sort((a, b) => b.length.compareTo(a.length))) {
      if (source.startsWith(token, start)) return token;
    }
    return null;
  }
}

class _VerseChunk {
  final String text;
  final String? number;

  const _VerseChunk(this.text, this.number);
}
