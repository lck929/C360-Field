import 'package:flutter/material.dart';

class MicrosoftLogo extends StatelessWidget {
  const MicrosoftLogo({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(int color) => SizedBox.square(dimension: 8, child: ColoredBox(color: Color(color)));
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [tile(0xFFF25022), tile(0xFF7FBA00)]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [tile(0xFF00A4EF), tile(0xFFFFB900)]),
          ],
        ),
      ),
    );
  }
}
