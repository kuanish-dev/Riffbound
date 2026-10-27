class_name Fretboard
extends Node

signal voiced(note: String, string: String, corrected: bool)
signal played(note: String, string: String, time: float)
signal slurred(note: String, string: String, time: float)
signal muted(string: String, time: float)
signal bent(string: String, amount: float, time: float)

const LENIENCY := 0.05
const LEGATO_WINDOW := 0.65

var conductor: Conductor
var held := {}
var active := ""
var ringing := {}
var bending := false
var bend_amount := 0.0
var sliding := false
var pick_strings: Callable = _lowest_string
var _pending := {}


func _init() -> void:
	process_priority = -5


func _unhandled_input(event: InputEvent) -> void:
	for fret: String in Notes.FRETS:
		var action := InputConfig.fret_action(fret)
		if event.is_action_pressed(action):
			press_fret(fret)
		elif event.is_action_released(action):
			release_fret(fret)
	if event.is_action_pressed("strike"):
		for string: String in pick_strings.call():
			strike(string)
	if event.is_action_pressed("bend"):
		set_bend(1.0)
	elif event.is_action_released("bend"):
		set_bend(0.0)
	elif event.is_action("bend_pull"):
		set_bend(event.get_action_strength("bend_pull") * Tuning.BEND_MAX if event.is_pressed() else 0.0)
	if event.is_action("slide"):
		sliding = event.is_pressed()


static func _lowest_string() -> Array:
	return [Notes.STRINGS[0]]


func _process(_delta: float) -> void:
	update()


func press_fret(fret: String) -> void:
	held[fret] = true
	if not _pending.is_empty():
		_pending["fret_pressed"] = true
		return
	if (_legato_open() or _slide_open()) and _rank(_top_fret()) > _rank(String(ringing[active]["note"])):
		_slur(_top_fret())


func release_fret(fret: String) -> void:
	held.erase(fret)
	for string: String in ringing.keys():
		var frets: Array = ringing[string]["frets"]
		if not frets.has(fret):
			continue
		var top := _top_fret()
		if string == active and _pending.is_empty() and (_legato_open() or _slide_open()) and top != "" and _rank(top) < _rank(fret):
			_slur(top)
		else:
			_mute(string)


func strike(string: String) -> void:
	if not _pending.is_empty():
		_commit()
	var note := Notes.from_frets(held)
	var time := conductor.player_time()
	_pending = {"time": time, "note": note, "string": string, "fret_pressed": false}
	active = string
	_ring(string, note, time)
	voiced.emit(note, string, false)
	if bending:
		bent.emit(string, bend_amount, time)


func set_bend(amount: float) -> void:
	amount = clampf(amount, 0.0, Tuning.BEND_MAX)
	bending = amount > 0.0
	bend_amount = amount
	if active != "":
		bent.emit(active, amount, conductor.player_time())


func update() -> void:
	if not _pending.is_empty() and conductor.player_time() - float(_pending["time"]) >= LENIENCY:
		_commit()


func cancel() -> void:
	_pending = {}
	ringing.clear()
	active = ""


func _commit() -> void:
	var pending := _pending
	_pending = {}
	var note: String = pending["note"]
	var string: String = pending["string"]
	var time := float(pending["time"])
	if pending["fret_pressed"]:
		var late := Notes.from_frets(held)
		if late != note or not ringing.has(string):
			note = late
			_ring(string, note, time)
			voiced.emit(note, string, true)
	played.emit(note, string, time)


func _ring(string: String, note: String, time: float) -> void:
	if note == Notes.MUTE:
		ringing.erase(string)
	else:
		ringing[string] = {"note": note, "frets": held.keys(), "since": time}


func _slur(fret: String) -> void:
	var time := conductor.player_time()
	ringing[active] = {"note": fret, "frets": [fret], "since": time}
	slurred.emit(fret, active, time)


func _mute(string: String) -> void:
	ringing.erase(string)
	muted.emit(string, conductor.player_time())


func _legato_open() -> bool:
	return active != "" and ringing.has(active) \
		and conductor.player_time() - float(ringing[active]["since"]) <= LEGATO_WINDOW


func _slide_open() -> bool:
	return sliding and active != "" and ringing.has(active)


func _top_fret() -> String:
	var top := ""
	for fret: String in Notes.FRETS:
		if held.has(fret):
			top = fret
	return top


func _rank(fret: String) -> int:
	return Notes.FRETS.find(fret)
