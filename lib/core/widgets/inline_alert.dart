import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class InlineAlert extends StatelessWidget {
  const InlineAlert({super.key, required this.message, this.warning = false});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? context.palette.warning : context.palette.destructive;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(warning ? Icons.info_outline : Icons.error_outline, size: 17, color: color),
            const SizedBox(width: 9),
            Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13, height: 1.4))),
          ],
        ),
      ),
    );
  }
}
