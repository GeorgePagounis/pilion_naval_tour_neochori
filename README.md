# Pilion Naval Tour — Neochori

An interactive, choose-your-own-adventure digital tour of **Neochori** (Pelion,
near Volos, Greece), told in the language of the sea. A guide — Lambros, the
fictional shipmate of Captain Apostolis Giannoulakis — walks you through the
village as though it were a harbour. Each stop is a photo scene with narration
that types itself in, branching choices, and "encounters" where composite voices
from the past speak to you. Built with Flutter for the web; QR codes at physical
spots deep-link to individual stops.

## Run it locally

```
flutter pub get
flutter run -d chrome
```

To open in Greek or English directly (useful for QR codes at a physical sign):

```
http://localhost:<port>/stop/mooring?lang=el
http://localhost:<port>/stop/mooring?lang=en
```

## Editing the story / the map

Everything — stops, text, choices, encounters, both languages — lives in
[`assets/story.json`](assets/story.json). You never edit Dart to change content.
See **[AUTHORING.md](AUTHORING.md)** for the full guide. Quick reference:

```
dart run tool/story_map.dart      # draw + validate the map (read-only)
dart run tool/story_edit.dart     # add/remove/rename/link stops (edits the JSON for you)
```

## Photos

Drop `stop_<id>.jpeg` files into [`assets/images/`](assets/images/) — ids are
`mooring, kalderimi, boatyard, fountain, stnicholas, lookout`. Missing photos
show a painted anchor placeholder, so nothing looks broken. Keep each file under
~400 KB / ~1600 px long edge. Re-run the app after adding photos (new assets are
picked up at build start, not on hot reload).

## Deploy to Firebase Hosting (when ready)

`firebase.json` is already configured (public dir `build/web`, single-page-app
rewrite so `/stop/:id` deep links work). One-time setup, then deploy:

```
flutter build web --release            # add --no-web-resources-cdn if the venue is offline
firebase login                         # only you can do this
firebase init hosting                  # choose "Use an existing project", keep the existing firebase.json
firebase deploy --only hosting
```

After deploy your stops live at `https://<your-site>.web.app/stop/<id>`. Generate
QR codes from those URLs with any QR generator and print them for the physical
tour. For a Greek sign vs an English sign, point them at `.../stop/<id>?lang=el`
and `.../stop/<id>?lang=en`.

## Tech notes

- Data-driven story engine (hand-rolled), `go_router` for deep links,
  `usePathUrlStrategy()` for clean URLs, `animated_text_kit` for the typewriter.
- Bundled **EB Garamond** font (full Greek glyph coverage).
- No backend, no state-management package, no audio/video (encounters are text).
- `flutter analyze` is clean and `flutter test` validates the story graph
  (every choice target resolves; no dead ends).
