import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Font sizes closer than this are treated as equal.
const _epsilon = 1e-6;

/// Everything that decides which font size fits and how the text is laid
/// out. When any of it changes, the text is fitted again.
@immutable
class TextFitSettings {
  const TextFitSettings({
    required this.text,
    required this.baseFontSize,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.maxLines,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.wrapWords = true,
    this.minFontSize = 12,
    this.maxFontSize = double.infinity,
    this.stepGranularity = 1,
    this.presetFontSizes,
    this.strokeWidth = 0,
  });

  /// The text, with the fully resolved style on its root span.
  final TextSpan text;

  /// The font size of the root style. Fitted sizes are applied as a scale
  /// relative to it, so nested spans keep their proportions.
  final double baseFontSize;

  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final ui.TextHeightBehavior? textHeightBehavior;
  final int? maxLines;
  final bool softWrap;
  final TextOverflow overflow;
  final bool wrapWords;
  final double minFontSize;
  final double maxFontSize;
  final double stepGranularity;
  final List<double>? presetFontSizes;

  /// Width of the outline drawn around the text. The text is fitted into the
  /// space left once the outline is taken off every side.
  final double strokeWidth;

  /// Whether [other] only differs from this in how the text is painted, so
  /// the fitted size and the layout stay the same.
  bool onlyPaintDiffers(TextFitSettings other) =>
      baseFontSize == other.baseFontSize &&
      textAlign == other.textAlign &&
      textDirection == other.textDirection &&
      textScaler == other.textScaler &&
      locale == other.locale &&
      strutStyle == other.strutStyle &&
      textWidthBasis == other.textWidthBasis &&
      textHeightBehavior == other.textHeightBehavior &&
      maxLines == other.maxLines &&
      softWrap == other.softWrap &&
      overflow == other.overflow &&
      wrapWords == other.wrapWords &&
      minFontSize == other.minFontSize &&
      maxFontSize == other.maxFontSize &&
      stepGranularity == other.stepGranularity &&
      listEquals(presetFontSizes, other.presetFontSizes) &&
      strokeWidth == other.strokeWidth &&
      text.compareTo(other.text).index <= RenderComparison.paint.index;

  @override
  bool operator ==(Object other) =>
      other is TextFitSettings && text == other.text && onlyPaintDiffers(other);

  @override
  int get hashCode => Object.hash(
    text,
    baseFontSize,
    textAlign,
    textDirection,
    textScaler,
    locale,
    strutStyle,
    textWidthBasis,
    textHeightBehavior,
    maxLines,
    softWrap,
    overflow,
    wrapWords,
    minFontSize,
    maxFontSize,
    stepGranularity,
    presetFontSizes == null ? null : Object.hashAll(presetFontSizes!),
    strokeWidth,
  );
}

/// Applies the user's [TextScaler] to the font size picked while fitting.
///
/// Font sizes are multiplied by [factor] before the user's scaler sees them,
/// so a nonlinear system text scale still applies to the fitted size.
class _FitScaler extends TextScaler {
  const _FitScaler(this.inner, this.factor);

  final TextScaler inner;
  final double factor;

  @override
  double scale(double fontSize) => inner.scale(fontSize * factor);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => inner.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _FitScaler && other.inner == inner && other.factor == factor;

  @override
  int get hashCode => Object.hash(inner, factor);
}

/// The biggest font size that fits, and whether it really fits or is just
/// the smallest size allowed.
typedef _Fit = ({double fontSize, bool fits});

/// Lays out, fits and paints auto-sized text, with an optional gradient
/// fill and outline.
///
/// When the text doesn't fit even at the smallest size and there is a
/// [child], the child is shown instead.
class RenderAutoSizeText extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderAutoSizeText({
    required TextFitSettings settings,
    AutoSizeGroup? group,
    Gradient? gradient,
    Color strokeColor = const Color(0xFF000000),
    Gradient? strokeGradient,
    String? semanticsLabel,
  }) : _settings = settings,
       _group = group,
       _gradient = gradient,
       _strokeColor = strokeColor,
       _strokeGradient = strokeGradient,
       _semanticsLabel = semanticsLabel {
    _configurePainters();
  }

  /// Used only to try out font sizes, so the painted text is never disturbed.
  final _measure = TextPainter();

  /// Paints the text fill.
  final _painter = TextPainter();

  /// Paints the outline under the fill. Only created when there is one.
  TextPainter? _strokePainter;

  TextFitSettings get settings => _settings;
  TextFitSettings _settings;
  set settings(TextFitSettings value) {
    if (value == _settings) return;
    final paintOnly = _settings.onlyPaintDiffers(value);
    _settings = value;
    _configurePainters();
    _plainText = null;
    markNeedsSemanticsUpdate();
    // Only the paint changed, so the fitted size stays. The painters still
    // lay out again, since the paints are part of their text.
    if (!paintOnly) _fitConstraints = null;
    markNeedsLayout();
  }

  AutoSizeGroup? get group => _group;
  AutoSizeGroup? _group;
  set group(AutoSizeGroup? value) {
    if (value == _group) return;
    _group?._remove(this);
    _group = value;
    markNeedsLayout();
  }

  Gradient? get gradient => _gradient;
  Gradient? _gradient;
  set gradient(Gradient? value) {
    if (value == _gradient) return;
    _gradient = value;
    _stylesDirty = true;
    markNeedsLayout();
  }

  Color get strokeColor => _strokeColor;
  Color _strokeColor;
  set strokeColor(Color value) {
    if (value == _strokeColor) return;
    _strokeColor = value;
    _stylesDirty = true;
    markNeedsLayout();
  }

  Gradient? get strokeGradient => _strokeGradient;
  Gradient? _strokeGradient;
  set strokeGradient(Gradient? value) {
    if (value == _strokeGradient) return;
    _strokeGradient = value;
    _stylesDirty = true;
    markNeedsLayout();
  }

  String? get semanticsLabel => _semanticsLabel;
  String? _semanticsLabel;
  set semanticsLabel(String? value) {
    if (value == _semanticsLabel) return;
    _semanticsLabel = value;
    markNeedsSemanticsUpdate();
  }

  /// The font size the text was last fitted to, before the user's text
  /// scale. Null until the first layout.
  double? get fontSize => _paintFontSize;

  /// Whether the text fit at [fontSize] when it was last laid out.
  bool get textFits => _textFits;
  bool _textFits = true;

  double get _inset => _settings.strokeWidth;

  // The result of the last fit, reused while the constraints stay the same.
  BoxConstraints? _fitConstraints;
  _Fit? _fit;

  // The constraints and font size of the last layout. The paint font size
  // can be smaller when a group shrinks after this text was laid out.
  BoxConstraints? _layoutConstraints;
  double? _layoutFontSize;
  double? _paintFontSize;

  bool _showReplacement = false;
  bool _needsClipping = false;
  ui.Shader? _fadeShader;

  // Bounds of the laid out lines, which the gradients stretch across, and
  // the bounds the current styles were built for.
  Rect? _lines;
  Rect? _styledFor;
  bool _stylesDirty = true;

  String? _plainText;
  String get _text => _plainText ??= _settings.text.toPlainText();

  void _configurePainters() {
    final s = _settings;
    for (final painter in [_measure, _painter, ?_strokePainter]) {
      painter
        ..textAlign = s.textAlign
        ..textDirection = s.textDirection
        ..locale = s.locale
        ..strutStyle = s.strutStyle
        ..textWidthBasis = s.textWidthBasis
        ..textHeightBehavior = s.textHeightBehavior
        ..maxLines = s.maxLines;
    }
    final ellipsis = s.overflow == TextOverflow.ellipsis ? '…' : null;
    _painter.ellipsis = ellipsis;
    _strokePainter?.ellipsis = ellipsis;
    _measure.text = s.text;
    if (s.strokeWidth <= 0) {
      _strokePainter?.dispose();
      _strokePainter = null;
    }
    _stylesDirty = true;
  }

  TextScaler _scalerFor(double fontSize) => _FitScaler(
    _settings.textScaler,
    _settings.baseFontSize > 0 ? fontSize / _settings.baseFontSize : 1,
  );

  // Fitting.

  /// The font sizes to try, from the biggest down. The biggest is the style's
  /// own size, so text never grows past the size it was given.
  ({double top, double bottom}) get _range {
    final s = _settings;
    final top = math.min(s.baseFontSize, s.maxFontSize);
    return (top: top, bottom: math.min(s.minFontSize, top));
  }

  bool _fitsAt(double fontSize, double maxWidth, double maxHeight) {
    final s = _settings;
    _measure
      ..textScaler = _scalerFor(fontSize)
      ..layout(maxWidth: s.softWrap ? maxWidth : double.infinity);
    if (_measure.didExceedMaxLines) return false;
    if (_measure.width > maxWidth + _epsilon) return false;
    if (_measure.height > maxHeight + _epsilon) return false;
    if (!s.wrapWords && _breaksAWord(_measure)) return false;
    return true;
  }

  /// Whether any line of [painter] ends in the middle of a word, which
  /// happens when a word is too long for the line on its own.
  bool _breaksAWord(TextPainter painter) {
    final text = _text;
    var start = 0;
    while (start < text.length) {
      final end = painter.getLineBoundary(TextPosition(offset: start)).end;
      if (end <= start) {
        start++;
        continue;
      }
      if (end < text.length &&
          !_breaksAfter(text.codeUnitAt(end - 1)) &&
          !_breaksAfter(text.codeUnitAt(end))) {
        return true;
      }
      start = end;
    }
    return false;
  }

  static bool _breaksAfter(int char) =>
      char == 0x20 || // space
      char == 0x09 || // tab
      char == 0x0A || // line feed
      char == 0x0D || // carriage return
      char == 0x2D || // hyphen
      char == 0x2010 || // hyphen
      char == 0x2013 || // en dash
      char == 0x200B; // zero width space

  _Fit _computeFit(BoxConstraints constraints) {
    final maxWidth = math.max(0.0, constraints.maxWidth - 2 * _inset);
    final maxHeight = math.max(0.0, constraints.maxHeight - 2 * _inset);
    bool fits(double size) => _fitsAt(size, maxWidth, maxHeight);

    final presets = _settings.presetFontSizes;
    if (presets != null) {
      // Presets go from big to small, so the ones that fit are at the end.
      var low = 0, high = presets.length - 1, found = -1;
      while (low <= high) {
        final mid = (low + high) ~/ 2;
        if (fits(presets[mid])) {
          found = mid;
          high = mid - 1;
        } else {
          low = mid + 1;
        }
      }
      return found == -1
          ? (fontSize: presets.last, fits: false)
          : (fontSize: presets[found], fits: true);
    }

    final (:top, :bottom) = _range;
    if (fits(top)) return (fontSize: top, fits: true);

    // Try bottom, bottom + step, bottom + 2 * step, ... below top.
    final step = _settings.stepGranularity;
    var steps = ((top - bottom) / step).floor();
    if (bottom + steps * step >= top - _epsilon) steps--;
    var low = 0, high = steps, found = -1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (fits(bottom + mid * step)) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found == -1
        ? (fontSize: bottom, fits: false)
        : (fontSize: bottom + found * step, fits: true);
  }

  _Fit _fitFor(BoxConstraints constraints) {
    if (constraints != _fitConstraints || _fit == null) {
      _fit = _computeFit(constraints);
      _fitConstraints = constraints;
    }
    return _fit!;
  }

  /// The font size to show: the fitted size, or the group's size when it is
  /// smaller.
  double _shownSize(double fitted) {
    final shared = _group?._smallest;
    return shared == null ? fitted : math.min(fitted, shared);
  }

  // Layout.

  void _layoutText(TextPainter painter, double fontSize, BoxConstraints c) {
    final s = _settings;
    final maxWidth = math.max(0.0, c.maxWidth - 2 * _inset);
    final widthMatters = s.softWrap || s.overflow == TextOverflow.ellipsis;
    painter
      ..textScaler = _scalerFor(fontSize)
      ..layout(
        minWidth: clampDouble(c.minWidth - 2 * _inset, 0, maxWidth),
        maxWidth: widthMatters ? maxWidth : double.infinity,
      );
  }

  Size _textSize(TextPainter painter) =>
      Size(painter.width + 2 * _inset, painter.height + 2 * _inset);

  @override
  void performLayout() {
    final c = constraints;
    final fit = _fitFor(c);
    _group?._report(this, fit.fontSize);
    final fontSize = _shownSize(fit.fontSize);
    _textFits = fit.fits || fontSize < fit.fontSize - _epsilon;
    _layoutConstraints = c;
    _layoutFontSize = fontSize;

    final showReplacement = !_textFits && child != null;
    if (showReplacement != _showReplacement) {
      _showReplacement = showReplacement;
      markNeedsSemanticsUpdate();
    }
    if (_showReplacement) {
      child!.layout(c, parentUsesSize: true);
      size = child!.size;
      _paintFontSize = fontSize;
      return;
    }

    _layoutPainters(fontSize, c);
    size = c.constrain(_textSize(_painter));
    _updateOverflow();
  }

  void _layoutPainters(double fontSize, BoxConstraints c) {
    _paintFontSize = fontSize;
    if (_painter.text == null) _restyle();
    _layoutText(_painter, fontSize, c);
    final hasGradient =
        _gradient != null ||
        (_settings.strokeWidth > 0 && _strokeGradient != null);
    _lines = hasGradient ? _linesRect() : null;
    // The gradient and outline paints count as layout changes to a text
    // painter, so it lays out again when they were rebuilt.
    if (_restyle()) _layoutText(_painter, fontSize, c);
    if (_strokePainter case final stroke?) _layoutText(stroke, fontSize, c);
  }

  void _updateOverflow() {
    final textSize = _textSize(_painter);
    final overflowsWidth = size.width < textSize.width - _epsilon;
    final overflowsHeight =
        size.height < textSize.height - _epsilon || _painter.didExceedMaxLines;
    _fadeShader = null;
    _needsClipping = false;
    if (!overflowsWidth && !overflowsHeight) return;
    switch (_settings.overflow) {
      case TextOverflow.visible:
        break;
      case TextOverflow.clip:
      case TextOverflow.ellipsis:
        _needsClipping = true;
      case TextOverflow.fade:
        _needsClipping = true;
        final fade = TextPainter(
          text: TextSpan(style: _settings.text.style, text: '…'),
          textDirection: _settings.textDirection,
          textScaler: _painter.textScaler,
          locale: _settings.locale,
        )..layout();
        const colors = [Color(0xFFFFFFFF), Color(0x00FFFFFF)];
        if (overflowsWidth) {
          final (start, end) = switch (_settings.textDirection) {
            TextDirection.rtl => (fade.width, 0.0),
            TextDirection.ltr => (size.width - fade.width, size.width),
          };
          _fadeShader = ui.Gradient.linear(
            Offset(start, 0),
            Offset(end, 0),
            colors,
          );
        } else {
          final end = size.height;
          _fadeShader = ui.Gradient.linear(
            Offset(0, end - fade.height / 2),
            Offset(0, end),
            colors,
          );
        }
        fade.dispose();
    }
  }

  // Styling. The fill and the outline are painted from copies of the text
  // whose styles carry the gradient and stroke paints.

  /// Bounds of the laid out lines, which the gradients stretch across.
  Rect _linesRect() {
    final lines = _painter.computeLineMetrics();
    if (lines.isEmpty) return Offset.zero & _painter.size;
    var left = double.infinity, right = double.negativeInfinity;
    for (final line in lines) {
      left = math.min(left, line.left);
      right = math.max(right, line.left + line.width);
    }
    return Rect.fromLTRB(left, 0, right, _painter.height);
  }

  /// Rebuilds the fill and outline spans. Paint objects can't be compared, so
  /// they are only rebuilt when something they depend on changed; otherwise
  /// the painters would rebuild their paragraphs on every frame.
  bool _restyle() {
    if (!_stylesDirty && _styledFor == _lines && _painter.text != null) {
      return false;
    }
    _stylesDirty = false;
    _styledFor = _lines;

    final hasStroke = _settings.strokeWidth > 0;
    final dir = _settings.textDirection;
    final root = _settings.text;
    final rect = _lines;

    // A gradient needs laid out lines. Until then the text is filled with
    // its normal colors, and restyled right after the first layout.
    final fillPaint = _gradient != null && rect != null
        ? (Paint()..shader = _gradient!.createShader(rect, textDirection: dir))
        : null;
    _painter.text = fillPaint == null && !hasStroke
        ? root
        : _restyleSpan(root, (style, isRoot) {
            if (style == null) return null;
            return _copyStyle(
              style,
              foreground: isRoot ? fillPaint : null,
              // The outline carries the shadows, so they sit under it.
              dropShadows: hasStroke,
              isRoot: isRoot,
            );
          });

    if (!hasStroke) return true;
    // The outline is drawn centered on the letters' edges, with the fill
    // covering its inner half. Hollow text shows both halves, so it's drawn
    // half as wide to keep the same visible thickness.
    final hollow =
        _gradient == null &&
        root.style?.foreground == null &&
        (root.style?.color?.a ?? 1) == 0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _settings.strokeWidth * (hollow ? 1 : 2)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = _strokeColor;
    if (_strokeGradient != null && rect != null) {
      stroke.shader = _strokeGradient!.createShader(
        rect.inflate(_settings.strokeWidth),
        textDirection: dir,
      );
    }
    final strokePainter = _strokePainter ??= _newStrokePainter();
    strokePainter.text = _restyleSpan(root, (style, isRoot) {
      if (style == null) return null;
      return _copyStyle(style, foreground: stroke, strokeLayer: true);
    });
    return true;
  }

  TextPainter _newStrokePainter() {
    final s = _settings;
    return TextPainter(
      textAlign: s.textAlign,
      textDirection: s.textDirection,
      locale: s.locale,
      strutStyle: s.strutStyle,
      textWidthBasis: s.textWidthBasis,
      textHeightBehavior: s.textHeightBehavior,
      maxLines: s.maxLines,
      ellipsis: s.overflow == TextOverflow.ellipsis ? '…' : null,
    );
  }

  /// Keeps the paint in step with the group: when another text in the group
  /// changed size after this one was laid out, this one is resized right
  /// away for painting, and laid out again after the frame.
  ///
  /// Returns where to paint the text in the meantime: centered in the box,
  /// which is where it ends up in buttons, tabs and other centered layouts.
  Offset _followGroup() {
    final fitted = _fit?.fontSize;
    final c = _layoutConstraints;
    if (fitted == null || c == null) return Offset.zero;
    final target = _shownSize(fitted);
    if ((target - _paintFontSize!).abs() > _epsilon) {
      _layoutPainters(target, c);
    }
    if ((_paintFontSize! - _layoutFontSize!).abs() <= _epsilon) {
      return Offset.zero;
    }
    final text = _textSize(_painter);
    return Offset(
      math.max(0, (size.width - text.width) / 2),
      math.max(0, (size.height - text.height) / 2),
    );
  }

  /// Called by the group after a frame in which its size changed.
  void _groupChanged() {
    final fitted = _fit?.fontSize;
    if (fitted == null || !attached) return;
    if ((_shownSize(fitted) - _layoutFontSize!).abs() > _epsilon) {
      markNeedsLayout();
    }
  }

  // Painting.

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_showReplacement) {
      context.paintChild(child!, offset);
      return;
    }
    final shift = _followGroup();

    final canvas = context.canvas;
    if (_needsClipping) {
      final bounds = offset & size;
      if (_fadeShader != null) {
        canvas.saveLayer(bounds, Paint());
      } else {
        canvas
          ..save()
          ..clipRect(bounds);
      }
    }

    canvas
      ..save()
      ..translate(offset.dx + shift.dx + _inset, offset.dy + shift.dy + _inset);
    _strokePainter?.paint(canvas, Offset.zero);
    _painter.paint(canvas, Offset.zero);
    canvas.restore();

    if (_needsClipping) {
      if (_fadeShader != null) {
        canvas
          ..translate(offset.dx, offset.dy)
          ..drawRect(
            Offset.zero & size,
            Paint()
              ..blendMode = BlendMode.modulate
              ..shader = _fadeShader,
          );
      }
      canvas.restore();
    }
  }

  // Hit testing: taps reach the recognizers of the spans under them.

  @override
  bool hitTestSelf(Offset position) => !_showReplacement;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _showReplacement && child!.hitTest(result, position: position);

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (_showReplacement || event is! PointerDownEvent) return;
    final local = entry.localPosition - Offset(_inset, _inset);
    final position = _painter.getPositionForOffset(local);
    final span = _painter.text?.getSpanForPosition(position);
    if (span is TextSpan) span.recognizer?.addPointer(event);
  }

  // Intrinsics and dry layout, so the text works inside IntrinsicHeight,
  // IntrinsicWidth, tables and anything else that measures before layout.

  @override
  double computeMinIntrinsicWidth(double height) {
    _measure
      ..textScaler = _scalerFor(_smallestSize)
      ..layout();
    return _measure.minIntrinsicWidth + 2 * _inset;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _measure
      ..textScaler = _scalerFor(_biggestSize)
      ..layout();
    return _measure.maxIntrinsicWidth + 2 * _inset;
  }

  double get _smallestSize => _settings.presetFontSizes?.last ?? _range.bottom;

  double get _biggestSize => _settings.presetFontSizes?.first ?? _range.top;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _dryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _dryLayout(constraints);

  Size _dryLayout(BoxConstraints constraints) {
    final fit = _computeFit(constraints);
    final fontSize = _shownSize(fit.fontSize);
    final fits = fit.fits || fontSize < fit.fontSize - _epsilon;
    if (!fits && child != null) return child!.getDryLayout(constraints);
    _layoutText(_measure, fontSize, constraints);
    return constraints.constrain(_textSize(_measure));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final fit = _computeFit(constraints);
    final fontSize = _shownSize(fit.fontSize);
    final fits = fit.fits || fontSize < fit.fontSize - _epsilon;
    if (!fits && child != null) {
      return child!.getDryBaseline(constraints, baseline);
    }
    _layoutText(_measure, fontSize, constraints);
    return _measure.computeDistanceToActualBaseline(baseline) + _inset;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_showReplacement) return child!.getDistanceToActualBaseline(baseline);
    return _painter.computeDistanceToActualBaseline(baseline) + _inset;
  }

  // Semantics.

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (_showReplacement) return;
    config
      ..label = _semanticsLabel ?? _text
      ..textDirection = _settings.textDirection;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_showReplacement) super.visitChildrenForSemantics(visitor);
  }

  // Lifecycle.

  @override
  void detach() {
    _group?._remove(this);
    super.detach();
  }

  @override
  void dispose() {
    _measure.dispose();
    _painter.dispose();
    _strokePainter?.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', _text))
      ..add(DoubleProperty('fontSize', _paintFontSize))
      ..add(FlagProperty('textFits', value: _textFits, ifFalse: 'overflows'))
      ..add(
        DiagnosticsProperty<AutoSizeGroup>('group', _group, defaultValue: null),
      );
  }
}

/// Copies [span], passing each style through [restyle]. Recognizers, mouse
/// cursors and semantics labels are kept.
TextSpan _restyleSpan(
  TextSpan span,
  TextStyle? Function(TextStyle? style, bool isRoot) restyle, {
  bool isRoot = true,
}) {
  return TextSpan(
    text: span.text,
    style: restyle(span.style, isRoot),
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    locale: span.locale,
    spellOut: span.spellOut,
    children: span.children
        ?.map(
          (child) => _restyleSpan(child as TextSpan, restyle, isRoot: false),
        )
        .toList(),
  );
}

/// Copies [style]. With [foreground], its color is dropped (a style can't
/// have both). [dropShadows] removes the shadows; [strokeLayer] also removes
/// backgrounds and decorations, which the fill already paints.
TextStyle _copyStyle(
  TextStyle style, {
  Paint? foreground,
  bool dropShadows = false,
  bool strokeLayer = false,
  bool isRoot = false,
}) {
  // A null list inherits the parent's shadows, an empty one clears them.
  final shadows = dropShadows && (isRoot || style.shadows != null)
      ? const <Shadow>[]
      : style.shadows;
  final paintsColor = strokeLayer || foreground != null;
  return TextStyle(
    inherit: style.inherit,
    color: paintsColor ? null : style.color,
    foreground: strokeLayer ? foreground : (foreground ?? style.foreground),
    backgroundColor: strokeLayer ? null : style.backgroundColor,
    background: strokeLayer ? null : style.background,
    fontSize: style.fontSize,
    fontWeight: style.fontWeight,
    fontStyle: style.fontStyle,
    letterSpacing: style.letterSpacing,
    wordSpacing: style.wordSpacing,
    textBaseline: style.textBaseline,
    height: style.height,
    leadingDistribution: style.leadingDistribution,
    locale: style.locale,
    shadows: shadows,
    fontFeatures: style.fontFeatures,
    fontVariations: style.fontVariations,
    decoration: strokeLayer && (isRoot || style.decoration != null)
        ? TextDecoration.none
        : style.decoration,
    decorationColor: style.decorationColor,
    decorationStyle: style.decorationStyle,
    decorationThickness: style.decorationThickness,
    debugLabel: style.debugLabel,
    fontFamily: style.fontFamily,
    fontFamilyFallback: style.fontFamilyFallback,
    overflow: style.overflow,
  );
}

/// Keeps several [AutoSizeText]s at the same font size: all of them use the
/// size of the one that needs the smallest.
///
/// Create one group and pass it to every text that should match. Listen to
/// the group to read the shared size, for example to size an icon next to
/// the text.
///
/// ```dart
/// final group = AutoSizeGroup();
///
/// Row(children: [
///   Expanded(child: AutoSizeText('Save', group: group, maxLines: 1)),
///   Expanded(child: AutoSizeText('Save and close', group: group, maxLines: 1)),
/// ]);
/// ```
class AutoSizeGroup extends ChangeNotifier {
  final _sizes = <RenderAutoSizeText, double>{};
  var _updateScheduled = false;

  /// The font size every text in the group shows, before the user's text
  /// scale. Null while the group is empty.
  ///
  /// Updated after the frame in which it changed; listeners are notified then.
  double? get fontSize => _fontSize;
  double? _fontSize;

  double? get _smallest {
    double? smallest;
    for (final size in _sizes.values) {
      if (smallest == null || size < smallest) smallest = size;
    }
    return smallest;
  }

  void _report(RenderAutoSizeText text, double fontSize) {
    if (_sizes[text] == fontSize) return;
    _sizes[text] = fontSize;
    _scheduleUpdate();
  }

  void _remove(RenderAutoSizeText text) {
    if (_sizes.remove(text) != null) _scheduleUpdate();
  }

  void _scheduleUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _updateScheduled = false;
        for (final text in _sizes.keys.toList()) {
          text._groupChanged();
        }
        final smallest = _smallest;
        if (smallest != _fontSize) {
          _fontSize = smallest;
          notifyListeners();
        }
      }, debugLabel: 'AutoSizeGroup.update')
      ..ensureVisualUpdate();
  }
}
