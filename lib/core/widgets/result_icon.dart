import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

enum Tone { success, pending, failure, loading }

class ResultIcon extends StatelessWidget {
  const ResultIcon({super.key, required this.tone, this.size = 72});

  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (color, icon) = switch (tone) {
      Tone.success => (p.success, Icons.check_rounded),
      Tone.pending => (p.warning, Icons.cloud_upload_outlined),
      Tone.failure => (p.destructive, Icons.close_rounded),
      Tone.loading => (Brand.gold, null),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
      child: icon == null
          ? SizedBox.square(dimension: size * 0.45, child: CircularProgressIndicator(strokeWidth: 3, color: color))
          : Icon(icon, size: size * 0.5, color: color),
    );
  }
}
