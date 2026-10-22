class_name CoreTests
extends TestSuite
## Основа без сцены: сетка времени, звучащий лад, строй (тональность, гаммы, позиции), окно прощения.


func test_judge_windows() -> void:
	var s := Timing.SLOT_LEN
	eq(Timing.judge(s * 3)["slot"], 3, "ближайший слот")
	eq(Timing.judge(s * 3 + 0.03)["judgement"]["id"], "perfect", "чуть позже")
	eq(Timing.judge(s * 3 - 0.07)["judgement"]["id"], "good", "заметно раньше")
	eq(Timing.judge(s * 3 + 0.12)["judgement"]["id"], "miss", "между долями")


func test_top_fret_sounds() -> void:
	eq(Notes.from_frets({}), "X", "без ладов — глушняк")
	eq(Notes.from_frets({"1": true}), "1", "один лад")
	eq(Notes.from_frets({"3": true, "1": true}), "3", "звучит верхний из зажатых, как на гитаре")


func test_song_tuning() -> void:
	var tuning := Tuning.song()
	eq(Tuning.note_name(tuning.midi("1", "low")), "E3", "1-й лад нижней")
	eq(Tuning.note_name(tuning.midi("1", "mid")), "B3", "1-й лад средней")
	eq(Tuning.note_name(tuning.midi("3", "high")), "B4", "3-й лад верхней")
	eq(tuning.midis("X", "low"), [], "у глушняка нет высоты")


func test_fourth_fret_reaches_next_string() -> void:
	var tuning := Tuning.song()
	eq(tuning.midi("4", "low"), tuning.midi("1", "mid"), "мизинец на нижней = 1-й лад средней")
	eq(Tuning.note_name(tuning.midi("4", "high")), "D5", "на верхней — новая нота сверху")
	eq(Notes.from_frets({"1": true, "4": true}), "4", "звучит мизинец — верхний из зажатых")


func test_positions_and_scales() -> void:
	var tuning := Tuning.song()
	check(tuning.shift_position(1), "позиция вверх")
	eq(Tuning.note_name(tuning.midi("1", "low")), "B3", "нижняя струна взяла ноты средней")
	check(not tuning.shift_position(5), "за диапазон сэмплов не уйти")
	tuning.position = 0
	tuning.scale = Tuning.scale_index("major")
	tuning.key = 0
	eq(tuning.midis("1", "low") + tuning.midis("2", "low") + tuning.midis("3", "low") + tuning.midis("1", "mid"),
		[48, 50, 52, 53], "до мажор: до ре ми фа — три ноты на струну")
	check(not tuning.is_minor(), "мажор")
	tuning.shift_key(-1)
	eq(Tuning.note_name(tuning.midi("1", "low")), "B3", "тональность по кругу: до → си")


func test_leniency_late_fret() -> void:
	var played := _strum_case(func(fb: Fretboard, clock: Conductor) -> void:
		fb.strike("low")
		clock.set_manual(1.03)
		fb.press_fret("3"))
	eq(played, ["3:low@1.0"], "лад сразу после удара")


func test_leniency_expired() -> void:
	var played := _strum_case(func(fb: Fretboard, clock: Conductor) -> void:
		fb.strike("mid")
		clock.set_manual(1.06)
		fb.update()
		fb.press_fret("3"))
	eq(played, ["X:mid@1.0"], "лад после окна — глушняк")


func test_leniency_switch_fret() -> void:
	var played := _strum_case(func(fb: Fretboard, clock: Conductor) -> void:
		fb.press_fret("1")
		fb.strike("mid")
		fb.release_fret("1")
		clock.set_manual(1.02)
		fb.press_fret("3"))
	eq(played, ["3:mid@1.0"], "перестановка пальца в окне")


## Гитара на ручных часах (t = 1.0): действия → засчитанные удары «лад:струна@время».
func _strum_case(actions: Callable) -> Array:
	var clock := Conductor.new()
	clock.set_manual(1.0)
	var fb := Fretboard.new()
	fb.conductor = clock
	var played: Array = []
	fb.played.connect(func(note: String, string: String, time: float) -> void:
		played.append("%s:%s@%.1f" % [note, string, time]))
	actions.call(fb, clock)
	clock.set_manual(1.2)
	fb.update()
	fb.free()
	clock.free()
	return played
