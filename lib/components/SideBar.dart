import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/components/NotesPicker.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/screens/file_select_screen.dart';

class FileSidebar extends StatelessWidget {
  final FileNode node;
  final void Function(FileNode)? onFileTap;
  final void Function(FileNode)? onDirectoryChange;
  const FileSidebar({
    super.key,
    required this.node,
    required this.onDirectoryChange,
    this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    // log("Building sidebar with ${nodes.length} nodes");
    return Container(
      width: 350,
      color: const Color.fromARGB(255, 15, 15, 15),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              Scaffold.of(context).showBottomSheet(
                (context) => NotesPicker(
                  searchController: TextEditingController(),
                  onPick: onDirectoryChange,
                ),
              );
            },
            child: Text(node.name, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0.0),
              children: node.children.map((node) => _buildNode(node)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(FileNode node) {
    if (node.isDirectory) {
      return ExpansionTile(
        childrenPadding: EdgeInsets.only(left: 20),
        tilePadding: const EdgeInsets.only(right: 8),
        // showTrailingIcon: false,
        title: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(node.name),
          onTap: onFileTap != null ? () => onFileTap!(node) : null,
        ),
        children: node.children.map(_buildNode).toList(),
      );
      // return Text(node.name);
    } else {
      return ListTile(
        leading: const Icon(Icons.insert_drive_file),
        title: Text(node.name),
        onTap: onFileTap != null ? () => onFileTap!(node) : null,
      );
    }
  }
}
