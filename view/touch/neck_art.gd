class_name NeckArt
extends RefCounted

const ROWS := {"high": 0.2, "mid": 0.38, "low": 0.56}
const SLIDE_RUN := 0.16
const SLIDE_FADE := 0.3
const TRAIL_PARTS := 12


static func draw(ci: CanvasItem, cells: Dictionary, s: Dictionary) -> void:
	var whole := _bounds(cells)
	PadArt.panel(ci, whole, PadArt.IDLE)
	for fret: String in cells:
		_draw_cell(ci, cells[fret], fret, s)
	_draw_fret_wires(ci, cells, whole)
	for string: String in ROWS:
		_draw_string(ci, whole, string, s["ringing"].get(string, {}), cells, float(s["t"]))
	for dot: Dictionary in s["dots"]:
		_draw_dot(ci, cells, whole, dot)
	for slide: Dictionary in s["slides"]:
		_draw_slide(ci, cells, whole, slide)
	for finger: Vector2 in s["fingers"]:
		if whole.has_point(finger):
			ci.draw_arc(finger, 30.0, 0.0, TAU, 32, Color(PadArt.NEON, 0.5), 3.0, true)


static func _bounds(cells: Dictionary) -> Rect2:
	var first: Rect2 = cells[cells.keys().front()]
	var last: Rect2 = cells[cells.keys().back()]
	return Rect2(first.position, Vector2(last.end.x - first.position.x, first.size.y))


static func _row_y(whole: Rect2, string: String) -> float:
	return whole.position.y + whole.size.y * float(ROWS[string])


static func _draw_cell(ci: CanvasItem, cell: Rect2, fret: String, s: Dictionary) -> void:
	var inner := cell.grow(-7.0)
	var held: bool = s["held"].has(fret)
	if held:
		ci.draw_rect(inner, Color(PadArt.NEON, 0.22))
		ci.draw_rect(inner, PadArt.NEON, false, 3.0)
	elif s["cued"].has(fret):
		var pulse := float(s["pulse"])
		ci.draw_rect(inner, Color(PadArt.GOLD, 0.25 * pulse))
		ci.draw_rect(inner, Color(PadArt.GOLD, 0.5 + 0.5 * pulse), false, 4.0)
	Glyph.title_center(ci, cell.get_center().x, cell.end.y - 22, fret, 38, Color(Color.WHITE, 1.0 if held else 0.8))


static func _draw_fret_wires(ci: CanvasItem, cells: Dictionary, whole: Rect2) -> void:
	var top := whole.position.y + 10
	var bottom := whole.end.y - 10
	ci.draw_line(Vector2(whole.position.x + 7, top), Vector2(whole.position.x + 7, bottom), PadArt.IDLE.lightened(0.4), 6.0)
	var frets: Array = cells.keys()
	for i in range(1, frets.size()):
		var x := ((cells[frets[i - 1]] as Rect2).end.x + (cells[frets[i]] as Rect2).position.x) * 0.5
		ci.draw_line(Vector2(x, top), Vector2(x, bottom), Color(PadArt.NEON, 0.18), 10.0)
		ci.draw_line(Vector2(x, top), Vector2(x, bottom), PadArt.NEON.darkened(0.25), 3.0)


static func _draw_string(ci: CanvasItem, whole: Rect2, string: String, ringing: Dictionary, cells: Dictionary, t: float) -> void:
	var y := _row_y(whole, string)
	var width := float(PadArt.STRINGS[string]) * 0.8
	ci.draw_line(Vector2(whole.position.x + 7, y), Vector2(whole.end.x, y), Color(PadArt.IDLE.lightened(0.15), 0.8), width, true)
	if ringing.is_empty() or not cells.has(ringing["fret"]):
		return
	var from := (cells[ringing["fret"]] as Rect2).get_center().x
	var points := _vibrating(from, whole.end.x, y, float(ringing["shake"]), t)
	ci.draw_polyline(points, Color(PadArt.NEON, 0.3), width * 3.0 + 4.0, true)
	ci.draw_polyline(points, PadArt.NEON.lightened(0.5), width, true)


static func _vibrating(from: float, to: float, y: float, shake: float, t: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 33:
		var u := i / 32.0
		points.append(Vector2(lerpf(from, to, u), y + shake * 4.0 * sin(PI * u) * sin(u * TAU * 6.0 - t * 70.0)))
	return points


static func _draw_dot(ci: CanvasItem, cells: Dictionary, whole: Rect2, dot: Dictionary) -> void:
	if not cells.has(dot["fret"]):
		return
	var at := Vector2((cells[dot["fret"]] as Rect2).get_center().x, _row_y(whole, String(dot["string"])))
	ci.draw_circle(at, 12.0, Color(dot["ink"] as Color, 0.3), true, -1.0, true)
	ci.draw_circle(at, 7.0, dot["ink"], true, -1.0, true)


static func _draw_slide(ci: CanvasItem, cells: Dictionary, whole: Rect2, slide: Dictionary) -> void:
	if not cells.has(slide["from"]) or not cells.has(slide["to"]):
		return
	var age := float(slide["age"])
	var fade := 1.0 - clampf((age - SLIDE_RUN) / SLIDE_FADE, 0.0, 1.0)
	var y := _row_y(whole, String(slide["string"]))
	var start := Vector2((cells[slide["from"]] as Rect2).get_center().x, y)
	var finish := Vector2((cells[slide["to"]] as Rect2).get_center().x, y)
	var head := start.lerp(finish, ease(clampf(age / SLIDE_RUN, 0.0, 1.0), 0.4))
	for i in TRAIL_PARTS:
		var tail_alpha := fade * float(i + 1) / TRAIL_PARTS
		ci.draw_line(start.lerp(head, float(i) / TRAIL_PARTS), start.lerp(head, float(i + 1) / TRAIL_PARTS),
			Color(PadArt.HOT, tail_alpha), 8.0, true)
	ci.draw_circle(head, 13.0 * fade + 1.0, Color(PadArt.HOT, 0.35 * fade), true, -1.0, true)
	ci.draw_circle(head, 7.0, Color(Color.WHITE, fade), true, -1.0, true)
