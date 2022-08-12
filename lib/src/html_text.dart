import 'package:flutter/material.dart';

import 'parser.dart';

typedef OnLinkTap = void Function(String link);

class HtmlText {
  final Parser _parser;

  HtmlText(BuildContext context, String html, {OnLinkTap? onLinkTap})
      : _parser = Parser(context, html, onLinkTap: onLinkTap);

  TextSpan toTextSpan() {
    if (_parser.html.isEmpty) {
      return const TextSpan();
    }

    final spans = _parser.parse();
    if (spans.isEmpty) {
      return const TextSpan();
    }

    return TextSpan(text: '', children: spans);
  }

  RichText toRichText() => RichText(text: toTextSpan());

  void dispose() {
    _parser.dispose();
  }
}

TextSpan htmlToTextSpan(BuildContext context, String html) {
  if (html.isEmpty) {
    return const TextSpan();
  }

  final parser = Parser(context, html);
  final spans = parser.parse();
  if (spans.isEmpty) {
    return const TextSpan();
  }

  return TextSpan(text: '', children: spans);
}

RichText htmlToRichText(BuildContext context, String html) =>
    RichText(text: htmlToTextSpan(context, html));
