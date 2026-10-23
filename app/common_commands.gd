class_name CommonCommands
extends RefCounted

const OFFSET_STEP := 0.005
const OFFSET_LIMIT := 0.2

var _main: Main


func _init(main: Main) -> void:
	_main = main


func menu_up() -> void:
	Game.menu_index = posmod(Game.menu_index - 1, Songs.all().size())


func menu_down() -> void:
	Game.menu_index = posmod(Game.menu_index + 1, Songs.all().size())


func easier() -> void:
	_choose_difficulty(Difficulty.current_index() - 1)


func harder() -> void:
	_choose_difficulty(Difficulty.current_index() + 1)


func _choose_difficulty(next: int) -> void:
	if not Difficulty.choose(Difficulty.selected_id(), next):
		_main.feedback.say("deny", "Сложность: %s — %s" % [Difficulty.current()["name"], "дальше некуда"])
		return
	var level := Difficulty.current()
	_main.feedback.say("shift", "Сложность: %s — %s" % [level["name"], level["about"]])


func position_down() -> void:
	_shift_position(-1)


func position_up() -> void:
	_shift_position(1)


func toggle_metronome() -> void:
	Game.metronome = not Game.metronome
	Game.conductor.set_click_on(Game.metronome)
	var state := "включён" if Game.metronome else "выключен"
	_main.feedback.say("toggle_on" if Game.metronome else "toggle_off", "Метроном: %s" % state)


func offset_down() -> void:
	_nudge_offset(-OFFSET_STEP)


func offset_up() -> void:
	_nudge_offset(OFFSET_STEP)


func _shift_position(delta: int) -> void:
	var tuning := Game.tuning
	if not tuning.shift_position(delta):
		_main.feedback.say("deny", "Дальше по грифу некуда")
		return
	var lowest := Tuning.note_name(tuning.midi("1", "low"))
	var highest := Tuning.note_name(tuning.midi("3", "high"))
	_main.feedback.say("shift", "Позиция %d: %s–%s" % [tuning.position + 1, lowest, highest])


func _nudge_offset(delta: float) -> void:
	var conductor := Game.conductor
	conductor.input_offset = clampf(conductor.input_offset + delta, -OFFSET_LIMIT, OFFSET_LIMIT)
