import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.title, this.icon, this.action});

  final String message;
  final String? title;
  final Widget? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
        child: Column(
          children: [
            if (icon != null) ...[icon!, const SizedBox(height: 16)],
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 6),
            ],
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.palette.mutedForeground)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      );
}
