class_name TouchPad
extends Node

signal row_selected
signal slid(from_fret: String, to_fret: String)

const SCROLL_SLOP := 14.0

var active := false
var sink: Callable = _to_input
var points := {}
var _touches := {}
var _holds := {}
var _rows := {}
var _bends := {}


func holding(action: String) -> bool:
	return int(_holds.get(action, 0)) > 0


func pull_of(string: String) -> BendGesture:
	for bend: BendGesture in _bends.values():
		if bend.string == string:
			return bend
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_drag_to((event as InputEventScreenDrag).index, (event as InputEventScreenDrag).position)
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_press_at(touch.index, touch.position)
	else:
		_lift(touch.index)


func _press_at(index: int, pos: Vector2) -> void:
	points[index] = pos
	var button := TouchButtons.at(Game.state, pos)
	if button.get("kind") == "row":
		_rows[index] = {"row": button, "from": pos, "scroll": float(Game.scroll.get(Game.state, 0.0)), "moved": false}
		return
	_move(index, button)
	_aim_bend(index, button, pos)


func _drag_to(index: int, pos: Vector2) -> void:
	points[index] = pos
	if _rows.has(index):
		_scroll(index, pos)
		return
	var button := TouchButtons.at(Game.state, pos)
	if _can_move(index, button):
		_move_sliding(index, button)
		if button.has("string"):
			_aim_bend(index, button, pos)
	_track_bend(index, pos)


func _lift(index: int) -> void:
	points.erase(index)
	if _rows.has(index):
		if not _rows[index]["moved"]:
			_begin_row(_rows[index]["row"])
		_rows.erase(index)
		return
	_move(index, {})
	_touches.erase(index)
	_release_bend(index)


func _can_move(index: int, button: Dictionary) -> bool:
	var bending: bool = _bends.has(index) and (_bends[index] as BendGesture).on
	return button != _touches.get(index, {}) and (not bending or button.has("string"))


func _move_sliding(index: int, button: Dictionary) -> void:
	var old: Dictionary = _touches.get(index, {})
	var slide := button.has("fret") and old.has("fret")
	if slide:
		sink.call("slide", true, 1.0)
	_move(index, button)
	if slide:
		sink.call("slide", false, 0.0)
		slid.emit(String(old["fret"]), String(button["fret"]))


func _scroll(index: int, pos: Vector2) -> void:
	var press: Dictionary = _rows[index]
	var dy := pos.y - (press["from"] as Vector2).y
	if not press["moved"] and absf(dy) < SCROLL_SLOP:
		return
	press["moved"] = true
	Game.scroll[Game.state] = TouchLists.scrolled(Game.state, float(press["scroll"]), dy)


func _aim_bend(index: int, button: Dictionary, pos: Vector2) -> void:
	_release_bend(index)
	if button.has("string"):
		_bends[index] = BendGesture.new(String(button["string"]), pos)


func _track_bend(index: int, pos: Vector2) -> void:
	var bend: BendGesture = _bends.get(index)
	if bend != null and bend.follow(pos):
		sink.call("bend_pull", bend.amount > 0.0, bend.amount / Tuning.BEND_MAX)


func _release_bend(index: int) -> void:
	var bend: BendGesture = _bends.get(index)
	if bend != null and bend.amount > 0.0:
		sink.call("bend_pull", false, 0.0)
	_bends.erase(index)


func _move(index: int, button: Dictionary) -> void:
	var old: Dictionary = _touches.get(index, {})
	_touches[index] = button
	if not button.is_empty():
		call("_begin_" + String(button["kind"]), button)
	if not old.is_empty() and old["kind"] == "hold":
		_hold(String(old["action"]), -1)


func _begin_hold(button: Dictionary) -> void:
	_hold(String(button["action"]), 1)


func _begin_tap(button: Dictionary) -> void:
	sink.call(String(button["action"]), true, 1.0)
	sink.call(String(button["action"]), false, 0.0)


func _begin_row(row: Dictionary) -> void:
	var index := int(row["index"])
	if row.has("level"):
		Game.set(row["field"], index)
		Difficulty.choose(String(Songs.all()[index]["id"]), int(row["level"]))
		row_selected.emit()
		return
	var again := int(Game.get(row["field"])) == index
	Game.set(row["field"], index)
	if again or row["instant"]:
		_begin_tap({"action": "start"})
	else:
		row_selected.emit()


func _hold(action: String, delta: int) -> void:
	var before := int(_holds.get(action, 0))
	var after := maxi(0, before + delta)
	_holds[action] = after
	if before == 0 and after > 0:
		sink.call(action, true, 1.0)
	elif before > 0 and after == 0:
		sink.call(action, false, 0.0)


func _to_input(action: String, pressed: bool, strength: float) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength
	Input.parse_input_event(event)
