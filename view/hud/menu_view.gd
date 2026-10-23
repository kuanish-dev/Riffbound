class_name MenuView
extends HudLayer

const PIP_DARK := Color(0.09, 0.08, 0.13)


func _draw() -> void:
	ListArt.top_panel(self)
	Glyph.neon_left(self, Vector2(20, 37), "RIFFBOUND", 26, Ink.GOLD)
	if not Game.touch:
		var level := Difficulty.current()
		Glyph.neon(self, Vector2(640, 27), "‹  %s  ›" % level["name"], 22, level["tint"])
	ListArt.coins(self, Vector2(1110, 35))
	ListArt.list_frame(self, "menu", "ВЫБЕРИ ПЕСНЮ")
	var songs := Songs.all()
	for item: Dictionary in TouchLists.rows("menu"):
		var song: Dictionary = songs[int(item["index"])]
		if item.has("level"):
			_draw_level(item["rect"], String(song["id"]), int(item["level"]))
		else:
			_draw_song(song, item["frame"], item["rect"], int(item["index"]) == Game.menu_index)
	ListArt.scrollbar(self, "menu")


func _draw_song(song: Dictionary, frame: Rect2, name_area: Rect2, selected: bool) -> void:
	ListArt.row(self, frame, selected)
	var big := frame.size.y / 30.0
	var size := int(clampf(19.0 * big * 0.55, 19.0, 34.0))
	var mine := String(song["id"]).begins_with("my_")
	Glyph.text(self, frame.position + Vector2(14 * big * 0.6, frame.size.y * 0.5 + size * 0.36), String(song["name"]), size,
		Ink.GOLD if mine else Color.WHITE)
	if selected or Game.touch:
		_draw_play_mark(Vector2(name_area.end.x - 24, frame.get_center().y), big, selected)


func _draw_level(rect: Rect2, song_id: String, level: int) -> void:
	var tint: Color = Difficulty.LEVELS[level]["tint"]
	var passed := Difficulty.passed(song_id, level)
	var chosen := Difficulty.index_for(song_id) == level
	draw_rect(rect, tint if passed else PIP_DARK)
	draw_rect(rect, Color.WHITE if chosen else Color(tint, 0.8), false, 3.0 if chosen else 1.5)
	var size := int(rect.size.y * 0.55)
	Glyph.title_center(self, rect.get_center().x, rect.get_center().y + size * 0.36, str(level + 1), size,
		Ink.PANEL if passed else tint)


func _draw_play_mark(center: Vector2, big: float, selected: bool) -> void:
	var k := clampf(big * 0.6, 1.0, 2.0)
	var triangle := PackedVector2Array([center + Vector2(-7, -9) * k, center + Vector2(9, 0) * k, center + Vector2(-7, 9) * k])
	draw_colored_polygon(triangle, Ink.GOLD if selected else Ink.DIM)
