class_name DifficultyTests
extends TestSuite

const LEAD := Songs.LEAD_IN * Timing.SLOTS_PER_BAR


func after_all() -> void:
	Timing.leniency = 1.0
	Difficulty.forced = -1


func test_expert_keeps_the_tab() -> void:
	var song := _song([{"low": "1 h2 3 4b 1 2 3 4"}])
	var notes := Difficulty.simplify(Songs.notes_of(song), _level("expert"))
	eq(notes.size(), 8, "все ноты")
	eq([notes[1]["legato"], notes[3]["bend"]], [true, true], "техника на месте")


func test_easy_keeps_one_note_per_beat_without_technique() -> void:
	var song := _song([{"low": "1 h2 3 4b 1 - - 3"}])
	var notes := Difficulty.simplify(Songs.notes_of(song), _level("easy"))
	eq(notes.map(func(n: Dictionary) -> int: return int(n["slot"]) - LEAD), [0, 2, 4], "ноты на долях")
	check(notes.all(func(n: Dictionary) -> bool: return not n["legato"] and not n["bend"]), "без легато и бенда")


func test_hard_drops_every_second_offbeat_and_keeps_chords() -> void:
	var song := _song([{"low": "1 2 3 4 1 2 - 3", "mid": "1 - - - - - - -"}])
	var notes := Difficulty.simplify(Songs.notes_of(song), _level("hard"))
	eq(notes.map(func(n: Dictionary) -> String: return "%d%s" % [int(n["slot"]) - LEAD, String(n["string"])[0]]),
		["0l", "0m", "1l", "2l", "4l", "5l"], "доли и каждая вторая слабая, аккорд целиком")


func test_hard_breaks_legato_after_dropped_note() -> void:
	var song := _song([{"low": "- - 1 h2 h3 - - -"}])
	var notes := Difficulty.simplify(Songs.notes_of(song), _level("hard"))
	eq(notes.map(func(n: Dictionary) -> bool: return n["legato"]), [false, false], "легато после выпавшей ноты — удар")


func test_easier_levels_forgive_more() -> void:
	Timing.bpm = Timing.DEFAULT_BPM
	var late := Timing.slot_len() * 3 + 0.12
	Timing.leniency = 1.0
	eq(Timing.judge(late)["judgement"]["id"], "miss", "сложный: мимо")
	Timing.leniency = float(_level("easy")["window"])
	eq(Timing.judge(late)["judgement"]["id"], "good", "лёгкий: хорошо")


func test_records_and_coins_per_level() -> void:
	eq(Difficulty.record_key("ode", Difficulty.index_of("expert")), "ode", "эксперт — прежний рекорд")
	eq(Difficulty.record_key("ode", Difficulty.index_of("easy")), "ode@easy", "лёгкий — свой рекорд")
	check(float(_level("easy")["coins"]) < float(_level("expert")["coins"]), "на лёгком монет меньше")


func test_novice_plays_strong_beats_single_notes() -> void:
	var song := _song([{"low": "1 2 3 4 x - 3 -", "mid": "1 - - - 1 - - -"}, {"low": "2 - 2 - 2 - 2 -"}])
	var notes := Difficulty.simplify(Songs.notes_of(song), _level("novice"))
	eq(notes.map(func(n: Dictionary) -> String: return "%d%s" % [int(n["slot"]) - LEAD, String(n["string"])[0]]),
		["0l", "4m", "8l", "12l"], "1-я и 3-я доли, одна нота вместо аккорда, без глушняков")


func test_medium_adds_chords_and_mutes_but_no_offbeats() -> void:
	var song := _song([{"low": "1 2 x - - - - -", "mid": "1 - - - - - - -"}])
	var notes := Difficulty.simplify(Songs.notes_of(song), _level("medium"))
	eq(notes.map(func(n: Dictionary) -> String: return "%d%s" % [int(n["slot"]) - LEAD, String(n["string"])[0]]),
		["0l", "0m", "2l"], "аккорд и глушняк есть, слабой доли нет")


func test_each_song_has_its_own_level() -> void:
	var saved := Songs.persist
	Songs.persist = false
	Difficulty.chosen.clear()
	eq(Difficulty.index_for("никогда_не_играли"), 0, "непройденная песня начинается с новичка")
	Difficulty.choose("a", 3)
	eq([Difficulty.index_for("a"), Difficulty.index_for("b")], [3, 0], "выбор одной песни не трогает другую")
	Difficulty.chosen.clear()
	Songs.persist = saved


func test_best_passed_level_colors_the_song() -> void:
	var saved := Songs.persist
	Songs.persist = false
	eq(Difficulty.best_passed("не_играли"), -1, "не пройдена — без цвета")
	Songs.record(Difficulty.record_key("цвет", 1), {"score": 100, "stars": 1, "accuracy": 0.5}, false)
	eq(Difficulty.best_passed("цвет"), 1, "доиграл — уровень пройден, звёзды не важны")
	Songs.record(Difficulty.record_key("цвет", 3), {"score": 100, "stars": 5, "accuracy": 1.0}, false)
	eq(Difficulty.best_passed("цвет"), 3, "цвет — самого сложного пройденного уровня")
	Songs.persist = saved


func test_harder_levels_add_mechanics() -> void:
	var flags := ["chords", "mutes", "techniques"]
	for i in range(1, Difficulty.LEVELS.size()):
		var easier: Dictionary = Difficulty.LEVELS[i - 1]
		var harder: Dictionary = Difficulty.LEVELS[i]
		for flag: String in flags:
			check(not easier[flag] or harder[flag], "%s: %s не пропадает" % [harder["id"], flag])
		check(not harder["auto_hand"] or easier["auto_hand"], "%s: рука сама — только ниже" % harder["id"])
		check(float(harder["window"]) <= float(easier["window"]), "%s: окно не шире" % harder["id"])
		check(float(harder["coins"]) >= float(easier["coins"]), "%s: монет не меньше" % harder["id"])


static func _level(id: String) -> Dictionary:
	return Difficulty.LEVELS[Difficulty.index_of(id)]


static func _song(bars: Array) -> Dictionary:
	return {"id": "test", "name": "Тест", "backing": "rock", "key": 4, "scale": "minor_pentatonic", "text": "",
		"bars": bars}
