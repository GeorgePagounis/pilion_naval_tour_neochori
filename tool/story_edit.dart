// Story editor for the Neochori tour — add / remove / rename / rewire stops
// without hand-editing JSON. Every command edits assets/story.json in place,
// keeps a timestamped-free backup at assets/story.json.bak, then re-draws and
// re-validates the map so you immediately see the result.
//
// Usage (run from the project root):
//
//   dart run tool/story_edit.dart add <id> "<EN title>" "<EL title>"
//       Add a new blank stop. Fill in its narration/encounter in the JSON
//       afterwards; it starts with placeholder text and no choices.
//
//   dart run tool/story_edit.dart link <from> <to> "<EN label>" "<EL label>"
//       Add a choice from one stop to another. <to> may be another stop id or
//       the reserved word `end` (finish the tour).
//
//   dart run tool/story_edit.dart unlink <from> <to>
//       Remove the choice from <from> to <to>.
//
//   dart run tool/story_edit.dart rename <oldId> <newId>
//       Rename a stop everywhere at once: the stop itself, every choice that
//       points to it, its image path, and the start marker if needed. This is
//       why stop ids are named after the PLACE, not their position — the name
//       never has to change when you rewire the route.
//
//   dart run tool/story_edit.dart remove <id>
//       Delete a stop and automatically drop every choice that pointed to it.
//
//   dart run tool/story_edit.dart set-start <id>
//       Choose which stop the tour opens on.
//
// After any command, run `dart run tool/story_map.dart` any time to see the map
// again (this editor runs it for you automatically once).

import 'dart:convert';
import 'dart:io';

final _file = File('assets/story.json');

void main(List<String> args) {
  if (args.isEmpty) {
    _usageAndExit();
  }
  if (!_file.existsSync()) {
    stderr.writeln('Could not find assets/story.json (run from project root).');
    exit(2);
  }

  final story = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
  final nodes = (story['nodes'] as Map).cast<String, dynamic>();
  final cmd = args[0];

  switch (cmd) {
    case 'add':
      _needArgs(args, 4, 'add <id> "<EN title>" "<EL title>"');
      _add(nodes, args[1], args[2], args[3]);
    case 'remove':
      _needArgs(args, 2, 'remove <id>');
      _remove(nodes, args[1]);
    case 'rename':
      _needArgs(args, 3, 'rename <oldId> <newId>');
      _rename(story, nodes, args[1], args[2]);
    case 'link':
      _needArgs(args, 5, 'link <from> <to> "<EN label>" "<EL label>"');
      _link(nodes, args[1], args[2], args[3], args[4]);
    case 'unlink':
      _needArgs(args, 3, 'unlink <from> <to>');
      _unlink(nodes, args[1], args[2]);
    case 'set-start':
      _needArgs(args, 2, 'set-start <id>');
      _setStart(story, nodes, args[1]);
    default:
      _usageAndExit();
  }

  _save(story);
  stdout.writeln('\n✓ Saved. Backup at assets/story.json.bak\n');
  // Re-draw + re-validate so you see the result immediately.
  final result = Process.runSync('dart', ['run', 'tool/story_map.dart']);
  stdout.write(result.stdout);
  if (result.exitCode != 0) {
    stderr.writeln('\n⚠  The map tool reported problems above — fix them before '
        'demoing.');
  }
}

void _add(Map<String, dynamic> nodes, String id, String en, String el) {
  if (nodes.containsKey(id)) {
    _fail('A stop with id "$id" already exists.');
  }
  _requireValidId(id);
  nodes[id] = {
    'image': 'assets/images/stop_$id.jpeg',
    'title': {'el': el, 'en': en},
    'text': {
      'el': 'TODO: αφήγηση για το $el.',
      'en': 'TODO: narration for $en.',
    },
    'choices': <dynamic>[],
  };
  stdout.writeln('Added stop "$id". It has no choices yet — use `link` to '
      'connect it, and edit its narration in assets/story.json.');
}

void _remove(Map<String, dynamic> nodes, String id) {
  if (!nodes.containsKey(id)) _fail('No stop with id "$id".');
  nodes.remove(id);
  // Drop any choices that pointed at the removed stop.
  var pruned = 0;
  for (final node in nodes.values) {
    final choices = (node as Map)['choices'] as List? ?? [];
    final before = choices.length;
    choices.removeWhere((c) => (c as Map)['target'] == id);
    pruned += before - choices.length;
  }
  stdout.writeln('Removed "$id" and $pruned inbound choice(s) that pointed to '
      'it.');
}

void _rename(
    Map<String, dynamic> story, Map<String, dynamic> nodes, String oldId,
    String newId) {
  if (!nodes.containsKey(oldId)) _fail('No stop with id "$oldId".');
  if (nodes.containsKey(newId)) _fail('A stop with id "$newId" already exists.');
  _requireValidId(newId);

  // Rebuild the nodes map preserving order, swapping the key.
  final rebuilt = <String, dynamic>{};
  nodes.forEach((k, v) {
    rebuilt[k == oldId ? newId : k] = v;
  });
  nodes
    ..clear()
    ..addAll(rebuilt);

  // Point the image at the new id if it still uses the default pattern.
  final node = nodes[newId] as Map;
  final img = (node['image'] ?? '').toString();
  if (img == 'assets/images/stop_$oldId.jpeg' || img.isEmpty) {
    node['image'] = 'assets/images/stop_$newId.jpeg';
  }

  // Repoint every choice target.
  var repointed = 0;
  for (final n in nodes.values) {
    for (final c in ((n as Map)['choices'] as List? ?? [])) {
      if ((c as Map)['target'] == oldId) {
        c['target'] = newId;
        repointed++;
      }
    }
  }

  // Update start if needed.
  if (story['start'] == oldId) story['start'] = newId;

  stdout.writeln('Renamed "$oldId" → "$newId" ($repointed choice target(s) '
      'updated). Remember to rename the photo file to stop_$newId.jpeg.');
}

void _link(Map<String, dynamic> nodes, String from, String to, String en,
    String el) {
  if (!nodes.containsKey(from)) _fail('No stop with id "$from".');
  if (to != 'end' && !nodes.containsKey(to)) {
    _fail('Target "$to" is not a stop (use an existing id or `end`).');
  }
  final choices = (nodes[from] as Map)['choices'] as List;
  if (choices.any((c) => (c as Map)['target'] == to)) {
    _fail('"$from" already has a choice leading to "$to".');
  }
  choices.add({
    'label': {'el': el, 'en': en},
    'target': to,
  });
  stdout.writeln('Linked "$from" → "$to".');
}

void _unlink(Map<String, dynamic> nodes, String from, String to) {
  if (!nodes.containsKey(from)) _fail('No stop with id "$from".');
  final choices = (nodes[from] as Map)['choices'] as List;
  final before = choices.length;
  choices.removeWhere((c) => (c as Map)['target'] == to);
  if (choices.length == before) {
    _fail('"$from" had no choice leading to "$to".');
  }
  stdout.writeln('Unlinked "$from" → "$to".');
}

void _setStart(
    Map<String, dynamic> story, Map<String, dynamic> nodes, String id) {
  if (!nodes.containsKey(id)) _fail('No stop with id "$id".');
  story['start'] = id;
  stdout.writeln('Start stop is now "$id".');
}

void _save(Map<String, dynamic> story) {
  _file.copySync('${_file.path}.bak');
  const encoder = JsonEncoder.withIndent('  ');
  _file.writeAsStringSync('${encoder.convert(story)}\n');
}

void _requireValidId(String id) {
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
    _fail('Stop id "$id" is invalid. Use lowercase letters, numbers and '
        'underscores only (name it after the PLACE, e.g. "boatyard").');
  }
}

void _needArgs(List<String> args, int n, String shape) {
  if (args.length < n) _fail('Usage: dart run tool/story_edit.dart $shape');
}

Never _fail(String msg) {
  stderr.writeln('✗ $msg');
  exit(1);
}

Never _usageAndExit() {
  stdout.writeln('''
Story editor — edit the tour map with single commands.

  add <id> "<EN title>" "<EL title>"        add a new blank stop
  link <from> <to> "<EN label>" "<EL label>"  connect two stops (<to> or `end`)
  unlink <from> <to>                        remove a connection
  rename <oldId> <newId>                    rename a stop everywhere at once
  remove <id>                               delete a stop + inbound links
  set-start <id>                            choose the opening stop

Ids are named after the PLACE (e.g. mooring, boatyard) and never encode the
route — connections live only in each stop's choices, and this tool keeps them
consistent. Run `dart run tool/story_map.dart` any time to see the map.
''');
  exit(0);
}
