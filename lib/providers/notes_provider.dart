import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/models/file_node.dart';

class NotesDirProvider extends Notifier<List<FileNode>> {
  NotesDirProvider() : super();
  @override
  List<FileNode> build() {
    return [];
  }

  Future<List<FileNode>> updateNotesDir(String path) async {
    late List<FileNode> nodes = [];
    if (Platform.isAndroid) {
      nodes = await readDirectoryTree(path);
    } else if (Platform.isMacOS) {
      nodes = await readDirectoryTree(path);
    }
    state = nodes;
    log("notes length: ${nodes.length}");
    return nodes;
  }

  FileNode? findNotesDir(String name) {
    return state.firstWhereOrNull((node) => node.name == name);
  }
}

final notesDirProvider = NotifierProvider<NotesDirProvider, List<FileNode>>(
  () => NotesDirProvider(),
);

Future<List<FileNode>> readDirectoryTree(String rootPath) async {
  final dir = Directory(rootPath);
  if (!await dir.exists()) {
    log("directory does not exist: $rootPath");
    return [];
  }
  final List<FileNode> directories = [];
  final List<FileNode> files = [];
  final List<FileSystemEntity> entities = await dir.list().toList();
  for (final entity in entities) {
    final name = entity.path.split('/').last;
    if (!Settings.showHiddenFiles && name.startsWith(".")) continue;
    if (entity is Directory) {
      directories.add(
        FileNode(
          name: name,
          path: entity.path,
          isDirectory: true,
          children: await readDirectoryTree(entity.path),
        ),
      );
    } else if (entity is File) {
      files.add(FileNode(name: name, path: entity.path, isDirectory: false));
    }
  }
  // Directories first, then files
  return [...directories, ...files];
}
