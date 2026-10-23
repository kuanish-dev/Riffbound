class_name TouchTests
extends TestSuite

const MIN_BUTTON := Vector2(100, 60)

var pad: TouchPad
var sent: Array[String] = []


func before_each() -> void:
	if pad != null:
		pad.free()
	pad = TouchPad.new()
	pad.active = true
	sent.clear()
	pad.sink = func(action: String, pressed: bool, strength: float) -> void:
		if action == "bend_pull":
			sent.append("bend %.1f" % (strength * Tuning.BEND_MAX))
		else:
			sent.append("%s %s" % [action, "↓" if pressed else "↑"])
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
	eq(sent, ["fret_1 ↓", "slide ↓", "fret_3 ↓", "fret_1 ↑", "slide ↑"], "палец поехал по ладам — слайд: новый лад, потом старый")


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
	var mid: Rect2 = TouchButtons.at("song", _center("strike_mid"))["rect"]
	_touch(0, Vector2(mid.get_center().x, mid.position.y - 7), true)
	eq(sent, [], "в промежуток между струнами — не удар")
	check(mid.size.y >= 120.0 and mid.size.x >= 200.0, "кнопка струны крупная")


func test_strings_stack_like_the_highway() -> void:
	var high: Rect2 = TouchButtons.at("song", _center("strike_high"))["rect"]
	var low: Rect2 = TouchButtons.at("song", _center("strike_low"))["rect"]
	check(high.position.y < low.position.y, "верхняя струна сверху, как на дорожке")
	check(not high.intersects(Layout.HIGHWAY_TOUCH), "струны не залезают на дорожку")


func test_chord_with_two_hands() -> void:
	_touch(0, _center("fret_1"), true)
	_touch(1, _center("strike_low"), true)
	_drag(1, _center("strike_mid"))
	eq(sent, ["fret_1 ↓", "strike_low ↓", "strike_low ↑", "strike_mid ↓", "strike_mid ↑"], "лад держится, другой палец бьёт")


func test_menu_row_starts_at_once() -> void:
	Game.state = "menu"
	var second: Rect2 = TouchLists.rows("menu")[1]["rect"]
	_touch(0, second.get_center(), true)
	eq(sent, [], "пока палец на строке — ничего: вдруг это прокрутка")
	_touch(0, second.get_center(), false)
	eq(Game.menu_index, 1, "касание выбирает песню")
	eq(sent, ["start ↓", "start ↑"], "и сразу её играет — одно касание")


func test_shop_row_selects_then_takes() -> void:
	Game.state = "shop"
	Game.shop_index = 0
	var second: Rect2 = TouchLists.rows("shop")[1]["rect"]
	_touch(0, second.get_center(), true)
	_touch(0, second.get_center(), false)
	eq(Game.shop_index, 1, "в магазине касание выбирает гитару")
	eq(sent, [], "но не покупает")
	_touch(0, second.get_center(), true)
	_touch(0, second.get_center(), false)
	eq(sent, ["start ↓", "start ↑"], "второе касание — взять")
	Game.shop_index = 0


func test_buttons_only_when_needed() -> void:
	Game.needs = {"bend": false, "positions": false}
	var actions := TouchButtons.buttons("song").map(func(b: Dictionary) -> String: return b.get("action", ""))
	check(not actions.has("position_up"), "песне без сдвига руки — нет кнопок позиции")
	Game.needs = {"bend": true, "positions": true}
	actions = TouchButtons.buttons("song").map(func(b: Dictionary) -> String: return b.get("action", ""))
	check(actions.has("position_up"), "нужен сдвиг — кнопки есть")
	check(not actions.has("bend"), "кнопки бенда нет вовсе — бенд жестом по струне")


func test_jam_more_panel() -> void:
	Game.more = false
	var actions := TouchButtons.buttons("jam").map(func(b: Dictionary) -> String: return b.get("action", ""))
	check(actions.has("record") and actions.has("backing") and not actions.has("scale"), "сначала — только запись и музыка")
	Game.more = true
	actions = TouchButtons.buttons("jam").map(func(b: Dictionary) -> String: return b.get("action", ""))
	check(actions.has("scale") and actions.has("metronome") and actions.has("tap_tempo"), "«Ещё» открывает остальное")
	Game.more = false


func test_jam_buttons() -> void:
	Game.state = "jam"
	eq(TouchButtons.at("jam", Vector2(395, 82)).get("action"), "record", "кнопка записи в джеме")
	eq(TouchButtons.at("song", Vector2(395, 82)), {}, "в песне её нет")


func test_metronome_toggle_buttons() -> void:
	Game.state = "jam"
	Game.more = true
	eq(TouchButtons.at("jam", _center("metronome")).get("lit"), "metronome", "кнопка метронома подсвечивается по Game.metronome")
	Game.more = false


func test_buttons_fit_a_finger() -> void:
	var was_touch := Game.touch
	Game.touch = true
	for more: bool in [false, true]:
		Game.more = more
		for state: String in ["menu", "jam", "song", "shop", "results"]:
			var buttons := TouchButtons.buttons(state)
			for i in buttons.size():
				var a: Rect2 = buttons[i]["rect"]
				var name := String(buttons[i].get("action", "row"))
				check(a.size.x >= MIN_BUTTON.x and a.size.y >= MIN_BUTTON.y, "%s: «%s» не мельче пальца (%s)" % [state, name, a.size])
				for j in range(i + 1, buttons.size()):
					check(not a.intersects(buttons[j]["rect"]), "%s: кнопки «%s» и «%s» не налезают" % [state, name,
						buttons[j].get("action", "row")])
	Game.more = false
	Game.touch = was_touch


func test_finger_scroll_reaches_every_song() -> void:
	var was_touch := Game.touch
	Game.touch = true
	Game.state = "menu"
	Game.scroll["menu"] = 0.0
	var rows: Array = TouchLists.rows("menu")
	var top: Rect2 = rows[0]["rect"]
	_touch(0, top.get_center(), true)
	_drag(0, top.get_center() + Vector2(4, -2000))
	_touch(0, top.get_center() + Vector2(4, -2000), false)
	eq(sent, [], "листал — песню не запустил")
	var last: Dictionary = TouchLists.rows("menu").back()
	eq(int(last["index"]), Songs.all().size() - 1, "пролистал до последней песни")
	_touch(0, (last["rect"] as Rect2).get_center(), true)
	_touch(0, (last["rect"] as Rect2).get_center(), false)
	eq(Game.menu_index, Songs.all().size() - 1, "коснулся последней — она выбрана")
	eq(sent, ["start ↓", "start ↑"], "и играет")
	Game.scroll["menu"] = 0.0
	Game.touch = was_touch


func test_bend_by_pulling_string() -> void:
	var at := _center("strike_mid")
	var tone := BendGesture.DEAD + BendGesture.RANGE
	_touch(0, at, true)
	_drag(0, at + Vector2(-3, 1))
	_drag(0, at + Vector2(-(BendGesture.DEAD + BendGesture.RANGE * 0.5), 5))
	_drag(0, at + Vector2(-tone, 6))
	_drag(0, at + Vector2(-tone * 3.0, 8))
	_drag(0, at + Vector2(-5, 4))
	_drag(0, at + Vector2(-tone, 0))
	_touch(0, at + Vector2(-tone, 0), false)
	eq(sent, ["strike_mid ↓", "strike_mid ↑", "bend 0.5", "bend 1.0", "bend %.1f" % Tuning.BEND_MAX, "bend 0.0",
		"bend 1.0", "bend 0.0"],
		"тянешь — полтона, тон, до упора; вернул — отпустил; снова потянул и поднял палец — отпустил")


func test_wiggle_on_string_is_vibrato() -> void:
	var at := _center("strike_high")
	_touch(0, at, true)
	for x: float in [4.0, 10.0, 16.0, 10.0, 4.0, -4.0, -10.0, -16.0, -10.0, -4.0, 4.0, 10.0, 16.0]:
		_drag(0, at + Vector2(x, 1))
	_touch(0, at + Vector2(16, 1), false)
	var bends := sent.filter(func(s: String) -> bool: return s.begins_with("bend"))
	check(bends.size() >= 4, "покачивание на струне — нота дрожит (%s)" % str(bends))
	check(bends.all(func(s: String) -> bool: return float(s.split(" ")[1]) <= 0.1), "вибрато мелкое, не бенд на тон")
	eq(sent.back(), "bend 0.0", "отпустил — струна отпущена")
	eq(sent.count("strike_high ↓"), 1, "покачивание не бьёт по струне заново")


func test_strum_is_not_bend() -> void:
	var high := _center("strike_high")
	_touch(0, high, true)
	_drag(0, _center("strike_mid") + Vector2(-50, 0))
	_drag(0, _center("strike_low") + Vector2(-60, 0))
	_touch(0, _center("strike_low") + Vector2(-60, 0), false)
	check(not sent.any(func(s: String) -> bool: return s.begins_with("bend")), "бой наискосок через струны — не бенд: %s" % str(sent))
	eq(sent.count("strike_low ↓"), 1, "но удары по всем струнам есть")


func test_pad_shows_fingers_pull_and_slide() -> void:
	var slides: Array = []
	pad.slid.connect(func(from: String, to: String) -> void: slides.append([from, to]))
	_touch(0, _center("fret_1"), true)
	_drag(0, _center("fret_3"))
	eq(slides, [["1", "3"]], "слайд с лада на лад")
	var from := _center("strike_mid")
	_touch(1, from, true)
	_drag(1, from + Vector2(40, 0))
	var pull := pad.pull_of("mid")
	eq([pull.from, pull.pos, pull.on], [from, from + Vector2(40, 0), true], "тянет среднюю от точки удара")
	check(pad.pull_of("high") == null, "верхнюю никто не тянет")
	eq(pad.points.size(), 2, "два пальца на экране")
	_touch(1, from + Vector2(40, 0), false)
	check(pad.pull_of("mid") == null and pad.points.size() == 1, "палец поднят — не тянет и не виден")


func _center(action: String) -> Vector2:
	for button: Dictionary in TouchButtons.buttons(Game.state):
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
