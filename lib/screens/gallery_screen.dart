// lib/screens/gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../data/gallery_data.dart';
import '../navigation/home_scaffold_controller.dart';
import '../utils/image_download_helper.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  void _closeToDrawer(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
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
          title: Text(
            'चित्र सूची',
            style: GoogleFonts.notoSerifDevanagari(fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 430;
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                narrow ? 12 : 16,
                14,
                narrow ? 12 : 16,
                24,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: narrow ? 1 : 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: narrow ? 0.78 : 0.6,
              ),
              itemCount: GalleryData.items.length,
              itemBuilder: (context, i) {
                final item = GalleryData.items[i];
                return _GalleryTile(
                  item: item,
                  index: i,
                  cs: cs,
                  onTap: () => Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 320),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 220),
                      pageBuilder: (_, __, ___) =>
                          _FullScreen(items: GalleryData.items, initial: i),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: a, child: child),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final GalleryItem item;
  final int index;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.item,
    required this.index,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.primary.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.28
                        : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'gallery_$index',
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.background.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: cs.outline.withOpacity(0.12)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: item.isPlaceholder || item.assetPath == null
                            ? _Placeholder(color: item.placeholderColor)
                            : Image.asset(
                                item.assetPath!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _Placeholder(color: item.placeholderColor),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 96,
                  child: Center(
                    child: Text(
                      item.title,
                      locale: const Locale('hi', 'IN'),
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerifDevanagari(
                        color: cs.onSurface,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Color color;
  const _Placeholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.75),
      child: Icon(Icons.image_outlined,
          size: 38, color: Colors.white.withOpacity(0.45)),
    );
  }
}

class _FullScreen extends StatefulWidget {
  final List<GalleryItem> items;
  final int initial;
  const _FullScreen({required this.items, required this.initial});

  @override
  State<_FullScreen> createState() => _FullScreenState();
}

class _FullScreenState extends State<_FullScreen> {
  late int _current;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.items[_current];
    final canDownload = !item.isPlaceholder && item.assetPath != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: const CloseButton(),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: canDownload && !_isDownloading ? _downloadCurrent : null,
            icon: _isDownloading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : const Icon(Icons.download_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: PhotoViewGallery.builder(
                pageController: PageController(initialPage: widget.initial),
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _current = i),
                scrollPhysics: const BouncingScrollPhysics(),
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFE8B84B),
                    value: event == null || event.expectedTotalBytes == null
                        ? null
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                  ),
                ),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                builder: (context, i) {
                  final galleryItem = widget.items[i];
                  if (galleryItem.isPlaceholder ||
                      galleryItem.assetPath == null) {
                    return PhotoViewGalleryPageOptions.customChild(
                      heroAttributes:
                          PhotoViewHeroAttributes(tag: 'gallery_$i'),
                      child: Center(
                        child:
                            _Placeholder(color: galleryItem.placeholderColor),
                      ),
                    );
                  }
                  return PhotoViewGalleryPageOptions(
                    imageProvider: AssetImage(galleryItem.assetPath!),
                    heroAttributes: PhotoViewHeroAttributes(tag: 'gallery_$i'),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    initialScale: PhotoViewComputedScale.contained,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outline.withOpacity(0.12)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_current + 1}/${widget.items.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      locale: const Locale('hi', 'IN'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerifDevanagari(
                        color: cs.onSurface,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCurrent() async {
    final messenger = ScaffoldMessenger.of(context);
    final item = widget.items[_current];
    final assetPath = item.assetPath;
    if (item.isPlaceholder || assetPath == null) return;

    setState(() => _isDownloading = true);
    try {
      final savedTo = await downloadAssetImage(
        assetPath: assetPath,
        title: item.title,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Downloaded: $savedTo')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}
