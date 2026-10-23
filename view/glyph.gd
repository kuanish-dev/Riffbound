class_name Glyph

const INK := Color(0.93, 0.92, 0.97)
const FILL := Color(0.16, 0.15, 0.22)
const TITLE := preload("res://assets/fonts/RussoOne-Regular.ttf")
const WEIGHT := 500
const NEON_LAYERS := [{"shift": Vector2(1.0, 0.9), "tint": Color(1.0, 0.16, 0.55)},
	{"shift": Vector2(-0.7, -0.5), "tint": Color(0.15, 0.95, 1.0)}]
const NEON_SHIFT := 0.07


static func note(ci: CanvasItem, pos: Vector2, id: String, r: float, ink := INK, fill := FILL) -> void:
	ci.draw_circle(pos, r, fill, true, -1.0, true)
	ci.draw_arc(pos, r, 0.0, TAU, 28, ink, 2.0, true)
	var label := "x" if id == Notes.MUTE else id
	text_center(ci, pos.x, pos.y + r * 0.45, label, int(r * 1.25), ink)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, tint: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, tint)


static func text_center(ci: CanvasItem, center_x: float, y: float, s: String, size: int, tint: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, Vector2(center_x - 600.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, 1200.0, size, tint)


static func title(ci: CanvasItem, pos: Vector2, s: String, size: int, tint: Color) -> void:
	ci.draw_string(TITLE, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, tint)


static func title_center(ci: CanvasItem, center_x: float, y: float, s: String, size: int, tint: Color) -> void:
	ci.draw_string(TITLE, Vector2(center_x - 600.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, 1200.0, size, tint)


static func neon(ci: CanvasItem, center: Vector2, s: String, size: int, tint: Color, angle := 0.0, scale := 1.0) -> void:
	ci.draw_set_transform(center, angle, Vector2(scale, scale))
	var base := size * 0.36
	var shift := maxf(1.5, size * NEON_SHIFT)
	for layer: Dictionary in NEON_LAYERS:
		var offset: Vector2 = (layer["shift"] as Vector2) * shift
		title_center(ci, offset.x, base + offset.y, s, size, Color(layer["tint"] as Color, tint.a * 0.9))
	title_center(ci, 0.0, base, s, size, tint)
	ci.draw_set_transform(Vector2.ZERO)


static func neon_left(ci: CanvasItem, pos: Vector2, s: String, size: int, tint: Color) -> void:
	var w := TITLE.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	neon(ci, Vector2(pos.x + w * 0.5, pos.y - size * 0.36), s, size, tint)


static func width(s: String, size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_font() -> Font:
	var variation := FontVariation.new()
	variation.base_font = load("res://assets/fonts/Rubik.ttf")
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): WEIGHT}
	return variation
