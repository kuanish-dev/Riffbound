class_name MenuView
extends HudLayer

const STRIPE_W := 6.0
const LEVEL_AREA := Rect2(850, 62, 260, 180)
const LEVEL_MAX_SIZE := 64
const ARROW_SIZE := 96


func _draw() -> void:
	ListArt.top_panel(self)
	Glyph.neon_left(self, Vector2(20, 37), "RIFFBOUND", 26, Ink.GOLD)
	_draw_level()
	ListArt.coins(self, Vector2(1110, 35))
	ListArt.list_frame(self, "menu", "ВЫБЕРИ ПЕСНЮ")
	var songs := Songs.all()
	for item: Dictionary in TouchLists.rows("menu"):
		var index := int(item["index"])
		if item.get("play", false):
			_draw_play_button(item["rect"], index == Game.menu_index)
		else:
			_draw_song(songs[index], item["frame"], item["rect"], index == Game.menu_index)
	ListArt.scrollbar(self, "menu")


func _draw_level() -> void:
	var level := Difficulty.current()
	var tint: Color = level["tint"]
	draw_rect(LEVEL_AREA, Color(Ink.PANEL, 0.8))
	Glyph.text_center(self, LEVEL_AREA.get_center().x, LEVEL_AREA.position.y + 34, "сложность", 18, Ink.DIM)
	var name := String(level["name"])
	Glyph.neon(self, LEVEL_AREA.get_center() + Vector2(0, 12), name, _fitting_size(name), tint)
	if not Game.touch:
		for action: String in ["easier", "harder"]:
			var arrow := "‹" if action == "easier" else "›"
			Glyph.neon(self, TouchButtons.extra_rect("menu", action).get_center(), arrow, ARROW_SIZE, tint)


static func _fitting_size(text: String) -> int:
	var size := LEVEL_MAX_SIZE
	while size > 20 and Glyph.TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > LEVEL_AREA.size.x - 20:
		size -= 2
	return size


func _draw_song(song: Dictionary, frame: Rect2, name_area: Rect2, selected: bool) -> void:
	ListArt.row(self, frame, selected)
	var best := Difficulty.best_passed(String(song["id"]))
	var tint: Color = Color.WHITE if best < 0 else Difficulty.LEVELS[best]["tint"]
	var big := frame.size.y / 30.0
	var size := int(clampf(19.0 * big * 0.55, 19.0, 34.0))
	var baseline := frame.position.y + frame.size.y * 0.5 + size * 0.36
	Glyph.text(self, Vector2(frame.position.x + 14 * big * 0.6, baseline), String(song["name"]), size, tint)
	if best >= 0:
		draw_rect(Rect2(frame.position, Vector2(STRIPE_W, frame.size.y)), tint)
		Glyph.title_right(self, name_area.end.x - (20.0 if Game.touch else 70.0), baseline, _best_score(song, best), size, tint)
	if selected and not Game.touch:
		_draw_play_mark(Vector2(frame.end.x - 40, frame.get_center().y), 1.0, Ink.GOLD)


func _draw_play_button(rect: Rect2, selected: bool) -> void:
	PadArt.panel(self, rect, PadArt.GOLD if selected else PadArt.IDLE, 0.6 if selected else 0.0)
	_draw_play_mark(rect.get_center(), 2.0, Ink.GOLD if selected else Color.WHITE)


static func _best_score(song: Dictionary, level: int) -> String:
	return "%d" % int(Songs.best(Difficulty.record_key(String(song["id"]), level)).get("score", 0))


func _draw_play_mark(center: Vector2, k: float, ink: Color) -> void:
	var triangle := PackedVector2Array([center + Vector2(-7, -9) * k, center + Vector2(9, 0) * k, center + Vector2(-7, 9) * k])
	draw_colored_polygon(triangle, ink)
