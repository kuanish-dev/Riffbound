class_name StringVoice
extends Node

const RELEASE := 0.06
const BEND_SPEED := 16.0
const GLIDE_SPEED := 30.0
const VOLUME_DB := -1.0

var bank: SampleBank
var silent := false
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _sample_midis: Array = []
var _midis: Array = []
var _bend := 0.0
var _bend_target := 0.0
var _glide := 0.0
var _fade := -1.0


func pluck(event: Dictionary) -> void:
	var streams: Array = []
	var samples: Array = []
	for midi: int in event["midis"]:
		streams.append(bank.note(midi))
		samples.append(SampleBank.sample_midi(midi))
	_start(streams, event["midis"], samples)


func dead(event: Dictionary) -> void:
	_start([bank.dead()], [], [])
	if not silent:
		_players[0].pitch_scale = float(SampleBank.DEAD_PITCH[event["string"]])


func slur(event: Dictionary) -> void:
	var midis: Array = event["midis"]
	if _active == 0 or _sample_midis.is_empty():
		pluck(event)
		return
	for i in range(midis.size(), _active):
		_players[i].stop()
	_active = mini(_active, midis.size())
	if event.get("glide", false) and not _midis.is_empty() and not midis.is_empty():
		_glide += float(_midis[0]) - float(midis[0])
	_midis = midis.slice(0, _active)
	_fade = -1.0
	_apply_pitch()


func mute(_event: Dictionary) -> void:
	if _active > 0:
		_fade = RELEASE


func bend(event: Dictionary) -> void:
	_bend_target = float(event["amount"]) * Tuning.BEND_SEMITONES


func silence() -> void:
	for player in _players:
		player.stop()
	_active = 0
	_fade = -1.0


func _process(delta: float) -> void:
	if _active == 0:
		_bend = _bend_target
		_glide = 0.0
		return
	if _bend != _bend_target or _glide != 0.0:
		_bend = move_toward(_bend, _bend_target, BEND_SPEED * delta)
		_glide = move_toward(_glide, 0.0, GLIDE_SPEED * delta)
		_apply_pitch()
	if _fade > 0.0:
		_fade -= delta
		var gain := maxf(_fade / RELEASE, 0.0)
		for i in _active:
			_players[i].volume_db = _volume() + linear_to_db(maxf(gain, 0.0001))
		if _fade <= 0.0:
			silence()


func _start(streams: Array, midis: Array, samples: Array) -> void:
	if silent:
		return
	silence()
	_sample_midis = samples.duplicate()
	_midis = midis.duplicate()
	_glide = 0.0
	_active = streams.size()
	for i in _active:
		var player := _player(i)
		player.stream = streams[i]
		player.volume_db = _volume()
		player.play()
	_apply_pitch()


func _apply_pitch() -> void:
	for i in mini(_active, _midis.size()):
		_players[i].pitch_scale = pow(2.0, (float(_midis[i]) + _bend + _glide - float(_sample_midis[i])) / 12.0)


func _volume() -> float:
	return VOLUME_DB - 3.0 * (maxi(_active, 1) - 1)


func _player(index: int) -> AudioStreamPlayer:
	while _players.size() <= index:
		var player := AudioStreamPlayer.new()
		player.bus = GuitarVoices.LEAD_BUS
		add_child(player)
		_players.append(player)
	return _players[index]
