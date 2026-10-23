class_name Difficulty
extends RefCounted

const LEVELS := [
	{"id": "novice", "name": "новичок", "about": "только сильные доли, по одной ноте, рука сама едет по грифу",
		"beats_every": 2, "offbeats_every": 0, "chords": false, "mutes": false, "techniques": false, "auto_hand": true,
		"window": 1.8, "coins": 0.3, "record": "@novice", "tint": Color(0.55, 1.0, 0.45)},
	{"id": "easy", "name": "лёгкий", "about": "+ каждая доля; рука сама едет по грифу",
		"beats_every": 1, "offbeats_every": 0, "chords": false, "mutes": false, "techniques": false, "auto_hand": true,
		"window": 1.6, "coins": 0.45, "record": "@easy", "tint": Color(0.35, 0.9, 1.0)},
	{"id": "medium", "name": "средний", "about": "+ аккорды и глушняки; руку по грифу двигаешь сам (Q/E)",
		"beats_every": 1, "offbeats_every": 0, "chords": true, "mutes": true, "techniques": false, "auto_hand": false,
		"window": 1.4, "coins": 0.6, "record": "@medium", "tint": Color(1.0, 0.85, 0.3)},
	{"id": "hard", "name": "сложный", "about": "+ легато, бенды и больше нот в пробежках",
		"beats_every": 1, "offbeats_every": 2, "chords": true, "mutes": true, "techniques": true, "auto_hand": false,
		"window": 1.2, "coins": 0.8, "record": "@hard", "tint": Color(1.0, 0.55, 0.2)},
	{"id": "expert", "name": "эксперт", "about": "все ноты, как в табе",
		"beats_every": 1, "offbeats_every": 1, "chords": true, "mutes": true, "techniques": true, "auto_hand": false,
		"window": 1.0, "coins": 1.0, "record": "", "tint": Color(1.0, 0.3, 0.5)},
]
const FILE := "user://settings.json"

static var chosen := {}
static var forced := -1


static func current() -> Dictionary:
	return LEVELS[current_index()]


static func current_index() -> int:
	return index_for(selected_id())


static func selected_id() -> String:
	var songs := Songs.all()
	return String(songs[clampi(Game.menu_index, 0, songs.size() - 1)]["id"])


static func index_for(song_id: String) -> int:
	if forced >= 0:
		return forced
	return int(chosen.get(song_id, first_unpassed(song_id)))


static func first_unpassed(song_id: String) -> int:
	for i in LEVELS.size():
		if not passed(song_id, i):
			return i
	return LEVELS.size() - 1


static func passed(song_id: String, level: int) -> bool:
	return not Songs.best(record_key(song_id, level)).is_empty()


static func best_passed(song_id: String) -> int:
	for level in range(LEVELS.size() - 1, -1, -1):
		if passed(song_id, level):
			return level
	return -1


static func record_key(song_id: String, level: int) -> String:
	return song_id + String(LEVELS[level]["record"])


static func index_of(id: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i]["id"] == id:
			return i
	return 0


static func choose(song_id: String, level: int) -> bool:
	var clamped := clampi(level, 0, LEVELS.size() - 1)
	if clamped == index_for(song_id):
		return false
	chosen[song_id] = clamped
	Songs.save_json(FILE, {"levels": chosen})
	return true


static func load_saved() -> void:
	var data: Variant = Songs.load_json(FILE)
	chosen = {}
	if data is Dictionary and data.get("levels") is Dictionary:
		for id: String in data["levels"]:
			chosen[id] = int(data["levels"][id])


static func rules_for(song: Dictionary, level: Dictionary) -> Dictionary:
	var rules := level.duplicate()
	rules.merge(song.get("keeps", {}), true)
	return rules


static func simplify(notes: Array[Dictionary], level: Dictionary) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	var last_slot := -1000
	var previous_kept := {}
	for note in notes:
		var string := String(note["string"])
		var keep := _keeps(note, last_slot, level)
		if keep:
			_simplify_technique(note, bool(level["techniques"]), bool(previous_kept.get(string, true)))
			kept.append(note)
			last_slot = int(note["slot"])
		previous_kept[string] = keep
	return kept


static func _keeps(note: Dictionary, last_slot: int, level: Dictionary) -> bool:
	var slot := int(note["slot"])
	if note["fret"] == Notes.MUTE and not level["mutes"]:
		return false
	if slot == last_slot:
		return bool(level["chords"])
	@warning_ignore("integer_division")
	var beat := slot / Timing.SLOTS_PER_BEAT
	if slot % Timing.SLOTS_PER_BEAT == 0:
		return beat % int(level["beats_every"]) == 0
	var every := int(level["offbeats_every"])
	return every > 0 and beat % every == 0


static func _simplify_technique(note: Dictionary, techniques: bool, previous_kept: bool) -> void:
	if note["legato"] and not (techniques and previous_kept):
		note["legato"] = false
		note["tech"] = ""
	if not techniques:
		note["bend"] = false
