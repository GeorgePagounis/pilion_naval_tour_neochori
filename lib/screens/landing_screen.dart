import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Title screen: the guide introduces himself and invites you to cast off.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.story});

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
          const Positioned.fill(child: _CompassWatermark()),
          const BottomScrim(),
          ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              final lang = appState.lang;
              return ContentColumn(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.anchor, size: 64, color: seafoam),
                  const SizedBox(height: 20),
                  Text(
                    story.title.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    story.subtitle.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: seafoam),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    story.intro.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  ChoiceButton(
                    icon: Icons.sailing,
                    label: lang == Lang.el ? 'Σαλπάρουμε' : 'Cast off',
                    onPressed: () => context.go('/stop/${story.start}'),
                  ),
                  const SizedBox(height: 4),
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

class _CompassWatermark extends StatelessWidget {
  const _CompassWatermark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.06,
        child: Icon(Icons.explore,
            size: MediaQuery.of(context).size.shortestSide * 0.9,
            color: foam),
      ),
    );
  }
}
