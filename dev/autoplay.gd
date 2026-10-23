class_name Autoplay
extends Node

const PREPARE := 0.06
const SHIFT_AHEAD := 0.25
const SHIFT_AFTER := 0.03

var _actions: Array[Dictionary] = []
var _held := {}
var _position := 0
var _state := ""


func _process(_delta: float) -> void:
	if Game.state != _state:
		_state = Game.state
		_start()
	if not Game.state in ["song", "jam"]:
		return
	var now := Game.conductor.player_time()
	while not _actions.is_empty() and now >= float(_actions[0]["time"]):
		var action: Dictionary = _actions.pop_front()
		call("_do_" + String(action["kind"]), action)


func _start() -> void:
	_actions.clear()
	_do_frets({"frets": []})
	_position = Game.tuning.position if Game.tuning != null else 0
	if Game.state == "song":
		_plan(Game.performance.notes)
	elif Game.state == "jam":
		_send("record", true)
		_send("record", false)
		_plan(Songs.notes_of(SongBook.SONGS[0]))


func _plan(notes: Array) -> void:
	var position := _position
	var last := -INF
	for i in notes.size():
		var note: Dictionary = notes[i]
		var t := int(note["slot"]) * Timing.slot_len()
		if int(note["pos"]) != position:
			position = int(note["pos"])
			_add(maxf(t - SHIFT_AHEAD, last + SHIFT_AFTER), {"kind": "position", "to": position})
		last = t
		_plan_fingers(notes, i, t)
		if note["bend"]:
			_plan_bend(note, t)
	_actions.sort_custom(_earlier)


func _plan_fingers(notes: Array, i: int, t: float) -> void:
	var note: Dictionary = notes[i]
	var fret := String(note["fret"])
	if note["legato"]:
		_add(t, {"kind": "legato", "fret": fret})
		return
	var frets := [] if fret == Notes.MUTE else [fret]
	frets.append_array(_pull_targets(notes, i))
	_add(t - PREPARE, {"kind": "frets", "frets": frets})
	_add(t, {"kind": "strike", "string": note["string"]})


func _plan_bend(note: Dictionary, t: float) -> void:
	_add(t + 0.02, {"kind": "bend", "on": true})
	_add((int(note["slot"]) + int(note["len"])) * Timing.slot_len() - 0.04, {"kind": "bend", "on": false})


func _pull_targets(notes: Array, index: int) -> Array:
	var out: Array = []
	var top := Notes.FRETS.find(notes[index]["fret"])
	for j in range(index + 1, notes.size()):
		var next: Dictionary = notes[j]
		if next["string"] != notes[index]["string"]:
			continue
		if not next["legato"]:
			break
		if Notes.FRETS.find(next["fret"]) < top:
			out.append(next["fret"])
	return out


func _add(time: float, action: Dictionary) -> void:
	action["time"] = time
	_actions.append(action)


func _do_frets(action: Dictionary) -> void:
	var want: Array = action["frets"]
	for on: bool in [false, true]:
		for fret: String in Notes.FRETS:
			if want.has(fret) == on and on != bool(_held.get(fret, false)):
				_send(InputConfig.fret_action(fret), on)
				_held[fret] = on


func _do_strike(action: Dictionary) -> void:
	_send(InputConfig.strike_action(String(action["string"])), true)
	_send(InputConfig.strike_action(String(action["string"])), false)


func _do_legato(action: Dictionary) -> void:
	var fret := String(action["fret"])
	if not _held.get(fret, false):
		_send(InputConfig.fret_action(fret), true)
		_held[fret] = true
		return
	for above: String in Notes.FRETS.slice(Notes.FRETS.find(fret) + 1):
		if _held.get(above, false):
			_send(InputConfig.fret_action(above), false)
			_held[above] = false


func _do_bend(action: Dictionary) -> void:
	_send("bend", bool(action["on"]))


func _do_position(action: Dictionary) -> void:
	var step := "position_up" if int(action["to"]) > _position else "position_down"
	while _position != int(action["to"]):
		_send(step, true)
		_send(step, false)
		_position += 1 if step == "position_up" else -1


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


static func _earlier(a: Dictionary, b: Dictionary) -> bool:
	return float(a["time"]) < float(b["time"])
