import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/reader_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final app = context.watch<AppProvider>();

    return PageView.builder(
      controller: reader.pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: reader.totalPages,
      onPageChanged: reader.onSwipedToPage,
      itemBuilder: (context, index) {
        final page = reader.currentBook.pages[index];
        return _PageBody(
          title: page.title,
          content: page.content,
          fontSize: app.fontSize,
          pageIndex: index,
          totalPages: reader.totalPages,
          onReadingHeaderChanged:
              index == reader.pageIndex ? reader.setReadingHeaderActive : null,
        );
      },
    );
  }
}

class _PageBody extends StatelessWidget {
  final String title;
  final String content;
  final double fontSize;
  final int pageIndex;
  final int totalPages;
  final ValueChanged<bool>? onReadingHeaderChanged;

  const _PageBody({
    required this.title,
    required this.content,
    required this.fontSize,
    required this.pageIndex,
    required this.totalPages,
    this.onReadingHeaderChanged,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content));
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
    final cs = Theme.of(context).colorScheme;

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
              onReadingHeaderChanged?.call(notification.metrics.pixels > 8);
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 49),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                title,
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
              const SizedBox(height: 6),
              Text(
                content,
                locale: const Locale('hi', 'IN'),
                softWrap: true,
                textAlign: TextAlign.start,
                textWidthBasis: TextWidthBasis.parent,
                style: GoogleFonts.notoSerifDevanagari(
                  fontSize: fontSize,
                  height: 1.9,
                  letterSpacing: 0,
                  wordSpacing: 0,
                  color: cs.onBackground,
                ), // letterSpacing removed
                strutStyle: StrutStyle(
                  fontSize: fontSize,
                  height: 1.9,
                  forceStrutHeight: false,
                ),
              ),
              const SizedBox(height: 36),
              _Divider(color: cs.primary),
              const SizedBox(height: 14),
              Text(
                '${pageIndex + 1}  /  $totalPages',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerifDevanagari(
                  fontSize: 12,
                  color: cs.primary.withOpacity(0.45),
                ), // letterSpacing removed
              ),
              const SizedBox(height: 6),
              Text(
                'कॉपी करने के लिए दबाकर रखें  •  पृष्ठ बदलने के लिए स्वाइप करें',
                textAlign: TextAlign.center,
                locale: const Locale('hi', 'IN'),
                style: TextStyle(
                  fontSize: 10.5,
                  color: cs.onBackground.withOpacity(0.25),
                ), // letterSpacing removed
              ),
              ],
            ),
          ),
        ),
      ),
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
