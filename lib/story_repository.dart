import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'models.dart';

/// Asset keys that actually shipped in this build. We consult this before ever
/// calling Image.asset, so a not-yet-supplied photo shows the painted
/// placeholder without the engine attempting (and logging) a failed fetch.
Set<String> availableAssets = <String>{};

/// Loads and parses the bundled story graph exactly once at startup, and
/// records which assets are present.
Future<Story> loadStory() async {
  final raw = await rootBundle.loadString('assets/story.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    availableAssets = manifest.listAssets().toSet();
  } catch (_) {
    availableAssets = <String>{};
  }
  return Story.fromJson(json);
}

/// True when a real image file for this path shipped in the build.
bool hasAsset(String path) =>
    path.isNotEmpty && availableAssets.contains(path);
