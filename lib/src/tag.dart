import 'package:flutter/material.dart' hide Element;

import 'style.dart';

enum ListTag {
  ol,
  ul;
}

class ListData {
  ListTag listTag;

  int nestedListNum;

  int? orderedNum;

  ListData(
      {required this.listTag, required this.nestedListNum, this.orderedNum});
}

class Tag {
  final String? tagName;

  final List<Style> styles = [];

  String? link;

  InlineSpan? inlineSpan;

  Tag(this.tagName);

  void addStyle(Style style) => styles.add(style);

  TextStyle _tagStyle(TextStyle textStyle, TextTheme textTheme) {
    switch (tagName) {
      case 'a':
        //textStyle = _addDecoration(textStyle, TextDecoration.underline);
        return textStyle.copyWith(
            foreground: Paint()..color = const Color(0xff0077dd));
      case 'b':
      case 'strong':
        return textStyle.copyWith(fontWeight: FontWeight.bold);
      case 'del':
      case 's':
        return _addDecoration(textStyle, TextDecoration.lineThrough);
      case 'em':
      case 'i':
        return textStyle.copyWith(fontStyle: FontStyle.italic);
      case 'h1':
        return textStyle.copyWith(
            fontSize: textTheme.displayLarge?.fontSize,
            fontWeight: textTheme.displayLarge?.fontWeight,
            letterSpacing: textTheme.displayLarge?.letterSpacing);
      case 'h2':
        return textStyle.copyWith(
            fontSize: textTheme.displayMedium?.fontSize,
            fontWeight: textTheme.displayMedium?.fontWeight,
            letterSpacing: textTheme.displayMedium?.letterSpacing);
      case 'h3':
        return textStyle.copyWith(
            fontSize: textTheme.displaySmall?.fontSize,
            fontWeight: textTheme.displaySmall?.fontWeight,
            letterSpacing: textTheme.displaySmall?.letterSpacing);
      case 'h4':
        return textStyle.copyWith(
            fontSize: textTheme.headlineMedium?.fontSize,
            fontWeight: textTheme.headlineMedium?.fontWeight,
            letterSpacing: textTheme.headlineMedium?.letterSpacing);
      case 'h5':
        return textStyle.copyWith(
            fontSize: textTheme.headlineSmall?.fontSize,
            fontWeight: textTheme.headlineSmall?.fontWeight,
            letterSpacing: textTheme.headlineSmall?.letterSpacing);
      case 'h6':
        return textStyle.copyWith(
            fontSize: textTheme.titleLarge?.fontSize,
            fontWeight: textTheme.titleLarge?.fontWeight,
            letterSpacing: textTheme.titleLarge?.letterSpacing);
      case 'ins':
      case 'u':
        return _addDecoration(textStyle, TextDecoration.underline);
      default:
        return textStyle;
    }
  }

  TextStyle style(TextStyle textStyle, TextTheme textTheme) {
    var tagStyle = _tagStyle(textStyle, textTheme);

    for (final style in styles) {
      tagStyle = style.addTo(textStyle: tagStyle, parentTextStyle: textStyle);
    }

    return tagStyle;
  }
}

TextStyle _addDecoration(TextStyle textStyle, TextDecoration textDecoration) {
  final decoration = textStyle.decoration;
  if (decoration != null) {
    if (decoration.contains(textDecoration)) {
      return textStyle;
    }
    final decorations = <TextDecoration>[textDecoration];
    if (decoration.contains(TextDecoration.lineThrough)) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (decoration.contains(TextDecoration.none)) {
      decorations.add(TextDecoration.none);
    }
    if (decoration.contains(TextDecoration.overline)) {
      decorations.add(TextDecoration.overline);
    }
    if (decoration.contains(TextDecoration.underline)) {
      decorations.add(TextDecoration.underline);
    }
    return textStyle.copyWith(decoration: TextDecoration.combine(decorations));
  } else {
    return textStyle.copyWith(decoration: textDecoration);
  }
}
