import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

const _slides = [
  (asset: 'assets/images/img.png', alignment: Alignment(0, 0.2)),
  (asset: 'assets/images/img_1.png', alignment: Alignment(0, -0.3)),
  (asset: 'assets/images/img_2.png', alignment: Alignment(0.3, -0.2)),
];

class LoginHero extends StatefulWidget {
  const LoginHero({super.key});

  @override
  State<LoginHero> createState() => _LoginHeroState();
}

class _LoginHeroState extends State<LoginHero> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      setState(() => _index = (_index + 1) % _slides.length);
      _progress.forward(from: 0);
    })
    ..forward();
  var _index = 0;
  var _precached = false;

  int _cacheWidth(BuildContext context) {
    final media = MediaQuery.of(context);
    return (media.size.width * media.devicePixelRatio).round();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    final width = _cacheWidth(context);
    for (final slide in _slides) {
      precacheImage(ResizeImage(AssetImage(slide.asset), width: width), context);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheWidth = _cacheWidth(context);
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF111111)),
          for (var i = 0; i < _slides.length; i++)
            AnimatedOpacity(
              opacity: i == _index ? 1 : 0,
              duration: const Duration(milliseconds: 1200),
              child: Image.asset(
                _slides[i].asset,
                fit: BoxFit.cover,
                alignment: _slides[i].alignment,
                cacheWidth: cacheWidth,
                excludeFromSemantics: true,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Color(0x1A000000)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Sobha Constructions',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOBHA',
                        style: serif(size: 30, weight: FontWeight.w500, color: Brand.logoGold, height: 1)
                            .copyWith(letterSpacing: 9.6),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'CONSTRUCTIONS',
                        style: TextStyle(fontSize: 9.5, letterSpacing: 4.4, color: Brand.logoGold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Construct 360 for site teams', style: TextStyle(fontSize: 14, color: Color(0xDBFFFFFF))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < _slides.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 3,
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (_, _) => LinearProgressIndicator(
                                value: i == _index ? _progress.value : 0,
                                backgroundColor: const Color(0x66FFFFFF),
                                color: const Color(0xF2CCA85C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
