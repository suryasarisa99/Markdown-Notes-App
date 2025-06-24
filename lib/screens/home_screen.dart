import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:markdown_notes/components/code_block.dart';
import 'package:markdown_notes/components/notes_picker.dart';
import 'package:markdown_notes/components/side_bar.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/notes_provider.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_notes/utils/traverse.dart';
import 'package:markdown_widget/markdown_widget.dart';

enum FileOpenType {
  fromSidebar("sidebar"),
  fromLink("link");

  final String name;
  const FileOpenType(this.name);
}

class HomeScreen extends ConsumerStatefulWidget {
  final FileNode projectNode;
  final FileNode? curFileNode;
  const HomeScreen({required this.projectNode, this.curFileNode, super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String data = "";
  late FileNode projectNode = widget.projectNode;
  late FileNode? curFileNode = widget.curFileNode;
  bool isMarkdownFile = true;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _anchorKeys = {};
  final Map<String, int> _anchorCounts = {};
  final focusNode = FocusNode();
  final mainFocusScope = FocusScopeNode();
  final tocController = TocController();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    log("TestScreen initialized with projectNode: ${projectNode.name}");
    if (curFileNode != null) {
      _handleData(curFileNode!);
    } else {
      openPreviousOpenedFile();
    }
  }

  bool openPreviousOpenedFile() {
    final path = Settings.getLastFilePath(projectNode.path);
    if (path != null) {
      final node = traverseForwardFromProjectNode(projectNode, path);
      if (node != null) {
        _handleData(node);
        return true;
      }
      return false;
    }
    return false;
  }

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

  Key _addAnchorKey(String text) {
    String baseAnchor = _normalizeAnchor(text);
    int count = (_anchorCounts[baseAnchor] ?? 0);
    String anchor = count == 0 ? baseAnchor : '$baseAnchor-$count';
    _anchorCounts[baseAnchor] = count + 1;
    log("created anchor: $text => $anchor");
    _anchorKeys[anchor] = GlobalKey();
    return _anchorKeys[anchor]!;
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
      Scrollable.ensureVisible(key.currentContext!, curve: Curves.easeInOut);
    }
  }

  void _handleNewPage(FileNode node, FileOpenType openType) {
    final openInNewTab = openType == FileOpenType.fromLink
        ? Settings.linkFileHistory
        : Settings.sidebarFileHistory;
    if (openInNewTab) {
      context.push(
        '/home',
        extra: (projectNode: projectNode, curFileNode: node),
      );
    } else {
      _handleData(node);
      _scrollController.jumpTo(0);
    }
  }

  void _handleData(FileNode node) async {
    final text = await File(node.path).readAsString();
    Settings.setLastFilePath(projectNode.path, node.path);
    setState(() {
      data = text;
      isMarkdownFile =
          node.name.endsWith(".md") || node.name.endsWith(".markdown");
      curFileNode = node;
    });
  }

  Key? onBuild(String text) {
    return _addAnchorKey(text);
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
          searchController: searchController,
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
    log("Only build once");
    final brightness = Theme.brightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;
    final theme = AppTheme.from(brightness);
    final codeBlockTheme = isDarkMode
        ? codeBlockDarkTheme
        : codeBlockLightTheme;
    final conditionBg = isMarkdownFile
        ? theme.background
        : codeBlockTheme['root']!.backgroundColor!;
    // clear keys and counts
    _anchorKeys.clear();
    _anchorCounts.clear();
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
            backgroundColor: conditionBg,
            drawer: FileSidebar(
              projectNode: projectNode,
              currentNode: curFileNode,
              onDirectoryChange: (node) {
                context.pop();
                setState(() {
                  projectNode = node;
                });
                if (!openPreviousOpenedFile()) {
                  scaffoldKey.currentState!.openDrawer();
                }
              },
              onFileTap: (node) {
                context.pop(); // Close the drawer
                _handleNewPage(node, FileOpenType.fromSidebar);
              },
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                final notesNotifier = ref.read(notesDirProvider.notifier);
                await notesNotifier.updateNotesDir(Settings.location);
                final x = notesNotifier.findNotesDir(projectNode.name);
                setState(() {
                  if (x != null) projectNode = x;
                });
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(conditionBg, theme),
                  SliverToBoxAdapter(child: _buildPage(isDarkMode, theme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color appBarBackground, AppColors theme) {
    return SliverAppBar(
      backgroundColor: appBarBackground,
      actions: [
        IconButton(
          icon: Icon(HugeIcons.strokeRoundedMoreVertical),
          onPressed: () {
            // show menu items
            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(100.0, 60.0, 0.0, 0.0),
              menuPadding: const EdgeInsets.all(0.0),
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
        icon: Icon(HugeIcons.strokeRoundedSidebarLeft, color: theme.iconColor),
        onPressed: _openDrawer,
      ),
      title: Text(curFileNode?.name ?? ""),
      floating: true,
      snap: true,
    );
  }

  Widget _buildPage(bool isDarkMode, AppColors theme) {
    if (data.isEmpty) {
      return SizedBox(
        height:
            MediaQuery.of(context).size.height -
            kToolbarHeight -
            MediaQuery.paddingOf(context).top,
        child: Center(
          child: Text(
            "No content available. Please select a file.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    if (!isMarkdownFile) {
      return CodeBlock(
        codeContent: data,
        isDarkMode: isDarkMode,
        language: curFileNode?.name.split('.').last ?? 'js',
        isFullSize: true,
      );
    } else {
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
          tocController: tocController,
          config: config.copy(
            configs: [
              preConfig.copy(
                decoration: BoxDecoration(
                  color: codeBlockTheme['root']?.backgroundColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                // wrapper: (child, text, lang) {
                //   return Padding(
                //     padding: const EdgeInsets.all(12.0),
                //     child: child,
                //   );
                // },
                theme: codeBlockTheme,
                // theme: a11yDarkTheme,
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
                onTap: (url) {
                  if (url.startsWith("http") || url.startsWith("www")) {
                    // external link
                  } else if (url.startsWith('#')) {
                    // Current Page navigation
                    final anchor = url.substring(1);
                    //     .toLowerCase()
                    //     .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
                    //     .replaceAll(RegExp(r'\s+'), '-');
                    // log("anchor: $anchor");
                    log("scrolling to anchor: $url");
                    _scrollToAnchor(anchor);
                  } else {
                    // Another notes page
                    final newPageNode = traverse(projectNode, curFileNode, url);
                    if (newPageNode != null) {
                      _handleNewPage(newPageNode, FileOpenType.fromLink);
                    } else {
                      log("Node not found for URL: $url");
                    }
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
}
