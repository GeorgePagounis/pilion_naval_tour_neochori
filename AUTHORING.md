# Editing the tour — where everything lives

**The whole tour is one file: [`assets/story.json`](assets/story.json).**
Text, choices, encounters, both languages, and the map (which stop leads where)
all live there. You never edit Dart code to change the story.

Two helper scripts sit next to it:

| File | What it does | Edit it? |
|---|---|---|
| `assets/story.json` | **The story + the map.** Source of truth. | ✅ Yes — this is where you change things |
| `tool/story_map.dart` | **Views & validates** the map. Read-only. | ❌ No — it just draws what's in the JSON |
| `tool/story_edit.dart` | **Commands** to add/remove/rewire stops for you | ❌ No — you run it, you don't edit it |

After any change, run this to see the map and catch mistakes:

```
dart run tool/story_map.dart
```

Then restart the app (`flutter run -d chrome`) to see it live.

---

## 1. The shape of a stop

Each stop is one entry under `"nodes"`:

```jsonc
"boatyard": {                                   // <- the stop id (name it after the PLACE)
  "image": "assets/images/stop_boatyard.jpeg",  // photo (optional — placeholder if missing)
  "title": { "el": "Ο Ταρσανάς", "en": "The Carpenter's Yard" },
  "text":  { "el": "Μυρίζει πίσσα…", "en": "It smells of tar…" },   // the narration
  "encounter": {                                // OPTIONAL — a voice from the past
    "speaker":    { "el": "Λάμπρος…", "en": "Lambros…" },
    "year": 1910,
    "provenance": { "el": "Επινοημένη φωνή…", "en": "Invented voice…" },
    "text":       { "el": "Τον Αποστόλη…", "en": "I knew Apostolis…" }
  },
  "choices": [                                  // <- THIS is the map: where this stop leads
    { "label": { "el": "…", "en": "Carry the votive up" }, "target": "stnicholas" },
    { "label": { "el": "…", "en": "Climb to the lookout" }, "target": "lookout" }
  ]
}
```

## 2. The map = the `choices`

You never track the whole map in your head. Each stop only knows **its own exits**:
a `choices` list where every choice has a button `label` (el/en) and a `target`
(the id of the next stop, or the special word `"end"` to finish the tour).

- One stop → many stops: add more entries to its `choices`.
- Many stops → one stop: give several stops a choice with the same `target`.
- The opening stop: the top-level `"start"` field.

Your example ("stop 2 → 3 and 6; 3 and 6 → 4") is just:

```jsonc
"two":  { …, "choices": [ {"…","target":"three"}, {"…","target":"six"} ] },
"three":{ …, "choices": [ {"…","target":"four"} ] },
"six":  { …, "choices": [ {"…","target":"four"} ] }
```

Going *backwards* needs no setup — the browser Back button already does it.

## 3. Naming stops — name the PLACE, never the route

Use short, lowercase, place-based ids: `mooring`, `boatyard`, `lookout`.

**Do not** encode the route in the name (like `stop2_to_3_and_6`). Reasons:
- The connections already live in `choices` — a name that repeats them is a second
  source of truth that will disagree the moment you rewire one arrow.
- You'd have to rename the stop (and its photo, and every reference) every time the
  route changes. A place name never has to change.
- `dart run tool/story_map.dart` already shows you the routing, drawn from the JSON.

## 4. Changing the map with commands (no JSON by hand)

Run from the project root:

```
dart run tool/story_edit.dart add lookout "The Lookout" "Η Βίγλα"
dart run tool/story_edit.dart link boatyard lookout "Climb to the lookout" "Ανέβα στη βίγλα"
dart run tool/story_edit.dart link lookout end "Cast off" "Σαλπάρισε"
dart run tool/story_edit.dart unlink boatyard lookout
dart run tool/story_edit.dart rename boatyard tarsanas     # renames it EVERYWHERE at once
dart run tool/story_edit.dart remove lookout               # also drops choices pointing to it
dart run tool/story_edit.dart set-start mooring
```

Every command backs up the file to `assets/story.json.bak`, then re-draws and
re-validates the map. Run `dart run tool/story_edit.dart` with no arguments for
the full list.

## 5. Photos

Drop `stop_<id>.jpeg` files into `assets/images/` (see the note in that folder).
A stop with no photo shows a painted anchor placeholder automatically. After
adding photos, fully stop and re-run the app — new asset files are picked up at
build start, not on hot reload.
