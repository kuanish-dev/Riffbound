class_name SampleBank
extends RefCounted

const DIR := "res://assets/guitar/"
const NOTES := [40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 86]
const DEAD := ["dead_1", "dead_2", "dead_3"]
const DEAD_PITCH := {"low": 1.0, "mid": 1.12, "high": 1.26}

var notes := {}
var _dead: Array[AudioStream] = []
var _dead_next := 0


func build() -> void:
	for midi: int in NOTES:
		notes[midi] = load(DIR + "%d.ogg" % midi)
	for name: String in DEAD:
		_dead.append(load(DIR + name + ".ogg"))


static func sample_midi(midi: int) -> int:
	var best: int = NOTES[0]
	for m: int in NOTES:
		if absi(m - midi) < absi(best - midi):
			best = m
	return best


func note(midi: int) -> AudioStream:
	return notes[sample_midi(midi)]


func dead() -> AudioStream:
	_dead_next = (_dead_next + 1) % _dead.size()
	return _dead[_dead_next]
