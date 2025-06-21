import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/main.dart';

Future<String?> pickMacosFolderBookmark() async {
  log("bookmark not found, requesting folder access...");
  String? folderPath = await FilePicker.platform.getDirectoryPath();
  log("picked folder path: $folderPath");
  if (folderPath == null) return null;
  final dir = Directory(folderPath);
  final newBookmark = await SecureBookmarks().bookmark(dir);
  await prefs?.setString(macosFolderBookmark, newBookmark);
  log('macOS folder bookmark saved.');
  Settings.location = folderPath;
  return folderPath;
}
