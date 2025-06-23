import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/components/notes_picker.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/theme.dart';

class FileSidebar extends StatelessWidget {
  final FileNode projectNode;
  final FileNode? currentNode;
  final void Function(FileNode)? onFileTap;
  final void Function(FileNode)? onDirectoryChange;
  const FileSidebar({
    super.key,
    required this.projectNode,
    this.currentNode,
    required this.onDirectoryChange,
    this.onFileTap,
  });

  List<String> getParts() {
    if (currentNode == null) return [];
    log("currentNode: ${currentNode!.path}");
    String diff = currentNode!.path.replaceFirst(projectNode.path, "");
    log("diff: $diff");
    diff = diff.startsWith("/") ? diff.substring(1) : diff;
    log("diff after removing first slash: $diff");
    return diff.split("/");
  }

  @override
  Widget build(BuildContext context) {
    final diffParts = getParts();
    final brightness = Theme.brightnessOf(context);
    final theme = AppTheme.from(brightness);

    return Drawer(
      width: 300,
      // color: const Color.fromARGB(255, 19, 29, 44),
      child: Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: 8,
          top: MediaQuery.paddingOf(context).top + 8,
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context.pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return NotesPicker(
                        searchController: TextEditingController(),
                        hasFocus: true,
                        onPick: onDirectoryChange,
                      );
                    },
                  );
                },
                child: Text(projectNode.name),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0.0),
                children: projectNode.children
                    .map((node) => _buildNode(node, diffParts, theme))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(FileNode node, List<String>? urlParts, AppColors theme) {
    if (node.isDirectory) {
      final isDirectoryOpen =
          urlParts != null &&
          urlParts.isNotEmpty &&
          urlParts.first == node.name &&
          urlParts.length > 1;
      return ExpansionTile(
        childrenPadding: EdgeInsets.only(left: 14),
        tilePadding: const EdgeInsets.only(right: 8),
        dense: true,
        initiallyExpanded: isDirectoryOpen,
        showTrailingIcon: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide.none,
        ),
        title: ListTile(
          visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
          contentPadding: const EdgeInsets.only(left: 4),
          dense: true,
          horizontalTitleGap: 2,
          leading: const Icon(Icons.folder, size: 22, color: Color(0xFFFF9A3B)),
          title: Text(node.name),
          // onTap: onFileTap != null ? () => onFileTap!(node) : null,
        ),
        children: node.children
            .map(
              (part) => _buildNode(
                part,
                (urlParts?.isNotEmpty ?? false) ? urlParts!.sublist(1) : null,
                theme,
              ),
            )
            .toList(),
      );
      // return Text(node.name);
    } else {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 4),
        // minVerticalPadding: 0,
        dense: true,
        visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
        selectedColor: theme.primary,
        selectedTileColor: theme.surface2,
        selected: currentNode?.path == node.path,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        horizontalTitleGap: 2,
        leading: const Icon(
          Icons.insert_drive_file,
          size: 20,
          color: Color(0xFF51A8FF),
        ),
        title: Text(node.name),
        onTap: onFileTap != null ? () => onFileTap!(node) : null,
      );
    }
  }
}
