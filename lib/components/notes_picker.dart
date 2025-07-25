import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_notes/main.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/notes_provider.dart';
import 'package:markdown_notes/theme.dart';

class NotesPicker extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final Function(FileNode)? onPick;
  final bool hasFocus;
  final bool canClose; // Set to false if you want to disable closing
  const NotesPicker({
    required this.searchController,
    required this.onPick,
    this.hasFocus = false,
    this.canClose = true,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NotesPickerState();
}

class _NotesPickerState extends ConsumerState<NotesPicker> {
  late List<FileNode> _allSidebarNodes = ref.read(notesDirProvider);
  late List<FileNode> _filteredSidebarNodes = _allSidebarNodes;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
    if (widget.hasFocus) {
      focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant NotesPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchChanged);
      widget.searchController.addListener(_onSearchChanged);
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    // widget.searchController.dispose();
    focusNode.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(notesDirProvider);
    final brightness = Theme.of(context).brightness;
    final theme = AppTheme.from(brightness);
    final appTheme = Theme.of(context);
    log("nodes: ${nodes.length}");
    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      initialChildSize: 0.65,
      shouldCloseOnMinExtent: widget.canClose,
      expand: false,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 300,
          color: theme.surface,
          width: double.infinity,
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
                  // onChanged: (value) {
                  //   log('Search query: $value');
                  // },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _filteredSidebarNodes.length,
                  itemBuilder: (context, index) {
                    final node = _filteredSidebarNodes[index];
                    return CallbackShortcuts(
                      bindings: {
                        LogicalKeySet(LogicalKeyboardKey.enter): () =>
                            _onFileSelected(node),
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
        );
      },
    );
  }
}
