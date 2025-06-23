import 'dart:ui';

import 'package:flutter/material.dart';

class MarkdownColors {
  final Color h1;
  final Color h2;
  final Color h3;
  final Color h4;
  final Color h5;
  final Color h6;
  final Color inlineCodeBg;
  final Color inlineCodeTxt;

  const MarkdownColors({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.inlineCodeBg,
    required this.inlineCodeTxt,
  });
}

class AppColors {
  // Define your custom color properties
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surface2;
  final Color iconColor;
  final Color tertiary;
  final Color tertiaryInv;
  final Color text;
  final Color accent;
  final Color greenText;
  final Color yellow;
  final Color redText;
  final MarkdownColors markdownColors;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.iconColor,
    required this.tertiary,
    required this.tertiaryInv,
    required this.text,
    required this.greenText,
    required this.redText,
    required this.yellow,
    required this.accent,
    required this.markdownColors,
  });
}

const lightColors = AppColors(
  primary: Color(0xFF1A98FF),
  secondary: Color(0xFF42A5F5),
  // background: Color(0xFFE4E4E6),
  background: Color(0xFFECEEF0),
  surface: Color.fromARGB(255, 215, 221, 228),
  surface2: Color.fromARGB(255, 189, 198, 209),
  iconColor: Color(0xFF57647C),
  text: Color(0xFF222222),
  tertiaryInv: Color(0xFFFFFFFF),
  tertiary: Color(0xFF000000),
  greenText: Color(0xFF14A219),
  redText: Color(0xFFF44336),
  yellow: Color.fromARGB(255, 255, 162, 0),
  accent: Color(0xFF0D92FF),
  markdownColors: MarkdownColors(
    h1: Color(0xFFE01E9C),
    h2: Color(0xFF5DAE01),
    h3: Color(0xFF178AE9),
    h4: Color(0xFFC25A35),
    h5: Colors.teal,
    h6: Color(0xFF636364),
    inlineCodeBg: Color(0xFFCFE3FF),
    inlineCodeTxt: Color(0xFF2877FF),
  ),
);

const darkColors = AppColors(
  primary: Color(0xFF269DFF),
  secondary: Color(0xFF1976D2),
  background: Color(0xFF0B121D),
  surface: Color(0xFF131D2C),
  surface2: Color.fromARGB(255, 48, 64, 87),
  iconColor: Color(0xFF8895B1),
  tertiary: Color(0xFFFFFFFF),
  tertiaryInv: Color(0xFF000000),
  text: Color(0xFFF5F5F5),
  greenText: Color(0xFF4CAF50),
  redText: Color(0xFFF44336),
  yellow: Color.fromARGB(255, 255, 217, 0),
  accent: Color.fromARGB(255, 119, 153, 255),
  markdownColors: MarkdownColors(
    h1: Color(0xFFFF5EC7),
    h2: Color(0xFF89C940),
    h3: Color(0xFF3FA9FF),
    h4: Color(0xFFB75B3A),
    h5: Colors.teal,
    h6: Colors.grey,
    inlineCodeBg: Color(0xFF252C36),
    inlineCodeTxt: Colors.blue,
  ),
);

class AppTheme {
  static const AppColors light = lightColors;
  static const AppColors dark = darkColors;

  // Get the correct AppColors based on brightness
  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  static AppColors from(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
