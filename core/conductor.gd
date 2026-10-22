class_name Conductor
extends Node
## Музыкальные часы. Время песни берётся из позиции звука, а не из кадров, иначе ритм «плывёт»:
## позиция плеера + время с последнего смешивания − задержка вывода; обороты лупа считаются.
## Без звука (headless) часы идут по delta кадра, в тестах время выставляется вручную.

enum Source { AUDIO, DELTA, MANUAL }

var source := Source.AUDIO
## Калибровка: на сколько секунд игрок бьёт позже, чем слышит долю.
var input_offset := 0.0
var player: AudioStreamPlayer
var running := false
var _loop_len := 0.0
var _time := 0.0
var _loops := 0
var _last_raw := 0.0


func _init() -> void:
	process_priority = -10


func setup(loop_seconds: float) -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -5.0
	add_child(player)
	_loop_len = loop_seconds
	if DisplayServer.get_name() == "headless":
		source = Source.DELTA


## Подложка — луп длиной loop_seconds; часы считают по ней. Сменить можно только до start().
func set_music(music: AudioStreamWAV) -> void:
	player.stream = music


func start() -> void:
	_time = 0.0
	_loops = 0
	_last_raw = 0.0
	running = true
	if source == Source.AUDIO and player != null:
		player.play(0.0)


func stop() -> void:
	running = false
	if player != null:
		player.stop()


## Тесты: часы стоят, время задаётся вручную.
func set_manual(time: float) -> void:
	source = Source.MANUAL
	running = true
	_time = time


func _process(delta: float) -> void:
	if running and source == Source.DELTA:
		_time += delta


## Время песни в секундах, не убывает.
func now() -> float:
	if running and source == Source.AUDIO and player != null and player.playing:
		var raw := player.get_playback_position()
		if raw < _last_raw - _loop_len * 0.5:
			_loops += 1
		_last_raw = raw
		var t := _loops * _loop_len + raw + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		_time = maxf(_time, t)
	return _time


## Время по меркам игрока — с поправкой калибровки. По нему оцениваются удары.
func player_time() -> float:
	return now() - input_offset


func slot_f() -> float:
	return now() / Timing.SLOT_LEN


func beat_f() -> float:
	return now() / Timing.BEAT_LEN
