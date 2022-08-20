import 'package:flutter/material.dart';

import 'parser.dart';

typedef OnLinkTap = void Function(BuildContext context, String link);

typedef OnText = String? Function(BuildContext context, String text);

class HtmlText {
  final BuildContext context;

  final String html;

  final OnLinkTap? onLinkTap;

  final OnText? onText;

  final Parser _parser;

  HtmlText(this.context, this.html, {this.onLinkTap, this.onText})
      : _parser = Parser(context, html, onLinkTap: onLinkTap, onText: onText);

  TextSpan toTextSpan() {
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

TextSpan htmlToTextSpan(BuildContext context, String html, {OnText? onText}) {
  final parser = Parser(context, html, onText: onText);
  final spans = parser.parse();
  if (spans.isEmpty) {
    return const TextSpan();
  }

  return TextSpan(text: '', children: spans);
}

RichText htmlToRichText(BuildContext context, String html, {OnText? onText}) =>
    RichText(text: htmlToTextSpan(context, html, onText: onText));
