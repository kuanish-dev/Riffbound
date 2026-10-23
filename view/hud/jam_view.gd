class_name JamView
extends HudLayer

const PLAYED_MAX := 48

var _played: Array[Dictionary] = []


func clear_played() -> void:
	_played.clear()


func add_played(note: String, string: String, time: float, legato: bool) -> void:
	_played.append({"note": note, "string": string, "t": time, "legato": legato})
	if _played.size() > PLAYED_MAX:
		_played.pop_front()


func _draw() -> void:
	_draw_top()
	Lanes.draw(self, strikes, {}, t)
	ChordGuide.draw(self)
	_draw_played()
	if Game.more and not Game.touch:
		NoteMap.draw(self)
	LoopBar.draw(self)


func _draw_top() -> void:
	ListArt.top_panel(self)
	Glyph.neon_left(self, Vector2(20, 36), "ДЖЕМ", 22, Ink.GOLD)
	var bpm := float(Game.music.get("bpm", 0.0))
	var tempo := "%d bpm" % roundi(bpm) if bpm > 0.0 else "темп? (Тап)"
	var click := " + метроном" if Game.metronome else ""
	Glyph.text(self, Vector2(110, 34), "%s · %s%s" % [Game.music.get("name", ""), tempo, click], 18, Color.WHITE)
	if Game.more:
		Glyph.text(self, Vector2(20, Layout.TOP_H + 26), Game.tuning.title(), 17, Ink.GOLD)


func _draw_played() -> void:
	var now := Lanes.slot_now()
	var area := Lanes.rect()
	for item: Dictionary in _played:
		var x := Lanes.slot_x(float(item["t"]) / Timing.slot_len(), now)
		if x >= Lanes.left() and x <= area.end.x:
			var r := Lanes.NOTE_R * (0.7 if item["legato"] else 1.0)
			Glyph.note(self, Vector2(x, Lanes.lane_y(String(item["string"]))), Lanes.fret_label(String(item["note"])), r)
