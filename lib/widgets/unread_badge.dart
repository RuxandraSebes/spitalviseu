import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Unread count badge — white background, black text (visible on red headers).
class UnreadBadge extends StatelessWidget {
  final int count;
  final double fontSize;
  final EdgeInsets padding;
  final double minSize;

  const UnreadBadge({
    super.key,
    required this.count,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.minSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      padding: padding,
      decoration: const BoxDecoration(
        color: AppColors.unreadBadgeBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.unreadBadgeText,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
