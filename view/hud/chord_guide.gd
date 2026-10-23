class_name ChordGuide
extends RefCounted

const GRID := {"x": 70.0, "step": 62.0, "r": 18.0}
const NAME_SIZE := 24


static func now() -> String:
	return Harmony.at(Game.chords, Game.conductor.player_time() / Timing.beat_len())


static func draw(ci: CanvasItem) -> void:
	var name := now()
	var chord := Harmony.parse(name)
	if chord.is_empty():
		return
	var top := Lanes.rect().position.y + 24
	Glyph.neon_left(ci, Vector2(Layout.HIT_X + 14, top + 2), name, NAME_SIZE, Ink.GOLD)
	_draw_upcoming(ci, name, top)
	_draw_grid(ci, chord)


static func _draw_upcoming(ci: CanvasItem, name: String, top: float) -> void:
	var slot_now := Lanes.slot_now()
	var area := Lanes.rect()
	var free_x := Layout.HIT_X + 40 + Glyph.TITLE.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
	var last_beat := ceili((slot_now + (area.end.x - Layout.HIT_X) / Layout.SLOT_PX) / Timing.SLOTS_PER_BEAT)
	var shown := name
	for beat in range(floori(slot_now / Timing.SLOTS_PER_BEAT) + 1, last_beat):
		var next := Harmony.at(Game.chords, beat)
		if next == shown:
			continue
		shown = next
		var x := Lanes.slot_x(beat * Timing.SLOTS_PER_BEAT, slot_now)
		if x > free_x and x < area.end.x - 40:
			Glyph.title(ci, Vector2(x + 6, top), next, 18, Ink.DIM)


static func _draw_grid(ci: CanvasItem, chord: Dictionary) -> void:
	for string: String in Notes.STRINGS:
		for c in Notes.FRETS.size():
			var at := Vector2(Layout.HIT_X + float(GRID["x"]) + c * float(GRID["step"]), Lanes.lane_y(string))
			_draw_cell(ci, at, Notes.FRETS[c], string, chord)


static func _draw_cell(ci: CanvasItem, at: Vector2, fret: String, string: String, chord: Dictionary) -> void:
	var r := float(GRID["r"])
	var role := Harmony.role(chord, Game.tuning.midi(fret, string))
	if role.is_empty():
		Glyph.note(ci, at, Lanes.fret_label(fret), r, Color(Ink.DIM, 0.35), Color(Ink.PANEL, 0.9))
	else:
		Glyph.note(ci, at, Lanes.fret_label(fret), r, Ink.PANEL, Ink.GOLD if role == "root" else Ink.CHORD_TONE)
	var held: Dictionary = Game.fretboard.ringing.get(string, {})
	if not held.is_empty() and held["note"] == fret:
		ci.draw_arc(at, r + 5, 0.0, TAU, 28, Color.WHITE, 2.5, true)
