import 'package:markdown_notes/main.dart';

class Settings {
  static final bool _sidebarFileHistory = false;
  static final bool _linkFileHistory = true;
  static final String _location = "/storage/emulated/0/Notes";
  static final String _theme = 'system';
  static final bool _showHiddenFiles = false;

  static bool get sidebarFileHistory =>
      prefs?.getBool('sidebarFileHistory') ?? _sidebarFileHistory;
  static bool get linkFileHistory =>
      prefs?.getBool('linkFileHistory') ?? _linkFileHistory;
  static String get location => prefs?.getString('location') ?? _location;
  static String get theme => prefs?.getString('theme') ?? _theme;
  static bool get showHiddenFiles =>
      prefs?.getBool('showHiddenFiles') ?? _showHiddenFiles;
  static set sidebarFileHistory(bool value) {
    prefs?.setBool('sidebarFileHistory', value);
  }

  static set linkFileHistory(bool value) {
    prefs?.setBool('linkFileHistory', value);
  }

  static set location(String value) {
    prefs?.setString('location', value);
  }

  static set theme(String value) {
    prefs?.setString('theme', value);
  }

  static set showHiddenFiles(bool value) {
    prefs?.setBool('showHiddenFiles', value);
  }

  static String? getLastFilePath(String path) {
    return prefs?.getString('lastFile_$path');
  }

  static setLastFilePath(String path, String filePath) {
    prefs?.setString('lastFile_$path', filePath);
  }
}
