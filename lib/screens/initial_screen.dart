import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_notes/components/NotesPicker.dart';
import 'package:markdown_notes/main.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/NotesProvider.dart';
import 'package:permission_handler/permission_handler.dart';
// Android persistent folder access
// macOS persistent folder access
// import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
// import 'package:saf/saf.dart';

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

  @override
  void initState() {
    super.initState();
    requestAllFilesAccessAndReadNotes().then((status) {
      log("Permission status: $status");
      if (status) {
        loadNotesDirectories();
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

  Future<bool> requestAllFilesAccessAndReadNotes() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.manageExternalStorage
          .request();
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        // await openAppSettings();
        return false; // Permission denied, return false
      } else if (status.isPermanentlyDenied) {
        log(
          "MANAGE_EXTERNAL_STORAGE permanently denied. Please go to settings.",
        );
        return await openAppSettings();
      }
      return false; // Other statuses (restricted, limited, etc.)
    }
  }

  Future<void> loadNotesDirectories() async {
    final notesDirNotifier = ref.read(notesDirProvider.notifier);
    await notesDirNotifier.updateNotesDir();
    final selectedNotesName = prefs?.getString('selectedNotes');
    if (selectedNotesName != null) {
      final selectedNode = await notesDirNotifier.findNotesDir(
        selectedNotesName,
      );
      if (selectedNode != null && mounted) {
        context.go('/home', extra: selectedNode);
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
                            context.go('/home', extra: node);
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
