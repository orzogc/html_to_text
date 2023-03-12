import 'package:flutter/material.dart' hide Element;
import 'package:html/dom.dart';

import 'parser.dart';

typedef OnTapLinkCallback = void Function(
    BuildContext context, String link, String text);

typedef OnTapTextCallback = void Function(BuildContext context, String text);

typedef OnTextCallback = String? Function(BuildContext context, String text);

typedef OnTagCallback = InlineSpan? Function(
    BuildContext context, Element element, TextStyle textStyle);

typedef OnImageCallback = InlineSpan? Function(
    BuildContext context, String? image, Element element);

typedef BuildTextCallback = InlineSpan Function(
    BuildContext context, String text, TextStyle textStyle, String? link);

class HtmlText {
  final Parser _parser;

  BuildContext get context => _parser.context;

  String get html => _parser.html;

  OnTapLinkCallback? get onTapLink => _parser.onTapLink;

  OnTextCallback? get onText => _parser.onText;

  bool get isParsingTextRecursively => _parser.isParsingTextRecursively;

  Map<String, OnTagCallback>? get onTags => _parser.onTags;

  OnImageCallback? get onImage => _parser.onImage;

  BuildTextCallback? get buildText => _parser.buildText;

  TextStyle? get textStyle => _parser.textStyle;

  TextTheme? get textTheme => _parser.textTheme;

  TextStyle? get overrodeTextStyle => _parser.overrodeTextStyle;

  HtmlText(
    BuildContext context,
    String html, {
    OnTapLinkCallback? onTapLink,
    OnTapTextCallback? onTapText,
    OnTextCallback? onText,
    bool isParsingTextRecursively = false,
    Map<String, OnTagCallback>? onTags,
    OnImageCallback? onImage,
    BuildTextCallback? buildText,
    TextStyle? textStyle,
    TextTheme? textTheme,
    TextStyle? overrodeTextStyle,
  }) : _parser = Parser(
          context,
          html,
          onTapLink: onTapLink,
          onTapText: onTapText,
          onText: onText,
          isParsingTextRecursively: isParsingTextRecursively,
          onTags: onTags,
          onImage: onImage,
          buildText: buildText,
          textStyle: textStyle,
          textTheme: textTheme,
          overrodeTextStyle: overrodeTextStyle,
        );

  TextSpan toTextSpan() {
    final spans = _parser.parse();
    if (spans.isEmpty) {
      return const TextSpan();
    }

    return TextSpan(children: spans);
  }

  RichText toRichText({StrutStyle? strutStyle}) =>
      RichText(text: toTextSpan(), strutStyle: strutStyle);

  void dispose() => _parser.dispose();
}

TextSpan htmlToTextSpan(
  BuildContext context,
  String html, {
  OnTextCallback? onText,
  bool isParsingTextRecursively = false,
  Map<String, OnTagCallback>? onTags,
  OnImageCallback? onImage,
  BuildTextCallback? buildText,
  TextStyle? textStyle,
  TextTheme? textTheme,
  TextStyle? overrodeTextStyle,
}) {
  final parser = Parser(
    context,
    html,
    onText: onText,
    isParsingTextRecursively: isParsingTextRecursively,
    onTags: onTags,
    onImage: onImage,
    buildText: buildText,
    textStyle: textStyle,
    textTheme: textTheme,
    overrodeTextStyle: overrodeTextStyle,
  );

  final spans = parser.parse();
  if (spans.isEmpty) {
    return const TextSpan();
  }

  return TextSpan(children: spans);
}

RichText htmlToRichText(
  BuildContext context,
  String html, {
  OnTextCallback? onText,
  bool isParsingTextRecursively = false,
  Map<String, OnTagCallback>? onTags,
  OnImageCallback? onImage,
  BuildTextCallback? buildText,
  TextStyle? textStyle,
  TextTheme? textTheme,
  TextStyle? overrodeTextStyle,
  StrutStyle? strutStyle,
}) =>
    RichText(
      text: htmlToTextSpan(
        context,
        html,
        onText: onText,
        isParsingTextRecursively: isParsingTextRecursively,
        onTags: onTags,
        onImage: onImage,
        buildText: buildText,
        textStyle: textStyle,
        textTheme: textTheme,
        overrodeTextStyle: overrodeTextStyle,
      ),
      strutStyle: strutStyle,
    );
