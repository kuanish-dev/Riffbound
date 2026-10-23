class_name Feedback
extends Node

const FACT_SOUNDS := {"miss": "miss", "wrong": "miss", "tech": "tech"}

var ui: UiSounds
var _hud: Hud
var _rank_player: AudioStreamPlayer
var _rank_sounds := {}
var _multiplier := 1


func setup(hud: Hud) -> void:
	_hud = hud
	ui = UiSounds.new()
	add_child(ui)
	_rank_player = AudioStreamPlayer.new()
	_rank_player.volume_db = -6.0
	add_child(_rank_player)


func play(sound: String) -> void:
	ui.play(sound)


func say(sound: String, text: String) -> void:
	_hud.toast(text)
	ui.play(sound)


func reset() -> void:
	_multiplier = 1


func stop() -> void:
	_rank_player.stop()
	ui.stop()


func on_fact(kind: String, _data: Dictionary) -> void:
	ui.play(String(FACT_SOUNDS.get(kind, "")))
	var multiplier := Game.performance.multiplier()
	if multiplier > _multiplier:
		ui.play("mult")
	_multiplier = multiplier


func on_ranked(rank: int, up: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_rank_player.stream = _rank_sound(rank, up)
	_rank_player.play()


func _rank_sound(rank: int, up: bool) -> AudioStream:
	var key := "up:%d" % rank if up else "down"
	if not _rank_sounds.has(key):
		_rank_sounds[key] = Sfx.rank_up(rank) if up else Sfx.rank_down()
	return _rank_sounds[key]
