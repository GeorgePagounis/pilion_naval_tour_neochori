import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../models.dart';
import '../story_repository.dart' show hasAsset;
import '../theme.dart';
import '../widgets.dart';

/// Credits for the physical-tour team, plus the historical-sources note.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key, required this.story});

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
              final credits = story.credits;
              return ContentColumn(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.groups, size: 52, color: seafoam),
                  const SizedBox(height: 14),
                  Text(
                    credits.title.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    credits.intro.of(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  for (final person in credits.people)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          if (person.photo != null &&
                              hasAsset(person.photo!)) ...[
                            ClipOval(
                              child: Image.asset(
                                person.photo!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            person.role.of(lang),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: seafoam,
                                    fontStyle: FontStyle.normal),
                          ),
                          const SizedBox(height: 2),
                          if (person.name.isNotEmpty && person.name != '—')
                            Text(
                              person.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 26),
                  ChoiceButton(
                    icon: Icons.arrow_back,
                    label: lang == Lang.el ? 'Πίσω' : 'Back',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
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
