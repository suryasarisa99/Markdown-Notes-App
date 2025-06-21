import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:markdown_notes/data/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      activeColor: Theme.of(context).colorScheme.primary,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
