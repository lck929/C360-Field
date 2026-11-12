import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('C360 Field', style: serif(size: 26, color: Brand.gold)),
              const SizedBox(height: 20),
              const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      );
}
