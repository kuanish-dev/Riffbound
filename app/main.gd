class_name Main
extends Node
## Точка сборки симулятора гитары: строй, звук, часы, гитара, песня, лупер, сцена, интерфейс.
## Режимы (Game.state): меню → песня → итог; меню → джем. Клавиши режимов — COMMANDS.
## Игра на гитаре превращается в события {kind, string, fret, pos, midis, amount}: их играет голос
## гитары, записывает лупер, а в песне ещё и оценивает SongJudge.
## Музыка — «подложка» (music_choices): стиль барабанов и баса Backing.STYLES, собранный под темп и
## тональность, или трек Tracks со своим темпом и тональностью. Грузит её _load_<kind>.

## Режим → действие ввода → метод. «*» — во всех режимах.
const COMMANDS := {
	"*": {"position_down": "_position_down", "position_up": "_position_up",
		"offset_down": "_offset_down", "offset_up": "_offset_up"},
	"menu": {"menu_up": "_menu_up", "menu_down": "_menu_down", "start": "start_song", "jam": "start_jam", "quit": "quit"},
	"song": {"quit": "_to_menu"},
	"results": {"start": "start_song", "quit": "_to_menu"},
	"jam": {"quit": "_to_menu", "record": "_jam_record", "undo_layer": "_jam_undo", "save_song": "_jam_save_song",
		"delete_song": "_jam_delete_song", "export_midi": "_jam_export", "key_down": "_jam_key_down",
		"key_up": "_jam_key_up", "scale": "_jam_scale", "backing": "_jam_backing", "tap_tempo": "_jam_tap"},
}
const TAP_MIN := 6                      ## ударов тап-темпа, чтобы принять темп
const TAP_GAP := 2.0                    ## пауза дольше — тап начинается заново
const TAP_DONE := 1.2                   ## столько секунд без ударов после TAP_MIN — темп принят
const TAP_BPM := Vector2(50.0, 220.0)

var conductor: Conductor
var fretboard: Fretboard
var performance: SongJudge
var tuning: Tuning
var looper: Looper
var bank: SampleBank
var voices: GuitarVoices
var stage: StageView
var hud: Hud
var touch_pad: TouchPad
var _layer_voices: Array[GuitarVoices] = []
var _backings := {}                     ## «стиль:тональность:лад:темп» → AudioStreamWAV
var _jam_tuning := Tuning.song()        ## строй джема живёт между заходами; в песне — строй песни
var _jam_bpm := Timing.DEFAULT_BPM      ## темп джема под стиль барабанов (меняется тап-темпом)
var _taps: Array[float] = []            ## тап-темп: время ударов (с, по часам системы)
var _tap_from := 0.0                    ## где звучал файл музыки на первом ударе
var _asked_permissions := false


func _ready() -> void:
	DevArgs.parse()
	InputConfig.register()
	ThemeDB.fallback_font = Glyph.text_font()
	if DevArgs.has("test"):
		set_process(false)
		set_process_unhandled_input(false)
		DevTools.run_tests(self)
		return
	Songs.load_saved()
	bank = SampleBank.new()
	bank.build()
	tuning = Tuning.song()
	looper = Looper.new()
	conductor = Conductor.new()
	add_child(conductor)
	conductor.setup()
	fretboard = Fretboard.new()
	fretboard.conductor = conductor
	add_child(fretboard)
	voices = GuitarVoices.new()
	add_child(voices)
	voices.setup(bank)
	performance = SongJudge.new()
	Game.conductor = conductor
	Game.fretboard = fretboard
	Game.tuning = tuning
	Game.looper = looper
	Game.voices = voices
	Game.performance = performance
	stage = StageView.new()
	add_child(stage)
	var stage_fx := FxLayer.new("stage")
	add_child(stage_fx)
	hud = Hud.new()
	add_child(hud)
	var fx := FxLayer.new("top")
	add_child(fx)
	# сенсор: на телефоне и планшете сам, на компьютере — флаг --touch (мышь работает как палец)
	if DevArgs.has("touch"):
		Input.emulate_touch_from_mouse = true
	Game.touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	touch_pad = TouchPad.new()
	touch_pad.active = Game.touch
	add_child(touch_pad)
	for listener: Object in [self, stage, hud, stage_fx, fx]:
		fretboard.voiced.connect(Callable(listener, "on_voiced"))
	fretboard.played.connect(_on_played)
	fretboard.slurred.connect(_on_slurred)
	fretboard.muted.connect(_on_muted)
	fretboard.bent.connect(_on_bent)
	for listener: Object in [stage, hud, stage_fx, fx]:
		performance.fact.connect(Callable(listener, "on_fact"))
	get_tree().on_request_permissions_result.connect(_on_permission)
	Game.menu_index = clampi(DevArgs.get_int("song", 1) - 1, 0, Songs.all().size() - 1)
	Game.jam_backing = DevArgs.get_str("backing", Game.jam_backing)
	if DevArgs.has("sim"):
		DevTools.simulate(self)
	elif DevArgs.has("screenshot"):
		DevTools.screenshot(self)
	elif DevArgs.has("play"):
		start_song()
	elif DevArgs.has("jam"):
		start_jam()


func start_song() -> void:
	var song: Dictionary = Songs.all()[Game.menu_index]
	_leave_music()
	var song_tuning := Tuning.new()
	song_tuning.key = int(song["key"])
	song_tuning.scale = Tuning.scale_index(String(song["scale"]))
	_use_tuning(song_tuning)
	var choice := music(String(song["backing"]))
	call("_load_" + String(choice["kind"]), choice, Songs.bpm_of(song))
	# ноты песни записаны в её темпе — он главнее темпа трека
	Timing.bpm = Songs.bpm_of(song)
	performance.start(song)
	tuning.position = int(performance.next_note().get("pos", 0))
	_begin("song")


func start_jam() -> void:
	_leave_music()
	_use_tuning(_jam_tuning)
	_scan_tracks()
	_load_jam_music(true)
	_begin("jam")
	hud.toast("Джем: играй свободно. R — записать луп, V — подложка, T — тап-темп")


func _use_tuning(value: Tuning) -> void:
	tuning = value
	Game.tuning = value


func _begin(state: String) -> void:
	Game.state = state
	looper.length = Looper.BARS * Timing.bar_len()
	fretboard.cancel()
	stage.reset()
	hud.reset()
	conductor.start()


func _to_menu() -> void:
	_leave_music()
	conductor.stop()
	Game.state = "menu"


func _leave_music() -> void:
	voices.silence()
	looper.reset()
	_sync_layer_voices()
	_taps.clear()


func _process(_delta: float) -> void:
	var due := looper.tick(conductor.now())
	_sync_layer_voices()
	for item: Dictionary in due:
		_layer_voices[int(item["layer"])].play(item["event"])
	_tap_tick()
	if Game.state != "song":
		return
	performance.update(conductor.player_time())
	if performance.finished:
		Game.last_result = performance.result()
		Game.last_result["record"] = Songs.record(String(performance.song["id"]), performance.result())
		Game.state = "results"
		conductor.stop()
		voices.silence()


func _unhandled_input(event: InputEvent) -> void:
	for table: Dictionary in [COMMANDS["*"], COMMANDS.get(Game.state, {})]:
		for action: String in table:
			if event.is_action_pressed(action):
				call(String(table[action]))
				return


## Выход: сначала глушим звук и даём аудиопотоку пару кадров убрать проигрывания,
## иначе Godot при выходе ругается на утёкшие AudioStreamPlayback.
func quit(code := 0) -> void:
	_leave_music()
	conductor.stop()
	for i in 3:
		await get_tree().process_frame
	get_tree().quit(code)


# --- гитара → голос, лупер, оценка ------------------------------------------

func on_voiced(note: String, string: String, _corrected: bool) -> void:
	var kind := "dead" if note == Notes.MUTE else "pluck"
	_perform({"kind": kind, "string": string, "fret": note, "pos": tuning.position, "midis": tuning.midis(note, string)})


func _on_played(note: String, string: String, time: float) -> void:
	if Game.state == "song":
		performance.play(string, _midi(note, string), time, false)
	hud.played_note(note, string, time, false)


func _on_slurred(note: String, string: String, time: float) -> void:
	_perform({"kind": "slur", "string": string, "fret": note, "pos": tuning.position, "midis": tuning.midis(note, string)})
	if Game.state == "song":
		performance.play(string, _midi(note, string), time, true)
	hud.played_note(note, string, time, true)


func _on_muted(string: String, time: float) -> void:
	_perform({"kind": "mute", "string": string})
	if Game.state == "song":
		performance.mute(string, time)


func _on_bent(string: String, amount: float, time: float) -> void:
	_perform({"kind": "bend", "string": string, "amount": amount})
	if Game.state == "song":
		performance.bend(string, amount, time)


func _perform(event: Dictionary) -> void:
	voices.play(event)
	looper.capture(event, conductor.now())


func _midi(note: String, string: String) -> int:
	var midis := tuning.midis(note, string)
	return midis[0] if not midis.is_empty() else -1


# --- музыка -----------------------------------------------------------------

## Подложки по кругу (V в джеме): стили барабанов, затем треки — встроенные и свои.
static func music_choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for style: Dictionary in Backing.STYLES:
		out.append({"id": style["id"], "name": style["name"], "kind": "style"})
	for track: Dictionary in Tracks.all():
		var choice := track.duplicate()
		choice["kind"] = "track"
		out.append(choice)
	return out


static func music(id: String) -> Dictionary:
	var choices := music_choices()
	return choices[maxi(0, _music_index(choices, id))]


static func _music_index(choices: Array[Dictionary], id: String) -> int:
	for i in choices.size():
		if choices[i]["id"] == id:
			return i
	return -1


## Стиль: луп Looper.BARS тактов в темпе bpm и тональности строя.
func _load_style(choice: Dictionary, bpm: float) -> void:
	Timing.bpm = bpm
	conductor.set_music(_backing(String(choice["id"])), Looper.BARS * Timing.bar_len())


## Трек: свой темп. Свой трек без темпа крутится целиком, пока его не протапают (T).
func _load_track(choice: Dictionary, bpm: float) -> void:
	var stream := Tracks.load_stream(choice)
	if stream == null:
		Game.music["problem"] = "файл не читается — играем без подложки"
		hud.toast("«%s»: %s" % [choice["name"], Game.music["problem"]])
		_load_style(music("none"), bpm)
		return
	stream.set("loop", true)
	Timing.bpm = float(choice["bpm"]) if float(choice["bpm"]) > 0.0 else bpm
	var bars := int(choice["bars"])
	if bars == 0 and float(choice["bpm"]) > 0.0:
		bars = Tracks.fit_bars(stream.get_length(), float(choice["start"]), Timing.bar_len())
	var seconds := bars * Timing.bar_len() if bars > 0 else stream.get_length()
	conductor.set_music(stream, seconds, float(choice.get("start", 0.0)), float(choice["offset"]))


func _backing(id: String) -> AudioStreamWAV:
	var key := "%s:%d:%s:%.2f" % [id, tuning.key, tuning.is_minor(), Timing.bpm]
	if not _backings.has(key):
		_backings[key] = Backing.render(id, tuning.key, tuning.is_minor())
	return _backings[key]


# --- меню и общие команды ---------------------------------------------------

func _menu_up() -> void:
	Game.menu_index = posmod(Game.menu_index - 1, Songs.all().size())


func _menu_down() -> void:
	Game.menu_index = posmod(Game.menu_index + 1, Songs.all().size())


func _position_down() -> void:
	_shift_position(-1)


func _position_up() -> void:
	_shift_position(1)


func _shift_position(delta: int) -> void:
	if tuning.shift_position(delta):
		hud.toast("Позиция %d: %s–%s" % [tuning.position, Tuning.note_name(tuning.midi("1", "low")),
			Tuning.note_name(tuning.midi("3", "high"))])
	else:
		hud.toast("Дальше по грифу некуда")


func _offset_down() -> void:
	conductor.input_offset = clampf(conductor.input_offset - 0.005, -0.2, 0.2)


func _offset_up() -> void:
	conductor.input_offset = clampf(conductor.input_offset + 0.005, -0.2, 0.2)


# --- джем -------------------------------------------------------------------

func _jam_record() -> void:
	if looper.start_recording(conductor.now()):
		hud.toast("Запись: один круг, %d такта" % Looper.BARS)
	elif looper.recording:
		hud.toast("Запись уже идёт")
	else:
		hud.toast("Слоёв уже %d — сотри последний (Backspace)" % Looper.MAX_LAYERS)


func _jam_undo() -> void:
	if looper.undo():
		_sync_layer_voices()
		hud.toast("Слой стёрт, осталось %d" % looper.layers.size())


## Последний слой лупера — в список песен: его можно играть по табу, как обычную песню.
func _jam_save_song() -> void:
	if looper.layers.is_empty():
		hud.toast("Сначала запиши луп (R)")
		return
	var song := Songs.from_layer(looper.layers.back(), tuning, Game.jam_backing)
	if (song["notes"] as Array).is_empty():
		hud.toast("В слое нет нот")
		return
	Songs.add_my(song)
	hud.toast("«%s» в списке песен: %s" % [song["name"], song["text"]])


func _jam_delete_song() -> void:
	var removed := Songs.remove_last_my()
	Game.menu_index = clampi(Game.menu_index, 0, Songs.all().size() - 1)
	hud.toast("«%s» удалена" % removed["name"] if not removed.is_empty() else "Своих песен нет")


func _jam_export() -> void:
	if looper.layers.is_empty():
		hud.toast("Сначала запиши луп (R)")
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := Tracks.user_dir().path_join("riffbound-%s.mid" % stamp)
	var error := MidiFile.save(path, looper.layers)
	hud.toast("MIDI сохранён: %s" % path if error == OK else "Не удалось сохранить MIDI (%s)" % error_string(error))


func _jam_key_down() -> void:
	tuning.shift_key(-1)
	_jam_retune("Тональность")


func _jam_key_up() -> void:
	tuning.shift_key(1)
	_jam_retune("Тональность")


func _jam_scale() -> void:
	tuning.cycle_scale()
	_jam_retune("Гамма")


func _jam_backing() -> void:
	var choices := music_choices()
	var next := (maxi(0, _music_index(choices, Game.jam_backing)) + 1) % choices.size()
	Game.jam_backing = String(choices[next]["id"])
	_restart_jam_music(true)
	var hint := ""
	if Game.music.has("problem"):
		hint = " · " + String(Game.music["problem"])
	elif float(Game.music.get("bpm", 1.0)) <= 0.0:
		hint = " · темп неизвестен — тапни T в такт с сильной доли"
	elif next == choices.size() - 1:
		hint = " · свои треки — в папку %s" % Tracks.user_dir()
	hud.toast("Подложка: %s · %s%s" % [Game.music["name"], tuning.title(), hint])


## Строй сменили сами. Свой трек запоминает тональность; стиль барабанов собирается под неё заново.
func _jam_retune(what: String) -> void:
	var track := Tracks.find(Game.jam_backing)
	if track.get("user", false):
		track["key"] = tuning.key
		track["scale"] = Tuning.SCALES[tuning.scale]["id"]
		Tracks.remember(track, Songs.persist)
	if Game.music["kind"] == "style":
		_restart_jam_music(false)
	hud.toast("%s · %s" % [what, tuning.title()])


## Круг заново с выбранной подложкой. retune — взять тональность трека (при входе и смене подложки;
## свой трек помнит тональность, выбранную игроком).
## Слои лупера остаются, если темп тот же: их время отсчитывается от начала круга.
func _restart_jam_music(retune: bool) -> void:
	looper.cancel_recording()
	conductor.stop()
	_load_jam_music(retune)
	conductor.start()


func _load_jam_music(retune: bool) -> void:
	var choice := music(Game.jam_backing)
	Game.music = choice
	if retune and int(choice.get("key", -1)) >= 0:
		tuning.set_key(int(choice["key"]), String(choice["scale"]))
	var before := Timing.bpm
	call("_load_" + String(choice["kind"]), choice, _jam_bpm)
	Game.music["bpm"] = Timing.bpm if float(choice.get("bpm", 1.0)) > 0.0 else 0.0
	if not is_equal_approx(before, Timing.bpm):
		looper.reset()
		_sync_layer_voices()
	looper.length = Looper.BARS * Timing.bar_len()


func _scan_tracks() -> void:
	# Android: файлы из «Музыки» читаются только с разрешением — спросить один раз, ответ пересканирует папку
	if OS.has_feature("android") and not _asked_permissions:
		_asked_permissions = true
		OS.request_permissions()
	Tracks.scan_user()


func _on_permission(_permission: String, granted: bool) -> void:
	if granted:
		Tracks.scan_user()


# --- тап-темп ---------------------------------------------------------------

## Удар тап-темпа (T): стучи в такт, начиная с сильной доли; после TAP_MIN ударов и паузы темп принят.
func _jam_tap() -> void:
	var clock := Time.get_ticks_msec() / 1000.0
	if not _taps.is_empty() and clock - _taps.back() > TAP_GAP:
		_taps.clear()
	if _taps.is_empty():
		_tap_from = conductor.music_position()
	_taps.append(clock)
	if _taps.size() >= 2:
		hud.toast("Тап-темп: %d bpm%s" % [roundi(_tap_bpm()),
			" · ещё %d" % (TAP_MIN - _taps.size()) if _taps.size() < TAP_MIN else " · хватит, жди"])


func _tap_bpm() -> float:
	return tap_bpm(_taps)


## Темп по ударам (секунды): средний промежуток между первым и последним.
static func tap_bpm(taps: Array[float]) -> float:
	return 60.0 * (taps.size() - 1) / maxf(taps.back() - taps.front(), 0.001)


func _tap_tick() -> void:
	if _taps.is_empty() or Time.get_ticks_msec() / 1000.0 - _taps.back() < TAP_DONE:
		return
	if _taps.size() >= TAP_MIN:
		var bpm := snappedf(clampf(_tap_bpm(), TAP_BPM.x, TAP_BPM.y), 0.1)
		call("_tap_" + String(Game.music["kind"]), bpm)
	_taps.clear()


## Стиль барабанов: тап задаёт темп джема.
func _tap_style(bpm: float) -> void:
	_jam_bpm = bpm
	_restart_jam_music(false)
	hud.toast("Темп джема: %s bpm" % bpm)


## Свой трек: тап задаёт темп и сильную долю (первый удар), это запоминается. У встроенного темп известен.
func _tap_track(bpm: float) -> void:
	var track := Tracks.find(Game.jam_backing)
	if not track.get("user", false):
		hud.toast("У этого трека темп известен: %s bpm" % track["bpm"])
		return
	track["bpm"] = bpm
	track["start"] = Tracks.first_downbeat(_tap_from, bpm)
	Tracks.remember(track, Songs.persist)
	_restart_jam_music(false)
	hud.toast("«%s»: %s bpm, сильная доля на %.2f с — запомнено" % [track["name"], bpm, track["start"]])


## У каждого слоя лупера свой голос гитары.
func _sync_layer_voices() -> void:
	while _layer_voices.size() < looper.layers.size():
		var layer := GuitarVoices.new()
		add_child(layer)
		layer.setup(bank)
		_layer_voices.append(layer)
	while _layer_voices.size() > looper.layers.size():
		var layer: GuitarVoices = _layer_voices.pop_back()
		layer.silence()
		layer.queue_free()
