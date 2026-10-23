class_name Conductor
extends Node

enum Source { AUDIO, DELTA, MANUAL }

const SEEK_LATE := 0.01
const CLICK_DB := -3.0
const SILENT_DB := -80.0

var source := Source.AUDIO
var input_offset := 0.0
var player: AudioStreamPlayer
var click: AudioStreamPlayer
var running := false
var loop_len := 1.0
var loop_start := 0.0
var offset := 0.0
var _time := 0.0
var _loops := 0
var _last_raw := 0.0


func _init() -> void:
	process_priority = -10


func setup() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -5.0
	add_child(player)
	click = AudioStreamPlayer.new()
	click.volume_db = SILENT_DB
	add_child(click)
	if DisplayServer.get_name() == "headless":
		source = Source.DELTA


func set_music(stream: AudioStream, seconds: float, start_at := 0.0, downbeat := 0.0) -> void:
	player.stream = stream
	loop_len = maxf(seconds, 0.1)
	loop_start = start_at
	offset = downbeat


func start() -> void:
	_time = 0.0
	_loops = 0
	_last_raw = loop_start
	running = true
	if source == Source.AUDIO and player != null and player.stream != null:
		_play()


func stop() -> void:
	running = false
	if player != null:
		player.stop()
		click.stop()


func set_click(stream: AudioStream) -> void:
	click.stream = stream


func set_click_on(on: bool) -> void:
	click.volume_db = CLICK_DB if on else SILENT_DB


func set_manual(time: float) -> void:
	source = Source.MANUAL
	running = true
	_time = time


func _process(delta: float) -> void:
	if not running:
		return
	if source == Source.DELTA:
		_time += delta
	elif source == Source.AUDIO and player != null and player.stream != null:
		if not player.playing or player.get_playback_position() >= loop_start + loop_len + SEEK_LATE:
			_play()


func _play() -> void:
	player.play(loop_start)
	if click.stream != null:
		click.play(0.0)


func now() -> float:
	if running and source == Source.AUDIO and player != null and player.playing:
		var raw := player.get_playback_position()
		if raw < _last_raw - loop_len * 0.5:
			_loops += 1
		_last_raw = raw
		var t := _loops * loop_len + raw - loop_start - offset + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		_time = maxf(_time, t)
	return _time


func music_position() -> float:
	if source == Source.AUDIO and player != null and player.playing:
		return player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return loop_start + fposmod(_time + offset, loop_len)


func player_time() -> float:
	return now() - input_offset


func slot_f() -> float:
	return now() / Timing.slot_len()


func beat_f() -> float:
	return now() / Timing.beat_len()
