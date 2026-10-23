class_name PadArt
extends RefCounted

const CUT := 16.0
const GLASS := [Color(0.13, 0.11, 0.22), Color(0.045, 0.04, 0.08)]
const NEON := Color(0.3, 0.92, 1.0)
const HOT := Color(1.0, 0.27, 0.66)
const GOLD := Color(1.0, 0.82, 0.3)
const IDLE := Color(0.46, 0.43, 0.62)
const STRINGS := {"high": 2.0, "mid": 3.0, "low": 4.2}


static func panel(ci: CanvasItem, rect: Rect2, edge: Color, glow := 0.0) -> void:
	var shape := _outline(rect)
	ci.draw_polygon(shape, _glass_colors(shape, rect, edge, glow))
	var loop := shape.duplicate()
	loop.append(shape[0])
	ci.draw_polyline(loop, Color(edge, 0.16 + 0.3 * glow), 7.0, true)
	ci.draw_polyline(loop, edge, 2.0, true)
	_draw_corner_brackets(ci, rect, edge.lightened(0.35))


static func button(ci: CanvasItem, rect: Rect2, label: String, edge: Color, glow := 0.0) -> void:
	panel(ci, rect, edge, glow)
	var size := clampi(int(minf(rect.size.y * 0.32, rect.size.x / maxf(1.0, label.length()) * 1.3)), 14, 48)
	Glyph.text_center(ci, rect.get_center().x, rect.get_center().y + size * 0.35, label, size, Color.WHITE)


static func shift(ci: CanvasItem, rect: Rect2, label: String, dir: float, edge: Color, glow := 0.0) -> void:
	panel(ci, rect, edge, glow)
	var center := rect.get_center() - Vector2(0, rect.size.y * 0.08)
	for i in 2:
		var tip := center + Vector2(dir * (8.0 + i * 26.0), 0)
		var chevron := PackedVector2Array([tip + Vector2(-dir * 20, -26), tip, tip + Vector2(-dir * 20, 26)])
		ci.draw_polyline(chevron, Color(NEON, 0.55 + 0.45 * i), 6.0, true)
	Glyph.text_center(ci, rect.get_center().x, rect.end.y - 26, label, 22, Color(Color.WHITE, 0.8))


static func _glass_colors(shape: PackedVector2Array, rect: Rect2, edge: Color, glow: float) -> PackedColorArray:
	var top: Color = (GLASS[0] as Color).lerp(edge.darkened(0.35), glow)
	var bottom: Color = (GLASS[1] as Color).lerp(edge.darkened(0.6), glow)
	var colors := PackedColorArray()
	for v in shape:
		colors.append(top.lerp(bottom, (v.y - rect.position.y) / rect.size.y))
	return colors


static func _draw_corner_brackets(ci: CanvasItem, rect: Rect2, ink: Color) -> void:
	var arm := minf(18.0, rect.size.y * 0.2)
	for corner: Array in [[Vector2(rect.end.x, rect.position.y), Vector2(-1, 1)], [Vector2(rect.position.x, rect.end.y), Vector2(1, -1)]]:
		var at: Vector2 = corner[0]
		var dir: Vector2 = corner[1]
		ci.draw_polyline(PackedVector2Array([at + Vector2(dir.x * arm, 0), at, at + Vector2(0, dir.y * arm)]), ink, 3.0, true)


static func _outline(rect: Rect2) -> PackedVector2Array:
	var cut := minf(CUT, minf(rect.size.x, rect.size.y) * 0.25)
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([Vector2(p.x + cut, p.y), Vector2(e.x, p.y), Vector2(e.x, e.y - cut), Vector2(e.x - cut, e.y),
		Vector2(p.x, e.y), Vector2(p.x, p.y + cut)])
