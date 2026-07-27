extends RefCounted
class_name OpponentNames
## Random opponent names for Career mode, so each bracket round feels like a
## different player rather than an anonymous "Bot." The round-start
## announcement speaks the full name (screen-reader only, see
## MatchManager.gd/Voice.say_dynamic - too many combinations to pre-render).
## During the match itself, frequent announcements (serve/point/game/etc.)
## use just the surname, composed from small pre-rendered clips (see
## Voice.gd's NAME_KEYS/LINES) so they keep full offline fallback - that's
## only possible because LAST_NAMES is a small, fixed, known set.

const FIRST_NAMES: Array[String] = [
	"Alex", "Jordan", "Sam", "Casey", "Morgan", "Taylor", "Riley", "Jamie",
	"Drew", "Cameron", "Avery", "Quinn", "Reese", "Skyler", "Rowan", "Dakota",
	"Emerson", "Finley", "Hayden", "Jules",
]

const LAST_NAMES: Array[String] = [
	"Carter", "Bennett", "Hayes", "Mercer", "Ellison", "Whitfield", "Sorensen",
	"Delgado", "Kowalski", "Novak", "Fontaine", "Marsh", "Osei", "Larsson",
	"Vance", "Renwick", "Castillo", "Abernathy", "Nakamura", "Petrov",
]

static func random_first() -> String:
	return FIRST_NAMES[randi() % FIRST_NAMES.size()]

static func random_last() -> String:
	return LAST_NAMES[randi() % LAST_NAMES.size()]

## Voice.gd's LINES key for a given surname's pre-rendered clip - e.g.
## "Mercer" -> "name_mercer". Every entry in LAST_NAMES has a matching clip
## in both languages (see tools/generate_voice.ps1 / generate_voice_es.py).
static func name_key(surname: String) -> String:
	return "name_%s" % surname.to_lower()
