import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;

import '../widget/blocks/leaf/heading.dart';
import '../widget/span_node.dart';
import '../widget/widget_visitor.dart';
import 'configs.dart';
import 'toc.dart';

typedef HeadingNodeFilter = bool Function(HeadingNode toc);

///use [MarkdownGenerator] to transform markdown data to [Widget] list, so you can render it by any type of [ListView]
class MarkdownGenerator {
  final Iterable<m.InlineSyntax> inlineSyntaxList;
  final Iterable<m.BlockSyntax> blockSyntaxList;
  final EdgeInsets linesMargin;
  final List<SpanNodeGeneratorWithTag> generators;
  final SpanNodeAcceptCallback? onNodeAccepted;
  final m.ExtensionSet? extensionSet;
  final TextNodeGenerator? textGenerator;
  final SpanNodeBuilder? spanNodeBuilder;
  final RichTextBuilder? richTextBuilder;
  final RegExp? splitRegExp;
  final HeadingNodeFilter headingNodeFilter;

  /// Use [headingNodeFilter] to filter the levels of headings you want to show.
  /// e.g.
  /// ```dart
  /// (HeadingNode node) => {'h1', 'h2'}.contains(node.headingConfig.tag)
  /// ```
  MarkdownGenerator(
      {this.inlineSyntaxList = const [],
      this.blockSyntaxList = const [],
      this.linesMargin = const EdgeInsets.symmetric(vertical: 8),
      this.generators = const [],
      this.onNodeAccepted,
      this.extensionSet,
      this.textGenerator,
      this.spanNodeBuilder,
      this.richTextBuilder,
      this.splitRegExp,
      headingNodeFilter})
      : headingNodeFilter = headingNodeFilter ?? allowAll;

  ///convert [data] to widgets
  ///[onTocList] can provider [Toc] list
  List<Widget> buildWidgets(String data,
      {Function(List<Toc>, Map<String, int>)? onTocList,
      MarkdownConfig? config}) {
    final mdConfig = config ?? MarkdownConfig.defaultConfig;
    final m.Document document = m.Document(
      extensionSet: extensionSet ?? m.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      inlineSyntaxes: inlineSyntaxList,
      blockSyntaxes: blockSyntaxList,
    );
    final regExp = splitRegExp ?? WidgetVisitor.defaultSplitRegExp;
    final List<String> lines = data.split(regExp);
    final List<m.Node> nodes = document.parseLines(lines);
    final List<Toc> tocList = [];
    final Map<String, int> anchorToIndexMap = {};
    final visitor = WidgetVisitor(
        config: mdConfig,
        generators: generators,
        textGenerator: textGenerator,
        richTextBuilder: richTextBuilder,
        splitRegExp: regExp,
        onNodeAccepted: (node, index) {
          onNodeAccepted?.call(node, index);
          if (node is HeadingNode && headingNodeFilter(node)) {
            final listLength = tocList.length;
            tocList.add(
                Toc(node: node, widgetIndex: index, selfIndex: listLength));
          }
        });
    final spans = visitor.visit(nodes);
    // Build anchor map after spans are created
    for (var toc in tocList) {
      final headingNode = toc.node;
      // Try to get text from the built span
      final textSpan = headingNode.build();
      String headingText = '';

      if (textSpan is TextSpan) {
        headingText = _extractTextFromTextSpan(textSpan);
      }

      // Fallback to node.getText() if still empty
      if (headingText.isEmpty) {
        headingText = headingNode.getText();
      }

      if (headingText.isNotEmpty) {
        final anchor = normalizeAnchor(headingText);
        anchorToIndexMap[anchor] = toc.widgetIndex;
        log("Created anchor: '$headingText' => '$anchor' at index ${toc.widgetIndex}");
      }
    }

    onTocList?.call(tocList, anchorToIndexMap);
    // onTocList?.call(tocList);
    final List<Widget> widgets = [];
    for (var span in spans) {
      final textSpan = spanNodeBuilder?.call(span) ?? span.build();
      final richText = richTextBuilder?.call(textSpan) ?? Text.rich(textSpan);
      widgets.add(Padding(padding: linesMargin, child: richText));
    }
    return widgets;
  }

  static String normalizeAnchor(String text) {
    String anchor = text
        .trim()
        .toLowerCase()
        .replaceAll('<code>', '')
        .replaceAll('</code>', '');
    anchor = anchor.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    anchor = anchor.replaceAll(RegExp(r'\s+'), '-');
    return anchor;
  }

  static String _extractTextFromTextSpan(TextSpan textSpan) {
    final buffer = StringBuffer();

    // Add the main text
    if (textSpan.text != null) {
      buffer.write(textSpan.text);
    }

    // Recursively extract text from children
    if (textSpan.children != null) {
      for (final child in textSpan.children!) {
        if (child is TextSpan) {
          buffer.write(_extractTextFromTextSpan(child));
        } else if (child is WidgetSpan) {
          // For WidgetSpan, we might not be able to extract text easily
          // You could implement specific logic here if needed
        }
      }
    }

    return buffer.toString();
  }

  static bool allowAll(HeadingNode toc) => true;
}

typedef SpanNodeBuilder = TextSpan Function(SpanNode spanNode);

typedef RichTextBuilder = Widget Function(InlineSpan span);
