import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/components/notes_picker.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/main.dart';
import 'package:markdown_notes/providers/notes_provider.dart';
import 'package:markdown_notes/utils/macos_file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    final isNotFirstTime = prefs!.getBool("isNotFirstTime");
    log("isNotFirstTime: $isNotFirstTime");
    if (isNotFirstTime == null || !isNotFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPopup();
      });
    } else {
      _requestAllFilesAccessAndReadNotes().then((path) {
        log("got permission for path: $path");
        if (path != null) {
          _loadNotesDirectories(path);
        }
      });
    }
  }

  Future<String?> _pickNotesDirectory() async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Notes Directory'),
          content: const Text(
            'Please select the directory where your notes are stored.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // returns null
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedDir = await FilePicker.platform
                    .getDirectoryPath();
                if (selectedDir != null && selectedDir.isNotEmpty) {
                  Settings.location = selectedDir;
                  GoRouter.of(context).pop(selectedDir);
                }
              },
              child: const Text('Select Directory'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _requestAllFilesAccessAndReadNotes() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.manageExternalStorage
          .request();
      if (status.isGranted) {
        final location = Settings.location;
        return location.isNotEmpty ? location : await _pickNotesDirectory();
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
          final path = await _getMacosFolderBookmark(bookmark);
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

  Future<String?> _getMacosFolderBookmark(String bookmark) async {
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

  Future<void> _loadNotesDirectories(String path) async {
    final notesDirNotifier = ref.read(notesDirProvider.notifier);
    await notesDirNotifier.updateNotesDir(path);
    final selectedNotesName = prefs?.getString('selectedNotes');
    if (selectedNotesName != null) {
      final selectedNode = notesDirNotifier.findNotesDir(selectedNotesName);
      if (selectedNode != null && mounted) {
        context.go(
          '/home',
          extra: (projectNode: selectedNode, curFileNode: null),
        );
      }
    } else {
      if (mounted) {
        _showBottomSheet();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showPopup() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notes Access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To access your notes, we need permission to read files on your device. ',
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // close app
                log("User cancelled the permission request.");
                exit(0);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).pop();
                _requestAllFilesAccessAndReadNotes().then((path) {
                  log("got permission for path: $path");
                  if (path != null) {
                    prefs?.setBool("isNotFirstTime", true);
                    _loadNotesDirectories(path);
                  }
                });
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet() {
    scaffoldKey.currentState!.showBottomSheet((context) {
      return NotesPicker(
        searchController: _searchController,
        canClose: false,
        hasFocus: true,
        onPick: (node) {
          context.go('/home', extra: (projectNode: node, curFileNode: null));
        },
      );
    }, enableDrag: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Column(
        children: [Expanded(child: Center(child: CircularProgressIndicator()))],
      ),
    );
  }
}
