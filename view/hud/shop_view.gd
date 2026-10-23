class_name ShopView
extends HudLayer


static func status_of(skin: Dictionary) -> Array:
	if skin["id"] == Shop.equipped:
		return ["надета", Ink.GOLD]
	if Shop.owned.has(skin["id"]):
		return ["своя", Color.WHITE]
	return ["%d монет" % int(skin["price"]), Color.WHITE if Shop.coins >= int(skin["price"]) else Ink.RED]


func _draw() -> void:
	ListArt.top_panel(self)
	Glyph.neon_left(self, Vector2(20, 37), "МАГАЗИН", 24, Ink.GOLD)
	ListArt.coins(self, Vector2(820, 35))
	ListArt.list_frame(self, "shop", "ГИТАРЫ")
	for item: Dictionary in TouchLists.rows("shop"):
		_draw_skin_row(Shop.SKINS[int(item["index"])], item["rect"], int(item["index"]) == Game.shop_index)
	ListArt.scrollbar(self, "shop")
	_draw_preview(Shop.SKINS[Game.shop_index])


func _draw_skin_row(skin: Dictionary, row: Rect2, selected: bool) -> void:
	ListArt.row(self, row, selected)
	var tall := row.size.y > 40.0
	var swatch := Rect2(row.position + Vector2(8, row.size.y * 0.5 - (12 if tall else 8)), Vector2.ONE * (24 if tall else 16))
	draw_rect(swatch, skin["body"])
	draw_rect(swatch, skin.get("edge", skin["body"]), false, 2.0)
	var name_x := 44.0 if tall else 34.0
	Glyph.text(self, row.position + Vector2(name_x, row.size.y * 0.5 + (0 if tall else 7)), String(skin["name"]),
		23 if tall else 18, Color.WHITE)
	var tone := Vector2(name_x, row.size.y * 0.5 + 22) if tall else Vector2(190, 20)
	Glyph.text(self, row.position + tone, String(skin["tone"]["name"]), 15 if tall else 14, Ink.DIM)
	var status := status_of(skin)
	var size := 18 if tall else 15
	var x := row.size.x - 12 - Glyph.width(status[0], size)
	Glyph.text(self, row.position + Vector2(x, row.size.y * 0.5 + size * 0.36), status[0], size, status[1])


func _draw_preview(skin: Dictionary) -> void:
	var rect := Layout.SHOP_PREVIEW
	draw_rect(rect, Ink.PANEL)
	var span := GuitarArt.extent(String(skin["shape"]))
	var size := (rect.size.x - 40.0) / (span.y - span.x)
	GuitarArt.draw(self, skin, Vector2(rect.position.x + 20.0 - span.x * size, rect.get_center().y + 16.0), 0.0, size)
	Glyph.title(self, rect.position + Vector2(16, 30), String(skin["name"]), 22, Color.WHITE)
	var status := status_of(skin)
	Glyph.text(self, rect.position + Vector2(rect.size.x - 16 - Glyph.width(status[0], 17), 28), status[0], 17, status[1])
