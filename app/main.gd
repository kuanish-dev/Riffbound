class_name Main
extends Node

const COMMANDS := {
	"*": {"position_down": "common.position_down", "position_up": "common.position_up",
		"offset_down": "common.offset_down", "offset_up": "common.offset_up", "metronome": "common.toggle_metronome"},
	"menu": {"menu_up": "common.menu_up", "menu_down": "common.menu_down", "start": "start_song", "jam": "start_jam",
		"shop": "open_shop", "quit": "quit"},
	"shop": {"menu_up": "shop.up", "menu_down": "shop.down", "start": "shop.take", "listen": "listen", "quit": "_to_menu"},
	"song": {"quit": "_to_menu"},
	"results": {"start": "start_song", "quit": "_to_menu"},
	"jam": {"quit": "_to_menu", "record": "jam.record", "undo_layer": "jam.undo", "save_song": "jam.save_song",
		"delete_song": "jam.delete_song", "export_midi": "jam.export_midi", "key_down": "jam.key_down",
		"key_up": "jam.key_up", "scale": "jam.next_scale", "backing": "jam.next_backing", "tap_tempo": "jam.tap",
		"jam": "jam.toggle_more"},
}
const COMMAND_SOUNDS := {
	"*": {"offset_down": "tick", "offset_up": "tick"},
	"menu": {"menu_up": "move", "menu_down": "move", "start": "start", "jam": "start", "shop": "select", "quit": "back"},
	"song": {"quit": "back"},
	"results": {"start": "start", "quit": "back"},
	"jam": {"quit": "back", "key_down": "shift", "key_up": "shift", "scale": "toggle_on", "backing": "select"},
	"shop": {"menu_up": "move", "menu_down": "move", "quit": "back"},
}

var conductor: Conductor
var fretboard: Fretboard
var performance: SongJudge
var looper: Looper
var voices: GuitarVoices
var layers: LayerVoices
var style: StyleMeter
var stage: StageView
var style_view: StyleView
var hud: Hud
var touch_pad: TouchPad
var feedback: Feedback
var music: MusicLoader
var jam: JamSession
var shop: ShopScreen
var common: CommonCommands
var router: GuitarRouter
var stage_fx: FxLayer
var fx: FxLayer
var shaker: Shaker
var _layers_seen := 0


func _ready() -> void:
	DevArgs.parse()
	InputConfig.register()
	ThemeDB.fallback_font = Glyph.text_font()
	if DevArgs.has("test"):
		_run_tests()
		return
	Songs.load_saved()
	Shop.load_saved()
	SceneBuilder.build(self)
	_connect_listeners()
	_apply_dev_args()
	_start_dev_mode()


func start_song() -> void:
	var song: Dictionary = Songs.all()[Game.menu_index]
	_leave_music()
	Game.tuning = _tuning_of(song)
	music.load_music(MusicLoader.find(String(song["backing"])), Songs.bpm_of(song), Songs.chords_of(song))
	Timing.bpm = Songs.bpm_of(song)
	performance.start(song)
	Game.tuning.position = int(performance.next_note().get("pos", 0))
	Game.needs = _needs_of(performance.notes, Game.tuning.position)
	_begin("song")


func start_jam() -> void:
	_leave_music()
	Game.tuning = jam.tuning
	jam.start()
	Game.needs = {"bend": true, "positions": true}
	_begin("jam")
	hud.toast("Джем: играй что хочешь")


func open_shop() -> void:
	shop.open()


func listen() -> void:
	shop.listen()


func quit(code := 0) -> void:
	fretboard.process_mode = Node.PROCESS_MODE_DISABLED
	music.finish_prerender()
	_leave_music()
	conductor.stop()
	feedback.stop()
	for i in 3:
		await get_tree().process_frame
	get_tree().quit(code)


func _process(_delta: float) -> void:
	_tick_looper()
	jam.tick()
	music.prerender_tick()
	shop.tick()
	if Game.state == "song":
		_tick_song()


func _unhandled_input(event: InputEvent) -> void:
	for scope: String in ["*", Game.state]:
		var table: Dictionary = COMMANDS.get(scope, {})
		for action: String in table:
			if event.is_action_pressed(action):
				_run(String(table[action]))
				feedback.play(String((COMMAND_SOUNDS.get(scope, {}) as Dictionary).get(action, "")))
				return


func _run(command: String) -> void:
	var parts := command.split(".")
	var target: Object = self if parts.size() == 1 else get(parts[0])
	target.call(parts[-1])


func _run_tests() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	TestRunner.run(self)


func _connect_listeners() -> void:
	touch_pad.row_selected.connect(feedback.play.bind("move"))
	touch_pad.slid.connect(hud.on_slid)
	for listener: Object in [router, stage, hud, stage_fx, fx]:
		fretboard.voiced.connect(Callable(listener, "on_voiced"))
	for listener: Object in [feedback, stage, stage_fx, fx, style, shaker]:
		performance.fact.connect(Callable(listener, "on_fact"))
	for listener: Object in [feedback, style_view, stage_fx, fx, shaker]:
		style.ranked.connect(Callable(listener, "on_ranked"))
	get_tree().on_request_permissions_result.connect(jam.on_permission)


func _apply_dev_args() -> void:
	Game.menu_index = clampi(DevArgs.get_int("song", 1) - 1, 0, Songs.all().size() - 1)
	Game.jam_backing = DevArgs.get_str("backing", Game.jam_backing)
	Game.metronome = DevArgs.has("metronome")
	Game.more = DevArgs.has("more")


func _start_dev_mode() -> void:
	if DevArgs.has("sim"):
		Simulation.run(self)
	elif DevArgs.has("tones"):
		ToneMeter.run(self)
	elif DevArgs.has("screenshot"):
		Screenshot.take(self)
	elif DevArgs.has("play"):
		start_song()
	elif DevArgs.has("jam"):
		start_jam()


static func _tuning_of(song: Dictionary) -> Tuning:
	var tuning := Tuning.new()
	tuning.set_key(int(song["key"]), String(song["scale"]))
	return tuning


static func _needs_of(notes: Array, position: int) -> Dictionary:
	return {"bend": notes.any(func(n: Dictionary) -> bool: return n["bend"]),
		"positions": notes.any(func(n: Dictionary) -> bool: return int(n["pos"]) != position)}


func _begin(state: String) -> void:
	Game.state = state
	looper.length = Looper.BARS * Timing.bar_len()
	fretboard.cancel()
	stage.reset()
	hud.reset()
	style.reset()
	style_view.reset()
	feedback.reset()
	music.start_clock()


func _to_menu() -> void:
	music.restart_prerender()
	shop.stop_listening()
	Game.more = false
	_leave_music()
	conductor.stop()
	Game.state = "menu"


func _leave_music() -> void:
	voices.silence()
	looper.reset()
	layers.sync(0)
	jam.leave()


func _tick_looper() -> void:
	var due := looper.tick(conductor.now())
	if looper.layers.size() > _layers_seen:
		feedback.play("layer")
	_layers_seen = looper.layers.size()
	layers.sync(_layers_seen)
	layers.play(due)


func _tick_song() -> void:
	performance.update(conductor.player_time())
	style.update(conductor.player_time())
	if performance.finished:
		_finish_song()


func _finish_song() -> void:
	var result := performance.result()
	result.merge(style.result())
	Game.last_result = result.duplicate()
	Game.last_result["record"] = Songs.record(String(performance.song["id"]), result)
	Game.last_result["coins"] = Shop.reward(result)
	feedback.play("finish")
	if Game.last_result["record"]:
		feedback.play("record_new")
	Game.state = "results"
	conductor.stop()
	voices.silence()
