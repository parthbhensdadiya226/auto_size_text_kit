import 'package:flutter/widgets.dart';

import 'render_auto_size_text.dart';

/// Text that shrinks its font size until it fits its space, with an optional
/// gradient fill and outline.
///
/// It takes the same arguments as the `auto_size_text` package, so switching
/// only takes changing the import.
///
/// The text starts at the font size of its [style] and gets smaller, in
/// steps of [stepGranularity], until it fits the width, height and
/// [maxLines] it was given, but never below [minFontSize]. It never grows
/// past the style's size.
///
/// ```dart
/// SizedBox(
///   width: 200,
///   child: AutoSizeText(
///     'The quick brown fox jumps over the lazy dog',
///     style: TextStyle(fontSize: 30),
///     maxLines: 2,
///   ),
/// )
/// ```
///
/// Only [TextSpan]s are supported inside [AutoSizeText.rich];
/// [WidgetSpan]s are not.
class AutoSizeText extends StatelessWidget {
  /// Creates auto-sizing text.
  ///
  /// If [style] is null, the text uses the closest enclosing
  /// [DefaultTextStyle].
  const AutoSizeText(
    String this.data, {
    super.key,
    this.textKey,
    this.style,
    this.strutStyle,
    this.minFontSize = 12,
    this.maxFontSize = double.infinity,
    this.stepGranularity = 1,
    this.presetFontSizes,
    this.group,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.wrapWords = true,
    this.overflow,
    this.overflowReplacement,
    @Deprecated('Use textScaler instead.') this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.gradient,
    this.strokeWidth = 0,
    this.strokeColor,
    this.strokeGradient,
  }) : textSpan = null,
       assert(
         overflow == null || overflowReplacement == null,
         'Either overflow or overflowReplacement must be null.',
       ),
       assert(
         maxLines == null || maxLines > 0,
         'maxLines must be greater than 0.',
       ),
       assert(minFontSize >= 0, 'minFontSize must not be negative.'),
       assert(maxFontSize > 0, 'maxFontSize must be greater than 0.'),
       assert(
         minFontSize <= maxFontSize,
         'minFontSize must not be bigger than maxFontSize.',
       ),
       assert(stepGranularity > 0, 'stepGranularity must be greater than 0.'),
       assert(strokeWidth >= 0, 'strokeWidth must not be negative.');

  /// Creates auto-sizing text from a [TextSpan].
  ///
  /// The whole span shrinks together, so spans with different font sizes
  /// keep their proportions.
  const AutoSizeText.rich(
    TextSpan this.textSpan, {
    super.key,
    this.textKey,
    this.style,
    this.strutStyle,
    this.minFontSize = 12,
    this.maxFontSize = double.infinity,
    this.stepGranularity = 1,
    this.presetFontSizes,
    this.group,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.wrapWords = true,
    this.overflow,
    this.overflowReplacement,
    @Deprecated('Use textScaler instead.') this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.gradient,
    this.strokeWidth = 0,
    this.strokeColor,
    this.strokeGradient,
  }) : data = null,
       assert(
         overflow == null || overflowReplacement == null,
         'Either overflow or overflowReplacement must be null.',
       ),
       assert(
         maxLines == null || maxLines > 0,
         'maxLines must be greater than 0.',
       ),
       assert(minFontSize >= 0, 'minFontSize must not be negative.'),
       assert(maxFontSize > 0, 'maxFontSize must be greater than 0.'),
       assert(
         minFontSize <= maxFontSize,
         'minFontSize must not be bigger than maxFontSize.',
       ),
       assert(stepGranularity > 0, 'stepGranularity must be greater than 0.'),
       assert(strokeWidth >= 0, 'strokeWidth must not be negative.');

  /// A key for the widget that lays out and paints the text, to find it in
  /// tests.
  final Key? textKey;

  /// The text to show. Null when [textSpan] is used.
  final String? data;

  /// The text to show as a [TextSpan]. Null when [data] is used.
  final TextSpan? textSpan;

  /// The style of the text. Its font size is the biggest size the text is
  /// shown at.
  ///
  /// If the style's `inherit` is true (the default), it is merged with the
  /// closest enclosing [DefaultTextStyle]. A text without any font size
  /// starts at 14.
  final TextStyle? style;

  /// The strut style, which sets the minimum height of each line.
  final StrutStyle? strutStyle;

  /// The smallest font size the text shrinks to. Defaults to 12.
  ///
  /// When the style's font size is smaller than this, the text stays at the
  /// style's size. Ignored when [presetFontSizes] is set.
  final double minFontSize;

  /// The biggest font size the text is shown at, even when its style's font
  /// size is bigger. Ignored when [presetFontSizes] is set.
  final double maxFontSize;

  /// How much the font size shrinks with each step. Defaults to 1.
  ///
  /// Sizes are tried from [minFontSize] up in these steps. Ignored when
  /// [presetFontSizes] is set.
  final double stepGranularity;

  /// The only font sizes allowed, from biggest to smallest.
  ///
  /// The first one that fits is used; if none fits, the last one is.
  final List<double>? presetFontSizes;

  /// Keeps this text at the same font size as the other texts in the group.
  ///
  /// All texts in a group use the smallest size any of them needs.
  final AutoSizeGroup? group;

  /// How the text is aligned horizontally.
  final TextAlign? textAlign;

  /// The direction of the text. Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// Picks locale-specific glyphs. Defaults to the app's locale.
  final Locale? locale;

  /// Whether the text wraps onto new lines. Defaults to the enclosing
  /// [DefaultTextStyle].
  final bool? softWrap;

  /// Whether a word too long for a line on its own may be split across
  /// lines. Defaults to true.
  ///
  /// When false, the text shrinks until every word fits on a line.
  final bool wrapWords;

  /// What happens to text that doesn't fit even at the smallest size.
  /// Defaults to the enclosing [DefaultTextStyle].
  final TextOverflow? overflow;

  /// Shown instead of the text when it doesn't fit even at the smallest
  /// size.
  final Widget? overflowReplacement;

  /// Deprecated: use [textScaler].
  @Deprecated('Use textScaler instead.')
  final double? textScaleFactor;

  /// Scales the font size for accessibility, on top of the fitted size.
  /// Defaults to the ambient [MediaQuery]'s text scaler.
  ///
  /// It also applies to [minFontSize], [maxFontSize] and [presetFontSizes].
  final TextScaler? textScaler;

  /// The most lines the text may take. Defaults to the enclosing
  /// [DefaultTextStyle].
  final int? maxLines;

  /// Read by screen readers instead of the text.
  ///
  /// ```dart
  /// AutoSizeText(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  final String? semanticsLabel;

  /// Whether the text is as wide as its space or as its longest line.
  final TextWidthBasis? textWidthBasis;

  /// How the height of the first and last lines is applied.
  final TextHeightBehavior? textHeightBehavior;

  /// Fills the text with a gradient instead of its color.
  ///
  /// The gradient stretches across the lines of text, not the whole box.
  ///
  /// ```dart
  /// AutoSizeText(
  ///   'Sunset',
  ///   gradient: LinearGradient(colors: [Colors.orange, Colors.pink]),
  /// )
  /// ```
  final Gradient? gradient;

  /// Width of the outline around the text. Defaults to 0, no outline.
  ///
  /// The outline sits outside the letters and is taken into account while
  /// fitting, so it is never cut off.
  final double strokeWidth;

  /// Color of the outline. Defaults to black.
  final Color? strokeColor;

  /// Fills the outline with a gradient instead of [strokeColor].
  final Gradient? strokeGradient;

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    var effectiveStyle = style == null || style!.inherit
        ? defaults.style.merge(style)
        : style!;
    if (MediaQuery.boldTextOf(context)) {
      effectiveStyle = effectiveStyle.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    final baseFontSize = effectiveStyle.fontSize ?? 14;
    effectiveStyle = effectiveStyle.copyWith(fontSize: baseFontSize);

    final text = textSpan == null
        ? TextSpan(text: data, style: effectiveStyle)
        : TextSpan(style: effectiveStyle, children: [textSpan!]);
    assert(
      _hasNoWidgetSpans(text),
      'AutoSizeText.rich does not support WidgetSpans.',
    );

    // ignore: deprecated_member_use_from_same_package
    final legacyScale = textScaleFactor;
    final scaler =
        textScaler ??
        (legacyScale != null
            ? TextScaler.linear(legacyScale)
            : MediaQuery.textScalerOf(context));

    return _AutoSizeTextLayout(
      key: textKey,
      settings: TextFitSettings(
        text: text,
        baseFontSize: baseFontSize,
        textAlign: textAlign ?? defaults.textAlign ?? TextAlign.start,
        textDirection: textDirection ?? Directionality.of(context),
        textScaler: scaler,
        locale: locale ?? Localizations.maybeLocaleOf(context),
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis ?? defaults.textWidthBasis,
        textHeightBehavior:
            textHeightBehavior ??
            defaults.textHeightBehavior ??
            DefaultTextHeightBehavior.maybeOf(context),
        maxLines: maxLines ?? defaults.maxLines,
        softWrap: softWrap ?? defaults.softWrap,
        overflow: overflow ?? defaults.overflow,
        wrapWords: wrapWords,
        minFontSize: minFontSize,
        maxFontSize: maxFontSize,
        stepGranularity: stepGranularity,
        presetFontSizes: presetFontSizes,
        strokeWidth: strokeWidth,
      ),
      group: group,
      gradient: gradient,
      strokeColor: strokeColor ?? const Color(0xFF000000),
      strokeGradient: strokeGradient,
      semanticsLabel: semanticsLabel,
      child: overflowReplacement,
    );
  }

  static bool _hasNoWidgetSpans(InlineSpan span) {
    var ok = true;
    span.visitChildren((child) {
      if (child is! TextSpan) ok = false;
      return ok;
    });
    return ok;
  }
}

class _AutoSizeTextLayout extends SingleChildRenderObjectWidget {
  const _AutoSizeTextLayout({
    super.key,
    required this.settings,
    required this.group,
    required this.gradient,
    required this.strokeColor,
    required this.strokeGradient,
    required this.semanticsLabel,
    super.child,
  });

  final TextFitSettings settings;
  final AutoSizeGroup? group;
  final Gradient? gradient;
  final Color strokeColor;
  final Gradient? strokeGradient;
  final String? semanticsLabel;

  @override
  RenderAutoSizeText createRenderObject(BuildContext context) =>
      RenderAutoSizeText(
        settings: settings,
        group: group,
        gradient: gradient,
        strokeColor: strokeColor,
        strokeGradient: strokeGradient,
        semanticsLabel: semanticsLabel,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAutoSizeText renderObject,
  ) {
    renderObject
      ..settings = settings
      ..group = group
      ..gradient = gradient
      ..strokeColor = strokeColor
      ..strokeGradient = strokeGradient
      ..semanticsLabel = semanticsLabel;
  }
}
