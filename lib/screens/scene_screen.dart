import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../models.dart';
import '../story_repository.dart' show hasAsset;
import '../theme.dart';
import '../widgets.dart';
import 'encounter_overlay.dart';

/// The core screen: a full-bleed scene photo (or placeholder), narration that
/// types itself in the guide's voice, then choices — and an encounter — that
/// fade in once the narration finishes.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key, required this.story, required this.nodeId});

  final Story story;
  final String nodeId;

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  bool _revealed = false;

  StoryNode get _node => widget.story[widget.nodeId]!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      appState.visit(widget.nodeId);
      _precacheChoiceImages();
    });
  }

  /// Warm the image cache for the stops this scene can lead to, so the next
  /// crossfade is instant. Missing assets throw past errorBuilder — swallow.
  void _precacheChoiceImages() {
    for (final choice in _node.choices) {
      final next = widget.story[choice.target];
      if (next != null && hasAsset(next.image)) {
        precacheImage(AssetImage(next.image), context).catchError((_) {});
      }
    }
  }

  void _go(String target) {
    context.go(target == 'end' ? '/end' : '/stop/$target');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final lang = appState.lang;
          final node = _node;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Keyed on node AND language so the switcher animates on both a
              // stop change and a language toggle ("the story retells itself").
              // Positioned.fill keeps the switcher a direct child of the Stack
              // (its fade wrapper would otherwise orphan a Positioned child).
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: SceneBackdrop(
                    key: ValueKey('bg-${node.id}-${lang.name}'),
                    node: node,
                    lang: lang,
                  ),
                ),
              ),
              const BottomScrim(),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: _SceneContent(
                    // New key on every node/lang change rebuilds the subtree,
                    // restarting the typewriter and re-hiding the choices.
                    key: ValueKey('content-${node.id}-${lang.name}'),
                    node: node,
                    lang: lang,
                    onNarrationDone: () {
                      if (mounted) setState(() => _revealed = true);
                    },
                    revealed: _revealed,
                    onChoice: _go,
                  ),
                ),
              ),
              const LanguageToggle(),
            ],
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SceneScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId) {
      _revealed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        appState.visit(widget.nodeId);
        _precacheChoiceImages();
      });
    }
  }
}

/// The narration + choices column. Stateful so its typewriter restarts cleanly
/// whenever the parent gives it a new key (node or language change).
class _SceneContent extends StatefulWidget {
  const _SceneContent({
    super.key,
    required this.node,
    required this.lang,
    required this.onNarrationDone,
    required this.revealed,
    required this.onChoice,
  });

  final StoryNode node;
  final Lang lang;
  final VoidCallback onNarrationDone;
  final bool revealed;
  final void Function(String target) onChoice;

  @override
  State<_SceneContent> createState() => _SceneContentState();
}

class _SceneContentState extends State<_SceneContent> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final lang = widget.lang;
    final isEl = lang == Lang.el;

    return ContentColumn(
      children: [
        Text(
          node.title.of(lang),
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: seafoam),
        ),
        const SizedBox(height: 14),
        // Typewriter narration. Tap anywhere on the text to skip to the end.
        AnimatedTextKit(
          key: ValueKey('typer-${node.id}-${lang.name}'),
          isRepeatingAnimation: false,
          displayFullTextOnTap: true,
          totalRepeatCount: 1,
          onFinished: () {
            if (!_done) {
              _done = true;
              widget.onNarrationDone();
            }
          },
          animatedTexts: [
            TypewriterAnimatedText(
              node.text.of(lang),
              textStyle: Theme.of(context).textTheme.bodyLarge,
              speed: const Duration(milliseconds: 32),
            ),
          ],
        ),
        // Choices + encounter fade in only after narration completes.
        AnimatedOpacity(
          opacity: widget.revealed ? 1 : 0,
          duration: const Duration(milliseconds: 500),
          child: IgnorePointer(
            ignoring: !widget.revealed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (node.encounter != null) ...[
                  const SizedBox(height: 16),
                  EncounterButton(
                    label: _encounterLabel(node.encounter!, isEl),
                    onPressed: () => showEncounter(context, node.encounter!),
                  ),
                ],
                const SizedBox(height: 8),
                for (final choice in node.choices)
                  ChoiceButton(
                    label: choice.label.of(lang),
                    onPressed: () => widget.onChoice(choice.target),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _encounterLabel(Encounter e, bool isEl) {
    final speaker = e.speaker.of(isEl ? Lang.el : Lang.en);
    return isEl
        ? 'Μια φωνή από το ${e.year} — $speaker'
        : 'A voice from ${e.year} — $speaker';
  }
}
