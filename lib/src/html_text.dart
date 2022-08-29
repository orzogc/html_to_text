import 'package:flutter/material.dart';

import 'parser.dart';

typedef OnLinkTap = void Function(BuildContext context, String link);

typedef OnText = String? Function(BuildContext context, String text);

class HtmlText {
  final Parser _parser;

  BuildContext get context => _parser.context;

  String get html => _parser.html;

  OnLinkTap? get onLinkTap => _parser.onLinkTap;

  OnText? get onText => _parser.onText;

  TextStyle? get textStyle => _parser.textStyle;

  TextTheme? get textTheme => _parser.textTheme;

  HtmlText(
    BuildContext context,
    String html, {
    OnLinkTap? onLinkTap,
    OnText? onText,
    TextStyle? textStyle,
    TextTheme? textTheme,
  }) : _parser = Parser(
          context,
          html,
          onLinkTap: onLinkTap,
          onText: onText,
          textStyle: textStyle,
          textTheme: textTheme,
        );

  TextSpan toTextSpan() {
    final spans = _parser.parse();
    if (spans.isEmpty) {
      return const TextSpan(text: '');
    }

    return TextSpan(children: spans);
  }

  RichText toRichText() => RichText(text: toTextSpan());

  void dispose() {
    _parser.dispose();
  }
}

TextSpan htmlToTextSpan(
  BuildContext context,
  String html, {
  OnText? onText,
  TextStyle? textStyle,
  TextTheme? textTheme,
}) {
  final parser = Parser(
    context,
    html,
    onText: onText,
    textStyle: textStyle,
    textTheme: textTheme,
  );
  final spans = parser.parse();
  if (spans.isEmpty) {
    return const TextSpan(text: '');
  }

  return TextSpan(children: spans);
}

RichText htmlToRichText(
  BuildContext context,
  String html, {
  OnText? onText,
  TextStyle? textStyle,
  TextTheme? textTheme,
}) =>
    RichText(
      text: htmlToTextSpan(
        context,
        html,
        onText: onText,
        textStyle: textStyle,
        textTheme: textTheme,
      ),
    );
