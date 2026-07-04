// Story map + validator for the Neochori tour.
//
// Run it any time you edit assets/story.json:
//
//   dart run tool/story_map.dart
//
// It does three things so you never have to hold the whole branching map in
// your head:
//   1. Prints the map as a readable "from -> to (choice)" list.
//   2. Validates the graph — broken links, dead ends, unreachable stops,
//      missing translations — and exits non-zero if anything is wrong.
//   3. Writes a Mermaid diagram to build/story_map.mmd that you can paste into
//      https://mermaid.live (or any Markdown that renders Mermaid) to SEE the
//      map as boxes and arrows.
//
// Editing rule of thumb: you only ever edit ONE stop's `choices` at a time —
// "from here, where can the visitor go?" You never need to know the rest of
// the graph. Re-run this tool and it draws the current map for you.

import 'dart:convert';
import 'dart:io';

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _red = '\x1B[31m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _cyan = '\x1B[36m';

void main(List<String> args) {
  final file = File('assets/story.json');
  if (!file.existsSync()) {
    stderr.writeln('${_red}Could not find assets/story.json '
        '(run this from the project root).$_reset');
    exit(2);
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final start = (json['start'] ?? '').toString();
  final rawNodes = (json['nodes'] as Map?) ?? const {};

  // id -> list of (label, target)
  final edges = <String, List<MapEntry<String, String>>>{};
  final titles = <String, String>{};
  final missingTranslations = <String>[];

  rawNodes.forEach((key, value) {
    final id = '$key';
    final node = value as Map;
    titles[id] = _pick(node['title'], 'en').isEmpty
        ? id
        : _pick(node['title'], 'en');

    // Translation completeness (title + narration, both languages).
    for (final field in ['title', 'text']) {
      if (_pick(node[field], 'el').isEmpty || _pick(node[field], 'en').isEmpty) {
        missingTranslations.add('$id.$field');
      }
    }

    final choices = (node['choices'] as List? ?? const [])
        .whereType<Map>()
        .map((c) => MapEntry(
              _pick(c['label'], 'en'),
              (c['target'] ?? '').toString(),
            ))
        .toList();
    edges[id] = choices;
  });

  final ids = edges.keys.toSet();

  // ---- Reachability from start (via BFS) ----
  final reachable = <String>{};
  final queue = <String>[if (ids.contains(start)) start];
  while (queue.isNotEmpty) {
    final cur = queue.removeLast();
    if (!reachable.add(cur)) continue;
    for (final e in edges[cur] ?? const []) {
      if (e.value != 'end' && ids.contains(e.value)) queue.add(e.value);
    }
  }

  // ---- Collect problems ----
  final brokenLinks = <String>[];
  final deadEnds = <String>[];
  edges.forEach((id, choices) {
    if (choices.isEmpty) {
      deadEnds.add(id); // a node with no way out and it is not the 'end' card
    }
    for (final e in choices) {
      final t = e.value;
      if (t != 'end' && !ids.contains(t)) {
        brokenLinks.add('$id --"${e.key}"--> $t');
      }
    }
  });
  final unreachable = ids.difference(reachable).toList()..sort();

  // ---- 1. Readable map ----
  stdout.writeln('\n$_bold=== Neochori story map ===$_reset');
  stdout.writeln('start: $_cyan$start$_reset  '
      '(${ids.length} stops)\n');
  final ordered = _orderFromStart(start, edges, ids);
  for (final id in ordered) {
    final marker = id == start ? '⚓ ' : '  ';
    stdout.writeln('$marker$_bold$id$_reset  — ${titles[id]}');
    final choices = edges[id]!;
    if (choices.isEmpty) {
      stdout.writeln('      $_red(no choices — dead end)$_reset');
    }
    for (final e in choices) {
      final target = e.value == 'end'
          ? '${_green}THE END$_reset'
          : (ids.contains(e.value) ? e.value : '$_red${e.value} (?)$_reset');
      stdout.writeln('      → $target   $_yellow"${e.key}"$_reset');
    }
  }

  // ---- 2. Validation summary ----
  stdout.writeln('\n$_bold=== validation ===$_reset');
  var ok = true;
  ok &= _report('broken links', brokenLinks);
  ok &= _report('dead ends (no choices)', deadEnds);
  ok &= _report('unreachable stops', unreachable);
  ok &= _report('missing translations', missingTranslations);
  if (!ids.contains(start)) {
    ok = false;
    stdout.writeln('  $_red✗ start "$start" is not a real stop$_reset');
  }
  if (ok) stdout.writeln('  $_green✓ all good$_reset');

  // ---- 3. Mermaid diagram ----
  final mmd = _mermaid(start, edges, titles, ids);
  Directory('build').createSync(recursive: true);
  File('build/story_map.mmd').writeAsStringSync(mmd);
  stdout.writeln('\n${_cyan}Diagram written to build/story_map.mmd$_reset');
  stdout.writeln('Paste its contents into https://mermaid.live to see the '
      'map as boxes & arrows.\n');
  stdout.writeln(mmd);

  exit(ok ? 0 : 1);
}

/// Pull a language variant out of a {el,en} object (or a bare string).
String _pick(Object? v, String lang) {
  if (v is Map) return (v[lang] ?? '').toString();
  return (v ?? '').toString();
}

/// Nodes in a stable, start-first, breadth-ish order for readable printing.
List<String> _orderFromStart(String start,
    Map<String, List<MapEntry<String, String>>> edges, Set<String> ids) {
  final seen = <String>{};
  final out = <String>[];
  final queue = <String>[if (ids.contains(start)) start];
  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    if (!seen.add(cur)) continue;
    out.add(cur);
    for (final e in edges[cur] ?? const []) {
      if (e.value != 'end' && ids.contains(e.value) && !seen.contains(e.value)) {
        queue.add(e.value);
      }
    }
  }
  // Append any stops the traversal never reached, so they still show up.
  for (final id in ids) {
    if (!seen.contains(id)) out.add(id);
  }
  return out;
}

bool _report(String label, List<String> problems) {
  if (problems.isEmpty) return true;
  stdout.writeln('  $_red✗ $label:$_reset');
  for (final p in problems) {
    stdout.writeln('      - $p');
  }
  return false;
}

String _mermaid(String start, Map<String, List<MapEntry<String, String>>> edges,
    Map<String, String> titles, Set<String> ids) {
  final b = StringBuffer('flowchart TD\n');
  // Node declarations with human titles.
  for (final id in ids) {
    final label = (titles[id] ?? id).replaceAll('"', "'");
    b.writeln('    $id["$id\\n$label"]');
  }
  b.writeln('    END(("⚓ THE END"))');
  // Edges.
  for (final id in ids) {
    for (final e in edges[id] ?? const []) {
      final target = e.value == 'end' ? 'END' : e.value;
      final label = e.key.replaceAll('"', "'");
      b.writeln('    $id -- "$label" --> $target');
    }
  }
  b.writeln('    style $start fill:#7EC8B8,stroke:#0B2239,color:#0B2239');
  return b.toString();
}
