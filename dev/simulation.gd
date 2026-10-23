class_name Simulation
extends Node

var _main: Main
var _wrong: Array[String] = []


static func run(main: Main) -> void:
	main.add_child(Simulation.new(main))


func _init(main: Main) -> void:
	_main = main


func _ready() -> void:
	Songs.persist = false
	_main.add_child(Autoplay.new())
	_main.performance.fact.connect(_on_fact)
	_run_all()


func _run_all() -> void:
	var problems: Array[String] = []
	for i in SongBook.SONGS.size():
		if not await _play_song(i):
			problems.append(String(_main.performance.song["id"]))
	print("[sim] %s %s" % ["PASS" if problems.is_empty() else "FAIL", ", ".join(PackedStringArray(problems))])
	_main.quit(0 if problems.is_empty() else 1)


func _play_song(index: int) -> bool:
	Game.menu_index = index
	_wrong.clear()
	_main.start_song()
	while Game.state == "song":
		await _main.get_tree().process_frame
	var p := _main.performance
	print("[sim] %-14s нот %d/%d, техника %d/%d, не тех %d, счёт %d, звёзд %d, стиль %s" % [p.song["name"], p.hits,
		p.notes.size(), p.techs, p.tech_total, p.wrongs, p.score, p.stars(), _main.style.result()["style"]])
	var clean := p.hits == p.notes.size() and p.wrongs == 0 and p.techs == p.tech_total
	if not clean:
		_print_problems(p)
	return clean


func _print_problems(p: SongJudge) -> void:
	for note: Dictionary in p.notes:
		if note["state"] != "hit":
			print("[sim]   мимо: " + _describe(note))
	for wrong in _wrong:
		print("[sim]   не та: " + wrong)


static func _describe(note: Dictionary) -> String:
	@warning_ignore("integer_division")
	var bar := int(note["slot"]) / Timing.SLOTS_PER_BAR - Songs.LEAD_IN + 1
	var legato := " легато" if note["legato"] else ""
	return "такт %d.%d %s лад %s поз %d%s" % [bar, int(note["slot"]) % Timing.SLOTS_PER_BAR, note["string"], note["fret"],
		note["pos"], legato]


func _on_fact(kind: String, data: Dictionary) -> void:
	if kind == "wrong":
		_wrong.append("%s %s @%.2f" % [data["string"], Tuning.note_name(int(data["midi"])), _main.conductor.player_time()])
