import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_notes/models/file_node.dart';
import 'package:markdown_notes/providers/theme_provider.dart';
import 'package:markdown_notes/screens/home_screen.dart';
import 'package:markdown_notes/screens/initial_screen.dart';
import 'package:markdown_notes/screens/file_screen.dart';
import 'package:markdown_notes/settings/settings_screen.dart';
import 'package:markdown_notes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uri_content/uri_content.dart';

typedef HomeProps = ({
  FileNode projectNode,
  FileNode? curFileNode,
  String? anchor,
});
typedef TestProps = ({String filePath, String data});

SharedPreferences? prefs;
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          final data = state.extra as HomeProps;
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
      GoRoute(
        path: '/file',
        pageBuilder: (_, state) {
          final data = state.extra as TestProps;
          return MaterialPage(
            child: FileScreen(filePath: data.filePath, data: data.data),
          );
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      return null;
    },
  );
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
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

class MainApp extends ConsumerStatefulWidget {
  final GoRouter router;

  const MainApp({required this.router, super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle the initial link
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleAppLink(uri);
    }

    // Handle subsequent links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleAppLink(uri);
    });
  }

  void _handleAppLink(Uri uri) async {
    log('Received link: $uri');
    // Check if it's a file URI and a .txt file
    try {
      if (uri.scheme == 'file' || uri.scheme == 'content') {
        // Use uri_content to read the content from either file:// or content:// URI
        final UriContent uriContent = UriContent();
        final bytes = await uriContent.from(uri);
        final fileContent = String.fromCharCodes(bytes);
        // log("File content: $fileContent");

        if (_rootNavigatorKey.currentState != null && mounted) {
          _rootNavigatorKey.currentState!.context.go(
            "/file",
            extra: (filePath: uri.path, data: fileContent),
          );
        }
      }
    } catch (e) {
      log('Error reading file: $e');
      // Handle error displaying file
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // textTheme: GoogleFonts.plusJakartaSansTextTheme(
        //   Theme.of(context).textTheme.apply(
        //     bodyColor: Colors.black,
        //     displayColor: Colors.black,
        //   ),
        // ),
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

        // textTheme: GoogleFonts.plusJakartaSansTextTheme(
        //   Theme.of(context).textTheme.apply(
        //     bodyColor: Colors.white,
        //     displayColor: Colors.white,
        //   ),
        // ),
        iconTheme: IconThemeData(color: AppTheme.dark.iconColor),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.dark.iconColor,
            iconSize: 20,
          ),
        ),
      ),
      routerConfig: widget.router,
    );
  }
}
