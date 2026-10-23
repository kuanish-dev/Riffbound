class_name CrtOverlay
extends Node2D
## Плёнка поверх всего, как в Hotline Miami: сканлайны (тёмная строка каждые period пикселей) и затемнённые
## края. Рисуется один раз; с запасом MARGIN за краем — на тряску и качание камеры.

const SCANLINES := {"period": 3, "alpha": 0.14}
const VIGNETTE := {"width": 150.0, "alpha": 0.42}
const MARGIN := 40.0

var _lines: ImageTexture


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var period := int(SCANLINES["period"])
	var image := Image.create(1, period, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.set_pixel(0, period - 1, Color(0, 0, 0, 1))
	_lines = ImageTexture.create_from_image(image)


func _draw() -> void:
	var w := Layout.SCREEN.x
	var h := Layout.SCREEN.y
	var m := MARGIN
	draw_texture_rect(_lines, Rect2(-m, -m, w + 2 * m, h + 2 * m), true, Color(1, 1, 1, float(SCANLINES["alpha"])))
	var dark := Color(0, 0, 0, float(VIGNETTE["alpha"]))
	var clear := Color(0, 0, 0, 0)
	var e := float(VIGNETTE["width"])
	var edges := [
		[Vector2(-m, -m), Vector2(e, -m), Vector2(e, h + m), Vector2(-m, h + m), [dark, clear, clear, dark]],
		[Vector2(w - e, -m), Vector2(w + m, -m), Vector2(w + m, h + m), Vector2(w - e, h + m), [clear, dark, dark, clear]],
		[Vector2(-m, -m), Vector2(w + m, -m), Vector2(w + m, e * 0.6), Vector2(-m, e * 0.6), [dark, dark, clear, clear]],
		[Vector2(-m, h - e * 0.6), Vector2(w + m, h - e * 0.6), Vector2(w + m, h + m), Vector2(-m, h + m), [clear, clear, dark, dark]],
	]
	for edge: Array in edges:
		draw_polygon(PackedVector2Array(edge.slice(0, 4)), PackedColorArray(edge[4]))
