import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/settings/markdown_settings.dart';

class CodeBlock extends StatelessWidget {
  final String codeContent;
  final String? language;
  final bool isDarkMode;
  final bool isFullSize;
  const CodeBlock({
    required this.codeContent,
    this.language,
    this.isDarkMode = false,
    this.isFullSize = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? codeBlockDarkTheme : codeBlockLightTheme;
    return Container(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
      decoration: BoxDecoration(
        color: theme['root']?.backgroundColor,
        borderRadius: BorderRadius.circular(6.0),
        border: !isFullSize
            ? Border.all(color: const Color(0x13000000), width: 1.0)
            : null,
        boxShadow: !isFullSize
            ? [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.08),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          codeContent,
          language: language,
          theme: theme,
          textStyle: TextStyle(
            fontSize: MdSettings.codePageFontSize,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
