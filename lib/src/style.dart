import 'package:flutter/material.dart';
import 'package:from_css_color/from_css_color.dart';

abstract class Style {
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle});
}

class ColorStyle implements Style {
  final String color;

  ColorStyle(String color) : color = color.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    try {
      final color_ = fromCssColor(color);
      return textStyle.copyWith(foreground: Paint()..color = color_);
    } catch (e) {
      debugPrint('fails to convert CSS color to Color: $e');
      return textStyle;
    }
  }
}

class BackgroundColorStyle implements Style {
  final String color;

  BackgroundColorStyle(String color) : color = color.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    try {
      final color_ = fromCssColor(color);
      return textStyle.copyWith(background: Paint()..color = color_);
    } catch (e) {
      debugPrint('fails to convert CSS color to Color: $e');
      return textStyle;
    }
  }
}

class FontWeightStyle implements Style {
  static const List<String> numberValues = [
    '100',
    '200',
    '300',
    '400',
    '500',
    '600',
    '700',
    '800',
    '900',
  ];

  final String value;

  FontWeightStyle(String value) : value = value.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    final index = numberValues.indexOf(value);
    if (index >= 0) {
      return textStyle.copyWith(fontWeight: FontWeight.values[index]);
    }

    switch (value) {
      case 'normal':
        return textStyle.copyWith(fontWeight: FontWeight.normal);
      case 'bold':
        return textStyle.copyWith(fontWeight: FontWeight.bold);
      case 'lighter':
        if (parentTextStyle.fontWeight != null) {
          final index = parentTextStyle.fontWeight!.index;
          return index > 0
              ? textStyle.copyWith(fontWeight: FontWeight.values[index - 1])
              : textStyle.copyWith(fontWeight: FontWeight.w100);
        }
        debugPrint('no parent font weight, fails to get the font weight');
        return textStyle.copyWith(fontWeight: FontWeight.w300);
      case 'bolder':
        if (parentTextStyle.fontWeight != null) {
          final index = parentTextStyle.fontWeight!.index;
          return index < FontWeight.values.length - 1
              ? textStyle.copyWith(fontWeight: FontWeight.values[index + 1])
              : textStyle.copyWith(fontWeight: FontWeight.w900);
        }
        debugPrint('no parent font weight, fails to get the font weight');
        return textStyle.copyWith(fontWeight: FontWeight.w500);
    }

    debugPrint('unknown font weight: $value');
    return textStyle;
  }
}

class FontSlantStyle implements Style {
  final String value;

  FontSlantStyle(String value) : value = value.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    if (value == 'normal') {
      return textStyle.copyWith(fontStyle: FontStyle.normal);
    }
    if (value == 'italic' || value.startsWith('oblique')) {
      return textStyle.copyWith(fontStyle: FontStyle.italic);
    }

    debugPrint('unknown font style: $value');
    return textStyle;
  }
}

class FontSizeStyle implements Style {
  final String value;

  FontSizeStyle(String value) : value = value.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    if (value.endsWith('px')) {
      return textStyle.copyWith(
          fontSize: double.tryParse(value.replaceAll('px', '').trim()) ?? 14.0);
    }

    if (value.endsWith('em')) {
      if (parentTextStyle.fontSize != null) {
        try {
          final size = parentTextStyle.fontSize! *
              (double.parse(value.replaceAll('em', '').trim()));
          return textStyle.copyWith(fontSize: size);
        } catch (e) {
          debugPrint('fails to get the font size: $e');
          return textStyle.copyWith(fontSize: parentTextStyle.fontSize);
        }
      } else {
        debugPrint('no parent font size, fails to get the font size');
        return textStyle.copyWith(fontSize: 14.0);
      }
    }

    if (value.endsWith('%')) {
      if (parentTextStyle.fontSize != null) {
        try {
          final size = parentTextStyle.fontSize! *
              (double.parse(value.replaceAll('%', '').trim())) /
              100.0;
          return textStyle.copyWith(fontSize: size);
        } catch (e) {
          debugPrint('fails to get the font size: $e');
          return textStyle.copyWith(fontSize: parentTextStyle.fontSize);
        }
      } else {
        debugPrint('no parent font size, fails to get the font size');
        return textStyle.copyWith(fontSize: 14.0);
      }
    }

    switch (value) {
      case 'xx-small':
        return textStyle.copyWith(fontSize: 14.0 * 0.55);
      case 'x-small':
        return textStyle.copyWith(fontSize: 14.0 * 0.7);
      case 'small':
        return textStyle.copyWith(fontSize: 14.0 * 0.85);
      case 'medium':
        return textStyle.copyWith(fontSize: 14.0);
      case 'large':
        return textStyle.copyWith(fontSize: 14.0 * 1.15);
      case 'x-large':
        return textStyle.copyWith(fontSize: 14.0 * 1.3);
      case 'xx-large':
        return textStyle.copyWith(fontSize: 14.0 * 1.45);
      case 'xxx-large':
        return textStyle.copyWith(fontSize: 14.0 * 1.6);
      case 'smaller':
        if (parentTextStyle.fontSize != null) {
          return textStyle.copyWith(fontSize: parentTextStyle.fontSize! * 0.85);
        }
        debugPrint('no parent font size, fails to get the font size');
        return textStyle.copyWith(fontSize: 14.0 * 0.85);
      case 'larger':
        if (parentTextStyle.fontSize != null) {
          return textStyle.copyWith(fontSize: parentTextStyle.fontSize! * 1.15);
        }
        debugPrint('no parent font size, fails to get the font size');
        return textStyle.copyWith(fontSize: 14.0 * 1.15);
    }

    debugPrint('unknown font size: $value');
    return textStyle;
  }
}

class FontFamilyStyle implements Style {
  final String fontFamily;

  const FontFamilyStyle(this.fontFamily);

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    var font = fontFamily.split(',')[0].trim();
    if ((font.startsWith('"') && font.endsWith('"')) ||
        (font.startsWith("'") && font.endsWith("'"))) {
      font = font.substring(1, font.length - 1);
    }

    return textStyle.copyWith(fontFamily: font);
  }
}

class DecorationStyle implements Style {
  final String values;

  DecorationStyle(String values) : values = values.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    final decorations = <TextDecoration>[];
    TextDecorationStyle? decorationStyle;
    Color? decorationColor;

    final decoration = textStyle.decoration;
    if (decoration != null) {
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
    }

    for (final value
        in values.split(' ').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      switch (value) {
        case 'none':
          decorations.add(TextDecoration.none);
          break;
        case 'underline':
          decorations.add(TextDecoration.underline);
          break;
        case 'overline':
          decorations.add(TextDecoration.overline);
          break;
        case 'line-through':
          decorations.add(TextDecoration.lineThrough);
          break;
        case 'solid':
          decorationStyle = TextDecorationStyle.solid;
          break;
        case 'double':
          decorationStyle = TextDecorationStyle.double;
          break;
        case 'dotted':
          decorationStyle = TextDecorationStyle.dotted;
          break;
        case 'dashed':
          decorationStyle = TextDecorationStyle.dashed;
          break;
        case 'wavy':
          decorationStyle = TextDecorationStyle.wavy;
          break;
        default:
          try {
            decorationColor = fromCssColor(value);
          } catch (e) {
            debugPrint('unknown text decoration: $value');
          }
      }
    }

    return textStyle.copyWith(
        decoration:
            decorations.isEmpty ? null : TextDecoration.combine(decorations),
        decorationStyle: decorationStyle ?? textStyle.decorationStyle,
        decorationColor: decorationColor ?? textStyle.decorationColor);
  }
}

class LineHeightStyle implements Style {
  final String value;

  LineHeightStyle(String value) : value = value.toLowerCase();

  @override
  TextStyle addTo(
      {required TextStyle textStyle, required TextStyle parentTextStyle}) {
    if (value == 'normal') {
      return textStyle;
    }

    final height = double.tryParse(value);
    if (height != null) {
      return textStyle.copyWith(height: height);
    }

    if (value.endsWith('px')) {
      if (textStyle.fontSize != null) {
        try {
          final height = double.parse(value.replaceAll('px', '').trim());
          return textStyle.copyWith(height: height / textStyle.fontSize!);
        } catch (e) {
          debugPrint('fails to get the line height: $e');
          return textStyle;
        }
      } else {
        debugPrint('no font size in the text style');
        return textStyle;
      }
    }

    if (value.endsWith('em')) {
      try {
        final height = double.parse(value.replaceAll('em', '').trim());
        return textStyle.copyWith(height: height);
      } catch (e) {
        debugPrint('fails to get the line height: $e');
        return textStyle;
      }
    }

    if (value.endsWith('%')) {
      try {
        final height = double.parse(value.replaceAll('%', '').trim());
        return textStyle.copyWith(height: height / 100.0);
      } catch (e) {
        debugPrint('fails to get the line height: $e');
        return textStyle;
      }
    }

    debugPrint('unknown line height: $value');
    return textStyle;
  }
}
