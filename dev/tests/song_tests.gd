class_name SongTests
extends TestSuite
## Песни: разбор таба, играбельность встроенных песен, оценка игры (SongJudge), песня из лупа.

const LEAD := Songs.LEAD_IN * 8


func test_tab_cells() -> void:
	var notes := Songs.notes_of(_song([{"low": "1 = h2 - x - 3b ="}]))
	eq(notes.size(), 4, "четыре ноты")
	eq([notes[0]["slot"], notes[0]["fret"], notes[0]["len"], notes[0]["legato"]], [LEAD, "1", 2, false], "удар, держать две восьмые")
	eq([notes[1]["fret"], notes[1]["legato"], notes[1]["tech"]], ["2", true, "h"], "хаммер-он")
	eq(notes[2]["fret"], Notes.MUTE, "глушняк")
	eq([notes[3]["fret"], notes[3]["bend"], notes[3]["len"]], ["3", true, 2], "бенд")


func test_tab_hold_across_bars() -> void:
	var notes := Songs.notes_of(_song([{"pos": 1, "mid": "- - - - - - 1 ="}, {"mid": "= = - - - - - -"}]))
	eq([notes.size(), notes[0]["len"], notes[0]["pos"]], [1, 4, 1], "нота тянется через такт, позиция такта")
	eq(Songs.end_slot(_song([{"low": "1 - - - - - - -"}])), LEAD + 16, "конец — такт после последней ноты")


## Каждое легато встроенных песен должно быть сыграбельным: на той же струне перед ним нота,
## начатая не раньше окна легато; позиции — в диапазоне сэмплов.
func test_built_in_songs_are_playable() -> void:
	for song: Dictionary in Songs.BUILT_IN:
		var notes := Songs.notes_of(song)
		check(not notes.is_empty(), "%s: есть ноты" % song["id"])
		var last := {}
		for note in notes:
			var string := String(note["string"])
			if note["legato"]:
				var ok := last.has(string) and (int(note["slot"]) - int(last[string]["slot"])) * Timing.SLOT_LEN <= Fretboard.LEGATO_WINDOW
				check(ok, "%s: легато в слоте %d на струне %s успевает" % [song["id"], note["slot"], string])
			last[string] = note
			var tuning := Tuning.new()
			tuning.key = int(song["key"])
			tuning.scale = Tuning.scale_index(String(song["scale"]))
			check(tuning.fits(int(note["pos"])), "%s: позиция %d в диапазоне" % [song["id"], note["pos"]])


func test_hit_miss_and_score() -> void:
	var p := _perf([{"low": "1 - 2 - - - - -"}])
	p.play("low", 52, _t(LEAD) + 0.02, false)
	eq([p.hits, p.streak], [1, 1], "первая нота сыграна")
	check(p.score > 0, "очки за ноту")
	p.update(_t(LEAD + 2) + 0.2)
	eq([p.misses, p.streak], [1, 0], "вторую пропустил — серия оборвана")


func test_wrong_note_breaks_streak() -> void:
	var p := _perf([{"low": "1 - 2 - - - - -"}])
	p.play("low", 52, _t(LEAD), false)
	p.play("low", 57, _t(LEAD + 2), false)
	eq([p.wrongs, p.streak, p.hits], [1, 0, 1], "удар не той высоты рядом с нотой песни")


func test_stray_legato_and_noodling_are_free() -> void:
	var p := _perf([{"low": "1 - - - - - - 2"}])
	p.play("low", 52, _t(LEAD), false)
	p.play("low", 57, _t(LEAD + 1), true)
	p.play("low", 59, _t(LEAD + 3), false)
	eq([p.wrongs, p.streak], [0, 1], "случайное легато и игра между нотами не ошибки")


func test_strike_after_early_legato_is_not_doubled() -> void:
	var p := _perf([{"low": "1 - - - - - - -"}])
	p.play("low", 52, _t(LEAD) - 0.05, true)
	p.play("low", 52, _t(LEAD), false)
	eq([p.hits, p.wrongs], [1, 0], "легато взяло ноту, удар следом — повтор")


func test_technique_bonus() -> void:
	var p := _perf([{"low": "1 h2 - - 2b = - -"}])
	p.play("low", 52, _t(LEAD), false)
	p.play("low", 55, _t(LEAD + 1), true)
	p.play("low", 55, _t(LEAD + 4), false)
	p.bend("low", 1.0, _t(LEAD + 4) + 0.1)
	eq([p.techs, p.tech_total], [2, 2], "хаммер-он легато и бенд засчитаны")


func test_sustain_ratio() -> void:
	var p := _perf([{"mid": "1 = = = - - - -"}])
	var ratios: Array = []
	p.fact.connect(func(kind: String, data: Dictionary) -> void:
		if kind == "sustain":
			ratios.append(snappedf(float(data["ratio"]), 0.01)))
	p.play("mid", 59, _t(LEAD), false)
	p.mute("mid", _t(LEAD + 2))
	eq(ratios, [0.5], "держал половину ноты")


func test_finish_and_stars() -> void:
	var p := _perf([{"low": "1 - - - - - - -"}])
	p.play("low", 52, _t(LEAD), false)
	p.update(p.end_time)
	check(p.finished, "песня кончилась")
	eq(p.stars(), 5, "все ноты — пять звёзд")


func test_song_from_loop_layer() -> void:
	var layer := [
		{"t": 0.0, "kind": "pluck", "string": "low", "fret": "1", "pos": 0, "midis": [52]},
		{"t": 0.3, "kind": "slur", "string": "low", "fret": "2", "pos": 0, "midis": [55]},
		{"t": 0.45, "kind": "bend", "string": "low", "amount": 1.0},
		{"t": 0.9, "kind": "mute", "string": "low"},
		{"t": 1.2, "kind": "dead", "string": "mid", "fret": "X", "pos": 0, "midis": []},
	]
	var song := Songs.from_layer(layer, Tuning.song(), "rock")
	var notes := Songs.notes_of(song)
	eq(notes.size(), 3, "три ноты")
	eq([notes[0]["slot"], notes[0]["len"]], [LEAD, 1], "удар до легато")
	eq([notes[1]["fret"], notes[1]["legato"], notes[1]["bend"], notes[1]["len"]], ["2", true, true, 2], "легато с бендом до глушения")
	eq([notes[2]["string"], notes[2]["fret"]], ["mid", Notes.MUTE], "глушняк")


func _song(bars: Array) -> Dictionary:
	return {"id": "test", "name": "Тест", "level": 1, "backing": "rock", "key": 4, "scale": "minor_pentatonic", "text": "",
		"bars": bars}


func _perf(bars: Array) -> SongJudge:
	var p := SongJudge.new()
	p.start(_song(bars))
	return p


func _t(slot: int) -> float:
	return slot * Timing.SLOT_LEN
