class_name MenuView
extends HudLayer


func _draw() -> void:
	ListArt.top_panel(self)
	Glyph.neon_left(self, Vector2(20, 37), "RIFFBOUND", 26, Ink.GOLD)
	ListArt.coins(self, Vector2(1110, 35))
	ListArt.list_frame(self, "menu", "ВЫБЕРИ ПЕСНЮ")
	var songs := Songs.all()
	for item: Dictionary in TouchLists.rows("menu"):
		_draw_song(songs[int(item["index"])], item["rect"], int(item["index"]) == Game.menu_index)
	ListArt.scrollbar(self, "menu")


func _draw_song(song: Dictionary, row: Rect2, selected: bool) -> void:
	ListArt.row(self, row, selected)
	var big := row.size.y / 30.0
	var size := int(clampf(19.0 * big * 0.55, 19.0, 34.0))
	var mine := String(song["id"]).begins_with("my_")
	Glyph.text(self, row.position + Vector2(14 * big * 0.6, row.size.y * 0.5 + size * 0.36), String(song["name"]), size,
		Ink.GOLD if mine else Color.WHITE)
	var r := clampf(7.0 * big * 0.5, 7.0, 12.0)
	var best := int(Songs.best(String(song["id"])).get("stars", 0))
	ListArt.stars(self, row.position + Vector2(row.size.x - 70 - r * 13.0, row.size.y * 0.5), best, r)
	if selected or Game.touch:
		_draw_play_mark(row, big, selected)


func _draw_play_mark(row: Rect2, big: float, selected: bool) -> void:
	var c := row.position + Vector2(row.size.x - 40, row.size.y * 0.5)
	var k := clampf(big * 0.6, 1.0, 2.0)
	var triangle := PackedVector2Array([c + Vector2(-7, -9) * k, c + Vector2(9, 0) * k, c + Vector2(-7, 9) * k])
	draw_colored_polygon(triangle, Ink.GOLD if selected else Ink.DIM)
