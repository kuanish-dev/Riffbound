class_name LayerSong
extends RefCounted

const EVENT_NOTES := {
	"pluck": {"legato": false},
	"slur": {"legato": true},
	"dead": {"legato": false},
}


static func notes(events: Array) -> Array[Dictionary]:
	var start := Songs.LEAD_IN * Timing.SLOTS_PER_BAR
	var loop_slots := Looper.BARS * Timing.SLOTS_PER_BAR
	var out: Array[Dictionary] = []
	var sounding := {}
	for event: Dictionary in events:
		var slot := start + posmod(roundi(float(event["t"]) / Timing.slot_len()), loop_slots)
		_apply(event, slot, out, sounding)
	for string: String in sounding:
		_close(sounding[string], start + loop_slots)
	return _one_per_slot(out)


static func _apply(event: Dictionary, slot: int, out: Array[Dictionary], sounding: Dictionary) -> void:
	var string := String(event["string"])
	if event.has("amount"):
		if float(event["amount"]) > 0.0 and sounding.has(string):
			sounding[string]["bend"] = true
		return
	if sounding.has(string):
		_close(sounding[string], slot)
		sounding.erase(string)
	var note := _note(event, slot)
	if note.is_empty():
		return
	out.append(note)
	if note["fret"] != Notes.MUTE:
		sounding[string] = note


static func _note(event: Dictionary, slot: int) -> Dictionary:
	var kind := String(event["kind"])
	if not EVENT_NOTES.has(kind):
		return {}
	var legato: bool = EVENT_NOTES[kind]["legato"]
	return {"slot": slot, "string": String(event["string"]), "fret": String(event.get("fret", Notes.MUTE)),
		"pos": int(event.get("pos", 0)), "legato": legato, "bend": false, "len": 1, "tech": "h" if legato else ""}


static func _close(note: Dictionary, slot: int) -> void:
	note["len"] = maxi(1, slot - int(note["slot"]))


static func _one_per_slot(notes: Array[Dictionary]) -> Array[Dictionary]:
	var seen := {}
	var unique: Array[Dictionary] = []
	for note in notes:
		var key := "%s:%d" % [note["string"], note["slot"]]
		if not seen.has(key):
			seen[key] = true
			unique.append(note)
	unique.sort_custom(Songs.by_time)
	return unique
