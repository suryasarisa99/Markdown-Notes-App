import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markdown_notes/theme.dart';
import 'package:markdown_widget/markdown_widget.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String data = "";

  void _pickFile() {
    FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false)
        .then((result) {
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;
            final text = File(file.path!).readAsStringSync();
            setState(() {
              data = text;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;
    final theme = AppTheme.from(brightness);
    final config = isDarkMode
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Column(
        children: [
          const Text('This is a test screen.'),
          ElevatedButton(
            onPressed: () {
              _pickFile();
            },
            child: const Text('Go Back'),
          ),
          if (data.isNotEmpty)
            Expanded(
              child: MarkdownWidget(
                data: data,
                config: config.copy(
                  configs: [
                    H1Config(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
