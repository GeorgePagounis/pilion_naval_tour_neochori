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
                    // giving a fresh State — so the typewriter restarts and the
                    // skip/reveal flags reset automatically.
                    key: ValueKey('content-${node.id}-${lang.name}'),
                    node: node,
                    lang: lang,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        appState.visit(widget.nodeId);
        _precacheChoiceImages();
      });
    }
  }
}

/// The narration + choices column. Stateful; a fresh key (node or language
/// change) gives it a new State, so the typewriter restarts and the skip/reveal
/// flags reset on their own. One tap anywhere fast-forwards: the full narration
/// appears at once and the choices reveal immediately.
class _SceneContent extends StatefulWidget {
  const _SceneContent({
    super.key,
    required this.node,
    required this.lang,
    required this.onChoice,
  });

  final StoryNode node;
  final Lang lang;
  final void Function(String target) onChoice;

  @override
  State<_SceneContent> createState() => _SceneContentState();
}

class _SceneContentState extends State<_SceneContent> {
  bool _revealed = false; // choices visible?
  bool _skipped = false; // narration fast-forwarded to full text?

  /// Fast-forward: fill in the narration and show the choices at once.
  void _skip() {
    if (_revealed) return;
    setState(() {
      _skipped = true;
      _revealed = true;
    });
  }

  void _onNarrationFinished() {
    if (!_revealed && mounted) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final lang = widget.lang;
    final isEl = lang == Lang.el;

    return Stack(
      fit: StackFit.expand,
      children: [
        ContentColumn(
          children: [
            Text(
              node.title.of(lang),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: seafoam),
            ),
            const SizedBox(height: 14),
            // Narration: typewriter until finished/skipped, then plain full text.
            if (_skipped)
              Text(
                node.text.of(lang),
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              AnimatedTextKit(
                key: ValueKey('typer-${node.id}-${lang.name}'),
                isRepeatingAnimation: false,
                displayFullTextOnTap: true,
                totalRepeatCount: 1,
                onFinished: _onNarrationFinished,
                animatedTexts: [
                  TypewriterAnimatedText(
                    node.text.of(lang),
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    speed: const Duration(milliseconds: 32),
                  ),
                ],
              ),
            // "Tap to continue" hint while the narration is still playing.
            if (!_revealed)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app,
                        size: 16, color: foam.withValues(alpha: 0.55)),
                    const SizedBox(width: 6),
                    Text(
                      isEl ? 'Πάτα για συνέχεια' : 'Tap to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: foam.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            // Choices + encounter fade in once revealed.
            AnimatedOpacity(
              opacity: _revealed ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: IgnorePointer(
                ignoring: !_revealed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (node.encounter != null) ...[
                      const SizedBox(height: 16),
                      EncounterButton(
                        label: _encounterLabel(node.encounter!, isEl),
                        onPressed: () =>
                            showEncounter(context, node.encounter!),
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
        ),
        // Full-screen tap layer that fast-forwards. Present only while the
        // narration plays; once revealed it is removed so the choice buttons
        // (below it in the column) receive taps normally. It sits below the
        // LanguageToggle in the parent Stack, so the toggle stays clickable.
        if (!_revealed)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
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
