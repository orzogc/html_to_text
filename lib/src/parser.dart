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

  Object styleOrSpan(
    BuildContext context,
    TextStyle textStyle,
    TextTheme textTheme,
  ) {
    for (final tag in tags) {
      if (tag.onTagSpan != null) {
        return tag.onTagSpan!;
      }

      textStyle = tag.style(textStyle, textTheme);
    }

    return textStyle;
  }
}

class Visitor extends TreeVisitor {
  final BuildContext context;

  final List<Tag>? parentTags;

  final OnTextCallback? onText;

  final bool onTextRecursiveParse;

  final Map<String, OnTagCallback>? onTags;

  final TextStyle textStyle;

  final TextTheme textTheme;

  Visitor(this.context,
      {this.parentTags,
      this.onText,
      this.onTextRecursiveParse = false,
      this.onTags,
      required this.textStyle,
      required this.textTheme});

  List<Tag> tags = [];

  final List<Span> spans = [];

  @override
  void visitChildren(Node node) {
    if (node is Element) {
      final tagName = node.localName;

      _addNewline(tagName);
    }

    for (final child in node.nodes) {
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
      final text = onText!(context, htmlSerializeEscape(node.text));
      if (text != null) {
        if (onTextRecursiveParse) {
          try {
            final parsed = HtmlParser(text).parseFragment();
            final visitor = Visitor(context,
                parentTags: [...?parentTags, ...tags],
                onTags: onTags,
                textStyle: textStyle,
                textTheme: textTheme)
              ..visit(parsed);
            spans.addAll(visitor.spans);
          } catch (e) {
            debugPrint('fails to parse text which onText returned: $e');
            spans.add(Span([...?parentTags, ...tags], text));
          }
        } else {
          spans.add(Span([...?parentTags, ...tags], text));
        }
      } else {
        spans.add(Span([...?parentTags, ...tags], node.text));
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
          for (final style in value
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

    for (final style in lastStyles) {
      tag.addStyle(style);
    }

    tags.add(tag);

    if ((onTags?.containsKey(tag.tagName) ?? false)) {
      final styleOrSpan = Span([...?parentTags, ...tags], '')
          .styleOrSpan(context, textStyle, textTheme);
      if (styleOrSpan is TextStyle) {
        final span = onTags![tag.tagName]!(context, node, styleOrSpan);
        if (span != null) {
          tags.last.onTagSpan = span;
          spans.add(Span([...?parentTags, ...tags], ''));
          return;
        }
      } else {
        debugPrint('styleOrSpan should be TextStyle');
      }
    }

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

  final OnLinkTapCallback? onLinkTap;

  final OnTextCallback? onText;

  final bool onTextRecursiveParse;

  final Map<String, OnTagCallback>? onTags;

  final BuildTextCallback? buildText;

  final TextStyle? textStyle;

  final TextTheme? textTheme;

  final TextStyle? overrideTextStyle;

  final List<TapGestureRecognizer> _recognizers = [];

  Parser(this.context, this.html,
      {this.onLinkTap,
      this.onText,
      this.onTextRecursiveParse = false,
      this.onTags,
      this.buildText,
      this.textStyle,
      this.textTheme,
      this.overrideTextStyle});

  List<InlineSpan> parse() {
    if (html.isEmpty) {
      return [];
    }

    final textStyle = DefaultTextStyle.of(context).style.merge(this.textStyle);
    final textTheme = Theme.of(context).textTheme.merge(this.textTheme);

    final content =
        html.replaceAllMapped(RegExp('(\r\n)|(\n)|(\t)'), (_) => '');

    try {
      final parsed = HtmlParser(content).parseFragment();
      final visitor = Visitor(context,
          onText: onText,
          onTextRecursiveParse: onTextRecursiveParse,
          onTags: onTags,
          textStyle: textStyle,
          textTheme: textTheme)
        ..visit(parsed)
        ..mergeNewlines()
        ..removeLastNewLines();

      return visitor.spans.map((span) {
        final styleOrSpan = span.styleOrSpan(context, textStyle, textTheme);

        if (styleOrSpan is TextStyle) {
          if (onLinkTap != null && span.link != null) {
            final recognizer = TapGestureRecognizer()
              ..onTap = () => onLinkTap!(context, span.link!);
            _recognizers.add(recognizer);

            if (buildText != null) {
              return TextSpan(children: [
                buildText!(context, span.text, styleOrSpan, span.link)
              ], recognizer: recognizer);
            }

            return TextSpan(
                text: span.text,
                style: styleOrSpan.merge(overrideTextStyle),
                recognizer: recognizer);
          }

          if (buildText != null) {
            return buildText!(context, span.text, styleOrSpan, span.link);
          }

          return TextSpan(
              text: span.text, style: styleOrSpan.merge(overrideTextStyle));
        } else if (styleOrSpan is InlineSpan) {
          return styleOrSpan;
        } else {
          debugPrint('unknown span: $styleOrSpan');
          return const TextSpan();
        }
      }).toList();
    } catch (e) {
      debugPrint('fails to parse html: $e');
      return [TextSpan(text: html, style: textStyle)];
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
    case 'li':
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
