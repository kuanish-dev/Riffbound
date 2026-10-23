class_name StringArt
extends RefCounted

const STRING_AT := 0.66
const BOW := 0.32
const STEPS := 48
const SHAKE := {"amp": 6.0, "waves": 4.5, "speed": 70.0}
const RIPPLE := {"amp": 7.0, "waves": 2.0, "speed": 28.0}
const BEND_MARKS := {0.5: "½", 1.0: "1", 1.5: "1½"}


static func draw(ci: CanvasItem, rect: Rect2, s: Dictionary) -> void:
	PadArt.panel(ci, rect, s["edge"], float(s["glow"]) * 0.6)
	var meter := Rect2(rect.end.x - 30, rect.position.y + 16, 12, rect.size.y - 32)
	var span := Vector2(rect.position.x + 18, meter.position.x - 40)
	var y := rect.position.y + rect.size.y * STRING_AT
	var apex := _apex(float(s["apex"]), span)
	var bow := rect.size.y * BOW * float(s["amount"]) / Tuning.BEND_MAX
	var heat := clampf(maxf(float(s["amount"]) / 0.5, float(s["wobble"])), 0.0, 1.0)
	_draw_line(ci, _points(s, span, y, apex, bow), s, heat)
	_draw_stands(ci, span, y)
	if float(s["apex"]) >= 0.0:
		_draw_finger(ci, Vector2(lerpf(span.x, span.y, apex), y - bow))
	_draw_labels(ci, rect, s, span.y, heat)
	_draw_meter(ci, meter, float(s["amount"]), float(s["meter"]))


static func _apex(x: float, span: Vector2) -> float:
	return 0.5 if x < 0.0 else clampf((x - span.x) / (span.y - span.x), 0.2, 0.8)


static func _points(s: Dictionary, span: Vector2, y: float, apex: float, bow: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in STEPS + 1:
		var u := float(i) / STEPS
		points.append(Vector2(lerpf(span.x, span.y, u), y + _offset(u, s, apex, bow)))
	return points


static func _offset(u: float, s: Dictionary, apex: float, bow: float) -> float:
	var lift := sin(PI * 0.5 * (u / apex if u < apex else (1.0 - u) / (1.0 - apex)))
	var t := float(s["t"])
	var tremble := float(s["shake"]) * _wave(SHAKE, u, t) + float(s["wobble"]) * _wave(RIPPLE, u, t)
	return -bow * lift + sin(PI * u) * tremble


static func _wave(wave: Dictionary, u: float, t: float) -> float:
	return float(wave["amp"]) * sin(u * TAU * float(wave["waves"]) - t * float(wave["speed"]))


static func _draw_line(ci: CanvasItem, points: PackedVector2Array, s: Dictionary, heat: float) -> void:
	var ink := PadArt.NEON.lerp(PadArt.HOT, heat)
	var width := float(PadArt.STRINGS[s["string"]])
	var energy := maxf(maxf(float(s["shake"]), heat), float(s["glow"]))
	ci.draw_polyline(points, Color(ink, 0.15 + 0.4 * energy), width * 3.0 + 6.0, true)
	ci.draw_polyline(points, Color.WHITE.lerp(ink, 0.4), width, true)


static func _draw_stands(ci: CanvasItem, span: Vector2, y: float) -> void:
	for x in [span.x, span.y]:
		ci.draw_line(Vector2(x, y - 13), Vector2(x, y + 13), PadArt.IDLE.lightened(0.2), 4.0, true)


static func _draw_finger(ci: CanvasItem, tip: Vector2) -> void:
	ci.draw_circle(tip, 16.0, Color(PadArt.HOT, 0.25), true, -1.0, true)
	ci.draw_circle(tip, 7.0, PadArt.HOT, true, -1.0, true)


static func _draw_labels(ci: CanvasItem, rect: Rect2, s: Dictionary, right: float, heat: float) -> void:
	Glyph.text(ci, rect.position + Vector2(18, 32), String(s["name"]), 20, Color(Color.WHITE, 0.75))
	var note := String(s["note"])
	if note.is_empty():
		return
	var width := Glyph.TITLE.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	Glyph.title(ci, Vector2(right - width, rect.position.y + 34), note, 24, Color.WHITE.lerp(PadArt.HOT, heat))


static func _draw_meter(ci: CanvasItem, rect: Rect2, amount: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	ci.draw_rect(rect, Color(PadArt.IDLE, 0.35 * alpha), false, 2.0)
	var fill := rect.size.y * amount / Tuning.BEND_MAX
	ci.draw_rect(Rect2(rect.position.x, rect.end.y - fill, rect.size.x, fill), Color(PadArt.HOT, alpha))
	for mark: float in BEND_MARKS:
		_draw_mark(ci, rect, mark, amount >= mark - 0.05, alpha)


static func _draw_mark(ci: CanvasItem, rect: Rect2, mark: float, reached: bool, alpha: float) -> void:
	var y := rect.end.y - rect.size.y * mark / Tuning.BEND_MAX
	ci.draw_line(Vector2(rect.position.x - 6, y), Vector2(rect.end.x, y), Color(Color.WHITE, 0.5 * alpha), 2.0)
	var ink := Color(PadArt.HOT.lightened(0.4) if reached else Color.WHITE, alpha * (1.0 if reached else 0.55))
	Glyph.text(ci, Vector2(rect.position.x - 24, y + 6), String(BEND_MARKS[mark]), 14, ink)
