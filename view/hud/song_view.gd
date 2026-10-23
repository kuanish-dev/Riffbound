class_name SongView
extends HudLayer

const BEND_MARK := [Vector2(10, -6), Vector2(22, -26), Vector2(14, -22), Vector2(22, -17)]


static func draw_top(ci: CanvasItem) -> void:
	var performance := Game.performance
	ListArt.top_panel(ci)
	Glyph.title(ci, Vector2(20, 36), String(performance.song.get("name", "")), 21, Color.WHITE)
	var score := "%d" % performance.score
	var right := 1070.0 if Game.touch else 1250.0
	var width := Glyph.TITLE.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	Glyph.title(ci, Vector2(right - width, 38), score, 26, Ink.GOLD)
	var progress := clampf(Game.conductor.now() / maxf(performance.end_time, 0.001), 0.0, 1.0)
	ci.draw_rect(Rect2(0, Layout.TOP_H - 3, Layout.SCREEN.x * progress, 3), Ink.GOLD)


func _draw() -> void:
	draw_top(self)
	Lanes.draw(self, strikes, Cue.next(), t)
	var now := Lanes.slot_now()
	_draw_position_changes(now)
	var previous := {}
	for note: Dictionary in Game.performance.notes:
		if _visible(note, now):
			_draw_note(note, previous.get(note["string"], {}), now)
		previous[note["string"]] = note
	_draw_position_hint()


func _visible(note: Dictionary, now: float) -> bool:
	var x := Lanes.slot_x(float(note["slot"]), now)
	var end_x := _end_x(note, now)
	var on_screen := end_x > Lanes.left() and x < Lanes.rect().end.x + Lanes.NOTE_R
	return on_screen and not (note["state"] == "hit" and end_x < Layout.HIT_X)


func _end_x(note: Dictionary, now: float) -> float:
	return Lanes.slot_x(float(note["slot"]) + float(note["len"]), now) - 8.0


func _draw_note(note: Dictionary, previous: Dictionary, now: float) -> void:
	var x := Lanes.slot_x(float(note["slot"]), now)
	var y := Lanes.lane_y(String(note["string"]))
	var ink := _ink(note)
	if int(note["len"]) > 1:
		var from := maxf(x, Layout.HIT_X) if note["state"] == "hit" else x
		draw_line(Vector2(from, y), Vector2(_end_x(note, now), y), Color(ink, 0.55), 8.0, true)
	if note["legato"] and not previous.is_empty():
		var from := Lanes.slot_x(float(previous["slot"]), now)
		draw_arc(Vector2((from + x) * 0.5, y - Lanes.NOTE_R), (x - from) * 0.5, PI, TAU, 16, Color(ink, 0.7), 2.0, true)
	if note["bend"]:
		_draw_bend_mark(Vector2(x, y), ink)
	if not (note["state"] == "hit" and x < Layout.HIT_X):
		Glyph.note(self, Vector2(x, y), Lanes.fret_label(String(note["fret"])), Lanes.NOTE_R, ink)


func _draw_bend_mark(at: Vector2, ink: Color) -> void:
	draw_line(at + BEND_MARK[0], at + BEND_MARK[1], ink, 2.0, true)
	draw_line(at + BEND_MARK[1], at + BEND_MARK[2], ink, 2.0, true)
	draw_line(at + BEND_MARK[1], at + BEND_MARK[3], ink, 2.0, true)


func _draw_position_changes(now: float) -> void:
	var area := Lanes.rect()
	var last_pos := -1
	for note: Dictionary in Game.performance.notes:
		var x := Lanes.slot_x(float(note["slot"]), now)
		var changed := last_pos >= 0 and int(note["pos"]) != last_pos
		if changed and x > Lanes.left() and x < area.end.x + Lanes.NOTE_R:
			var line_x := x - Lanes.NOTE_R - 6
			draw_dashed_line(Vector2(line_x, area.position.y + 6), Vector2(line_x, area.end.y - 6), Ink.GOLD, 2.0, 6.0)
		last_pos = int(note["pos"])


func _draw_position_hint() -> void:
	var next := Game.performance.next_note()
	if next.is_empty() or int(next["pos"]) == Game.tuning.position:
		return
	var up := int(next["pos"]) > Game.tuning.position
	var key := InputConfig.key_label("position_up" if up else "position_down")
	if Game.touch:
		key = "поз →" if up else "← поз"
	Glyph.neon(self, Vector2(Layout.HIT_X + 120, Lanes.rect().end.y - 22), "жми %s" % key, 22, Ink.GOLD)


static func _ink(note: Dictionary) -> Color:
	if note["state"] == "hit":
		return Ink.GOLD
	if note["state"] == "miss":
		return Ink.RED
	return Glyph.INK
