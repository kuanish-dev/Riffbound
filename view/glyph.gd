class_name Glyph
## Общие рисовалки. Нота таба — кружок с номером лада (глушняк — «x»); тон задаёт вызывающий:
## ink — цвет обводки и цифры, fill — заливка.

const INK := Color(0.93, 0.92, 0.97)
const FILL := Color(0.16, 0.15, 0.22)


static func note(ci: CanvasItem, pos: Vector2, id: String, r: float, ink := INK, fill := FILL) -> void:
	ci.draw_circle(pos, r, fill, true, -1.0, true)
	ci.draw_arc(pos, r, 0.0, TAU, 28, ink, 2.0, true)
	var label := "x" if id == Notes.MUTE else id
	text_center(ci, pos.x, pos.y + r * 0.45, label, int(r * 1.25), ink)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, tint: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, tint)


## Строка по центру относительно center_x; y — базовая линия.
static func text_center(ci: CanvasItem, center_x: float, y: float, s: String, size: int, tint: Color) -> void:
	ci.draw_string(ThemeDB.fallback_font, Vector2(center_x - 600.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, 1200.0, size, tint)
