import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_notes/constants.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/screens/home_screen.dart';
import 'package:markdown_notes/screens/initial_screen.dart';
import 'package:markdown_notes/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? prefs;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(child: const MainApp()));
}

final darkSchema = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 72, 124, 255),
  brightness: Brightness.dark,
);
final lightSchema = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 72, 124, 255),
  brightness: Brightness.light,
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // darkTheme: ThemeData.dark(useMaterial3: false),
      theme: ThemeData(useMaterial3: false, colorScheme: lightSchema),
      darkTheme: ThemeData(
        useMaterial3: false,
        colorScheme: darkSchema,
        scaffoldBackgroundColor: scaffoldDarkBackgroundColor,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) {
        final data =
            state.extra as ({FileNode projectNode, FileNode? curFileNode});
        return MaterialPage(
          child: HomeScreen(
            projectNode: data.projectNode,
            curFileNode: data.curFileNode,
          ),
        );
      },
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        return MaterialPage(child: InitialScreen());
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        return MaterialPage(child: SettingsScreen());
      },
    ),
  ],
);
