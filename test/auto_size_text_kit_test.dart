import 'package:auto_size_text_kit/auto_size_text_kit.dart';
import 'package:auto_size_text_kit/src/render_auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// In the test font every glyph is a square as wide and tall as the font
// size, so 'Hello' at 10 is 50 wide and 10 tall.

Future<RenderAutoSizeText> pumpText(
  WidgetTester tester,
  Widget text, {
  double width = 1000,
  double height = 1000,
  MediaQueryData media = const MediaQueryData(),
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: media,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: width,
            height: height,
            // Loose, so the text is only as big as it needs to be.
            child: Align(alignment: Alignment.topLeft, child: text),
          ),
        ),
      ),
    ),
  );
  return renderOf(tester, find.byType(AutoSizeText));
}

/// The render object of the text inside [finder].
RenderAutoSizeText renderOf(WidgetTester tester, Finder finder) =>
    tester.renderObject(
      find.descendant(
        of: finder,
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_AutoSizeTextLayout',
        ),
      ),
    );

void main() {
  const style = TextStyle(fontSize: 20);

  testWidgets('keeps the style size when the text fits', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1),
    );
    expect(text.fontSize, 20);
    expect(text.textFits, isTrue);
  });

  testWidgets('shrinks to the biggest size that fits', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1, minFontSize: 1),
      width: 50,
    );
    expect(text.fontSize, 10);
    expect(text.size.width, 50);
  });

  testWidgets('never grows past the style size or maxFontSize', (tester) async {
    var text = await pumpText(
      tester,
      const AutoSizeText('Hi', style: TextStyle(fontSize: 8)),
    );
    expect(text.fontSize, 8);

    text = await pumpText(
      tester,
      const AutoSizeText('Hi', style: style, maxFontSize: 15),
    );
    expect(text.fontSize, 15);
  });

  testWidgets('stops at minFontSize and shows the replacement', (tester) async {
    var text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1),
      width: 20,
    );
    expect(text.fontSize, 12);
    expect(text.textFits, isFalse);

    await pumpText(
      tester,
      const AutoSizeText(
        'Hello',
        style: style,
        maxLines: 1,
        overflowReplacement: Text('Too long'),
      ),
      width: 20,
    );
    expect(find.text('Too long'), findsOneWidget);
  });

  testWidgets('wraps onto maxLines before shrinking', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText(
        'Hello world',
        style: style,
        maxLines: 2,
        minFontSize: 1,
      ),
      width: 100,
    );
    // 'Hello' and 'world' each take a line at 20: 100 wide.
    expect(text.fontSize, 20);
    expect(text.size.height, 40);
  });

  testWidgets('shrinks to fit the height', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText('Hello world', style: style, minFontSize: 1),
      width: 100,
      height: 30,
    );
    // Two lines have to fit in 30: 15 each.
    expect(text.fontSize, 15);
  });

  testWidgets('step sizes need not divide the font sizes', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText(
        'Hello',
        style: style,
        maxLines: 1,
        minFontSize: 5,
        stepGranularity: 3,
      ),
      width: 60,
    );
    // Tries 5, 8, 11, 14, 17: 11 is the biggest under 12 (60 / 5).
    expect(text.fontSize, 11);
  });

  testWidgets('uses the first preset size that fits', (tester) async {
    var text = await pumpText(
      tester,
      const AutoSizeText(
        'Hello',
        maxLines: 1,
        presetFontSizes: [30, 20, 10, 5],
      ),
      width: 60,
    );
    expect(text.fontSize, 10);

    text = await pumpText(
      tester,
      const AutoSizeText('Hello', maxLines: 1, presetFontSizes: [30, 20]),
      width: 60,
    );
    expect(text.fontSize, 20);
    expect(text.textFits, isFalse);
  });

  testWidgets('leaves room for the outline', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText(
        'Hello',
        style: style,
        maxLines: 1,
        minFontSize: 1,
        strokeWidth: 5,
      ),
      width: 50,
    );
    // 10 on each side for the outline leaves 40: 8 per letter.
    expect(text.fontSize, 8);
    expect(text.size, const Size(50, 18));
  });

  testWidgets('applies the text scaler on top of the fitted size', (
    tester,
  ) async {
    var text = await pumpText(
      tester,
      const AutoSizeText('Hi', style: style),
      media: const MediaQueryData(textScaler: TextScaler.linear(2)),
    );
    expect(text.size.width, 80);

    text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1, minFontSize: 1),
      width: 50,
      media: const MediaQueryData(textScaler: TextScaler.linear(2)),
    );
    // 5 before scaling, 10 on screen.
    expect(text.fontSize, 5);
    expect(text.size.width, 50);
  });

  testWidgets('measures bold text as bold', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1, minFontSize: 1),
      width: 50,
      media: const MediaQueryData(boldText: true),
    );
    expect(text.settings.text.style!.fontWeight, FontWeight.bold);
    expect(text.size.width, lessThanOrEqualTo(50));
  });

  testWidgets('shrinks instead of breaking words when wrapWords is false', (
    tester,
  ) async {
    var text = await pumpText(
      tester,
      const AutoSizeText('Hi abcdefghij', style: style, minFontSize: 1),
      width: 100,
    );
    expect(text.fontSize, 20);

    text = await pumpText(
      tester,
      const AutoSizeText(
        'Hi abcdefghij',
        style: style,
        minFontSize: 1,
        wrapWords: false,
      ),
      width: 100,
    );
    // The 10 letter word has to fit a line: 10 per letter.
    expect(text.fontSize, 10);
  });

  testWidgets('rich text keeps its proportions', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText.rich(
        TextSpan(
          text: 'AA',
          children: [TextSpan(text: 'BB', style: TextStyle(fontSize: 40))],
        ),
        style: style,
        maxLines: 1,
        minFontSize: 1,
      ),
      width: 60,
    );
    // 2 * 20 + 2 * 40 = 120 at full size, so half size fits 60.
    expect(text.fontSize, 10);
    expect(text.size.width, 60);
  });

  testWidgets('a group shows the smallest size of its texts', (tester) async {
    final group = AutoSizeGroup();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: AutoSizeText(
                'Hi',
                key: const Key('short'),
                style: style,
                group: group,
                maxLines: 1,
                minFontSize: 1,
              ),
            ),
            SizedBox(
              width: 100,
              child: AutoSizeText(
                'Hello world',
                key: const Key('long'),
                style: style,
                group: group,
                maxLines: 1,
                minFontSize: 1,
              ),
            ),
          ],
        ),
      ),
    );
    // Already painted at the shared size in the first frame: no flicker.
    expect(renderOf(tester, find.byKey(const Key('short'))).fontSize, 9);
    await tester.pump();

    // 'Hello world' is 11 letters: 9 fits 100.
    expect(renderOf(tester, find.byKey(const Key('long'))).fontSize, 9);
    expect(renderOf(tester, find.byKey(const Key('short'))).fontSize, 9);
    expect(group.fontSize, 9);
  });

  testWidgets('a group grows back when its smallest text leaves', (
    tester,
  ) async {
    final group = AutoSizeGroup();
    Widget build({required bool withLong}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: AutoSizeText(
              'Hi',
              style: style,
              group: group,
              maxLines: 1,
              minFontSize: 1,
            ),
          ),
          if (withLong)
            SizedBox(
              width: 100,
              child: AutoSizeText(
                'Hello world',
                style: style,
                group: group,
                maxLines: 1,
                minFontSize: 1,
              ),
            ),
        ],
      ),
    );
    await tester.pumpWidget(build(withLong: true));
    await tester.pump();
    expect(group.fontSize, 9);

    await tester.pumpWidget(build(withLong: false));
    await tester.pump();
    expect(group.fontSize, 20);
  });

  testWidgets('works inside IntrinsicHeight and reports its height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 50,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AutoSizeText(
                      'Hello',
                      style: style,
                      maxLines: 1,
                      minFontSize: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(IntrinsicHeight)).height, 10);
  });

  testWidgets('works in tables and IntrinsicWidth', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: [
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: const [
                  TableRow(
                    children: [
                      AutoSizeText('Name', style: style, maxLines: 1),
                      AutoSizeText('Value', style: style, maxLines: 1),
                    ],
                  ),
                ],
              ),
              DataTable(
                columns: const [
                  DataColumn(label: AutoSizeText('Name', maxLines: 1)),
                ],
                rows: const [
                  DataRow(
                    cells: [
                      DataCell(AutoSizeText('A long cell value', maxLines: 1)),
                    ],
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.topLeft,
                child: IntrinsicWidth(
                  key: Key('intrinsic'),
                  child: AutoSizeText(
                    'Hello',
                    // No letter spacing from the Material theme.
                    style: TextStyle(fontSize: 20, letterSpacing: 0),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Five letters at 20 plus 2 on each side for the outline.
    expect(tester.getSize(find.byKey(const Key('intrinsic'))).width, 104);
  });

  testWidgets('aligns on the baseline in a row', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 50,
              child: AutoSizeText(
                'Hello',
                style: style,
                maxLines: 1,
                minFontSize: 1,
              ),
            ),
            Text('Hi', style: TextStyle(fontSize: 30)),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('taps reach span recognizers', (tester) async {
    var taps = 0;
    final recognizer = TapGestureRecognizer()..onTap = () => taps++;
    addTearDown(recognizer.dispose);
    await pumpText(
      tester,
      AutoSizeText.rich(
        TextSpan(text: 'Tap', recognizer: recognizer),
        style: style,
        gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
        strokeWidth: 2,
      ),
      width: 200,
      height: 50,
    );
    await tester.tap(find.byType(AutoSizeText));
    expect(taps, 1);
  });

  testWidgets('screen readers read the text or the label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpText(tester, const AutoSizeText('Hello', style: style));
    expect(find.bySemanticsLabel('Hello'), findsOneWidget);

    await pumpText(
      tester,
      const AutoSizeText(r'$$', style: style, semanticsLabel: 'Double dollars'),
    );
    expect(find.bySemanticsLabel('Double dollars'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('paints gradients, outlines and every overflow', (tester) async {
    for (final overflow in TextOverflow.values) {
      await pumpText(
        tester,
        AutoSizeText(
          'Hello world, this does not fit',
          style: style.copyWith(
            shadows: const [Shadow(blurRadius: 2)],
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: overflow,
          gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
          strokeWidth: 2,
          strokeGradient: const LinearGradient(
            colors: [Colors.white, Colors.black],
          ),
        ),
        width: 100,
        height: 40,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fits again when the text or the space changes', (tester) async {
    var text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1, minFontSize: 1),
      width: 50,
    );
    expect(text.fontSize, 10);

    text = await pumpText(
      tester,
      const AutoSizeText('Hello', style: style, maxLines: 1, minFontSize: 1),
      width: 25,
    );
    expect(text.fontSize, 5);

    text = await pumpText(
      tester,
      const AutoSizeText('Hi', style: style, maxLines: 1, minFontSize: 1),
      width: 25,
    );
    expect(text.fontSize, 12);
  });

  testWidgets('a color change repaints without fitting again', (tester) async {
    final text = await pumpText(
      tester,
      const AutoSizeText(
        'Hello',
        style: TextStyle(fontSize: 20, color: Colors.red),
        maxLines: 1,
        minFontSize: 1,
      ),
      width: 50,
    );
    await pumpText(
      tester,
      const AutoSizeText(
        'Hello',
        style: TextStyle(fontSize: 20, color: Colors.blue),
        maxLines: 1,
        minFontSize: 1,
      ),
      width: 50,
    );
    expect(text.debugNeedsLayout, isFalse);
    expect(text.fontSize, 10);
  });
}
