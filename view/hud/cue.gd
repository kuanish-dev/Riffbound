class_name Cue
extends RefCounted

const LOOKAHEAD := 1.2
const BLINK := 14.0


static func next() -> Dictionary:
	if Game.state != "song":
		return {}
	var now := Game.conductor.player_time()
	var cue := {"frets": [], "strings": [], "bend": false, "power": 0.0}
	var slot := -1
	for note: Dictionary in Game.performance.notes:
		if note["state"] != "wait":
			continue
		var ahead := float(note["t"]) - now
		if (slot >= 0 and int(note["slot"]) != slot) or ahead > LOOKAHEAD:
			break
		slot = int(note["slot"])
		_add_note(cue, note, ahead)
	return cue if slot >= 0 else {}


static func glow(cue: Dictionary, t: float) -> float:
	return float(cue.get("power", 0.0)) * blink(t)


static func blink(t: float) -> float:
	return 0.65 + 0.35 * sin(t * BLINK)


static func shift() -> Dictionary:
	if Game.state != "song" or not Game.needs.get("positions", true):
		return {}
	var next := Game.performance.next_note()
	var delta := int(next.get("pos", Game.tuning.position)) - Game.tuning.position
	return {} if delta == 0 else {"dir": signi(delta), "steps": absi(delta)}


static func shift_label(dir: int, steps: int) -> String:
	var arrows := ("»" if dir > 0 else "«").repeat(steps)
	if Game.touch:
		return arrows
	return "%s %s" % [InputConfig.key_label("position_up" if dir > 0 else "position_down"), arrows]


static func _add_note(cue: Dictionary, note: Dictionary, ahead: float) -> void:
	if note["fret"] != Notes.MUTE:
		cue["frets"].append(note["fret"])
	if not note["legato"]:
		cue["strings"].append(note["string"])
	cue["bend"] = cue["bend"] or note["bend"]
	cue["power"] = 1.0 - clampf(ahead / LOOKAHEAD, 0.0, 1.0)
