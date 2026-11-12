import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, this.size = 44});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.palette.accent,
          border: Border.all(color: Brand.gold.withValues(alpha: 0.5)),
        ),
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: size * 0.31, color: context.palette.accentForeground),
        ),
      );
}
