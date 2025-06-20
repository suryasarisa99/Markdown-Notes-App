import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/components/NotesPicker.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/main.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/NotesProvider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  FileNode? _selectedNode;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? _macosBookmark; // Store the bookmark string

  @override
  void initState() {
    super.initState();
    requestAllFilesAccessAndReadNotes().then((path) {
      log("got permission for path: $path");
      if (path != null) {
        loadNotesDirectories(path);
      }
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String filePath = result.files.single.path!;
      log('Picked file: $filePath');
      String fileContent = await File(filePath).readAsString();
      if (mounted) {
        context.push("/", extra: fileContent);
      }
    } else {
      log('No file selected');
    }
  }

  Future<String?> requestAllFilesAccessAndReadNotes() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.manageExternalStorage
          .request();
      if (status.isGranted) {
        return "";
      } else if (status.isDenied) {
        return null;
      } else if (status.isPermanentlyDenied) {
        log(
          "MANAGE_EXTERNAL_STORAGE permanently denied. Please go to settings.",
        );
        await openAppSettings();
        return null;
      }
      return null;
    } else if (Platform.isMacOS) {
      // Use SecureBookmarks to request folder access and persist bookmark
      try {
        String? bookmark = prefs?.getString(macosFolderBookmark);
        // String? bookmark = null;
        if (bookmark == null) {
          return pickMacosFolderBookmark();
        } else {
          log('macOS folder bookmark found: $bookmark');
          final path = await getMacosFolderBookmark(bookmark);
          log("resolved path: $path");
          try {
            Directory(path!).listSync();
          } catch (e) {
            return pickMacosFolderBookmark();
          }
          return path;
        }
      } catch (e) {
        log('macOS folder permission error: $e');
        return null;
      }
    }
    return null;
  }

  Future<String?> getMacosFolderBookmark(String bookmark) async {
    final resolvedDir = await SecureBookmarks().resolveBookmark(
      bookmark,
      isDirectory: true,
    );
    if (resolvedDir is Directory) {
      return resolvedDir.path;
    } else {
      await prefs?.remove(macosFolderBookmark);
      return null;
    }
  }

  Future<String?> pickMacosFolderBookmark() async {
    log("bookmark not found, requesting folder access...");
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    log("picked folder path: $folderPath");
    if (folderPath == null) return null;
    final dir = Directory(folderPath);
    final newBookmark = await SecureBookmarks().bookmark(dir);
    await prefs?.setString(macosFolderBookmark, newBookmark);
    log('macOS folder bookmark saved.');
    return folderPath;
  }

  Future<void> loadNotesDirectories(String path) async {
    final notesDirNotifier = ref.read(notesDirProvider.notifier);
    await notesDirNotifier.updateNotesDir(path);
    final selectedNotesName = prefs?.getString('selectedNotes');
    if (selectedNotesName != null) {
      final selectedNode = await notesDirNotifier.findNotesDir(
        selectedNotesName,
      );
      if (selectedNode != null && mounted) {
        context.go(
          '/home',
          extra: (projectNode: selectedNode, curFileNode: null),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log("rebuilding...");
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: const Text('Select File')),
      body: Row(
        children: [
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      scaffoldKey.currentState!.showBottomSheet((context) {
                        return NotesPicker(
                          searchController: _searchController,
                          onPick: (node) {
                            context.go('/home', extra: (projectNode: node));
                          },
                        );
                      });
                    },
                    child: const Text('Select File'),
                  ),
                  _selectedNode == null
                      ? const Text('No file selected')
                      : Text("selected: ${_selectedNode!.name}"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
