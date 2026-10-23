class_name TouchTests
extends TestSuite
## Сенсорное управление: какие действия ввода рождают касания и скольжения пальцев.

var pad: TouchPad
var sent: Array[String] = []


func before_each() -> void:
	if pad != null:
		pad.free()
	pad = TouchPad.new()
	pad.active = true
	sent.clear()
	pad.sink = func(action: String, pressed: bool) -> void: sent.append("%s %s" % [action, "↓" if pressed else "↑"])
	Game.state = "song"
	Game.menu_index = 0


func after_all() -> void:
	pad.free()
	Game.state = "menu"


func test_fret_is_held_while_touched() -> void:
	_touch(0, _center("fret_1"), true)
	_touch(0, _center("fret_1"), false)
	eq(sent, ["fret_1 ↓", "fret_1 ↑"], "лад держится, пока палец на нём")


func test_slide_to_next_fret_is_legato() -> void:
	_touch(0, _center("fret_1"), true)
	_drag(0, _center("fret_3"))
	eq(sent, ["fret_1 ↓", "fret_3 ↓", "fret_1 ↑"], "скольжение: сначала новый лад, потом старый — легато")


func test_two_fingers_on_one_fret() -> void:
	_touch(0, _center("fret_2"), true)
	_touch(1, _center("fret_2"), true)
	_touch(0, _center("fret_2"), false)
	eq(sent, ["fret_2 ↓"], "второй палец ещё держит лад")


func test_swipe_across_strings_strums() -> void:
	_touch(0, _center("strike_high"), true)
	_drag(0, _center("strike_mid"))
	_drag(0, _center("strike_low"))
	eq(sent, ["strike_high ↓", "strike_high ↑", "strike_mid ↓", "strike_mid ↑", "strike_low ↓", "strike_low ↑"],
		"провёл через струны — удар по каждой")


func test_gap_between_strings_is_dead_zone() -> void:
	var mid: Rect2 = TouchPad.button_at("song", _center("strike_mid"))["rect"]
	_touch(0, Vector2(mid.get_center().x, mid.position.y - 7), true)
	eq(sent, [], "в промежуток между струнами — не удар")
	check(mid.size.y >= 120.0 and mid.size.x >= 200.0, "кнопка струны крупная")


func test_strings_stack_like_the_highway() -> void:
	var high: Rect2 = TouchPad.button_at("song", _center("strike_high"))["rect"]
	var low: Rect2 = TouchPad.button_at("song", _center("strike_low"))["rect"]
	check(high.position.y < low.position.y, "верхняя струна сверху, как на дорожке")
	check(not high.intersects(Layout.HIGHWAY_TOUCH), "струны не залезают на дорожку")


func test_chord_with_two_hands() -> void:
	_touch(0, _center("fret_1"), true)
	_touch(1, _center("strike_low"), true)
	_drag(1, _center("strike_mid"))
	eq(sent, ["fret_1 ↓", "strike_low ↓", "strike_low ↑", "strike_mid ↓", "strike_mid ↑"], "лад держится, другой палец бьёт")


func test_menu_row_selects_then_starts() -> void:
	Game.state = "menu"
	var rows := TouchPad.menu_rows()
	var second: Rect2 = rows[1]["rect"]
	_touch(0, second.get_center(), true)
	eq(Game.menu_index, 1, "касание выбирает песню")
	_touch(0, second.get_center(), false)
	_touch(0, second.get_center(), true)
	eq(sent, ["start ↓", "start ↑"], "второе касание — играть")


func test_jam_buttons() -> void:
	Game.state = "jam"
	eq(TouchPad.button_at("jam", Vector2(395, 82)).get("action"), "record", "кнопка записи в джеме")
	eq(TouchPad.button_at("song", Vector2(395, 82)), {}, "в песне её нет")


func _center(action: String) -> Vector2:
	for button: Dictionary in TouchPad.buttons(Game.state):
		if button.get("action") == action:
			return (button["rect"] as Rect2).get_center()
	return Vector2(-100, -100)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	pad._unhandled_input(event)


func _drag(index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	pad._unhandled_input(event)
