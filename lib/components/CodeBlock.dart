import 'package:flutter/material.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';

class CodeBlock extends StatelessWidget {
  final String codeContent;
  final String? language;
  final bool isDarkMode;
  const CodeBlock({
    required this.codeContent,
    this.language,
    this.isDarkMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode
              ? atomOneDarkTheme['root']?.backgroundColor
              : atomOneLightTheme['root']?.backgroundColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: HighlightView(
          codeContent,
          language: language ?? 'dart',
          theme: isDarkMode ? atomOneDarkTheme : atomOneLightTheme,
          textStyle: const TextStyle(
            fontFamily: 'JetBrainsMonoNL',
            fontSize: 14.0,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
