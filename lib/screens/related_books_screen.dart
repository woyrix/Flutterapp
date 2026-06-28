import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/related_books_data.dart';
import '../navigation/home_scaffold_controller.dart';

class RelatedBooksScreen extends StatelessWidget {
  const RelatedBooksScreen({super.key});

  void _closeToDrawer(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  Future<void> _openBook(BuildContext context, RelatedBookData book) async {
    final url = book.downloadUrl;
    final uri = url == null ? null : Uri.tryParse(url);

    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('इस पुस्तक का डाउनलोड लिंक अभी जोड़ना है'),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('डाउनलोड लिंक खोलने में समस्या आई'),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: Text(
            'प्रियतम काव्य से संबंधित पुस्तकें',
            maxLines: 2,
            overflow: TextOverflow.visible,
            locale: const Locale('hi', 'IN'),
            strutStyle: const StrutStyle(
              fontSize: 15,
              height: 1.32,
              forceStrutHeight: true,
            ),
            style: GoogleFonts.notoSerifDevanagari(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.32,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: RelatedBooksData.all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final book = RelatedBooksData.all[index];

            return Material(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openBook(context, book),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          book.title,
                          locale: const Locale('hi', 'IN'),
                          style: GoogleFonts.notoSerifDevanagari(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        color: cs.primary.withOpacity(0.72),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
