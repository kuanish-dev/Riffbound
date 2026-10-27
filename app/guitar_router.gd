class_name GuitarRouter
extends RefCounted

var _hud: Hud


func _init(fretboard: Fretboard, hud: Hud) -> void:
	_hud = hud
	fretboard.played.connect(_on_played)
	fretboard.slurred.connect(_on_slurred)
	fretboard.muted.connect(_on_muted)
	fretboard.bent.connect(_on_bent)


func strings_to_strike() -> Array:
	if _judging():
		var near := Game.performance.strings_near(Game.conductor.player_time())
		if not near.is_empty():
			return near
	return [Game.tuning.strings[0]]


func on_voiced(note: String, string: String, _corrected: bool) -> void:
	var kind := "dead" if note == Notes.MUTE else "pluck"
	_perform({"kind": kind, "string": string, "fret": note, "pos": Game.tuning.position,
		"midis": Game.tuning.midis(note, string)})


func _on_played(note: String, string: String, time: float) -> void:
	if _judging():
		Game.performance.play(string, _midi(note, string), time, false)
	_hud.played_note(note, string, time, false)


func _on_slurred(note: String, string: String, time: float) -> void:
	_perform({"kind": "slur", "string": string, "fret": note, "pos": Game.tuning.position,
		"midis": Game.tuning.midis(note, string), "glide": Game.fretboard.sliding})
	if _judging():
		Game.performance.play(string, _midi(note, string), time, true)
	_hud.played_note(note, string, time, true)


func _on_muted(string: String, time: float) -> void:
	_perform({"kind": "mute", "string": string})
	if _judging():
		Game.performance.mute(string, time)


func _on_bent(string: String, amount: float, time: float) -> void:
	_perform({"kind": "bend", "string": string, "amount": amount})
	if _judging():
		Game.performance.bend(string, amount, time)


func _perform(event: Dictionary) -> void:
	Game.voices.play(event)
	Game.looper.capture(event, Game.conductor.now())


func _judging() -> bool:
	return Game.state == "song"


func _midi(note: String, string: String) -> int:
	var midis := Game.tuning.midis(note, string)
	return midis[0] if not midis.is_empty() else -1
