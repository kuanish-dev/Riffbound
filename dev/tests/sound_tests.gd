class_name SoundTests
extends TestSuite
## Звуки отклика: каждый рецепт собирается в слышный и не перегруженный звук, а все имена звуков,
## которые зовёт Main (таблицы и вызовы в коде), есть в UiSounds.SOUNDS.


func test_sounds_render() -> void:
	for id: String in UiSounds.SOUNDS:
		var wav := UiSounds.render(UiSounds.SOUNDS[id])
		var peak := 0
		for i in range(0, wav.data.size(), 2):
			peak = maxi(peak, absi(wav.data.decode_s16(i)))
		check(peak > 2000, "%s: слышно (пик %d)" % [id, peak])
		check(peak < 32000, "%s: не перегружен (пик %d)" % [id, peak])
		check(wav.data.size() / 2 < UiSounds.RATE, "%s: короче секунды" % id)


func test_command_sounds_match_commands() -> void:
	for scope: String in Main.COMMAND_SOUNDS:
		for action: String in Main.COMMAND_SOUNDS[scope]:
			check((Main.COMMANDS.get(scope, {}) as Dictionary).has(action), "%s/%s: такая команда есть" % [scope, action])
			check(UiSounds.SOUNDS.has(Main.COMMAND_SOUNDS[scope][action]), "%s/%s: звук есть" % [scope, action])
	for kind: String in Main.FACT_SOUNDS:
		check(UiSounds.SOUNDS.has(Main.FACT_SOUNDS[kind]), "факт %s: звук есть" % kind)


## Имена звуков в вызовах ui.play(звук) и _say(звук, …) в коде Main.
func test_sounds_named_in_code_exist() -> void:
	var source := FileAccess.get_file_as_string("res://app/main.gd")
	var calls := RegEx.create_from_string("(?:ui\\.play|_say)\\((\"[a-z_]+\"(?: if [^,]+ else \"[a-z_]+\")?)")
	var names := RegEx.create_from_string("\"([a-z_]+)\"")
	var found := 0
	for call in calls.search_all(source):
		for m in names.search_all(call.get_string(1)):
			found += 1
			check(UiSounds.SOUNDS.has(m.get_string(1)), "звук «%s» есть" % m.get_string(1))
	check(found > 20, "звуки в коде найдены (%d)" % found)
