import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app_state.dart';
import 'models.dart';
import 'router.dart';
import 'story_repository.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs (/stop/mooring, no '#') so printed QR codes are tidy. The
  // Firebase SPA rewrite serves index.html for every path.
  usePathUrlStrategy();
  // Optional ?lang=el / ?lang=en so a QR at a physical spot can open the tour
  // in a chosen language (e.g. a Greek sign and an English sign side by side).
  final langParam = Uri.base.queryParameters['lang'];
  if (langParam == 'el') appState.setLang(Lang.el);
  if (langParam == 'en') appState.setLang(Lang.en);
  final story = await loadStory();
  runApp(NeochoriTourApp(story: story));
}

class NeochoriTourApp extends StatelessWidget {
  const NeochoriTourApp({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Neochori Naval Tour',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: buildRouter(story),
    );
  }
}
