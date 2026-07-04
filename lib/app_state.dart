import 'dart:collection';

import 'package:flutter/foundation.dart';

enum Lang { el, en }

/// Global, app-scoped state: the chosen language and the ordered set of stops
/// the visitor has passed through. Deliberately a single mutable singleton —
/// correct and boring for a prototype, no state-management package needed.
///
/// Consume it with `ListenableBuilder(listenable: appState, ...)`.
class AppState extends ChangeNotifier {
  // Default to English — safest for an international convention audience.
  // Flip this one constant if the room turns out to be Greek-speaking.
  Lang _lang = Lang.en;
  Lang get lang => _lang;

  final LinkedHashSet<String> _visited = LinkedHashSet<String>();

  /// Stop ids in the order they were first visited.
  List<String> get visited => _visited.toList(growable: false);

  void toggleLang() {
    _lang = _lang == Lang.el ? Lang.en : Lang.el;
    notifyListeners();
  }

  void setLang(Lang lang) {
    if (lang == _lang) return;
    _lang = lang;
    notifyListeners();
  }

  /// Record a stop as visited. Notifies only on the first visit so re-entering
  /// a stop (e.g. via browser back) doesn't churn listeners.
  void visit(String id) {
    if (_visited.add(id)) {
      notifyListeners();
    }
  }

  /// Clear the trail for "Sail again". Language is intentionally preserved.
  void reset() {
    _visited.clear();
    notifyListeners();
  }
}

/// The one shared instance.
final AppState appState = AppState();
