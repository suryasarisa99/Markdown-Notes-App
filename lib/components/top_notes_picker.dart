import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_notes/main.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/notes_provider.dart';
import 'package:markdown_notes/theme.dart';

class TopNotesPicker extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final Function(FileNode)? onPick;
  final bool hasFocus;
  final bool canClose; // Set to false if you want to disable closing

  const TopNotesPicker({
    required this.searchController,
    required this.onPick,
    this.hasFocus = false,
    this.canClose = true,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopNotesPickerState();
}

class _TopNotesPickerState extends ConsumerState<TopNotesPicker> {
  late List<FileNode> _allSidebarNodes = ref.read(notesDirProvider);
  late List<FileNode> _filteredSidebarNodes =
      widget.searchController.text.isEmpty
      ? _allSidebarNodes
      : _allSidebarNodes.where((node) {
          return node.name.toLowerCase().contains(
            widget.searchController.text.toLowerCase(),
          );
        }).toList();
  static double listItemHeight = 40.0;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
    if (widget.hasFocus) {
      focusNode.requestFocus();
    }
  }

  void _onSearchChanged() {
    final query = widget.searchController.text.toLowerCase();
    log('query: $query');
    setState(() {
      if (query.isNotEmpty) {
        _filteredSidebarNodes = _allSidebarNodes.where((node) {
          return node.name.toLowerCase().contains(query);
        }).toList();
      } else {
        _filteredSidebarNodes = _allSidebarNodes;
      }
    });
  }

  void _onFileSelected(FileNode node) {
    prefs!.setString("selectedNotes", node.name);
    // Navigator.of(context).pop();
    widget.onPick?.call(node);
  }

  FocusNode focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final isDesktop =
        Platform.isMacOS || Platform.isLinux || Platform.isWindows;
    // final isDesktop = false;

    final appTheme = Theme.of(context);
    final theme = AppTheme.from(appTheme.brightness);

    double height = size.height - keyboardHeight;
    // if (_filteredSidebarNodes.length * listItemHeight < height) {
    //   height = _filteredSidebarNodes.length * listItemHeight + 50 + 100;
    // }
    if (isKeyboardOpen) {
      height -= 50;
    }

    return Align(
      // alignment: Alignment.topCenter,
      alignment: isDesktop ? Alignment(0, -0.5) : Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: isDesktop ? 400 : height,
          width: math.min(780, size.width),
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              CallbackShortcuts(
                bindings: {
                  LogicalKeySet(LogicalKeyboardKey.arrowDown): () {
                    log('Arrow Down pressed');
                    if (focusNode.hasFocus) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                },
                child: TextField(
                  focusNode: focusNode,
                  autofocus: widget.hasFocus,
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSidebarNodes.length,
                  itemBuilder: (context, index) {
                    final node = _filteredSidebarNodes[index];
                    return CallbackShortcuts(
                      bindings: {
                        LogicalKeySet(LogicalKeyboardKey.enter): () =>
                            // _onFileSelected(node),
                            {},
                      },
                      child: Focus(
                        child: Builder(
                          builder: (context) {
                            final hasFocus = Focus.of(context).hasFocus;
                            return Container(
                              decoration: BoxDecoration(
                                border: hasFocus
                                    ? Border.all(
                                        color: appTheme.colorScheme.primary,
                                        width: 2,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ListTile(
                                minTileHeight: 40,
                                // dense: true,
                                minVerticalPadding: 0,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 0,
                                ),
                                leading: Icon(
                                  node.isDirectory
                                      ? Icons.folder
                                      : Icons.insert_drive_file,
                                ),
                                title: Text(node.name),
                                onTap: () => _onFileSelected(node),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
