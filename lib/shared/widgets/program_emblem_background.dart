import 'package:flutter/material.dart';

/// Paints the grey project emblem behind scrollable content areas.
class ProgramEmblemBackground extends StatelessWidget {
  static const _assetPath =
      'assets/emblemaHUSKROUA ENI logo_final_grey_20-01.png';

  final Widget child;

  const ProgramEmblemBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoSize =
            (constraints.maxWidth * 0.5).clamp(180.0, 420.0).toDouble();

        return Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    _assetPath,
                    width: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}
