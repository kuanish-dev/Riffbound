class_name Gestures
extends RefCounted

const SCRIPTS := {
	"bend": [[1.0, 0, "press", "fret_2", Vector2.ZERO], [1.2, 1, "press", "strike_mid", Vector2(-80, 0)],
		[1.3, 1, "drag", "strike_mid", Vector2(-40, 0)], [1.4, 1, "drag", "strike_mid", Vector2(10, 0)],
		[1.5, 1, "drag", "strike_mid", Vector2(60, 0)], [1.6, 1, "drag", "strike_mid", Vector2(80, 0)]],
	"vibrato": [[1.0, 0, "press", "fret_3", Vector2.ZERO], [1.2, 1, "press", "strike_high", Vector2(-80, 0)],
		[1.3, 1, "drag", "strike_high", Vector2(-20, 0)], [1.4, 1, "wiggle", "strike_high", Vector2(0, 0)]],
	"slide": [[1.0, 0, "press", "fret_1", Vector2.ZERO], [1.2, 1, "press", "strike_low", Vector2.ZERO],
		[1.3, 1, "lift", "strike_low", Vector2.ZERO], [1.5, 0, "drag", "fret_2", Vector2(-40, 0)],
		[1.55, 0, "drag", "fret_3", Vector2(-40, 0)]],
	"demo": [[0.8, 0, "press", "fret_1", Vector2.ZERO], [1.0, 1, "press", "strike_low", Vector2.ZERO],
		[1.15, 1, "lift", "strike_low", Vector2.ZERO], [1.5, 0, "drag", "fret_2", Vector2(-40, 0)],
		[1.6, 0, "drag", "fret_3", Vector2(-40, 0)], [2.2, 1, "press", "strike_mid", Vector2.ZERO],
		[2.35, 1, "lift", "strike_mid", Vector2.ZERO], [2.6, 0, "drag", "fret_4", Vector2(-40, 0)],
		[3.2, 0, "lift", "fret_4", Vector2.ZERO], [3.3, 0, "press", "fret_2", Vector2.ZERO],
		[3.5, 1, "press", "strike_high", Vector2(-80, 0)], [3.6, 1, "drag", "strike_high", Vector2(-40, 0)],
		[3.7, 1, "drag", "strike_high", Vector2(0, 0)], [3.8, 1, "drag", "strike_high", Vector2(30, 0)],
		[4.2, 1, "wiggle", "strike_high", Vector2(30, 0)], [5.6, 1, "lift", "strike_high", Vector2(30, 0)],
		[5.8, 0, "lift", "fret_2", Vector2.ZERO], [6.0, 0, "press", "fret_1", Vector2.ZERO],
		[6.2, 1, "press", "strike_high", Vector2.ZERO], [6.3, 1, "drag", "strike_mid", Vector2.ZERO],
		[6.4, 1, "drag", "strike_low", Vector2.ZERO], [6.5, 1, "lift", "strike_low", Vector2.ZERO],
		[7.2, 0, "lift", "fret_1", Vector2.ZERO]],
}
const WIGGLE := {"px": 22.0, "hz": 6.0}

var _steps: Array = []
var _done := {}


func _init(name: String) -> void:
	_steps = SCRIPTS.get(name, [])


func tick(pad: TouchPad, now: float) -> void:
	for i in _steps.size():
		if now >= float(_steps[i][0]) and not _done.has(i):
			_play(pad, i, now)


func _play(pad: TouchPad, i: int, now: float) -> void:
	var step: Array = _steps[i]
	var op := String(step[2])
	var pos := TouchButtons.center(String(step[3])) + (step[4] as Vector2)
	if op == "wiggle":
		if _next_step_due(i, now):
			return
		pos.x += float(WIGGLE["px"]) * sin(now * TAU * float(WIGGLE["hz"]))
	else:
		_done[i] = true
	var event := _event(op, pos)
	event.set("index", int(step[1]))
	pad._unhandled_input(event)


static func _event(op: String, pos: Vector2) -> InputEvent:
	if op in ["drag", "wiggle"]:
		var drag := InputEventScreenDrag.new()
		drag.position = pos
		return drag
	var touch := InputEventScreenTouch.new()
	touch.position = pos
	touch.pressed = op == "press"
	return touch


func _next_step_due(i: int, now: float) -> bool:
	for j in range(i + 1, _steps.size()):
		if _steps[j][1] == _steps[i][1]:
			return now >= float(_steps[j][0])
	return false
