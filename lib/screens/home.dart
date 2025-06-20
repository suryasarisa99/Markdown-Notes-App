import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' hide Text;
import 'package:html_unescape/html_unescape.dart';
import 'package:markdown_notes/components/CodeBlock.dart';
import 'package:markdown_notes/components/SideBar.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/screens/file_select_screen.dart';

class HomeScreen extends StatefulWidget {
  final FileNode projectNode;
  const HomeScreen({required this.projectNode, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FileNode projectNode = widget.projectNode;
  late FileNode curFileNode;
  bool? isMarkdownFile;
  String _htmlText = '';
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _anchorKeys = {};
  final Map<String, int> _anchorCounts = {};
  final Map<String, int> _renderedAnchorCounts = {};

  @override
  void initState() {
    super.initState();
  }

  void handleParse(FileNode node) async {
    // read content from fileNode path
    log("path: ${node.path} , name: ${node.name}");
    String text = File(node.path).readAsStringSync();
    if (node.name.endsWith('.md') || node.name.endsWith('.markdown')) {
      setState(() {
        _htmlText = markdownToHtml(
          text,
          extensionSet: ExtensionSet.gitHubFlavored,
        );
        isMarkdownFile = true;
      });
    } else {
      setState(() {
        isMarkdownFile = false;
        _htmlText = text;
      });
    }

    // log(_htmlText);
    _generateAnchorKeys(_htmlText);
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String filePath = result.files.single.path!;
      // Use the file path as needed
      log('Picked file: $filePath');
      // read text from the file
      String text = await File(filePath).readAsString();
      setState(() {
        _htmlText = markdownToHtml(
          text,
          extensionSet: ExtensionSet.gitHubFlavored,
        );
        _generateAnchorKeys(_htmlText);
      });
      // log(fileContent);
    } else {
      // User canceled the picker
      log('No file selected');
    }
  }

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
    _renderedAnchorCounts[baseAnchor] = count + 1;
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

  String _normalizeAnchor(String text) {
    // heading text to link conversion.
    // VS Code style: lowercase, remove special chars, replace spaces with dashes
    String anchor = text.trim().toLowerCase();
    anchor = anchor.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    anchor = anchor.replaceAll(RegExp(r'\s+'), '-');
    log("normalized anchor: $text => $anchor");
    return anchor;
  }

  @override
  Widget build(BuildContext context) {
    _renderedAnchorCounts.clear();
    final currentBrightness = Theme.of(context).brightness;
    final isDarkMode = currentBrightness == Brightness.dark;
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.keyP, LogicalKeyboardKey.meta):
            pickFile,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: scaffoldKey,
          drawer: FileSidebar(
            node: projectNode,
            onDirectoryChange: (node) {
              setState(() {
                projectNode = node;
              });
              scaffoldKey.currentState!.openDrawer();
            },
            onFileTap: (node) {
              context.pop(); // Close the drawer
              log('Tapped file: ${node.path}');
              handleParse(node);
              _scrollController.jumpTo(0);
            },
          ),
          body: SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              // padding: const EdgeInsets.all(10.0),
              // padding: const EdgeInsets.only(left: 12.0, top: 18),
              slivers: [
                SliverAppBar(
                  title: const Text('Markdown Notes'),
                  floating: true,
                  snap: true,
                  backgroundColor: isDarkMode
                      ? const Color.fromARGB(255, 11, 18, 29)
                      : Colors.white,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    // padding: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.only(left: 12.0, top: 18),
                    child: isMarkdownFile == null
                        ? Center(
                            // child: Text(
                            //   'No content available',
                            //   style: TextStyle(fontSize: 18),
                            // ),
                            child: TextButton(
                              onPressed: () {
                                // Scaffold.of(context).openDrawer();
                                scaffoldKey.currentState!.openDrawer();
                              },
                              child: Text("show"),
                            ),
                          )
                        : !isMarkdownFile!
                        ? CodeBlock(
                            codeContent: _htmlText,
                            isDarkMode: isDarkMode,
                            // language: null, // No language for plain text
                          )
                        : Html(
                            data: _htmlText,
                            onAnchorTap: (url, attrs, elm) {
                              if (url != null && url.startsWith('#')) {
                                final anchor = url
                                    .substring(1)
                                    .toLowerCase()
                                    .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
                                    .replaceAll(RegExp(r'\s+'), '-');
                                log("anchor: $anchor");
                                _scrollToAnchor(anchor);
                              }
                            },
                            onLinkTap: (url, attrs, elm) {
                              // handle external links if needed
                            },
                            style: {
                              'ul': Style(
                                padding: HtmlPaddings.zero,
                                margin: Margins.only(
                                  left: 16,
                                  top: 6,
                                  bottom: 12,
                                  right: 0,
                                ),
                              ),
                              'ol': Style(
                                padding: HtmlPaddings.zero,
                                margin: Margins.only(
                                  left: 14,
                                  top: 0,
                                  bottom: 0,
                                  right: 0,
                                ),
                              ),
                              'li': Style(
                                padding: HtmlPaddings.zero,
                                margin: Margins.only(
                                  left: 0,
                                  top: 0,
                                  bottom: 8,
                                  right: 0,
                                ),
                                fontFamily: 'JetBrainsMonoNL',
                                fontSize: FontSize(16),
                              ),
                              'p': Style(
                                margin: Margins.only(bottom: 16),
                                fontSize: FontSize(18),
                              ),
                              'table': Style(
                                border: Border.all(color: Colors.grey),
                                backgroundColor: Colors.white,
                                margin: Margins.symmetric(vertical: 12),
                                fontFamily: 'cursive',
                              ),
                              'th': Style(
                                padding: HtmlPaddings.all(8),
                                backgroundColor: const Color(0xFFE0E0E0),
                                border: Border.all(color: Colors.grey),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'cursive',
                              ),
                              'td': Style(
                                padding: HtmlPaddings.all(8),
                                border: Border.all(color: Colors.grey),
                                fontFamily: 'cursive',
                              ),
                              'hr': Style(
                                margin: Margins.symmetric(vertical: 0),
                                border: Border.all(color: Colors.grey),
                              ),
                            },
                            extensions: [
                              TagExtension(
                                tagsToExtend: {
                                  'h1',
                                  'h2',
                                  'h3',
                                  'h4',
                                  'h5',
                                  'h6',
                                },
                                builder: (extContext) {
                                  final text = extContext.innerHtml;
                                  final anchor = _getAnchorForHeading(text);
                                  final key = _anchorKeys[anchor];
                                  TextStyle? headingStyle;
                                  // Define a record to hold fontSize and color
                                  ({double fontSize, Color color}) styleRecord;

                                  switch (extContext.element?.localName) {
                                    case 'h1':
                                      styleRecord = (
                                        fontSize: 32.0,
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          94,
                                          199,
                                        ),
                                      );
                                      break;
                                    case 'h2':
                                      styleRecord = (
                                        fontSize: 28.0,
                                        color: const Color.fromARGB(
                                          255,
                                          171,
                                          255,
                                          75,
                                        ),
                                      );
                                      break;
                                    case 'h3':
                                      styleRecord = (
                                        fontSize: 24.0,
                                        color: const Color.fromARGB(
                                          255,
                                          63,
                                          169,
                                          255,
                                        ),
                                      );
                                      break;
                                    case 'h4':
                                      styleRecord = (
                                        fontSize: 20.0,
                                        color: const Color.fromARGB(
                                          255,
                                          183,
                                          91,
                                          58,
                                        ),
                                      );
                                      break;
                                    case 'h5':
                                      styleRecord = (
                                        fontSize: 18.0,
                                        color: Colors.teal,
                                      );
                                      break;
                                    case 'h6':
                                      styleRecord = (
                                        fontSize: 16.0,
                                        color: Colors.grey,
                                      );
                                      break;
                                    default:
                                      styleRecord = (
                                        fontSize: 16.0,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            Colors.black,
                                      );
                                  }
                                  return Column(
                                    children: [
                                      Container(
                                        key: key,
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          top: 32,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            fontSize: styleRecord.fontSize,
                                            color: styleRecord.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Divider(color: styleRecord.color),
                                    ],
                                  );
                                },
                              ),
                              TagExtension(
                                // style code which as class attribute
                                tagsToExtend: {'code'},
                                builder: (extContext) {
                                  // Only style code blocks (inside <pre>), not inline code
                                  final isBlock =
                                      extContext.element?.parent?.localName ==
                                      'pre';
                                  final String? language = extContext
                                      .attributes['class']
                                      ?.split(' ')
                                      .firstWhere(
                                        (attr) => attr.startsWith('language-'),
                                        orElse: () => '',
                                      )
                                      .replaceFirst('language-', '');
                                  // Decode HTML entities so code blocks show <, >, etc. correctly
                                  final String codeContent = HtmlUnescape()
                                      .convert(extContext.innerHtml);
                                  if (isBlock) {
                                    return CodeBlock(
                                      codeContent: codeContent,
                                      isDarkMode: isDarkMode,
                                      language: language,
                                    );
                                  } else {
                                    // Inline code: minimal style, no background
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color.fromARGB(255, 37, 44, 54),
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                      child: Text(
                                        codeContent,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          color: Colors.blue,
                                          backgroundColor: Color.fromARGB(
                                            255,
                                            37,
                                            44,
                                            54,
                                          ),
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
