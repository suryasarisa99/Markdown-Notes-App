import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/main.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/NotesProvider.dart';
import 'package:markdown_notes/screens/file_select_screen.dart';

class NotesPicker extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final Function(FileNode)? onPick;
  const NotesPicker({
    required this.searchController,
    required this.onPick,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NotesPickerState();
}

class _NotesPickerState extends ConsumerState<NotesPicker> {
  List<FileNode> _filteredSidebarNodes = [];

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        _filteredSidebarNodes = ref.read(notesDirProvider).where((node) {
          return node.name.toLowerCase().contains(query);
        }).toList();
      }
    });
    // _debounce = Timer(const Duration(milliseconds: 300), () {});
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(notesDirProvider);
    log("nodes: ${nodes.length}");
    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      initialChildSize: 0.65,
      expand: false,
      builder: (context, controller) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: 300,
              width: double.infinity,
              child: Column(
                children: [
                  TextField(
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
                    onChanged: (value) {
                      log('Search query: $value');
                      setModalState(() {}); // Rebuild bottom sheet
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: widget.searchController.text.isEmpty
                          ? nodes.length
                          : _filteredSidebarNodes.length,
                      itemBuilder: (context, index) {
                        final node = widget.searchController.text.isEmpty
                            ? nodes[index]
                            : _filteredSidebarNodes[index];
                        return ListTile(
                          leading: Icon(
                            node.isDirectory
                                ? Icons.folder
                                : Icons.insert_drive_file,
                          ),
                          title: Text(node.name),
                          onTap: () {
                            log('Tapped file: ${node.path}');
                            prefs?.setString('selectedNotes', node.name);
                            Navigator.of(context).pop();
                            widget.onPick?.call(node);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
