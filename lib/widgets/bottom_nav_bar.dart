import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/reader_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final cs = Theme.of(context).colorScheme;
    final alreadyHome = reader.bookIndex == 0 && reader.pageIndex == 0;

    void showMessage(String message, {int seconds = 2}) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(message),
          duration: Duration(seconds: seconds),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
    }

    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: 56,
      child: Row(children: [
        Expanded(
          child: _NavBtn(
            icon: Icons.chevron_left_rounded,
            label: 'Previous',
            iconFirst: true,
            enabled: reader.canPrev,
            onTap: () => context.read<ReaderProvider>().prevPage(),
          ),
        ),
        Container(width: 0.5, height: 28, color: cs.outline),
        Expanded(
          child: _NavBtn(
            icon: Icons.home_rounded,
            label: 'मुखपृष्ठ',
            enabled: true,
            isCenter: true,
            onTap: () {
              showMessage(
                alreadyHome
                    ? 'आप अभी मुखपृष्ठ पर ही हैं'
                    : 'मुखपृष्ठ पर लौटने के लिए थोड़ी देर दबाकर रखें',
              );
            },
            onLongPress: () {
              if (alreadyHome) {
                showMessage('आप अभी मुखपृष्ठ पर ही हैं', seconds: 1);
                return;
              }
              HapticFeedback.mediumImpact();
              context.read<ReaderProvider>().goHome();
              showMessage('मुखपृष्ठ खुल गया', seconds: 1);
            },
          ),
        ),
        Container(width: 0.5, height: 28, color: cs.outline),
        Expanded(
          child: _NavBtn(
            icon: Icons.chevron_right_rounded,
            label: 'Next',
            iconFirst: false,
            enabled: reader.canNext,
            onTap: () => context.read<ReaderProvider>().nextPage(),
          ),
        ),
      ]),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isCenter;
  final bool iconFirst;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.isCenter = false,
    this.iconFirst = true,
    this.onLongPress,
  });

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.enabled ? cs.primary : cs.primary.withOpacity(0.22);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
      onTapUp: widget.enabled
          ? (_) async {
              await _ctrl.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _ctrl.reverse();
              widget.onLongPress!.call();
            },
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox.expand(
          child: Center(
            child: widget.isCenter
                ? Icon(widget.icon, color: color, size: 24)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.iconFirst
                        ? [
                            Icon(widget.icon, color: color, size: 22),
                            const SizedBox(width: 2),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ]
                        : [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(widget.icon, color: color, size: 22),
                          ],
                  ),
          ),
        ),
      ),
    );
  }
}
