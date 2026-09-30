<div align="center">

# 🔠 auto_size_text_kit

**Text that fits. With gradients and outlines.**

A drop-in replacement for `auto_size_text`: text that shrinks its font size
until it fits its space, plus gradient fills and outlines that are measured
together with the text, so they never get cut off.

[![pub package](https://img.shields.io/pub/v/auto_size_text_kit.svg)](https://pub.dev/packages/auto_size_text_kit)
[![likes](https://img.shields.io/pub/likes/auto_size_text_kit)](https://pub.dev/packages/auto_size_text_kit/score)
[![pub points](https://img.shields.io/pub/points/auto_size_text_kit)](https://pub.dev/packages/auto_size_text_kit/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

<img src="https://raw.githubusercontent.com/parthbhensdadiya226/auto_size_text_kit/main/doc/hero.gif" width="300" alt="Headlines, gradient text, outlined text, numbers and buttons shrinking as their space gets narrower">

</div>

---

## 📚 Contents

- [Why auto_size_text_kit?](#-why-auto_size_text_kit)
- [Switching from auto_size_text](#-switching-from-auto_size_text)
- [Quick start](#-quick-start)
- [How the font size is picked](#-how-the-font-size-is-picked)
- [Gradient and outline](#-gradient-and-outline)
- [Same size in a group](#-same-size-in-a-group)
- [Rich text](#-rich-text)
- [When the text doesn't fit](#-when-the-text-doesnt-fit)
- [Rows, tables and IntrinsicHeight](#-rows-tables-and-intrinsicheight)
- [All parameters](#-all-parameters)
- [Platforms](#-platforms)

## ✨ Why auto_size_text_kit?

auto_size_text_kit keeps the API of
[`auto_size_text`](https://pub.dev/packages/auto_size_text), so your code
stays the same. Inside, it is built as a single render object that measures
and paints the text in one place, which is what makes the extras below
possible:

| | |
|---|---|
| 🎯 **Measures what it paints** | The size is picked with exactly the same text layout that is painted, so text isn't cut off when bold text is on or the alignment and direction differ |
| 🌈 **Gradient fill** | Any `Gradient`, stretched across the lines of text |
| ✏️ **Outline** | A solid or gradient outline, taken into account while fitting |
| 📐 **Works where layout measures first** | `IntrinsicHeight`, `IntrinsicWidth`, `Table`, `DataTable`, baseline rows |
| 👯 **Groups without flicker** | Texts in a group are painted at the shared size from the first frame |
| 🔍 **Accessible text scaling** | Uses `TextScaler`, including Android 14's nonlinear font scaling |
| 🧹 **No leaks** | Every text painter is disposed |
| ⚡ **Fits once** | The size is only picked again when its text, style or space changes, not on every rebuild or color change |
| 📦 **No dependencies** | Only Flutter itself |

## 🔁 Switching from auto_size_text

Change the dependency and the import. Everything else stays the same.

```yaml
dependencies:
  auto_size_text_kit: ^0.1.0
```

```dart
// Before
import 'package:auto_size_text/auto_size_text.dart';

// After
import 'package:auto_size_text_kit/auto_size_text_kit.dart';
```

`AutoSizeText`, `AutoSizeText.rich` and `AutoSizeGroup` take the same
arguments. A few things behave differently:

| | auto_size_text 3.0.0 | auto_size_text_kit |
|---|---|---|
| `minFontSize` and `maxFontSize` | Must be multiples of `stepGranularity` (checked by an assertion) | Any value |
| Style smaller than `minFontSize` | Grows to `minFontSize` | Stays at the style's size |
| `textScaleFactor` | Supported | Still works, but deprecated: use `textScaler` |
| Bold text setting (iOS and Android) | Measured as regular, painted bold | Measured and painted bold |
| Inside `IntrinsicHeight` or `DataTable` | Not supported: it uses a `LayoutBuilder`, which can't report intrinsic sizes | Works |
| Reading the font size | No API for it | `AutoSizeGroup.fontSize` |

The one difference to know: `textKey` now finds the widget that lays out
the text instead of a `Text` widget, since there is no `Text` inside.

**Switching file by file?** Both packages use the same class names, so a
file that imports both gets an "imported from both" error. Hide the old
names in that file until you remove `auto_size_text`:

```dart
import 'package:auto_size_text/auto_size_text.dart'
    hide AutoSizeText, AutoSizeGroup;
import 'package:auto_size_text_kit/auto_size_text_kit.dart';
```

## 🚀 Quick start

```dart
import 'package:auto_size_text_kit/auto_size_text_kit.dart';

SizedBox(
  width: 200,
  child: AutoSizeText(
    'The quick brown fox jumps over the lazy dog',
    style: TextStyle(fontSize: 30),
    maxLines: 2,
  ),
)
```

The text starts at 30 and gets smaller until it fits in two lines of 200
pixels.

> **Tip:** AutoSizeText needs a limit to fit into. Give it a width (a
> `SizedBox`, `Expanded` or `Flexible`), and a `maxLines` or a height.
> Without any limit, the text simply stays at its style's size.

## 📏 How the font size is picked

1. The text starts at the font size of its `style`, or `maxFontSize` if
   that's smaller.
2. If it doesn't fit the width, the height and `maxLines`, it tries smaller
   sizes, going down in steps of `stepGranularity` (1 by default).
3. It stops at `minFontSize` (12 by default). If the text still doesn't
   fit, `overflow` or `overflowReplacement` decide what happens.

The biggest size that fits is found with a binary search, so even a big
range takes only a few measurements.

```dart
AutoSizeText(
  'Welcome back',
  style: TextStyle(fontSize: 40),
  minFontSize: 18,     // never smaller than 18
  maxFontSize: 32,     // never bigger than 32, even though the style says 40
  stepGranularity: 2,  // 18, 20, 22, ...
  maxLines: 1,
)
```

**Only some sizes allowed?** Pass them from biggest to smallest. The first
one that fits is used:

```dart
AutoSizeText(
  'Welcome back',
  presetFontSizes: [40, 28, 20, 14],
  maxLines: 1,
)
```

**Don't want words split across lines?** By default, a word too long for a
line on its own is broken, like `Text` does. With `wrapWords: false`, the
text shrinks until every word fits on a line instead:

```dart
AutoSizeText('Supercalifragilistic', maxLines: 2, wrapWords: false)
```

**Accessibility.** The user's text size setting is applied on top of the
picked size, and also scales `minFontSize`, `maxFontSize` and
`presetFontSizes`. Pass `textScaler` to override it.

## 🌈 Gradient and outline

<img src="https://raw.githubusercontent.com/parthbhensdadiya226/auto_size_text_kit/main/doc/gradient_outline.png" width="420" alt="SUMMER SALE in a gradient with a white outline, the word Outlined with a gradient outline, and three numbers: one with a gradient and outline, one outline only, one gradient only">

```dart
AutoSizeText(
  'SUMMER SALE',
  style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900),
  maxLines: 1,
  gradient: LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF6F61)]),
  strokeWidth: 3,
  strokeColor: Colors.white,
)
```

- `gradient` fills the text with any `Gradient`: linear, radial or sweep.
  It stretches across the lines of text, not the whole box, so short
  centered text still shows every color.
- `strokeWidth` draws an outline that thick around every letter. The
  outline sits outside the letters and is part of the text's size, so a
  fitted text with an outline is never cut off.
- `strokeColor` colors the outline (black by default), or `strokeGradient`
  fills it with a gradient.
- Shadows in the style are drawn under the outline.

**Numbers** are where this shines: prices, scores and stats. Put them in a
group so they share one size:

```dart
final group = AutoSizeGroup();
const style = TextStyle(fontSize: 48, fontWeight: FontWeight.w900);

Row(
  // An outline takes space like a border, so outlined numbers are a little
  // taller. Aligning on the baseline lines the digits up.
  crossAxisAlignment: CrossAxisAlignment.baseline,
  textBaseline: TextBaseline.alphabetic,
  children: [
    // Gradient and outline
    Expanded(
      child: AutoSizeText(
        '2,480',
        group: group,
        style: style,
        maxLines: 1,
        gradient: LinearGradient(colors: [Colors.amber, Colors.orange]),
        strokeWidth: 2,
        strokeColor: Colors.white,
      ),
    ),
    // Outline only: a transparent fill leaves just the outline
    Expanded(
      child: AutoSizeText(
        '98%',
        group: group,
        style: style.copyWith(color: Colors.transparent),
        maxLines: 1,
        strokeWidth: 2,
        strokeColor: Colors.tealAccent,
      ),
    ),
    // Gradient only
    Expanded(
      child: AutoSizeText(
        '4.9',
        group: group,
        style: style,
        maxLines: 1,
        gradient: LinearGradient(colors: [Colors.lightBlue, Colors.purple]),
      ),
    ),
  ],
)
```

With a transparent fill, the outline keeps the same thickness as on filled
text.

**Just want gradient or outlined text, without shrinking?** Use it without
limits (no `maxLines`, enough space), and it's regular styled text.

## 👯 Same size in a group

Texts that belong together, like buttons in a row, look odd at different
sizes. Give them the same `AutoSizeGroup`, and all of them use the size of
the one that needs the smallest:

```dart
final group = AutoSizeGroup();

Row(
  children: [
    for (final label in ['OK', 'Save', 'Publish'])
      Expanded(
        child: FilledButton(
          onPressed: () {},
          child: AutoSizeText(label, group: group, maxLines: 1),
        ),
      ),
  ],
)
```

Create the group once in a `State`, not in `build`, and dispose it with the
state:

```dart
class _MyPageState extends State<MyPage> {
  final _group = AutoSizeGroup();

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  // ... pass _group to your AutoSizeTexts in build.
}
```

**Reading the size.** The group tells you the size it picked, so you can
size an icon to match, for example:

```dart
ListenableBuilder(
  listenable: group,
  builder: (context, _) => Icon(Icons.check, size: group.fontSize ?? 24),
)
```

`fontSize` is the size before the user's text scale. Use a group with a
single text to read the size of that text.

## ✍️ Rich text

`AutoSizeText.rich` shrinks the whole text together, so parts with
different sizes keep their proportions:

```dart
AutoSizeText.rich(
  TextSpan(children: [
    TextSpan(text: '\$1,299'),
    TextSpan(
      text: ' / month',
      style: TextStyle(fontSize: 24, color: Colors.grey),
    ),
  ]),
  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800),
  maxLines: 1,
)
```

Tap recognizers on spans keep working. A `gradient` fills every part that
has no color of its own; spans with a color, like ' / month' above, keep it.
`WidgetSpan`s aren't supported.

## 🙈 When the text doesn't fit

Even at `minFontSize` some text is too long. `overflow` works like on
`Text`:

```dart
AutoSizeText(
  'A very long product name that never fits',
  maxLines: 1,
  minFontSize: 14,
  overflow: TextOverflow.ellipsis, // or clip, fade, visible
)
```

Or show a different widget instead:

```dart
AutoSizeText(
  user.fullName,
  maxLines: 1,
  minFontSize: 16,
  overflowReplacement: Text(user.initials),
)
```

## 📐 Rows, tables and IntrinsicHeight

- **In a `Row`**, wrap the text in `Expanded` or `Flexible`. Otherwise the
  row gives it unlimited width, and it never has to shrink.
- **`IntrinsicHeight`, `IntrinsicWidth`, `Table` and `DataTable`** measure
  their children before laying them out. That works: the text reports the
  height it will have at the size it will pick.
- **Baseline alignment** in rows works too.

## 🧾 All parameters

Everything the package gives you:

| API | What it is |
|---|---|
| `AutoSizeText('text', ...)` | Auto-sizing text from a `String` |
| `AutoSizeText.rich(TextSpan(...), ...)` | Auto-sizing text from a `TextSpan`, for mixed styles |
| `AutoSizeGroup()` | Keeps several texts at the same size |
| `group.fontSize` | The size the group picked, or null while it's empty |
| `group.addListener(...)` | Called when `fontSize` changes (it's a `ChangeNotifier`) |
| `group.dispose()` | Frees the group when you're done with it |

`AutoSizeText` and `AutoSizeText.rich` take the same parameters, the same
as `auto_size_text`. The ones in **bold** are new:

| Parameter | Default | What it does |
|---|---|---|
| `style` | `DefaultTextStyle` | Its font size is the biggest size the text is shown at |
| `minFontSize` | `12` | The smallest size the text shrinks to |
| `maxFontSize` | none | The biggest size, even if the style is bigger |
| `stepGranularity` | `1` | How much the size changes with each step |
| `presetFontSizes` | none | The only sizes allowed, biggest first |
| `maxLines` | `DefaultTextStyle` | The most lines the text may take |
| `group` | none | Keeps several texts at the same size |
| `wrapWords` | `true` | Whether a long word may be split across lines |
| `overflow` | `DefaultTextStyle` | What happens when it doesn't fit even at `minFontSize` |
| `overflowReplacement` | none | Shown instead when it doesn't fit |
| **`textScaler`** | `MediaQuery` | Scales the text for accessibility |
| `textAlign`, `textDirection`, `locale`, `softWrap`, `strutStyle`, `semanticsLabel` | | Like on `Text` |
| **`textWidthBasis`**, **`textHeightBehavior`** | | Like on `Text` |
| `textScaleFactor` | none | Deprecated, use `textScaler`. Still works |
| `textKey` | none | A key for the widget that lays out the text |
| **`gradient`** | none | Fills the text with a gradient |
| **`strokeWidth`** | `0` | Width of the outline around the text |
| **`strokeColor`** | black | Color of the outline |
| **`strokeGradient`** | none | Fills the outline with a gradient |

## 📱 Platforms

Pure Dart with no dependencies besides Flutter, so it works everywhere
Flutter runs: Android, iOS, web, macOS, Windows and Linux. Tested with widget tests and in the example app on the
web (Chromium).

The example app in [`example/`](example) shows every feature, with a slider
to squeeze the space.

---

API compatible with [auto_size_text](https://pub.dev/packages/auto_size_text)
by Simon Leier, so switching takes one import. The code is written from
scratch.

Found a bug or have an idea?
[Open an issue](https://github.com/parthbhensdadiya226/auto_size_text_kit/issues).
