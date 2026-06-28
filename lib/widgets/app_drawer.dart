import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/reader_provider.dart';
import '../screens/appearance_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/related_books_screen.dart';
import '../screens/social_links_screen.dart';
import '../screens/topic_section_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(cs: cs),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                children: _drawerMenu(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _drawerMenu(BuildContext context) => [
        _DrawerExpandTile(
          icon: Icons.history_edu_rounded,
          title: 'पूज्य श्रीराधाबाबा संक्षिप्त जीवन परिचय',
          children: _subTopics(
            context,
            [
              'संक्षिप्त जीवन परिचय',
              'श्रीराधाबाबा के द्वितीय काष्ठमौन पर पूज्य श्रीभाई जी के उद्गार पूज्य बाबाके लिए',
              'श्रीराधाबाबा – जीवनयात्रा',
            ],
            sectionId: 'topic1',
          ),
        ),
        _DrawerExpandTile(
          icon: Icons.volunteer_activism_rounded,
          title: 'निवेदन',
          children: _subTopics(
            context,
            [
              'महाप्रभु श्रीपोद्दार महाराज',
              'परम पूज्य श्रीबालकृष्णदासजी महाराज',
              'श्रीमती सावित्रीदेवी फोगला',
              'परम पूज्य श्रीसाधुकृष्ण प्रेम जी',
              'पूज्य श्रीराधेश्याम बंका',
            ],
            sectionId: 'topic2',
          ),
        ),
        _DrawerExpandTile(
          icon: Icons.format_list_numbered_rounded,
          title: 'अनुक्रमणिका (सार संक्षेप)',
          children: _subTopics(
            context,
            [
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
            ],
            sectionId: 'topic3',
          ),
        ),
        _DrawerExpandTile(
          icon: Icons.auto_stories_rounded,
          title: 'सरलार्थ (प्रियतम काव्य)',
          children: _subTopics(
            context,
            [
              'सरलार्थ एवं प्रथम शतक',
              'दूसरा शतक',
              'तीसरा शतक',
              'चौथा शतक',
              'पाँचवा शतक',
              'छठवाँ शतक',
              'सातवाँ शतक',
              'आठवाँ शतक',
              'नौवाँ शतक',
              'दसवाँ शतक',
              'ग्यारहवाँ शतक',
            ],
            sectionId: 'topic4',
          ),
        ),
        _DrawerExpandTile(
          icon: Icons.message_rounded,
          title: 'काव्य-मय सन्देश',
          children: _subTopics(
            context,
            [
              '(क)योऽहं    ममास्ति    यत्किञ्चिदिह   लोके   परत्र  च।',
              '(ख)मो इच्छित  कै  कृस्न पिय,  रुचै  बनिउ,  बनराउ।',
              '(ग)सुन्दर  इस  निज चरित्र  छविको  मेरे  उरपर  लिखना, प्रियतम !',
              '(घ)है  पथ  तुलसी वन जोह  रहा हम दोनों का प्यारी  प्रियतम ।',
              '(ड़)साँवर-साँवर ही  आगे हैं,  साँवर  ही पीछे हैं, प्रियतम !',
            ],
            sectionId: 'topic4',
          ),
        ),
        _DrawerActionTile(
          icon: Icons.menu_book_rounded,
          title: 'विहंगिनी काव्य',
          onTap: () => _openReader(context, 0, 0),
        ),
        _DrawerExpandTile(
          icon: Icons.local_florist_rounded,
          title: 'फलश्रुतियाँ',
          children: _subTopics(
            context,
            [
              'श्लोक एवं प्रथम शतक',
              'द्वितीय शतक',
              'तृतीय शतक',
              'चतुर्थ शतक',
              'पंचम एवं अन्य',
            ],
            sectionId: 'topic6',
          ),
        ),
        _DrawerActionTile(
          icon: Icons.library_books_rounded,
          title: 'प्रियतम काव्य से संबंधित पुस्तकें',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(_slide(const RelatedBooksScreen()));
          },
        ),
        _DrawerActionTile(
          icon: Icons.photo_library_rounded,
          title: 'चित्रसूची',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(_slide(const GalleryScreen()));
          },
        ),
        _DrawerExpandTile(
          icon: Icons.music_note_rounded,
          title: 'षोडश गीत',
          children: _subTopics(
              context,
              [
                'वंदना',
                '1.राधिके ! तुम मम जीवन-मूल।',
                '2.हौं तो दासी नित्य तिहारी।',
                '3.हे आराध्या राधा ! मेरे मनका तुझमें नित्य निवास।',
                '4.मेरी इस विनीत विनतीको सुन लो, हे व्रजराजकुमार !',
                '5.हे वृषभानुराजनन्दिनि ! हे अतुल प्रेम-रस-सुधा-निधान !',
                '6.सुन्दर श्याम कमल-दल-लोचन दुखमोचन व्रजराजकिशोर।',
                '7.हे प्रियतमे राधिके ! तेरी महिमा अनुपम अकथ अनन्त।',
                '8.सदा सोचती रहती हूँ मैं—क्या दूँ तुमको, जीवनधन !',
                '9.राधे, हे प्रियतमे, प्राण-प्रतिमे, हे मेरी जीवन मूल !',
                '10.मेरे धन-जन-जीवन तुम ही, तुम ही तन-मन, तुम सब धर्म।',
                '11.मेरा तन-मन सब तेरा ही, तू ही सदा स्वामिनी एक।',
                '12.तुमसे सदा लिया ही मैंने, लेती-लेती थकी नहीं।',
                '13.राधे ! तू ही चित्तरञ्जनी, तू ही चेतनता मेरी।',
                '14.तुम अनन्त सौन्दर्य-सुधा-निधि, तुममें सब माधुर्य अनन्त।',
                '15.राधा ! तुम-सी तुम्हीं एक हो, नहीं कहीं भी उपमा और।',
                '16.तुम हो यन्त्री, मैं यन्त्र, काठकी पुतली मैं, तुम सूत्रधार।',
                'पुष्पिका',
              ],
              sectionId: 'topic5'),
        ),
        _DrawerActionTile(
          icon: Icons.link_rounded,
          title: 'Social Media',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(_slide(const SocialLinksScreen()));
          },
        ),
        _DrawerActionTile(
          icon: Icons.bookmark_rounded,
          title: 'Book Marks',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(_slide(const BookmarksScreen()));
          },
        ),
        _DrawerExpandTile(
          icon: Icons.settings_rounded,
          title: 'Settings',
          children: [
            _SubTopicTile(
              title: 'Theme Colour and Appearance',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(_slide(const AppearanceScreen()));
              },
            ),
            _SubTopicTile(
              title: 'Share App With Others',
              onTap: () => _openSimplePage(context, 'Share app with others'),
            ),
            _SubTopicTile(
              title: 'Feedback',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(_slide(const _FeedbackPage()));
              },
            ),
            _SubTopicTile(
              title: 'About us',
              onTap: () => _openSimplePage(context, 'About'),
            ),
            _SubTopicTile(
              title: 'Privacy policy',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(_slide(const _PrivacyPolicyPage()));
              },
            ),
          ],
        ),
      ];

  List<Widget> _numberedTopics(
    BuildContext context,
    int count,
    String prefix,
  ) {
    return List.generate(
      count,
      (i) => _SubTopicTile(
        title: '$prefix ${i + 1}',
        onTap: () => _openSimplePage(context, '$prefix ${i + 1}'),
      ),
    );
  }

  List<Widget> _subTopics(
    BuildContext context,
    List<String> titles, {
    String? sectionId,
  }) {
    final sectionTopics = List<String>.unmodifiable(titles);
    return List.generate(sectionTopics.length, (index) {
      final title = sectionTopics[index];
      return _SubTopicTile(
        title: title,
        onTap: () => _openTopicSection(
          context,
          sectionTopics,
          index,
          sectionId: sectionId,
        ),
      );
    });
  }

  void _openReader(BuildContext context, int bookIndex, int pageIndex) {
    Navigator.of(context).pop();
    context.read<ReaderProvider>().navigateTo(bookIndex, pageIndex);
  }

  void _openSimplePage(BuildContext context, String title) {
    Navigator.of(context).pop();
    Navigator.of(context).push(_slide(_SimpleDrawerPage(title: title)));
  }

  void _openTopicSection(
    BuildContext context,
    List<String> topics,
    int initialIndex, {
    String? sectionId,
    String? sectionTitle,
  }) {
    Navigator.of(context).pop();
    Navigator.of(context).push(_slide(TopicSectionScreen(
      topics: topics,
      initialIndex: initialIndex,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
    )));
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
}

class _DrawerExpandTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _DrawerExpandTile({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        expansionAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 140),
          reverseDuration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: const EdgeInsets.only(left: 44, right: 8, bottom: 6),
        leading: Icon(icon, color: cs.primary, size: 21),
        iconColor: cs.primary,
        collapsedIconColor: cs.primary.withOpacity(0.75),
        title: Text(
          title,
          locale: const Locale('hi', 'IN'),
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Icon(icon, color: cs.primary, size: 21),
      title: Text(
        title,
        locale: const Locale('hi', 'IN'),
        softWrap: true,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SubTopicTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SubTopicTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      minLeadingWidth: 0,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.chevron_right_rounded,
        color: cs.primary.withOpacity(0.7),
        size: 18,
      ),
      title: Text(
        title,
        locale: const Locale('hi', 'IN'),
        softWrap: true,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.76),
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }
}

const _drawerHeaderPhotos = [
  _DrawerHeaderPhoto('assets/images/sidebar/perfect1.png'),
  _DrawerHeaderPhoto('assets/images/sidebar/perfect2.png'),
  _DrawerHeaderPhoto('assets/images/sidebar/perfect3.png'),
  _DrawerHeaderPhoto('assets/images/sidebar/perfect 4.png'),
  _DrawerHeaderPhoto(
    'assets/images/sidebar/Copy of Screenshot_20231220-060420_YouTube.png',
    alignment: Alignment.center,
  ),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060430_YouTube.png'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060456_YouTube.png'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060349_YouTube.jpg'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060524_YouTube.jpg'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060638_YouTube.png'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Screenshot_20231220-060737_YouTube.jpg'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060931_YouTube.jpg'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-060934_YouTube.png'),
  _DrawerHeaderPhoto(
      'assets/images/sidebar/Copy of Screenshot_20231220-061108_YouTube.png'),
];

class _DrawerHeaderPhoto {
  final String path;
  final Alignment alignment;

  const _DrawerHeaderPhoto(
    this.path, {
    this.alignment = Alignment.topCenter,
  });
}

class _DrawerHeader extends StatelessWidget {
  final ColorScheme cs;
  const _DrawerHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0600) : const Color(0xFF1E0E00),
        border: Border(
          bottom: BorderSide(color: cs.primary.withOpacity(0.3), width: 0.8),
        ),
      ),
      child: const _HeaderPhotoCarousel(),
    );
  }
}

class _HeaderPhotoCarousel extends StatefulWidget {
  const _HeaderPhotoCarousel();

  @override
  State<_HeaderPhotoCarousel> createState() => _HeaderPhotoCarouselState();
}

class _HeaderPhotoCarouselState extends State<_HeaderPhotoCarousel> {
  late final PageController _pageController;
  late int _currentPage;
  Timer? _autoSlideTimer;
  bool _userIsDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPage = _drawerHeaderPhotos.length * 1000;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.9,
    );
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 1750), (_) {
      if (!mounted || _userIsDragging || !_pageController.hasClients) return;

      final nextPage = _currentPage + 1;
      _currentPage = nextPage;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _userIsDragging = true;
      _autoSlideTimer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _userIsDragging = false;
      _startAutoSlide();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 188,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (page) => _currentPage = page,
          itemBuilder: (context, index) {
            final photo =
                _drawerHeaderPhotos[index % _drawerHeaderPhotos.length];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Image.asset(
                    photo.path,
                    fit: BoxFit.cover,
                    alignment: photo.alignment,
                    width: double.infinity,
                    height: double.infinity,
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

class _SimpleDrawerPage extends StatelessWidget {
  final String title;

  const _SimpleDrawerPage({required this.title});

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
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              title,
              textAlign: TextAlign.center,
              locale: const Locale('hi', 'IN'),
              style: GoogleFonts.notoSerifDevanagari(
                color: cs.onBackground.withOpacity(0.72),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyPolicyPage extends StatelessWidget {
  const _PrivacyPolicyPage();

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
          centerTitle: true,
          title: const Text('Privacy Policy'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
          children: [
            Text(
              'Welcome to प्रियतम काव्य',
              style: TextStyle(
                color: cs.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last Updated: September 2026',
              style: TextStyle(
                color: cs.onBackground.withOpacity(0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            _PolicyParagraph(
              'प्रियतम काव्य is a premium reading application dedicated to providing seamless access to literary, devotional, and poetic content. We respect your privacy and are deeply committed to protecting it. This Privacy Policy outlines how we collect, use, and safeguard your personal information to ensure a secure user experience.',
              cs: cs,
            ),
            _PolicyHeading('Information We Collect', cs: cs),
            _PolicyParagraph(
              'प्रियतम काव्य does not collect, store, or share any personal information from users.\n----FOR KIND ATTENTION----\nWe do not require users to create an account or provide personal details such as name, email address, phone number, profile photo, or location data.',
              cs: cs,
            ),
            _PolicyHeading('Permissions', cs: cs),
            _PolicyParagraph(
              'The application does not request access to device permissions such as camera, microphone, contacts, storage, or location.',
              cs: cs,
            ),
            _PolicyHeading('Advertisements', cs: cs),
            _PolicyParagraph(
              'प्रियतम काव्य does not display third-party advertisements.',
              cs: cs,
            ),
            _PolicyHeading('Payments and Purchases', cs: cs),
            _PolicyParagraph(
              'The application does not offer paid subscriptions, in-app purchases, or payment services.',
              cs: cs,
            ),
            _PolicyHeading('Children\'s Privacy', cs: cs),
            _PolicyParagraph(
              'The application is suitable for users of all ages. Since we do not collect personal information, we do not knowingly collect information from children.',
              cs: cs,
            ),
            _PolicyHeading('Data Security', cs: cs),
            _PolicyParagraph(
              'As the application does not collect or store personal data, no personal information is maintained on our servers.',
              cs: cs,
            ),
            _PolicyHeading('Third-Party Services', cs: cs),
            _PolicyParagraph(
              'प्रियतम काव्य does not use third-party services for collecting user information.',
              cs: cs,
            ),
            _PolicyHeading('Changes to This Privacy Policy', cs: cs),
            _PolicyParagraph(
              'We may update this Privacy Policy from time to time. Any changes will be reflected by updating the Last Updated date above.',
              cs: cs,
            ),
            const SizedBox(height: 16),
            _PolicySignature(cs: cs),
          ],
        ),
      ),
    );
  }
}

class _PolicyHeading extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  final TextAlign textAlign;

  const _PolicyHeading(
    this.text, {
    required this.cs,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 7),
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            color: cs.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _PolicyParagraph(this.text, {required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      locale: const Locale('hi', 'IN'),
      style: GoogleFonts.notoSerifDevanagari(
        color: cs.onBackground.withOpacity(0.74),
        fontSize: 14,
        height: 1.62,
      ),
    );
  }
}

class _PolicySignature extends StatelessWidget {
  final ColorScheme cs;

  const _PolicySignature({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.055),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cs.primary.withOpacity(0.18),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 1,
              color: cs.primary.withOpacity(0.42),
            ),
            const SizedBox(height: 14),
            Text(
              'Thank you for using',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onBackground.withOpacity(0.62),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'प्रियतम काव्य',
              textAlign: TextAlign.center,
              locale: const Locale('hi', 'IN'),
              style: GoogleFonts.notoSerifDevanagari(
                color: cs.primary,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 46,
              height: 1,
              color: cs.primary.withOpacity(0.42),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackPage extends StatefulWidget {
  const _FeedbackPage();

  @override
  State<_FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<_FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String _type = 'Suggestion';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _closeToDrawer() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final subject = Uri.encodeComponent('Priyatam Kavya $_type');
    final body = Uri.encodeComponent('''
Name: ${_name.text.trim()}
Email: ${_email.text.trim()}
Type: $_type

Feedback:
${_message.text.trim()}
''');
    final mailUri = Uri.parse(
      'mailto:shreegolokdham2002@gmail.com?subject=$subject&body=$body',
    );

    launchUrl(mailUri);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Email app खुल रहा है'),
        duration: Duration(seconds: 2),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Feedback'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _closeToDrawer,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
            children: [
              Text(
                'Send Feedback',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'आपके विचार और सुझाव हमारे लिए महत्वपूर्ण हैं। ऐप से संबंधित किसी भी समस्या या सुधार के सुझाव यहाँ साझा करें।',
                locale: const Locale('hi', 'IN'),
                style: GoogleFonts.notoSerifDevanagari(
                  color: cs.onBackground.withOpacity(0.64),
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Feedback type'),
                items: const [
                  DropdownMenuItem(
                    value: 'Suggestion',
                    child: Text('Suggestion'),
                  ),
                  DropdownMenuItem(
                    value: 'Bug report',
                    child: Text('Bug report'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'कृपया नाम लिखें';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'कृपया email लिखें';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'सही email लिखें';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _message,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Your feedback',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 5) {
                    return 'कृपया feedback लिखें';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit Feedback'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.18),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          'shreegolokdham2002@gmail.com',
                          maxLines: 1,
                          style: TextStyle(
                            color: cs.onBackground.withOpacity(0.78),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
