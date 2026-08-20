import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../navigation/home_scaffold_controller.dart';
import '../providers/app_provider.dart';
import '../screens/appearance_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/related_books_screen.dart';
import '../screens/social_links_screen.dart';
import '../screens/topic_section_screen.dart';
import 'font_size_slider.dart';

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
            sectionId: 'topic7',
          ),
        ),
        _DrawerActionTile(
          icon: Icons.menu_book_rounded,
          title: 'विहंगिनी काव्य',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(_slide(const _VihanginiKavyaPage()));
          },
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
              onTap: () => _shareApp(context),
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
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(_slide(const _AboutUsPage()));
              },
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

  void _openSimplePage(BuildContext context, String title) {
    Navigator.of(context).pop();
    Navigator.of(context).push(_slide(_SimpleDrawerPage(title: title)));
  }

  void _shareApp(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    Navigator.of(context).pop();
    Share.share(
      'प्रियतम काव्य\nhttps://www.youtube.com',
      subject: 'प्रियतम काव्य',
      sharePositionOrigin: origin,
    );
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

// Menu icons are Material Icons. Pick a new icon from
// https://fonts.google.com/icons and replace the matching Icons.* value above.
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

class _AboutLogoSlide {
  const _AboutLogoSlide(this.path, this.aspectRatio);

  final String path;
  final double aspectRatio;
}

const _aboutUsLogoSlides = [
  _AboutLogoSlide('assets/images/upload/1.png', 4032 / 3024),
  _AboutLogoSlide('assets/images/upload/2.png', 1280 / 960),
  _AboutLogoSlide('assets/images/upload/3.png', 1280 / 960),
  _AboutLogoSlide('assets/images/upload/4.png', 1280 / 960),
  _AboutLogoSlide('assets/images/upload/5.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/6.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/7.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/8.PNG', 1086 / 1448),
  _AboutLogoSlide('assets/images/upload/9.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/10.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/11.png', 3024 / 4032),
  _AboutLogoSlide('assets/images/upload/12.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/13.png', 780 / 1040),
  _AboutLogoSlide('assets/images/upload/14.png', 960 / 1280),
  _AboutLogoSlide('assets/images/upload/15.png', 720 / 1280),
  _AboutLogoSlide('assets/images/upload/16.png', 1368 / 912),
];

const _aboutUsContent = '''

सर्वप्रथम प्रेम अर्थात (प्रीति) की प्रतिष्ठा के लिए,  राधानाम-रस-सुधा की प्रतिष्ठा के लिए, यहाँ की धूलिके कण-कण, अणु-अणु, परमाणु-परमाणुमें महा भावभक्ति, महा महाभावभक्ति की प्रतिष्ठाके लिए, यहाँ की जड़ भूमिके कण-कण को रस से सराबोर, नहीं ! प्रीति रस से सराबोर, नहीं नहीं ! प्रीति महाभाव-रस से सराबोर करने के लिए, प्रत्येक पामर जीवके अंतः करण में तत्सुख भाव की प्रतिष्ठा के लिए, केवल कृष्णसुखाभिलाषा के लिए, सारे रसों के सार अर्थात नित्य विहार रस की प्रतिष्ठा के लिए सं १९९५, अप्रैल २२ के दिन सर्वप्रथम यहाँ प्राकट्य हुआ हमारे एकमात्र अवलंबन, एकमात्र सुखसार, एकमात्र सर्वस्व, हमारे सौंदर्य-माधुर्य-सुधारस-निधि, निर्मल प्रेमपूंज स्वरूप रसमयी-रसमय श्यामा-श्यामजू सरकार का । 
जिनका हृदय प्रीतिसिंधु में पूर्णतः निमज्जन कर प्रीतिस्वरूप बन गया, उस प्रीतिमय हृदय में प्रीतिकी अनंत तरंगे उमड़ने लगी और इन्हीं प्रीति तरंगों में से एक प्रीति तरंगके फलः स्वरूप सं २००२, कृष्ण जन्माष्टमीके दिन यहाँ ‘नित्य योगपीठ स्थित श्री श्रीगोलोक धाम’ अर्थात श्रीराधा-माधवजी का प्राकट्य हुआ । 
आज इस घोर कलिकाल में सर्वत्र-सर्वत्र काम-वासना का ही विस्तार हो रहा है, विषयजन हर वस्तुको, हर स्थानको, जड़ बनाते चले जा रहे हैं । अप्राकृत चिन्मय वृंदवान धामको भी सब जड़ बनाते जा रहे हैं, उसकी चिन्मयता से कहाँ परिचित हो रहे हैं ? और यहाँ ! इस जड़ स्थान (मु० नगर) को ‘वह’ रस से प्लावित कर रहे हैं, इसके कण-कण अणु-अणु परमाणु-परमाणुमें मात्र केवल तत्सुखभाव ही शेष रह जाए ऐसा रसप्रयास कर रहे हैं, इसके कण-कणको, अणु-अणुको, परमाणु-परमाणु को राधानाम-सुधारस का पान कराकर चिन्मय बना रहे हैं । जिस राधानाम की महिमा में आता है-
राधा राधेति  कुर्यात्तु  राधा राधेति पूजयेत् ।
राधा राधेति यन्निष्ठा राधा राधेति जल्पति ।
वृन्दारण्ये  महाभागा  राधा सहचरी भवेत् ॥

अतः जिनका जीवन राधानाम है, जिनका सर्वस्व राधानाम है, जिनका एकमात्र अवलंबन राधानाम है, जिनके प्राण राधा नाम ही है तो उस हृदय में ‘चाह’ क्या होगी ? उस हृदय की चाह भी तो राधानाम ही होगी ! इसी कारणसे उनके हृदयमें यह मधुराभिलाषा प्रकट हुई कि यहाँ के प्रत्येक विषयजीव का हृदय राधानाम से सराबोर हो और राधानाम ही उसका जीवन हो इस उद्देश्य से यहाँपर ‘राधानाम संकीर्तन’ सन १९९५ को प्रारंभ हुआ था ।
जिनका ह्रदय प्रेमसिंधु था अकारण या कारण उनका जाना गिरिराजजी हुआ, और वहाँ संत श्री श्रीजगन्नाथबाबाजी से उनका मिलन हुआ, उस प्रेममय मिलन, उस अंतरंग प्रेममय वार्ता के फलः स्वरूप ‘नित्य एकादशी जागरण’ यहाँ (मु० नगर) में सन २००० को प्रारंभ हुआ । सामान्यतः व्रतोंमें सर्वोपरि एकादशी-व्रत कहा गया है । पर प्रायः एकादशी व्रत अपने कल्याण के लिए, स्व के लिए, फल की प्राप्ति के लिए, सर्व-पापों के नाश के लिए किया जाता है । यही उद्देश्य इस ‘एकादशी जागरण’ का भी हो यह उन्हें कदापि स्वीकार नहीं था अतः इस उद्देश्य को आमूल-चूल परिवर्तन करते हुए उन्होंने यहाँ स्वसुख धारा को हटाकर तत्सुख धारा को स्थापित किया अर्थात ‘एकादशी जागरण’ का उद्देश्य केवल मात्र प्रिया-प्रियतम का सुख, प्रियतमको रस निमग्न करनेके लिए, पुनः महाभाव समुद्रमें डूबा देने के लिए, राधानाम रस-समुद्रमें डूबा देनेके लिए........ 
सब रसको रस सार बिहार, सो चीन्हौ हम रसिकन जन ।।  
नित्य विहार रस ही सारे रसोंका सार है- यह निर्णय रसिकजनोंका है । प्रिया-प्रियतम का विहार निरवधिकाल से चलता आ रहा है और चलता रहेगा । विहार रस में सबका प्रवेश संभव नहीं पर राधाचरणाश्रित संतों की कृपा से सब संभव है । जैसे नित्य-जगत में प्रविष्ट होने के लिए पहले भाव-देह से लीलाओंका मानसिक चिन्तन करना पढ़ता है, फिर संतों की कृपा और शनैः शनैः अभ्यास द्वारा नित्य जगत में प्रवेश होता है, ऐसे ही नित्यविहार में प्रविष्ट होने के लिए पहले नित्यविहार का मानसिक चिन्तन भी आवश्यक है इसलिए सन २००२ को ‘नित्य योगपीठ स्थित श्री श्रीगोलोक धाम’ में नित्यविहार उत्सव प्रारंभ हुआ और इसके अतिरिक्त प्रत्येक वर्ष में २ माह के लिए रसीली-विहार यात्रा प्रारंभ हुई ।
इस विहार यात्रामें सब ‘८४ कोस’ का मानसिक भाव रखते हुए और प्रिया-प्रियतम को सुख प्रदान करते हुए प्रिया-प्रियतम के साथ (सहचरी, मंजरी) भाव से विहार करते, अतः जिनका हृदय प्रेमसिंधु था, उनका रसोद्देश्य बस यही था की सब इस (मु० नगर) स्थान पर रहते हुए वृंदावन की नित्य विहार यात्रा का मानसिक चिन्तन करते हुए उस विहार-रस में प्रविष्ट हों । 
सबको प्रीतिदेने के लिए, सबको राधानाम-रस-सुधा का रस देने के लिए, सबको भाव (मंजरी) स्वरूप देने के लिए उन्होंने क्रमशः क्रमशः यहाँ पर प्रेमजगत की सम्पूर्ण साधना सिद्धि सहज में सबको उपलब्ध कराई ।
जिनका हृदय प्रेमसिंधु था, जो खंडिता भावमें नित्य लहराते रहते थे, उनको कुछ भक्तों ने गुरुरूप में ‘ग्रहण’ करना चाहा और दीक्षा लेनी चाही पर उन्होंने कभी भी गुरुपद स्वीकार नहीं करा । वृंदावन के संतों ने भी यही आदेश दिया की आप सबको दीक्षा दीजिए पर उन संतों की बात को भी उन्होंने स्वीकार नहीं किया ! जो अपने को सदा दीन-हीन ही समझते हैं, जो सर्वथा अकिंचन हैं, जिनके अंदर सदा यही भाव रहा कि ‘मैं कुछ नहीं हूँ’ अतः वो सबको दीक्षा कैसे दे सकते हैं ?   
जब उनकी राधारानी ही अकिंचन हैं, दीन-मलिन हैं, ‘जो देनेको लेना समझती हैं’ तो उनके चरणाश्रित ‘वो’ गुरुपद कैसे ग्रहण करे ? अतः स्वयं को पीछे रखकर, अपने स्वरूप का कभी भी प्रकाश न करते हुए उन्होंने परम पूज्य युगपत स्वरूप श्रीपोद्दार महाराज एवं महभाव दिनमणि श्रीराधा बाबा के स्वरूप की यहाँ ‘नित्य योगपीठ स्थित श्री श्रीगोलोक धाम’ में प्रतिष्ठा की और सबको यही आज्ञा करी कि सब पूज्य भाईजी, बाबा को ही गुरुरूप में स्वीकार कीजिए ।
अतः आज लगभग ३० वर्ष बीत चुके हैं और प्रेमसमुद्र की असीम उत्ताल तरंगे हिलोरे लेकर उमड़ रहीं हैं और एक दिन ऐसा अवश्य आएगा जब उनके हृदय की महा-महातरंग यहाँ सबको बहाकर ले जाएगी, उसमें सबकुछ डूब जाएगा, कुछ भी नहीं बचेगा....जैसे बाड़ या सूनामी आजाने पर कुछ नहीं बचता, सब उसमें बह जाते हैं ऐसे ही प्रीति की महातरंग एक-दिन सबको बहा ले जाएगी निश्चिय ही-निश्चिय ही.....  
अतः खंडिता भावनिमग्न उन श्रीसतीश बाऊजी को मेरा प्रणाम ॥ 

[R]--तृण 
Made with love by Vaibhav Dhingra

''';

const _vihanginiKavyaContent = '''
वंदन है शत सहस्रशः उस धरणीके रज-कणको प्रियतम !
पिंजर वह इन्द्रनीलमय है शोभित हो रहा जहाँ प्रियतम !
आकर्षण अभिनव वह उसमें है अबतक भरा हुआ प्रियतम !
मोहित हो जिससे थी उतरी नभसे विहंगिनी मैं प्रियतम !१!

पासकी न अहो ! गन्ध भी यह उस समय तनिक ऐसी प्रियतम !
निर्माण किया है तुमने ही इसको, अपने करसे प्रियतम !
किंचित्-सा उपादान लेकर अपने ही उस तनसे प्रियतम !
नीलिमा अनिर्वचनीय नित्य वह है अचिन्त्य जिसमें प्रियतम !२!

थी श्रमित हुई उड़ती-उड़ती निस्सीम गगन-तलमें प्रियतम !
मेरे ही साथ सदा तुम थे हँस-हँसकर खेल रहे प्रियतम !
समझाते पुनः पुनः तुम थे 'प्रियतमे ! चलो बैठें' प्रियतम !
छूटी न किन्तु हठ उड़नेकी जो है स्वभावमें ही प्रियतम !३!

फिर, हुए अधीर मुझे अतिशय देखा जब थकी हुई प्रियतम !
कौशल अपनाकर, जाल नया फैलाया क्षणमें ही प्रियतम !
सहसा अवनीकी ओर दृष्टि मेरी गड़ गयी तथा प्रियतम !
दीखा श्यामल सुन्दर पिंजर अब तो गति रुद्ध हुई प्रियतम !४!

ढल पड़ी निकट आकर, फेरी दो चार बार उसकी, प्रियतम !
दी, और अचानक यन्त्रित-सी घुस पड़ी भला उसमें प्रियतम !
हो गया द्वार बस, रुद्ध और फँस गयी चंचला मैं  प्रियतम !
विश्राम-सदनमें मुझको तुम लाकर इस भाँति हँसे प्रियतम !५!

उसके पश्चात् अहर्निश जो घटनाएँ वहाँ घटीं प्रियतम !
विवरण उनका अब कौन करे संचित हैं हृत्तलमें प्रियतम !
द्रुम-पत्रावलि उन छिद्रोंके पथसे आती, उससे प्रियतम !
छू जाता चंचु, और उसपर अंकित कुछ हो जाती प्रियतम !६!

बाहर समीर उस पथसे ही उसको फिर ले जाता प्रियतम !
सौरभसे सनी हुई उसकी मोहकता अब बढ़ती प्रियतम !
पर गन्ध-फलीका वह वन था, भौंरा कैसे आवे प्रियतम !
फिर थी बिखरी पत्रावलि, ले उद्दाम पवन भागा प्रियतम !७!

पंकिल थलमें कुछ नष्ट हुई, काँटोंकी झाड़ीमें प्रियतम !
कुछ गिरी, बची फिर भी कुछ थी, पर था विधान ऐसा प्रियतम !
हो जायँ लुप्त अंकित बातें लीला की तुमने ही प्रियतम !
दावाकी एक लहर आयी स्वाहा हो गयी सभी प्रियतम !८!

आँधी फिर एक बड़ी आई, चिन्तित मैं स्वयं हुई प्रियतम !
पिंजर न कहीं उड़ जाय और वे टूट जायँ सपने प्रियतम !
जिनको प्रति पल थी सजा रही, रो-रोकर मैं भोली प्रियतम !
तुम हँसे, और आकाश बना निर्मल निमेष ही में प्रियतम !६!

रजनी आती, दिनकर हँसता, क्रमशः सब ऋतुएँ भी प्रियतम !
आकर अपनी-अपनी क्रीड़ा दिखलाकर छिप जाते प्रियतम !
कैसी, क्या-क्या अनुभूति हुई मुझको उन वर्षोंमें प्रियतम !
बन जाय पुराण नवीन अहो ! गाने लग जाऊँ जो प्रियतम !१०!

जितना सम्भव हो, मौन रहे, है रसकी परिपाटी प्रियतम !
इसलिए प्यारकी वह गाथा ले जाऊँगी मनमें प्रियतम !
चर्चा पर जब कर बैठी हूँ तो इतनी सी कह दूँ प्रियतम !
कुछ बात बदलकर वर्तमान एवं अतीतकी भी प्रियतम !११!

दीना खिन्ना भ्रमिता भूखी पिंजरसे जुड़ती-सी प्रियतम !
थी पड़ी, द्रवित होकर तुमने छातीसे लगा लिया प्रियतम !
दे रखा जीवनेश्वरी तथा प्रियतमा वल्लभाका, प्रियतम !
जो पद था, नित्य मुझे उसका संकेत चले करने प्रियतम !१२!

क्षण एक हुआ था आई ही पिंजर-परिसरमें थी प्रियतम !
उसके काले घेरेका था छू गया अंश मुझसे प्रियतम !
ऐसी प्रतीति उस समय हुई मानो चिर परिचित था प्रियतम !
सुन्दर वह नित्य भवन मेरा, भूला-सा हुआ अभी प्रियतम !१३!

द्वादशी प्रदोष समय आश्विन शुक्लाकी यह घटना प्रियतम !
तेइस वर्षोंसे पहले की वैसी ही दीख रही प्रियतम !
पर जो फुलेलका ही करके आचमन कहे मीठा प्रियतम !
देना फिर उसको पुष्प-सार केवल गँवारपन है प्रियतम !१४!

दोहा* प्राचीन एक कविका है भाव लिए ऐसा प्रियतम !
जो है घट चुका सत्य बनकर कुछ वर्ष अभी पहले प्रियतम !
जीवनमें इस विहंगिनीके कर-करके व्यथित इसे प्रियतम !
कम-से-कम नौ दस बार, अतः रुक रही गिरा अब है प्रियतम !१५!

जो समझ सके, समझे इसको आगे चलती मैं हूँ प्रियतम !
छब्बीस पहरकी सरस विरस अनुभूति न कहकर ही प्रियतम !
समला प्रवाहिनी क्षुद्र एक जो थी उसके तटकी प्रियतम !
बातोंको छूती हुई तनिक दाएँ बाएँ मुड़ती प्रियतम !१६!

क्या से क्या कुछ दिनमें ही था जीवनका हाल हुआ प्रियतम !
कैसे बह गयी ज्ञान-गरिमा इस नीली धारामें प्रियतम !
कैसे क्रमशः पिंजरमें थी आसक्ति बढ़ी मेरी प्रियतम !
सुनने वाला न मिला इसको, सुननेवाली न मिली प्रियतम !१७!

जो हो, फिर परिच्छेद मधुमय आया जिसमें तुमने प्रियतम !
माया थी रची चित्रपटके होठोंकी ओट लिए प्रियतम !
'प्रगट्यो ग्वालिनी नेह पूरन' पदका अन्तस्तलमें प्रियतम !
नयनोंमें और अहंतामें था राग लगा छिड़ने प्रियतम !१८!

जो ज्ञान शुद्ध रसमय तरु दो तोरण हैं बने हुए प्रियतम !
है एक सारथी रथ चिन्हित, मुनि कीर एक पर है प्रियतम !
सन्धिस्थलपर मिलती-सी हैं दो सत्ता जहाँ अहो ! प्रियतम !
इस दृश्य विश्वका इधर, और उस ओर तूर्य रसका प्रियतम !१६!

दोनों द्रुमसे लिपटी फूली वह भावमयी वल्ली प्रियतम !
जो है, उसकी टहनीपर ही पिंजरा था झूल रहा प्रियतम !
उसके भीतर पत्रोंसे सट बैठी थी मैं बिहगी प्रियतम !
उन रागोंसे मन बहलाती उरमें रखकर तुमको प्रियतम !२०!

कोई क्षण भरके लिए विहग बाहरका सुन लेता प्रियतम !
मेरा स्वर, और मुग्ध होता, पर दाद न दे पाता प्रियतम !
केदारा, नट या मालकोश पीलू ही गाती थी प्रियतम !
मेरे पर षडज ऋषभ सब वे थे भिन्न, न मिलते थे प्रियतम !२१!

संचालित तुम कर देते थे पिंजड़े को, वह हिलता प्रियतम !
झोंटा खाकर डर जाती थी, सुखमत्त कभी होती प्रियतम !
चिन्तित-सी कभी क्षणिक होती, भावी है क्या मेरी प्रियतम !
पर हुआ न अहो विराम कभी मेरी स्वर-लहरी का प्रियतम !२२!

अब सुनो रसीली वह गाथा, तुमने सरकाया था प्रियतम !
पिंजड़ेको उस टहनीपर ही, पूरबकी ओर किया प्रियतम !
मैं लगी देखने दृश्य सुखद शुभ था विपाक आया प्रियतम !
भावुकतामय मेरे जो थे वे सत् प्रयास उनका प्रियतम !२३!

वैकुण्ठ नामकी नगरी थी, ज्ञानी थे एक वहाँ प्रियतम !
राजा विदेहके सदृश भला प्रेमी रघुकुलमणिके प्रियतम !
आदर्श चरित्रोंके वे थे, 'जय सीताराम' तथा प्रियतम !
'नारायण' नाम अधिक उनको प्रिय था ऐसा लगता प्रियतम !२४!

जीवनमें उनके छाया थी उस तुलाधारकी भी प्रियतम !
थे अतिशय सरल, दक्षपर थे जगके व्यवहारोंमें प्रियतम !
देखा था उनको मैंने जब आकाशचारिणी थी प्रियतम !
होती थी सुनकर फुल्ल सदा प्रवचन पवित्र उनका प्रियतम !२५!

पिंजड़ेपर हाथ धरे रहते हरदम वे थे अपने प्रियतम !
थे खड़े उधर तुम भी छिपकर उसपर कर मृदुल रखे प्रियतम !
थी नहीं अहंता उनमें, फिर पिंजड़ेमें क्या रहती प्रियतम !
मुझसे विनोद करनेकी थी वह युक्ति अहा कैसी प्रियतम !२६!

बातें सुरसरिता-तटपरकी रवितनय तपोवनकी प्रियतम !
वे हैं इससे पहलेकी, पर कहने लग जाऊँ जो प्रियतम !
लंबी अत्यधिक कथा होगी, श्रोता भी है न यहाँ प्रियतम !
जिसके दृग बनें सजल सुनकर, इसलिए छोड़ दी है प्रियतम !२७!

इच्छा थी केवल आठ गीत लेकर उन गीतोंसे प्रियतम !
गा जाऊँ, पर लीला जब है हो रही यहाँ ऐसी प्रियतम !
है उचित यही कुछ दिन देखूँ, कैसे क्या होता है प्रियतम !
तुम तो हँसते ही हो हरदम, मैं भी क्यों नहीं हँसू प्रियतम !२८!

अभिनव रंगस्थलकी रचना पहले हो जाय तभी प्रियतम !
गानेवाली गाऊँ मैं, तुम सुननेवाले सुनलो प्रियतम !
संभव है कुछ ऐसा ही तुम हँसकर हो सोच रहे प्रियतम !
इसलिये रोक देते हो तुम लोनी दृगभंगीसे प्रियतम !२६!

पर इन पद-नलिनोंकी रजकी परछाँई भी मुझसे प्रियतम !
सपनेमें भी न तिरस्कृत हो, यह सत्य मनोरथ है प्रियतम !
वे गीत न सही, चलो आगे अब 'महाभाव' का ही प्रियतम !
संगीत सुनाऊँ मैं तुमको धीमे-धीमे स्वर में प्रियतम !३०!

सोई थी वह निकुंजमें तुम जिसको प्रियतमे ! अहो प्रियतम !
हे प्राणवल्लभे ! ईश्वरि हे प्राणोंकी कहते हो प्रियतम !
तुम उसके चरण-सरोरुहको अपनी अलकावलिसे प्रियतम !
थे पौंछ रहे धीरे धीरे, श्रीमुख था राग-भरा प्रियतम !३१!

मृदुल स्मितमें गहरापन था, आँखोंकी मद-धारा प्रियतम !
थी आज अधिक गहरी, कुछ थे वे अंग शिथिल गोरे प्रियतम !
श्रम-सीकर उदित कपोलोंपर होनेवाले-से थे प्रियतम !
हेमन्त वातसे रह-रहकर तन छू जाने पर भी प्रियतम !३२!

रजनी भी प्रायः बीत गयी उजियारी चौदसकी प्रियतम !
पत्तोंसे विरचित वातायन कम्पित हो जाता था प्रियतम !
उस पथसे ही हिमकर-किरणें होकर शर्मीली-सी प्रियतम !
उस कुंजथलीकी देवीको लेती थीं देख कभी प्रियतम !३३!

जिज्ञासा-भरे लोचनोंसे तुमने उसके मुखको प्रियतम !
देखा था क्षणभर, और हुए शंकित उन चिन्होंसे प्रियतम !
व्रजवाम-दृगोंकी भंगीके जो अर्थ मनोहर हैं प्रियतम !
उनका पण्डित तुम-सा न हुआ, है नहीं, न होगा ही प्रियतम !३४!

तुम लगे सोचने भ्रम ऐसा है हुआ न कभी मुझे प्रियतम !
हैं सत्य मानिनी जीवनकी रानी हो रहीं अभी प्रियतम !
मैं भले न कारण जान सकूँ या सिद्ध इसे कर दूँ प्रियतम !
हूँ चूक गया पर मैं अवश्य इस समय कहीं न कहीं प्रियतम ! ३५!

अन्तर्मनकी चिन्ता यह थी नीले मुखपर आयी प्रियतम !
इन बिम्बविडम्बी अधरोंका 'सी सी' रव बन करके प्रियतम !
तत्काल उठी प्रियतमा और कर-पल्लवकी माला प्रियतम !
वल्लभकी ग्रीवामें पहना ढल पड़ी अंशपर थी प्रियतम ! ३६!

वैसे ही मुद्रित नयन हुए तुम साँवर सुन्दरके प्रियतम !
नीरवताका आवरण लिए प्राणोंमें प्राण मिले प्रियतम !
अनुभूति परस्पर रसमय दो प्राणोंकी एक हुई प्रियतम !
संविद् वह नील कि पीत बचा यह बनी पहेली थी प्रियतम !३७!

कुछ तो था बचा अवश्य वहाँ, इससे क्या अधिक कहूँ प्रियतम !
सच तो यह है निर्देश अहो सर्वथा असम्भव है प्रियतम !
कहनेवाली सुननेवाले दोनों जब एक हुए प्रियतम !
फिर कौन, कहाँ, किससे, क्या तो कह दे, अथवा सुन ले प्रियतम !३८!

जैसे पर चंचल लहरें हैं सागरकी टकराती प्रियतम !
दो भिन्न दिशाओंसे आकर कण-कण मिल जाता है प्रियतम !
है दो प्रवाह उसमें तथापि, देखें हम, मत देखें प्रियतम !
उच्छलित बूँद भी होती है, वैसे ही कह-सुन लें प्रियतम !३६!

कहनेके लिए श्यामवर्णा रमणी थी एक वहाँ प्रियतम !
थी किंतु मनोहर पिंगलता उसके हृदयस्थलमें प्रियतम !
आँखें थीं सजल, मुक्तकेशी विक्षिप्त हुई-सी थी प्रियतम !
अपना इतिवृत्त सुनाती कुछ अपनेको ही वह थी प्रियतम !४०!

बोली वेदना भरे स्वरमें दोलित कर चिकुरोंको प्रियतम !
कोई न बची, जिसकी काली पुतलीको देख सकूँ प्रियतम !
दर्पण होता अपने दृगका प्रतिबिम्ब देख लेती प्रियतम !
मैंने ही फोड़ दिया उसको चिढ़कर हँसता वह था प्रियतम !!४१!!

यह सूख गयी नीली सरिता, सागर वह सूख गया प्रियतम !
जलते तनको शीतल कर लूँ पैठी थी मैं इनमें प्रियतम !
ये सह न सके मेरी ज्वाला उसमें ही लुप्त हुए प्रियतम !
परछाँही-दर्शनका साधन खो गया सुलभतम भी प्रियतम !४२!

मिट गए सदाके लिए यहाँ वे देव किरणमाली प्रियतम !
मिट गयी किरणकी राशि सृजन करनेवाली छाया प्रियतम !
मैं खड़ी हुई ही थी आकर जाँचूँ कण एक दया प्रियतम !
तन छाँह थलीमें मिले, किंतु जल गए वरद वे ही प्रियतम !४३!

उनके ही साथ जला हिमकर रजनी-दिन अब न रहे प्रियतम !
है एक अँधेरा, इसीलिए जीती अब तक मैं हूँ प्रियतम !
तुम अहो त्रिभंगीनाथ रमण मोहन जीवनधनकी प्रियतम !
आकृति उसकी छाया न सही, है बची कृष्णता जो प्रियतम !४४!

श्रवणोंमें वेणुनादकी सच झंकृति थी या भ्रम था प्रियतम !
हूँ पूछ चुकी आकाश मुझे बतला दे बात सही प्रियतम !
उत्तर पर इसने नहीं दिया मत दे, क्या करना है प्रियतम !
भ्रम था तो मिटे न कभी, सत्य यदि था, धिक् है मुझको प्रियतम !४५!

उन कोमल कर-कमलोंकी, फिर उन अधर सुमन-दलकी प्रियतम ! 
त्वक्पर थी छाप पड़ी, अथवा वह मात्र कल्पना थी प्रियतम !
रे पवन ! कभी मत बतलाना, सौ बार भले पूछूँ प्रियतम !
कह कर अबला बधका पातक चिरकाल न तू ढोना प्रियतम !४६!

भस्मावशेष अब हुए तपन शशि पुनः कदाचित् हों प्रियतम !
जीवित अपने ही किसी पुण्यबलसे चलकर आगे प्रियतम !
दोनोंसे ही विनती यह है मेरी, वे सदय बनें प्रियतम !
वह रूप-दृगोंमें सच आया, या चिन्तन था, न कहें प्रियतम !४७!

वह सत्य निराविल सुधामयी रस पान-मत्तता थी प्रियतम !
माया थी केवल रची हुई अथवा मेरी अपनी प्रियतम !
जानूँ, है चाह नहीं अब, है हित भी न जाननेमें प्रियतम !
जब दूर पिलानेवाला है, इस पीनेवालीसे प्रियतम !४८!

हो गयी धरा परिणत भीषण सर्वथा मरुस्थलमें प्रियतम !
सौरभका लेश नहीं इसमें है शेष कहींपर भी प्रियतम !
कैसे निर्णय अब करूँ भ्रमित थी हुई, सत्य ही या प्रियतम !
नीले अंगोंकी वह सुगन्ध अप्रतिम मिल गयी थी प्रियतम !४६!

कालेको छूकर मन मेरा हो गया निपट काला प्रियतम !
कुछ भी संकल्प करूँ, काला होकर वह निकलेगा प्रियतम !
यह असित रंग घन-घनतर अब होगा क्रमशः आगे प्रियतम !
है अतः अनन्तकाल तक ही जीवित रहकर रोना प्रियतम !५०!

रो-रोकर अहो निरन्तर मैं कालेमें बदल गयी प्रियतम !
पल्लवका तल्प साथ ही वह काला हो गया भला प्रियतम !
वे पत्र निकुंजवल्लियोंके काले हो गए सभी प्रियतम !
उस कुंजस्थलका कण-कण ही काला-काला अब है प्रियतम !५१!

बंकिम चितवन, बंकिम सुकण्ठ, बंकिम कटिकी झाँकी प्रियतम !
जिस तरुके अन्तरालसे थी, वह अन्तिम बार हुई प्रियतम !
आगे अत्यंत सघन वन था दृग देख न सकते थे प्रियतम !
वे सभी सदाके लिए यहाँ काले हो गए अहो प्रियतम !५२!

वह तुंग शैल गोवर्धनके जिसपर वे खड़े हुए प्रियतम !
जानेसे एक दिवस पहले लेकर दुकूल पीला प्रियतम !
फहरा फहरा करके गोधन एकत्र कर रहे थे प्रियतम !
रत्नोंकी ज्योति गयी वह भी कालेमें लीन हुआ प्रियतम !५३!

मेरे दृगकी भी ज्योति गयी कालेमें समा गयी प्रियतम !
कैसे समझूँ है प्राची यह, या दिशा प्रतीचीकी प्रियतम !
हे सर्वनियन्ता ! तुमसे यह मैं भीख माँगती हूँ प्रियतम !
दिग्भ्रममें भी मैं पैर रखूँ, जिस ओर चाहती हूँ प्रियतम !५४!

वह देश दूर है आज जहाँ मेरे प्राणाधिक हैं प्रियतम !
उससे विपरीत दिशामें ही मैं भाग चलूँ अब तो प्रियतम !
है तापमान इन साँसोंका प्रतिपल बढ़ता जाता प्रियतम !
इनकी गरमी न लगे, जिससे उस नील कलेवरको प्रियतम !५५!

अलिकुल गुन-गुन करता था क्यों मेरे पीछे वे थे प्रियतम !
वे चले गये अतएव देह यह सड़ी-गली अब है प्रियतम !
यह गन्धवाह इसलिये यहाँ निश्चय कपूय होगा प्रियतम !
मैं चलूँ और भी दूर गन्ध उनके न पास पहुँचे प्रियतम !५६!

मैं नहीं मरूँगी कभी, सत्य यह है त्रिकाल, फिर भी प्रियतम !
यह तन तो सदा जलेगा ही काली उन लपटोंमें प्रियतम !
फैलेगी धूम राशि नभमें मैं इतनी दूर चलूँ प्रियतम !
धूआँ लाकर पंकिल न बनें वे दृग सरोज-दल-से प्रियतम !५७!

है पता नहीं इस समय वहाँ वे क्या करते होंगे प्रियतम !
चंचल उनका स्वभाव कैसे मिट गया अभी होगा प्रियतम !
वे पुष्प चयन करके गुम्फित कर रहे हार ही हों प्रियतम !
दे भुजा किसीकी ग्रीवामें अथवा हों झूल रहे प्रियतम !५८!

किसलयकी शय्या प्रस्तुत कर उत्कंठित आँखोंसे प्रियतम !
गिरवरके पार, बाट या हों मेरी ही देख रहे प्रियतम !
है किन्तु पिशाची आशा यह ठग रही पुनः मुझको प्रियतम !
जाते ही क्यों जो सुख मिलता उनको इस दासीसे प्रियतम !५६!

मैं हाय! किन्तु साँवर उनके प्रस्वेद भरे मुखको प्रियतम !
भूलूँ किस भाँति चित्त जिससे प्रतिचित्रित हो न वहाँ प्रियतम !
होगा वह निस्सन्देह नील परिपूरित, आहोंसे प्रियतम !
धू-धूकर तनके जलनेकी ज्वालाएँ लिए हुए प्रियतम !६०!

छू गये कहीं क्षणभर भी वे इस मनकी किरणोंसे प्रियतम !
काननसे पार गये उनका सब रस फीका होगा प्रियतम !
वानीर कुंजकी वे बातें हृत्तलमें जागेंगी प्रियतम !
वे खिली हुई उरकी कलियाँ कुम्हला कर झर न पड़ें प्रियतम !६१!

कोई-सा प्रबल सुकृत मेरा उनके बलसे जागे प्रियतम !
जाऊँ मैं भूल सत्य उनको, इसके अतिरिक्त भले प्रियतम !
कुछ भी कर लूँ यह मन उनमें प्रतिबिम्ब नहीं डाले प्रियतम !
है शक्य नहीं यह तो चाहे मैं कहीं चली जाऊँ प्रियतम !६२!

धिक्कार अनन्तकाल तक है प्रतिपल शत-शत मुझको प्रियतम !
मेरा मन बना विघातक है जीवन धनके सुखका प्रियतम !
रोकर भी मैं सुखिया रहती सुखमें यदि वे होते प्रियतम !
मेरी यह याद किंतु उनको हरदम पीड़ा देगी प्रियतम !६३!

अच्छा, मैं एक उपाय करूँ वे श्याम मनोहर हैं प्रियतम !
इतनी-सी याद सही-झूठी अबतक है बनी हुई प्रियतम !
मैं गढूँ एक प्रतिमा सुन्दर मानसी बालिकाकी प्रियतम !
उन-से ही कृष्ण सलोने मुख-कर-पद-अंगों वाली प्रियतम !६४!

उसके परिधान सभी होंगे उनके समान पीले प्रियतम !
भूषित वनमालासे प्रतिदिन कर दूँगी मैं उसको प्रियतम !
मेरे प्राणोंकी चेतनता उसमें पूरित होगी प्रियतम !
होगी वह नित्य बहिन मेरी, प्राणोंमें बसी हुई प्रियतम !६५!

उनका स्वभाव अप्रतिम शील उसमें भर दूँगी मैं प्रियतम ! 
अनुगमन करेगी छाया-सी एकत्व किये मुझसे प्रियतम !
देखूँ मैं उसे, न देखूँ वह देखेगी मुझको ही प्रियतम !
उसके जीवनका अवलम्बन मैं ही बन जाऊँगी प्रियतम !६६!

उसको फिर मैं वंशीमें स्वर भरना सिखलाऊँगी प्रियतम !
बतला न भले पाऊँ अनन्त उन राग लहरियोंको प्रियतम !
कल्याण-साँझवाले स्वरको हृदयंगम कर लेगी प्रियतम !
जो प्रिय अत्यन्त नाम मेरा उनको था, गा लेगी प्रियतम !६७!

उसमें ही चित्त फँसाऊँगी प्रतिपल हँस-हँस करके प्रियतम !
देखूँ इस भाँति भूल पाऊँ दुःसह वेदना कहीं प्रियतम !!
मेरा प्रसन्न मन फिर उनमें प्रतिभात लगे होने प्रियतम !
निश्चिन्त सोचकर वे हों यह कि किंकिरी न दुखिया है प्रियतम !६८!

उसके दिन सुखसे कटते हैं भूली-सी अब वह है प्रियतम !
संकल्प सदाके लिए मिटे उनका मैं लौट चलूँ प्रियतम !
जीवनकी साध मिले मुझको, हो जाएँ सुखी अब वे प्रियतम !
विस्मरण हुआ जो है मेरा, उनको चिरकाल रहे प्रियतम !६६!

पर कहीं स्व-सुखमें मत्त हुई कोई मधुपुर-रमणी प्रियतम !
लेकर भुजबन्धनमें उनको खोकर विवेक अपना प्रियतम !
कंकणका चिन्ह बना देगी उस नील मृदुल तनमें प्रियतम !
वे भले न जानें, पर अंकित होगी ही वह मुझमें प्रियतम !७०!

प्राणोंका क्रन्दन करुण तथा उस समय उठेगा ही प्रियतम !
अब कौन सँभाल करे साँवर तनकी इस चिन्तासे प्रियतम !
परिरम्भणका वह सुख तो सच अविलम्ब जले जिससे प्रियतम !
आयी न सावधानी इतनी मर्दित न नील तन हो प्रियतम !७१!

हैं परम उदार सुमधुर धीर अद्भुत वे रसदानी प्रियतम !
उनको कुछ भी हो जाय भले क्षत लगे स्याम तनमें प्रियतम !
वे तो निमग्न कर देंगे ही उस सुधा-सरोवरमें प्रियतम !
जिसकी ही एक बूँदसे हैं निःसृत रतिनायक ही प्रियतम !७२!

ऐसे अनमोल महामरकतमणि जो वे हैं मेरे प्रियतम !
उनका आदर करके अपने दृगमें रखनेवाली प्रियतम !
कोई तरुणी हो तभी भले मेरा मन फुल्ल बने प्रियतम !
अन्यथा रुलाऊँ मैं उनको जीना है इसीलिए प्रियतम !७३!

ऐसे जीवनसे अच्छा था अधमा इस दासीका प्रियतम !
अस्तित्व नहीं होता अनादि एकाकी वे रहते प्रियतम !
हूँ किन्तु गँवारी मैं क्या इन बातोंको समझ सकूँ प्रियतम !
क्या पता अधिक सुख होता हो रोनेमें हँसनेसे प्रियतम !७४!

अब कहाँ चलूँ, किससे पूछूँ, क्या करूँ अनाथा मैं प्रियतम !
वे ही जब चले गए, मुझपर अब कौन दया करके प्रियतम !
जलना था, जलती, पर उनकी पीड़ा न सही जाती प्रियतम !
देखो री हाय ! हाय ! वे तो रो रहे वहाँ पर हैं प्रियतम !७५!

रे हाय ! हुए गीले उभरे श्यामल कपोल दोनों प्रियतम !
आयी-आयी, अर्बुद मेरे प्राणोंके हे स्वामी प्रियतम !
पौछूँगी अभी तुरंत अश्रु अपने ही हाथोंसे प्रियतम !
मानिनी कहाँ, सच हूँ तुमसे कर रही खेल मैं थी प्रियतम !७६!

प्रस्तर खण्डों का काँटों का गह्वर पूरित वन था प्रियतम !
कोई पथ पगडंडीका भी मैं देख न पाती थी प्रियतम !
सूनापन था, गड़गड़ रव था युगपत् थी घोर निशा प्रियतम !
उसमें तुम थे जा छिपे तथा चिन्ता थी हुई मुझे प्रियतम !७७!

उन शत-शत नलिन दलोंकी मृदु शय्या वह दूर रहे प्रियतम !
अपनी इन नयन पुतरियोंकी जो सेज बनाऊँ मैं प्रियतम !
उसपर भी जब पधरानेमें तुमको सकुचाती हूँ प्रियतम !
कैसे न छिदेंगे वे दोनों पद इस मनमानीसे प्रियतम !७८!

शासन करनेकी वृत्ति जगी जिससे तुम डर जाओ प्रियतम !
क्षणभरके लिए भले पर रस-निर्झर ही रुद्ध हुआ प्रियतम !
साहस न कभी तुममें आए इस भाँति भागनेका प्रियतम !
निर्भय हो सत्य निकुंजपति अब होंगे न चपल ऐसे प्रियतम !७६!

रोने लग जाओगे तुम जो यह बात जानती मैं प्रियतम !
कोई दूसरा उपाय सरस करती समझानेका प्रियतम !
अनुरक्ति अहो इस ममतापर बलिहार हुई पहुँची प्रियतम !
इतना कहकर फिर अट्टहास करके बोली वह थी प्रियतम !८०!

दो टूक हुआ आकाश मिटी वह नभस्वान सत्ता प्रियतम !
है समा गया सब कुछ तो ही फटनेके उस रवमें प्रियतम !
मैं भी अब चली, गई कलना, है प्रकृति नहीं, चिति है प्रियतम !
हूँ महाप्रलयके पार अहा! क्रन्दन कि हास यह है प्रियतम !८१!

उस तरुणीके तनका कण-कण इतनेमें बिखर गया प्रियतम !
पिंगलता अतुल उरस्थलकी, तनकी कृष्णता तथा प्रियतम !
परिपूरित थी प्रत्येक दिव्य, उड़ते-से उस कणमें प्रियतम !
प्रत्येक, और हो गया लीन तुम दोनोंकी द्युतिमें प्रियतम !८२!

इस भाँति अकूल रसोदधिके निरुपम उद्वेलनमें प्रियतम !
जो अहो स्वरूपविलास नित्य तुम लीलामयका है प्रियतम !
है काल न, जहाँ प्रतिष्ठित है जो अपनी महिमामें प्रियतम !
मज्जन कर तुम जग उठे, जगी प्राणोंकी वह देवी प्रियतम !८३!

तुम दोनोंकी अनुभूति एक थी आदि अंत तककी प्रियतम !
पर बड़े मर्मका अतुल सरस अन्तर था इतना-सा प्रियतम !
तुम कहते थे प्रियतमे ! श्याम उर था वह गोरी थी प्रियतम !
थी उक्ति वल्लभाकी श्यामा वह थी उर था गोरा प्रियतम !८४!

यह महाभावमय गीत नहीं है सुना किसीने भी प्रियतम !
प्रायः विहंग विहगी-दल इस काननके मोहित हैं प्रियतम !
हैं व्यस्त मदनके दर्शनमें, दाना बटोरनेमें प्रियतम !
चें-चें कर अहो! परस्पर फिर उड़-उड़ कर लड़नेमें प्रियतम !८५! 

है किन्तु अहो यह भी लीला तुम जीवनधनकी ही प्रियतम !
चालक तुम हो, सब पुतली हैं, मलिना अवश्य मैं हूँ प्रियतम !
है प्रिय तथापि मेरी वाणी तुमको, स्वरूपसे हो प्रियतम !
अद्भुत अदोष-दर्शी तुम जो, विह्वल हो जाते हो प्रियतम !८६!

क्यों सुने, धरा क्या है इसमें, यह बुद्धि लिए जो हैं प्रियतम !
गाती थी मैं, सुनते थे तुम, गाती हूँ तुम सुन लो प्रियतम !
हैं कहते उपसंहार जिसे वह किंतु उपक्रमके प्रियतम !
अनुरूप बने, है नियम यही, अतएव यही अब हो प्रियतम !८७!

उन आठ मनोहर गीतोंकी सूची रच देती हूँ प्रियतम !
जो हैं उस पिंजरकी छाया छिति-तल पर पड़ी हुई प्रियतम !
तुम नित्य यशोदा उदरस्थल-सागरसे प्रकट हुए प्रियतम !
शशधरके शुभ्र चाँदनीमें उसके हिल जानेसे प्रियतम !८८!

अर्चन करने मैं बैठी थी सन्मुख मेरे तुम थे प्रियतम !
तुम पर थी फूल चढ़ाती, पर पिंजरपर चढ़ जाता प्रियतम !
इस भाँति अनेक बार जब था दीखा, चकराई मैं प्रियतम !
तुमने समझाया तभी मर्म इसका मैं समझ सकी प्रियतम !८६!

विहगीसे मैं थी रमणीमें परिणत हो गयी अहो प्रियतम !
क्षण एक अभी पहले जो था पिंजड़ा वह भी बदला प्रियतम !
षोड़शी सुन्दरी बाला थी अब वहाँ, और मैं थी प्रियतम !
उसके समीप, वह थी मेरी अलकें सज्जित करती प्रियतम !६०!

मेला था या बाजार इसे था कठिन समझ लेना प्रियतम !
अध्यस्त हो गयी मैं सहसा उस साधु-कलेवरमें प्रियतम !
अधिदेव नित्य पिंजरके तुम उसमें से थे निकले प्रियतम !
मुझको दिखला दी फिर सूची भावी उस लीलाकी प्रियतम !६१!

लेकर अपना ही नाम भला थी पूछ रही तुमसे प्रियतम !
है कहाँ महारस? तुम कहते पिंजर ही तो वह है प्रियतम !
अचरजमें पड़कर बार-बार थी दृष्टि डालती मैं प्रियतम !
आखिर वह भेद खुला रसमय वारीश उमड़ आया प्रियतम !६२!

था देश मरुस्थलका, रजनी आधी थी बीत गयी प्रियतम !
चूरण पीताभ बालुकाका विस्तृत हो गया तथा प्रियतम !
मैं तो थी देख रही सपना, उस ओर सत्य ही थे प्रियतम !
आये तुम पिंजरसे जुड़कर शिव कथा कह रहे थे प्रियतम !६३!

जिस वनमें गाय चराते हो, मुरली मुखरित जो है प्रियतम !
उसके उन निभृत निकुंजोंके सर्वथा अगम थलमें प्रियतम !
जा सकूँ, अतुल वह शक्तिपात तुमने पिंजर-छड़से प्रियतम !
था किया, सदाके लिए मिटा भिखमंगीपन मेरा प्रियतम !६४!

वह नंदगाँवकी थी झाँकी प्रस्तरकी प्रतिमा थी प्रियतम !
पिंजरसे प्रतिमाका अभेद मुझको था दीख रहा प्रियतम !
आगे चलकर तुरंत तुमने बतलाया स्वयं मुझे प्रियतम !
पिंजर तुम उपलमयी प्रतिमा है एक वस्तु तीनों प्रियतम !६५!

उन सिद्धनाथके पत्तनमें बनियेके बालकका प्रियतम !
था पावन महाप्रयाण इधर हो रहा, उधर मैं थी प्रियतम !
पिंजरेके साथ खिसक आयी उस भाव-लता पर ही प्रियतम !
अत्यन्त दूर, फिर भी स्वर यह संवादी मिला दिया प्रियतम !६६!

नैसर्गिक वत्सलताका रस कितना मीठा सच है प्रियतम !
जैसे पिंजरको कम्पित कर तुमने दिखलाया था प्रियतम !
उसका भी है इतिहास बड़ा सुन्दर शुभ सुखदायी प्रियतम !
है किंतु नहीं अवकाश यहाँ, फिर गोपनीय भी है प्रियतम !६७!

पिंजर काला प्रतीक यह है व्रजधरा अरण्य तथा प्रियतम !
सब मातृ-पितृ-कुलके परिकर वे श्वसुरालयके भी प्रियतम !
गोवंश वसन उपकरण सभी जनके तन धारणके प्रियतम !
सन्धिनी शक्तिकी परिणति ही जो हैं-इन सबका ही प्रियतम !६८ !

क्या कहूँ तथा क्या नहीं कहूँ, मैं समझ नहीं पाती प्रियतम !
पिंजरको सरका-सरका कर लीला तुमने जो की प्रियतम !
लजवंती लतिका-सी अगणित अनुभूति-राशि वह है प्रियतम !
वाणी छू लेगी यदि उसको, सिकुड़ेगी ही वह तो प्रियतम !६६!

पिंजर परिसरमें पत्तनकी रचना तुमने की थी प्रियतम !
मेरी मनुहार मनोरंजन करनेके लिए भला प्रियतम !
वह अब भी है पर बसे हुए उसमें तुम ही थे, हो, प्रियतम !
वैसे ही देख रही हूँ मैं उसको, उसमें तुमको प्रियतम !१००!

इन अगणित रूपोंमें मेरे सन्मुख आ आ करके प्रियतम !
जो प्यार दिया, देते हो, क्या संभव है कह देना प्रियतम !
आँखें ये सदा बनीं नीची लज्जा-कृतज्ञतासे प्रियतम !
रह जायँ और तुम पढ़ लो, है कितना बोझा इनमें प्रियतम !१०१!

आये विराम इस गाथाका इससे पहले तुमसे प्रियतम !
अपने मनकी वह बात तनिक जो नहीं यहाँ कह दूँ प्रियतम !
जो है लघु कुंजी-सी मेरे रसमय उस सागरकी प्रियतम !
हो जाय निरर्थक सब वर्णन, संकेत अतः सुन लो प्रियतम !१०२!

हो बने रामदेई माता मेरी तुम अभी यहाँ प्रियतम !
धरते न रूप यदि तुम ऐसा देते न बाँध फिर जो प्रियतम !
मुझ विहगीके पदको, अपनी ममताकी डोरीसे प्रियतम !
नीलमके इस पिंजड़ेमें थी आबद्ध, किंतु उड़ती प्रियतम !१०३!

लेकर सुंदर लट एक पुनः अपने कुंचित कचसे प्रियतम !
देकर फिर रूप उसे मेरी श्यामा भगिनीका हे प्रियतम !
दी पाँखें बाँध मृदुल उससे फड़-फड़ थीं जो करतीं प्रियतम !
ऐसी द्रुत गतिसे संभवतः जैसे वे टूट गिरें प्रियतम !१०४!

होता न सुभाव कहीं मेरी भगिनीका तुम-सा ही प्रियतम !
थी पाँख भले बन्धनमें, पर उड़ जाते प्राण कभी प्रियतम !
हो दैव-दलित यदि रह जाते, नीरस हो जाते ये प्रियतम !
कैसे नहलाती मैं तुमको प्रतिपल नव-धारासे प्रियतम !१०५!

जो हो इन रूपोंमें तुमने, मुझसे है खेल किया प्रियतम !
ये रूप सभी प्राणोंसे हैं प्रिय अधिक अतः मुझको प्रियतम !
होकर वियोग इनका न कहीं पड़ जाय रंग फीका प्रियतम !
अतएव साथ लेकर ही मैं जाऊँगी इन सबको प्रियतम !१०६!

मैया तन्मय होगी दोनों दृगकी इन पुतरीमें प्रियतम !
जिनमें अनादि कालसे ही रहती यह दासी है प्रियतम !
मेरी यह बहिन मिलेगी आ तुममें फिर बेसरमें प्रियतम !
हम दोनोंकी, एवं पिंजड़ा नीली द्युतिमें वपुकी प्रियतम !१०७!

ये सुमन एक सौ आठ अहो तुम वंशीधारीकी प्रियतम !
पद-रजको छूकर अभिलाषा पावन पूरी कर दें प्रियतम !
उन नित्य शारदा गोपीकी पुत्रीकी छायासे  प्रियतम !
भावित जो है यह बहिन रहेगी सदा जुड़ी तुमसे प्रियतम !१०८!


''';

class _AboutLogoSlideshow extends StatefulWidget {
  const _AboutLogoSlideshow();

  @override
  State<_AboutLogoSlideshow> createState() => _AboutLogoSlideshowState();
}

class _AboutLogoSlideshowState extends State<_AboutLogoSlideshow> {
  late final PageController _pageController;
  late int _currentPage;
  Timer? _autoSlideTimer;
  bool _userIsDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPage = _aboutUsLogoSlides.length * 1000;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.92,
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
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted || _userIsDragging || !_pageController.hasClients) return;

      final nextPage = _currentPage + 1;
      _currentPage = nextPage;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 380),
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
      height: 340,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (page) => _currentPage = page,
          itemBuilder: (context, index) {
            final slide =
                _aboutUsLogoSlides[index % _aboutUsLogoSlides.length];

            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                var scale = 0.92;
                if (_pageController.hasClients &&
                    _pageController.position.haveDimensions) {
                  final page = _pageController.page ?? _currentPage.toDouble();
                  scale = (1 - ((page - index).abs() * 0.08)).clamp(0.9, 1.0);
                }

                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: AspectRatio(
                          aspectRatio: slide.aspectRatio,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.primary.withOpacity(0.18),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                slide.path,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AboutUsPage extends StatefulWidget {
  const _AboutUsPage();

  @override
  State<_AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<_AboutUsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().resetFontSize(9);
      }
    });
  }

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
          title: const Text('About us'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
          actions: const [_TextSizeAction()],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            const _AboutLogoSlideshow(),
            const SizedBox(height: 24),
            Text(
              '॥ नित्य योगपीठ स्थित श्री श्रीगोलोक धाम ॥ ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _DrawerContentParagraph(_aboutUsContent, cs: cs),
          ],
        ),
      ),
    );
  }
}

class _VihanginiKavyaPage extends StatefulWidget {
  const _VihanginiKavyaPage();

  @override
  State<_VihanginiKavyaPage> createState() => _VihanginiKavyaPageState();
}

class _VihanginiKavyaPageState extends State<_VihanginiKavyaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().resetFontSize(9);
      }
    });
  }

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
          title: const Text('विहंगिनी काव्य'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
          actions: const [_TextSizeAction()],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
          children: [
            Text(
              'शतक',
              textAlign: TextAlign.center,
              locale: const Locale('hi', 'IN'),
              style: GoogleFonts.notoSerifDevanagari(
                color: cs.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _DrawerContentParagraph(_vihanginiKavyaContent, cs: cs),
          ],
        ),
      ),
    );
  }
}

class _DrawerContentParagraph extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _DrawerContentParagraph(this.text, {required this.cs});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return ValueListenableBuilder<double>(
      valueListenable: app.fontSizePreview,
      builder: (context, fontSize, _) {
        final style = GoogleFonts.notoSerifDevanagari(
          color: cs.onBackground.withOpacity(0.74),
          fontSize: fontSize,
          height: 1.62,
          fontWeight: FontWeight.w600,
        );
        final lines = text.trim().split('\n');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              _DrawerFormattedContentLine(
                line: line,
                style: style,
              ),
          ],
        );
      },
    );
  }
}

class _DrawerFormattedContentLine extends StatelessWidget {
  final String line;
  final TextStyle style;

  const _DrawerFormattedContentLine({
    required this.line,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (line.trim().isEmpty) {
      return SizedBox(height: (style.fontSize ?? 9) * 0.65);
    }

    final trimmed = line.trimLeft();
    final isRightAligned = trimmed.startsWith('[R]');
    final displayLine = isRightAligned
        ? trimmed.replaceFirst('[R]', '').trimLeft()
        : line.replaceAll('\t', '    ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        textAlign: isRightAligned ? TextAlign.right : TextAlign.center,
        locale: const Locale('hi', 'IN'),
        text: TextSpan(
          style: style,
          children: _drawerContentSpans(displayLine, style),
        ),
      ),
    );
  }

  List<TextSpan> _drawerContentSpans(String source, TextStyle baseStyle) {
    final parts = source.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? baseStyle.copyWith(fontWeight: FontWeight.w900)
              : baseStyle,
        ),
    ];
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

class _TextSizeAction extends StatelessWidget {
  const _TextSizeAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Text size',
      icon: const Icon(Icons.text_fields_rounded),
      onPressed: () {
        showDialog<void>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.18),
          builder: (context) {
            return Dialog(
              insetPadding: const EdgeInsets.only(top: 76, left: 22, right: 22),
              alignment: Alignment.topCenter,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const SizedBox(
                height: 58,
                child: FontSizeSlider(),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShareAppPage extends StatelessWidget {
  const _ShareAppPage();

  static const _shareUrl = 'https://www.youtube.com';

  void _closeToDrawer(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      'प्रियतम काव्य\n$_shareUrl',
      subject: 'प्रियतम काव्य',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Share App'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 24, 22, bottomInset + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.ios_share_rounded,
                  size: 44,
                  color: cs.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'प्रियतम काव्य',
                  textAlign: TextAlign.center,
                  locale: const Locale('hi', 'IN'),
                  style: GoogleFonts.notoSerifDevanagari(
                    color: cs.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _shareUrl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onBackground.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                ),
                const Spacer(),
              ],
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
          padding: EdgeInsets.fromLTRB(22, 18, 22, bottomInset + 24),
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
    this.textAlign = TextAlign.center,
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
        fontSize: AppProvider.defaultFont,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              width: 34,
              height: 1,
              color: cs.primary.withOpacity(0.42),
            ),
            const SizedBox(height: 9),
            Text(
              'Thank you for using',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onBackground.withOpacity(0.62),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'प्रियतम काव्य',
              textAlign: TextAlign.center,
              locale: const Locale('hi', 'IN'),
              style: GoogleFonts.notoSerifDevanagari(
                color: cs.primary,
                fontSize: 18,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Container(
              width: 34,
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
                '''आपके विचार और सुझाव हमारे लिए महत्वपूर्ण हैं।
ऐप से संबंधित किसी भी समस्या या सुधार के सुझाव यहाँ साझा करें।''',
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
