import 'package:flutter/material.dart';
import 'package:markdown_notes/components/code_block.dart';
import 'package:markdown_notes/components/markdown_view.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/theme.dart';

class FileScreen extends StatefulWidget {
  final String data;
  final String filePath;
  const FileScreen({required this.filePath, required this.data, super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;
    final language = widget.filePath.split('.').last;
    final fileName = widget.filePath.split('/').last;
    final isMarkdown = language == 'md' || language == 'markdown';
    final conditionBg = isMarkdown
        ? AppTheme.from(brightness).background
        : (isDarkMode ? codeBlockDarkTheme : codeBlockLightTheme)['root']!
              .backgroundColor!;

    return Scaffold(
      backgroundColor: conditionBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(backgroundColor: conditionBg, title: Text(fileName)),
            SliverToBoxAdapter(
              child: !isMarkdown
                  ? CodeBlock(
                      codeContent: widget.data,
                      isDarkMode: isDarkMode,
                      language: language,
                      isFullSize: true,
                    )
                  : MarkdownView(
                      data: widget.data,
                      onLinkTap: (s) {},
                      preAnchor: null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
