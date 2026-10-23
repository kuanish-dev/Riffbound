class_name InstrumentTests
extends TestSuite
## Гитара как инструмент: глушение отпущенным ладом, хаммер-он, пулл-офф, окно легато, бенд.

var clock: Conductor
var fb: Fretboard
var log: Array[String] = []


func before_each() -> void:
	if fb != null:
		fb.free()
		clock.free()
	clock = Conductor.new()
	clock.set_manual(1.0)
	fb = Fretboard.new()
	fb.conductor = clock
	log.clear()
	fb.played.connect(func(note: String, string: String, _t: float) -> void: log.append("strike %s:%s" % [note, string]))
	fb.slurred.connect(func(note: String, string: String, _t: float) -> void: log.append("slur %s:%s" % [note, string]))
	fb.muted.connect(func(string: String, _t: float) -> void: log.append("mute %s" % string))
	fb.bent.connect(func(string: String, amount: float, _t: float) -> void: log.append("bend %s %.1f" % [string, amount]))


func after_all() -> void:
	fb.free()
	clock.free()


func test_release_mutes_string() -> void:
	fb.press_fret("1")
	fb.strike("low")
	_at(1.2)
	fb.release_fret("1")
	eq(log, ["strike 1:low", "mute low"], "отпустил лад — струна заглохла")


func test_other_string_keeps_ringing() -> void:
	fb.press_fret("1")
	fb.strike("low")
	_at(1.1)
	fb.release_fret("1")
	fb.press_fret("3")
	fb.strike("mid")
	_at(1.6)
	fb.release_fret("3")
	eq(log, ["strike 1:low", "mute low", "strike 3:mid", "mute mid"], "каждая струна глохнет от своего лада")


func test_hammer_on_and_pull_off() -> void:
	fb.press_fret("1")
	fb.strike("low")
	_at(1.15)
	fb.press_fret("3")
	_at(1.3)
	fb.release_fret("3")
	eq(log, ["strike 1:low", "slur 3:low", "slur 1:low"], "трель без ударов: 1 → 3 → 1")


func test_lower_fret_is_not_hammer() -> void:
	fb.press_fret("3")
	fb.strike("mid")
	_at(1.15)
	fb.press_fret("1")
	eq(log, ["strike 3:mid"], "лад ниже звучащего не меняет ноту")


func test_legato_window_closes() -> void:
	fb.press_fret("1")
	fb.strike("low")
	_at(1.0 + Fretboard.LEGATO_WINDOW + 0.1)
	fb.press_fret("3")
	fb.release_fret("1")
	eq(log, ["strike 1:low", "mute low"], "поздно: хаммер-она нет, снятый лад глушит")


func test_bend_follows_active_string() -> void:
	fb.press_fret("2")
	fb.strike("high")
	fb.set_bend(1.0)
	fb.set_bend(0.0)
	eq(log.slice(log.size() - 2), ["bend high 1.0", "bend high 0.0"], "бенд и отпуск на последней струне")


func test_slide_long_after_strike() -> void:
	fb.press_fret("1")
	fb.strike("low")
	_at(1.0 + Fretboard.LEGATO_WINDOW + 1.0)
	fb.sliding = true
	fb.press_fret("3")
	fb.release_fret("1")
	fb.sliding = false
	eq(log, ["strike 1:low", "slur 3:low"], "палец поехал по ладам — слайд, хоть и долго после удара")


func test_bend_any_height() -> void:
	fb.press_fret("1")
	fb.strike("mid")
	fb.set_bend(0.3)
	fb.set_bend(1.2)
	fb.set_bend(9.0)
	fb.set_bend(0.0)
	eq(log.slice(log.size() - 4), ["bend mid 0.3", "bend mid 1.2", "bend mid %.1f" % Tuning.BEND_MAX, "bend mid 0.0"],
		"тянешь на сколько угодно — до полутора тонов")


func _at(time: float) -> void:
	clock.set_manual(time)
	fb.update()
