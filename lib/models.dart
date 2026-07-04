import 'app_state.dart' show Lang;

/// A string with Greek + English variants. All user-facing copy in the story
/// JSON is stored this way so content edits never touch Dart.
class LocalizedText {
  const LocalizedText({required this.el, required this.en});

  final String el;
  final String en;

  String of(Lang lang) => lang == Lang.el ? el : en;

  /// Tolerant of missing keys — an absent field becomes an empty string rather
  /// than throwing, so a half-written story node still renders.
  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedText(
        el: (json['el'] ?? '').toString(),
        en: (json['en'] ?? '').toString(),
      );
    }
    // A bare string (not localized) is used for both languages.
    final s = (json ?? '').toString();
    return LocalizedText(el: s, en: s);
  }

  bool get isEmpty => el.isEmpty && en.isEmpty;
}

class Choice {
  const Choice({required this.label, required this.target});

  final LocalizedText label;
  final String target;

  factory Choice.fromJson(Map json) => Choice(
        label: LocalizedText.fromJson(json['label']),
        target: (json['target'] ?? '').toString(),
      );
}

/// A "voice from the past" — a composite/fictional character. The [provenance]
/// line is shown to the visitor and states plainly that the voice is composed.
class Encounter {
  const Encounter({
    required this.speaker,
    required this.year,
    required this.provenance,
    required this.text,
  });

  final LocalizedText speaker;
  final int year;
  final LocalizedText provenance;
  final LocalizedText text;

  factory Encounter.fromJson(Map json) => Encounter(
        speaker: LocalizedText.fromJson(json['speaker']),
        year: (json['year'] is int)
            ? json['year'] as int
            : int.tryParse('${json['year']}') ?? 0,
        provenance: LocalizedText.fromJson(json['provenance']),
        text: LocalizedText.fromJson(json['text']),
      );
}

class StoryNode {
  const StoryNode({
    required this.id,
    required this.image,
    required this.title,
    required this.text,
    required this.choices,
    this.encounter,
  });

  final String id;
  final String image;
  final LocalizedText title;
  final LocalizedText text;
  final List<Choice> choices;
  final Encounter? encounter;

  factory StoryNode.fromJson(String id, Map json) => StoryNode(
        id: id,
        image: (json['image'] ?? '').toString(),
        title: LocalizedText.fromJson(json['title']),
        text: LocalizedText.fromJson(json['text']),
        encounter: json['encounter'] is Map
            ? Encounter.fromJson(json['encounter'] as Map)
            : null,
        choices: (json['choices'] as List? ?? const [])
            .whereType<Map>()
            .map(Choice.fromJson)
            .toList(growable: false),
      );
}

class CreditPerson {
  const CreditPerson({required this.role, required this.name, this.photo});

  final LocalizedText role;
  final String name;

  /// Optional team photo path (e.g. assets/images/team_guides.jpeg). Shown as
  /// an avatar only if the file shipped; otherwise the entry is text-only.
  final String? photo;

  factory CreditPerson.fromJson(Map json) => CreditPerson(
        role: LocalizedText.fromJson(json['role']),
        name: (json['name'] ?? '').toString(),
        photo: json['photo']?.toString(),
      );
}

/// The closing "path you sailed" screen copy.
class EndCard {
  const EndCard({required this.title, required this.text});

  final LocalizedText title;
  final LocalizedText text;

  factory EndCard.fromJson(Map? json) => EndCard(
        title: LocalizedText.fromJson(json?['title']),
        text: LocalizedText.fromJson(json?['text']),
      );
}

class Credits {
  const Credits({
    required this.title,
    required this.intro,
    required this.people,
  });

  final LocalizedText title;
  final LocalizedText intro;
  final List<CreditPerson> people;

  factory Credits.fromJson(Map? json) => Credits(
        title: LocalizedText.fromJson(json?['title']),
        intro: LocalizedText.fromJson(json?['intro']),
        people: (json?['people'] as List? ?? const [])
            .whereType<Map>()
            .map(CreditPerson.fromJson)
            .toList(growable: false),
      );
}

/// The whole immutable story graph, loaded once at startup.
class Story {
  const Story({
    required this.start,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.guideNote,
    required this.nodes,
    required this.end,
    required this.credits,
  });

  final String start;
  final LocalizedText title;
  final LocalizedText subtitle;
  final LocalizedText intro;
  final LocalizedText guideNote;
  final Map<String, StoryNode> nodes;
  final EndCard end;
  final Credits credits;

  /// Look up a node by id; returns null for unknown ids (router handles the
  /// redirect). The reserved id 'end' is intentionally not a node.
  StoryNode? operator [](String id) => nodes[id];

  bool has(String id) => nodes.containsKey(id);

  factory Story.fromJson(Map<String, dynamic> json) {
    final rawNodes = (json['nodes'] as Map?) ?? const {};
    final nodes = <String, StoryNode>{};
    rawNodes.forEach((key, value) {
      if (value is Map) {
        nodes['$key'] = StoryNode.fromJson('$key', value);
      }
    });
    return Story(
      start: (json['start'] ?? '').toString(),
      title: LocalizedText.fromJson(json['title']),
      subtitle: LocalizedText.fromJson(json['subtitle']),
      intro: LocalizedText.fromJson(json['intro']),
      guideNote: LocalizedText.fromJson(json['guideNote']),
      nodes: nodes,
      end: EndCard.fromJson(json['end'] as Map?),
      credits: Credits.fromJson(json['credits'] as Map?),
    );
  }
}
