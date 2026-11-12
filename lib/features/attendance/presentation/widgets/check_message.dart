import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/utils/formatters.dart';
import 'package:c360/core/widgets/result_icon.dart';
import 'package:flutter/material.dart';

class CheckMessage extends StatelessWidget {
  const CheckMessage({
    super.key,
    required this.tone,
    required this.title,
    required this.body,
    this.time,
    this.actions = const [],
  });

  final Tone tone;
  final String title;
  final String body;
  final DateTime? time;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResultIcon(tone: tone),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
              if (time != null) ...[
                const SizedBox(height: 8),
                Text(formatHm(time!), style: serif(size: 40, weight: FontWeight.w500, color: Brand.gold)),
              ],
              const SizedBox(height: 10),
              Text(body, textAlign: TextAlign.center, style: TextStyle(color: context.palette.mutedForeground)),
              for (final action in actions) ...[
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: action),
              ],
            ],
          ),
        ),
      );
}
