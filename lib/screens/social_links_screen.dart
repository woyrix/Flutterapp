import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../navigation/home_scaffold_controller.dart';

class SocialLinksScreen extends StatelessWidget {
  const SocialLinksScreen({super.key});

  static const _officialChannels = [
    _SocialLink(
      title: 'प्रियतम काव्य',
      url:
          'https://youtube.com/channel/UC8TMvT-aZLUk1bLLAMSUstA?si=md5ZZofWGR81G4sg',
      imageUrl:
          'https://yt3.googleusercontent.com/bS3ana9it7i1EScXq_2oWFZJszq1q-gTAdawJV3N5raRHpKWXbA9GF6La05t_OvEA3rk3emy=s240-c-k-c0x00ffffff-no-rj',
      assetImage: 'assets/images/sidebar/perfect1.png',
      type: _SocialLinkType.youtube,
    ),
    _SocialLink(
      title: 'पद-रत्नाकर',
      url:
          'https://youtube.com/channel/UCwJknSLu2taM0b2F1IbcmVA?si=QPeQHcNbhEB-0Ew2',
      imageUrl:
          'https://yt3.googleusercontent.com/Orop3zhraSGw2K8yTjQLh6pdxP_QXXWY-aT011VtDlT49zH1t6rVHDRWekj3KLlCVA2CCs3ocko=s240-c-k-c0x00ffffff-no-rj',
      assetImage: 'assets/images/sidebar/perfect2.png',
      type: _SocialLinkType.youtube,
    ),
    _SocialLink(
      title: 'radhababaofgorakhpur',
      url: 'https://youtube.com/@radhababaofgorakhpur?si=aDb_6-s_n6zpgbjA',
      imageUrl:
          'https://yt3.googleusercontent.com/ytc/AIdro_nMTTKOfiVTS_ykXs_w91LoJ3xwSNfWIXjWwqipHTc=s240-c-k-c0x00ffffff-no-rj',
      forceSingleLineTitle: true,
      type: _SocialLinkType.youtube,
    ),
    _SocialLink(
      title: 'संत श्रीगयाप्रसाद जी महाराज',
      url: 'https://youtube.com/@saint_shreegayaprasad_ji?si=qrsNIUFbW7JCyILE',
      imageUrl:
          'https://yt3.googleusercontent.com/iuM5_1itkcl0A5Sr512W47a2_xBPQn5cGR4VA6cxsMeBMzEGVz-JWX7TdnutkW9T5Y1W-SHpKA=s240-c-k-c0x00ffffff-no-rj',
      assetImage: 'assets/images/sidebar/perfect 4.png',
      type: _SocialLinkType.youtube,
    ),
  ];

  static const _officialPlaylists = [
    _SocialLink(
      title: 'प्रियतम काव्य',
      url:
          'https://youtube.com/playlist?list=PLqYHT-_FCLCM0_Mrbv9N9982guDJKc1Xk&si=tg_JBKnlvZyAAXeh',
      imageUrl: '',
      type: _SocialLinkType.playlist,
    ),
    _SocialLink(
      title: '॥ विहंगिनी काव्य ॥ ',
      url:
          'https://youtube.com/playlist?list=PLqYHT-_FCLCPUrO7-bI3szBtz2rhpXj99&si=dbzWudsW3FKuQjGh',
      imageUrl: '',
      type: _SocialLinkType.playlist,
    ),
    _SocialLink(
      title: 'प्रियतम काव्य ॥ पूज्य श्रीनारायण दादा',
      url:
          'https://youtube.com/playlist?list=PLqYHT-_FCLCM4Nv28wzFONYH6EYwjrm6d&si=m66nHJeL2UtEe6RC',
      imageUrl: '',
      type: _SocialLinkType.playlist,
    ),
    _SocialLink(
      title: 'काव्य-मय सन्देश',
      url:
          'https://youtube.com/playlist?list=PLqYHT-_FCLCO0XKyrGx7MbV13pWm28MHC&si=WVJNnDpUqzXjsd8M',
      imageUrl: '',
      type: _SocialLinkType.playlist,
    ),
    _SocialLink(
      title: 'Internet Archive',
      url: 'https://archive.org/details/@golokdham/uploads',
      imageUrl: '',
      type: _SocialLinkType.archive,
    ),
  ];

  void _closeToDrawer(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => openHomeDrawer());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        _closeToDrawer(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          titleSpacing: 0,
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Social Media',
              maxLines: 1,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _closeToDrawer(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
          children: [
            _LinkSection(
              title: 'OFFICIAL PLAYLISTS',
              links: _officialPlaylists,
              cs: cs,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _LinkSection(
              title: 'OFFICIAL CHANNELS',
              links: _officialChannels,
              cs: cs,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkSection extends StatelessWidget {
  final String title;
  final List<_SocialLink> links;
  final ColorScheme cs;
  final bool isDark;

  const _LinkSection({
    required this.title,
    required this.links,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: cs.primary,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 14),
        for (final link in links) ...[
          _SocialHandleTile(link: link, cs: cs, isDark: isDark),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SocialHandleTile extends StatelessWidget {
  final _SocialLink link;
  final ColorScheme cs;
  final bool isDark;

  const _SocialHandleTile({
    required this.link,
    required this.cs,
    required this.isDark,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(link.url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Link open nahi hua'),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYoutube = link.type == _SocialLinkType.youtube;
    final isPlaylist = link.type == _SocialLinkType.playlist;
    final accent = (isYoutube || isPlaylist)
        ? const Color(0xFFE62117)
        : const Color(0xFF4F5D75);

    return Material(
      color: isDark ? cs.surface.withOpacity(0.86) : cs.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.primary.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              _LinkAvatar(
                link: link,
                accent: accent,
                isYoutube: isYoutube,
                isPlaylist: isPlaylist,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  link.title,
                  maxLines: link.forceSingleLineTitle ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: link.forceSingleLineTitle ? 15 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                link.url.isEmpty
                    ? Icons.link_off_rounded
                    : Icons.open_in_new_rounded,
                color: link.url.isEmpty
                    ? cs.onSurface.withOpacity(0.38)
                    : cs.primary.withOpacity(0.74),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final Color accent;
  final bool isYoutube;
  final bool isPlaylist;

  const _FallbackAvatar({
    required this.accent,
    required this.isYoutube,
    required this.isPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isPlaylist
        ? Icons.playlist_play_rounded
        : isYoutube
            ? Icons.play_circle_fill_rounded
            : Icons.archive_rounded;
    final radius = isPlaylist ? 8.0 : 23.0;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(isPlaylist ? 0.98 : 0.16),
            accent.withOpacity(isPlaylist ? 0.68 : 0.08),
          ],
        ),
        border: Border.all(
          color: accent.withOpacity(isPlaylist ? 0.3 : 0.18),
          width: 0.8,
        ),
      ),
      child: Icon(
        icon,
        color: isPlaylist ? Colors.white : accent,
        size: isPlaylist ? 31 : 28,
      ),
    );
  }
}

class _LinkAvatar extends StatelessWidget {
  final _SocialLink link;
  final Color accent;
  final bool isYoutube;
  final bool isPlaylist;

  const _LinkAvatar({
    required this.link,
    required this.accent,
    required this.isYoutube,
    required this.isPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaylist || link.type == _SocialLinkType.archive) {
      return _FallbackAvatar(
        accent: accent,
        isYoutube: isYoutube,
        isPlaylist: isPlaylist,
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 46,
        height: 46,
        child: link.assetImage.isNotEmpty
            ? Image.asset(
                link.assetImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackAvatar(
                  accent: accent,
                  isYoutube: isYoutube,
                  isPlaylist: isPlaylist,
                ),
              )
            : Image.network(
                link.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackAvatar(
                  accent: accent,
                  isYoutube: isYoutube,
                  isPlaylist: isPlaylist,
                ),
              ),
      ),
    );
  }
}

enum _SocialLinkType { youtube, playlist, archive }

class _SocialLink {
  final String title;
  final String url;
  final String imageUrl;
  final String assetImage;
  final bool forceSingleLineTitle;
  final _SocialLinkType type;

  const _SocialLink({
    required this.title,
    required this.url,
    required this.imageUrl,
    this.assetImage = '',
    this.forceSingleLineTitle = false,
    required this.type,
  });
}
