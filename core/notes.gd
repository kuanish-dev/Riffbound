class_name Notes

const FRETS := ["1", "2", "3", "4"]
const STRINGS := ["low", "mid", "high"]
const MUTE := "X"

const STRING_NAMES := {"low": "нижняя", "mid": "средняя", "high": "верхняя"}


static func from_frets(held: Dictionary) -> String:
	var top := MUTE
	for fret: String in FRETS:
		if held.get(fret, false):
			top = fret
	return top


static func parts(id: String) -> Array:
	return [] if id == MUTE else [id]


static func title(id: String) -> String:
	return "глушняк" if id == MUTE else "лад %s" % id
