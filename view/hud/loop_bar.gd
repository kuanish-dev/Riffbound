class_name LoopBar
extends RefCounted

const TRACK := Color(0.18, 0.16, 0.24)
const RECORDING := Color(1, 0.3, 0.3, 0.7)


static func draw(ci: CanvasItem) -> void:
	var looper := Game.looper
	var now := Game.conductor.now()
	var rect := Layout.LOOP_BAR
	ci.draw_rect(rect, Ink.PANEL)
	var bar := Rect2(rect.position + Vector2(110, 12), Vector2(rect.size.x - 124, 16))
	ci.draw_rect(bar, TRACK)
	for i in range(1, Looper.BARS):
		var x := bar.position.x + bar.size.x * i / Looper.BARS
		ci.draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color(1, 1, 1, 0.25), 1.0)
	if looper.recording:
		ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * looper.progress(now), bar.size.y)), RECORDING)
	if looper.length > 0.0:
		var head := bar.position.x + bar.size.x * fposmod(now, looper.length) / looper.length
		ci.draw_line(Vector2(head, bar.position.y - 4), Vector2(head, bar.end.y + 4), Color.WHITE, 2.0)
	var label := "● ЗАПИСЬ" if looper.recording else "ЛУП %d/%d" % [looper.layers.size(), Looper.MAX_LAYERS]
	Glyph.text(ci, rect.position + Vector2(10, 26), label, 16, Ink.RED if looper.recording else Ink.DIM)
