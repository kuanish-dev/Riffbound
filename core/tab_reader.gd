class_name TabReader
extends RefCounted

var _song_id := ""
var _notes: Array[Dictionary] = []
var _ringing := {}


static func read(song: Dictionary) -> Array[Dictionary]:
	var reader := TabReader.new()
	reader._song_id = String(song["id"])
	var bars: Array = song["bars"]
	for index in bars.size():
		reader._read_bar(bars[index], index)
	return reader._notes


static func note_of(cell: String, string: String, pos: int, slot: int) -> Dictionary:
	var note := {"slot": slot, "string": string, "pos": pos, "legato": false, "bend": false, "len": 1, "tech": ""}
	if cell[0] in ["h", "p"]:
		note["legato"] = true
		note["tech"] = cell[0]
		cell = cell.substr(1)
	if cell.ends_with("b"):
		note["bend"] = true
		cell = cell.left(-1)
	note["fret"] = Notes.MUTE if cell == "x" else cell
	return note


func _read_bar(bar: Dictionary, index: int) -> void:
	for string: String in Notes.STRINGS:
		if bar.has(string):
			_read_row(String(bar[string]), string, int(bar.get("pos", 0)), index)
		else:
			_ringing.erase(string)


func _read_row(row: String, string: String, pos: int, bar: int) -> void:
	var cells := row.split(" ", false)
	if cells.size() != Timing.SLOTS_PER_BAR:
		push_error("Песня %s, такт %d, струна %s: нужно %d клеток" % [_song_id, bar + 1, string, Timing.SLOTS_PER_BAR])
	for c in cells.size():
		_read_cell(cells[c], string, pos, (Songs.LEAD_IN + bar) * Timing.SLOTS_PER_BAR + c)


func _read_cell(cell: String, string: String, pos: int, slot: int) -> void:
	if cell == "=":
		_hold(string, slot)
		return
	_ringing.erase(string)
	if cell == "-":
		return
	var note := note_of(cell, string, pos, slot)
	_notes.append(note)
	_ringing[string] = note


func _hold(string: String, slot: int) -> void:
	var note: Dictionary = _ringing.get(string, {})
	if not note.is_empty() and int(note["slot"]) + int(note["len"]) == slot:
		note["len"] = int(note["len"]) + 1
