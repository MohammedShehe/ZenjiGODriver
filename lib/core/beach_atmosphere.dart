import 'package:flutter/material.dart';
import 'theme.dart';

/// Global visual identity layer: Zanzibar lagoon, sand and tropical coast.
/// It is deliberately a background layer so existing screens and flows remain intact.
class BeachAtmosphere extends StatelessWidget {
  final Widget child;
  final bool showImage;
  final double imageOpacity;

  const BeachAtmosphere({
    super.key,
    required this.child,
    this.showImage = true,
    this.imageOpacity = .14,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF06283A), Color(0xFF0B3448), Color(0xFF123A3E)]
                  : const [Color(0xFFFDF7E9), Color(0xFFEAF9F6), Color(0xFFDDF5F4)],
            ),
          ),
        ),
        if (showImage)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: imageOpacity,
                child: Image.asset(
                  'assets/images/zanzibar_beach_hero.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [Colors.black.withValues(alpha: .16), Colors.transparent, Colors.black.withValues(alpha: .10)]
                      : [Colors.white.withValues(alpha: .30), Colors.transparent, Colors.white.withValues(alpha: .12)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -70,
          child: IgnorePointer(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (dark ? ZenjiColors.darkAccent : ZenjiColors.teal).withValues(alpha: .10),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -110,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ZenjiColors.sand.withValues(alpha: dark ? .08 : .20),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
