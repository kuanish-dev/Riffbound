class_name Harmony

const QUALITIES := {"": [0, 4, 7], "m": [0, 3, 7], "5": [0, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10], "dim": [0, 3, 6]}
const PROGRESSIONS := {"minor": [[0, "m"], [0, "m"], [8, ""], [10, ""]], "major": [[0, ""], [0, ""], [5, ""], [7, ""]]}
const ACCIDENTALS := {"": 0, "#": 1, "b": -1}
const DEGREES := {"root": 0, "octave": 12}


static func parse(name: String) -> Dictionary:
	var m := RegEx.create_from_string("^([A-G])([#b]?)(.*)$").search(name)
	if m == null or not QUALITIES.has(m.get_string(3)):
		return {}
	var root := posmod(Tuning.KEY_NAMES.find(m.get_string(1)) + int(ACCIDENTALS[m.get_string(2)]), 12)
	var tones: Array[int] = []
	for step: int in QUALITIES[m.get_string(3)]:
		tones.append((root + step) % 12)
	return {"root": root, "quality": m.get_string(3), "tones": tones}


static func name_of(root: int, quality: String) -> String:
	return Tuning.KEY_NAMES[posmod(root, 12)] + quality


static func progression(key: int, minor: bool) -> Array[String]:
	var out: Array[String] = []
	for step: Array in PROGRESSIONS["minor" if minor else "major"]:
		out.append(name_of(key + int(step[0]), String(step[1])))
	return out


static func at(bars: Array, beat: float) -> String:
	if bars.is_empty():
		return ""
	var bar := floori(beat / Timing.BEATS_PER_BAR)
	var parts := String(bars[posmod(bar, bars.size())]).split(" ", false)
	var within := (beat - bar * Timing.BEATS_PER_BAR) / Timing.BEATS_PER_BAR
	return parts[mini(floori(within * parts.size()), parts.size() - 1)]


static func in_bar(spec: String, slot: int) -> String:
	var parts := spec.split(" ", false)
	@warning_ignore("integer_division")
	return parts[mini(slot * parts.size() / Timing.SLOTS_PER_BAR, parts.size() - 1)]


static func degree(chord: Dictionary, name: String) -> int:
	if DEGREES.has(name):
		return int(DEGREES[name])
	for step: int in [7, 6, 8]:
		if (chord["tones"] as Array).has((int(chord["root"]) + step) % 12):
			return step
	return 7


static func role(chord: Dictionary, midi: int) -> String:
	if chord.is_empty():
		return ""
	var pc := posmod(midi, 12)
	if pc == int(chord["root"]):
		return "root"
	return "tone" if (chord["tones"] as Array).has(pc) else ""
