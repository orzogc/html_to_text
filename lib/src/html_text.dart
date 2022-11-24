import 'package:flutter/material.dart' hide Element;
import 'package:html/dom.dart';

import 'parser.dart';

typedef OnLinkTapCallback = void Function(
    BuildContext context, String link, String text);

typedef OnTextTapCallback = void Function(BuildContext context, String text);

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

  OnLinkTapCallback? get onLinkTap => _parser.onLinkTap;

  OnTextCallback? get onText => _parser.onText;

  bool get onTextRecursiveParse => _parser.onTextRecursiveParse;

  Map<String, OnTagCallback>? get onTags => _parser.onTags;

  OnImageCallback? get onImage => _parser.onImage;

  BuildTextCallback? get buildText => _parser.buildText;

  TextStyle? get textStyle => _parser.textStyle;

  TextTheme? get textTheme => _parser.textTheme;

  TextStyle? get overrideTextStyle => _parser.overrideTextStyle;

  HtmlText(
    BuildContext context,
    String html, {
    OnLinkTapCallback? onLinkTap,
    OnTextTapCallback? onTextTap,
    OnTextCallback? onText,
    bool onTextRecursiveParse = false,
    Map<String, OnTagCallback>? onTags,
    OnImageCallback? onImage,
    BuildTextCallback? buildText,
    TextStyle? textStyle,
    TextTheme? textTheme,
    TextStyle? overrideTextStyle,
  }) : _parser = Parser(
          context,
          html,
          onLinkTap: onLinkTap,
          onTextTap: onTextTap,
          onText: onText,
          onTextRecursiveParse: onTextRecursiveParse,
          onTags: onTags,
          onImage: onImage,
          buildText: buildText,
          textStyle: textStyle,
          textTheme: textTheme,
          overrideTextStyle: overrideTextStyle,
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
  bool onTextRecursiveParse = false,
  Map<String, OnTagCallback>? onTags,
  OnImageCallback? onImage,
  BuildTextCallback? buildText,
  TextStyle? textStyle,
  TextTheme? textTheme,
  TextStyle? overrideTextStyle,
}) {
  final parser = Parser(
    context,
    html,
    onText: onText,
    onTextRecursiveParse: onTextRecursiveParse,
    onTags: onTags,
    onImage: onImage,
    buildText: buildText,
    textStyle: textStyle,
    textTheme: textTheme,
    overrideTextStyle: overrideTextStyle,
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
  bool onTextRecursiveParse = false,
  Map<String, OnTagCallback>? onTags,
  OnImageCallback? onImage,
  BuildTextCallback? buildText,
  TextStyle? textStyle,
  TextTheme? textTheme,
  TextStyle? overrideTextStyle,
  StrutStyle? strutStyle,
}) =>
    RichText(
      text: htmlToTextSpan(
        context,
        html,
        onText: onText,
        onTextRecursiveParse: onTextRecursiveParse,
        onTags: onTags,
        onImage: onImage,
        buildText: buildText,
        textStyle: textStyle,
        textTheme: textTheme,
        overrideTextStyle: overrideTextStyle,
      ),
      strutStyle: strutStyle,
    );
