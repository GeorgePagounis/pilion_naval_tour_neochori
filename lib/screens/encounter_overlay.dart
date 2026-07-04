import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// Shows a "voice from the past" as a blurred, dimmed interstitial card.
/// Reached only by a deliberate tap, so it never surprises the visitor.
Future<void> showEncounter(BuildContext context, Encounter encounter) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'encounter',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, _) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: _EncounterCard(encounter: encounter),
        ),
      );
    },
  );
}

class _EncounterCard extends StatelessWidget {
  const _EncounterCard({required this.encounter});

  final Encounter encounter;

  @override
  Widget build(BuildContext context) {
    final lang = appState.lang;
    final isEl = lang == Lang.el;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: deepNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: seafoam, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 32),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_quote, color: seafoam, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${encounter.speaker.of(lang)}  ·  ${encounter.year}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: seafoam),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    encounter.provenance.of(lang),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Divider(height: 26, color: Colors.white24),
                  Text(
                    encounter.text.of(lang),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: ropeBeige,
                        foregroundColor: deepNavy,
                      ),
                      child: Text(isEl ? 'Επιστροφή' : 'Return'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
