## 0.1.0

* 🎉 Initial release.
* `AutoSizeText`, `AutoSizeText.rich` and `AutoSizeGroup` with the same
  arguments as the `auto_size_text` package, so switching only takes
  changing the import.
* Rebuilt as a single render object that measures and paints the text with
  the same layout, so the picked size always matches what is painted,
  including with the bold text setting.
* New: `gradient` fills the text with any gradient, stretched across its
  lines.
* New: `strokeWidth`, `strokeColor` and `strokeGradient` draw an outline
  around the text, taken into account while fitting. With a transparent
  fill, it draws hollow text with the same outline thickness.
* New: `AutoSizeGroup.fontSize` reports the shared font size, and the group
  notifies listeners when it changes.
* New: `textScaler`, `textWidthBasis` and `textHeightBehavior`.
  `textScaleFactor` still works but is deprecated.
* Works inside `IntrinsicHeight`, `IntrinsicWidth`, `Table` and `DataTable`,
  and with baseline alignment.
* Texts in a group are painted at the shared size from the first frame.
* `minFontSize` and `maxFontSize` no longer need to be multiples of
  `stepGranularity`, and text smaller than `minFontSize` is no longer
  enlarged.
* The text is only fitted again when its text, style or space changes, not
  on every rebuild or color change. Text painters are disposed.
