class_name SampleBank
extends RefCounted
## Сэмплы гитары (assets/guitar — CC0, см. CREDITS.md): настоящая гитара, пропущенная через перегруз
## и кабинет (tools/build_assets.py), по ноте на малую терцию от E2 до D6. Нота между сэмплами — ближайший
## сэмпл с подтяжкой высоты (не больше полутора полутонов — на слух незаметно). Глухой «чк» — три
## записи по кругу; струна задаёт ему высоту (DEAD_PITCH).

const DIR := "res://assets/guitar/"
const NOTES := [40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 86]
const DEAD := ["dead_1", "dead_2", "dead_3"]
const DEAD_PITCH := {"low": 1.0, "mid": 1.12, "high": 1.26}

var notes := {}           ## MIDI сэмпла → AudioStream
var _dead: Array[AudioStream] = []
var _dead_next := 0


func build() -> void:
	for midi: int in NOTES:
		notes[midi] = load(DIR + "%d.ogg" % midi)
	for name: String in DEAD:
		_dead.append(load(DIR + name + ".ogg"))


## Ближайший к ноте сэмпл (его MIDI).
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
