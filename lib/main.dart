import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/theme_provider.dart';
import 'package:markdown_notes/screens/home_screen.dart';
import 'package:markdown_notes/screens/initial_screen.dart';
import 'package:markdown_notes/settings/settings_screen.dart';
import 'package:markdown_notes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? prefs;
void main() async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          final data =
              state.extra
                  as ({
                    FileNode projectNode,
                    FileNode? curFileNode,
                    String? anchor,
                  });
          return MaterialPage(
            child: HomeScreen(
              projectNode: data.projectNode,
              curFileNode: data.curFileNode,
              anchor: data.anchor,
            ),
          );
        },
      ),
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => const MaterialPage(child: InitialScreen()),
      ),

      GoRoute(
        path: '/settings',
        pageBuilder: (_, __) => const MaterialPage(child: SettingsScreen()),
      ),
    ],
  );
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // <-- transparent status bar
      statusBarIconBrightness:
          Brightness.dark, // or Brightness.light for white icons
      statusBarBrightness: Brightness.light, // for iOS
    ),
  );
  prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(child: MainApp(router: router)));
}

final darkSchema = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 72, 124, 255),
  brightness: Brightness.dark,
);
final lightSchema = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 72, 124, 255),
  brightness: Brightness.light,
);

class MainApp extends ConsumerWidget {
  final GoRouter router;
  const MainApp({required this.router, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: lightSchema,
        scaffoldBackgroundColor: AppTheme.light.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.light.background,
          foregroundColor: AppTheme.light.text,
          elevation: 0,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppTheme.light.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        drawerTheme: DrawerThemeData(backgroundColor: AppTheme.light.surface),
        dialogTheme: DialogThemeData(
          backgroundColor: AppTheme.light.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actionsPadding: const EdgeInsets.only(right: 18.0, bottom: 20.0),
        ),
        canvasColor: AppTheme.light.surface,
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(AppTheme.light.surface),
          ),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.light.iconColor),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.light.iconColor,
            iconSize: 20,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        colorScheme: darkSchema,
        scaffoldBackgroundColor: AppTheme.dark.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.dark.background,
          foregroundColor: AppTheme.dark.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppTheme.dark.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        drawerTheme: DrawerThemeData(backgroundColor: AppTheme.dark.surface),
        dialogTheme: DialogThemeData(
          backgroundColor: AppTheme.dark.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actionsPadding: const EdgeInsets.only(right: 18.0, bottom: 20.0),
        ),
        canvasColor: AppTheme.dark.surface,
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(AppTheme.dark.surface),
          ),
        ),

        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.dark.iconColor),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.dark.iconColor,
            iconSize: 20,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
