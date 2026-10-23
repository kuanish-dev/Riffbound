class_name ResultsView
extends HudLayer


func _draw() -> void:
	SongView.draw_top(self)
	var rect := Layout.HIGHWAY
	var result := Game.last_result
	var top := rect.position.y
	draw_rect(rect, Ink.PANEL)
	Glyph.neon(self, Vector2(640, top + 40), String(Game.performance.song.get("name", "")), 28, Color.WHITE)
	if result.get("failed", false):
		_draw_failed(top, result)
	else:
		_draw_passed(top, result)
	var style := String(result.get("style", ""))
	if not style.is_empty():
		Glyph.neon(self, Vector2(1050, top + 118), style, 84, StyleMeter.rank_of(style)["tint"], -0.08)


func _draw_passed(top: float, result: Dictionary) -> void:
	ListArt.stars(self, Vector2(640 - 78, top + 92), int(result.get("stars", 0)), 15.0)
	Glyph.title_center(self, 640, top + 160, "%d" % int(result.get("score", 0)), 40, Ink.GOLD)
	Glyph.text_center(self, 640, top + 200, _rewards(result), 20, Color.WHITE)


func _draw_failed(top: float, result: Dictionary) -> void:
	Glyph.neon(self, Vector2(640, top + 100), "ПРОВАЛ", 48, Ink.RED, -0.04)
	Glyph.title_center(self, 640, top + 168, "%d" % int(result.get("score", 0)), 30, Ink.DIM)
	Glyph.text_center(self, 640, top + 204, "%d ошибки подряд — уровень не пройден" % SongJudge.MISTAKES_TO_FAIL, 20, Color.WHITE)


static func _rewards(result: Dictionary) -> String:
	var coins := "+%d монет" % int(result.get("coins", 0))
	return "новый рекорд!   " + coins if result.get("record", false) else coins
