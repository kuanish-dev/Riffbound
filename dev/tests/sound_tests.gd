class_name SoundTests
extends TestSuite


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
	for kind: String in Feedback.FACT_SOUNDS:
		check(UiSounds.SOUNDS.has(Feedback.FACT_SOUNDS[kind]), "факт %s: звук есть" % kind)


func test_sounds_named_in_code_exist() -> void:
	var source := ""
	for file in DirAccess.get_files_at("res://app"):
		if file.ends_with(".gd"):
			source += FileAccess.get_file_as_string("res://app".path_join(file))
	var calls := RegEx.create_from_string("(?:play|say)\\((\"[a-z_]+\"(?: if [^,]+ else \"[a-z_]+\")?)")
	var names := RegEx.create_from_string("\"([a-z_]+)\"")
	var found := 0
	for call in calls.search_all(source):
		for m in names.search_all(call.get_string(1)):
			found += 1
			check(UiSounds.SOUNDS.has(m.get_string(1)), "звук «%s» есть" % m.get_string(1))
	check(found > 20, "звуки в коде найдены (%d)" % found)
