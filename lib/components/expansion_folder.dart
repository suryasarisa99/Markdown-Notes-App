import 'package:flutter/material.dart';

class ExpansionFolder extends StatefulWidget {
  final Widget title;
  final List<Widget> children;
  const ExpansionFolder({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  State<ExpansionFolder> createState() => _ExpansionFolderState();
}

class _ExpansionFolderState extends State<ExpansionFolder> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: widget.title,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(children: widget.children),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
