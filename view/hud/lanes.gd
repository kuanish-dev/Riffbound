class_name Lanes
extends RefCounted

const LANE := {"high": -1.0, "mid": 0.0, "low": 1.0}
const LABELS_W := 60.0
const NOTE_R := 16.0
const STRING_LINE := Color(0.78, 0.74, 0.66, 0.45)
const STRING_HOT := Color(1.0, 0.92, 0.7, 0.9)
const VIBRATO := {"amp": 5.0, "waves": 9.0, "speed": 70.0, "steps": 96}


static func rect() -> Rect2:
	return Layout.HIGHWAY_TOUCH if Game.touch and Game.state in ["song", "jam"] else Layout.HIGHWAY


static func slot_now() -> float:
	return Game.conductor.player_time() / Timing.slot_len()


static func slot_x(slot: float, now: float) -> float:
	return Layout.HIT_X + (slot - now) * Layout.SLOT_PX


static func lane_y(string: String) -> float:
	return Layout.HIGHWAY.get_center().y + float(LANE.get(string, 0.0)) * Layout.LANE_GAP


static func left() -> float:
	return rect().position.x + LABELS_W


static func fret_label(fret: String) -> String:
	if Game.touch or fret == Notes.MUTE:
		return fret
	return InputConfig.key_label(InputConfig.fret_action(fret))


static func draw(ci: CanvasItem, strikes: Strikes) -> void:
	var area := rect()
	var now := slot_now()
	ci.draw_rect(area, Ink.PANEL)
	_draw_bar_lines(ci, area, now)
	for string: String in Game.tuning.strings:
		_draw_string(ci, string, area, strikes)
	ci.draw_line(Vector2(Layout.HIT_X, area.position.y + 8), Vector2(Layout.HIT_X, area.end.y - 8), Color(1, 1, 1, 0.9), 4.0)


static func _draw_bar_lines(ci: CanvasItem, area: Rect2, now: float) -> void:
	var first := floori(now - (Layout.HIT_X - area.position.x) / Layout.SLOT_PX)
	var last := ceili(now + (area.end.x - Layout.HIT_X) / Layout.SLOT_PX)
	for s in range(first, last + 1):
		var x := slot_x(s, now)
		var bar := posmod(s, Timing.SLOTS_PER_BAR) == 0
		var beat := posmod(s, Timing.SLOTS_PER_BEAT) == 0
		if (bar or beat) and x >= area.position.x + LABELS_W and x <= area.end.x - 2:
			ci.draw_line(Vector2(x, area.position.y + 12), Vector2(x, area.end.y - 12), Color(1, 1, 1, 0.16 if bar else 0.05),
				2.0 if bar else 1.0)


static func _draw_string(ci: CanvasItem, string: String, area: Rect2, strikes: Strikes) -> void:
	var y := lane_y(string)
	var x0 := area.position.x + LABELS_W
	var width := 3.0 - Notes.STRINGS.find(string) * 0.5
	var shake := strikes.shake(string)
	if shake <= 0.01:
		ci.draw_line(Vector2(x0, y), Vector2(area.end.x, y), STRING_LINE, width)
		return
	var age := strikes.age(string)
	var steps := int(VIBRATO["steps"])
	var points := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var wave := sin(k * TAU * float(VIBRATO["waves"]) - age * float(VIBRATO["speed"]))
		points.append(Vector2(lerpf(x0, area.end.x, k), y + float(VIBRATO["amp"]) * shake * sin(k * PI) * wave))
	ci.draw_polyline(points, STRING_LINE.lerp(STRING_HOT, shake), width, true)

