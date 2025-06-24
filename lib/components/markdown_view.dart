import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/container/blockquote.dart';
import 'package:markdown_widget/widget/blocks/container/list.dart';
import 'package:markdown_widget/widget/blocks/container/table.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/blocks/leaf/heading.dart';
import 'package:markdown_widget/widget/blocks/leaf/link.dart';
import 'package:markdown_widget/widget/inlines/code.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownView extends StatelessWidget {
  final String data;
  final Key? Function(String)? onBuild;
  final Function(String)? onLinkTap;

  const MarkdownView({
    required this.data,
    required this.onBuild,
    required this.onLinkTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final theme = AppTheme.from(brightness);
    final isDarkMode = brightness == Brightness.dark;
    final config = isDarkMode
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    final preConfig = isDarkMode ? PreConfig.darkConfig : PreConfig();
    final codeBlockTheme = isDarkMode
        ? codeBlockDarkTheme
        : codeBlockLightTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: MarkdownWidget(
        data: data,
        config: config.copy(
          configs: [
            preConfig.copy(
              decoration: BoxDecoration(
                color: codeBlockTheme['root']?.backgroundColor,
                borderRadius: BorderRadius.circular(6.0),
              ),
              theme: codeBlockTheme,
            ),
            TableConfig(
              border: TableBorder.all(
                color: Colors.red,
                width: 1.0,
                borderRadius: BorderRadius.circular(6),
              ),
              headerRowDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: codeBlockTheme['tableHeader']?.backgroundColor,
              ),
              wrapper: (table) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              ),
            ),
            H1Config(
              onBuild: onBuild,
              style: TextStyle(
                color: theme.markdownColors.h1,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            H2Config(
              onBuild: onBuild,
              style: TextStyle(color: theme.markdownColors.h2, fontSize: 25),
            ),
            H3Config(
              onBuild: onBuild,
              style: TextStyle(
                color: theme.markdownColors.h3,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            H4Config(
              onBuild: onBuild,
              style: TextStyle(
                color: theme.markdownColors.h4,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            H5Config(
              onBuild: onBuild,
              style: TextStyle(color: theme.markdownColors.h5, fontSize: 18),
            ),
            H6Config(
              onBuild: onBuild,
              style: TextStyle(color: theme.markdownColors.h6, fontSize: 16),
            ),
            ListConfig(marginLeft: 24),
            ListConfig(),
            BlockquoteConfig(padding: EdgeInsets.symmetric(horizontal: 30)),
            CodeConfig(
              style: TextStyle(
                backgroundColor: theme.markdownColors.inlineCodeBg,
                color: theme.markdownColors.inlineCodeTxt,
              ),
            ),
            LinkConfig(
              onBuild: (link) {
                // log("Link built: $link");
                // _addAnchorKey(link);
              },
              onTap: onLinkTap,
              style: TextStyle(
                color: isDarkMode ? Colors.blueAccent : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
