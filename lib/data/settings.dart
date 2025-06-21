import 'package:markdown_notes/main.dart';

class Settings {
  static final bool _sidebarFileHistory = false;
  static final bool _linkFileHistory = true;
  static final String _location = "/storage/emulated/0/Notes";
  static final String _theme = 'system';

  static bool get sidebarFileHistory =>
      prefs?.getBool('sidebarFileHistory') ?? _sidebarFileHistory;
  static bool get linkFileHistory =>
      prefs?.getBool('linkFileHistory') ?? _linkFileHistory;
  static String get location => prefs?.getString('location') ?? _location;
  static String get theme => prefs?.getString('theme') ?? _theme;

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
}
