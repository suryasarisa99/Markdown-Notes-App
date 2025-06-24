import 'package:markdown_notes/main.dart';

class MdSettings {
  static double get codeBlockFontSize =>
      prefs?.getDouble('md_code_block_font_size') ?? 14;
  static double get codePageFontSize =>
      prefs?.getDouble('md_code_page_font_size') ?? 14;

  static set codeBlockFontSize(double value) {
    prefs?.setDouble('md_code_block_font_size', value);
  }

  static set codePageFontSize(double value) {
    prefs?.setDouble('md_code_page_font_size', value);
  }
}
