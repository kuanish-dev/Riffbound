class_name Hud
extends Node2D

var _strikes := Strikes.new()
var _screens := {}
var _keys: KeyControls
var _touch: TouchControls
var _toast: Toast


func _ready() -> void:
	_screens = {"menu": MenuView.new(), "song": SongView.new(), "results": ResultsView.new(), "jam": JamView.new(),
		"shop": ShopView.new()}
	for state: String in _screens:
		_add_layer(_screens[state])
	_keys = _add_layer(KeyControls.new()) as KeyControls
	_touch = _add_layer(TouchControls.new()) as TouchControls
	_toast = Toast.new()
	add_child(_toast)


func _process(delta: float) -> void:
	_strikes.advance(delta)
	for state: String in _screens:
		(_screens[state] as HudLayer).visible = state == Game.state
	_keys.visible = not Game.touch
	_touch.visible = Game.touch


func reset() -> void:
	_jam().clear_played()


func toast(text: String) -> void:
	_toast.show_text(text)


func on_voiced(_note: String, string: String, corrected: bool) -> void:
	if not corrected:
		_strikes.strike(string)


func played_note(note: String, string: String, time: float, legato: bool) -> void:
	if Game.state == "jam":
		_jam().add_played(note, string, time, legato)


func on_slid(from: String, to: String) -> void:
	_touch.on_slid(from, to)


func _add_layer(layer: HudLayer) -> HudLayer:
	layer.strikes = _strikes
	add_child(layer)
	return layer


func _jam() -> JamView:
	return _screens["jam"]
