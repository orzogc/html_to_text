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
    for (var tag in tags) {
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
  List<Tag> tags = [];

  final List<Span> spans = [];

  @override
  void visitChildren(Node node) {
    if (node is Element) {
      final tagName = node.localName;

      _addNewline(tagName);
    }

    for (var child in node.nodes) {
      final parentTags = [...tags];
      visit(child);
      tags = parentTags;
    }

    if (node is Element) {
      final tagName = node.localName;

      if (tagName == 'br') {
        spans.add(Span([...tags], '\n')..isBr = true);
      } else {
        _addNewline(tagName);
      }
    }
  }

  @override
  void visitText(Text node) {
    spans.add(Span([...tags], node.text));

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
      spans.add(Span([...tags], '\n'));
    } else if (_shouldAddTwoNewLines(tagName)) {
      spans.add(Span([...tags], '\n\n'));
    }
  }

  /// merge new lines
  void _mergeNewlines() {
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
  void _removeLastNewLines() {
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

  final List<TapGestureRecognizer> _recognizers = [];

  Parser(this.context, this.html, {this.onLinkTap});

  List<TextSpan> parse() {
    if (html.isEmpty) {
      return [];
    }

    final textStyle = DefaultTextStyle.of(context).style;
    final textTheme = Theme.of(context).textTheme;

    var content = html.replaceAll('\r\n', '');
    content = content.replaceAll('\n', '');

    try {
      final htmlParser = HtmlParser(content);
      final parsed = htmlParser.parseFragment();
      final visitor = Visitor()
        ..visit(parsed)
        .._mergeNewlines()
        .._removeLastNewLines();

      return visitor.spans.map((span) {
        if (onLinkTap != null && span.link != null) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () => onLinkTap!(span.link!);
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
