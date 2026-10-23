class_name TouchLists
extends RefCounted


static func lists() -> Dictionary:
	return {
		"menu": {"field": "menu_index", "count": Songs.all().size(), "instant": true, "levels": true},
		"shop": {"field": "shop_index", "count": Shop.SKINS.size(), "instant": false, "levels": false},
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
		var frame := _row_rect(state, i - first)
		var row := {"kind": "row", "index": i, "field": list["field"], "instant": list["instant"], "rect": frame, "frame": frame}
		if list["levels"]:
			row["rect"] = Rect2(frame.position, Vector2(level_rect(frame, 0).position.x - 10 - frame.position.x, frame.size.y))
		out.append(row)
		if list["levels"]:
			out.append_array(_level_rows(row, frame))
	return out


static func level_rect(frame: Rect2, level: int) -> Rect2:
	var size := Vector2(100, frame.size.y - 20) if Game.touch else Vector2(28, frame.size.y - 8)
	var gap := 8.0 if Game.touch else 4.0
	var after := Difficulty.LEVELS.size() - level
	var right := frame.end.x - (10.0 if Game.touch else 60.0)
	return Rect2(right - after * size.x - (after - 1) * gap, frame.get_center().y - size.y * 0.5, size.x, size.y)


static func _level_rows(row: Dictionary, frame: Rect2) -> Array:
	var out: Array = []
	for level in Difficulty.LEVELS.size():
		var pip := row.duplicate()
		pip["level"] = level
		pip["instant"] = false
		pip["rect"] = level_rect(frame, level)
		out.append(pip)
	return out


static func _row_rect(state: String, visible_index: int) -> Rect2:
	var look := layout(state)
	var rect: Rect2 = look["rect"]
	var step := float(look["row_h"]) + float(look["gap"])
	var y := rect.position.y + float(look["top"]) + visible_index * step
	return Rect2(rect.position.x + 10, y, rect.size.x - 20, float(look["row_h"]))


static func _selected(state: String) -> int:
	return int(Game.get(lists()[state]["field"]))
