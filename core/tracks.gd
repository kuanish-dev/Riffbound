class_name Tracks

const DIR_NAME := "Riffbound"
const MEMORY_FILE := "user://user_tracks.json"
const LOADERS := {"ogg": "AudioStreamOggVorbis", "mp3": "AudioStreamMP3", "wav": "AudioStreamWAV"}
const TAIL := 0.05
const BUILT_IN := [
	{"id": "rock_theme_3", "name": "Rock Theme 3", "author": "Umplix", "file": "res://assets/tracks/rock_theme_3.ogg",
		"bpm": 120.0, "bars": 32, "offset": 0.01, "key": 2, "scale": "minor_pentatonic",
		"chords": "Gm|F|A|Dm|Gm|F|A|Dm|Gm|F|C|Dm|Gm|F|A|C|Gm|F|Am|Dm|Gm|F|Am|Dm|Gm|F|C|Dm|Gm|F|C|Dm"},
	{"id": "rocky_loop", "name": "Rocky Musicloop", "author": "johndekale", "file": "res://assets/tracks/rocky_loop.ogg",
		"bpm": 90.0, "bars": 19, "offset": 0.01, "key": 0, "scale": "minor_pentatonic",
		"chords": "Cm|Cm|Cm|Cm|Cm|Cm|Cm|Cm|Cm|Cm|Fm|Fm|Cm|Fm|Cm|Cm|Fm|Cm|Cm"},
	{"id": "unchained_destiny", "name": "Unchained Destiny", "author": "nene", "file": "res://assets/tracks/unchained_destiny.ogg",
		"bpm": 127.02, "bars": 32, "offset": 0.01, "key": 0, "scale": "minor_pentatonic",
		"chords": "Cm|Cm|G#|Cm|Cm|Cm|G#|Cm|Cm|Cm|Cm|Cm|Cm|Cm|G#|Gm|Cm|Cm|G#|Gm|Cm|Cm|G#|Cm|Cm|Fm|G#|Cm|Cm|Fm|G#|Cm"},
	{"id": "jrpg_battle", "name": "JRPG Rock Battle", "author": "HydroGene", "file": "res://assets/tracks/jrpg_battle.ogg",
		"bpm": 152.0, "bars": 72, "offset": 0.01, "key": 6, "scale": "minor_pentatonic",
		"chords": "F#m|F#m|F#m|F#m|F#m|F#m|F#m|D|C#m|C#m|C#|C#|F#m|F#m|F#m|F#m|F#m|F#m|F#m|D|C#m|C#m|C#|A|E|E|C#m|A|E|Bm|E|C#|F#m|F#m|F#m|F#m|F#m|F#m|F#m|F#m|F#m|F#m|F#m|D|C#m|C#m|E|C#|F#m|F#m|F#m|F#m|F#m|F#m|F#m|D|C#m|C#m|Bm|A|E|E|C#m|A|E|Bm|E|F#m|F#m|F#m|F#m|F#m"},
	{"id": "background_loop", "name": "Background Loop", "author": "Pro Sensory", "file": "res://assets/tracks/background_loop.ogg",
		"bpm": 140.0, "bars": 56, "offset": 0.01, "key": 7, "scale": "major_pentatonic",
		"chords": "G|C|G|Em|G|C|G|Em|G|C|G|Em|D|C|G|Em|G|C|G|C|G|C|G|D|G|C|D|Em|G|C|G|Em|G|C|D|Em|G|Bm|G|Em|G|C|G|Em|G|C|G|Em|G|C|G|Em|G|C|G|Em"},
	{"id": "funked_up", "name": "Funked Up", "author": "Joth", "file": "res://assets/tracks/funked_up.ogg",
		"bpm": 86.99, "bars": 24, "offset": 0.01, "key": 9, "scale": "minor_pentatonic",
		"chords": "Em|Am|Em|Am|Em|Am|Am|Am|Em|Am|Am|Am|Em|Am|Am|Am|Am|Am|Am|Am|Am|Am|Em|Am"},
	{"id": "swan_lake", "name": "Лебединое озеро", "author": "Чайковский", "file": "res://assets/tracks/swan_lake.ogg",
		"bpm": 84.0, "bars": 11, "offset": 0.01, "key": 11, "scale": "natural_minor",
		"chords": "Bm|Bm|Bm|D|Bm G|Bm|Bm|D|Bm G|Bm|Bm"},
	{"id": "fate", "name": "Симфония №5", "author": "Бетховен", "file": "res://assets/tracks/fate.ogg",
		"bpm": 140.0, "bars": 12, "offset": 0.01, "key": 0, "scale": "natural_minor",
		"chords": "Cm|Cm|Cm|G|Cm|Ab|Fm|G|Cm|G|Cm|Cm"},
	{"id": "canon", "name": "Канон ре мажор", "author": "Пахельбель", "file": "res://assets/tracks/canon.ogg",
		"bpm": 100.0, "bars": 12, "offset": 0.01, "key": 2, "scale": "major",
		"chords": "D A|D A|D A|Bm F#m|G D|G A|D A|Bm F#m|G D|G A|D|D"},
	{"id": "fur_elise", "name": "К Элизе", "author": "Бетховен", "file": "res://assets/tracks/fur_elise.ogg",
		"bpm": 140.0, "bars": 20, "offset": 0.01, "key": 9, "scale": "chromatic",
		"chords": "Am|Am|Am|E Am|Am|E|Am|E Am|Am|E|Am|E Am|Am|E|Am|E Am|Am|E|Am|Am"},
	{"id": "turkish_march", "name": "Турецкий марш", "author": "Моцарт", "file": "res://assets/tracks/turkish_march.ogg",
		"bpm": 150.0, "bars": 22, "offset": 0.01, "key": 9, "scale": "chromatic",
		"chords": "Am|Am|Am|Am|Am|E|Am|C|G|Em B7|Em|E|Am|Am|E|Am|C|G|Em B7|Em|Am|Am"},
	{"id": "bumblebee", "name": "Полёт шмеля", "author": "Римский-Корсаков", "file": "res://assets/tracks/bumblebee.ogg",
		"bpm": 150.0, "bars": 17, "offset": 0.01, "key": 9, "scale": "chromatic",
		"chords": "E|E|E|E|E|E|Am|Am|Am|Am|E|E|E|E|E|Am|Am"},
]
const MODE_SCALES := {"minor": "minor_pentatonic", "major": "major_pentatonic"}
const MINOR_WORDS := ["m", "min", "minor", "moll"]

static var _user: Array[Dictionary] = []
static var _memory := {}


static func all() -> Array:
	return BUILT_IN + _user


static func find(id: String) -> Dictionary:
	for track: Dictionary in all():
		if track["id"] == id:
			return track
	return {}


static func user_dir() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join(DIR_NAME)


static func scan_user() -> void:
	var memory: Variant = Songs.load_json(MEMORY_FILE)
	_memory = memory if memory is Dictionary else {}
	_user.clear()
	var dir := user_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var files := Array(DirAccess.get_files_at(dir))
	files.sort()
	for file: String in files:
		if LOADERS.has(file.get_extension().to_lower()):
			_user.append(user_track(file, _memory.get(file, {})))


static func user_track(file: String, remembered: Dictionary) -> Dictionary:
	var info := parse_name(file.get_basename())
	info.merge(remembered, true)
	return {"id": "user:" + file, "name": file.get_basename(), "author": "", "user": true,
		"file": user_dir().path_join(file), "bpm": float(info.get("bpm", 0.0)), "start": float(info.get("start", 0.0)),
		"offset": 0.0, "bars": 0, "key": int(info.get("key", -1)), "scale": String(info.get("scale", "")), "chords": ""}


static func parse_name(name: String) -> Dictionary:
	var out := {}
	var tempo := RegEx.create_from_string("(?i)(\\d{2,3}(?:[.,]\\d+)?)\\s*bpm").search(name)
	if tempo != null:
		out["bpm"] = float(tempo.get_string(1).replace(",", "."))
	var key_word := RegEx.create_from_string(
		"(?:^|[\\s_\\-\\(\\[,])([A-G])([#b]?)[\\s_]*([Mm]inor|[Mm]ajor|[Mm]in|[Mm]aj|[Mm]oll|[Dd]ur|m)?(?=$|[\\s_\\-\\)\\],.])")
	for found in key_word.search_all(name):
		var accidental := found.get_string(2)
		var mode := found.get_string(3).to_lower()
		if accidental.is_empty() and mode.is_empty() and found.get_start() == 0:
			continue
		var shift := {"": 0, "#": 1, "b": -1}[accidental] as int
		out["key"] = posmod(Tuning.KEY_NAMES.find(found.get_string(1)) + shift, 12)
		out["scale"] = MODE_SCALES["minor" if mode in MINOR_WORDS else "major"]
	return out


static func remember(track: Dictionary, save := true) -> void:
	if not track.get("user", false):
		return
	_memory[String(track["file"]).get_file()] = {"bpm": track["bpm"], "start": track["start"], "key": track["key"],
		"scale": track["scale"]}
	if save:
		Songs.save_json(MEMORY_FILE, _memory)


static func load_stream(track: Dictionary) -> AudioStream:
	var path := String(track["file"])
	if path.begins_with("res://"):
		return load(path)
	var loader: String = LOADERS.get(path.get_extension().to_lower(), "")
	var bytes := FileAccess.get_file_as_bytes(path)
	if loader.is_empty() or bytes.is_empty():
		push_warning("Трек не читается (%s): %s" % [error_string(FileAccess.get_open_error()), path])
		return null
	var stream := ClassDB.class_call_static(loader, "load_from_buffer", bytes) as AudioStream
	if stream == null:
		push_warning("Трек не раскодируется: %s" % path)
	return stream


static func first_downbeat(from: float, bpm: float) -> float:
	return snappedf(fposmod(from, 60.0 / bpm * Timing.BEATS_PER_BAR), 0.001)


static func fit_bars(seconds: float, start: float, bar: float) -> int:
	return maxi(0, floori((seconds - start - TAIL) / bar))
