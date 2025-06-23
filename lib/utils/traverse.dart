import 'dart:developer';
import 'dart:io';

import 'package:markdown_notes/models/file_node.dart';

FileNode? traverse(FileNode projectNode, FileNode? curFileNode, String url) {
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
  return _traverseForward(projectNode, diffPathParts);
}

FileNode? _traverseForward(FileNode node, List<String> parts) {
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
      return child;
    }
  }
  return null;
}

FileNode? traverseForwardFromProjectNode(FileNode node, String path) {
  path = path.replaceFirst(node.path, "");
  path = path.startsWith("/")
      ? path.substring(1)
      : path; // remove leading slash
  final parts = path.split("/");
  return _traverseForward(node, parts);
}
