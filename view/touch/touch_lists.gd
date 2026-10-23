class_name TouchLists
extends RefCounted


static func lists() -> Dictionary:
	return {
		"menu": {"field": "menu_index", "count": Songs.all().size(), "instant": true},
		"shop": {"field": "shop_index", "count": Shop.SKINS.size(), "instant": false},
	}


static func layout(state: String) -> Dictionary:
	return Layout.LISTS[state]["touch" if Game.touch else "keys"]


static func count(state: String) -> int:
	return int(lists()[state]["count"])


static func last_first_row(state: String) -> int:
	return maxi(0, count(state) - int(layout(state)["rows"]))


static func first_row(state: String) -> int:
	if Game.touch:
		return clampi(roundi(float(Game.scroll.get(state, 0.0))), 0, last_first_row(state))
	@warning_ignore("integer_division")
	var follow := _selected(state) - int(layout(state)["rows"]) / 3
	return clampi(follow, 0, last_first_row(state))


static func reveal(state: String) -> void:
	var rows := int(layout(state)["rows"])
	var selected := _selected(state)
	var first := clampi(roundi(float(Game.scroll.get(state, 0.0))), selected - rows + 1, selected)
	Game.scroll[state] = float(clampi(first, 0, last_first_row(state)))


static func scrolled(state: String, from: float, dy: float) -> float:
	var look := layout(state)
	return clampf(from - dy / (float(look["row_h"]) + float(look["gap"])), 0.0, float(last_first_row(state)))


static func rows(state: String) -> Array:
	var list: Dictionary = lists().get(state, {})
	var out: Array = []
	if list.is_empty():
		return out
	var first := first_row(state)
	for i in range(first, mini(int(list["count"]), first + int(layout(state)["rows"]))):
		out.append({"kind": "row", "index": i, "field": list["field"], "instant": list["instant"], "rect": _row_rect(state, i - first)})
	return out


static func _row_rect(state: String, visible_index: int) -> Rect2:
	var look := layout(state)
	var rect: Rect2 = look["rect"]
	var step := float(look["row_h"]) + float(look["gap"])
	var y := rect.position.y + float(look["top"]) + visible_index * step
	return Rect2(rect.position.x + 10, y, rect.size.x - 20, float(look["row_h"]))


static func _selected(state: String) -> int:
	return int(Game.get(lists()[state]["field"]))
