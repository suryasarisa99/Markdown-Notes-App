import 'package:markdown_notes/main.dart';

class Settings {
  static final bool _sidebarFileHistory = false;
  static final bool _linkFileHistory = true;

  static bool get sidebarFileHistory =>
      prefs?.getBool('sidebarFileHistory') ?? _sidebarFileHistory;
  static bool get linkFileHistory =>
      prefs?.getBool('linkFileHistory') ?? _linkFileHistory;
  static set sidebarFileHistory(bool value) {
    prefs?.setBool('sidebarFileHistory', value);
  }

  static set linkFileHistory(bool value) {
    prefs?.setBool('linkFileHistory', value);
  }
}
