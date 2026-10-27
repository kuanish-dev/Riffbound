class_name Songs

const LEAD_IN := 2
const MY_MAX := 6
const MY_FILE := "user://my_songs.json"
const SCORES_FILE := "user://scores.json"


static var persist := true
static var _my: Array[Dictionary] = []
static var _scores := {}


static func all() -> Array:
	return SongBook.SONGS + _my


static func my() -> Array[Dictionary]:
	return _my


static func bpm_of(song: Dictionary) -> float:
	return float(song.get("bpm", Timing.DEFAULT_BPM))


static func notes_of(song: Dictionary) -> Array[Dictionary]:
	var notes := _stored_notes(song) if song.has("notes") else TabReader.read(song)
	notes.sort_custom(by_time)
	return notes


static func _stored_notes(song: Dictionary) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	for item: Dictionary in song["notes"]:
		var note := item.duplicate()
		for field: String in ["slot", "pos", "len"]:
			note[field] = int(note[field])
		notes.append(note)
	return notes


static func chords_of(song: Dictionary) -> Array[String]:
	var own: Array = song.get("chords", [])
	if own.is_empty():
		var tuning := Tuning.new()
		tuning.set_key(int(song["key"]), String(song["scale"]))
		own = Harmony.progression(tuning.key, tuning.is_minor())
	var out: Array[String] = []
	@warning_ignore("integer_division")
	for bar in end_slot(song) / Timing.SLOTS_PER_BAR:
		out.append(String(own[clampi(bar - LEAD_IN, 0, own.size() - 1)]))
	return out


static func end_slot(song: Dictionary) -> int:
	var end := LEAD_IN * Timing.SLOTS_PER_BAR
	for note in notes_of(song):
		end = maxi(end, int(note["slot"]) + int(note["len"]))
	return (ceili(float(end) / Timing.SLOTS_PER_BAR) + 1) * Timing.SLOTS_PER_BAR


static func from_layer(events: Array, tuning: Tuning, backing: String, chords: Array[String]) -> Dictionary:
	var notes := LayerSong.notes(events)
	var song_tuning := Tuning.new()
	song_tuning.set_key(tuning.key, Tuning.SCALES[tuning.scale]["id"])
	LayerSong.fit_strings(notes, song_tuning)
	var number := _next_number()
	return {"id": "my_%d" % number, "name": "Моя песня %d" % number, "number": number, "backing": backing,
		"bpm": Timing.bpm, "key": tuning.key, "scale": Tuning.SCALES[tuning.scale]["id"],
		"text": "%d нот · %s" % [notes.size(), tuning.title()], "chords": chords.slice(0, Looper.BARS), "notes": notes}


static func add_my(song: Dictionary, save := true) -> void:
	_my.append(song)
	while _my.size() > MY_MAX:
		_my.pop_front()
	if save:
		save_json(MY_FILE, _my)


static func remove_last_my(save := true) -> Dictionary:
	if _my.is_empty():
		return {}
	var removed: Dictionary = _my.pop_back()
	if save:
		save_json(MY_FILE, _my)
	return removed


static func set_my(list: Array[Dictionary]) -> void:
	_my = list.duplicate()


static func best(id: String) -> Dictionary:
	return _scores.get(id, {})


static func record(id: String, result: Dictionary, save := true) -> bool:
	if int(result["score"]) <= int(best(id).get("score", -1)):
		return false
	_scores[id] = result
	if save:
		save_json(SCORES_FILE, _scores)
	return true


static func load_saved() -> void:
	var list: Array[Dictionary] = []
	var data: Variant = load_json(MY_FILE)
	if data is Array:
		for item: Variant in data:
			if item is Dictionary and (item as Dictionary).has_all(["id", "name", "notes", "key", "scale", "backing"]):
				list.append(item)
	set_my(list)
	var scores: Variant = load_json(SCORES_FILE)
	_scores = scores if scores is Dictionary else {}


static func _next_number() -> int:
	var top := 0
	for song in _my:
		top = maxi(top, int(song.get("number", 0)))
	return top + 1


static func by_time(a: Dictionary, b: Dictionary) -> bool:
	if int(a["slot"]) != int(b["slot"]):
		return int(a["slot"]) < int(b["slot"])
	return Notes.STRINGS.find(a["string"]) < Notes.STRINGS.find(b["string"])


static func load_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null


static func save_json(path: String, data: Variant) -> void:
	if not persist:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
