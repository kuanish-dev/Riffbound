class_name Toast
extends Node2D

const SHOW_TIME := 3.0
const FADE_TIME := 0.5
const Y := 62.0

var _text := ""
var _age := SHOW_TIME


func show_text(text: String) -> void:
	_text = text
	_age = 0.0


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	if _age > SHOW_TIME:
		return
	var alpha := clampf((SHOW_TIME - _age) / FADE_TIME, 0.0, 1.0)
	var width := Glyph.width(_text, 17)
	draw_rect(Rect2(640 - width * 0.5 - 14, Y, width + 28, 30), Color(0.05, 0.04, 0.08, 0.85 * alpha))
	Glyph.text_center(self, 640, Y + 21, _text, 17, Color(1, 1, 1, alpha))
