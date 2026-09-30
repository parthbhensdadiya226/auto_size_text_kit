import 'package:auto_size_text_kit/auto_size_text_kit.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'auto_size_text_kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage>
    with SingleTickerProviderStateMixin {
  /// How much of the available width the demos get, from 0.45 to 1.
  double _widthFactor = 1;

  late final AnimationController _animation =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addListener(() {
          final t = Curves.easeInOut.transform(_animation.value);
          setState(() => _widthFactor = (1 - t * 0.55).clamp(0.45, 1.0));
        });

  final _headlineGroup = AutoSizeGroup();
  final _buttonGroup = AutoSizeGroup();
  final _numberGroup = AutoSizeGroup();
  final _captionGroup = AutoSizeGroup();

  @override
  void dispose() {
    _animation.dispose();
    _headlineGroup.dispose();
    _buttonGroup.dispose();
    _numberGroup.dispose();
    _captionGroup.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_animation.isAnimating) {
      _animation.stop();
    } else {
      _animation.repeat(reverse: true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('auto_size_text_kit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.width_normal_outlined),
                Expanded(
                  child: Slider(
                    value: _widthFactor,
                    min: 0.45,
                    onChanged: (v) {
                      _animation.stop();
                      setState(() => _widthFactor = v);
                    },
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: _animation.isAnimating ? 'Stop' : 'Play',
                  onPressed: _togglePlay,
                  icon: Icon(
                    _animation.isAnimating
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Demo(
                  title: 'Shrinks to fit',
                  widthFactor: _widthFactor,
                  footer: ListenableBuilder(
                    listenable: _headlineGroup,
                    builder: (context, _) => Text(
                      'Font size: '
                      '${_headlineGroup.fontSize?.toStringAsFixed(0) ?? '-'}',
                      style: TextStyle(color: scheme.outline),
                    ),
                  ),
                  child: AutoSizeText(
                    'The quick brown fox jumps over the lazy dog',
                    group: _headlineGroup,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    minFontSize: 10,
                  ),
                ),
                _Demo(
                  title: 'Gradient and outline',
                  widthFactor: _widthFactor,
                  dark: true,
                  child: const AutoSizeText(
                    'SUMMER SALE',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    maxLines: 1,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF6F61)],
                    ),
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  ),
                ),
                _Demo(
                  title: 'Outline only',
                  widthFactor: _widthFactor,
                  child: const AutoSizeText(
                    'Outlined',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    strokeWidth: 2,
                    strokeGradient: LinearGradient(
                      colors: [Color(0xFF6750A4), Color(0xFF00B4D8)],
                    ),
                  ),
                ),
                _Demo(
                  title: 'Numbers',
                  widthFactor: _widthFactor,
                  dark: true,
                  child: Column(
                    children: [
                      // Aligned on the baseline: the outlined numbers are a
                      // little taller, since the outline takes space.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Center(
                              child: AutoSizeText(
                                '2,480',
                                group: _numberGroup,
                                style: _numberStyle,
                                maxLines: 1,
                                minFontSize: 8,
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFE082),
                                    Color(0xFFFF8F00),
                                  ],
                                ),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: AutoSizeText(
                                '98%',
                                group: _numberGroup,
                                // A transparent fill leaves only the outline.
                                style: _numberStyle.copyWith(
                                  color: Colors.transparent,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFF64FFDA),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: AutoSizeText(
                                '4.9',
                                group: _numberGroup,
                                style: _numberStyle,
                                maxLines: 1,
                                minFontSize: 8,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF80D8FF),
                                    Color(0xFFB388FF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final label in [
                            'Gradient + outline',
                            'Outline',
                            'Gradient',
                          ])
                            Expanded(
                              child: AutoSizeText(
                                label,
                                group: _captionGroup,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 6,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _Demo(
                  title: 'Same size in a group',
                  widthFactor: _widthFactor,
                  child: Row(
                    children: [
                      for (final label in ['OK', 'Save', 'Publish'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () {},
                              child: AutoSizeText(
                                label,
                                group: _buttonGroup,
                                style: const TextStyle(fontSize: 18),
                                maxLines: 1,
                                minFontSize: 6,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _Demo(
                  title: 'Rich text keeps its proportions',
                  widthFactor: _widthFactor,
                  child: AutoSizeText.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '\$1,299'),
                        TextSpan(
                          text: ' / month',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    minFontSize: 8,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                  ),
                ),
                _Demo(
                  title: 'Too long? Show something else',
                  widthFactor: _widthFactor,
                  child: AutoSizeText(
                    'Wolfeschlegelsteinhausenbergerdorff',
                    style: const TextStyle(fontSize: 28),
                    maxLines: 1,
                    minFontSize: 16,
                    overflowReplacement: Text(
                      'Name too long',
                      style: TextStyle(fontSize: 16, color: scheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _numberStyle = TextStyle(
  fontSize: 48,
  fontWeight: FontWeight.w900,
  color: Colors.white,
);

class _Demo extends StatelessWidget {
  const _Demo({
    required this.title,
    required this.widthFactor,
    required this.child,
    this.footer,
    this.dark = false,
  });

  final String title;
  final double widthFactor;
  final Widget child;
  final Widget? footer;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF1C1B2E)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: child,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 6), footer!],
        ],
      ),
    );
  }
}
