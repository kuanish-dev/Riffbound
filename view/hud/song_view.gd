class_name SongView
extends HudLayer

const BEND_MARK := [Vector2(10, -6), Vector2(22, -26), Vector2(14, -22), Vector2(22, -17)]
const SHIFT_ZONE_ALPHA := 0.14
const RIFF_ALPHA := 0.07
const BADGE_SIZE := 20
const LIFE_R := 7.0
const LIFE_GAP := 22.0


static func draw_top(ci: CanvasItem) -> void:
	var performance := Game.performance
	ListArt.top_panel(ci)
	var title := "%s · %s" % [performance.song.get("name", ""), Difficulty.current()["name"]]
	Glyph.title(ci, Vector2(20, 36), title, 21, Color.WHITE)
	var score := "%d" % performance.score
	var right := 1070.0 if Game.touch else 1250.0
	var width := Glyph.TITLE.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	Glyph.title(ci, Vector2(right - width, 38), score, 26, Ink.GOLD)
	_draw_lives(ci, right - width - 24.0)
	var progress := clampf(Game.conductor.now() / maxf(performance.end_time, 0.001), 0.0, 1.0)
	ci.draw_rect(Rect2(0, Layout.TOP_H - 3, Layout.SCREEN.x * progress, 3), Ink.GOLD)


static func _draw_lives(ci: CanvasItem, right: float) -> void:
	for i in SongJudge.MISTAKES_TO_FAIL:
		var center := Vector2(right - i * LIFE_GAP, 28)
		if i < Game.performance.lives():
			ci.draw_circle(center, LIFE_R, Ink.RED, true, -1.0, true)
		else:
			ci.draw_arc(center, LIFE_R, 0.0, TAU, 20, Ink.DIM, 1.5, true)


func _draw() -> void:
	draw_top(self)
	Lanes.draw(self, strikes)
	var now := Lanes.slot_now()
	if Game.needs.get("positions", false):
		_draw_riffs(now)
		_draw_shift_zones(now)
	var previous := {}
	for note: Dictionary in Game.performance.notes:
		if _visible(note, now):
			_draw_note(note, previous.get(note["string"], {}), now)
		previous[note["string"]] = note
	_draw_shift_hint()


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


func _draw_riffs(now: float) -> void:
	var notes := Game.performance.notes
	var first := 0
	for i in notes.size():
		var last := i == notes.size() - 1
		if last or int(notes[i + 1]["pos"]) != int(notes[i]["pos"]):
			_draw_riff(notes[first], notes[i], now)
			first = i + 1


func _draw_riff(first: Dictionary, last: Dictionary, now: float) -> void:
	var area := Lanes.rect()
	var x0 := maxf(Lanes.slot_x(float(first["slot"]), now) - Lanes.NOTE_R - 2, Lanes.left())
	var x1 := minf(Lanes.slot_x(float(last["slot"]) + float(last["len"]), now), area.end.x)
	if x1 <= x0:
		return
	var ink := Ink.of_position(int(first["pos"]))
	draw_rect(Rect2(x0, area.position.y + 4, x1 - x0, area.size.y - 8), Color(ink, RIFF_ALPHA))
	draw_line(Vector2(x0, area.end.y - 5), Vector2(x1, area.end.y - 5), Color(ink, 0.7), 3.0)


func _draw_shift_zones(now: float) -> void:
	var previous := {}
	for note: Dictionary in Game.performance.notes:
		if not previous.is_empty() and int(note["pos"]) != int(previous["pos"]):
			_draw_shift_zone(previous, note, now)
		previous = note


func _draw_shift_zone(before: Dictionary, after: Dictionary, now: float) -> void:
	var area := Lanes.rect()
	var to_slot := float(after["slot"])
	var from_slot := minf(float(before["slot"]) + float(before["len"]), to_slot - 0.5)
	var x0 := maxf(Lanes.slot_x(from_slot, now), Lanes.left())
	var x1 := Lanes.slot_x(to_slot, now) - Lanes.NOTE_R - 6
	if x1 < Lanes.left() or x0 > area.end.x:
		return
	draw_rect(Rect2(x0, area.position.y + 4, maxf(2.0, x1 - x0), area.size.y - 8), Color(Ink.GOLD, SHIFT_ZONE_ALPHA))
	draw_dashed_line(Vector2(x1, area.position.y + 6), Vector2(x1, area.end.y - 6), Ink.GOLD, 2.0, 6.0)
	var delta := int(after["pos"]) - int(before["pos"])
	var label := Cue.shift_label(signi(delta), absi(delta))
	_draw_badge(Vector2(x1, area.position.y + 6), label, Ink.of_position(int(after["pos"])))


func _draw_badge(right_top: Vector2, text: String, fill: Color) -> void:
	var width := Glyph.TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_SIZE).x + 16
	var box := Rect2(right_top.x - width, right_top.y, width, BADGE_SIZE + 8)
	draw_rect(box, fill)
	Glyph.title(self, Vector2(box.position.x + 8, box.end.y - 6), text, BADGE_SIZE, Ink.PANEL)


func _draw_shift_hint() -> void:
	var shift := Cue.shift()
	if shift.is_empty():
		return
	var text := "рука: %s" % Cue.shift_label(int(shift["dir"]), int(shift["steps"]))
	var ink := Color(Ink.GOLD, Cue.blink(t))
	Glyph.neon(self, Vector2(Layout.HIT_X + 130, Lanes.rect().end.y - 22), text, 24, ink)


static func _ink(note: Dictionary) -> Color:
	if note["state"] == "hit":
		return Ink.GOLD
	if note["state"] == "miss":
		return Ink.RED
	return Ink.of_position(int(note["pos"]))
