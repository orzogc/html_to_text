import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Element, Text;
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html/dom_parsing.dart';

import 'style.dart';
import 'tag.dart';
import 'html_text.dart';

class Span {
  final List<Tag> tags;

  String text;

  bool isBr = false;

  String? link;

  Span(this.tags, this.text) {
    for (final tag in tags) {
      if (tag.link != null) {
        link = tag.link;
      }
    }
  }

  TextStyle style(TextStyle textStyle, TextTheme textTheme) {
    for (final tag in tags) {
      textStyle = tag.style(textStyle, textTheme);
    }

    return textStyle;
  }
}

class Visitor extends TreeVisitor {
  final BuildContext context;

  final List<Tag>? parentTags;

  final OnText? onText;

  Visitor(this.context, {this.parentTags, this.onText});

  List<Tag> tags = [];

  final List<Span> spans = [];

  @override
  void visitChildren(Node node) {
    if (node is Element) {
      final tagName = node.localName;

      _addNewline(tagName);
    }

    for (var child in node.nodes) {
      final parentTags_ = [...tags];
      visit(child);
      tags = parentTags_;
    }

    if (node is Element) {
      final tagName = node.localName;

      if (tagName == 'br') {
        spans.add(Span([...?parentTags, ...tags], '\n')..isBr = true);
      } else {
        _addNewline(tagName);
      }
    }
  }

  @override
  void visitText(Text node) {
    if (onText == null) {
      spans.add(Span([...?parentTags, ...tags], node.text));
    } else {
      final text = onText!(context, node.text);
      if (text != null) {
        try {
          final htmlParser = HtmlParser(text);
          final parsed = htmlParser.parseFragment();
          final visitor =
              Visitor(context, parentTags: [...?parentTags, ...tags])
                ..visit(parsed);
          spans.addAll(visitor.spans);
        } catch (e) {
          debugPrint('fails to parse text which onText returned: $e');
        }
      }
    }

    super.visitText(node);
  }

  @override
  void visitElement(Element node) {
    final tag = Tag(node.localName);
    final lastStyles = <Style>[];

    // add the link
    if (tag.tagName == 'a') {
      tag.link = node.attributes['href'];
    }

    // parse the legacy font tag
    if (tag.tagName == 'font') {
      node.attributes.forEach((attribute, value) {
        if (attribute is String) {
          switch (attribute) {
            case 'color':
              tag.addStyle(ColorStyle(value));
              break;
            case 'face':
              tag.addStyle(FontFamilyStyle(value));
              break;
            default:
              // size attribute is not supported
              debugPrint('unsupported font tag attribute: $attribute');
          }
        } else {
          debugPrint('AttributeName: $attribute');
        }
      });
    }

    node.attributes.forEach((attribute, value) {
      if (attribute is String) {
        attribute = attribute.trim();
        value = value.trim();

        if (attribute == 'style') {
          for (var style in value
              .split(';')
              .map((style) => style.trim())
              .where((style) => style.isNotEmpty)) {
            final css = style.split(':').map((css) => css.trim()).toList();

            if (css.length == 2) {
              switch (css[0]) {
                case 'color':
                  tag.addStyle(ColorStyle(css[1]));
                  break;
                case 'background-color':
                  tag.addStyle(BackgroundColorStyle(css[1]));
                  break;
                case 'font-weight':
                  tag.addStyle(FontWeightStyle(css[1]));
                  break;
                case 'font-style':
                  tag.addStyle(FontSlantStyle(css[1]));
                  break;
                case 'font-size':
                  tag.addStyle(FontSizeStyle(css[1]));
                  break;
                case 'font-family':
                  tag.addStyle(FontFamilyStyle(css[1]));
                  break;
                case 'text-decoration':
                case 'text-decoration-color':
                case 'text-decoration-line':
                case 'text-decoration-style':
                  tag.addStyle(DecorationStyle(css[1]));
                  break;
                case 'line-height':
                  lastStyles.add(LineHeightStyle(css[1]));
                  break;
                default:
                  debugPrint('unsupported css style: $style');
              }
            } else {
              debugPrint('invalid css style: $style');
            }
          }
        }
      } else {
        debugPrint('AttributeName: $attribute');
      }
    });

    for (var style in lastStyles) {
      tag.addStyle(style);
    }

    tags.add(tag);

    super.visitElement(node);
  }

  void _addNewline(String? tagName) {
    if (_shouldAddOneNewLine(tagName)) {
      spans.add(Span([...?parentTags, ...tags], '\n'));
    } else if (_shouldAddTwoNewLines(tagName)) {
      spans.add(Span([...?parentTags, ...tags], '\n\n'));
    }
  }

  /// merge new lines
  void mergeNewlines() {
    final filter = <int>[];
    var num = -1;
    spans.asMap().forEach((index, span) {
      if (index > num && (span.text == '\n' || span.text == '\n\n')) {
        num = index;
        var hasNewline = false;
        for (var nextIndex = index + 1; nextIndex < spans.length; nextIndex++) {
          final text = spans[nextIndex].text;
          if (spans[nextIndex].isBr) {
            if (span.text == '\n\n') {
              span.text = '\n';
            } else if (!span.isBr && span.text == '\n') {
              filter.add(index);
            }
            num = nextIndex - 1;
            return;
          }
          if (text != '\n' && text != '\n\n') {
            num = nextIndex;
            return;
          }
          if (span.text == '\n\n') {
            filter.add(nextIndex);
            continue;
          }
          if (text == '\n') {
            filter.add(nextIndex);
            continue;
          }
          if (text == '\n\n') {
            if (span.isBr) {
              if (hasNewline) {
                filter.add(nextIndex);
              } else {
                spans[nextIndex].text = '\n';
                hasNewline = true;
              }
              continue;
            } else {
              filter.add(index);
              num = nextIndex - 1;
              return;
            }
          }
        }
        num = spans.length - 1;
      }
    });
    filter.sort();
    for (final index in filter.reversed) {
      spans.removeAt(index);
    }
  }

  /// remove extar new lines at the last
  void removeLastNewLines() {
    while (true) {
      if (spans.isNotEmpty) {
        final span = spans.last;
        // don't remove br's new line
        if (!span.isBr && (span.text == '\n' || span.text == '\n\n')) {
          spans.removeLast();
        } else {
          break;
        }
      } else {
        break;
      }
    }
  }
}

class Parser {
  final BuildContext context;

  final String html;

  final OnLinkTap? onLinkTap;

  final OnText? onText;

  final TextStyle? textStyle;

  final TextTheme? textTheme;

  final List<TapGestureRecognizer> _recognizers = [];

  Parser(this.context, this.html,
      {this.onLinkTap, this.onText, this.textStyle, this.textTheme});

  List<TextSpan> parse() {
    if (html.isEmpty) {
      return [];
    }

    final textStyle = this.textStyle ?? DefaultTextStyle.of(context).style;
    final textTheme = this.textTheme ?? Theme.of(context).textTheme;

    final content = html.replaceAllMapped(RegExp('(\r\n)|(\n)'), (_) => '');

    try {
      final htmlParser = HtmlParser(content);
      final parsed = htmlParser.parseFragment();
      final visitor = Visitor(context, onText: onText)
        ..visit(parsed)
        ..mergeNewlines()
        ..removeLastNewLines();

      return visitor.spans.map((span) {
        if (onLinkTap != null && span.link != null) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () => onLinkTap!(context, span.link!);
          _recognizers.add(recognizer);
          return TextSpan(
              text: span.text,
              style: span.style(textStyle, textTheme),
              recognizer: recognizer);
        }
        return TextSpan(
            text: span.text, style: span.style(textStyle, textTheme));
      }).toList();
    } catch (e) {
      debugPrint('fails to parse html: $e');
      return [];
    }
  }

  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
  }
}

bool _shouldAddOneNewLine(String? tagName) {
  switch (tagName) {
    case 'div':
      return true;
    default:
      return false;
  }
}

bool _shouldAddTwoNewLines(String? tagName) {
  switch (tagName) {
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
    case 'p':
      return true;
    default:
      return false;
  }
}
