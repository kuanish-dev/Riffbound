class_name Tracks
## Треки для джема (и для своих песен, записанных под трек).
## BUILT_IN — CC0-петли (авторы — CREDITS.md). Их собирает tools/build_assets.py: режет ровно в «bars» тактов
## от сильной доли (offset — пре-ролл перед ней), темп, такты и тональность считает там же — сетка игры не
## уезжает на повторах.
## Свои треки игрок кладёт в папку Документы/Riffbound (user_dir, туда же джем сохраняет MIDI). Не «Музыка»:
## на Android 11+ Godot читает напрямую только «Документы» и «Загрузки», а чужие файлы в «Музыке» ему не открыть.
## Темп и тональность — из имени файла
## («Song 120bpm Am.mp3»), иначе тап-темпом и клавишами тона/гаммы; найденное запоминается в MEMORY_FILE
## (по имени файла): bpm, start (сильная доля в файле, с), key, scale.

const DIR_NAME := "Riffbound"
const MEMORY_FILE := "user://user_tracks.json"
## Расширение → класс потока, который грузит файл с диска.
const LOADERS := {"ogg": "AudioStreamOggVorbis", "mp3": "AudioStreamMP3", "wav": "AudioStreamWAV"}
const TAIL := 0.05                     ## своя петля кончается чуть раньше файла
const BUILT_IN := [
	{"id": "rock_theme_3", "name": "Rock Theme 3", "author": "Umplix", "file": "res://assets/tracks/rock_theme_3.ogg",
		"bpm": 120.0, "bars": 32, "offset": 0.01, "key": 2, "scale": "minor_pentatonic"},
	{"id": "rocky_loop", "name": "Rocky Musicloop", "author": "johndekale", "file": "res://assets/tracks/rocky_loop.ogg",
		"bpm": 90.0, "bars": 19, "offset": 0.01, "key": 0, "scale": "minor_pentatonic"},
	{"id": "unchained_destiny", "name": "Unchained Destiny", "author": "nene", "file": "res://assets/tracks/unchained_destiny.ogg",
		"bpm": 127.02, "bars": 32, "offset": 0.01, "key": 0, "scale": "minor_pentatonic"},
	{"id": "jrpg_battle", "name": "JRPG Rock Battle", "author": "HydroGene", "file": "res://assets/tracks/jrpg_battle.ogg",
		"bpm": 152.0, "bars": 72, "offset": 0.01, "key": 6, "scale": "minor_pentatonic"},
	{"id": "background_loop", "name": "Background Loop", "author": "Pro Sensory", "file": "res://assets/tracks/background_loop.ogg",
		"bpm": 140.0, "bars": 56, "offset": 0.01, "key": 7, "scale": "major_pentatonic"},
	{"id": "funked_up", "name": "Funked Up", "author": "Joth", "file": "res://assets/tracks/funked_up.ogg",
		"bpm": 86.99, "bars": 24, "offset": 0.01, "key": 9, "scale": "minor_pentatonic"},
]
## Лад тональности из имени файла → гамма джема.
const MODE_SCALES := {"minor": "minor_pentatonic", "major": "major_pentatonic"}
const MINOR_WORDS := ["m", "min", "minor", "moll"]

static var _user: Array[Dictionary] = []
static var _memory := {}               ## файл → {bpm, start, key, scale}


static func all() -> Array:
	return BUILT_IN + _user


static func find(id: String) -> Dictionary:
	for track: Dictionary in all():
		if track["id"] == id:
			return track
	return {}


static func user_dir() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join(DIR_NAME)


## Перечитать папку своих треков (создаёт её, если можно).
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


## Свой трек по имени файла: найденное в имени, поверх — запомненное раньше. bpm 0 — темп не известен,
## key −1 — тональность не известна.
static func user_track(file: String, remembered: Dictionary) -> Dictionary:
	var info := parse_name(file.get_basename())
	info.merge(remembered, true)
	return {"id": "user:" + file, "name": file.get_basename(), "author": "", "user": true,
		"file": user_dir().path_join(file), "bpm": float(info.get("bpm", 0.0)), "start": float(info.get("start", 0.0)),
		"offset": 0.0, "bars": 0, "key": int(info.get("key", -1)), "scale": String(info.get("scale", ""))}


## Темп и тональность из имени: «120bpm» / «95 BPM»; тональность — отдельным словом: Am, F#m, Bb, C major,
## E minor. Одиночная буква без диеза и лада в самом начале имени не считается (это артикль: «A Day…»).
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


## Запомнить найденное для своего трека (тап-темп, тональность).
static func remember(track: Dictionary, save := true) -> void:
	if not track.get("user", false):
		return
	_memory[String(track["file"]).get_file()] = {"bpm": track["bpm"], "start": track["start"], "key": track["key"],
		"scale": track["scale"]}
	if save:
		Songs.save_json(MEMORY_FILE, _memory)


## Поток трека: встроенный — ресурс игры, свой — файл с диска (null, если не читается).
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


## Первая сильная доля файла: тап начат с «раз» на секунде from — раньше неё целые такты.
static func first_downbeat(from: float, bpm: float) -> float:
	return snappedf(fposmod(from, 60.0 / bpm * Timing.BEATS_PER_BAR), 0.001)


## Сколько тактов своего трека влезает от сильной доли до конца файла.
static func fit_bars(seconds: float, start: float, bar: float) -> int:
	return maxi(0, floori((seconds - start - TAIL) / bar))
