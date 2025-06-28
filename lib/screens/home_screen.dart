import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:markdown_notes/components/code_block.dart';
import 'package:markdown_notes/components/markdown_view.dart';
import 'package:markdown_notes/components/notes_picker.dart';
import 'package:markdown_notes/components/side_bar.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/settings/settings.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/notes_provider.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_notes/utils/traverse.dart';

enum FileOpenType {
  fromSidebar("sidebar"),
  fromLink("link");

  final String name;
  const FileOpenType(this.name);
}

class HomeScreen extends ConsumerStatefulWidget {
  final FileNode projectNode;
  final FileNode? curFileNode;
  final String? anchor;
  const HomeScreen({
    required this.projectNode,
    this.curFileNode,
    this.anchor,
    super.key,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String data = "";
  late FileNode projectNode = widget.projectNode;
  late FileNode? curFileNode = widget.curFileNode;
  bool isMarkdownFile = true;
  late String? preAnchor = widget.anchor;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  final focusNode = FocusNode();
  final mainFocusScope = FocusScopeNode();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (curFileNode != null) {
      _handleData(curFileNode!, preAnchor);
    } else {
      openPreviousOpenedFile();
    }
  }

  bool openPreviousOpenedFile() {
    final path = Settings.getLastFilePath(projectNode.path);
    if (path == null) return false;
    final node = traverseForwardFromProjectNode(projectNode, path);
    if (node == null) return false;
    _handleData(node);
    return true;
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

  void _handleNewPage(FileNode node, FileOpenType openType, {String? anchor}) {
    final openInNewTab = openType == FileOpenType.fromLink
        ? Settings.linkFileHistory
        : Settings.sidebarFileHistory;
    log("new page: newTab: $openInNewTab, anchor: $anchor");
    if (openInNewTab) {
      context.push(
        '/home',
        extra: (projectNode: projectNode, curFileNode: node, anchor: anchor),
      );
    } else {
      _handleData(node, anchor);
    }
  }

  void _handleData(FileNode node, [String? anchor]) async {
    final text = await File(node.path).readAsString();
    Settings.setLastFilePath(projectNode.path, node.path);
    setState(() {
      data = text;
      isMarkdownFile =
          node.name.endsWith(".md") || node.name.endsWith(".markdown");
      curFileNode = node;
      preAnchor = anchor;
    });
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

  void onLinkTap(url) async {
    // Another to another notes page
    log("url: $url");
    final traverseData = traverse(projectNode, curFileNode, url);
    if (traverseData.node != null) {
      _handleNewPage(
        traverseData.node!,
        FileOpenType.fromLink,
        anchor: traverseData.anchor,
      );
    } else {
      log("Node not found for URL: $url");
    }
  }

  Future<void> onRefresh() async {
    final notesNotifier = ref.read(notesDirProvider.notifier);
    await notesNotifier.updateNotesDir(Settings.location);
    final x = notesNotifier.findNotesDir(projectNode.name);
    setState(() {
      if (x != null) projectNode = x;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;
    final theme = AppTheme.from(brightness);
    final codeBlockTheme = isDarkMode
        ? codeBlockDarkTheme
        : codeBlockLightTheme;
    final conditionBg = isMarkdownFile
        ? theme.background
        : codeBlockTheme['root']!.backgroundColor!;

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
              onRefresh: onRefresh,
              child: SafeArea(
                // child: CustomScrollView(
                //   controller: _scrollController,
                //   slivers: [
                //     _buildAppBar(conditionBg, theme),
                //     SliverToBoxAdapter(child: _buildPage(isDarkMode, theme)),
                //   ],
                // ),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [_buildAppBar(conditionBg, theme)];
                  },
                  body: _buildPage(isDarkMode, theme),
                ),
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
                  onTap: onRefresh,
                  child: Text('Refresh'),
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
      return MarkdownView(
        data: data,
        onLinkTap: onLinkTap,
        preAnchor: preAnchor,
      );
    }
  }
}
