import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:markdown/markdown.dart' hide Text;
import 'package:html_unescape/html_unescape.dart';
import 'package:markdown_notes/components/code_block.dart';
import 'package:markdown_notes/components/notes_picker.dart';
import 'package:markdown_notes/components/side_bar.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/theme.dart';

enum FileOpenType {
  fromSidebar("sidebar"),
  fromLink("link");

  final String name;
  const FileOpenType(this.name);
}

class HomeScreen extends StatefulWidget {
  final FileNode projectNode;
  final FileNode? curFileNode;
  const HomeScreen({required this.projectNode, this.curFileNode, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FileNode projectNode = widget.projectNode;
  late FileNode? curFileNode = widget.curFileNode;
  bool isMarkdownFile = true;
  String _htmlText = '';
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _anchorKeys = {};
  final Map<String, int> _anchorCounts = {};
  final Map<String, int> _renderedAnchorCounts = {};
  final focusNode = FocusNode();
  final mainFocusScope = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    if (curFileNode != null) {
      _handleParse(curFileNode!);
    }

    // get focus back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  void _handleParse(FileNode node) async {
    // read content from fileNode path
    String text = File(node.path).readAsStringSync();
    if (node.name.endsWith('.md') || node.name.endsWith('.markdown')) {
      setState(() {
        curFileNode = node;
        _htmlText = markdownToHtml(
          text,
          // blockSyntaxes: [TableSyntax()],
          extensionSet: ExtensionSet.gitHubFlavored,
        );
        isMarkdownFile = true;
      });
    } else {
      setState(() {
        curFileNode = node;
        isMarkdownFile = false;
        _htmlText = text;
      });
    }

    // log(_htmlText);
    _generateAnchorKeys(_htmlText);
  }

  void _handleNewPage(FileNode node, FileOpenType openType) {
    // final openInNewTab = prefs!.getBool(openType.name) ?? false;

    final openInNewTab = openType == FileOpenType.fromLink
        ? Settings.linkFileHistory
        : Settings.sidebarFileHistory;
    if (openInNewTab) {
      context.push(
        '/home',
        extra: (projectNode: projectNode, curFileNode: node),
      );
    } else {
      _handleParse(node);
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String filePath = result.files.single.path!;
      String text = await File(filePath).readAsString();
      setState(() {
        _htmlText = markdownToHtml(
          text,
          blockSyntaxes: [TableSyntax()],
          extensionSet: ExtensionSet.gitHubFlavored,
        );
        isMarkdownFile =
            filePath.endsWith('.md') || filePath.endsWith('.markdown');
        _generateAnchorKeys(_htmlText);
      });
    } else {
      log('No file selected');
    }
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

  List<({String text, bool code})> _parseHeadingContent(String html) {
    final regex = RegExp(r'<code>(.*?)</code>');
    final matches = regex.allMatches(html);

    List<({String text, bool code})> result = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before <code>
      if (match.start > lastEnd) {
        final text = html.substring(lastEnd, match.start);
        if (text.trim().isNotEmpty) {
          result.add((text: text.trim(), code: false));
        }
      }
      // Add code content
      final codeText = match.group(1);
      if (codeText != null && codeText.isNotEmpty) {
        result.add((text: codeText, code: true));
      }
      lastEnd = match.end;
    }
    // Add any remaining text after the last <code>
    if (lastEnd < html.length) {
      final text = html.substring(lastEnd);
      if (text.trim().isNotEmpty) {
        result.add((text: text.trim(), code: false));
      }
    }
    return result;
  }

  void _traverse(String url) {
    // Traverse the projectNode tree to find the fileNode with the given path
    final pathAndAnchor = url.split('#');
    final path = pathAndAnchor[0];
    final parts = path.split("/");
    bool isAbsolutePath = path.startsWith("/");

    if (isAbsolutePath) {
      return _traverseForward(projectNode, parts.sublist(1));
    }
    // Relative path handling
    /*
    project Node:
      - home/react
    
    Example1:
      - curr Node.  : home/react/test/sample/file.md - ../file2.md
      - pointed Node: home/react/test/file2.md

    Example2:
      - curr Node.  : home/react/test/sample/file.md - ../../magic/file2.md
      - pointed Node: home/react/magic/file2.md

    Example3:
      - curr Node.  : home/react/test/sample/file.md - ../magic/file2.md
      - pointed Node: home/react/test/magic/file2.md
    
    */

    // diff: path diff between current file and project root, /test/sample/file.md
    final diff = curFileNode!.path.replaceFirst(projectNode.path, '');
    final diffParts = diff.split("/"); // [ , 'test', 'sample', 'file.md']
    final diffPathParts = diffParts.sublist(
      diffParts.length == 2 && diffParts[0] == ''
          ? 1
          : 0, // skip the first empty part if exists
      diffParts.length - 1,
    ); // ['test', 'sample']
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part == ".") {
        // Ignore this
      } else if (part == "..") {
        // Go up one directory
        if (diffPathParts.isNotEmpty) {
          diffPathParts.removeLast();
        }
      } else {
        // Add the new part to the path
        diffPathParts.add(part);
      }
    }
    _traverseForward(projectNode, diffPathParts);
  }

  void _traverseForward(FileNode node, List<String> parts) {
    for (final part in parts) {
      // Find the child with the matching name
      final child = node.children.firstWhere(
        (childNode) => childNode.name == part,
        orElse: () {
          log("not found");
          return FileNode(name: part, path: '', isDirectory: false);
        },
      );
      if (child.isDirectory) {
        node = child;
      } else {
        _handleNewPage(child, FileOpenType.fromLink);
        break;
      }
    }
  }

  void _goBack() {
    if (context.canPop()) context.pop();
  }

  void _goTop() => _scrollController.jumpTo(0);

  void _goBottom() =>
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  void _openDrawer() => scaffoldKey.currentState!.openDrawer();
  void _toggleDrawer() {
    final scaffoldState = scaffoldKey.currentState!;
    if (scaffoldState.isDrawerOpen) {
      scaffoldState.closeDrawer();
    } else {
      scaffoldState.openDrawer();
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return NotesPicker(
          searchController: TextEditingController(),
          hasFocus: true,
          onPick: (node) {
            context.pop();
            setState(() {
              projectNode = node;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _renderedAnchorCounts.clear();
    final brightness = Theme.of(context).brightness;
    final theme = AppTheme.from(brightness);
    final isDarkMode = brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? codeBlockDarkTheme['root']?.backgroundColor
        : codeBlockLightTheme['root']?.backgroundColor;
    final conditionalBg = !isMarkdownFile ? backgroundColor : theme.background;

    return FocusScope(
      autofocus: true,
      node: mainFocusScope,
      child: CallbackShortcuts(
        bindings: {
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyO):
              _pickFile,
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyP):
              _showPicker,

          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB):
              _toggleDrawer,

          // Close the current page
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyW):
              _goBack,
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowLeft):
              _goBack,
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.bracketLeft,
          ): _goBack,
          LogicalKeySet(LogicalKeyboardKey.escape): _goBack,

          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowUp):
              _goTop,
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.arrowDown):
              _goBottom,
        },
        child: Focus(
          autofocus: true,
          focusNode: focusNode,
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: conditionalBg,
            drawer: FileSidebar(
              node: projectNode,
              onDirectoryChange: (node) {
                context.pop();
                setState(() {
                  projectNode = node;
                });
                scaffoldKey.currentState!.openDrawer();
              },
              onFileTap: (node) {
                context.pop(); // Close the drawer
                _handleNewPage(node, FileOpenType.fromSidebar);
              },
            ),
            body: SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                // padding: const EdgeInsets.all(10.0),
                // padding: const EdgeInsets.only(left: 12.0, top: 18),
                slivers: [
                  SliverAppBar(
                    backgroundColor: conditionalBg,
                    actions: [
                      IconButton(
                        icon: Icon(
                          HugeIcons.strokeRoundedMoreVertical,
                          color: const Color.fromARGB(255, 163, 163, 163),
                        ),
                        onPressed: () {
                          // show menu items
                          showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              100.0,
                              60.0,
                              0.0,
                              0.0,
                            ),
                            menuPadding: const EdgeInsets.all(0.0),
                            // color: theme.surface,
                            items: [
                              PopupMenuItem(
                                height: 40,
                                onTap: () => context.push("/settings"),
                                child: Text('Settings'),
                              ),
                              PopupMenuItem(
                                height: 40,
                                onTap: _pickFile,
                                child: Text('Open File'),
                              ),
                              PopupMenuItem(
                                height: 40,
                                onTap: _showPicker,
                                child: Text('Open Notes Directory'),
                              ),
                              if (curFileNode != null)
                                PopupMenuItem(
                                  height: 40,
                                  onTap: _goTop,
                                  child: Text('Scroll to Top'),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    leading: IconButton(
                      icon: Icon(
                        HugeIcons.strokeRoundedSidebarLeft,
                        // color: const Color(0xFF8895B1),
                        color: theme.iconColor,
                      ),
                      onPressed: _openDrawer,
                    ),
                    title: Text(curFileNode?.name ?? ""),
                    floating: true,
                    snap: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      // padding: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.only(
                        left: 6,
                        right: 6,
                        top: 18,
                      ),
                      child: _buildBody(isDarkMode, theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode, AppColors theme) {
    if (curFileNode == null) {
      final query = MediaQuery.of(context);
      final height = query.size.height - kToolbarHeight - query.padding.top;
      return SizedBox(
        height: height - 18,
        child: Center(child: Text('Open File', style: TextStyle(fontSize: 18))),
      );
    }
    if (!isMarkdownFile) {
      return CodeBlock(
        codeContent: _htmlText,
        isDarkMode: isDarkMode,
        language: curFileNode?.name.split('.').last,
        isFullSize: true,
      );
    } else {
      return Html(
        data: _htmlText,

        onAnchorTap: (url, attrs, elm) {
          if (url != null && url.startsWith('#')) {
            final anchor = url.substring(1);
            //     .toLowerCase()
            //     .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
            //     .replaceAll(RegExp(r'\s+'), '-');
            // log("anchor: $anchor");
            log("scrolling to anchor: $url");
            _scrollToAnchor(anchor);
          } else {
            _traverse(url ?? '');
          }
        },
        onLinkTap: (url, attrs, elm) {
          // handle external links if needed
        },
        style: {
          'ul': Style(
            padding: HtmlPaddings.zero,
            margin: Margins.only(left: 16, top: 6, bottom: 12, right: 0),
          ),
          'ol': Style(
            padding: HtmlPaddings.zero,
            margin: Margins.only(left: 26, top: 0, bottom: 0, right: 0),
          ),
          'li': Style(
            padding: HtmlPaddings.zero,
            margin: Margins.only(left: 0, top: 0, bottom: 8, right: 0),
            fontSize: FontSize(16),
          ),
          'p': Style(margin: Margins.only(bottom: 16), fontSize: FontSize(18)),
          'table': Style(
            // border: Border.all(color: Colors.grey),
            // backgroundColor: Colors.white,
            margin: Margins.symmetric(vertical: 12),
          ),
          'th': Style(
            padding: HtmlPaddings.all(8),
            // backgroundColor: const Color(0xFFE0E0E0),
            border: Border.all(color: Colors.grey),
            fontWeight: FontWeight.bold,
          ),
          'td': Style(
            padding: HtmlPaddings.all(8),
            border: Border.all(color: Colors.grey),
          ),
          'hr': Style(
            margin: Margins.symmetric(vertical: 0),
            border: Border.all(color: Colors.grey),
          ),
        },
        extensions: [
          TableHtmlExtension(),
          TagExtension(
            tagsToExtend: {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'},
            // :TODO this builder runs every time click on screen or focus
            builder: (extContext) {
              final text = extContext.innerHtml;
              final anchor = _getAnchorForHeading(text);
              final key = _anchorKeys[anchor];
              final tagName = extContext.element?.localName!;
              final isLargeText =
                  tagName == 'h1' || tagName == 'h2' || tagName == 'h3';
              ({double fontSize, Color color}) styleRecord;

              switch (tagName) {
                case 'h1':
                  styleRecord = (
                    fontSize: 28.0,
                    color: theme.markdownColors.h1,
                  );
                  break;
                case 'h2':
                  styleRecord = (
                    fontSize: 25.0,
                    color: theme.markdownColors.h2,
                  );
                  break;
                case 'h3':
                  styleRecord = (
                    fontSize: 22.0,
                    color: theme.markdownColors.h3,
                  );
                  break;
                case 'h4':
                  styleRecord = (
                    fontSize: 20.0,
                    color: theme.markdownColors.h4,
                  );
                  break;
                case 'h5':
                  styleRecord = (
                    fontSize: 18.0,
                    color: theme.markdownColors.h5,
                  );
                  break;
                case 'h6':
                  styleRecord = (
                    fontSize: 16.0,
                    color: theme.markdownColors.h6,
                  );
                  break;
                default:
                  styleRecord = (
                    fontSize: 16.0,
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black,
                  );
              }

              final textParts = _parseHeadingContent(text);
              return Column(
                children: [
                  Container(
                    key: key,
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 32, bottom: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: textParts.map((part) {
                          return Container(
                            padding: part.code
                                ? const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 2.5,
                                  )
                                : EdgeInsets.zero,
                            margin: part.code
                                ? const EdgeInsets.symmetric(horizontal: 12.0)
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: part.code
                                  ? styleRecord.color.withValues(alpha: 0.2)
                                  : null,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              part.text,
                              style: TextStyle(
                                fontSize: part.code
                                    ? styleRecord.fontSize - 2
                                    : styleRecord.fontSize,
                                color: styleRecord.color,

                                fontWeight: part.code
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (isLargeText) Divider(color: styleRecord.color),
                ],
              );
            },
          ),

          TagExtension(
            // style code which as class attribute
            tagsToExtend: {'code'},
            builder: (extContext) {
              // Only style code blocks (inside <pre>), not inline code
              final isBlock = extContext.element?.parent?.localName == 'pre';
              final String? language = extContext.attributes['class']
                  ?.split(' ')
                  .firstWhere(
                    (attr) => attr.startsWith('language-'),
                    orElse: () => '',
                  )
                  .replaceFirst('language-', '');
              // Decode HTML entities so code blocks show <, >, etc. correctly
              final String codeContent = HtmlUnescape().convert(
                extContext.innerHtml,
              );
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
                    color: theme.markdownColors.inlineCodeBg,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    codeContent,
                    style: TextStyle(
                      color: theme.markdownColors.inlineCodeTxt,
                      fontSize: 14.0,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      );
    }
  }
}
