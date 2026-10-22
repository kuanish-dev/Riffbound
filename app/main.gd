class_name Main
extends Node
## Точка сборки симулятора гитары: строй, звук, часы, гитара, песня, лупер, сцена, интерфейс.
## Режимы (Game.state): меню → песня → итог; меню → джем. Клавиши режимов — COMMANDS.
## Игра на гитаре превращается в события {kind, string, fret, pos, midis, amount}: их играет голос
## гитары, записывает лупер, а в песне ещё и оценивает SongJudge.

## Режим → действие ввода → метод. «*» — во всех режимах.
const COMMANDS := {
	"*": {"position_down": "_position_down", "position_up": "_position_up",
		"offset_down": "_offset_down", "offset_up": "_offset_up"},
	"menu": {"menu_up": "_menu_up", "menu_down": "_menu_down", "start": "start_song", "jam": "start_jam", "quit": "quit"},
	"song": {"quit": "_to_menu"},
	"results": {"start": "start_song", "quit": "_to_menu"},
	"jam": {"quit": "_to_menu", "record": "_jam_record", "undo_layer": "_jam_undo", "save_song": "_jam_save_song",
		"delete_song": "_jam_delete_song", "export_midi": "_jam_export", "key_down": "_jam_key_down",
		"key_up": "_jam_key_up", "scale": "_jam_scale", "backing": "_jam_backing"},
}

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
var _backings := {}                     ## «подложка:тональность:лад» → AudioStreamWAV
var _rng := RandomNumberGenerator.new()
var _jam_tuning := Tuning.song()        ## строй джема живёт между заходами; в песне — строй песни


func _ready() -> void:
	DevArgs.parse()
	InputConfig.register()
	if DevArgs.has("test"):
		set_process(false)
		set_process_unhandled_input(false)
		DevTools.run_tests(self)
		return
	_rng.seed = 7
	Songs.load_saved()
	bank = SampleBank.new()
	bank.build(_rng)
	tuning = Tuning.song()
	looper = Looper.new()
	looper.length = Synth.loop_seconds()
	conductor = Conductor.new()
	add_child(conductor)
	conductor.setup(Synth.loop_seconds())
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
	hud = Hud.new()
	add_child(hud)
	# сенсор: на телефоне и планшете сам, на компьютере — флаг --touch (мышь работает как палец)
	Game.touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or DevArgs.has("touch")
	touch_pad = TouchPad.new()
	touch_pad.active = Game.touch
	add_child(touch_pad)
	fretboard.voiced.connect(_on_voiced)
	fretboard.voiced.connect(stage.on_voiced)
	fretboard.voiced.connect(hud.on_voiced)
	fretboard.played.connect(_on_played)
	fretboard.slurred.connect(_on_slurred)
	fretboard.muted.connect(_on_muted)
	fretboard.bent.connect(_on_bent)
	performance.fact.connect(stage.on_fact)
	performance.fact.connect(hud.on_fact)
	Game.menu_index = clampi(DevArgs.get_int("song", 1) - 1, 0, Songs.all().size() - 1)
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
	performance.start(song)
	tuning.position = int(performance.next_note().get("pos", 0))
	conductor.set_music(_backing(String(song["backing"])))
	_begin("song")


func start_jam() -> void:
	_leave_music()
	_use_tuning(_jam_tuning)
	conductor.set_music(_backing(Game.jam_backing))
	_begin("jam")
	hud.toast("Джем: играй свободно. R — записать луп, Enter — сохранить его как песню")


func _use_tuning(value: Tuning) -> void:
	tuning = value
	Game.tuning = value


func _begin(state: String) -> void:
	Game.state = state
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


func _process(_delta: float) -> void:
	var due := looper.tick(conductor.now())
	_sync_layer_voices()
	for item: Dictionary in due:
		_layer_voices[int(item["layer"])].play(item["event"])
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

func _on_voiced(note: String, string: String, _corrected: bool) -> void:
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
		hud.toast("Запись: один круг, %d такта" % Synth.BARS)
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
	var path := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Riffbound/riffbound-%s.mid" % stamp)
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
	var next := (Synth.backing_index(Game.jam_backing) + 1) % Synth.BACKINGS.size()
	Game.jam_backing = String(Synth.BACKINGS[next]["id"])
	_jam_retune("Подложка: %s" % Synth.BACKINGS[next]["name"])


## Подложка зависит от тональности и лада — пересобрать и начать круг заново.
## Слои лупера остаются: их время отсчитывается от начала круга.
func _jam_retune(what: String) -> void:
	looper.cancel_recording()
	conductor.stop()
	conductor.set_music(_backing(Game.jam_backing))
	conductor.start()
	hud.toast("%s · %s" % [what, tuning.title()])


func _backing(id: String) -> AudioStreamWAV:
	var key := "%s:%d:%s" % [id, tuning.key, tuning.is_minor()]
	if not _backings.has(key):
		_backings[key] = Synth.to_wav(Synth.backing(id, tuning.key, tuning.is_minor(), _rng), true)
	return _backings[key]


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
