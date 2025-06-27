import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  final String data;
  const TestScreen({required this.data, super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Center(
        child: Text(widget.data, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
