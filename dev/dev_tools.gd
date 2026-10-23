class_name DevTools
## CLI-режимы разработки (см. DevArgs): тесты, симуляция с ботом, снимок экрана.
## Всё здесь — только для разработки, игра от этого файла не зависит.

## Жесты пальцами для снимков (--gesture, с --touch): [время (с, часы игры), палец, что, кнопка, сдвиг от её
## середины]. press / drag / lift — касание, ведение, отпускание; wiggle — с этого времени палец качается вокруг
## сдвига на ±WIGGLE px (вибрато), пока не придёт его следующий шаг. demo — фраза для GIF в README
## (слайд, бенд, вибрато, бой; запись: --write-movie, см. CLAUDE.md).
const GESTURES := {
	"bend": [[1.0, 0, "press", "fret_2", Vector2.ZERO], [1.2, 1, "press", "strike_mid", Vector2(-80, 0)],
		[1.3, 1, "drag", "strike_mid", Vector2(-40, 0)], [1.4, 1, "drag", "strike_mid", Vector2(10, 0)],
		[1.5, 1, "drag", "strike_mid", Vector2(60, 0)], [1.6, 1, "drag", "strike_mid", Vector2(80, 0)]],
	"vibrato": [[1.0, 0, "press", "fret_3", Vector2.ZERO], [1.2, 1, "press", "strike_high", Vector2(-80, 0)],
		[1.3, 1, "drag", "strike_high", Vector2(-20, 0)], [1.4, 1, "wiggle", "strike_high", Vector2(0, 0)]],
	"slide": [[1.0, 0, "press", "fret_1", Vector2.ZERO], [1.2, 1, "press", "strike_low", Vector2.ZERO],
		[1.3, 1, "lift", "strike_low", Vector2.ZERO], [1.5, 0, "drag", "fret_2", Vector2(-40, 0)],
		[1.55, 0, "drag", "fret_3", Vector2(-40, 0)]],
	"demo": [[0.8, 0, "press", "fret_1", Vector2.ZERO], [1.0, 1, "press", "strike_low", Vector2.ZERO],
		[1.15, 1, "lift", "strike_low", Vector2.ZERO], [1.5, 0, "drag", "fret_2", Vector2(-40, 0)],
		[1.6, 0, "drag", "fret_3", Vector2(-40, 0)], [2.2, 1, "press", "strike_mid", Vector2.ZERO],
		[2.35, 1, "lift", "strike_mid", Vector2.ZERO], [2.6, 0, "drag", "fret_4", Vector2(-40, 0)],
		[3.2, 0, "lift", "fret_4", Vector2.ZERO], [3.3, 0, "press", "fret_2", Vector2.ZERO],
		[3.5, 1, "press", "strike_high", Vector2(-80, 0)], [3.6, 1, "drag", "strike_high", Vector2(-40, 0)],
		[3.7, 1, "drag", "strike_high", Vector2(0, 0)], [3.8, 1, "drag", "strike_high", Vector2(30, 0)],
		[4.2, 1, "wiggle", "strike_high", Vector2(30, 0)], [5.6, 1, "lift", "strike_high", Vector2(30, 0)],
		[5.8, 0, "lift", "fret_2", Vector2.ZERO], [6.0, 0, "press", "fret_1", Vector2.ZERO],
		[6.2, 1, "press", "strike_high", Vector2.ZERO], [6.3, 1, "drag", "strike_mid", Vector2.ZERO],
		[6.4, 1, "drag", "strike_low", Vector2.ZERO], [6.5, 1, "lift", "strike_low", Vector2.ZERO],
		[7.2, 0, "lift", "fret_1", Vector2.ZERO]],
}
const WIGGLE := {"px": 22.0, "hz": 6.0}


## Каждый метод test_* каждого набора: before_each() → тест → итог; в конце набора — after_all().
static func run_tests(main: Node) -> void:
	var suites: Array[TestSuite] = [CoreTests.new(), InstrumentTests.new(), SongTests.new(), JamTests.new(), TouchTests.new(),
		MusicTests.new(), HarmonyTests.new(), ShopTests.new(), StyleTests.new(), SoundTests.new()]
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


## Шаги жеста, чьё время пришло, — в TouchPad, как от настоящих пальцев.
static func _gesture_tick(pad: TouchPad, steps: Array, done: Dictionary, now: float) -> void:
	for i in steps.size():
		var step: Array = steps[i]
		if now < float(step[0]) or done.has(i):
			continue
		var pos := _button_center(String(step[3])) + (step[4] as Vector2)
		var op := String(step[2])
		if op == "wiggle":
			if _next_step_due(steps, i, now):
				continue
			pos.x += float(WIGGLE["px"]) * sin(now * TAU * float(WIGGLE["hz"]))
		else:
			done[i] = true
		var event: InputEvent
		if op == "drag" or op == "wiggle":
			var drag := InputEventScreenDrag.new()
			drag.position = pos
			event = drag
		else:
			var touch := InputEventScreenTouch.new()
			touch.position = pos
			touch.pressed = op == "press"
			event = touch
		event.set("index", int(step[1]))
		pad._unhandled_input(event)


## Пришло ли время следующего шага того же пальца (тогда покачивание кончилось).
static func _next_step_due(steps: Array, i: int, now: float) -> bool:
	for j in range(i + 1, steps.size()):
		if steps[j][1] == steps[i][1]:
			return now >= float(steps[j][0])
	return false


static func _button_center(action: String) -> Vector2:
	for button: Dictionary in TouchPad.GUITAR:
		if button["action"] == action:
			return (button["rect"] as Rect2).get_center()
	return Vector2.ZERO


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
		print("[sim] %-14s нот %d/%d, техника %d/%d, не тех %d, счёт %d, звёзд %d, стиль %s" % [p.song["name"], p.hits,
			p.notes.size(), p.techs, p.tech_total, p.wrongs, p.score, p.stars(), main.style.result()["style"]])
		if p.hits < p.notes.size() or p.wrongs > 0 or p.techs < p.tech_total:
			problems.append(String(p.song["id"]))
	print("[sim] %s %s" % ["PASS" if problems.is_empty() else "FAIL", ", ".join(PackedStringArray(problems))])
	main.quit(0 if problems.is_empty() else 1)


## Громкость звука каждой гитары: фраза «послушать» её звуком, уровень снимается с шины гитары после всех
## эффектов (AudioEffectCapture), общий выход приглушён — динамики молчат. Звуки должны быть близки по громкости.
static func tones(main: Main) -> void:
	Songs.persist = false
	AudioServer.set_bus_volume_db(0, -80.0)
	var bus := AudioServer.get_bus_index(GuitarVoices.LEAD_BUS)
	main.open_shop()
	for i in Shop.SKINS.size():
		Game.shop_index = i
		for f in 3:
			await main.get_tree().process_frame
		var capture := AudioEffectCapture.new()
		capture.buffer_length = 2.0
		AudioServer.add_bus_effect(bus, capture)
		main.listen()
		var sum := 0.0
		var count := 0
		var peak := 0.0
		var started := Time.get_ticks_msec()
		while Time.get_ticks_msec() - started < 3800:
			await main.get_tree().process_frame
			for frame: Vector2 in capture.get_buffer(capture.get_frames_available()):
				var v := maxf(absf(frame.x), absf(frame.y))
				sum += frame.x * frame.x + frame.y * frame.y
				count += 2
				peak = maxf(peak, v)
		var skin: Dictionary = Shop.SKINS[i]
		print("[tone] %-10s %-12s громкость %6.1f дБ, пик %6.1f дБ" % [skin["id"], skin["tone"]["name"],
			linear_to_db(sqrt(sum / maxi(count, 1))), linear_to_db(peak)])
	main.quit()


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
	elif DevArgs.has("shop"):
		main.open_shop()
		Game.shop_index = DevArgs.get_int("skin", Game.shop_index)
	elif not DevArgs.has("menu"):
		main.start_song()
	var at := float(DevArgs.get_str("at", "8"))
	var frames := 0
	var started := Time.get_ticks_msec()
	var gesture: Array = GESTURES.get(DevArgs.get_str("gesture", ""), [])
	var done := {}
	while (Game.state in ["song", "jam"] and main.conductor.now() < at) or (Game.state in ["menu", "shop"] and frames < 30):
		frames += 1
		_gesture_tick(main.touch_pad, gesture, done, main.conductor.now())
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := DevArgs.get_str("screenshot")
	main.get_viewport().get_texture().get_image().save_png(path)
	var fps := frames * 1000.0 / maxf(1.0, Time.get_ticks_msec() - started)
	print("[shot] %s (%s, %.1f с, счёт %d, %.0f fps)" % [path, Game.state, main.conductor.now(), main.performance.score, fps])
	if Game.metronome:
		# метроном и музыка должны стоять в одном месте такта
		var clock := main.conductor
		var drift := fposmod(clock.player.get_playback_position() - clock.loop_start, Timing.bar_len()) \
			- clock.click.get_playback_position()
		print("[shot] метроном: %s, расхождение с музыкой %.1f мс" % ["играет" if clock.click.playing else "молчит", drift * 1000.0])
	main.quit()
