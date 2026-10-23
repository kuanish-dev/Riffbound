class_name MenuView
extends HudLayer

const STRIPE_W := 6.0
const SCORE_RIGHT := 110.0


func _draw() -> void:
	ListArt.top_panel(self)
	Glyph.neon_left(self, Vector2(20, 37), "RIFFBOUND", 26, Ink.GOLD)
	_draw_level()
	ListArt.coins(self, Vector2(1110, 35))
	ListArt.list_frame(self, "menu", "ВЫБЕРИ ПЕСНЮ")
	var songs := Songs.all()
	for item: Dictionary in TouchLists.rows("menu"):
		var index := int(item["index"])
		_draw_song(songs[index], item["rect"], index == Game.menu_index)
	ListArt.scrollbar(self, "menu")


func _draw_level() -> void:
	var level := Difficulty.current()
	var text := String(level["name"]) if Game.touch else "‹  %s  ›" % level["name"]
	Glyph.neon(self, Vector2(640, 27), text, 22, level["tint"])


func _draw_song(song: Dictionary, frame: Rect2, selected: bool) -> void:
	ListArt.row(self, frame, selected)
	var best := Difficulty.best_passed(String(song["id"]))
	var tint: Color = Color.WHITE if best < 0 else Difficulty.LEVELS[best]["tint"]
	var big := frame.size.y / 30.0
	var size := int(clampf(19.0 * big * 0.55, 19.0, 34.0))
	var baseline := frame.position.y + frame.size.y * 0.5 + size * 0.36
	Glyph.text(self, Vector2(frame.position.x + 14 * big * 0.6, baseline), String(song["name"]), size, tint)
	if best >= 0:
		draw_rect(Rect2(frame.position, Vector2(STRIPE_W, frame.size.y)), tint)
		Glyph.title_right(self, frame.end.x - SCORE_RIGHT * big * 0.6, baseline, _best_score(song, best), size, tint)
	if selected or Game.touch:
		_draw_play_mark(Vector2(frame.end.x - 40, frame.get_center().y), big, selected)


static func _best_score(song: Dictionary, level: int) -> String:
	return "%d" % int(Songs.best(Difficulty.record_key(String(song["id"]), level)).get("score", 0))


func _draw_play_mark(center: Vector2, big: float, selected: bool) -> void:
	var k := clampf(big * 0.6, 1.0, 2.0)
	var triangle := PackedVector2Array([center + Vector2(-7, -9) * k, center + Vector2(9, 0) * k, center + Vector2(-7, 9) * k])
	draw_colored_polygon(triangle, Ink.GOLD if selected else Ink.DIM)
