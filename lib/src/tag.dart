import 'package:flutter/material.dart';

import 'style.dart';

class Tag {
  final String? tagName;

  final List<Style> styles = [];

  String? link;

  Tag(this.tagName);

  void addStyle(Style style) => styles.add(style);

  TextStyle _tagStyle(TextStyle textStyle, TextTheme textTheme) {
    switch (tagName) {
      case 'a':
        textStyle = _addDecoration(textStyle, TextDecoration.underline);
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
            fontSize: textTheme.headline1?.fontSize,
            fontWeight: textTheme.headline1?.fontWeight,
            letterSpacing: textTheme.headline1?.letterSpacing);
      case 'h2':
        return textStyle.copyWith(
            fontSize: textTheme.headline2?.fontSize,
            fontWeight: textTheme.headline2?.fontWeight,
            letterSpacing: textTheme.headline2?.letterSpacing);
      case 'h3':
        return textStyle.copyWith(
            fontSize: textTheme.headline3?.fontSize,
            fontWeight: textTheme.headline3?.fontWeight,
            letterSpacing: textTheme.headline3?.letterSpacing);
      case 'h4':
        return textStyle.copyWith(
            fontSize: textTheme.headline4?.fontSize,
            fontWeight: textTheme.headline4?.fontWeight,
            letterSpacing: textTheme.headline4?.letterSpacing);
      case 'h5':
        return textStyle.copyWith(
            fontSize: textTheme.headline5?.fontSize,
            fontWeight: textTheme.headline5?.fontWeight,
            letterSpacing: textTheme.headline5?.letterSpacing);
      case 'h6':
        return textStyle.copyWith(
            fontSize: textTheme.headline6?.fontSize,
            fontWeight: textTheme.headline6?.fontWeight,
            letterSpacing: textTheme.headline6?.letterSpacing);
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
