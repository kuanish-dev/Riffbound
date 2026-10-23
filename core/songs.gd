class_name Songs
## Песни — табы по тактам: строка на струну (Notes.STRINGS), восемь восьмых через пробел.
## Клетка: «-» — пусто, «1»…«3» — удар по ладу, «x» — глушняк, «h2»/«p1» — легато к ладу без удара
## (хаммер-он / пулл-офф), «…b» — бенд, «=» — держать ноту этой струны ещё восьмую.
## «pos» такта — позиция руки (Q/E) для его нот. Песня играет поверх подложки «backing» — стиля
## Backing.STYLES или трека Tracks — в своём темпе «bpm» (нет — Timing.DEFAULT_BPM); стиль играет её аккорды
## «chords» (Harmony: по такту, «Am E» — два аккорда в такте; нет — круг тональности строя песни).
## До первого такта — LEAD_IN тактов отсчёта.
## Свои песни делаются в джеме из слоя лупера (from_layer), хранятся в MY_FILE; лучшие счета — в SCORES_FILE.

const LEAD_IN := 2
const MY_MAX := 6
const MY_FILE := "user://my_songs.json"
const SCORES_FILE := "user://scores.json"
## Какие события гитары рождают ноту песни (from_layer): легато ли она и глушняк ли.
const EVENT_NOTES := {
	"pluck": {"legato": false},
	"slur": {"legato": true},
	"dead": {"legato": false},
}

const BUILT_IN := [
	{"id": "warmup", "name": "Разминка", "level": 1, "backing": "shuffle", "key": 4, "scale": "minor_pentatonic",
		"text": "лады по очереди, ноты по две доли",
		"chords": ["Em", "Em", "C", "D", "C", "G", "Am", "Em"],
		"bars": [
			{"low": "1 = 2 = 3 = - -"},
			{"mid": "1 = 2 = 3 = - -"},
			{"high": "1 = 2 = 3 = - -"},
			{"high": "3 = = = = = - -"},
			{"high": "3 = 2 = 1 = - -"},
			{"mid": "3 = 2 = 1 = - -"},
			{"low": "3 = 2 = 1 = - -"},
			{"low": "1 = = = = = - -"},
		]},
	{"id": "four", "name": "Четыре пальца", "level": 2, "backing": "rock", "key": 4, "scale": "minor_pentatonic",
		"text": "4-й лад (F) — мизинец: четыре ноты на струне",
		"chords": ["Em", "G", "C", "D", "C", "G", "Am", "Em"],
		"bars": [
			{"low": "1 = 2 = 3 = 4 ="},
			{"mid": "1 = 2 = 3 = 4 ="},
			{"high": "1 = 2 = 3 = 4 ="},
			{"high": "4 = = = = = - -"},
			{"high": "4 p3 p2 p1 = = - -"},
			{"mid": "1 h2 h3 h4 = p3 p2 p1"},
			{"low": "1 h2 h3 h4 = p3 p2 p1"},
			{"low": "1 = = = = = = -"},
		]},
	{"id": "power", "name": "Пауэр-аккорды", "level": 2, "backing": "metal", "key": 4, "scale": "minor_pentatonic",
		"text": "аккорд — один лад и удар по двум струнам сразу, x — глушняк",
		"chords": ["E5", "G5 A5", "E5", "G5 A5", "E5", "A5 G5", "E5", "E5"],
		"bars": [
			{"mid": "1 = - - 1 = - -", "low": "1 = x x 1 = x x"},
			{"mid": "2 = - - 3 = 2 =", "low": "2 = x x 3 = 2 ="},
			{"mid": "1 = - - 1 = - -", "low": "1 = x x 1 = x x"},
			{"mid": "2 = - - 3 = 2 =", "low": "2 = x x 3 = 2 ="},
			{"mid": "1 = - - 1 = - -", "low": "1 = x x 1 = x x"},
			{"mid": "3 = - - 2 = - -", "low": "3 = x x 2 = x x"},
			{"mid": "1 = - - 1 = - -", "low": "1 = x x 1 = x x"},
			{"mid": "1 = = = = = = -", "low": "1 = = = = = = -"},
		]},
	{"id": "legato", "name": "Легато", "level": 3, "backing": "slow", "key": 4, "scale": "minor_pentatonic",
		"text": "h — хаммер-он, p — пулл-офф: новая нота без удара",
		"chords": ["Em", "G", "C", "Em", "Em", "Em", "G", "Em"],
		"bars": [
			{"low": "1 h2 h3 = p2 p1 = -"},
			{"mid": "1 h2 h3 = p2 p1 = -"},
			{"high": "1 h2 h3 = p2 p1 = -"},
			{"high": "3 = p2 = p1 = = -"},
			{"mid": "1 h3 p1 h3 p1 h3 p1 -"},
			{"low": "1 h2 p1 h2 p1 h2 p1 -"},
			{"mid": "3 p2 p1 - 3 p2 p1 -"},
			{"low": "1 = = = = = = -"},
		]},
	{"id": "solo", "name": "Соло", "level": 4, "backing": "rock", "key": 4, "scale": "minor_pentatonic",
		"text": "бенды (пробел), легато и сдвиг руки по грифу (Q/E)",
		"chords": ["Em", "G", "D", "Em", "C", "Em", "D", "Em"],
		"bars": [
			{"high": "- - 1 h2 3 = 2b ="},
			{"high": "3 p2 p1 - - - - -", "mid": "- - - - 3 p2 p1 ="},
			{"mid": "2 3 2 1 - - - -", "low": "- - - - 3 = 3b ="},
			{"low": "1 = = = = = - -"},
			{"pos": 1, "mid": "1 h2 h3 = - 2b = ="},
			{"pos": 1, "high": "1 h2 h3 = 3 p2 p1 ="},
			{"pos": 1, "high": "2b = = = = = - -"},
			{"low": "1 = = = = = = -"},
		]},
	{"id": "korobeiniki", "name": "Коробейники", "level": 2, "backing": "rock", "bpm": 116.0, "key": 9,
		"scale": "natural_minor",
		"text": "народная · тема из «Тетриса», ля минор",
		"chords": ["Am E", "Am", "E", "Am", "Dm", "C", "E", "Am"],
		"bars": [
			{"mid": "2 = - - - - - -", "low": "- - 2 3 4 = 3 2"},
			{"low": "1 = 1 3 - - 4 3", "mid": "- - - - 2 = - -"},
			{"low": "2 = = 3 4 = - -", "mid": "- - - - - - 2 ="},
			{"low": "3 = 1 = 1 = = ="},
			{"mid": "- 1 = 3 - - - 3", "high": "- - - - 2 = 1 -"},
			{"mid": "2 = = - 2 = 1 -", "low": "- - - 3 - - - 3"},
			{"low": "2 = 2 3 4 = - -", "mid": "- - - - - - 2 ="},
			{"low": "3 = 1 = 1 = = ="},
		]},
	{"id": "mountain_king", "name": "В пещере горного короля", "level": 2, "backing": "metal", "key": 4,
		"scale": "natural_minor", "text": "Григ · упрощённо, ми минор",
		"chords": ["Em", "B7", "Em", "Em", "G", "Em"],
		"bars": [
			{"low": "1 2 3 4 - 3 - -", "mid": "- - - - 2 - 2 ="},
			{"low": "4 2 4 = = = = ="},
			{"low": "3 1 3 = = = = ="},
			{"low": "1 2 3 4 - 3 - -", "mid": "- - - - 2 - 2 -", "high": "- - - - - - - 2"},
			{"high": "1 - - - 1 = = =", "mid": "- 2 - 2 - - - -", "low": "- - 3 - - - - -"},
			{"low": "1 = = = = = = -"},
		]},
	{"id": "ode_to_joy", "name": "Ода к радости", "level": 1, "backing": "slow", "bpm": 92.0, "key": 9, "scale": "major",
		"text": "Бетховен · ля мажор, ноты по долям",
		"chords": ["A", "E", "A", "A E", "A", "E", "A", "E A"],
		"bars": [
			{"low": "3 = 3 = 4 = - -", "mid": "- - - - - - 2 ="},
			{"mid": "2 = - - - - - -", "low": "- - 4 = 3 = 2 ="},
			{"low": "1 = 1 = 2 = 3 ="},
			{"low": "3 = = 2 2 = = ="},
			{"low": "3 = 3 = 4 = - -", "mid": "- - - - - - 2 ="},
			{"mid": "2 = - - - - - -", "low": "- - 4 = 3 = 2 ="},
			{"low": "1 = 1 = 2 = 3 ="},
			{"low": "2 = = 1 1 = = ="},
		]},
	{"id": "toccata", "name": "Токката ре минор", "level": 4, "backing": "metal", "bpm": 92.0, "key": 2,
		"scale": "harmonic_minor",
		"text": "Бах · пулл-оффы, хаммер-оны, сдвиг позиции",
		"chords": ["A7", "A7 Dm", "A7", "A7 Dm", "Dm", "Dm"],
		"bars": [
			{"pos": 1, "high": "3 p2 h3 = = = - -"},
			{"pos": 1, "high": "2 1 - - - - - -", "mid": "- - 3 2 1 2 = ="},
			{"mid": "2 p1 h2 = = = - -"},
			{"low": "4 p3 p2 p1 = = = -"},
			{"low": "1 3 - - - - - -", "mid": "- - 2 - - - - -", "high": "- - - 2 = = = ="},
			{"high": "1 - - - - - - -", "mid": "- 2 - - - - - -", "low": "- - 3 1 = = = ="},
		]},
]

## Сохранять ли свои песни и рекорды на диск (симуляция и снимки выключают, чтобы не портить рекорды игрока).
static var persist := true
static var _my: Array[Dictionary] = []
static var _scores := {}                 ## id песни → {score, stars, accuracy}


static func all() -> Array:
	return BUILT_IN + _my


static func my() -> Array[Dictionary]:
	return _my


static func bpm_of(song: Dictionary) -> float:
	return float(song.get("bpm", Timing.DEFAULT_BPM))


## Ноты песни по времени: {slot (восьмые с начала песни), string, fret, pos, legato, bend, len}.
static func notes_of(song: Dictionary) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	if song.has("notes"):
		for item: Dictionary in song["notes"]:
			var note := item.duplicate()
			for field: String in ["slot", "pos", "len"]:
				note[field] = int(note[field])
			notes.append(note)
		return notes
	var last := {}                       ## струна → нота, которую может продлить «=»
	var bars: Array = song["bars"]
	for b in bars.size():
		var bar: Dictionary = bars[b]
		for string: String in Notes.STRINGS:
			if not bar.has(string):
				last.erase(string)
				continue
			var cells := String(bar[string]).split(" ", false)
			if cells.size() != Timing.SLOTS_PER_BAR:
				push_error("Песня %s, такт %d, струна %s: нужно %d клеток" % [song["id"], b + 1, string, Timing.SLOTS_PER_BAR])
			for c in cells.size():
				var slot := (LEAD_IN + b) * Timing.SLOTS_PER_BAR + c
				var cell: String = cells[c]
				if cell == "=":
					if last.has(string) and int(last[string]["slot"]) + int(last[string]["len"]) == slot:
						last[string]["len"] = int(last[string]["len"]) + 1
					continue
				last.erase(string)
				if cell == "-":
					continue
				var note := {"slot": slot, "string": string, "pos": int(bar.get("pos", 0)), "legato": false, "bend": false,
					"len": 1, "tech": ""}
				if cell[0] in ["h", "p"]:
					note["legato"] = true
					note["tech"] = cell[0]
					cell = cell.substr(1)
				if cell.ends_with("b"):
					note["bend"] = true
					cell = cell.left(-1)
				note["fret"] = Notes.MUTE if cell == "x" else cell
				notes.append(note)
				last[string] = note
	notes.sort_custom(_earlier)
	return notes


## Аккорды подложки по тактам от начала часов (с отсчётом): отсчёт — на первом аккорде песни, хвост — на последнем.
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


## Слот, где песня кончается: такт после последней ноты.
static func end_slot(song: Dictionary) -> int:
	var end := LEAD_IN * Timing.SLOTS_PER_BAR
	for note in notes_of(song):
		end = maxi(end, int(note["slot"]) + int(note["len"]))
	return (ceili(float(end) / Timing.SLOTS_PER_BAR) + 1) * Timing.SLOTS_PER_BAR


## Своя песня из слоя лупера: события {t, kind, string, fret, pos, amount} → ноты на сетке восьмых
## текущего темпа (Timing.bpm); подложка и аккорды круга — те, под которые играли.
static func from_layer(events: Array, tuning: Tuning, backing: String, chords: Array[String]) -> Dictionary:
	var loop_slots := Looper.BARS * Timing.SLOTS_PER_BAR
	var start := LEAD_IN * Timing.SLOTS_PER_BAR
	var notes: Array[Dictionary] = []
	var sounding := {}                   ## струна → нота
	for event: Dictionary in events:
		var string := String(event["string"])
		var slot := start + posmod(roundi(float(event["t"]) / Timing.slot_len()), loop_slots)
		if event.has("amount"):
			if float(event["amount"]) > 0.0 and sounding.has(string):
				sounding[string]["bend"] = true
			continue
		if sounding.has(string):
			_close(sounding[string], slot)
			sounding.erase(string)
		var kind := String(event["kind"])
		if not EVENT_NOTES.has(kind):
			continue
		var legato: bool = EVENT_NOTES[kind]["legato"]
		var note := {"slot": slot, "string": string, "fret": String(event.get("fret", Notes.MUTE)), "pos": int(event.get("pos", 0)),
			"legato": legato, "bend": false, "len": 1, "tech": "h" if legato else ""}
		notes.append(note)
		if note["fret"] != Notes.MUTE:
			sounding[string] = note
	for string: String in sounding:
		_close(sounding[string], start + loop_slots)
	# одна нота на струну в восьмой
	var seen := {}
	var unique: Array[Dictionary] = []
	for note in notes:
		var key := "%s:%d" % [note["string"], note["slot"]]
		if not seen.has(key):
			seen[key] = true
			unique.append(note)
	unique.sort_custom(_earlier)
	var number := _next_number()
	return {"id": "my_%d" % number, "name": "Моя песня %d" % number, "number": number, "level": 0, "backing": backing,
		"bpm": Timing.bpm, "key": tuning.key, "scale": Tuning.SCALES[tuning.scale]["id"], "text": "%d нот · %s" % [unique.size(), tuning.title()],
		"chords": chords.slice(0, Looper.BARS), "notes": unique}


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


## Запомнить результат; true — новый рекорд.
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


static func _close(note: Dictionary, slot: int) -> void:
	note["len"] = maxi(1, slot - int(note["slot"]))


static func _next_number() -> int:
	var top := 0
	for song in _my:
		top = maxi(top, int(song.get("number", 0)))
	return top + 1


static func _earlier(a: Dictionary, b: Dictionary) -> bool:
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
