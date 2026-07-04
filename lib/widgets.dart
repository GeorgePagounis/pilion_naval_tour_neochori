import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'story_repository.dart' show hasAsset;
import 'theme.dart';

/// Full-bleed scene background: the stop photo if it shipped, otherwise a
/// painted naval placeholder so a missing `stop_<id>.jpeg` looks intentional,
/// not broken. Returns a plain filling widget (NOT a Positioned) so it can sit
/// safely inside an AnimatedSwitcher; the caller pins it with Positioned.fill.
class SceneBackdrop extends StatelessWidget {
  const SceneBackdrop({super.key, required this.node, required this.lang});

  final StoryNode node;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: hasAsset(node.image)
          ? Image.asset(
              node.image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  PlaceholderScene(title: node.title.of(lang)),
            )
          : PlaceholderScene(title: node.title.of(lang)),
    );
  }
}

/// A painted stand-in for a not-yet-supplied photo: a navy→seafoam gradient,
/// a faint anchor + waves motif, and the stop's name.
class PlaceholderScene extends StatelessWidget {
  const PlaceholderScene({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [deepNavy, Color(0xFF12405B), seafoam],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _NavalMotifPainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.anchor,
                    size: 72, color: foam.withValues(alpha: 0.85)),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: foam.withValues(alpha: 0.95)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavalMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = foam.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // A few stylised wave lines across the lower third.
    for (int row = 0; row < 3; row++) {
      final y = size.height * (0.62 + row * 0.12);
      final path = Path()..moveTo(0, y);
      final wavelength = size.width / 6;
      for (double x = 0; x <= size.width; x += wavelength) {
        path.relativeQuadraticBezierTo(
            wavelength / 4, -14, wavelength / 2, 0);
        path.relativeQuadraticBezierTo(
            wavelength / 4, 14, wavelength / 2, 0);
      }
      canvas.drawPath(path, paint);
    }

    // A faint compass ring, top-right.
    final c = Offset(size.width * 0.82, size.height * 0.2);
    final r = math.min(size.width, size.height) * 0.12;
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c, r * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom scrim so text stays readable over any photo.
class BottomScrim extends StatelessWidget {
  const BottomScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0x330B2239), deepNavyScrim],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

/// The single responsive rule, applied on every screen: a centered, phone-width
/// column pinned to the bottom, scrollable if it overflows. On a phone it is the
/// screen; on a projector the photo breathes on the sides.
class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.children,
    this.alignment = Alignment.bottomCenter,
  });

  final List<Widget> children;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width rope-coloured choice button.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.sailing,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: ropeBeige,
          foregroundColor: deepNavy,
          minimumSize: const Size.fromHeight(54),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// A seafoam-outlined button that opens a "voice from the past" encounter.
class EncounterButton extends StatelessWidget {
  const EncounterButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.record_voice_over, size: 20),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 17)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: seafoam,
          minimumSize: const Size.fromHeight(52),
          alignment: Alignment.centerLeft,
          side: const BorderSide(color: seafoam, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// Top-right "ΕΛ | EN" toggle, shown on every screen.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              final isEl = appState.lang == Lang.el;
              return Material(
                color: deepNavyScrim,
                shape: StadiumBorder(
                  side: BorderSide(color: foam.withValues(alpha: 0.4)),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: appState.toggleLang,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LangChip(text: 'ΕΛ', active: isEl),
                        Text('  |  ',
                            style: TextStyle(
                                color: foam.withValues(alpha: 0.5))),
                        _LangChip(text: 'EN', active: !isEl),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: active ? seafoam : foam.withValues(alpha: 0.6),
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
