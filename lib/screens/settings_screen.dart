import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/providers/theme_provider.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_notes/utils/macos_file_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _pathController = TextEditingController();
  final _themeController = TextEditingController(text: Settings.theme);

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      activeColor: Theme.of(context).colorScheme.primary,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  void showPopupTextField(
    BuildContext context,
    String title,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter path",
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Settings.location = controller.text;
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.of(context).brightness);
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      // color: Colors.grey.shade300,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          _buildSwitch(
            'Show file history in sidebar',
            Settings.sidebarFileHistory,
            (value) {
              Settings.sidebarFileHistory = value;
              setState(() {});
            },
          ),
          _buildSwitch('Show file history in links', Settings.linkFileHistory, (
            value,
          ) {
            Settings.linkFileHistory = value;

            setState(() {});
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text("Theme", style: labelStyle),
                const Spacer(),
                DropdownMenu<String>(
                  controller: _themeController,
                  menuStyle: MenuStyle(),
                  enableFilter: false,
                  enableSearch: false,
                  width: 135,
                  alignmentOffset: const Offset(15, 8),
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    suffixIconConstraints: const BoxConstraints(
                      maxHeight: 42,
                      maxWidth: 40,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 0.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  trailingIcon: const Icon(
                    HugeIcons.strokeRoundedAbacus,
                    size: 20,
                  ),

                  // prevent to  show keyboard ( prevent edit text field )
                  requestFocusOnTap: false,
                  initialSelection: Settings.theme,
                  onSelected: (value) {
                    if (value != null) {
                      _themeController.text = value;
                      ref.read(themeModeProvider.notifier).update(value);
                    }
                  },
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(
                      value: "light",
                      label: "Light",
                      trailingIcon: Icon(Icons.sunny),
                    ),
                    DropdownMenuEntry(
                      value: "dark",
                      label: "Dark",
                      trailingIcon: Icon(Icons.brightness_3),
                    ),
                    DropdownMenuEntry(
                      value: "system",
                      label: "System",
                      trailingIcon: Icon(Icons.brightness_auto),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text("Location", style: labelStyle),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showPopupTextField(
                      context,
                      "Set Android Directory",
                      _pathController..text = Settings.location,
                    );
                  },
                  child: Text(
                    Settings.location.isEmpty ? "Not set" : Settings.location,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (Platform.isAndroid) {
                      FilePicker.platform.getDirectoryPath().then((
                        selectedDir,
                      ) {
                        if (selectedDir != null && selectedDir.isNotEmpty) {
                          Settings.location = selectedDir;
                          _pathController.text = selectedDir;
                          setState(() {});
                        }
                      });
                    } else if (Platform.isMacOS) {
                      pickMacosFolderBookmark().then((dir) {
                        setState(() {});
                      });
                    }
                  },
                  splashRadius: 24,
                  icon: Icon(
                    HugeIcons.strokeRoundedFolderEdit,
                    color: theme.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
