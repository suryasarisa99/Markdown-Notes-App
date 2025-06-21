import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/components/expansion_folder.dart';
import 'package:markdown_notes/components/notes_picker.dart';
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
      padding: EdgeInsets.only(
        left: 10,
        right: 8,
        top: MediaQuery.paddingOf(context).top + 8,
      ),
      color: const Color.fromARGB(255, 19, 29, 44),
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
              child: Text(
                node.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
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
        childrenPadding: EdgeInsets.only(left: 14),
        tilePadding: const EdgeInsets.only(right: 8),
        dense: true,
        showTrailingIcon: false,
        title: ListTile(
          contentPadding: const EdgeInsets.only(left: 4),
          dense: true,
          horizontalTitleGap: 2,
          leading: const Icon(Icons.folder, size: 22, color: Color(0xFFFF9A3B)),
          title: Text(node.name),
          // onTap: onFileTap != null ? () => onFileTap!(node) : null,
        ),
        children: node.children.map(_buildNode).toList(),
        // children: [
        //   IntrinsicHeight(
        //     child: Row(
        //       crossAxisAlignment: CrossAxisAlignment.stretch,
        //       children: [
        //         Container(
        //           width: 1,
        //           color: const Color.fromARGB(255, 82, 82, 82),
        //         ),
        //         SizedBox(width: 8),
        //         Expanded(
        //           child: Column(
        //             children: node.children.map(_buildNode).toList(),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      );
      // return Text(node.name);
    } else {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 4),
        // minVerticalPadding: 0,
        dense: true,
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
