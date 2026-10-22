class_name StringVoice
extends Node
## Одна струна: одна нота за раз (аккорд-двузвучие — несколько голосов этой струны).
## Нота звенит, пока её не заглушат (mute — короткий спад) или не затухнет сама.
## Легато и бенд меняют высоту звучащего сэмпла (pitch_scale), не начиная ноту заново.
## Команды — события гитары {kind, string, midis, amount}: pluck, slur, mute, dead, bend.

const RELEASE := 0.06       ## секунд спада при глушении
const BEND_SPEED := 16.0    ## полутонов в секунду — с такой скоростью тянется бенд
const VOLUME_DB := -4.0

var bank: SampleBank
var silent := false         ## без звукового вывода (headless) голоса не создаются
var _players: Array[AudioStreamPlayer] = []
var _active := 0            ## сколько голосов звучит
var _sample_midis: Array = []
var _midis: Array = []
var _bend := 0.0
var _bend_target := 0.0
var _fade := -1.0           ## > 0 — идёт спад после глушения


func pluck(event: Dictionary) -> void:
	var streams: Array = []
	for midi: int in event["midis"]:
		streams.append(bank.notes[clampi(midi, Tuning.MIDI_MIN, Tuning.MIDI_MAX)])
	_start(streams, event["midis"])


func dead(event: Dictionary) -> void:
	_start([bank.dead[event["string"]]], [])


## Легато: звучащая струна переходит на новую ноту без нового щипка.
func slur(event: Dictionary) -> void:
	var midis: Array = event["midis"]
	if _active == 0 or _sample_midis.is_empty():
		pluck(event)
		return
	for i in range(midis.size(), _active):
		_players[i].stop()
	_active = mini(_active, midis.size())
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
		return
	if _bend != _bend_target:
		_bend = move_toward(_bend, _bend_target, BEND_SPEED * delta)
		_apply_pitch()
	if _fade > 0.0:
		_fade -= delta
		var gain := maxf(_fade / RELEASE, 0.0)
		for i in _active:
			_players[i].volume_db = _volume() + linear_to_db(maxf(gain, 0.0001))
		if _fade <= 0.0:
			silence()


func _start(streams: Array, midis: Array) -> void:
	if silent:
		return
	silence()
	_sample_midis = midis.duplicate()
	_midis = midis.duplicate()
	_active = streams.size()
	for i in _active:
		var player := _player(i)
		player.stream = streams[i]
		player.volume_db = _volume()
		player.play()
	_apply_pitch()


func _apply_pitch() -> void:
	for i in mini(_active, _midis.size()):
		_players[i].pitch_scale = pow(2.0, (float(_midis[i]) + _bend - float(_sample_midis[i])) / 12.0)


## Аккорд звучит тише каждой ноты, чтобы в сумме не громче одиночной.
func _volume() -> float:
	return VOLUME_DB - 3.0 * (maxi(_active, 1) - 1)


func _player(index: int) -> AudioStreamPlayer:
	while _players.size() <= index:
		var player := AudioStreamPlayer.new()
		player.bus = GuitarVoices.LEAD_BUS
		add_child(player)
		_players.append(player)
	return _players[index]
