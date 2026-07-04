import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Closing screen: "the path you sailed" — the visited stops in order, joined
/// by a rope line, with an option to sail again.
class EndScreen extends StatelessWidget {
  const EndScreen({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1C2E), deepNavy, Color(0xFF12405B)],
              ),
            ),
          ),
          const BottomScrim(),
          ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              final lang = appState.lang;
              final visited = appState.visited;
              return ContentColumn(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.anchor, size: 56, color: seafoam),
                  const SizedBox(height: 16),
                  Text(
                    story.end.title.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 20),
                  _RouteList(story: story, visited: visited, lang: lang),
                  const SizedBox(height: 20),
                  Text(
                    story.end.text.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 26),
                  ChoiceButton(
                    icon: Icons.replay,
                    label: lang == Lang.el ? 'Ξανά ταξίδι' : 'Sail again',
                    onPressed: () {
                      appState.reset();
                      context.go('/');
                    },
                  ),
                  TextButton(
                    onPressed: () => context.go('/credits'),
                    child: Text(
                      lang == Lang.el ? 'Το πλήρωμα' : 'The crew',
                      style: const TextStyle(color: ropeBeige, fontSize: 16),
                    ),
                  ),
                ],
              );
            },
          ),
          const LanguageToggle(),
        ],
      ),
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({
    required this.story,
    required this.visited,
    required this.lang,
  });

  final Story story;
  final List<String> visited;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final stops = visited
        .map((id) => story[id])
        .whereType<StoryNode>()
        .toList(growable: false);

    if (stops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < stops.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(Icons.anchor, size: 20, color: ropeBeige),
                    if (i != stops.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: ropeBeige.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    stops[i].title.of(lang),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
