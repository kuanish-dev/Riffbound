class_name DevTools
## CLI-режимы разработки (см. DevArgs): тесты, симуляция с ботом, снимок экрана.
## Всё здесь — только для разработки, игра от этого файла не зависит.

## Каждый метод test_* каждого набора: before_each() → тест → итог; в конце набора — after_all().
static func run_tests(main: Node) -> void:
	var suites: Array[TestSuite] = [CoreTests.new(), InstrumentTests.new(), SongTests.new(), JamTests.new(), TouchTests.new(),
		MusicTests.new()]
	var total := 0
	var failed := 0
	for suite in suites:
		for m in suite.get_method_list():
			var test_name: String = m["name"]
			if not test_name.begins_with("test_"):
				continue
			total += 1
			suite.before_each()
			suite.begin()
			suite.call(test_name)
			var errors := suite.end()
			if errors.is_empty():
				print("[test] ok    %s" % test_name)
			else:
				failed += 1
				for e in errors:
					print("[test] FAIL  %s: %s" % [test_name, e])
		suite.after_all()
	print("[test] %s — %d/%d" % ["PASS" if failed == 0 else "FAIL", total - failed, total])
	main.get_tree().quit(1 if failed > 0 else 0)


## Бот играет все встроенные песни через настоящий ввод; PASS, если в каждой сыграны все ноты,
## вся техника и ни одной «не той ноты».
static func simulate(main: Main) -> void:
	Songs.persist = false
	main.add_child(Autoplay.new())
	var problems: Array[String] = []
	for i in Songs.BUILT_IN.size():
		Game.menu_index = i
		main.start_song()
		while Game.state == "song":
			await main.get_tree().process_frame
		var p := main.performance
		print("[sim] %-14s нот %d/%d, техника %d/%d, не тех %d, счёт %d, звёзд %d" % [p.song["name"], p.hits, p.notes.size(),
			p.techs, p.tech_total, p.wrongs, p.score, p.stars()])
		if p.hits < p.notes.size() or p.wrongs > 0 or p.techs < p.tech_total:
			problems.append(String(p.song["id"]))
	print("[sim] %s %s" % ["PASS" if problems.is_empty() else "FAIL", ", ".join(PackedStringArray(problems))])
	main.quit(0 if problems.is_empty() else 1)


## Кадр в PNG: --at=<сек> песни или джема, ~30 кадров меню (--menu); кончилась песня раньше — итог.
## Звук заглушен,
## в сводке — средний FPS (низкий означает, что тормозит сама игра).
static func screenshot(main: Main) -> void:
	Songs.persist = false
	AudioServer.set_bus_mute(0, true)
	# окно, открытое в фоне, macOS с вертикальной синхронизацией почти не рисует — снимку она не нужна
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	if DevArgs.has("autoplay"):
		main.add_child(Autoplay.new())
	if DevArgs.has("jam"):
		main.start_jam()
	elif not DevArgs.has("menu"):
		main.start_song()
	var at := float(DevArgs.get_str("at", "8"))
	var frames := 0
	var started := Time.get_ticks_msec()
	while (Game.state in ["song", "jam"] and main.conductor.now() < at) or (Game.state == "menu" and frames < 30):
		frames += 1
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := DevArgs.get_str("screenshot")
	main.get_viewport().get_texture().get_image().save_png(path)
	var fps := frames * 1000.0 / maxf(1.0, Time.get_ticks_msec() - started)
	print("[shot] %s (%s, %.1f с, счёт %d, %.0f fps)" % [path, Game.state, main.conductor.now(), main.performance.score, fps])
	main.quit()
