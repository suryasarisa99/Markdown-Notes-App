import 'dart:developer';

import 'package:flutter/material.dart';

class AnchorService {
  final Map<String, GlobalKey> _anchorKeys = {};
  final Map<String, int> _anchorCounts = {};

  // Clear all anchors (call when switching documents)
  void clearAnchors() {
    _anchorKeys.clear();
    _anchorCounts.clear();
    // log("Cleared all anchor keys");
  }

  // Normalize anchor text to valid anchor format
  String normalizeAnchor(String text) {
    String anchor = text
        .trim()
        .toLowerCase()
        .replaceAll('<code>', '')
        .replaceAll('</code>', '');
    anchor = anchor.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    anchor = anchor.replaceAll(RegExp(r'\s+'), '-');
    return anchor;
  }

  // Add or get anchor key for header text
  GlobalKey addAnchorKey(String text) {
    String baseAnchor = normalizeAnchor(text);
    int count = (_anchorCounts[baseAnchor] ?? 0);
    String anchor = count == 0 ? baseAnchor : '$baseAnchor-$count';
    _anchorCounts[baseAnchor] = count + 1;

    if (!_anchorKeys.containsKey(anchor)) {
      _anchorKeys[anchor] = GlobalKey();
      // log("Created anchor key: $text => $anchor");
    }

    return _anchorKeys[anchor]!;
  }

  // Scroll to anchor
  void scrollToAnchor(String anchor) {
    final key = _anchorKeys[anchor];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        curve: Curves.easeInOut,
        // duration: const Duration(milliseconds: 300),
      );
      log("Scrolled to anchor: $anchor");
    } else {
      log("Anchor key not found: $anchor");
    }
  }

  // Get anchor key by anchor string
  GlobalKey? getAnchorKey(String anchor) {
    return _anchorKeys[anchor];
  }

  // Get all available anchors
  List<String> getAvailableAnchors() {
    return _anchorKeys.keys.toList();
  }

  // Check if anchor exists
  bool hasAnchor(String anchor) {
    return _anchorKeys.containsKey(anchor);
  }
}
