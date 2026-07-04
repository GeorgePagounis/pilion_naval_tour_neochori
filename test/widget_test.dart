// Smoke test for the Neochori naval tour.
//
// The app loads its story from an asset at startup, so a full pump-the-app test
// would need asset bundling. Here we just verify the story graph parses and the
// core model contracts hold — enough to catch a broken JSON edit before a demo.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pilion_naval_tour_neochori/app_state.dart';
import 'package:pilion_naval_tour_neochori/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('story.json parses and is internally consistent', () async {
    final raw = await rootBundle.loadString('assets/story.json');
    final story = Story.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    // Start node exists.
    expect(story.has(story.start), isTrue);

    // Every choice target is either a real node or the reserved 'end'.
    for (final node in story.nodes.values) {
      for (final choice in node.choices) {
        expect(
          choice.target == 'end' || story.has(choice.target),
          isTrue,
          reason: 'node "${node.id}" points at unknown target '
              '"${choice.target}"',
        );
      }
    }

    // Bilingual copy is present on every node.
    for (final node in story.nodes.values) {
      expect(node.title.el.isNotEmpty && node.title.en.isNotEmpty, isTrue,
          reason: 'node "${node.id}" missing a title translation');
      expect(node.text.el.isNotEmpty && node.text.en.isNotEmpty, isTrue,
          reason: 'node "${node.id}" missing narration translation');
    }
  });

  test('AppState records visited stops in order, once each', () {
    final s = AppState();
    s.visit('mooring');
    s.visit('fountain');
    s.visit('mooring'); // duplicate — should not reorder or repeat
    expect(s.visited, ['mooring', 'fountain']);

    s.reset();
    expect(s.visited, isEmpty);
    expect(s.lang, Lang.en); // language preserved across reset
  });
}
