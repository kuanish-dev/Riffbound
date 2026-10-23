class_name TouchControls
extends HudLayer

const BEND_HINT := "ударь и тяни вбок →"

var _bends := {}
var _slides: Array[Dictionary] = []


func _ready() -> void:
	for string: String in Notes.STRINGS:
		_bends[string] = BendView.new()


func on_slid(from: String, to: String) -> void:
	var fretboard := Game.fretboard
	var string := fretboard.active if fretboard.ringing.has(fretboard.active) else String(Notes.STRINGS[1])
	_slides.append({"from": from, "to": to, "string": string, "age": 0.0})


func _process(delta: float) -> void:
	super(delta)
	_track_bends(delta)
	_age_slides(delta)


func _track_bends(delta: float) -> void:
	var fretboard := Game.fretboard
	if fretboard == null:
		return
	for string: String in Notes.STRINGS:
		var bending := fretboard.bending and fretboard.active == string
		(_bends[string] as BendView).update(fretboard.bend_amount if bending else 0.0, delta)


func _age_slides(delta: float) -> void:
	for slide: Dictionary in _slides:
		slide["age"] = float(slide["age"]) + delta
	_slides = _slides.filter(func(slide: Dictionary) -> bool: return float(slide["age"]) < NeckArt.SLIDE_RUN + NeckArt.SLIDE_FADE)


func _draw() -> void:
	var cue := Cue.next()
	var pulse := Cue.glow(cue, t)
	var frets := {}
	for button: Dictionary in TouchButtons.buttons(Game.state):
		if button.has("fret"):
			frets[button["fret"]] = button["rect"]
		elif button["kind"] != "row":
			call("_draw_" + String(button.get("art", "plain")), button, cue, pulse)
	if not frets.is_empty():
		NeckArt.draw(self, frets, _neck_state(cue, pulse))


func _draw_plain(button: Dictionary, _cue: Dictionary, _pulse: float) -> void:
	var lit: bool = button.has("lit") and Game.get(String(button["lit"]))
	PadArt.button(self, button["rect"], String(button["label"]), PadArt.NEON if lit else PadArt.IDLE, 1.0 if lit else 0.0)


func _draw_shift(button: Dictionary, _cue: Dictionary, _pulse: float) -> void:
	var next := Game.performance.next_note() if Game.state == "song" else {}
	var wanted := not next.is_empty() and signf(int(next["pos"]) - Game.tuning.position) == float(button["dir"])
	var glow := 0.5 * (0.6 + 0.4 * sin(t * Cue.BLINK)) if wanted else 0.0
	PadArt.shift(self, button["rect"], String(button["label"]), float(button["dir"]), PadArt.GOLD if wanted else PadArt.IDLE, glow)


func _draw_string(button: Dictionary, cue: Dictionary, pulse: float) -> void:
	var string := String(button["string"])
	var rect: Rect2 = button["rect"]
	var bend: BendView = _bends[string]
	var cued: bool = cue.get("strings", []).has(string)
	StringArt.draw(self, rect, {"string": string, "name": button["label"], "note": _sounding_note(string, bend.amount),
		"edge": _string_edge(cued, pulse, bend.amount), "glow": strikes.flash(string), "amount": bend.amount,
		"wobble": bend.wobble, "apex": _pull_x(string), "shake": strikes.shake(string), "t": t,
		"meter": maxf(0.25 if Game.needs.get("bend", true) else 0.0, clampf(bend.amount * 4.0, 0.0, 1.0))})
	if cued and cue.get("bend", false):
		Glyph.text_center(self, rect.get_center().x - 14, rect.end.y - 12, BEND_HINT, 17, Ink.GOLD)


static func _sounding_note(string: String, amount: float) -> String:
	var ringing: Dictionary = Game.fretboard.ringing.get(string, {})
	if ringing.is_empty():
		return ""
	var midi := Game.tuning.midi(String(ringing["note"]), string)
	return Tuning.note_name(midi + roundi(amount * Tuning.BEND_SEMITONES))


static func _string_edge(cued: bool, pulse: float, amount: float) -> Color:
	if cued:
		return PadArt.IDLE.lerp(PadArt.GOLD, 0.5 + 0.5 * pulse)
	return PadArt.HOT if amount > 0.05 else PadArt.IDLE


static func _pull_x(string: String) -> float:
	var pull: BendGesture = Game.pad.pull_of(string) if Game.pad != null else null
	return pull.from.x if pull != null and pull.on else -1.0


func _neck_state(cue: Dictionary, pulse: float) -> Dictionary:
	return {"held": Game.fretboard.held, "cued": cue.get("frets", []), "pulse": pulse, "ringing": _ringing_strings(),
		"dots": _chord_dots() + _cue_dots(cue, pulse), "slides": _slides,
		"fingers": Game.pad.points.values() if Game.pad != null else [], "t": t}


func _ringing_strings() -> Dictionary:
	var out := {}
	for string: String in Game.fretboard.ringing:
		out[string] = {"fret": Game.fretboard.ringing[string]["note"], "shake": strikes.shake(string)}
	return out


static func _chord_dots() -> Array[Dictionary]:
	var dots: Array[Dictionary] = []
	var chord := Harmony.parse(ChordGuide.now()) if Game.state == "jam" else {}
	for fret: String in Notes.FRETS:
		for string: String in Notes.STRINGS:
			var role := Harmony.role(chord, Game.tuning.midi(fret, string))
			if not role.is_empty():
				dots.append({"fret": fret, "string": string, "ink": PadArt.GOLD if role == "root" else PadArt.NEON})
	return dots


static func _cue_dots(cue: Dictionary, pulse: float) -> Array[Dictionary]:
	var dots: Array[Dictionary] = []
	for fret: String in cue.get("frets", []):
		for string: String in cue.get("strings", []):
			dots.append({"fret": fret, "string": string, "ink": Color(PadArt.GOLD, 0.4 + 0.6 * pulse)})
	return dots
