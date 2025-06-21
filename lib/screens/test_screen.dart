import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_widget/markdown_widget.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String data = "";
  // late FileNode projectNode = widget.projectNode;
  // late FileNode? curFileNode = widget.curFileNode;
  bool isMarkdownFile = true;
  String _htmlText = '';
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _anchorKeys = {};
  final Map<String, int> _anchorCounts = {};
  final Map<String, int> _renderedAnchorCounts = {};
  final focusNode = FocusNode();
  final mainFocusScope = FocusScopeNode();

  void _pickFile() {
    FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false)
        .then((result) {
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;
            final text = File(file.path!).readAsStringSync();
            setState(() {
              data = text;
            });
          }
        });
  }

  // Generates anchor keys from the HTML headings.
  void _generateAnchorKeys(String html) {
    _anchorKeys.clear();
    _anchorCounts.clear();
    final headingRegExp = RegExp(
      r'<h[1-6][^>]*>(.*?)<\/h[1-6]>',
      caseSensitive: false,
    );
    for (final match in headingRegExp.allMatches(html)) {
      String text = match.group(1) ?? '';
      String baseAnchor = _normalizeAnchor(text);
      int count = (_anchorCounts[baseAnchor] ?? 0);
      String anchor = count == 0 ? baseAnchor : '$baseAnchor-$count';
      _anchorCounts[baseAnchor] = count + 1;
      log("created anchor: $text => $anchor");
      _anchorKeys[anchor] = GlobalKey();
    }
  }

  String _getAnchorForHeading(String text) {
    String baseAnchor = _normalizeAnchor(text);
    int count = (_renderedAnchorCounts[baseAnchor] ?? 0);
    String anchor = count == 0 ? baseAnchor : '$baseAnchor-$count';
    log("get anchor: $text => $anchor");
    _renderedAnchorCounts[baseAnchor] = count + 1;
    return anchor;
  }

  // heading text to anchor(link) conversion.
  String _normalizeAnchor(String text) {
    // VS Code style: lowercase, remove special chars, replace spaces with dashes
    String anchor = text
        .trim()
        .toLowerCase()
        .replaceAll('<code>', '')
        .replaceAll('</code>', '');
    anchor = anchor.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    anchor = anchor.replaceAll(RegExp(r'\s+'), '-');
    // log("normalized anchor: $text => $anchor");
    return anchor;
  }

  void _scrollToAnchor(String anchor) {
    final key = _anchorKeys[anchor];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        // duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;
    final theme = AppTheme.from(brightness);
    final config = isDarkMode
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Column(
        children: [
          const Text('This is a test screen.'),
          ElevatedButton(
            onPressed: () {
              _pickFile();
            },
            child: const Text('Go Back'),
          ),
          if (data.isNotEmpty)
            Expanded(
              child: MarkdownWidget(
                data: data,
                config: config.copy(
                  configs: [
                    H1Config(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LinkConfig(
                      onBuild: (link) {
                        log("Link built: $link");
                      },
                      onTap: (link) {
                        log("Link tapped: $link");
                      },
                      style: TextStyle(
                        color: isDarkMode ? Colors.blueAccent : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
