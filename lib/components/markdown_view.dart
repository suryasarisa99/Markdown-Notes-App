import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/settings/markdown_settings.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_notes/utils/anchor_service.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownView extends StatefulWidget {
  final String data;
  final Function(String)? onLinkTap;
  final String? preAnchor;

  const MarkdownView({
    required this.data,
    required this.onLinkTap,
    this.preAnchor,
    super.key,
  });

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final AnchorService anchorService = AnchorService();

  @override
  void initState() {
    super.initState();
    log("MarkdownView initialized with preAnchor: ${widget.preAnchor}");
    // If preAnchor is provided, scroll to it after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preAnchor != null) {
        log(">>>>>>>>>>> Scrolling to pre-anchor: ${widget.preAnchor!}");
        anchorService.scrollToAnchor(widget.preAnchor!);
      }
    });
  }

  // widget update
  @override
  void didUpdateWidget(covariant MarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    log("MarkdownView updated with preAnchor: ${widget.preAnchor}");
    // If preAnchor is changed (replace current page data ), scroll to it after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preAnchor != null && widget.preAnchor != oldWidget.preAnchor) {
        anchorService.scrollToAnchor(widget.preAnchor!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    anchorService.clearAnchors();
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
        data: widget.data,
        config: config.copy(
          configs: [
            preConfig.copy(
              decoration: BoxDecoration(
                color: codeBlockTheme['root']?.backgroundColor,
                borderRadius: BorderRadius.circular(6.0),
              ),
              theme: codeBlockTheme,
              textStyle: TextStyle(fontSize: MdSettings.codeBlockFontSize),
            ),
            HrConfig(
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            TableConfig(
              border: TableBorder.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
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
              onBuild: anchorService.addAnchorKey,
              style: TextStyle(
                color: theme.markdownColors.h1,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            H2Config(
              onBuild: anchorService.addAnchorKey,
              style: TextStyle(color: theme.markdownColors.h2, fontSize: 25),
            ),
            H3Config(
              onBuild: anchorService.addAnchorKey,
              style: TextStyle(
                color: theme.markdownColors.h3,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            H4Config(
              onBuild: anchorService.addAnchorKey,
              style: TextStyle(
                color: theme.markdownColors.h4,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            H5Config(
              onBuild: anchorService.addAnchorKey,
              style: TextStyle(color: theme.markdownColors.h5, fontSize: 18),
            ),
            H6Config(
              onBuild: anchorService.addAnchorKey,
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
              // onTap: widget.onLinkTap,
              onTap: (url) async {
                if (url.startsWith("http") || url.startsWith("www")) {
                  // on external links
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    log("Opening URL: $url");
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    log("Cannot launch URL: $url");
                  }
                } else if (url.startsWith('#')) {
                  // markdown current page navigation
                  final anchor = url.substring(1);
                  log("scrolling to anchor: $url");
                  anchorService.scrollToAnchor(anchor);
                } else {
                  // markdown another notes page
                  widget.onLinkTap?.call(url);
                }
              },
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
