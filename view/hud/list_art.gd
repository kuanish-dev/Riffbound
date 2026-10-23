class_name ListArt
extends RefCounted


static func top_panel(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, Layout.SCREEN.x, Layout.TOP_H), Ink.PANEL)


static func coins(ci: CanvasItem, pos: Vector2) -> void:
	ci.draw_circle(pos + Vector2(8, -7), 9, Ink.GOLD, true, -1.0, true)
	ci.draw_circle(pos + Vector2(8, -7), 6, Ink.GOLD.darkened(0.25), false, 1.5, true)
	Glyph.text(ci, pos + Vector2(24, 0), "%d" % Shop.coins, 21, Ink.GOLD)


static func stars(ci: CanvasItem, origin: Vector2, count: int, r := 7.0) -> void:
	for i in SongJudge.STARS.size():
		ci.draw_circle(origin + Vector2(i * (r * 2.6), 0), r, Ink.GOLD if i < count else Ink.STAR_OFF, true, -1.0, true)


static func row(ci: CanvasItem, rect: Rect2, selected: bool) -> void:
	ci.draw_rect(rect, Ink.ROW_SELECTED if selected else Ink.ROW)
	if selected:
		ci.draw_rect(rect, Ink.GOLD, false, 2.0)


static func list_frame(ci: CanvasItem, state: String, title: String) -> void:
	var look := TouchLists.layout(state)
	var rect: Rect2 = look["rect"]
	ci.draw_rect(rect, Ink.PANEL)
	if float(look["top"]) > 0.0:
		Glyph.text(ci, rect.position + Vector2(16, 24), title, 16, Ink.DIM)


static func scrollbar(ci: CanvasItem, state: String) -> void:
	var look := TouchLists.layout(state)
	var count := int(TouchLists.lists()[state]["count"])
	var rows := int(look["rows"])
	if not Game.touch or count <= rows:
		return
	var rect: Rect2 = look["rect"]
	var track := Rect2(rect.end.x - 6, rect.position.y + 4, 4, rect.size.y - 8)
	var thumb := track.size.y * rows / count
	var y := track.position.y + (track.size.y - thumb) * TouchLists.first_row(state) / maxf(1.0, count - rows)
	ci.draw_rect(track, Color(1, 1, 1, 0.08))
	ci.draw_rect(Rect2(track.position.x, y, track.size.x, thumb), Color(Ink.GOLD, 0.8))
