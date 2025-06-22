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
  final tocController = TocController();

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
      // log("created anchor: $text => $anchor");
      _anchorKeys[anchor] = GlobalKey();
    }
  }

  Key _addAnchorKey(String text) {
    String baseAnchor = _normalizeAnchor(text);
    int count = (_anchorCounts[baseAnchor] ?? 0);
    String anchor = count == 0 ? baseAnchor : '$baseAnchor-$count';
    _anchorCounts[baseAnchor] = count + 1;
    log("created anchor: $text => $anchor");
    _anchorKeys[anchor] = GlobalKey();
    return _anchorKeys[anchor]!;
  }

  String _getAnchorForHeading(String text) {
    String baseAnchor = _normalizeAnchor(text);
    int count = (_renderedAnchorCounts[baseAnchor] ?? 0);
    String anchor = count == 0 ? baseAnchor : '$baseAnchor-$count';
    // log("get anchor: $text => $anchor");
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
    if (key != null) {
      if (key.currentContext == null) {
        log(
          "Anchor key context is null for: $anchor, state: ${key.currentState}",
        );
        return;
      }
      Scrollable.ensureVisible(
        key.currentContext!,
        // duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      log("Anchor not found: $anchor");
      log("Available anchors: ${_anchorKeys.keys.join(', ')}");
    }
  }

  Key? onBuild(String text) {
    return _addAnchorKey(text);
    // final anchor = _getAnchorForHeading(text);
    // final key = _anchorKeys[anchor];
    // log("onBuild called for: $text, anchor: $anchor, key: $key");
    // return key;
  }

  @override
  Widget build(BuildContext context) {
    log("Only build once");
    final brightness = Theme.brightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;
    final theme = AppTheme.from(brightness);
    final config = isDarkMode
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    // clear keys and counts
    _anchorKeys.clear();
    _anchorCounts.clear();
    return Scaffold(
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
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: MarkdownWidget(
                      data: data,
                      tocController: tocController,
                      config: config.copy(
                        configs: [
                          H1Config(onBuild: onBuild),
                          H2Config(onBuild: onBuild),
                          H3Config(onBuild: onBuild),
                          H4Config(onBuild: onBuild),
                          H5Config(onBuild: onBuild),
                          H6Config(onBuild: onBuild),

                          LinkConfig(
                            onBuild: (link) {
                              // log("Link built: $link");
                              // _addAnchorKey(link);
                            },
                            onTap: (link) {
                              log("Link tapped: $link");
                              _scrollToAnchor(link.substring(1));
                            },
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.blueAccent
                                  : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
