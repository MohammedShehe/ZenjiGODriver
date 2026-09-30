import 'package:flutter/material.dart';

/// Keeps the layout at a sane minimum size. When the window (for example a
/// browser window dragged very small) is narrower than [minWidth] or shorter than
/// [minHeight], the app keeps that minimum layout and scrolls, instead of throwing
/// hundreds of RenderFlex overflows. Phones are never this small, and the
/// on-screen keyboard does not shrink the constraints read here, so they are
/// unaffected.
class MinSizeGuard extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;

  const MinSizeGuard({
    super.key,
    required this.child,
    this.minWidth = 320,
    this.minHeight = 480,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) return child;
      final needsX = constraints.maxWidth < minWidth;
      final needsY = constraints.maxHeight < minHeight;
      if (!needsX && !needsY) return child;

      final width = needsX ? minWidth : constraints.maxWidth;
      final height = needsY ? minHeight : constraints.maxHeight;

      Widget content = SizedBox(
        width: width,
        height: height,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(width, height)),
          child: child,
        ),
      );
      if (needsY) {
        content = SingleChildScrollView(primary: false, child: content);
      }
      if (needsX) {
        content = SingleChildScrollView(primary: false, scrollDirection: Axis.horizontal, child: content);
      }
      return content;
    });
  }
}
