class_name Tuning
extends RefCounted
## Строй гитары: тональность, гамма и позиция руки на грифе. Кнопка (струна + лад) — ступень гаммы:
## следующая струна начинается через NOTES_PER_STRING ступеней («три ноты на струну»), а 4-й лад
## (мизинец) достаёт первую ноту соседней струны — как на настоящей гитаре, соседние струны перекрываются.
## Позиция сдвигает всю сетку на одну струну. Высоты — MIDI-номера.

const SCALES := [
	{"id": "minor_pentatonic", "name": "минорная пентатоника", "steps": [0, 3, 5, 7, 10]},
	{"id": "blues", "name": "блюзовая", "steps": [0, 3, 5, 6, 7, 10]},
	{"id": "natural_minor", "name": "натуральный минор", "steps": [0, 2, 3, 5, 7, 8, 10]},
	{"id": "harmonic_minor", "name": "гармонический минор", "steps": [0, 2, 3, 5, 7, 8, 11]},
	{"id": "dorian", "name": "дорийский", "steps": [0, 2, 3, 5, 7, 9, 10]},
	{"id": "major_pentatonic", "name": "мажорная пентатоника", "steps": [0, 2, 4, 7, 9]},
	{"id": "major", "name": "мажор", "steps": [0, 2, 4, 5, 7, 9, 11]},
	{"id": "chromatic", "name": "хроматика", "steps": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]},
]
const KEY_NAMES := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const SOLFEGE := ["до", "до#", "ре", "ре#", "ми", "фа", "фа#", "соль", "соль#", "ля", "ля#", "си"]
const BASE_MIDI := 48           ## C3: тоника на нижней струне в позиции 0 — BASE_MIDI + key
const NOTES_PER_STRING := 3
const MIDI_MIN := 40            ## E2 — диапазон сэмплов гитары
const MIDI_MAX := 88            ## E6
const BEND_SEMITONES := 2.0     ## бенд — на тон вверх
## Строй по умолчанию — ми, минорная пентатоника (с него начинается джем).
const SONG := {"key": 4, "scale": "minor_pentatonic"}

var key := 4                    ## индекс в KEY_NAMES
var scale := 0                  ## индекс в SCALES
var position := 0


static func song() -> Tuning:
	var tuning := Tuning.new()
	tuning.key = int(SONG["key"])
	tuning.scale = scale_index(String(SONG["scale"]))
	return tuning


static func scale_index(id: String) -> int:
	for i in SCALES.size():
		if SCALES[i]["id"] == id:
			return i
	return 0


func steps() -> Array:
	return SCALES[scale]["steps"]


func midi(fret: String, string: String) -> int:
	return _midi_at(fret, string, position)


## Высоты ноты на струне (аккорд — несколько, глушняк — ни одной).
func midis(note: String, string: String) -> Array[int]:
	var out: Array[int] = []
	for fret: String in Notes.parts(note):
		out.append(midi(fret, string))
	return out


## Влезают ли все девять нот позиции в диапазон сэмплов.
func fits(at_position: int) -> bool:
	for string: String in Notes.STRINGS:
		for fret: String in Notes.FRETS:
			var m := _midi_at(fret, string, at_position)
			if m < MIDI_MIN or m > MIDI_MAX:
				return false
	return true


func shift_position(delta: int) -> bool:
	if not fits(position + delta):
		return false
	position += delta
	return true


## Тональность и гамма разом (трек джема): позиция остаётся, если влезает в диапазон.
func set_key(new_key: int, scale_id: String) -> void:
	key = new_key
	scale = scale_index(scale_id)
	_keep_in_range()


func cycle_scale() -> void:
	scale = (scale + 1) % SCALES.size()
	_keep_in_range()


func shift_key(delta: int) -> void:
	key = posmod(key + delta, KEY_NAMES.size())
	_keep_in_range()


## Минорная ли гамма (есть малая терция) — от этого зависит гармония подложки.
func is_minor() -> bool:
	return steps().has(3)


func title() -> String:
	return "%s %s" % [KEY_NAMES[key], SCALES[scale]["name"]]


static func hz(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)


## «E3».
static func note_name(midi_note: int) -> String:
	@warning_ignore("integer_division")
	return "%s%d" % [KEY_NAMES[posmod(midi_note, 12)], midi_note / 12 - 1]


static func solfege(midi_note: int) -> String:
	return SOLFEGE[posmod(midi_note, 12)]


func _midi_at(fret: String, string: String, at_position: int) -> int:
	var all_steps := steps()
	var degree := (Notes.STRINGS.find(string) + at_position) * NOTES_PER_STRING + Notes.FRETS.find(fret)
	var octave := floori(float(degree) / all_steps.size())
	return BASE_MIDI + key + 12 * octave + int(all_steps[posmod(degree, all_steps.size())])


func _keep_in_range() -> void:
	if not fits(position):
		position = 0
