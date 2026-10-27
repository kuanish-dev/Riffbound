class_name NoteMap
extends RefCounted

const CELL_OFF := Color(0.14, 0.13, 0.2)
const CELL_RINGING := Color(0.4, 0.36, 0.2)
const CELL_EDGE := Color(0.5, 0.48, 0.6)


static func draw(ci: CanvasItem) -> void:
	var map := Layout.MAP
	ci.draw_rect(map, Color(Ink.PANEL, 0.92))
	var strings := Game.tuning.strings.duplicate()
	strings.reverse()
	var cell := Vector2(map.size.x / (Notes.FRETS.size() + 1.0), map.size.y / strings.size())
	var chord := Harmony.parse(ChordGuide.now())
	for r in strings.size():
		var top := map.position.y + r * cell.y
		_draw_row(ci, String(strings[r]), Rect2(map.position.x, top, map.size.x, cell.y), cell.x, chord)


static func _draw_row(ci: CanvasItem, string: String, row: Rect2, cell_w: float, chord: Dictionary) -> void:
	var key := InputConfig.key_label("strike")
	Glyph.text(ci, Vector2(row.position.x + 12, row.position.y + row.size.y * 0.5 + 6), key, 18, Ink.DIM)
	for c in Notes.FRETS.size():
		var box := Rect2(row.position.x + (c + 1) * cell_w + 4, row.position.y + 4, cell_w - 8, row.size.y - 8)
		_draw_cell(ci, box, Notes.FRETS[c], string, chord)


static func _draw_cell(ci: CanvasItem, box: Rect2, fret: String, string: String, chord: Dictionary) -> void:
	var ringing: Dictionary = Game.fretboard.ringing.get(string, {})
	var lit: bool = not ringing.is_empty() and ringing["note"] == fret
	var midi := Game.tuning.midi(fret, string)
	var role := Harmony.role(chord, midi)
	ci.draw_rect(box, CELL_RINGING if lit else CELL_OFF)
	if not role.is_empty():
		ci.draw_rect(box, Color(Ink.GOLD if role == "root" else Ink.CHORD_TONE, 0.25))
	ci.draw_rect(box, Ink.GOLD if lit else CELL_EDGE, false, 2.0)
	Glyph.text_center(ci, box.get_center().x, box.position.y + box.size.y * 0.5 + 2, Tuning.note_name(midi), 20, Color.WHITE)
	var key := InputConfig.key_label(InputConfig.fret_action(fret))
	Glyph.text_center(ci, box.get_center().x, box.end.y - 6, "%s · %s" % [key, Tuning.solfege(midi)], 12, Ink.DIM)
