class_name Fretboard
extends Node
## Гитара под пальцами. Левая рука держит лады, правая бьёт по одной из струн (Notes.STRINGS).
## Нота рождается в момент удара: звучит верхний из зажатых ладов, высота — от струны и строя (Tuning).
## Как на настоящей гитаре:
## - нота звенит, пока зажат её лад: отпустил — струна заглушена (muted);
## - на струне одна нота за раз, разные струны звенят вместе;
## - легато: пока последняя струна звенит недавно (LEGATO_WINDOW), прижатый выше лад — хаммер-он,
##   а снятый верхний палец при зажатом нижнем — пулл-офф: новая нота без удара (slurred),
##   звучит верхний из зажатых ладов;
## - бенд: пока зажата клавиша бенда, последняя струна подтянута вверх (bent).
## Окно прощения: лад, зажатый чуть позже удара (до LENIENCY), считается ладом этого удара.

## Звук удара: сразу при ударе и ещё раз, если окно прощения поменяло ноту (corrected).
signal voiced(note: String, string: String, corrected: bool)
## Удар засчитан (после окна прощения): нота, струна и время удара.
signal played(note: String, string: String, time: float)
## Легато: новая нота на струне без удара.
signal slurred(note: String, string: String, time: float)
## Струна заглушена: отпущен лад её ноты.
signal muted(string: String, time: float)
## Бенд струны: amount 1 — подтянута, 0 — отпущена.
signal bent(string: String, amount: float, time: float)

const LENIENCY := 0.05
const LEGATO_WINDOW := 0.65     ## чуть дольше четверти при 100 BPM

var conductor: Conductor
var held := {}            ## лад → true, пока зажат
var active := ""          ## струна последней ноты: на ней легато и бенд
var ringing := {}         ## струна → {note, frets, since}: что звенит и какими ладами держится
var bending := false
var _pending := {}        ## удар в окне прощения: time, note, string, fret_pressed


func _init() -> void:
	process_priority = -5


func _unhandled_input(event: InputEvent) -> void:
	for fret: String in Notes.FRETS:
		var action := InputConfig.fret_action(fret)
		if event.is_action_pressed(action):
			press_fret(fret)
		elif event.is_action_released(action):
			release_fret(fret)
	for string: String in Notes.STRINGS:
		if event.is_action_pressed(InputConfig.strike_action(string)):
			strike(string)
	if event.is_action_pressed("bend"):
		set_bend(true)
	elif event.is_action_released("bend"):
		set_bend(false)


func _process(_delta: float) -> void:
	update()


func press_fret(fret: String) -> void:
	held[fret] = true
	if not _pending.is_empty():
		_pending["fret_pressed"] = true
		return
	if _legato_open() and _rank(_top_fret()) > _rank(String(ringing[active]["note"])):
		_slur(_top_fret())


func release_fret(fret: String) -> void:
	held.erase(fret)
	for string: String in ringing.keys():
		var frets: Array = ringing[string]["frets"]
		if not frets.has(fret):
			continue
		var top := _top_fret()
		if string == active and _pending.is_empty() and _legato_open() and top != "" and _rank(top) < _rank(fret):
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
		bent.emit(string, 1.0, time)


func set_bend(on: bool) -> void:
	bending = on
	if active != "":
		bent.emit(active, 1.0 if on else 0.0, conductor.player_time())


## Закрывает окно прощения, когда оно истекло.
func update() -> void:
	if not _pending.is_empty() and conductor.player_time() - float(_pending["time"]) >= LENIENCY:
		_commit()


## Забыть удар в окне прощения и звенящие струны (новый бой или джем: часы начались заново).
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


## Верхний из зажатых ладов ("" — ничего не зажато).
func _top_fret() -> String:
	var top := ""
	for fret: String in Notes.FRETS:
		if held.has(fret):
			top = fret
	return top


func _rank(fret: String) -> int:
	return Notes.FRETS.find(fret)
