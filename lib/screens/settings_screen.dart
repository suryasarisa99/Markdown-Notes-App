import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:markdown_notes/data/settings.dart';
import 'package:markdown_notes/utils/macos_file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pathController = TextEditingController();
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
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      // color: Colors.grey.shade300,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                    color: Colors.grey.shade300,
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
